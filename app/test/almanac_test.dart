// The Almanac - V2's heart must be true, complete, and calm. Every
// wonder has its question, its looking, and its answer; every Atlas
// page lives in all four seasons; the daily picks are deterministic
// (a book, not a slot machine); and no line ever scolds.

import 'package:flutter_test/flutter_test.dart';
import 'package:hopeling/data/almanac.dart';

void main() {
  group('the living calendar', () {
    test('seasons match the window', () {
      expect(season(DateTime(2026, 4, 10)), 'spring');
      expect(season(DateTime(2026, 7, 25)), 'summer');
      expect(season(DateTime(2026, 10, 1)), 'autumn');
      expect(season(DateTime(2026, 12, 25)), 'winter');
      expect(season(DateTime(2026, 1, 5)), 'winter');
    });
  });

  group('the daily wonder', () {
    test('every wonder is whole: question, looking, answer', () {
      expect(wonders.length, greaterThanOrEqualTo(30));
      for (final w in wonders) {
        expect(w.q.trim(), isNotEmpty);
        expect(w.notice.trim(), isNotEmpty);
        expect(w.a.trim(), isNotEmpty);
        expect(w.q.length, lessThan(120),
            reason: 'a wonder is a question, not a lecture');
        if (w.month != null) {
          expect(w.month, inInclusiveRange(1, 12));
        }
      }
    });

    test('the year is covered: every month has its own wonder', () {
      for (var m = 1; m <= 12; m++) {
        expect(wonders.any((w) => w.month == m), isTrue,
            reason: 'month $m has no tuned wonder');
      }
    });

    test('deterministic all day, honest about yesterday', () {
      final morning = DateTime(2026, 7, 25, 7);
      final night = DateTime(2026, 7, 25, 22);
      expect(wonderOfDay(morning).q, wonderOfDay(night).q);
      expect(wonderOfYesterday(morning).q,
          wonderOfDay(DateTime(2026, 7, 24, 12)).q);
    });

    test('a month of mornings brings real variety', () {
      final seen = <String>{};
      for (var d = 0; d < 30; d++) {
        seen.add(
            wonderOfDay(DateTime(2026, 7, 1).add(Duration(days: d))).q);
      }
      expect(seen.length, greaterThanOrEqualTo(10));
    });
  });

  group('the living atlas', () {
    test('every page lives in all four seasons', () {
      expect(atlas.length, greaterThanOrEqualTo(8));
      final ids = <String>{};
      for (final s in atlas) {
        expect(ids.add(s.id), isTrue, reason: 'duplicate id ${s.id}');
        expect(s.emoji.trim(), isNotEmpty);
        expect(s.look.trim(), isNotEmpty);
        expect(s.wonder.trim(), isNotEmpty);
        expect(s.kidLine.trim(), isNotEmpty);
        for (final se in const [
          'spring',
          'summer',
          'autumn',
          'winter'
        ]) {
          expect(s.now[se]?.trim() ?? '', isNotEmpty,
              reason: '${s.id} is missing $se');
        }
      }
    });

    test('the night shift exists', () {
      expect(atlas.where((s) => s.nocturnal).length,
          greaterThanOrEqualTo(2));
    });

    test('species of the day: deterministic, night-aware', () {
      final t = DateTime(2026, 7, 25);
      expect(speciesOfDay(t).id, speciesOfDay(t).id);
      for (var d = 0; d < 20; d++) {
        final day = DateTime(2026, 3, 1).add(Duration(days: d));
        expect(speciesOfDay(day, dark: true).nocturnal, isTrue,
            reason: 'the evening slot belongs to the night shift');
      }
      // over a season, everyone gets a day
      final seen = <String>{};
      for (var d = 0; d < 90; d++) {
        seen.add(
            speciesOfDay(DateTime(2026, 3, 1).add(Duration(days: d)))
                .id);
      }
      expect(seen.length, atlas.length);
    });

    test('atlasById finds every page and no ghosts', () {
      for (final s in atlas) {
        expect(atlasById(s.id)?.name, s.name);
      }
      expect(atlasById('unicorn'), isNull);
    });
  });

  group('the voice of the almanac', () {
    test('no line ever scolds, scores, or panics', () {
      final all = [
        for (final w in wonders) ...[w.q, w.notice, w.a],
        for (final s in atlas) ...[
          s.look,
          s.wonder,
          s.kidLine,
          ...s.now.values
        ],
      ].join(' ').toLowerCase();
      for (final bad in [
        'score',
        'points',
        'you failed',
        'hurry',
        'you must',
        'crisis',
        'doomed',
        'dying planet',
      ]) {
        expect(all.contains(bad), isFalse,
            reason: 'banned phrase "$bad" in almanac content');
      }
    });

    test('no em or en dashes anywhere in the almanac', () {
      final all = [
        for (final w in wonders) ...[w.q, w.notice, w.a],
        for (final s in atlas) ...[
          s.look,
          s.wonder,
          s.kidLine,
          ...s.now.values
        ],
      ].join();
      expect(all.contains('—'), isFalse);
      expect(all.contains('–'), isFalse);
    });
  });
}
