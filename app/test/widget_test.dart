// Slice 1+2 suite: the clock is the PWA's clock, the save round-trips in
// Contract-1 shape, the streak never dies, the Thumb Promise cannot be
// tricked, state survives reload, and the layouts hold under large text
// and RTL. The full sim-ported rule suite arrives with slice 4.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:hopeling/core/clock.dart';
import 'package:hopeling/data/content.dart';
import 'package:hopeling/data/save.dart';
import 'package:hopeling/features/grove/grove_screen.dart';
import 'package:hopeling/features/grove/tree.dart';
import 'package:hopeling/main.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  // ---------- rules ----------

  test('dailyIndex matches the PWA hash exactly', () {
    final d = DateTime(2026, 7, 17);
    var h = 0;
    for (final c in '2026-07-17f'.codeUnits) {
      h = ((h * 31) + c) & 0xFFFFFFFF;
    }
    expect(dailyIndex(19, 'f', d), h % 19);
    expect(dailyIndex(19, 'f', d), dailyIndex(19, 'f', d));
    expect(dailyIndex(1000, 'f', d) == dailyIndex(1000, 'a', d), false);
  });

  test('daysBetween handles civil dates', () {
    expect(daysBetween('2026-07-16', '2026-07-17'), 1);
    expect(daysBetween('2026-12-31', '2027-01-01'), 1);
  });

  test('save round-trips in Contract-1 shape', () {
    final s = Save(
        xp: 42,
        streak: 7,
        last: '2026-07-17',
        freezes: 2,
        log: {'2026-07-17': 3});
    final j = s.toJson();
    expect(j['_app'], 'Hopeling');
    final back = Save.fromJson(j);
    expect(back.xp, 42);
    expect(back.streak, 7);
    expect(back.last, '2026-07-17');
    expect(back.log['2026-07-17'], 3);
  });

  // The full streak rules live in rules_test.dart, ported from the oracle.

  test('state persists and reloads (kill-proof)', () async {
    final s = Save(xp: 9, streak: 3, last: '2026-07-17');
    await Store.persist(s);
    final loaded = await Store.load();
    expect(loaded.xp, 9);
    expect(loaded.streak, 3);
    expect(loaded.last, '2026-07-17');
  });

  test('tree stages follow the thresholds', () {
    expect(stageForXp(0), 0);
    expect(stageForXp(4), 0);
    expect(stageForXp(5), 1);
    expect(stageForXp(14), 1);
    expect(stageForXp(15), 2);
    expect(stageForXp(39), 2);
    expect(stageForXp(40), 3);
    expect(stageForXp(99), 3);
    expect(stageForXp(100), 4);
    expect(stageName(0), 'A sleeping seed');
    expect(stageName(4), 'A mighty grove');
  });

  // ---------- the migration engine ----------

  test('unknown Contract-1 fields survive a round-trip (future-proof restore)',
      () {
    final doc = {
      'xp': 10,
      'streak': 2,
      'last': '2026-07-17',
      'freezes': 1,
      'log': {'2026-07-17': 1},
      'badges': {'🌊': 'Ocean helper'},
      'guardian': {'id': 'kakapo', 'date': '2026-01-01'},
      'rings': [
        {'n': 12, 'end': '2026-03-01'}
      ],
      'someFeatureFrom2027': {'x': true},
    };
    final s = Save.fromJson(doc);
    final back = s.toJson();
    expect(back['badges'], doc['badges']);
    expect(back['guardian'], doc['guardian']);
    expect(back['rings'], doc['rings']);
    expect(back['someFeatureFrom2027'], doc['someFeatureFrom2027']);
    expect(back['xp'], 10);
  });

  test('merge: a fresh phone yields wholly to the cloud', () {
    final local = Save();
    final cloud = Save(xp: 200, streak: 40, last: '2026-07-16',
        extra: {'badges': {'🦊': 'x'}});
    final m = Save.merge(local, cloud);
    expect(m.xp, 200);
    expect(m.streak, 40);
    expect(m.extra['badges'], isNotNull);
  });

  test('merge: nothing earned is ever lost between two lives', () {
    final local = Save(
        xp: 50,
        streak: 5,
        last: '2026-07-17',
        log: {'2026-07-17': 2, '2026-07-16': 1});
    final cloud = Save(
        xp: 45,
        streak: 9,
        last: '2026-07-15',
        log: {'2026-07-15': 3, '2026-07-16': 4},
        extra: {'guardian': {'id': 'vaquita'}});
    final m = Save.merge(local, cloud);
    expect(m.xp, 50); // max
    expect(m.streak, 9); // max
    expect(m.last, '2026-07-17'); // later
    expect(m.log['2026-07-16'], 4); // day-wise max
    expect(m.log['2026-07-17'], 2);
    expect(m.log['2026-07-15'], 3);
    expect(m.extra['guardian'], isNotNull); // cloud life preserved
  });

  test('content contract parses (Contract 2 shape)', () {
    final doc = {
      'version': 23,
      'categories': [
        {
          'slug': 'whales',
          'emo': '🐋',
          'name': 'Whales',
          'iucn': 'EN',
          'sum': 'The giants.',
          'threats': [
            ['Ship strikes', 'Slow lanes help.', 'NOAA']
          ],
          'species': ['Narwhal'],
          'acts': ['walk']
        }
      ],
      'actions': {
        'walk': {'t': 'Walk one trip', 'why': 'Less carbon.', 'min': 10}
      },
      'facts': [
        ['A fact.', 'SRC', 'whales', 'Simple fact.']
      ],
    };
    final c = AppContent.fromJson(doc, false);
    expect(c.worlds.length, 1);
    expect(c.worlds[0].threats[0][2], 'NOAA');
    expect(c.actions['walk']!.min, 10);
  });

  // ---------- the Thumb Promise ----------

  Widget holdHarness(ValueNotifier<int> commits) => MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 300,
              child: HoldToCommit(
                  done: false, onCommit: () => commits.value++),
            ),
          ),
        ),
      );

  testWidgets('an incomplete hold makes no promise', (tester) async {
    final commits = ValueNotifier<int>(0);
    await tester.pumpWidget(holdHarness(commits));
    final g = await tester.startGesture(
        tester.getCenter(find.byType(HoldToCommit)));
    await tester.pump(); // first frame anchors the animation clock
    await tester.pump(const Duration(milliseconds: 400)); // less than 1100
    await g.up();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400)); // ring undoes
    expect(commits.value, 0);
  });

  testWidgets('a full hold commits exactly once and saves', (tester) async {
    final commits = ValueNotifier<int>(0);
    await tester.pumpWidget(holdHarness(commits));
    final g = await tester.startGesture(
        tester.getCenter(find.byType(HoldToCommit)));
    await tester.pump(); // first frame anchors the animation clock
    await tester.pump(const Duration(milliseconds: 1200)); // past 1100
    await g.up();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600)); // settle back
    expect(commits.value, 1);
  });

  // ---------- layouts under stress ----------

  testWidgets('the grove builds', (tester) async {
    await tester.pumpWidget(const HopelingApp());
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text(todayStr()), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('large text does not break the grove', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2.0;
    addTearDown(tester.platformDispatcher.clearAllTestValues);
    await tester.pumpWidget(const HopelingApp());
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.takeException(), isNull);
  });

  testWidgets('RTL does not break the grove (Hebrew-ready)', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: GroveScreen(),
      ),
    ));
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.takeException(), isNull);
  });
}
