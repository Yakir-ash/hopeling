// The Field Guide of Mine - V2's progression system. Not points:
// pages. Every path chapter walked writes a Field Note; every
// species met (in the Atlas, a game, or a story) becomes a page.
// It can only grow. Nothing here ever decays, expires, or scolds.

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class FieldNote {
  final String chapterId;
  final String pathId;
  final int day; // days since epoch, enough to say "March, year one"
  const FieldNote(this.chapterId, this.pathId, this.day);

  Map<String, dynamic> toJson() =>
      {'c': chapterId, 'p': pathId, 'd': day};
  static FieldNote fromJson(Map<String, dynamic> j) => FieldNote(
      (j['c'] ?? '').toString(),
      (j['p'] ?? '').toString(),
      (j['d'] ?? 0) as int);
}

int _today() =>
    DateTime.now().difference(DateTime(2020, 1, 1)).inDays;

class FieldGuide {
  /// All earned notes, oldest first.
  static Future<List<FieldNote>> notes() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString('fieldNotes');
    if (raw == null) return [];
    try {
      return [
        for (final j in (jsonDecode(raw) as List))
          FieldNote.fromJson(j as Map<String, dynamic>)
      ];
    } catch (_) {
      return [];
    }
  }

  static Future<Set<String>> earnedChapterIds() async =>
      {for (final n in await notes()) n.chapterId};

  /// Walk a chapter: writes its note. Honest by design - the tap
  /// says "I looked", and we believe people. Idempotent.
  static Future<void> earn(String pathId, String chapterId) async {
    final p = await SharedPreferences.getInstance();
    final all = await notes();
    if (all.any((n) => n.chapterId == chapterId)) return;
    all.add(FieldNote(chapterId, pathId, _today()));
    await p.setString('fieldNotes',
        jsonEncode([for (final n in all) n.toJson()]));
  }

  /// Species met anywhere - the Atlas, a game ending, a story.
  static Future<Set<String>> metSpecies() async {
    final p = await SharedPreferences.getInstance();
    return (p.getStringList('metSpecies') ?? []).toSet();
  }

  static Future<void> meet(String speciesId) async {
    final p = await SharedPreferences.getInstance();
    final met = (p.getStringList('metSpecies') ?? []).toSet();
    if (met.add(speciesId)) {
      await p.setStringList('metSpecies', met.toList()..sort());
    }
  }

  /// Mystery verdicts: which mysteries were solved (guessed at
  /// all - a wrong guess still earns the story, because the story
  /// is the point).
  static Future<Set<String>> solvedMysteries() async {
    final p = await SharedPreferences.getInstance();
    return (p.getStringList('solvedMysteries') ?? []).toSet();
  }

  static Future<void> solveMystery(String id) async {
    final p = await SharedPreferences.getInstance();
    final s = (p.getStringList('solvedMysteries') ?? []).toSet();
    if (s.add(id)) {
      await p.setStringList('solvedMysteries', s.toList()..sort());
    }
  }

  /// The guess made for a mystery (index), or null.
  static Future<int?> mysteryGuess(String id) async {
    final p = await SharedPreferences.getInstance();
    final v = p.getInt('mystGuess_$id');
    return v;
  }

  static Future<void> setMysteryGuess(String id, int guess) async {
    final p = await SharedPreferences.getInstance();
    await p.setInt('mystGuess_$id', guess);
    await solveMystery(id);
  }
}

/// A gentle sentence about how far the guide has come - for the
/// guide's own cover. Never a score, always a story.
String guideLine(int noteCount, int speciesCount, int mysteryCount) {
  if (noteCount == 0 && speciesCount == 0 && mysteryCount == 0) {
    return 'Every field guide begins empty. The first page is one '
        'noticing away.';
  }
  final parts = <String>[
    if (noteCount > 0)
      '$noteCount field note${noteCount == 1 ? '' : 's'} walked',
    if (speciesCount > 0)
      '$speciesCount neighbor${speciesCount == 1 ? '' : 's'} met',
    if (mysteryCount > 0)
      '$mysteryCount myster${mysteryCount == 1 ? 'y' : 'ies'} '
          'solved',
  ];
  return 'So far: ${parts.join(', ')}. The guide only ever grows.';
}
