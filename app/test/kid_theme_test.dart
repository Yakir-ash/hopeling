// Hopeling Kids' design system vs the constitution: the guide is a
// companion, never a mascot with an agenda - its daily thoughts are
// pure wonder with no summons, no guilt, no parasocial hooks.

import 'package:flutter_test/flutter_test.dart';

import 'package:hopeling/core/kid_theme.dart';

void main() {
  test('the guide never guilts, summons, or performs missing you', () {
    expect(guideTips.length, greaterThanOrEqualTo(5));
    for (final t in guideTips) {
      for (final bad in [
        'waiting for you', 'missed you', 'miss you', 'come back',
        'where were you', 'streak', 'every day!', 'don\'t forget',
        'buy', 'unlock', 'reward'
      ]) {
        expect(t.toLowerCase().contains(bad), false,
            reason: '"$t" contains "$bad"');
      }
    }
  });

  test('the tickles are play, never pleading', () {
    expect(guideTickles.length, greaterThanOrEqualTo(3));
    for (final t in guideTickles) {
      for (final bad in [
        'waiting', 'missed', 'come back', 'again tomorrow', 'promise me'
      ]) {
        expect(t.toLowerCase().contains(bad), false);
      }
    }
  });

  test('the rooms each have their own weather', () {
    expect(kidRoomColors.length, 4);
    expect(kidRoomColors.toSet().length, 4); // all different
  });
}
