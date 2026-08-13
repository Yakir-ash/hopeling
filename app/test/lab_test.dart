// The Lab v2 constitution: deterministic bands (a book, not a
// slot machine), every edge explains itself, directions stay
// true, thresholds close doors honestly, repair obeys hysteresis,
// real-history claims carry citations, and the hood always opens.

import 'package:flutter_test/flutter_test.dart';
import 'package:hopeling/data/lab.dart';

void main() {
  group('the library', () {
    test('nine scenarios across at least five wings, unique', () {
      expect(labScenarios.length, 9);
      expect(labScenarios.map((s) => s.id).toSet().length, 9);
      expect(labScenarios.map((s) => s.wing).toSet().length,
          greaterThanOrEqualTo(5));
    });

    test('every scenario is complete', () {
      for (final s in labScenarios) {
        expect(s.options.length, greaterThanOrEqualTo(2),
            reason: s.id);
        expect(s.nodes.isNotEmpty, isTrue, reason: s.id);
        expect(s.predictIndex,
            inInclusiveRange(0, s.seriesNames.length - 1),
            reason: s.id);
        for (final o in s.options) {
          expect(o.moments.isNotEmpty, isTrue,
              reason: '${s.id}/${o.label}');
          expect(o.epilogue.length, greaterThan(40),
              reason: '${s.id}/${o.label}');
          for (final m in o.moments) {
            expect(m.step, inInclusiveRange(0, s.steps - 1),
                reason: '${s.id}/${o.label}');
          }
        }
        // the four-part honesty panel is never skipped
        expect(s.hood.know.length, greaterThan(40), reason: s.id);
        expect(s.hood.estimate.length, greaterThan(40),
            reason: s.id);
        expect(s.hood.simplified.length, greaterThan(40),
            reason: s.id);
        expect(s.hood.uncertain.length, greaterThan(30),
            reason: s.id);
      }
    });

    test('every edge carries a real why', () {
      for (final s in labScenarios) {
        for (final e in s.edges) {
          expect(e.why.length, greaterThan(40),
              reason: '${s.id}: ${e.from}->${e.to}');
          expect(
              s.nodes.any((n) => n.id == e.from) &&
                  s.nodes.any((n) => n.id == e.to),
              isTrue,
              reason: '${s.id}: dangling edge');
        }
      }
    });
  });

  group('a book, not a slot machine', () {
    test('same lever, same band, every time', () {
      for (final s in labScenarios) {
        final a = runBands(s, 0);
        final b = runBands(s, 0);
        for (var i = 0; i < a.mid.length; i++) {
          expect(a.mid[i], b.mid[i], reason: s.id);
          expect(a.lo[i], b.lo[i], reason: s.id);
          expect(a.hi[i], b.hi[i], reason: s.id);
        }
      }
    });

    test('every run bounded 0..1, correct lengths', () {
      for (final s in labScenarios) {
        for (var o = 0; o < s.options.length; o++) {
          final r = runBands(s, o);
          expect(r.mid.length, s.seriesNames.length,
              reason: '${s.id}/$o');
          for (final series in [...r.lo, ...r.mid, ...r.hi]) {
            expect(series.length, s.steps);
            for (final v in series) {
              expect(v, inInclusiveRange(0.0, 1.0));
            }
          }
        }
      }
    });
  });

  group('directions are true', () {
    test('meadow: losses climb the web without bees', () {
      final bees = runBands(labScenarioById('meadow')!, 0).mid;
      final none = runBands(labScenarioById('meadow')!, 2).mid;
      for (var i = 0; i < 3; i++) {
        expect(none[i].last, lessThan(bees[i].last));
      }
    });

    test('wolves: elk fall, willows and beavers rise', () {
      final s = labScenarioById('wolves')!;
      final without = runBands(s, 0).mid;
      final withW = runBands(s, 1).mid;
      expect(withW[0].last, lessThan(without[0].last));
      expect(withW[1].last, greaterThan(without[1].last));
      expect(withW[2].last, greaterThan(without[2].last));
    });

    test('sea: each degree costs coral, fish, and catch', () {
      final s = labScenarioById('sea')!;
      final c = [for (var o = 0; o < 3; o++) runBands(s, o).mid];
      expect(c[1][0].last, lessThan(c[0][0].last));
      expect(c[2][0].last, lessThan(c[1][0].last));
      expect(c[2][2].last, lessThan(c[0][2].last));
    });

    test('beaver: the engineer rebuilds the street', () {
      final s = labScenarioById('beaver')!;
      final absent = runBands(s, 0).mid;
      final back = runBands(s, 1).mid;
      for (var i = 0; i < 3; i++) {
        expect(back[i].last, greaterThan(absent[i].last));
      }
    });

    test('runoff: food becomes suffocation', () {
      final s = labScenarioById('runoff')!;
      final low = runBands(s, 0).mid;
      final heavy = runBands(s, 1).mid;
      expect(heavy[0].last, greaterThan(low[0].last)); // algae
      expect(heavy[1].last, lessThan(low[1].last)); // oxygen
      expect(heavy[2].last, lessThan(low[2].last)); // fish
    });

    test('overfishing: the paradox and the collapse', () {
      final s = labScenarioById('overfish')!;
      final relentless = runBands(s, 2);
      // best catches first, nothing later
      expect(relentless.mid[2].first,
          greaterThan(runBands(s, 0).mid[2].first));
      expect(relentless.mid[2].last, lessThan(0.15));
      // the threshold is crossed
      expect(relentless.collapsed, contains('c'));
      // and light fishing runs forever
      expect(runBands(s, 0).collapsed, isEmpty);
    });

    test('mpa: a richer sea, a catch no worse', () {
      final s = labScenarioById('mpa')!;
      final none = runBands(s, 0).mid;
      final third = runBands(s, 2).mid;
      expect(third[0].last, greaterThan(none[0].last * 1.4));
      expect(third[1].last, greaterThanOrEqualTo(none[1].last));
    });

    test('fire: suppression accumulates the debt', () {
      final s = labScenarioById('fire')!;
      final suppress = runBands(s, 0).mid;
      final letBurn = runBands(s, 1).mid;
      expect(suppress[0].last, greaterThan(letBurn[0].last));
      expect(letBurn[1].last, greaterThan(suppress[1].last));
      expect(letBurn[2].last, greaterThan(suppress[2].last));
    });

    test('ice: each degree shrinks the mirror', () {
      final s = labScenarioById('ice')!;
      final ends = [
        for (var o = 0; o < 3; o++) runBands(s, o).mid[0].last
      ];
      expect(ends[1], lessThan(ends[0]));
      expect(ends[2], lessThan(ends[1]));
    });
  });

  group('repair obeys real physics', () {
    test('meadow repair recovers - but below never-lost', () {
      final s = labScenarioById('meadow')!;
      final degradedEnd = runBands(s, 2).mid[0].last;
      final repaired = runRepair(s, 2).mid[0].last;
      final neverLost = runBands(s, 0).mid[0].last;
      expect(repaired, greaterThan(degradedEnd));
      expect(repaired, lessThan(neverLost)); // hysteresis
    });

    test('cod moratorium after collapse barely helps', () {
      final s = labScenarioById('overfish')!;
      final repaired = runRepair(s, 2).mid[0].last;
      expect(repaired, lessThan(0.15)); // some doors close
    });

    test('the wolves rewind: recovered is not safe', () {
      final s = labScenarioById('wolves')!;
      final recovered = runBands(s, 1).mid;
      final rewound = runRepair(s, 1).mid;
      expect(rewound[0].last,
          greaterThan(recovered[0].last)); // elk resurge
      expect(rewound[1].last,
          lessThan(recovered[1].last)); // willows fall
    });
  });

  group('honesty', () {
    test('real-history scenarios carry citations and urls', () {
      for (final id in ['wolves', 'overfish']) {
        final s = labScenarioById(id)!;
        expect(s.citation!.toLowerCase(),
            contains('really happened'));
        expect(s.citationUrl, contains('wikipedia'));
      }
    });

    test('the wolves carry real counted elk', () {
      final rd = labScenarioById('wolves')!.realData!;
      expect(rd.points.length, greaterThanOrEqualTo(8));
      expect(rd.cite.toLowerCase(), contains('park service'));
      // the real decline is present in the data itself
      expect(rd.points[19]!, lessThan(rd.points[0]! * 0.35));
      for (final v in rd.points.values) {
        expect(v, inInclusiveRange(0.0, 1.0));
      }
    });

    test('calm words: no doom-scolding, no dashes', () {
      final all = [
        for (final s in labScenarios) ...[
          s.title, s.question, s.citation ?? '',
          s.hood.know, s.hood.estimate, s.hood.simplified,
          s.hood.uncertain,
          for (final e in s.edges) ...[e.why, e.cite ?? ''],
          for (final o in s.options) ...[
            o.label, o.epilogue,
            for (final m in o.moments) m.text,
          ],
          if (s.repair != null) ...[
            s.repair!.label, s.repair!.description,
            s.repair!.epilogue,
            for (final m in s.repair!.moments) m.text,
          ],
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
