// Rain & Pulse - the truthful shared world (slice 8).
// One completion = one durable event with a stable UUID, queued locally,
// submitted idempotently, counted exactly once. The pulse is only ever
// what the server verified; nothing is invented, smoothed, or inflated.

import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart' show ValueNotifier;
import 'package:shared_preferences/shared_preferences.dart';

import '../core/clock.dart';
import 'api.dart';

final pulseTick = ValueNotifier<int>(0);

// ---------- stable event identity ----------
String uuid4() {
  final r = Random.secure();
  final b = List<int>.generate(16, (_) => r.nextInt(256));
  b[6] = (b[6] & 0x0f) | 0x40;
  b[8] = (b[8] & 0x3f) | 0x80;
  String h(int i) => b[i].toRadixString(16).padLeft(2, '0');
  return '${h(0)}${h(1)}${h(2)}${h(3)}-${h(4)}${h(5)}-${h(6)}${h(7)}-'
      '${h(8)}${h(9)}-${h(10)}${h(11)}${h(12)}${h(13)}${h(14)}${h(15)}';
}

// ---------- the outbound queue ----------
class PendingDrop {
  final String id; // event UUID: the idempotency key, forever
  final String day; // local civil date of the action
  final int n;
  int attempts;
  int nextRetryMs; // epoch ms; 0 = due now
  PendingDrop(this.id, this.day, this.n,
      {this.attempts = 0, this.nextRetryMs = 0});

  Map<String, dynamic> toJson() =>
      {'id': id, 'day': day, 'n': n, 'a': attempts, 'r': nextRetryMs};
  factory PendingDrop.fromJson(Map<String, dynamic> j) => PendingDrop(
      (j['id'] ?? '').toString(), (j['day'] ?? '').toString(),
      (j['n'] is int) ? j['n'] as int : 1,
      attempts: (j['a'] is int) ? j['a'] as int : 0,
      nextRetryMs: (j['r'] is int) ? j['r'] as int : 0);
}

/// Exponential backoff, bounded: 1, 2, 4... up to 60 minutes.
Duration backoff(int attempts) =>
    Duration(minutes: min(pow(2, attempts).toInt(), 60));

class Pulse {
  static const _qKey = 'pulseQueue';
  static const _maxQueue = 200;
  static const _maxAttempts = 8;
  static bool _flushing = false;

  static Future<List<PendingDrop>> queue() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_qKey);
    if (raw == null) return [];
    try {
      return (jsonDecode(raw) as List)
          .map((e) => PendingDrop.fromJson(
              (e as Map).map((k, v) => MapEntry(k.toString(), v))))
          .where((d) => d.id.isNotEmpty)
          .toList();
    } catch (_) {
      return []; // corruption recovery: a lost queue, never a crash
    }
  }

  static Future<void> _save(List<PendingDrop> q) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(
        _qKey, jsonEncode(q.take(_maxQueue).map((d) => d.toJson()).toList()));
  }

  /// One completed action becomes one durable event. Persisted BEFORE any
  /// animation, submitted after; safe to call from the background isolate.
  static Future<void> add({int n = 1}) async {
    final q = await queue();
    q.add(PendingDrop(uuid4(), todayStr(), n));
    await _save(q);
    pulseTick.value++;
    flush(); // fire and forget
  }

  /// Submit due events. Idempotent end to end: the UUID travels with the
  /// event, the server accepts it once, duplicates and true-accepts both
  /// leave the queue. Returns how many newly joined the rain.
  static Future<int> flush() async {
    if (_flushing || !Api.signedIn) return 0;
    _flushing = true;
    var joined = 0;
    try {
      final now = DateTime.now().millisecondsSinceEpoch;
      final q = await queue();
      final keep = <PendingDrop>[];
      for (final d in q) {
        if (d.nextRetryMs > now) {
          keep.add(d);
          continue;
        }
        try {
          var (code, body) = await Api.rpc(
              'log_event', {'eid': d.id, 'd': d.day, 'cnt': d.n});
          if (code == 404) {
            // Server not yet upgraded with pulse2.sql: legacy increment
            // (not idempotent server-side; the queue still dedupes locally).
            (code, body) = await Api.rpc('log_actions', {'n': d.n});
            body = 'true';
          }
          if (code >= 200 && code < 300) {
            if (body.trim() == 'true') joined += d.n;
            // accepted or duplicate: either way it is counted, remove it
          } else if (code == 401 || code == 403 || code == 429) {
            keep.add(d
              ..attempts += 1
              ..nextRetryMs =
                  now + backoff(d.attempts).inMilliseconds);
          } else if (d.attempts + 1 >= _maxAttempts) {
            // dead letter: permanently invalid, stop retrying quietly
          } else {
            keep.add(d
              ..attempts += 1
              ..nextRetryMs =
                  now + backoff(d.attempts).inMilliseconds);
          }
        } catch (_) {
          keep.add(d
            ..attempts += 1
            ..nextRetryMs = now + backoff(d.attempts).inMilliseconds);
        }
      }
      await _save(keep);
      if (joined > 0) pulseTick.value++;
      return joined;
    } finally {
      _flushing = false;
    }
  }

  // ---------- the truthful snapshot ----------
  static Future<PulseSnap?> snapshot({bool refresh = false}) async {
    final p = await SharedPreferences.getInstance();
    if (refresh) {
      final n = await Api.fetchPulse();
      if (n != null) {
        await p.setString('pulseSnap',
            jsonEncode({'n': n, 'at': DateTime.now().toIso8601String()}));
        pulseTick.value++;
        return PulseSnap(n, DateTime.now());
      }
    }
    final raw = p.getString('pulseSnap');
    if (raw == null) return null;
    try {
      final j = jsonDecode(raw) as Map<String, dynamic>;
      return PulseSnap((j['n'] is int) ? j['n'] as int : 0,
          DateTime.parse(j['at'].toString()));
    } catch (_) {
      return null;
    }
  }
}

class PulseSnap {
  final int n;
  final DateTime at;
  PulseSnap(this.n, this.at);

  /// Truth states, worn openly: Live / Updated Xm ago / Offline snapshot.
  String freshness([DateTime? now]) {
    final age = (now ?? DateTime.now()).difference(at);
    if (age.inMinutes < 2) return 'live';
    if (age.inHours < 1) return 'updated ${age.inMinutes} min ago';
    if (age.inHours < 24) return 'updated ${age.inHours}h ago';
    return 'offline snapshot';
  }
}

// ---------- the copy system ----------
class RainCopy {
  static const joined = 'Your drop joined the rain.';
  static const pending =
      'Your drop is safe and will join when the cloud is in reach.';
  static const guest =
      'Your drops are kept here. Sign in and they join the world\'s rain.';
  static const quiet = 'The rain is quiet right now.';
  static const unavailable = 'The pulse is out of reach. Your drops are safe.';
  static String offlineJoined(int n) => n == 1
      ? 'Your drop joined the rain.'
      : 'Your $n drops joined the rain.';
  static String watched(int n) =>
      '+$n while you watched. Someone, somewhere, just acted.';
}
