// Memory Meadow and Firefly Night vs the constitution: the pairs ARE
// the ecology (animal to home, never twin to twin), decks deal
// deterministically per round, light fades honestly, and neither game
// ever scores, scolds, or hurries.

import 'package:flutter_test/flutter_test.dart';

import 'package:hopeling/features/kids/games/firefly_night.dart';
import 'package:hopeling/features/kids/games/memory_meadow.dart';

void main() {
  test('the deck is complete, shuffled, and deterministic per round', () {
    final a = meadowDeck(7);
    expect(a.length, 12);
    // same round, same meadow (compared by value - cards are plain data)
    expect(a.map((c) => '${c.pair}:${c.isHome}').toList(),
        meadowDeck(7).map((c) => '${c.pair}:${c.isHome}').toList());
    // every pair id appears exactly twice: one animal, one home
    for (var p = 0; p < 6; p++) {
      final cards = a.where((c) => c.pair == p).toList();
      expect(cards.length, 2);
      expect(cards.where((c) => c.isHome).length, 1);
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

  test('firefly light fades honestly and never goes negative', () {
    expect(trailGlow(0), 1);
    expect(trailGlow(trailLife / 2), closeTo(0.5, 0.001));
    expect(trailGlow(trailLife), 0);
    expect(trailGlow(trailLife * 3), 0);
  });

  test('neither game scores, scolds, or hurries', () {
    for (final line in [
      MeadowCopy.intro, MeadowCopy.done, MeadowCopy.fact,
      FireflyCopy.intro, FireflyCopy.fact,
    ]) {
      for (final bad in [
        'wrong', 'score', 'points', 'fail', 'hurry', 'game over',
        'try harder', 'you missed'
      ]) {
        expect(line.toLowerCase().contains(bad), false,
            reason: '"$line" contains "$bad"');
      }
    }
  });
}
