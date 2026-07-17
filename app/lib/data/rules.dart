// The Forgiveness Engine - pure Dart, no Flutter, no I/O.
// Ported line-by-line from the PWA oracle (core.js touchStreak, repairable,
// repairStreak, addRing, longestStreak; features.js GROVE_STAGES/FRIENDS).
// The UI renders results; it never computes rules.
//
// Deviations from the oracle, documented:
// 1. longestStreak uses civil-day differences instead of raw 86400000ms
//    equality - identical results except across DST transitions, where the
//    oracle would (wrongly) break a run. We keep the run. Forgiveness wins.
// 2. Backwards device clock (last is in the future): the oracle would compute
//    a negative gap and reset the streak. We treat it as "today already
//    counted": nothing increments, nothing resets, `last` is left alone so
//    continuity self-heals when the clock returns. Never punitive.

import 'save.dart';
import '../core/clock.dart';

// ---------- the grove tables (features.js, verbatim) ----------
const groveStages = [
  [0, '🌰', 'Sleeping seed'],
  [1, '🌱', 'Sprout'],
  [3, '🌿', 'Seedling'],
  [7, '🌳', 'Young tree'],
  [14, '🌳', 'Strong tree'],
  [30, '🌳', 'Flourishing tree'],
  [60, '🌲', 'Mighty grove'],
  [100, '🌲', 'Ancient grove'],
];

const groveFriends = [
  [7, '🐦', 'a robin'],
  [14, '🐝', 'a bee'],
  [21, '🦋', 'a butterfly'],
  [30, '🐿️', 'a squirrel'],
  [45, '🦔', 'a hedgehog'],
  [60, '🦊', 'a fox'],
  [90, '🦉', 'an owl'],
  [120, '🦌', 'a deer'],
];

/// groveStageIdx(s) - verbatim.
int stageIdx(int streak) {
  var i = 0;
  for (var j = 0; j < groveStages.length; j++) {
    if (streak >= (groveStages[j][0] as int)) i = j;
  }
  return i;
}

String stageLabel(int idx) => groveStages[idx][2] as String;
String stageEmoji(int idx) => groveStages[idx][1] as String;

/// The 8 PWA stages mapped onto the 5 painted tree forms.
int painterStage(int idx) => const [0, 1, 2, 3, 3, 4, 4, 4][idx];

/// Friends arrive at best-ever milestones and stay forever (features.js).
List<String> friendsFor(int best) => [
      for (final f in groveFriends)
        if (best >= (f[0] as int)) f[1] as String
    ];

/// longestStreak() - civil-day port (deviation 1).
int longestStreak(Map<String, int> log) {
  final days = log.keys.where((d) => (log[d] ?? 0) > 0).toList()..sort();
  if (days.isEmpty) return 0;
  var best = 1, cur = 1;
  for (var i = 1; i < days.length; i++) {
    if (daysBetween(days[i - 1], days[i]) == 1) {
      cur++;
      if (cur > best) best = cur;
    } else {
      cur = 1;
    }
  }
  return best;
}

int groveBest(Save s) {
  final l = longestStreak(s.log);
  return s.streak > l ? s.streak : l;
}

// ---------- completion (touchStreak, verbatim + clock guard) ----------
class CompleteOutcome {
  final bool firstOfDay;
  final bool freezeUsed;
  final bool freezeEarned;
  final int? ringAdded; // the n of the ring, if one formed
  final String? newFriend; // '🐦 robin' style, only on first earn
  final int stageBefore;
  final int stageAfter;
  CompleteOutcome(this.firstOfDay, this.freezeUsed, this.freezeEarned,
      this.ringAdded, this.newFriend, this.stageBefore, this.stageAfter);
}

CompleteOutcome complete(Save s, String today) {
  final stageBefore = stageIdx(s.streak);
  var firstOfDay = false, freezeUsed = false, freezeEarned = false;
  int? ringAdded;
  String? newFriend;

  final clockBackwards = s.last.isNotEmpty && s.last.compareTo(today) > 0;
  if (!clockBackwards && s.last != today) {
    firstOfDay = true;
    if (s.last.isNotEmpty) {
      final gap = daysBetween(s.last, today);
      if (gap == 1) {
        s.streak++;
      } else if (gap == 2 && s.freezes > 0) {
        s.freezes--;
        s.streak++;
        freezeUsed = true;
      } else {
        if (s.streak >= 3) {
          _addRing(s, s.streak, s.last);
          ringAdded = s.streak;
        }
        s.streak = 1;
      }
    } else {
      s.streak = 1;
    }
    s.last = today;
    if (s.streak > 0 && s.streak % 7 == 0 && s.freezes < 3) {
      s.freezes++;
      freezeEarned = true;
    }
    for (final f in groveFriends) {
      final at = f[0] as int;
      if (s.streak == at && s.milestones['friend$at'] != 1) {
        s.milestones['friend$at'] = 1;
        newFriend = '${f[1]} ${(f[2] as String).replaceFirst(RegExp(r'^an? '), '')}';
      }
    }
  }
  s.xp += 1;
  s.log[today] = (s.log[today] ?? 0) + 1;
  return CompleteOutcome(firstOfDay, freezeUsed, freezeEarned, ringAdded,
      newFriend, stageBefore, stageIdx(s.streak));
}

void _addRing(Save s, int n, String end) {
  s.rings.insert(0, {'n': n, 'end': end});
  if (s.rings.length > 24) s.rings.removeRange(24, s.rings.length);
}

// ---------- repair (verbatim) ----------
bool repairable(Save s, String today) =>
    s.last.isNotEmpty &&
    s.last.compareTo(today) <= 0 &&
    daysBetween(s.last, today) == 2 &&
    s.streak >= 2 &&
    s.lastRepair != today;

void repair(Save s, String today) {
  s.last = addDays(today, -1);
  s.lastRepair = today;
}

// ---------- the return assessment ----------
enum ReturnCategory { none, oneDay, short, fog, long }

class ReturnState {
  final ReturnCategory category;
  final int daysMissed;
  final bool repairAvailable;
  ReturnState(this.category, this.daysMissed, this.repairAvailable);
}

ReturnState assess(Save s, String today) {
  if (s.last.isEmpty || s.last.compareTo(today) > 0) {
    return ReturnState(ReturnCategory.none, 0, false);
  }
  final gap = daysBetween(s.last, today);
  final missed = gap - 1;
  final rep = repairable(s, today);
  if (missed <= 0) return ReturnState(ReturnCategory.none, 0, false);
  if (missed == 1) return ReturnState(ReturnCategory.oneDay, 1, rep);
  if (missed <= 4) return ReturnState(ReturnCategory.short, missed, false);
  if (missed <= 13) return ReturnState(ReturnCategory.fog, missed, false);
  return ReturnState(ReturnCategory.long, missed, false);
}

// ---------- the forgiveness copy model ----------
// One place, structured, warm, truthful. No shame words anywhere.
class Lines {
  static String returned(ReturnState r) {
    switch (r.category) {
      case ReturnCategory.oneDay:
        return 'Yesterday rested. Today is still here.';
      case ReturnCategory.short:
        return 'The grove waited.';
      case ReturnCategory.fog:
        return 'You were away for ${r.daysMissed} days. Nothing here was lost.';
      case ReturnCategory.long:
        return 'You came back. That matters more than the number.';
      case ReturnCategory.none:
        return '';
    }
  }

  static const freezeUsed = 'Yesterday became a rest day. Your rhythm continues.';
  static String freezeEarned(int kept) =>
      'A rest day was earned. You are keeping $kept.';
  static String ringFormed(int n) =>
      'Your $n days became a ring in the trunk. Never lost.';
  static const repaired = 'Yesterday is mended.';
  static const repairOffer = 'Yesterday fell. You can mend it.';
  static String friendArrived(String friend) => '$friend arrived, and stays.';

  /// Screen-reader summary - no internal jargon.
  static String rhythm(Save s, String today) {
    final b = groveBest(s);
    var t = 'Current rhythm: ${s.streak} active days. Best: $b.';
    if (s.freezes > 0) {
      t += ' ${s.freezes} rest ${s.freezes == 1 ? 'day' : 'days'} available.';
    }
    if (repairable(s, today)) t += ' Yesterday can be repaired.';
    return t;
  }
}
