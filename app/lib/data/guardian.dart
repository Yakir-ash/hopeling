// Guardianship - "I will not look away from your story."
// State lives in the one save document under the PWA's own key
// (guardian: {id, date}) so it syncs, restores, and migrates for free.
// Archived relationships keep their history under guardianPast; the
// unknown-field engine carries both everywhere. Never ownership, never
// a pet, never a badge: a relationship the user chose.

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../core/clock.dart';
import 'content.dart';
import 'save.dart';

class Guardianship {
  static Map<String, dynamic>? active(Save s) {
    final g = s.extra['guardian'];
    return g is Map ? g.map((k, v) => MapEntry(k.toString(), v)) : null;
  }

  static String? activeId(Save s) => active(s)?['id']?.toString();
  static String since(Save s) => (active(s)?['date'] ?? '').toString();

  static List<Map<String, dynamic>> past(Save s) {
    final p = s.extra['guardianPast'];
    if (p is! List) return [];
    return p
        .whereType<Map>()
        .map((e) => e.map((k, v) => MapEntry(k.toString(), v)))
        .toList();
  }

  /// Begin a relationship. Idempotent: choosing your current guardian
  /// again changes nothing. Choosing another archives the current one
  /// first, with its history intact.
  static bool begin(Save s, String id, String today) {
    if (activeId(s) == id) return false; // already walking together
    if (active(s) != null) archive(s, today);
    // restore from the past if it was archived before: history continues
    final p = past(s);
    final old = p.where((e) => e['id'] == id).toList();
    final firstDate =
        old.isNotEmpty ? (old.first['date'] ?? today).toString() : today;
    p.removeWhere((e) => e['id'] == id);
    s.extra['guardianPast'] = p;
    s.extra['guardian'] = {'id': id, 'date': firstDate};
    return true;
  }

  /// Archive without shame: the relationship becomes part of history,
  /// letters remain readable, and it can always be restored.
  static void archive(Save s, String today) {
    final g = active(s);
    if (g == null) return;
    final p = past(s);
    p.insert(0, {...g, 'end': today});
    s.extra['guardianPast'] = p;
    s.extra['guardian'] = null;
  }

  static bool restore(Save s, String id, String today) =>
      past(s).any((e) => e['id'] == id) && begin(s, id, today);
}

// ---------- letters: curated dispatches, never talking animals ----------
class GuardianLetter {
  final String category; // welcome | quiet | ...
  final String title;
  final String opening;
  final String body;
  final String why;
  final List<String> sources;
  final String? actionSlug;
  GuardianLetter(this.category, this.title, this.opening, this.body,
      this.why, this.sources, this.actionSlug);
}

/// The welcome letter: built from the canonical content, sourced,
/// available offline the moment the relationship begins.
GuardianLetter welcomeLetter(GuardianDef g, World? w) {
  final sources = <String>[
    'Wikipedia: ${g.wiki.isNotEmpty ? g.wiki : g.name} (CC BY-SA)',
  ];
  if (w != null) {
    for (final t in w.threats) {
      if (t.length > 2 && t[2].isNotEmpty) sources.add(t[2]);
    }
    for (final f in w.facts) {
      if (f.length > 1 && f[1].isNotEmpty) sources.add(f[1]);
    }
  }
  return GuardianLetter(
    'welcome',
    'A letter from the world of the ${g.name.toLowerCase()}',
    'You chose to keep paying attention. This is where their story stands.',
    g.story,
    g.count,
    sources.toSet().take(4).toList(),
    (w != null && w.acts.isNotEmpty) ? w.acts.first : null,
  );
}

// ---------- the private record of attention ----------
Future<List<Map<String, String>>> timelineFor(String id) async {
  final p = await SharedPreferences.getInstance();
  final raw = p.getString('gtl_$id');
  if (raw == null) return [];
  try {
    return (jsonDecode(raw) as List)
        .map((e) =>
            (e as Map).map((k, v) => MapEntry(k.toString(), v.toString())))
        .toList();
  } catch (_) {
    return [];
  }
}

/// Presence only. There is no entry type for absence, by design.
Future<void> addTimeline(String id, String kind) async {
  final p = await SharedPreferences.getInstance();
  final list = await timelineFor(id);
  final today = todayStr();
  if (list.any((e) => e['k'] == kind && e['d'] == today)) return;
  list.insert(0, {'k': kind, 'd': today});
  await p.setString('gtl_$id', jsonEncode(list.take(60).toList()));
}

Future<String> guardianReflection(String id) async {
  final p = await SharedPreferences.getInstance();
  return p.getString('gnote_$id') ?? '';
}

Future<void> saveGuardianReflection(String id, String text) async {
  final p = await SharedPreferences.getInstance();
  await p.setString('gnote_$id', text);
}

// ---------- the copy, constitutionally non-owning ----------
class GCopy {
  static const explanation =
      'Becoming a Guardian does not mean owning or rescuing this animal. '
      'It means choosing to stay connected to its story - learning, '
      'noticing changes, and taking small actions when they matter. '
      'It is free, it is not a donation, and you can step back anytime. '
      'Updates come from credible sources, at a gentle pace you control.';
  static const holdLabel = 'Keep this species close';
  static String began(String name) =>
      'You began following the story of the $name.';
  static const archiveTitle = 'Archive this relationship';
  static const archiveBody =
      'Its history and letters stay with you, and you can return to it '
      'anytime. Nothing is lost.';
  static const archived =
      'The relationship rests in your history. It will be here.';
  static String anniversary(String name, String date) =>
      'Walking with the $name since $date.';
  static const reflectionPrompt = 'Why did you choose them?';
  static const timelineKinds = {
    'began': 'You began the relationship',
    'letter': 'You read a letter',
    'reflection': 'You wrote a reflection',
    'action': 'You acted for their world',
  };
}
