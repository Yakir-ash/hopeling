// Owl Glide and Bee Line - the pure logic under the night and the
// meadow. Determinism, reachable spacing, honest bounds, and copy
// that never scores, scolds, or hurries.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hopeling/features/kids/games/bee_line.dart';
import 'package:hopeling/features/kids/games/owl_glide.dart';

void main() {
  group('owl glide - moths', () {
    test('deterministic for a seed', () {
      expect(mothSpots(11, 12).toString(), mothSpots(11, 12).toString());
      expect(mothSpots(11, 12).toString(),
          isNot(mothSpots(11, 13).toString()));
    });

    test('spaced so she can always reach the next one', () {
      final m = mothSpots(11, 12);
      expect(m.length, 11);
      for (var i = 1; i < m.length; i++) {
        expect(m[i].$1 - m[i - 1].$1, greaterThanOrEqualTo(200.0));
      }
    });

    test('heights stay inside the playable sky', () {
      for (final (_, h) in mothSpots(30, 7)) {
        expect(h, greaterThanOrEqualTo(0.15));
        expect(h, lessThanOrEqualTo(0.72));
      }
    });
  });

  group('owl glide - sky', () {
    test('starts at night, ends at dawn', () {
      expect(skyAt(0.0), const Color(0xFF141C36));
      expect(skyAt(1.0), const Color(0xFFFFE9D6));
    });

    test('clamps outside the journey', () {
      expect(skyAt(-2.0), skyAt(0.0));
      expect(skyAt(5.0), skyAt(1.0));
    });

    test('dawn rises - the sky warms as she flies', () {
      expect(skyAt(0.8).r, greaterThan(skyAt(0.2).r));
    });
  });

  group('bee line - flowers', () {
    test('deterministic for a seed', () {
      expect(flowerField(40, 21).toString(), flowerField(40, 21).toString());
      expect(flowerField(40, 21).toString(),
          isNot(flowerField(40, 22).toString()));
    });

    test('lanes stay on the meadow', () {
      for (final (lane, _, c) in flowerField(60, 3)) {
        expect(lane, greaterThanOrEqualTo(0.12));
        expect(lane, lessThanOrEqualTo(0.88));
        expect(c, inInclusiveRange(0, 3));
      }
    });

    test('flowers stream steadily, never bunched', () {
      final f = flowerField(40, 21);
      for (var i = 1; i < f.length; i++) {
        expect(f[i].$2 - f[i - 1].$2, greaterThanOrEqualTo(150.0));
      }
    });

    test('the goal is gatherable from what grows', () {
      expect(flowerField(40, 21).length, greaterThan(nectarGoal * 2));
    });
  });

  group('copy - no scores, no scolds, no hurry', () {
    test('owl and bee speak gently', () {
      final all = [
        OwlCopy.intro,
        OwlCopy.done,
        BeeCopy.intro,
        BeeCopy.dance,
      ].join(' ').toLowerCase();
      for (final banned in [
        'score',
        'point',
        'fail',
        'lose',
        'wrong',
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
