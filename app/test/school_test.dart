// The Schoolhouse's front door: five jobs, decided by the calendar,
// the notebook and the door - never a feed. Same day, same pick.

import 'package:flutter_test/flutter_test.dart';
import 'package:hopeling/data/lab.dart';
import 'package:hopeling/data/school.dart';

void main() {
  group('five minutes of wonder', () {
    test('deterministic: the same day gives the same pick', () {
      final t = DateTime(2026, 9, 18, 10);
      for (final door in [null, 'wonder', 'act', 'quiet']) {
        final a = fiveMinutePick(t, door);
        final b = fiveMinutePick(t, door);
        expect(a.kind, b.kind, reason: '$door');
        expect(a.labId, b.labId, reason: '$door');
      }
    });

    test('a year visits every kind, whatever the door', () {
      for (final door in [null, 'wonder', 'act']) {
        final seen = <FiveKind>{};
        for (var d = 0; d < 366; d++) {
          seen.add(fiveMinutePick(DateTime(2026, 1, 1).add(Duration(days: d)),
                  door)
              .kind);
        }
        expect(seen, FiveKind.values.toSet(), reason: '$door');
      }
    });

    test('a lab pick always names a real experiment', () {
      for (var d = 0; d < 366; d++) {
        for (final door in [null, 'wonder', 'act']) {
          final p = fiveMinutePick(
              DateTime(2026, 1, 1).add(Duration(days: d)), door);
          if (p.kind == FiveKind.lab) {
            expect(labScenarioById(p.labId!), isNotNull);
            if (door == 'act') {
              // the act door leans to experiments with a repair
              expect(labScenarioById(p.labId!)!.repair, isNotNull);
            }
          } else {
            expect(p.labId, isNull);
          }
        }
      }
    });

    test('the door leans the year, it does not narrow it', () {
      int count(String? door, FiveKind k) {
        var n = 0;
        for (var d = 0; d < 366; d++) {
          if (fiveMinutePick(
                      DateTime(2026, 1, 1).add(Duration(days: d)), door)
                  .kind ==
              k) {
            n++;
          }
        }
        return n;
      }

      // every kind still lands roughly a quarter of the days, for
      // every door: a lean is a reorder, never an exclusion
      for (final door in [null, 'wonder', 'act']) {
        for (final k in FiveKind.values) {
          expect(count(door, k), inInclusiveRange(80, 100),
              reason: '$door $k');
        }
      }
    });
  });

  group('the fortnight experiment', () {
    test('holds for two weeks, then turns', () {
      // weeks 8 and 9 of 2026 share a fortnight (python-verified)
      final a = fortnightExperiment(DateTime(2026, 2, 27));
      final b = fortnightExperiment(DateTime(2026, 3, 3));
      expect(a.id, b.id);
      // and the fortnight after is a different experiment
      expect(fortnightExperiment(DateTime(2026, 3, 9)).id, isNot(a.id));
      // over a year, every experiment gets its fortnight
      final seen = <String>{};
      for (var d = 0; d < 366; d++) {
        seen.add(
            fortnightExperiment(DateTime(2026, 1, 1).add(Duration(days: d)))
                .id);
      }
      expect(seen.length, labScenarios.length);
    });
  });

  group('the one quiet line', () {
    test('every room is named, and named once', () {
      expect(schoolRooms.length, 6);
      expect(schoolRooms.map((r) => r.$2).toSet().length, 6);
      for (final (emoji, name, sub) in schoolRooms) {
        expect(emoji.isNotEmpty, isTrue);
        expect(name.isNotEmpty, isTrue);
        expect(sub.isNotEmpty, isTrue);
        expect(sub.contains('—'), isFalse);
        expect(sub.contains('–'), isFalse);
      }
    });
  });
}
