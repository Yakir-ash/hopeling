// The Little Meadow's constitution: the kids' first Lab runs on
// the real engine, speaks only fable lines, and can never end in
// the ruins - every branch closes on helping.

import 'package:flutter_test/flutter_test.dart';
import 'package:hopeling/data/lab.dart';
import 'package:hopeling/features/kids/games/little_meadow.dart';

void main() {
  test('nine fable lines, complete and calm', () {
    expect(littleMeadowLines.length, 9);
    expect(littleMeadowLines.toSet().length, 9);
    for (final l in littleMeadowLines) {
      expect(l.trim().isNotEmpty, isTrue);
      expect(l.contains('—'), isFalse, reason: l);
      expect(l.contains('–'), isFalse, reason: l);
    }
    final all = littleMeadowLines.join(' ').toLowerCase();
    for (final bad in [
      'die', 'dead', 'fail', 'wrong', 'hurry', 'too late',
      'your fault', 'score', 'points',
    ]) {
      expect(all.contains(bad), isFalse, reason: bad);
    }
  });

  test('no ruins endings: both closings land on helping', () {
    expect(lmClosing.toLowerCase(), contains('helped'));
    expect(lmClosingStay.toLowerCase(), contains('helped'));
    expect(lmClosing.toLowerCase(),
        contains('helpers change everything'));
    // and both branches carry a planting invitation
    expect(lmInviteRepair.toLowerCase(), contains('plant'));
    expect(lmInviteRicher.toLowerCase(), contains('plant'));
  });

  test('the same engine the grown-ups use, honestly', () {
    final meadow = labScenarioById('meadow')!;
    // the story's physics are the Lab's physics: recovery is
    // real but slower than never-losing (hysteresis holds even
    // in the children's telling)
    final degraded = runBands(meadow, 2).mid[0].last;
    final repaired = runRepair(meadow, 2).mid[0].last;
    final kept = runBands(meadow, 0).mid[0].last;
    expect(repaired, greaterThan(degraded));
    expect(repaired, lessThan(kept));
  });
}
