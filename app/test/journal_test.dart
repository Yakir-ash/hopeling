// The Nature Journal vs the constitution: a fresh page every day with
// no streaks and no guilt, file names that parse back losslessly, and
// prompts that invite rather than assign.

import 'package:flutter_test/flutter_test.dart';

import 'package:hopeling/data/journal.dart';

void main() {
  test('the daily prompt is deterministic and always an invitation', () {
    final now = DateTime(2026, 7, 22);
    expect(journalPrompt(now), journalPrompt(now));
    for (final p in journalPrompts) {
      expect(p.startsWith('Draw'), true); // one verb, gently
      for (final bad in [
        'must', 'should', 'homework', 'assignment', 'don\'t forget',
        'every day or'
      ]) {
        expect(p.toLowerCase().contains(bad), false);
      }
    }
  });

  test('file names round-trip and reject strangers', () {
    expect(journalFileName('k1', '2026-07-22'), 'j_k1_2026-07-22.png');
    expect(journalDayOf('j_k1_2026-07-22.png', 'k1'), '2026-07-22');
    expect(journalDayOf('j_k2_2026-07-22.png', 'k1'), null); // other child
    expect(journalDayOf('j_k1_not-a-date.png', 'k1'), null);
    expect(journalDayOf('random.txt', 'k1'), null);
  });

  test('the museum copy carries no guilt', () {
    for (final line in [
      JournalCopy.doorSub, JournalCopy.saved, JournalCopy.emptyMuseum
    ]) {
      for (final bad in ['missed', 'streak', 'behind', 'catch up', 'lost']) {
        expect(line.toLowerCase().contains(bad), false);
      }
    }
    expect(JournalCopy.emptyMuseum.contains('No hurry'), true);
  });
}
