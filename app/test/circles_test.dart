// Circles vs the constitution: PWA-parity week keys, stale weeks never
// count, summaries cooperate instead of comparing, and no line of copy
// competes, shames, or surveils.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:hopeling/core/deeplink.dart';
import 'package:hopeling/data/circles.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('weekKey matches the PWA formula exactly', () {
    // Reproduce the oracle by hand for a fixed date.
    final d = DateTime(2026, 7, 17);
    final oj = DateTime(2026, 1, 1);
    final w =
        ((d.difference(oj).inDays + (oj.weekday % 7) + 1) / 7).ceil();
    expect(weekKey(d), '2026-W$w');
    // Unpadded, like the sim fixture '2020-W1'.
    expect(weekKey(DateTime(2020, 1, 1)), startsWith('2020-W'));
    expect(weekKey(DateTime(2020, 1, 1)).contains('W0'), false);
  });

  test('stale weeks never count in the grove (the sim rule)', () {
    final wk = weekKey(DateTime(2026, 7, 17));
    final rows = [
      Member('a', 'Yakir', wk, 5, 3, 100),
      Member('b', 'Mom', wk, 2, 1, 20),
      Member('c', 'Old', '2020-W1', 9, 0, 50), // stale: invisible
    ];
    expect(weekTotal(rows, wk), 7);
    expect(weekParticipants(rows, wk), 2);
  });

  test('the summary cooperates, never compares', () {
    final wk = weekKey(DateTime(2026, 7, 17));
    final rows = [
      Member('a', 'Yakir', wk, 3, 1, 10),
      Member('b', 'Mom', wk, 1, 1, 5),
    ];
    expect(groveSummary(rows, wk), '2 people added 4 drops this week.');
    expect(groveSummary([], wk), CircleCopy.quietWeek);
    expect(groveSummary([Member('a', 'Y', wk, 1, 1, 1)], wk),
        '1 person added 1 drop this week.');
  });

  test('circle list round-trips and never duplicates', () async {
    SharedPreferences.setMockInitialValues({
      'myCircles':
          '[{"id":7,"name":"Fam","code":"ABCDEF","type":"family"}]'
    });
    final list = await Circles.mine();
    expect(list.length, 1);
    expect(list.first.code, 'ABCDEF');
    // archive moves, restore returns, nothing is lost
    await Circles.archive(list.first);
    expect(await Circles.mine(), isEmpty);
    final arch = await Circles.mine(archived: true);
    expect(arch.length, 1);
    await Circles.restore(arch.first);
    expect((await Circles.mine()).length, 1);
    expect(await Circles.mine(archived: true), isEmpty);
  });

  test('quiet mode replaces the name, not the participation', () async {
    await Circles.setDisplayName('Yakir');
    await Circles.setAnonymous(true);
    expect(await Circles.anonymous(), true);
    expect(CircleCopy.anonName.isNotEmpty, true);
    expect(CircleCopy.anonName.toLowerCase().contains('yakir'), false);
  });

  test('invite deep links parse in both shapes', () {
    final inv = parseDeepLink('hopeling://circle/invite/kwxqpz');
    expect(inv!.type, 'circleInvite');
    expect(inv.id, 'KWXQPZ');
    expect(parseDeepLink('hopeling://circle/12')!.type, 'circle');
  });

  test('the copy never competes, shames, or surveils', () {
    final lines = [
      CircleCopy.quietWeek,
      CircleCopy.firstDrop,
      CircleCopy.leaveTitle,
      CircleCopy.leaveBody,
      CircleCopy.left,
      CircleCopy.archived,
      CircleCopy.needAccount,
      CircleCopy.badCode,
      CircleCopy.invite('Fam', 'ABCDEF'),
      groveSummary([], weekKey()),
    ];
    for (final l in lines) {
      for (final bad in [
        'falling behind', 'let your', 'losing', 'beat', 'rank', 'top ',
        'leaderboard', 'abandon', 'last place', 'watching you'
      ]) {
        expect(l.toLowerCase().contains(bad), false,
            reason: '"$l" contains "$bad"');
      }
    }
  });
}
