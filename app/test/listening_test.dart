// The Listening Post's constitution: five complete voices, every
// recordist credited, a quiz that is deterministic (same day,
// same questions), fair (every voice gets its turn as the
// answer), and warm (a wrong door is an introduction, never a
// failure).

import 'package:flutter_test/flutter_test.dart';
import 'package:hopeling/data/errands.dart';
import 'package:hopeling/data/listening.dart';

void main() {
  group('the shelf', () {
    test('five voices, unique, complete', () {
      expect(birdVoices.length, 5);
      expect(birdVoices.map((v) => v.id).toSet().length, 5);
      expect(birdVoices.map((v) => v.file).toSet().length, 5);
      for (final v in birdVoices) {
        expect(v.file.endsWith('.mp3'), isTrue, reason: v.id);
        expect(v.hook.length, greaterThan(50), reason: v.id);
        expect(v.story.length, greaterThan(40), reason: v.id);
        expect(v.when.length, greaterThan(25), reason: v.id);
        expect(v.sci.contains(' '), isTrue, reason: v.id);
      }
      expect(birdAudioBase.startsWith('https://hopeling.app'),
          isTrue);
    });

    test('every recordist is credited - the license\'s price', () {
      for (final v in birdVoices) {
        expect(v.recordist.trim().split(' ').length,
            greaterThanOrEqualTo(2),
            reason: v.id);
        expect(RegExp(r'^XC\d+$').hasMatch(v.xc), isTrue,
            reason: v.id);
        expect(v.xcUrl, contains('xeno-canto.org/'));
        expect(v.xcUrl.contains('XC'), isFalse,
            reason: 'the url wants the bare number');
      }
    });
  });

  group('the quiz - a book, not a slot machine', () {
    test('same day, same quiz', () {
      final t = DateTime(2026, 8, 16, 9);
      final a = quizRounds(t);
      final b = quizRounds(DateTime(2026, 8, 16, 21));
      for (var i = 0; i < a.length; i++) {
        expect(a[i].answer.id, b[i].answer.id);
        expect([for (final o in a[i].options) o.id],
            [for (final o in b[i].options) o.id]);
      }
    });

    test('five rounds; every voice sings as the answer once', () {
      for (var d = 1; d <= 366; d += 31) {
        final t = DateTime(2026, 1, 1).add(Duration(days: d));
        final rounds = quizRounds(t);
        expect(rounds.length, 5);
        expect(rounds.map((r) => r.answer.id).toSet().length, 5,
            reason: 'day $d');
      }
    });

    test('three options, answer among them, no duplicates', () {
      for (var d = 1; d <= 366; d += 13) {
        final t = DateTime(2026, 1, 1).add(Duration(days: d));
        for (final r in quizRounds(t)) {
          expect(r.options.length, 3);
          expect(r.options.map((o) => o.id).toSet().length, 3);
          expect(r.options.any((o) => o.id == r.answer.id),
              isTrue);
        }
      }
    });

    test('the answer is not always the first door', () {
      var firsts = 0, total = 0;
      for (var d = 1; d <= 366; d += 7) {
        final t = DateTime(2026, 1, 1).add(Duration(days: d));
        for (final r in quizRounds(t)) {
          total++;
          if (r.options.first.id == r.answer.id) firsts++;
        }
      }
      expect(firsts, lessThan(total * 0.6));
      expect(firsts, greaterThan(0));
    });
  });

  group('the rite and the tone', () {
    test('the dawn sit exists and renders as an errand', () {
      final e = errandById('dawn-sit');
      expect(e, isNotNull);
      expect(e!.text.toLowerCase(), contains('first light'));
      expect(e.note.startsWith('I '), isTrue);
    });

    test('calm words: no tests, no failure, no dashes', () {
      final all = [
        for (final v in birdVoices) ...[
          v.name, v.hook, v.story, v.when,
        ],
        dawnSit.text,
        dawnSit.note,
      ].join(' ');
      for (final bad in [
        'fail', 'wrong!', 'score', 'test yourself', 'hurry',
        'earn points',
      ]) {
        expect(all.toLowerCase().contains(bad), isFalse,
            reason: bad);
      }
      expect(all.contains('—'), isFalse);
      expect(all.contains('–'), isFalse);
    });
  });
}
