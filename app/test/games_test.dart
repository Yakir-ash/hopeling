// The Play room vs the constitution: no fail states, no scores, no
// hurry - the wild does the real work and the child helps. Layouts
// are deterministic and stay inside their frames, and the track
// shapes cover every animal honestly.

import 'package:flutter_test/flutter_test.dart';

import 'package:hopeling/features/kids/games/river_keeper.dart';
import 'package:hopeling/features/kids/games/track_detective.dart';
import 'package:hopeling/features/kids/games/wind_garden.dart';

void main() {
  test('the garden plants the same flowers every time, inside the frame',
      () {
    final a = gardenSpots(6, 11);
    final b = gardenSpots(6, 11);
    expect(a, b);
    for (final o in a) {
      expect(o.dx, inInclusiveRange(0.05, 0.95));
      expect(o.dy, inInclusiveRange(0.5, 0.92));
    }
  });

  test('water clears in honest proportion', () {
    expect(clarity(0, 12), 0);
    expect(clarity(6, 12), 0.5);
    expect(clarity(12, 12), 1);
    expect(clarity(0, 0), 1); // an empty river is already clear
  });

  test('trails are deterministic, complete, and stay in the forest', () {
    final a = trailPoints(7, 101);
    expect(a, trailPoints(7, 101));
    expect(a.length, 7);
    for (final o in a) {
      expect(o.dx, inInclusiveRange(0.05, 0.95));
      expect(o.dy, inInclusiveRange(0.1, 0.92));
    }
  });

  test('every track animal has its whole story', () {
    expect(trackAnimals.length, greaterThanOrEqualTo(4));
    for (final a in trackAnimals) {
      expect(
          a.name.isNotEmpty &&
              a.trackName.isNotEmpty &&
              a.hello.isNotEmpty,
          true);
    }
  });

  test('no game ever scolds, scores, or hurries', () {
    for (final line in [
      GardenCopy.intro, GardenCopy.done, GardenCopy.fact,
      RiverCopy.intro, RiverCopy.patience, RiverCopy.done,
      RiverCopy.fact, TrackCopy.intro, TrackCopy.done,
      for (final a in trackAnimals) a.hello,
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
