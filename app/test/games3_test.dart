// Pond Hopper - the pure logic under the three ponds. Determinism,
// pads that always stay within a frog's leap on every level, wind
// and dip rhythms that stay honest, and copy that never scores,
// scolds, or hurries.

import 'dart:math';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:hopeling/features/kids/games/pond_hopper.dart';

void main() {
  group('pond hopper - pads', () {
    test('deterministic for a seed', () {
      expect(padSpots(13, 8).toString(), padSpots(13, 8).toString());
      expect(
          padSpots(13, 8).toString(), isNot(padSpots(13, 9).toString()));
    });

    test('every next pad is within a leap, on every level', () {
      for (final lv in PondLevel.levels) {
        final pads = padSpots(lv.padCount, lv.seed,
            spaceMin: lv.spaceMin,
            spaceMax: lv.spaceMax,
            rMin: lv.rMin,
            rMax: lv.rMax);
        expect(pads.length, lv.padCount);
        for (var i = 1; i < pads.length; i++) {
          expect((pads[i].$1 - pads[i - 1].$1).abs(),
              lessThanOrEqualTo(0.45),
              reason: '${lv.name}: sideways step');
          final dy = pads[i].$2 - pads[i - 1].$2;
          expect(dy, greaterThanOrEqualTo(lv.spaceMin),
              reason: '${lv.name}: spacing');
          expect(dy, lessThanOrEqualTo(lv.spaceMax),
              reason: '${lv.name}: spacing');
        }
        for (final (x, _, r, _) in pads) {
          expect(x, inInclusiveRange(0.18, 0.82),
              reason: '${lv.name}: x bounds');
          expect(r, inInclusiveRange(lv.rMin, lv.rMax),
              reason: '${lv.name}: radius');
        }
      }
    });

    test('worst-case leap fits under maxLeap on every level', () {
      // Even on a wide phone (450px pond), the farthest possible
      // next pad - plus drift both ways and the strongest wind
      // shove - must stay inside the frog's 290, with the landing
      // tolerance (pad radius + 16) helping her.
      for (final lv in PondLevel.levels) {
        for (final w in [330.0, 400.0, 450.0]) {
          final needed =
              sqrt(pow(0.45 * w, 2) + pow(lv.spaceMax, 2)) -
                  (lv.rMin + 16.0) +
                  lv.driftAmp * 2.0 +
                  lv.wind * 1.4 * 0.55;
          expect(needed, lessThan(290.0),
              reason: '${lv.name} at width $w: needs $needed');
        }
      }
    });
  });

  group('pond hopper - wind and dip', () {
    test('wind is bounded by 1.4x its strength', () {
      for (var t = 0.0; t < 30.0; t += 0.13) {
        expect(windX(t, 26.0).abs(), lessThanOrEqualTo(26.0 * 1.4));
      }
      expect(windX(7.3, 0.0), 0.0);
    });

    test('dip stays 0..1 and actually cycles', () {
      var lo = 1.0;
      var hi = 0.0;
      for (var t = 0.0; t < 20.0; t += 0.1) {
        final d = dipAmount(t, 1.7);
        expect(d, inInclusiveRange(0.0, 1.0));
        lo = min(lo, d);
        hi = max(hi, d);
      }
      expect(lo, 0.0); // pads spend real time fully dry
      expect(hi, greaterThan(0.9)); // and really do go under
    });

    test('different pads dip at different moments', () {
      expect(dipAmount(3.0, 0.5), isNot(closeTo(dipAmount(3.0, 3.5), 0.01)));
    });
  });

  group('pond hopper - butterflies and fireflies', () {
    test('deterministic, on the water, always between banks', () {
      for (final lv in PondLevel.levels) {
        final span = padSpots(lv.padCount, lv.seed,
                spaceMin: lv.spaceMin,
                spaceMax: lv.spaceMax,
                rMin: lv.rMin,
                rMax: lv.rMax)
            .last
            .$2;
        final flies = bfSpots(lv.flyCount, lv.seed + 1, span);
        expect(flies.toString(),
            bfSpots(lv.flyCount, lv.seed + 1, span).toString());
        for (final (x, d) in flies) {
          expect(x, inInclusiveRange(0.15, 0.85),
              reason: '${lv.name}: fly x');
          expect(d, greaterThan(0.0));
          expect(d, lessThan(span), reason: '${lv.name}: fly range');
        }
      }
    });
  });

  group('pond hopper - the leap', () {
    test('a reachable tap is taken exactly', () {
      const from = Offset(100, 100);
      const to = Offset(150, 180);
      expect(clampLeap(from, to, 290.0), to);
    });

    test('a far tap falls short in the same direction', () {
      const from = Offset(0, 0);
      const to = Offset(0, 1000);
      final got = clampLeap(from, to, 290.0);
      expect(got.dx, 0.0);
      expect(got.dy, closeTo(290.0, 0.001));
    });

    test('never lengthens a leap', () {
      final r = Random(3);
      for (var i = 0; i < 50; i++) {
        final from =
            Offset(r.nextDouble() * 400.0, r.nextDouble() * 2000.0);
        final to =
            Offset(r.nextDouble() * 400.0, r.nextDouble() * 2000.0);
        expect((clampLeap(from, to, 290.0) - from).distance,
            lessThanOrEqualTo(290.001));
      }
    });
  });

  group('copy - no scores, no scolds, no hurry', () {
    test('every pond speaks gently', () {
      final all = [...PondCopy.intros, ...PondCopy.dones]
          .join(' ')
          .toLowerCase();
      for (final banned in [
        'score',
        'point',
        'fail',
        'lose',
        'wrong',
        'miss',
        'hurry',
        'quick',
        'time is',
        'waiting for you',
      ]) {
        expect(all.contains(banned), isFalse,
            reason: 'banned word "$banned" found in game copy');
      }
    });

    test('one intro and one ending per pond', () {
      expect(PondCopy.intros.length, PondLevel.levels.length);
      expect(PondCopy.dones.length, PondLevel.levels.length);
    });
  });
}
