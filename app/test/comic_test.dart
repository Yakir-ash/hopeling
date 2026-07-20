// Comic books vs the constitution: a book, not a slot machine - same
// story, same panels, same host, every time; not one word of the lesson
// dropped or invented; nothing scary in the cast; no reward economy at
// the end.

import 'package:flutter_test/flutter_test.dart';

import 'package:hopeling/data/content.dart';
import 'package:hopeling/features/kids/comic.dart';

Lesson _l(String t, String body) => Lesson(t, 3, '', body, const []);

void main() {
  test('panels are deterministic: same story, same book', () {
    final a = comicPanels(_l('The Busy Bees', 'One. Two. Three.'));
    final b = comicPanels(_l('The Busy Bees', 'One. Two. Three.'));
    expect(a.length, b.length);
    for (var i = 0; i < a.length; i++) {
      expect(a[i].seed, b[i].seed);
      expect(a[i].caption, b[i].caption);
    }
  });

  test('a book has a cover, scenes, and an end', () {
    final p = comicPanels(_l('The River', 'Rivers move. Fish swim home.'));
    expect(p.first.kind, 'cover');
    expect(p.first.caption, 'The River');
    expect(p.last.kind, 'end');
    expect(p.where((x) => x.kind == 'scene').isNotEmpty, true);
  });

  test('not one word is dropped, however long the story', () {
    final sentences =
        List.generate(30, (i) => 'Sentence number $i is here.');
    final caps = comicCaptions(sentences.join(' '));
    expect(caps.length, lessThanOrEqualTo(10));
    for (var i = 0; i < 30; i++) {
      expect(caps.join(' ').contains('Sentence number $i is here.'), true);
    }
  });

  test('short stories get roomy pages, one or two sentences each', () {
    final caps = comicCaptions('The sea is big. Whales sing. Kelp sways. '
        'Otters float. Crabs walk sideways.');
    expect(caps.length, greaterThanOrEqualTo(3));
    for (final c in caps) {
      expect(RegExp(r'[.!?]').allMatches(c).length, lessThanOrEqualTo(2));
    }
  });

  test('the host fits the story and never changes narrators', () {
    expect(comicHost('Why the ocean matters', 'The sea is home.'), '🐋');
    expect(comicHost('Busy pollinators', 'Bees visit flowers.'), '🐝');
    expect(comicHost('Rivers of life', 'A river runs.'), '🐸');
    final h1 = comicHost('A Story With No Keywords', 'Plain words.');
    final h2 = comicHost('A Story With No Keywords', 'Plain words.');
    expect(h1, h2); // deterministic fallback
    expect(['🦊', '🐢', '🐿️', '🦔', '🐇'].contains(h1), true);
  });

  test('every book lives in one fitting world', () {
    expect(sceneOf('Why the ocean matters', 'The sea is home.'),
        ComicScene.ocean);
    expect(sceneOf('Busy pollinators', 'Bees visit flowers.'),
        ComicScene.meadow);
    expect(sceneOf('The old forest', 'Trees talk underground.'),
        ComicScene.forest);
    expect(sceneOf('Who flies at night', 'Bats eat moths.'),
        ComicScene.night);
    expect(sceneOf('Life on the ice', 'Polar summers.'), ComicScene.ice);
    expect(sceneOf('Rivers of life', 'A river runs.'), ComicScene.river);
    // deterministic, gentle fallback: never the night or the ice
    final f1 = sceneOf('A Story With No Keywords', 'Plain words.');
    final f2 = sceneOf('A Story With No Keywords', 'Plain words.');
    expect(f1, f2);
    expect(
        [ComicScene.meadow, ComicScene.forest, ComicScene.river]
            .contains(f1),
        true);
  });

  test('a page breaks into beats without losing a word', () {
    expect(panelChunks('One sentence only.'), ['One sentence only.']);
    final two = panelChunks('The sea is big. Whales sing in it.');
    expect(two.length, 2);
    expect(two[0], 'The sea is big.');
    expect(two[1], 'Whales sing in it.');
    final packed =
        panelChunks('First. Second. Third. Fourth.');
    expect(packed.length, 2);
    expect(packed.join(' '), 'First. Second. Third. Fourth.');
  });

  test('sound effects are scene-true, gentle, and deterministic', () {
    expect(soundFor(ComicScene.ocean, 3), soundFor(ComicScene.ocean, 3));
    for (final s in ComicScene.values) {
      for (var seed = 0; seed < 6; seed++) {
        final w = soundFor(s, seed).toLowerCase();
        for (final bad in ['bang', 'boom', 'crash', 'pow', 'smash']) {
          expect(w.contains(bad), false);
        }
      }
    }
  });

  test('empty stories make no book', () {
    expect(comicPanels(_l('Untitled', '   ')), isEmpty);
  });

  test('the end page closes gently - no rewards, no pressure', () {
    final end = comicPanels(_l('The River', 'Rivers move.')).last;
    for (final bad in [
      'buy', 'unlock', 'streak', 'points', 'prize',
      'come back', 'waiting for you', 'don\'t stop'
    ]) {
      expect(end.caption.toLowerCase().contains(bad), false);
    }
  });
}
