// The Storyteller vs the constitution: a familiar voice, not a slot
// machine - the same story reads the same way every night; questions
// lift, endings land, bedtime slows everything, and no shaping ever
// escapes the clamp into squeak or drawl.

import 'package:flutter_test/flutter_test.dart';

import 'package:hopeling/core/storyteller.dart';

void main() {
  test('the same sentence is always read the same way', () {
    final a = sentenceProsody('The fox slept.', 1, 3);
    final b = sentenceProsody('The fox slept.', 1, 3);
    expect(a.rate, b.rate);
    expect(a.pitch, b.pitch);
    expect(a.pauseMs, b.pauseMs);
  });

  test('questions lift, exclamations brighten, statements rest', () {
    final q = sentenceProsody('Can owls see at night?', 1, 3);
    final s = sentenceProsody('Owls can see at night.', 1, 3);
    final e = sentenceProsody('Owls can see at night!', 1, 3);
    expect(q.pitch, greaterThan(s.pitch));
    expect(e.pitch, greaterThan(s.pitch));
    expect(q.pauseMs, greaterThan(s.pauseMs)); // wonder gets a beat
  });

  test('the last sentence lands softly with a longer breath', () {
    final mid = sentenceProsody('And so they walked.', 1, 4);
    final last = sentenceProsody('And so they walked.', 3, 4);
    expect(last.rate, lessThan(mid.rate));
    expect(last.pauseMs, greaterThan(mid.pauseMs));
  });

  test('bedtime slows the whole telling', () {
    final day = sentenceProsody('The moon rose.', 0, 2);
    final night = sentenceProsody('The moon rose.', 0, 2, bedtime: true);
    expect(night.rate, lessThan(day.rate));
    expect(night.pauseMs, greaterThan(day.pauseMs));
  });

  test('early explorers get more room than young guardians', () {
    final early = sentenceProsody('A seed grew.', 0, 2, band: 'early');
    final young = sentenceProsody('A seed grew.', 0, 2, band: 'young');
    expect(early.rate, lessThan(young.rate));
  });

  test('shaping never escapes the clamp', () {
    for (final s in [
      'Why? Why! Why?', 'Hello.', 'A very long wondering question indeed?',
      '!', '?'
    ]) {
      for (var i = 0; i < 3; i++) {
        final p = sentenceProsody(s, i, 3, bedtime: i == 1);
        expect(p.rate, inInclusiveRange(0.28, 0.55));
        expect(p.pitch, inInclusiveRange(0.85, 1.25));
        expect(p.pauseMs, lessThanOrEqualTo(1400));
      }
    }
  });

  test('sentences split cleanly and lose nothing', () {
    final s = storySentences('One. Two? Three!  ');
    expect(s, ['One.', 'Two?', 'Three!']);
    expect(storySentences('   '), isEmpty);
  });

  test('voice ranking prefers natural English voices', () {
    expect(
        voiceScore({'name': 'en-us-x-abc-network', 'locale': 'en-US'}),
        greaterThan(voiceScore(
            {'name': 'en-us-x-abc-local', 'locale': 'en-US'})));
    expect(voiceScore({'name': 'fr-fr-x-neural', 'locale': 'fr-FR'}),
        lessThan(100)); // non-English never wins
    expect(voiceScore({'name': 'en-gb-wavenet-a', 'locale': 'en-GB'}),
        greaterThanOrEqualTo(160));
  });
}
