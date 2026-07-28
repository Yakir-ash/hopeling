// V2's engines: Paths, Mysteries, the Field Guide's pure logic.
// Content must be complete, ids unique, scheduling deterministic
// (a book, not a slot machine), and every word calm.

import 'package:flutter_test/flutter_test.dart';
import 'package:hopeling/data/almanac.dart';
import 'package:hopeling/data/fieldguide.dart';
import 'package:hopeling/data/mysteries.dart';
import 'package:hopeling/data/paths.dart';

void main() {
  group('paths', () {
    test('every chapter is whole, every id unique', () {
      expect(paths.length, greaterThanOrEqualTo(2));
      final ids = <String>{};
      for (final p in paths) {
        expect(p.chapters.length, greaterThanOrEqualTo(10),
            reason: '${p.name} is too short to be a walk');
        expect(p.promise.trim(), isNotEmpty);
        expect(p.capstone.trim(), isNotEmpty);
        for (final c in p.chapters) {
          expect(ids.add(c.id), isTrue,
              reason: 'duplicate chapter id ${c.id}');
          expect(c.title.trim(), isNotEmpty);
          expect(c.idea.trim(), isNotEmpty);
          expect(c.notice.trim(), isNotEmpty);
          expect(c.keeper.trim(), isNotEmpty);
          expect(c.note.trim(), isNotEmpty);
          if (c.speciesId != null) {
            expect(atlasById(c.speciesId!), isNotNull,
                reason:
                    '${c.id} links to missing species ${c.speciesId}');
          }
        }
      }
    });

    test('progress and continuation behave', () {
      final p = paths.first;
      expect(pathProgress(p, {}), 0);
      expect(nextChapter(p, {})!.id, p.chapters.first.id);
      final all = {for (final c in p.chapters) c.id};
      expect(pathProgress(p, all), p.chapters.length);
      expect(nextChapter(p, all), isNull);
      // continuePath prefers the furthest unfinished walk
      final some = {p.chapters.first.id, p.chapters[1].id};
      expect(continuePath(some)!.id, p.id);
      // all walked everywhere: nothing to continue
      final everything = {
        for (final pp in paths) ...{for (final c in pp.chapters) c.id}
      };
      expect(continuePath(everything), isNull);
    });
  });

  group('mysteries', () {
    test('every mystery is complete and honest', () {
      final ids = <String>{};
      for (final m in mysteries) {
        expect(ids.add(m.id), isTrue);
        expect(m.clues.length, 5,
            reason: '${m.id}: a week has five clue days');
        expect(m.suspects.length, 3);
        expect(m.answer, inInclusiveRange(0, 2));
        expect(m.scene.trim(), isNotEmpty);
        expect(m.reveal.trim(), isNotEmpty);
        expect(m.lesson.trim(), isNotEmpty);
        for (final c in m.clues) {
          expect(c.trim(), isNotEmpty);
        }
        if (m.speciesId != null) {
          expect(atlasById(m.speciesId!), isNotNull);
        }
      }
    });

    test('the week schedules itself deterministically', () {
      final mon = DateTime(2026, 7, 20); // a Monday
      expect(mysteryOfWeek(mon).id,
          mysteryOfWeek(DateTime(2026, 7, 24)).id,
          reason: 'one mystery per week, all week');
      expect(cluesOpen(DateTime(2026, 7, 20)), 1); // Monday
      expect(cluesOpen(DateTime(2026, 7, 22)), 3); // Wednesday
      expect(cluesOpen(DateTime(2026, 7, 24)), 5); // Friday
      expect(cluesOpen(DateTime(2026, 7, 26)), 5); // Sunday: full hand
      // successive weeks rotate
      expect(mysteryOfWeek(mon).id,
          isNot(mysteryOfWeek(mon.add(const Duration(days: 7))).id));
    });
  });

  group('the field guide voice', () {
    test('the cover line never scores or scolds', () {
      expect(guideLine(0, 0, 0), contains('begins empty'));
      final line = guideLine(3, 2, 1).toLowerCase();
      expect(line, contains('3 field notes'));
      expect(line, contains('2 neighbors'));
      expect(line, contains('1 mystery'));
      for (final bad in ['score', 'streak', 'level up', 'points']) {
        expect(line.contains(bad), isFalse);
      }
      expect(guideLine(1, 0, 0), contains('1 field note walked'));
    });
  });

  group('the voice of v2', () {
    test('no path or mystery ever scolds, panics, or dashes', () {
      final all = [
        for (final p in paths) ...[
          p.promise,
          p.capstone,
          for (final c in p.chapters) ...[
            c.idea,
            c.notice,
            c.keeper,
            c.note
          ]
        ],
        for (final m in mysteries) ...[
          m.scene,
          m.reveal,
          m.lesson,
          ...m.clues,
          ...m.suspects
        ],
      ].join(' ');
      final lower = all.toLowerCase();
      for (final bad in [
        'you failed',
        'wrong!',
        'hurry',
        'too slow',
        'score',
        'crisis',
        'doomed',
      ]) {
        expect(lower.contains(bad), isFalse,
            reason: 'banned phrase "$bad" in V2 content');
      }
      expect(all.contains('—'), isFalse, reason: 'em dash in content');
      expect(all.contains('–'), isFalse, reason: 'en dash in content');
    });
  });
}
