// Pond Hopper - the pure logic under the pond. Determinism, pads
// that always stay within a frog's leap, honest bounds, and copy
// that never scores, scolds, or hurries.

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

    test('every next pad is within a leap', () {
      final pads = padSpots(13, 8);
      for (var i = 1; i < pads.length; i++) {
        // sideways: never more than 0.45 of the pond's width
        expect((pads[i].$1 - pads[i - 1].$1).abs(),
            lessThanOrEqualTo(0.45));
        // forward: 95..150
        final dy = pads[i].$2 - pads[i - 1].$2;
        expect(dy, greaterThanOrEqualTo(95.0));
        expect(dy, lessThanOrEqualTo(150.0));
      }
    });

    test('pads stay on the pond and at kind sizes', () {
      for (final (x, _, r, _) in padSpots(30, 4)) {
        expect(x, greaterThanOrEqualTo(0.18));
        expect(x, lessThanOrEqualTo(0.82));
        expect(r, greaterThanOrEqualTo(28.0));
        expect(r, lessThanOrEqualTo(38.0));
      }
    });

    test('worst case pad-to-pad distance fits under maxLeap', () {
      // narrowest phones: ~330px of pond. Sideways 0.45 * 330 plus
      // forward 150 plus drift must stay under the frog's 290.
      final worst = sqrt(pow(0.45 * 330.0 + 28.0, 2) + pow(150.0, 2));
      expect(worst, lessThan(290.0));
    });
  });

  group('pond hopper - butterflies', () {
    test('deterministic and on the water', () {
      expect(bfSpots(5, 9).toString(), bfSpots(5, 9).toString());
      for (final (x, d) in bfSpots(5, 9)) {
        expect(x, greaterThanOrEqualTo(0.15));
        expect(x, lessThanOrEqualTo(0.85));
        expect(d, greaterThan(0.0));
      }
    });

    test('all butterflies live between the banks', () {
      final lastPad = padSpots(13, 8).last.$2;
      for (final (_, d) in bfSpots(5, 9)) {
        expect(d, lessThan(lastPad));
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
    test('the pond speaks gently', () {
      final all =
          [PondCopy.intro, PondCopy.done].join(' ').toLowerCase();
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
  });
}
