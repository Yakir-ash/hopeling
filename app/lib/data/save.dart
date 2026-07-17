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

const _known = {
  '_app', '_exported', 'xp', 'streak', 'last', 'freezes', 'log',
  'rings', 'lastRepair', 'milestones'
};

class Save {
  int xp;
  int streak;
  String last; // YYYY-MM-DD of last action day, '' if never
  int freezes;
  Map<String, int> log; // day -> actions count
  List<Map<String, dynamic>> rings; // [{n, end}] newest first, cap 24
  String lastRepair; // day a repair was last used, '' if never
  Map<String, dynamic> milestones; // friend7: 1, ...
  /// Everything else in the Contract-1 document, preserved verbatim:
  /// badges, totals, done, causes, guardian...
  Map<String, dynamic> extra;

  Save(
      {this.xp = 0,
      this.streak = 0,
      this.last = '',
      this.freezes = 0,
      Map<String, int>? log,
      List<Map<String, dynamic>>? rings,
      this.lastRepair = '',
      Map<String, dynamic>? milestones,
      Map<String, dynamic>? extra})
      : log = log ?? {},
        rings = rings ?? [],
        milestones = milestones ?? {},
        extra = extra ?? {};

  bool doneOn(String day) => (log[day] ?? 0) > 0;

  /// Anything worth protecting in a merge?
  bool get meaningful => xp > 0 || log.isNotEmpty || extra.isNotEmpty;

  Map<String, dynamic> toJson() => {
        ...extra,
        '_app': 'Hopeling',
        '_exported': DateTime.now().toIso8601String(),
        'xp': xp,
        'streak': streak,
        'last': last.isEmpty ? null : last,
        'freezes': freezes,
        'log': log,
        'rings': rings,
        'lastRepair': lastRepair.isEmpty ? null : lastRepair,
        'milestones': milestones,
      };

  factory Save.fromJson(Map<String, dynamic> j) {
    final extra = <String, dynamic>{};
    j.forEach((k, v) {
      if (!_known.contains(k)) extra[k] = v;
    });
    final lastRaw = j['last'];
    final repRaw = j['lastRepair'];
    return Save(
      xp: (j['xp'] is int) ? j['xp'] as int : 0,
      streak: (j['streak'] is int) ? j['streak'] as int : 0,
      last: (lastRaw == null) ? '' : lastRaw.toString(),
      freezes: (j['freezes'] is int) ? j['freezes'] as int : 0,
      log: ((j['log'] as Map<String, dynamic>?) ?? {})
          .map((k, v) => MapEntry(k, (v is int) ? v : 0)),
      rings: ((j['rings'] as List?) ?? [])
          .whereType<Map>()
          .map((r) => r.map((k, v) => MapEntry(k.toString(), v)))
          .toList(),
      lastRepair: (repRaw == null) ? '' : repRaw.toString(),
      milestones: (j['milestones'] as Map<String, dynamic>?) ?? {},
      extra: extra,
    );
  }

  /// Deterministic, idempotent conflict resolution: nothing earned is lost.
  /// - a fresh local yields wholly to the cloud
  /// - max of counters, later of dates, day-wise max of logs
  /// - rings: union by (n, end), newest first, cap 24 - never deleted
  /// - milestones: union (a friend earned anywhere is earned everywhere)
  /// - repaired state (later lastRepair) is preserved
  static Save merge(Save local, Save cloud) {
    if (!local.meaningful) return cloud;
    if (!cloud.meaningful) return local;
    final log = <String, int>{...cloud.log};
    local.log.forEach((d, n) {
      log[d] = (log[d] ?? 0) > n ? log[d]! : n;
    });
    final ringKeys = <String>{};
    final rings = <Map<String, dynamic>>[];
    for (final r in [...local.rings, ...cloud.rings]) {
      final k = '${r['n']}|${r['end']}';
      if (ringKeys.add(k)) rings.add(r);
    }
    rings.sort((a, b) =>
        (b['end'] ?? '').toString().compareTo((a['end'] ?? '').toString()));
    final extra = <String, dynamic>{...local.extra, ...cloud.extra};
    return Save(
      xp: local.xp > cloud.xp ? local.xp : cloud.xp,
      streak: local.streak > cloud.streak ? local.streak : cloud.streak,
      last: local.last.compareTo(cloud.last) > 0 ? local.last : cloud.last,
      freezes:
          local.freezes > cloud.freezes ? local.freezes : cloud.freezes,
      log: log,
      rings: rings.take(24).toList(),
      lastRepair: local.lastRepair.compareTo(cloud.lastRepair) > 0
          ? local.lastRepair
          : cloud.lastRepair,
      milestones: {...local.milestones, ...cloud.milestones},
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
