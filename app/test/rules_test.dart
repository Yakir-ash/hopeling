// The forgiveness engine vs the oracle. Every rule ported from core.js
// (touchStreak, repairable, repairStreak, addRing, longestStreak) has its
// case here, plus the time-and-conflict cases the PWA never had to face.

import 'package:flutter_test/flutter_test.dart';

import 'package:hopeling/core/clock.dart';
import 'package:hopeling/data/rules.dart' as rules;
import 'package:hopeling/data/save.dart';

void main() {
  // ---------- completion (touchStreak parity) ----------

  test('first completion starts the rhythm', () {
    final s = Save();
    final out = rules.complete(s, '2026-07-01');
    expect(out.firstOfDay, true);
    expect(s.streak, 1);
    expect(s.last, '2026-07-01');
    expect(s.log['2026-07-01'], 1);
  });

  test('consecutive days increment', () {
    final s = Save(streak: 1, last: '2026-07-01');
    rules.complete(s, '2026-07-02');
    expect(s.streak, 2);
  });

  test('duplicate same-day completion adds a drop, not a day', () {
    final s = Save(streak: 3, last: '2026-07-03', xp: 10);
    final out = rules.complete(s, '2026-07-03');
    expect(out.firstOfDay, false);
    expect(s.streak, 3);
    expect(s.xp, 11);
    expect(s.log['2026-07-03'], 1);
  });

  test('one missed day with a rest day available: rhythm continues', () {
    final s = Save(streak: 5, last: '2026-07-01', freezes: 2);
    final out = rules.complete(s, '2026-07-03'); // gap 2
    expect(out.freezeUsed, true);
    expect(s.freezes, 1);
    expect(s.streak, 6);
  });

  test('one missed day with no rest day: reset with a ring (3+)', () {
    final s = Save(streak: 5, last: '2026-07-01', freezes: 0);
    final out = rules.complete(s, '2026-07-03');
    expect(out.freezeUsed, false);
    expect(out.ringAdded, 5);
    expect(s.streak, 1);
    expect(s.rings.first['n'], 5);
    expect(s.rings.first['end'], '2026-07-01');
  });

  test('short streaks (under 3) leave no ring', () {
    final s = Save(streak: 2, last: '2026-07-01');
    final out = rules.complete(s, '2026-07-05');
    expect(out.ringAdded, null);
    expect(s.rings, isEmpty);
    expect(s.streak, 1);
  });

  test('long absence: reset with ring, history intact', () {
    final s = Save(
        streak: 30,
        last: '2026-06-01',
        freezes: 3,
        rings: [{'n': 12, 'end': '2026-04-01'}],
        milestones: {'friend7': 1, 'friend14': 1, 'friend21': 1, 'friend30': 1});
    rules.complete(s, '2026-07-17'); // 45 days later
    expect(s.streak, 1);
    expect(s.rings.length, 2); // old ring kept, new added
    expect(s.rings.first['n'], 30);
    expect(s.milestones['friend30'], 1); // friends never leave
    expect(s.freezes, 3); // freezes are not consumed by long gaps
  });

  test('rings cap at 24, newest first', () {
    final s = Save(rings: [
      for (var i = 0; i < 24; i++) {'n': 3, 'end': '2026-01-01'}
    ], streak: 4, last: '2026-07-01');
    rules.complete(s, '2026-07-09');
    expect(s.rings.length, 24);
    expect(s.rings.first['n'], 4);
  });

  test('a rest day is earned every 7 days, kept to a maximum of 3', () {
    final s = Save(streak: 6, last: '2026-07-01', freezes: 0);
    final out = rules.complete(s, '2026-07-02'); // streak hits 7
    expect(out.freezeEarned, true);
    expect(s.freezes, 1);
    final s2 = Save(streak: 13, last: '2026-07-01', freezes: 3);
    final out2 = rules.complete(s2, '2026-07-02'); // 14, but already at cap
    expect(out2.freezeEarned, false);
    expect(s2.freezes, 3);
  });

  test('friends arrive at milestones once, and never re-announce', () {
    final s = Save(streak: 6, last: '2026-07-01');
    final out = rules.complete(s, '2026-07-02');
    expect(out.newFriend, contains('robin'));
    expect(s.milestones['friend7'], 1);
    // rebuild to 7 again after a reset: no re-announcement
    final s2 = Save(streak: 6, last: '2026-07-01',
        milestones: {'friend7': 1});
    final out2 = rules.complete(s2, '2026-07-02');
    expect(out2.newFriend, null);
  });

  // ---------- repair (repairable/repairStreak parity) ----------

  test('repair window: missed exactly yesterday, streak 2+, once per day', () {
    expect(
        rules.repairable(
            Save(streak: 4, last: '2026-07-15'), '2026-07-17'),
        true);
    expect(
        rules.repairable(
            Save(streak: 1, last: '2026-07-15'), '2026-07-17'),
        false); // streak too small
    expect(
        rules.repairable(
            Save(streak: 4, last: '2026-07-14'), '2026-07-17'),
        false); // gap 3
    expect(
        rules.repairable(
            Save(streak: 4, last: '2026-07-16'), '2026-07-17'),
        false); // nothing missed
    expect(
        rules.repairable(
            Save(streak: 4, last: '2026-07-15', lastRepair: '2026-07-17'),
            '2026-07-17'),
        false); // already repaired today
  });

  test('repair then completion continues the streak (no freeze spent)', () {
    final s = Save(streak: 4, last: '2026-07-15', freezes: 2);
    rules.repair(s, '2026-07-17');
    expect(s.last, '2026-07-16');
    expect(s.lastRepair, '2026-07-17');
    rules.complete(s, '2026-07-17');
    expect(s.streak, 5);
    expect(s.freezes, 2); // repair saved the rest day
  });

  // ---------- time is never a weapon ----------

  test('backwards device clock: nothing increments, nothing resets', () {
    final s = Save(streak: 8, last: '2026-07-17', freezes: 1);
    final out = rules.complete(s, '2026-07-15'); // clock moved back 2 days
    expect(out.firstOfDay, false);
    expect(s.streak, 8);
    expect(s.freezes, 1);
    expect(s.last, '2026-07-17'); // continuity self-heals later
    expect(s.xp, 1); // the action itself still counts
  });

  test('civil dates ignore DST distortions', () {
    // Israel DST transitions around late March / late October.
    expect(daysBetween('2026-03-26', '2026-03-28'), 2);
    expect(daysBetween('2026-10-24', '2026-10-26'), 2);
    expect(addDays('2026-03-27', 1), '2026-03-28');
  });

  test('date line crossing is just another civil day', () {
    // Completed in Tokyo on the 17th, opened in Hawaii still on the 17th:
    // same civil day, duplicate rules apply, nothing breaks.
    final s = Save(streak: 3, last: '2026-07-17');
    final out = rules.complete(s, '2026-07-17');
    expect(out.firstOfDay, false);
    expect(s.streak, 3);
    // Westward travel making "yesterday" repeat is the backwards-clock case,
    // already protected above.
  });

  test('longestStreak reads history correctly', () {
    expect(
        rules.longestStreak({
          '2026-07-01': 1,
          '2026-07-02': 2,
          '2026-07-03': 1,
          '2026-07-08': 1,
          '2026-07-09': 1,
        }),
        3);
    expect(rules.longestStreak({}), 0);
  });

  test('grove stages and friends follow the oracle tables', () {
    expect(rules.stageIdx(0), 0);
    expect(rules.stageIdx(1), 1);
    expect(rules.stageIdx(3), 2);
    expect(rules.stageIdx(7), 3);
    expect(rules.stageIdx(14), 4);
    expect(rules.stageIdx(30), 5);
    expect(rules.stageIdx(60), 6);
    expect(rules.stageIdx(100), 7);
    expect(rules.stageLabel(0), 'Sleeping seed');
    expect(rules.stageLabel(7), 'Ancient grove');
    expect(rules.friendsFor(6), isEmpty);
    expect(rules.friendsFor(7), ['🐦']);
    expect(rules.friendsFor(45).length, 5);
    // A reset streak drops the stage but never the friends.
    final s = Save(streak: 0, log: {
      for (var i = 1; i <= 21; i++)
        addDays('2026-06-01', i): 1
    });
    expect(rules.groveBest(s) >= 21, true);
    expect(rules.friendsFor(rules.groveBest(s)), contains('🦋'));
  });

  // ---------- return states ----------

  test('return categories match the design', () {
    expect(rules.assess(Save(last: '2026-07-16', streak: 3), '2026-07-17')
        .category, rules.ReturnCategory.none);
    expect(rules.assess(Save(last: '2026-07-15', streak: 3), '2026-07-17')
        .category, rules.ReturnCategory.oneDay);
    expect(rules.assess(Save(last: '2026-07-13', streak: 3), '2026-07-17')
        .category, rules.ReturnCategory.short);
    expect(rules.assess(Save(last: '2026-07-08', streak: 3), '2026-07-17')
        .category, rules.ReturnCategory.fog);
    expect(rules.assess(Save(last: '2026-06-01', streak: 3), '2026-07-17')
        .category, rules.ReturnCategory.long);
    // future last (clock weirdness): calm nothing
    expect(rules.assess(Save(last: '2026-07-20', streak: 3), '2026-07-17')
        .category, rules.ReturnCategory.none);
  });

  test('copy never shames', () {
    for (final cat in rules.ReturnCategory.values) {
      final line = rules.Lines.returned(
          rules.ReturnState(cat, 6, false));
      for (final bad in ['lose', 'lost your', 'fail', 'last chance', 'broke']) {
        expect(line.toLowerCase().contains(bad), false,
            reason: '"$line" contains "$bad"');
      }
    }
  });

  // ---------- multi-device (merge determinism + idempotency) ----------

  test('merge is idempotent and unions history', () {
    final a = Save(
        xp: 50, streak: 5, last: '2026-07-17',
        log: {'2026-07-17': 2},
        rings: [{'n': 9, 'end': '2026-05-01'}],
        milestones: {'friend7': 1});
    final b = Save(
        xp: 45, streak: 9, last: '2026-07-15',
        log: {'2026-07-15': 3},
        rings: [{'n': 12, 'end': '2026-04-01'}],
        milestones: {'friend14': 1});
    final m1 = Save.merge(a, b);
    final m2 = Save.merge(m1, b); // running twice
    expect(m2.xp, m1.xp);
    expect(m2.streak, m1.streak);
    expect(m2.rings.length, 2);
    expect(m1.rings.length, 2);
    expect(m1.milestones['friend7'], 1);
    expect(m1.milestones['friend14'], 1);
    expect(m1.log['2026-07-17'], 2);
    expect(m1.log['2026-07-15'], 3);
  });

  test('repaired state survives a merge with an offline device', () {
    final repaired = Save(
        xp: 10, streak: 5, last: '2026-07-16', lastRepair: '2026-07-17');
    final offline = Save(xp: 9, streak: 4, last: '2026-07-15');
    final m = Save.merge(offline, repaired);
    expect(m.lastRepair, '2026-07-17');
    expect(m.last, '2026-07-16');
  });

  test('rings and lastRepair round-trip through the contract', () {
    final s = Save(
        rings: [{'n': 7, 'end': '2026-06-30'}],
        lastRepair: '2026-07-01',
        milestones: {'friend7': 1});
    final back = Save.fromJson(s.toJson());
    expect(back.rings.first['n'], 7);
    expect(back.lastRepair, '2026-07-01');
    expect(back.milestones['friend7'], 1);
  });
}
