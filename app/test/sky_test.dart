// The Living Sky - the math must be TRUE, because a parent will
// step outside and check. Moon phase against the real almanac,
// seasons that behave, a sky that turns without ever popping.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hopeling/core/sky.dart';

void main() {
  group('the moon is real', () {
    test('new at the epoch, full a fortnight later', () {
      final epoch = DateTime.utc(2000, 1, 6, 18, 14);
      expect(moonPhase(epoch), closeTo(0.0, 0.002));
      expect(
          moonPhase(epoch.add(const Duration(
              days: 14, hours: 18, minutes: 22))),
          closeTo(0.5, 0.01));
      expect(
          moonPhase(epoch.add(const Duration(
              days: 29, hours: 12, minutes: 44))),
          closeTo(0.0, 0.01));
    });

    test('matches the almanac on known full moons', () {
      // real full moons, UTC - the formula must land within ~half a day
      expect(moonPhase(DateTime.utc(2024, 1, 25, 17, 54)),
          closeTo(0.5, 0.03));
      expect(moonPhase(DateTime.utc(2026, 1, 3, 12, 0)),
          closeTo(0.5, 0.03));
      expect(moonPhase(DateTime.utc(2025, 7, 10, 20, 0)),
          closeTo(0.5, 0.03));
    });

    test('always 0..1, and the emoji follows the phase', () {
      for (var d = 0; d < 60; d++) {
        final p = moonPhase(DateTime.utc(2026, 1, 1).add(Duration(days: d)));
        expect(p, inInclusiveRange(0.0, 1.0));
      }
      expect(moonPhaseEmoji(0.0), '🌑');
      expect(moonPhaseEmoji(0.25), '🌓');
      expect(moonPhaseEmoji(0.5), '🌕');
      expect(moonPhaseEmoji(0.75), '🌗');
      expect(moonPhaseName(0.5), 'full moon');
    });
  });

  group('the sun keeps its seasons', () {
    test('summer days are long, winter days short', () {
      final (srSummer, ssSummer) = sunTimes(DateTime(2026, 6, 21));
      final (srWinter, ssWinter) = sunTimes(DateTime(2026, 12, 21));
      expect(ssSummer, greaterThan(ssWinter + 2.0));
      expect(srSummer, lessThan(srWinter - 1.5));
      // and always sane hours
      for (final v in [srSummer, ssSummer, srWinter, ssWinter]) {
        expect(v, inInclusiveRange(4.0, 21.0));
      }
    });
  });

  group('the sky turns, never pops', () {
    test('a minute changes the sky imperceptibly, all day long', () {
      var t = DateTime(2026, 7, 25, 0, 0);
      var prev = skyStops(t);
      for (var m = 1; m < 24 * 60; m++) {
        t = t.add(const Duration(minutes: 1));
        final cur = skyStops(t);
        for (var i = 0; i < 3; i++) {
          expect(
              ((cur[i].r - prev[i].r).abs() * 255),
              lessThan(8.0),
              reason: 'red jump at $t stop $i');
          expect(
              ((cur[i].g - prev[i].g).abs() * 255),
              lessThan(8.0),
              reason: 'green jump at $t stop $i');
          expect(
              ((cur[i].b - prev[i].b).abs() * 255),
              lessThan(8.0),
              reason: 'blue jump at $t stop $i');
        }
        prev = cur;
      }
    });

    test('midnight is dark, noon is not', () {
      expect(skyIsDark(DateTime(2026, 7, 25, 1, 30)), isTrue);
      expect(skyIsDark(DateTime(2026, 7, 25, 13, 0)), isFalse);
      expect(nightness(DateTime(2026, 7, 25, 2, 0)),
          greaterThan(nightness(DateTime(2026, 7, 25, 13, 0))));
    });

    test('the wash always hands back two colors', () {
      const base = Color(0xFFFBF6EA);
      for (final hour in [0, 6, 9, 13, 18, 21]) {
        final w = skyWash(DateTime(2026, 7, 25, hour), base);
        expect(w.length, 2);
        expect(w[1], base);
      }
    });
  });

  group('the sky line', () {
    test('speaks the moon at night, gold at dusk, nothing at noon', () {
      final night = skyLine(DateTime(2026, 7, 25, 23, 0));
      expect(night, contains('moon'));
      expect(skyLine(DateTime(2026, 7, 25, 13, 0)), isEmpty);
    });

    test('never scores, scolds, or hurries', () {
      for (final hour in [0, 5, 7, 12, 18, 20, 23]) {
        final line = skyLine(DateTime(2026, 7, 25, hour)).toLowerCase();
        for (final bad in ['hurry', 'score', 'fail', 'miss', 'wrong']) {
          expect(line.contains(bad), isFalse);
        }
      }
    });
  });
}
