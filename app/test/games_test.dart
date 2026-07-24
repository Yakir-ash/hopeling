// The Play games vs the constitution: no fail states, no scores, no
// hurry - and the Flame era keeps every rule. Rocks are always
// leapable, water clears in honest proportion, and no copy ever
// scolds.

import 'package:flutter_test/flutter_test.dart';

import 'package:hopeling/features/kids/games/river_keeper.dart';
import 'package:hopeling/features/kids/games/salmon_run.dart';

void main() {
  test('water clears in honest proportion', () {
    expect(clarity(0, 12), 0);
    expect(clarity(6, 12), 0.5);
    expect(clarity(12, 12), 1);
    expect(clarity(0, 0), 1); // an empty river is already clear
  });

  test('rocks are deterministic and always leapable', () {
    final a = rockSpots(9, 5);
    expect(a, rockSpots(9, 5));
    expect(a.length, 9);
    for (var i = 1; i < a.length; i++) {
      expect(a[i] - a[i - 1], greaterThanOrEqualTo(260),
          reason: 'a leap between rocks must always be possible');
    }
  });

  test('no game ever scolds, scores, or hurries', () {
    for (final line in [
      RiverCopy.intro, RiverCopy.patience, RiverCopy.done,
      RiverCopy.fact, SalmonCopy.intro, SalmonCopy.bump,
      SalmonCopy.done,
    ]) {
      for (final bad in [
        'you missed', 'game over', 'fail', 'lose', 'score', 'points',
        'hurry', 'too slow', 'try harder', 'wrong'
      ]) {
        expect(line.toLowerCase().contains(bad), false,
            reason: '"$line" contains "$bad"');
      }
    }
  });
}
