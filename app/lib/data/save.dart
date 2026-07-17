// The Save: one JSON document in Contract-1 shape (FLUTTER-CONTRACTS.md).
// Local-first. The same shape flows to Supabase saves.data, which makes
// PWA restore, native backup, and multi-device one code path.
//
// THE MIGRATION ENGINE RULE: this class carries every field of the
// document, even ones this app version does not understand yet (`extra`).
// Restore, merge, and re-upload round-trip losslessly - so every future
// feature that writes into the document restores automatically, forever,
// with zero special-case migration code.

import 'dart:convert';

import 'package:flutter/foundation.dart' show ValueNotifier;
import 'package:shared_preferences/shared_preferences.dart';

import '../core/clock.dart';

/// Bumps when the save changes from outside the grove (restore, merge).
final saveTick = ValueNotifier<int>(0);

const _known = {'_app', '_exported', 'xp', 'streak', 'last', 'freezes', 'log'};

class Save {
  int xp;
  int streak;
  String last; // YYYY-MM-DD of last action day, '' if never
  int freezes;
  Map<String, int> log; // day -> actions count
  /// Everything else in the Contract-1 document, preserved verbatim:
  /// badges, totals, done, causes, guardian, rings, milestones...
  Map<String, dynamic> extra;

  Save(
      {this.xp = 0,
      this.streak = 0,
      this.last = '',
      this.freezes = 0,
      Map<String, int>? log,
      Map<String, dynamic>? extra})
      : log = log ?? {},
        extra = extra ?? {};

  bool doneOn(String day) => (log[day] ?? 0) > 0;

  /// Anything worth protecting in a merge?
  bool get meaningful => xp > 0 || log.isNotEmpty || extra.isNotEmpty;

  /// Complete one action "today". Returns true if first of the day.
  bool complete([DateTime? now]) {
    final t = todayStr(now);
    final first = last != t;
    if (first) {
      // Forgiveness, slice-1 form: a gap never resets. The tree rested.
      streak += 1;
      last = t;
    }
    xp += 1;
    log[t] = (log[t] ?? 0) + 1;
    return first;
  }

  Map<String, dynamic> toJson() => {
        ...extra,
        '_app': 'Hopeling',
        '_exported': DateTime.now().toIso8601String(),
        'xp': xp,
        'streak': streak,
        'last': last.isEmpty ? null : last,
        'freezes': freezes,
        'log': log,
      };

  factory Save.fromJson(Map<String, dynamic> j) {
    final extra = <String, dynamic>{};
    j.forEach((k, v) {
      if (!_known.contains(k)) extra[k] = v;
    });
    final lastRaw = j['last'];
    return Save(
      xp: (j['xp'] is int) ? j['xp'] as int : 0,
      streak: (j['streak'] is int) ? j['streak'] as int : 0,
      last: (lastRaw == null) ? '' : lastRaw.toString(),
      freezes: (j['freezes'] is int) ? j['freezes'] as int : 0,
      log: ((j['log'] as Map<String, dynamic>?) ?? {})
          .map((k, v) => MapEntry(k, (v is int) ? v : 0)),
      extra: extra,
    );
  }

  /// Deterministic conflict resolution: nothing earned is ever lost.
  /// - a fresh local yields wholly to the cloud
  /// - otherwise: max of counters, later of dates, day-wise max of logs,
  ///   cloud's extra as the base (it is the older, richer life) with local
  ///   extra keys kept when the cloud lacks them.
  static Save merge(Save local, Save cloud) {
    if (!local.meaningful) return cloud;
    if (!cloud.meaningful) return local;
    final log = <String, int>{...cloud.log};
    local.log.forEach((d, n) {
      log[d] = (log[d] ?? 0) > n ? log[d]! : n;
    });
    final extra = <String, dynamic>{...local.extra, ...cloud.extra};
    return Save(
      xp: local.xp > cloud.xp ? local.xp : cloud.xp,
      streak: local.streak > cloud.streak ? local.streak : cloud.streak,
      last: local.last.compareTo(cloud.last) > 0 ? local.last : cloud.last,
      freezes:
          local.freezes > cloud.freezes ? local.freezes : cloud.freezes,
      log: log,
      extra: extra,
    );
  }
}

class Store {
  static const _key = 'save';

  static Future<Save> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return Save();
    try {
      return Save.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return Save();
    }
  }

  static Future<void> persist(Save s) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(s.toJson()));
  }
}
