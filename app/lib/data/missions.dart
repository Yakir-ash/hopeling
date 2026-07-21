// Missions - participation without surveillance. Missions ride the
// content contract (editorially owned, additive, ignored by older
// clients). Eligibility and lifecycle live in one engine; observations
// are protocol-shaped, previewed before submission, savable privately,
// queued idempotently on the Rain pattern; there is no location code in
// this file because none is collected. One completed mission = one
// equal rain drop, never two.

import 'dart:convert';

import 'package:flutter/foundation.dart' show ValueNotifier;
import 'package:shared_preferences/shared_preferences.dart';

import '../core/clock.dart';
import 'api.dart';
import 'content.dart';
import 'pulse.dart';
import 'rules.dart' as rules;
import 'save.dart';

final missionTick = ValueNotifier<int>(0);

// ---------- domain ----------
class ProtocolField {
  final String k, label, kind; // count | choice | note
  final List<String> opts;
  ProtocolField(this.k, this.label, this.kind, this.opts);
}

class Mission {
  final String id, t, type, sum, desc, supervision, dataUse, verified, status;
  final List<String> cats, safety, steps, sources;
  final List<int> months; // empty = all year
  final int min;
  final bool family;
  final List<ProtocolField> protocol;
  Mission(
      this.id, this.t, this.type, this.sum, this.desc, this.supervision,
      this.dataUse, this.verified, this.status, this.cats, this.safety,
      this.steps, this.sources, this.months, this.min, this.family,
      this.protocol);

  factory Mission.fromJson(Map<String, dynamic> j) => Mission(
        (j['id'] ?? '').toString(),
        (j['t'] ?? '').toString(),
        (j['type'] ?? 'observe').toString(),
        (j['sum'] ?? '').toString(),
        (j['desc'] ?? '').toString(),
        (j['supervision'] ?? 'none').toString(),
        (j['dataUse'] ?? '').toString(),
        (j['verified'] ?? '').toString(),
        (j['status'] ?? 'approved').toString(),
        ((j['cats'] as List?) ?? []).map((e) => e.toString()).toList(),
        ((j['safety'] as List?) ?? []).map((e) => e.toString()).toList(),
        ((j['steps'] as List?) ?? []).map((e) => e.toString()).toList(),
        ((j['sources'] as List?) ?? []).map((e) => e.toString()).toList(),
        ((j['months'] as List?) ?? [])
            .map((e) => (e is int) ? e : int.tryParse('$e') ?? 0)
            .toList(),
        (j['min'] is int) ? j['min'] as int : 15,
        j['family'] == true,
        ((j['protocol'] as List?) ?? []).map((p) {
          final m = asStrMap(p);
          return ProtocolField(
              (m['k'] ?? '').toString(),
              (m['label'] ?? '').toString(),
              (m['kind'] ?? 'count').toString(),
              ((m['opts'] as List?) ?? [])
                  .map((e) => e.toString())
                  .toList());
        }).toList(),
      );
}

List<Mission>? _missionCache;
bool _cacheHooked = false;

Future<List<Mission>> loadMissions() async {
  // Fresh content means fresh missions, wherever missions are read from -
  // not only while the missions screen happens to be open.
  if (!_cacheHooked) {
    _cacheHooked = true;
    contentTick.addListener(invalidateMissionCache);
  }
  if (_missionCache != null) return _missionCache!;
  final p = await SharedPreferences.getInstance();
  final raw = p.getString('contentCache');
  if (raw == null) return const [];
  try {
    final doc = jsonDecode(raw) as Map<String, dynamic>;
    _missionCache = ((doc['missions'] as List?) ?? [])
        .map((e) => Mission.fromJson(asStrMap(e)))
        .toList();
  } catch (_) {
    _missionCache = const [];
  }
  return _missionCache!;
}

void invalidateMissionCache() => _missionCache = null;

// ---------- eligibility: one engine, explainable answers ----------
enum MissionFit {
  eligible,
  needsAdult,
  outOfSeason,
  stale,
  notApproved,
  notForKids,
}

const staleAfterDays = 180;

MissionFit missionFit(Mission m, DateTime now, {bool kidsMode = false}) {
  if (m.status != 'approved') return MissionFit.notApproved;
  if (m.verified.isNotEmpty &&
      daysBetween(m.verified, todayStr(now)) > staleAfterDays) {
    return MissionFit.stale;
  }
  if (m.months.isNotEmpty && !m.months.contains(now.month)) {
    return MissionFit.outOfSeason;
  }
  if (kidsMode) {
    if (!m.family) return MissionFit.notForKids;
    if (m.supervision != 'none') return MissionFit.needsAdult;
  }
  return m.supervision != 'none'
      ? MissionFit.eligible // adults see the supervision note, not a block
      : MissionFit.eligible;
}

String freshnessLine(Mission m, DateTime now) {
  if (m.verified.isEmpty) return '';
  final age = daysBetween(m.verified, todayStr(now));
  if (age > staleAfterDays) {
    return 'Last verified ${m.verified} - please confirm details before relying on this.';
  }
  return 'verified ${m.verified}';
}

// ---------- participation: typed states, device-local ----------
// discovered -> saved? -> started -> drafted -> completedPrivate |
// submitted(queued) -> completedSubmitted. Rain fires exactly once,
// at first completion, guarded by state.
class Participation {
  String state; // none|saved|started|drafted|completedPrivate|completedSubmitted
  String startedDay;
  Map<String, dynamic> draft;
  bool rained;
  Participation(
      {this.state = 'none',
      this.startedDay = '',
      Map<String, dynamic>? draft,
      this.rained = false})
      : draft = draft ?? {};

  Map<String, dynamic> toJson() =>
      {'s': state, 'd': startedDay, 'o': draft, 'r': rained};
  factory Participation.fromJson(Map<String, dynamic> j) => Participation(
      state: (j['s'] ?? 'none').toString(),
      startedDay: (j['d'] ?? '').toString(),
      draft: asStrMap(j['o']),
      rained: j['r'] == true);
}

class MissionStore {
  static Future<Map<String, Participation>> all() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString('missionState');
    if (raw == null) return {};
    try {
      return (jsonDecode(raw) as Map).map((k, v) =>
          MapEntry(k.toString(), Participation.fromJson(asStrMap(v))));
    } catch (_) {
      return {};
    }
  }

  static Future<Participation> of(String id) async =>
      (await all())[id] ?? Participation();

  static Future<void> put(String id, Participation part) async {
    final p = await SharedPreferences.getInstance();
    final m = await all();
    m[id] = part;
    await p.setString('missionState',
        jsonEncode(m.map((k, v) => MapEntry(k, v.toJson()))));
    missionTick.value++;
  }
}

/// The one rain guard: first completion of a mission adds one drop, ever.
/// And an equal drop is equal everywhere: the first completion also
/// counts in your own grove - the day is logged, the streak is touched,
/// the tree grows - exactly once, through the same forgiveness rules as
/// any action. Submitting later never double-credits.
Future<void> completeMission(String id, Participation part,
    {required bool submitted}) async {
  part.state = submitted ? 'completedSubmitted' : 'completedPrivate';
  if (!part.rained) {
    part.rained = true;
    final s = await Store.load();
    rules.complete(s, todayStr());
    await Store.persist(s);
    if (Api.signedIn) Api.pushSave(s.toJson());
    saveTick.value++;
    await Pulse.add();
  }
  await MissionStore.put(id, part);
}

// ---------- the observation queue (Rain's pattern, own lane) ----------
class PendingObservation {
  final String id; // idempotency key, forever
  final String missionId;
  final String day;
  final Map<String, dynamic> payload; // protocol fields ONLY, never notes
  int attempts;
  int nextRetryMs;
  PendingObservation(this.id, this.missionId, this.day, this.payload,
      {this.attempts = 0, this.nextRetryMs = 0});

  Map<String, dynamic> toJson() => {
        'id': id, 'm': missionId, 'day': day, 'p': payload,
        'a': attempts, 'r': nextRetryMs
      };
  factory PendingObservation.fromJson(Map<String, dynamic> j) =>
      PendingObservation((j['id'] ?? '').toString(),
          (j['m'] ?? '').toString(), (j['day'] ?? '').toString(),
          asStrMap(j['p']),
          attempts: (j['a'] is int) ? j['a'] as int : 0,
          nextRetryMs: (j['r'] is int) ? j['r'] as int : 0);
}

class ObsQueue {
  static const _key = 'obsQueue';
  static bool _flushing = false;

  static Future<List<PendingObservation>> all() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_key);
    if (raw == null) return [];
    try {
      return (jsonDecode(raw) as List)
          .map((e) => PendingObservation.fromJson(asStrMap(e)))
          .where((o) => o.id.isNotEmpty)
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> _save(List<PendingObservation> q) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(
        _key, jsonEncode(q.take(100).map((o) => o.toJson()).toList()));
  }

  /// The payload is exactly what the preview showed: protocol fields only.
  static Future<void> enqueue(String missionId,
      Map<String, dynamic> protocolPayload) async {
    final q = await all();
    q.add(PendingObservation(
        uuid4(), missionId, todayStr(), protocolPayload));
    await _save(q);
    missionTick.value++;
    flush();
  }

  static Future<int> flush() async {
    if (_flushing || !Api.signedIn) return 0;
    _flushing = true;
    var accepted = 0;
    try {
      final now = DateTime.now().millisecondsSinceEpoch;
      final q = await all();
      final keep = <PendingObservation>[];
      for (final o in q) {
        if (o.nextRetryMs > now) {
          keep.add(o);
          continue;
        }
        try {
          final (code, body) = await Api.rpc('submit_observation', {
            'oid': o.id, 'mid': o.missionId, 'd': o.day, 'body': o.payload
          });
          if (code >= 200 && code < 300) {
            if (body.trim() == 'true') accepted++;
            // accepted or duplicate: either way it rests
          } else if (o.attempts + 1 >= 8) {
            // dead letter, quietly
          } else {
            keep.add(o
              ..attempts += 1
              ..nextRetryMs = now + backoff(o.attempts).inMilliseconds);
          }
        } catch (_) {
          keep.add(o
            ..attempts += 1
            ..nextRetryMs = now + backoff(o.attempts).inMilliseconds);
        }
      }
      await _save(keep);
      if (accepted > 0) missionTick.value++;
      return accepted;
    } finally {
      _flushing = false;
    }
  }
}

// ---------- copy: practical, never heroic ----------
class MissionCopy {
  static const intro =
      'Real, small ways to take part in the living world - from a window, '
      'a street, a porch. Hopeling never asks where you are: missions are '
      'chosen by season and by you, not by tracking.';
  static const noLocation =
      'No GPS, ever, in missions. Season and your own choices do the work.';
  static const privateSaved =
      'Kept privately in your mission history. Nothing left your phone.';
  static const submitted = 'Your observation joined the archive.';
  static const pendingOffline =
      'Your observation is safe and will join when the cloud is in reach.';
  static const guest =
      'Observations need an account to travel. Yours is kept here meanwhile.';
  static const previewTitle = 'Exactly what will be shared';
  static const previewNote =
      'Only the fields below leave your phone. Your private note stays '
      'private. No location is attached - none was collected.';
  static const historyEmpty =
      'Your field record starts with your first mission.';
  static String outOfSeason(Mission m) =>
      'Sleeping until its season returns.';
}
