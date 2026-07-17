// Instant, local, forgiving search over everything the phone already holds:
// species, worlds, facts, actions. No server, no lag, works on a mountain.

import 'content.dart';

class Hit {
  final String kind; // 'species' | 'world' | 'fact' | 'action' | 'journey'
  final String title;
  final String sub;
  final World? world; // owning world (for navigation)
  final Journey? journey; // for journey hits
  final int speciesIndex; // for species hits
  final int score;
  Hit(this.kind, this.title, this.sub, this.world,
      {this.journey, this.speciesIndex = 0, this.score = 0});
}

/// True one-edit tolerance: substitution, insertion, or deletion anywhere
/// ("vaquta" still finds the vaquita).
bool _within1(String a, String b) {
  if ((a.length - b.length).abs() > 1) return false;
  var i = 0, j = 0, edits = 0;
  while (i < a.length && j < b.length) {
    if (a[i] == b[j]) {
      i++;
      j++;
      continue;
    }
    if (++edits > 1) return false;
    if (a.length > b.length) {
      i++;
    } else if (b.length > a.length) {
      j++;
    } else {
      i++;
      j++;
    }
  }
  return edits + (a.length - i) + (b.length - j) <= 1;
}

bool _fuzzy(String haystack, String q) {
  final h = haystack.toLowerCase();
  if (h.contains(q)) return true;
  if (q.length < 4) return false;
  for (final word in h.split(RegExp(r'[^a-z0-9]+'))) {
    if (word.isEmpty) continue;
    if (word.startsWith(q) || _within1(word, q)) return true;
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

  for (final jn in c.journeys) {
    final inTitle = _fuzzy(jn.t, q) || _fuzzy(jn.d, q);
    final inBody = jn.lessons.any((l) => _fuzzy(l.t, q) || _fuzzy(l.body, q));
    if (inTitle || inBody) {
      hits.add(Hit('journey', jn.t, '${jn.badge} ${jn.lessons.length} chapters',
          null,
          journey: jn, score: _score(jn.t, q) + (inTitle ? 8 : -5)));
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
