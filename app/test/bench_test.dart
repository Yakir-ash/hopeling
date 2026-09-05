// The Classroom Bench's constitution: every experiment carries a
// real lesson plan, the room is asked a comparison (the only
// question a controlled experiment can answer), the model gives
// a difference worth pointing at, and no reading of the room is
// ever a mark.

import 'package:flutter_test/flutter_test.dart';
import 'package:hopeling/data/bench.dart';
import 'package:hopeling/data/lab.dart';

void main() {
  group('the lesson plans', () {
    test('every experiment carries one, and it is complete', () {
      expect(benchLessons.length, labScenarios.length);
      for (final s in labScenarios) {
        final l = benchLessonFor(s.id);
        expect(l, isNotNull, reason: s.id);
        expect(l!.board.trim().isNotEmpty, isTrue, reason: s.id);
        // the misconception is the whole point of the plan: it
        // is never allowed to be a throwaway line
        expect(l.misconception.length, greaterThan(80),
            reason: s.id);
        expect(l.discuss.length, 3, reason: s.id);
        expect(l.discuss.toSet().length, 3, reason: s.id);
        for (final d in l.discuss) {
          expect(d.trim().isNotEmpty, isTrue, reason: s.id);
        }
        expect(l.closing.trim().isNotEmpty, isTrue, reason: s.id);
        expect(l.minutes, inInclusiveRange(5, 45), reason: s.id);
      }
    });

    test('no dashes anywhere: the house rule holds here too', () {
      for (final e in benchLessons.entries) {
        final all = [
          e.value.board,
          e.value.misconception,
          e.value.closing,
          ...e.value.discuss,
        ].join(' ');
        expect(all.contains('—'), isFalse, reason: e.key);
        expect(all.contains('–'), isFalse, reason: e.key);
      }
    });

    test('nothing in a lesson plan is a mark', () {
      for (final e in benchLessons.entries) {
        final all = [
          e.value.board,
          e.value.misconception,
          e.value.closing,
          ...e.value.discuss,
        ].join(' ').toLowerCase();
        for (final bad in [
          'score', 'grade', 'points', 'quiz', 'winner',
          'test them', 'well done',
        ]) {
          expect(all.contains(bad), isFalse,
              reason: '${e.key}: $bad');
        }
      }
    });

    test('the room is always asked a comparison, never the '
        'control', () {
      for (final s in labScenarios) {
        final l = benchLessonFor(s.id)!;
        // bench one is the control; asking about it would be
        // asking a question the experiment cannot answer
        expect(l.ask, greaterThan(0), reason: s.id);
        expect(l.ask, lessThan(s.options.length), reason: s.id);
      }
    });
  });

  group('the model answers the room honestly', () {
    String verdictFor(LabScenario s) {
      final l = benchLessonFor(s.id)!;
      final base = runBands(s, 0).mid[s.predictIndex].last;
      final lever = runBands(s, l.ask).mid[s.predictIndex].last;
      return benchVerdict(base, lever);
    }

    test('every lesson has a real difference to point at', () {
      for (final s in labScenarios) {
        expect(verdictFor(s), isNot('about the same'),
            reason: s.id);
      }
    });

    test('the surprises the plans promise are the ones the '
        'model actually gives', () {
      // the boats do not starve when a third of the sea closes
      expect(verdictFor(labScenarioById('mpa')!), 'higher');
      // letting small fires burn leaves LESS fuel, not more
      expect(verdictFor(labScenarioById('fire')!), 'lower');
      // the foxes never met a bee and still pay for them
      expect(verdictFor(labScenarioById('meadow')!), 'lower');
      // a predator turns out to be a gardener
      expect(verdictFor(labScenarioById('wolves')!), 'higher');
      // cutting ground in half is itself an injury
      expect(verdictFor(labScenarioById('corridor')!), 'higher');
      // the night shift recovers when the lamps do
      expect(verdictFor(labScenarioById('light')!), 'higher');
    });

    test('deterministic: the same lesson twice is the same '
        'lesson', () {
      for (final s in labScenarios) {
        final l = benchLessonFor(s.id)!;
        expect(runBands(s, l.ask).mid[s.predictIndex],
            equals(runBands(s, l.ask).mid[s.predictIndex]),
            reason: s.id);
      }
    });

    test('the dead band is real: a two point wobble is not a '
        'finding', () {
      expect(benchVerdict(0.5, 0.52), 'about the same');
      expect(benchVerdict(0.5, 0.48), 'about the same');
      expect(benchVerdict(0.5, 0.55), 'higher');
      expect(benchVerdict(0.5, 0.45), 'lower');
    });

    test('three answers, and they are comparative', () {
      expect(benchAnswers, ['higher', 'lower', 'about the same']);
    });
  });

  group('the room is read back to itself, never marked', () {
    Map<String, int> h(int hi, int lo, int same) =>
        {'higher': hi, 'lower': lo, 'about the same': same};

    test('agreement sends them looking for why', () {
      final v = roomVerdict(h(20, 4, 2), 'higher', 'Foxes');
      expect(v.toLowerCase(), contains('why'));
    });

    test('disagreement is named as the best place to begin', () {
      final v = roomVerdict(h(3, 18, 1), 'higher', 'The catch');
      expect(v.toLowerCase(), contains('best place'));
    });

    test('an even split keeps both sentences alive', () {
      final v = roomVerdict(h(5, 5, 0), 'higher', 'Willows');
      expect(v.toLowerCase(), contains('split'));
    });

    test('a room that never counted still gets a lesson', () {
      final v = roomVerdict(h(0, 0, 0), 'lower', 'Oxygen');
      expect(v.toLowerCase(), contains('no hands'));
    });

    test('no verdict ever grades anybody', () {
      for (final hands in [
        h(20, 4, 2),
        h(3, 18, 1),
        h(5, 5, 0),
        h(0, 0, 0),
      ]) {
        for (final w in benchAnswers) {
          final v = roomVerdict(hands, w, 'Foxes').toLowerCase();
          for (final bad in [
            'correct', 'wrong', 'score', 'right answer',
            'well done', 'mistake',
          ]) {
            expect(v.contains(bad), isFalse,
                reason: '$bad in "$v"');
          }
          expect(v.contains('—'), isFalse);
          expect(v.contains('–'), isFalse);
        }
      }
    });
  });
}
