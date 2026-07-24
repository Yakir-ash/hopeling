// Memory Meadow vs the constitution: the pairs ARE the ecology
// (animal to home, never twin to twin), decks deal deterministically
// per round at every size, and the copy never scores or scolds.

import 'package:flutter_test/flutter_test.dart';

import 'package:hopeling/features/kids/games/memory_meadow.dart';

void main() {
  test('the deck deals complete and deterministic at every size', () {
    for (final pairs in [4, 6, 8]) {
      final a = meadowDeck(7, pairs: pairs);
      expect(a.length, pairs * 2);
      expect(a.map((c) => '${c.pair}:${c.isHome}').toList(),
          meadowDeck(7, pairs: pairs)
              .map((c) => '${c.pair}:${c.isHome}')
              .toList());
      for (var p = 0; p < pairs; p++) {
        final cards = a.where((c) => c.pair == p).toList();
        expect(cards.length, 2);
        expect(cards.where((c) => c.isHome).length, 1);
      }
    }
  });

  test('an animal matches its home, never its twin', () {
    const fox = MeadowCard(0, false, '🦊', 'Fox');
    const den = MeadowCard(0, true, '🕳️', 'Den');
    const fox2 = MeadowCard(0, false, '🦊', 'Fox');
    const nest = MeadowCard(1, true, '🪺', 'Nest');
    expect(meadowMatch(fox, den), true);
    expect(meadowMatch(fox, fox2), false); // twins are not a match
    expect(meadowMatch(fox, nest), false); // wrong home
  });

  test('the meadow copy never scores or scolds', () {
    for (final line in [
      MeadowCopy.intro, MeadowCopy.done, MeadowCopy.fact,
    ]) {
      for (final bad in [
        'wrong', 'score', 'points', 'fail', 'hurry', 'game over'
      ]) {
        expect(line.toLowerCase().contains(bad), false);
      }
    }
  });
}
