// Instant, local, forgiving search over everything the phone already holds:
// species, worlds, facts, actions. No server, no lag, works on a mountain.

import 'content.dart';

class Hit {
  final String kind; // 'species' | 'world' | 'fact' | 'action'
  final String title;
  final String sub;
  final World world; // owning world (for navigation)
  final int speciesIndex; // for species hits
  final int score;
  Hit(this.kind, this.title, this.sub, this.world,
      {this.speciesIndex = 0, this.score = 0});
}

/// Small typo tolerance: exact contains, prefix, or one-edit-forgiving
/// word-prefix match ("vaquta" still finds the vaquita).
bool _fuzzy(String haystack, String q) {
  final h = haystack.toLowerCase();
  if (h.contains(q)) return true;
  for (final word in h.split(RegExp(r'[^a-z0-9]+'))) {
    if (word.isEmpty) continue;
    if (q.length >= 4 && word.startsWith(q.substring(0, q.length - 1))) {
      return true;
    }
  }
  return false;
}

int _score(String title, String q) {
  final t = title.toLowerCase();
  if (t == q) return 100;
  if (t.startsWith(q)) return 80;
  if (t.contains(q)) return 60;
  return 30;
}

List<Hit> search(AppContent c, String query) {
  final q = query.trim().toLowerCase();
  if (q.length < 2) return [];
  final hits = <Hit>[];

  for (final w in c.worlds) {
    if (_fuzzy(w.name, q) || _fuzzy(w.sum, q)) {
      hits.add(Hit('world', w.name, w.sum, w, score: _score(w.name, q) + 5));
    }
    for (var i = 0; i < w.species.length; i++) {
      if (_fuzzy(w.species[i], q)) {
        hits.add(Hit('species', w.species[i], '${w.emo} ${w.name}', w,
            speciesIndex: i, score: _score(w.species[i], q) + 10));
      }
    }
    for (final f in w.facts) {
      if (_fuzzy(f[0], q)) {
        hits.add(Hit('fact', f[0], '${w.emo} ${w.name}', w,
            score: _score(f[0], q) - 20));
      }
    }
    for (final slug in w.acts) {
      final a = c.actions[slug];
      if (a != null && _fuzzy(a.t, q)) {
        hits.add(Hit('action', a.t, '${w.emo} ${w.name}', w,
            score: _score(a.t, q) - 10));
      }
    }
  }

  // Dedupe by kind+title, best score first, keep it digestible.
  final seen = <String>{};
  hits.sort((a, b) => b.score.compareTo(a.score));
  return [
    for (final h in hits)
      if (seen.add('${h.kind}|${h.title}')) h
  ].take(30).toList();
}
