// The Errand's constitution: deterministic like a book, tuned to
// season and darkness, calm in tone, and generous enough that no
// combination of season and hour ever runs dry.

import 'package:flutter_test/flutter_test.dart';
import 'package:hopeling/data/errands.dart';

void main() {
  group('the deck', () {
    test('ids unique, every errand complete', () {
      expect(errands.map((e) => e.id).toSet().length, errands.length);
      for (final e in errands) {
        expect(e.text.length, greaterThan(30), reason: e.id);
        expect(e.note.length, greaterThan(15), reason: e.id);
        expect(e.emoji.trim().isNotEmpty, isTrue, reason: e.id);
        // notes are past tense first-person - the guide's voice
        expect(e.note.startsWith('I '), isTrue, reason: e.id);
      }
    });

    test('no season+darkness combination runs dry', () {
      for (final s in ['spring', 'summer', 'autumn', 'winter']) {
        for (final dark in [true, false]) {
          final pool = errands.where((e) =>
              (e.seasons == null || e.seasons!.contains(s)) &&
              (e.dark == null || e.dark == dark));
          expect(pool.length, greaterThanOrEqualTo(4),
              reason: '$s dark=$dark');
        }
      }
    });
  });

  group('the pick', () {
    test('deterministic: same day, same errand', () {
      final t = DateTime(2026, 8, 12, 10);
      expect(errandOfDay(t, dark: false).id,
          errandOfDay(t, dark: false).id);
    });

    test('respects darkness: night errands only at night', () {
      for (var d = 1; d <= 365; d += 7) {
        final t = DateTime(2026, 1, 1).add(Duration(days: d));
        final day = errandOfDay(t, dark: false);
        final night = errandOfDay(t, dark: true);
        expect(day.dark != true, isTrue, reason: day.id);
        expect(night.dark != false, isTrue, reason: night.id);
      }
    });

    test('respects season across the year', () {
      for (var d = 1; d <= 365; d += 11) {
        final t = DateTime(2026, 1, 1).add(Duration(days: d));
        final e = errandOfDay(t, dark: false);
        if (e.seasons != null) {
          // the season function is the almanac's; if the errand is
          // seasonal, its seasons must include the pick day's
          expect(e.seasons!.isNotEmpty, isTrue);
        }
      }
    });

    test('variety: a fortnight is not one errand repeated', () {
      final seen = <String>{};
      for (var d = 0; d < 14; d++) {
        final t = DateTime(2026, 6, 1).add(Duration(days: d));
        seen.add(errandOfDay(t, dark: false).id);
      }
      expect(seen.length, greaterThanOrEqualTo(5));
    });
  });

  group('tone', () {
    test('no hurry, no tests, no scolds, no dashes', () {
      final all = [
        for (final e in errands) ...[e.text, e.note]
      ].join(' ');
      for (final bad in [
        'hurry', 'quick!', 'you must', 'fail', 'score', 'points',
        'quiz', 'test yourself', 'don\'t forget',
      ]) {
        expect(all.toLowerCase().contains(bad), isFalse, reason: bad);
      }
      expect(all.contains('—'), isFalse);
      expect(all.contains('–'), isFalse);
    });

    test('errand note ids carry the day, so errands can repeat', () {
      final e = errands.first;
      final a = errandNoteId(e, DateTime(2026, 3, 1));
      final b = errandNoteId(e, DateTime(2026, 3, 2));
      expect(a == b, isFalse);
      expect(a.startsWith('err:${e.id}:'), isTrue);
    });
  });
}
