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

  test('rocks are deterministic, leapable, and never twins in height',
      () {
    final a = rockSpots(9, 5);
    expect(a.map((r) => '${r.$1}:${r.$2}').toList(),
        rockSpots(9, 5).map((r) => '${r.$1}:${r.$2}').toList());
    expect(a.length, 9);
    for (var i = 1; i < a.length; i++) {
      expect(a[i].$1 - a[i - 1].$1, greaterThanOrEqualTo(260),
          reason: 'a leap between rocks must always be possible');
      expect((a[i].$2 - a[i - 1].$2).abs(), greaterThanOrEqualTo(0.2),
          reason: 'neighboring rocks must ask different jumps');
    }
    for (final r in a) {
      expect(r.$2, inInclusiveRange(0.6, 1.5));
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
