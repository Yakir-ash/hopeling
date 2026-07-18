// The Robin's pure logic vs the constitution: quiet hours hold, "tonight"
// reschedules kindly, Sunday reflects without evaluating, and no line of
// copy ever shames.

import 'package:flutter_test/flutter_test.dart';

import 'package:hopeling/core/deeplink.dart';
import 'package:hopeling/core/notify.dart';
import 'package:hopeling/data/save.dart';

void main() {
  test('quiet hours: 21:00 to 08:00, boundaries exact', () {
    expect(inQuietHours(20), false);
    expect(inQuietHours(21), true);
    expect(inQuietHours(23), true);
    expect(inQuietHours(0), true);
    expect(inQuietHours(7), true);
    expect(inQuietHours(8), false);
  });

  test('nextDaily: today if ahead, tomorrow if passed, quiet times nudged',
      () {
    final noon = DateTime(2026, 7, 17, 12, 0);
    expect(nextDaily(noon, 18, 30), DateTime(2026, 7, 17, 18, 30));
    expect(nextDaily(noon, 9, 0), DateTime(2026, 7, 18, 9, 0));
    // 22:00 preference falls in quiet hours: nudged to 08:00
    expect(nextDaily(noon, 22, 0), DateTime(2026, 7, 18, 8, 0));
    expect(nextDaily(DateTime(2026, 7, 17, 7, 0), 22, 0),
        DateTime(2026, 7, 17, 8, 0));
  });

  test('tonight: before evening → 19:30; evening → +2h; late → tomorrow',
      () {
    expect(tonightAt(DateTime(2026, 7, 17, 14, 0), 18, 30),
        DateTime(2026, 7, 17, 19, 30));
    // 18:59 is before evening
    expect(tonightAt(DateTime(2026, 7, 17, 18, 59), 18, 30),
        DateTime(2026, 7, 17, 19, 30));
    // 19:00 + 2h = 21:00 which is quiet → tomorrow at preference
    expect(tonightAt(DateTime(2026, 7, 17, 19, 0), 18, 30),
        DateTime(2026, 7, 18, 18, 30));
    // 20:30 + 2h = 22:30 quiet → tomorrow
    expect(tonightAt(DateTime(2026, 7, 17, 20, 30), 18, 30),
        DateTime(2026, 7, 18, 18, 30));
  });

  test('Sunday summary reflects, never evaluates', () {
    final s = Save(log: {
      '2026-07-15': 2,
      '2026-07-16': 1,
    }, extra: {
      'lessons': {'ocean-pollution0': true}
    });
    final line = sundaySummary(s, DateTime(2026, 7, 17));
    expect(line.contains('3 promises'), true);
    expect(line.contains('2 days'), true);
    expect(line.contains('1 chapters'), true);
    expect(line.toLowerCase().contains('missed'), false);
    // an empty week is rest, not failure
    final empty = sundaySummary(Save(), DateTime(2026, 7, 17));
    expect(empty.contains('rested'), true);
    expect(empty.toLowerCase().contains('missed'), false);
  });

  test('the copy never shames', () {
    final lines = [
      RobinCopy.dailyTitle,
      RobinCopy.dailyBody,
      RobinCopy.tonightTitle,
      RobinCopy.tonightBody,
      RobinCopy.sundayTitle,
      RobinCopy.privateBody,
      sundaySummary(Save(), DateTime(2026, 7, 17)),
    ];
    for (final l in lines) {
      for (final bad in [
        'miss you', 'don\'t lose', 'last chance', 'falling behind',
        'come back', 'hurry', 'only have', 'streak'
      ]) {
        expect(l.toLowerCase().contains(bad), false,
            reason: '"$l" contains "$bad"');
      }
    }
  });

  test('private previews hide everything', () {
    final p = RobinPrefs()..privatePreview = true;
    expect(RobinCopy.body(p, 'Your circle got four drops today'),
        RobinCopy.privateBody);
    final open = RobinPrefs();
    expect(RobinCopy.body(open, RobinCopy.dailyBody), RobinCopy.dailyBody);
  });

  test('notification deep links parse', () {
    expect(parseDeepLink('hopeling://today')!.type, 'today');
    expect(parseDeepLink('hopeling://today')!.id, '');
    expect(parseDeepLink('hopeling://today/why')!.id, 'why');
  });
}
