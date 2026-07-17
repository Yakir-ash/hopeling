// The Save: one JSON document in Contract-1 shape (FLUTTER-CONTRACTS.md).
// Local-first. The same shape flows to Supabase saves.data, which makes
// PWA restore, native backup, and multi-device one code path.
//
// Slice 1 carries the core fields; the full forgiveness engine (freezes,
// repair, rings) is slice 4, with the sim suite as the oracle. Until then
// one rule is already law: THE STREAK NEVER DIES. It rests.

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../core/clock.dart';

class Save {
  int xp;
  int streak;
  String last; // YYYY-MM-DD of last action day, '' if never
  int freezes;
  Map<String, int> log; // day -> actions count

  Save({this.xp = 0, this.streak = 0, this.last = '', this.freezes = 0, Map<String, int>? log})
      : log = log ?? {};

  bool doneOn(String day) => (log[day] ?? 0) > 0;

  /// Complete one action "today". Returns true if this was the first of the day
  /// (the streak day), false if it was an extra drop.
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
        '_app': 'Hopeling',
        '_exported': DateTime.now().toIso8601String(),
        'xp': xp,
        'streak': streak,
        'last': last.isEmpty ? null : last,
        'freezes': freezes,
        'log': log,
      };

  factory Save.fromJson(Map<String, dynamic> j) => Save(
        xp: (j['xp'] is int) ? j['xp'] as int : 0,
        streak: (j['streak'] is int) ? j['streak'] as int : 0,
        last: (j['last'] ?? '').toString() == 'null' ? '' : (j['last'] ?? '').toString(),
        freezes: (j['freezes'] is int) ? j['freezes'] as int : 0,
        log: ((j['log'] as Map<String, dynamic>?) ?? {})
            .map((k, v) => MapEntry(k, (v is int) ? v : 0)),
      );
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
