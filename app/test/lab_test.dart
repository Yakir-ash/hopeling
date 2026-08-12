// The Lab's constitution: deterministic (same lever, same curves),
// directionally true (no bees is worse for flowers; wolves bring
// willows back; heat unbuilds coral), always bounded, and calm.

import 'package:flutter_test/flutter_test.dart';
import 'package:hopeling/data/lab.dart';

void main() {
  group('shape', () {
    test('three scenarios, complete and unique', () {
      expect(labScenarios.length, 3);
      expect(labScenarios.map((s) => s.id).toSet().length, 3);
      for (final s in labScenarios) {
        expect(s.options.length, greaterThanOrEqualTo(2),
            reason: s.id);
        expect(s.series.length, 3, reason: s.id);
        for (final o in s.options) {
          expect(o.moments.length, greaterThanOrEqualTo(2),
              reason: '${s.id}/${o.label}');
          expect(o.epilogue.length, greaterThan(40),
              reason: '${s.id}/${o.label}');
          for (final m in o.moments) {
            expect(m.step, inInclusiveRange(0, 11));
          }
        }
      }
    });

    test('every option simulates: 3 series x 12 seasons, 0..1', () {
      for (final s in labScenarios) {
        for (var o = 0; o < s.options.length; o++) {
          final data = simulate(s.id, o);
          expect(data.length, 3, reason: '${s.id}/$o');
          for (final series in data) {
            expect(series.length, 12);
            for (final v in series) {
              expect(v, inInclusiveRange(0.0, 1.0));
            }
          }
        }
      }
    });
  });

  group('a book, not a slot machine', () {
    test('same lever, same curves, every time', () {
      for (final s in labScenarios) {
        final a = simulate(s.id, 0);
        final b = simulate(s.id, 0);
        for (var i = 0; i < a.length; i++) {
          expect(a[i], b[i], reason: s.id);
        }
      }
    });
  });

  group('directions are true', () {
    test('meadow: flowers end lower without bees', () {
      final withBees = simulate('meadow', 0);
      final noBees = simulate('meadow', 2);
      expect(noBees[0].last, lessThan(withBees[0].last));
      // and the loss travels up the web
      expect(noBees[1].last, lessThan(withBees[1].last));
      expect(noBees[2].last, lessThan(withBees[2].last));
    });

    test('wolves: willows and beavers recover, elk decline', () {
      final without = simulate('wolves', 0);
      final withWolves = simulate('wolves', 1);
      expect(withWolves[0].last, lessThan(without[0].last)); // elk
      expect(withWolves[1].last,
          greaterThan(without[1].last)); // willows
      expect(withWolves[2].last,
          greaterThan(without[2].last)); // beavers
    });

    test('sea: coral ends lower each added degree', () {
      final c0 = simulate('sea', 0)[0].last;
      final c1 = simulate('sea', 1)[0].last;
      final c2 = simulate('sea', 2)[0].last;
      expect(c1, lessThan(c0));
      expect(c2, lessThan(c1));
      // the catch follows the reef down
      expect(simulate('sea', 2)[2].last,
          lessThan(simulate('sea', 0)[2].last));
    });
  });

  group('honesty and tone', () {
    test('scenarios that claim reality carry citations', () {
      final wolves = labScenarioById('wolves')!;
      expect(wolves.citation, isNotNull);
      expect(wolves.citation!.toLowerCase(),
          contains('really happened'));
      expect(wolves.citationUrl, contains('wikipedia'));
    });

    test('calm words: no doom-scolding, no dashes', () {
      final all = [
        for (final s in labScenarios) ...[
          s.title,
          s.question,
          for (final o in s.options) ...[
            o.label,
            o.epilogue,
            for (final m in o.moments) m.text,
          ],
          s.citation ?? '',
        ]
      ].join(' ');
      for (final bad in [
        'your fault', 'too late', 'doomed', 'hopeless', 'panic',
      ]) {
        expect(all.toLowerCase().contains(bad), isFalse, reason: bad);
      }
      expect(all.contains('—'), isFalse);
      expect(all.contains('–'), isFalse);
    });
  });
}
