// Slice-1 tests: the clock is the PWA's clock, the save round-trips in
// Contract-1 shape, the streak never dies, and the grove builds.
// The full sim-ported rule suite arrives with slice 4.

import 'package:flutter_test/flutter_test.dart';

import 'package:hopeling/core/clock.dart';
import 'package:hopeling/data/save.dart';
import 'package:hopeling/main.dart';

void main() {
  test('dailyIndex matches the PWA hash exactly', () {
    // Oracle values computed with core.js logic for a fixed date.
    final d = DateTime(2026, 7, 17);
    // h over '2026-07-17f' -> reproduce independently:
    var h = 0;
    for (final c in '2026-07-17f'.codeUnits) {
      h = ((h * 31) + c) & 0xFFFFFFFF;
    }
    expect(dailyIndex(19, 'f', d), h % 19);
    expect(dailyIndex(19, 'f', d), dailyIndex(19, 'f', d)); // deterministic
    expect(dailyIndex(1000, 'f', d) == dailyIndex(1000, 'a', d), false);
  });

  test('daysBetween handles civil dates', () {
    expect(daysBetween('2026-07-16', '2026-07-17'), 1);
    expect(daysBetween('2026-07-10', '2026-07-17'), 7);
    expect(daysBetween('2026-12-31', '2027-01-01'), 1);
  });

  test('save round-trips in Contract-1 shape', () {
    final s = Save(xp: 42, streak: 7, last: '2026-07-17', freezes: 2,
        log: {'2026-07-17': 3});
    final j = s.toJson();
    expect(j['_app'], 'Hopeling');
    final back = Save.fromJson(j);
    expect(back.xp, 42);
    expect(back.streak, 7);
    expect(back.last, '2026-07-17');
    expect(back.freezes, 2);
    expect(back.log['2026-07-17'], 3);
  });

  test('the streak never dies: gaps rest, first-of-day increments', () {
    final s = Save();
    final day1 = DateTime(2026, 7, 1);
    expect(s.complete(day1), true); // first of day
    expect(s.streak, 1);
    expect(s.complete(day1), false); // extra drop, same day
    expect(s.streak, 1);
    expect(s.xp, 2);
    final day2 = DateTime(2026, 7, 2);
    expect(s.complete(day2), true);
    expect(s.streak, 2);
    // A week of silence. The tree rested. Nothing was lost.
    final day9 = DateTime(2026, 7, 9);
    expect(s.complete(day9), true);
    expect(s.streak, 3);
  });

  testWidgets('the grove builds', (WidgetTester tester) async {
    await tester.pumpWidget(const HopelingApp());
    expect(find.text('small actions, real hope'), findsOneWidget);
  });
}
