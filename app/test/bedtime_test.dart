// Bedtime vs the constitution: a ritual, not a feature. The window
// wraps midnight correctly, tonight's story cannot be renegotiated by
// reopening the app, the guardian's sleep is biology rather than
// theater, and nothing at the end pulls a child back in.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:hopeling/data/bedtime.dart';
import 'package:hopeling/data/content.dart';
import 'package:hopeling/features/kids/comic.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('the bedtime window wraps midnight', () {
    final p = BedtimePrefs(startMin: 19 * 60, endMin: 7 * 60);
    expect(inBedtimeWindow(DateTime(2026, 7, 20, 20, 0), p), true);
    expect(inBedtimeWindow(DateTime(2026, 7, 20, 23, 59), p), true);
    expect(inBedtimeWindow(DateTime(2026, 7, 21, 3, 0), p), true);
    expect(inBedtimeWindow(DateTime(2026, 7, 21, 6, 59), p), true);
    expect(inBedtimeWindow(DateTime(2026, 7, 21, 7, 0), p), false);
    expect(inBedtimeWindow(DateTime(2026, 7, 21, 12, 0), p), false);
    expect(inBedtimeWindow(DateTime(2026, 7, 21, 18, 59), p), false);
    // a non-wrapping window still works
    final day = BedtimePrefs(startMin: 12 * 60, endMin: 14 * 60);
    expect(inBedtimeWindow(DateTime(2026, 7, 21, 13, 0), day), true);
    expect(inBedtimeWindow(DateTime(2026, 7, 21, 15, 0), day), false);
    // a zero-width window is never bedtime
    final z = BedtimePrefs(startMin: 600, endMin: 600);
    expect(inBedtimeWindow(DateTime(2026, 7, 21, 10, 0), z), false);
  });

  test('one story per night: deterministic, un-renegotiable', () {
    final now = DateTime(2026, 7, 20, 20, 30);
    expect(tonightIndex(7, now), tonightIndex(7, now));
    expect(tonightIndex(0), 0); // empty shelf is safe
    // a different night may pick a different story
    final other = DateTime(2026, 7, 21, 20, 30);
    // (not asserting inequality - hash may collide - only stability)
    expect(tonightIndex(7, other), tonightIndex(7, other));
  });

  test('prefs round-trip', () async {
    final p = BedtimePrefs(
        auto: false, startMin: 1200, endMin: 400, maxMinutes: 8);
    await p.save();
    final back = await BedtimePrefs.load();
    expect(back.auto, false);
    expect(back.startMin, 1200);
    expect(back.endMin, 400);
    expect(back.maxMinutes, 8);
  });

  test('the guardian sleeps biologically, never as a cartoon', () {
    final owl = guardianRest('owls', 'Barn Owl');
    expect(owl.contains('awake now'), true); // owls do not sleep at night
    final fox = guardianRest('foxes', 'Red Fox');
    expect(fox.contains('curls'), true);
    final unknown = guardianRest('nowhere', 'Friend');
    expect(unknown.contains('settles into its safe place'), true);
    for (final line in [owl, fox, unknown]) {
      for (final bad in ['pajamas', 'teddy', 'dreams of you', 'misses you']) {
        expect(line.toLowerCase().contains(bad), false);
      }
    }
  });

  test('reflection is one gentle daily question', () {
    final now = DateTime(2026, 7, 20, 20, 0);
    expect(reflectionQuestion(now), reflectionQuestion(now));
    expect(reflectionQuestions.length, greaterThanOrEqualTo(3));
    for (final q in reflectionQuestions) {
      expect(q.endsWith('?'), true);
      for (final bad in ['should', 'must', 'why didn\'t']) {
        expect(q.toLowerCase().contains(bad), false);
      }
    }
  });

  test('bedtime pages carry one sentence each, losing nothing', () {
    final caps =
        bedtimeCaptions('The moon rises. Owls wake. Mice listen. All is well.');
    expect(caps.length, 4);
    expect(caps[0], 'The moon rises.');
    final long = bedtimeCaptions(
        List.generate(20, (i) => 'Sentence $i sleeps.').join(' '));
    expect(long.length, 12);
    for (var i = 0; i < 20; i++) {
      expect(long.join(' ').contains('Sentence $i sleeps.'), true);
    }
  });

  test('a bedtime book ends with goodnight, not a hook', () {
    final l = Lesson('The Quiet Pond', 3, '', 'Frogs float. Stars blink.',
        const []);
    final p = comicPanels(l, bedtime: true);
    expect(p.last.caption, 'Goodnight 🌙');
    expect(p.length, 2 + 2); // cover + 2 sentences + end
    for (final bad in [
      'one more', 'next story', 'don\'t stop', 'keep going', 'unlock'
    ]) {
      expect(p.last.caption.toLowerCase().contains(bad), false);
      expect(BedtimeCopy.ending.toLowerCase().contains(bad), false);
    }
    // and the healthy ending promises tomorrow instead
    expect(BedtimeCopy.ending.contains('tomorrow'), true);
  });
}
