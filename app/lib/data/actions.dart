// The Daily Action Engine - pure Dart, deterministic, explainable.
//
// The PRIMARY pick is sacred: it is the PWA's own algorithm (the causes
// pool + dailyIndex with salt 'a'), so the same person sees the same
// today on every platform. Around it, the native engine adds what HTML
// never could: eligibility, cooldowns, a difficulty ramp, guardian
// awareness, and alternatives - each carrying its WHY. Same inputs,
// same outputs, always: curiosity, never a slot machine.

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'content.dart';
import 'guardian.dart';
import 'rules.dart' as rules;
import 'save.dart';
import '../core/clock.dart';

/// Local, device-side engine state (loaded from prefs by the caller;
/// kept as a plain object so every rule below is pure and testable).
class EngineLocal {
  final Map<String, String> lastDone; // slug -> last completed day
  final Map<String, String> dismissed; // slug -> day dismissed
  final String override; // today's chosen alternate, '' if none
  final String mode; // any | home | outdoor | online | financial
  final int minutes; // 0 = any
  const EngineLocal(
      {this.lastDone = const {},
      this.dismissed = const {},
      this.override = '',
      this.mode = 'any',
      this.minutes = 0});
}

class Pick {
  final ActionItem a;
  final String reason;
  Pick(this.a, this.reason);
}

// ---------- eligibility (the gate every shown action passes) ----------
const _doneCooldownDays = 7;
const _dismissCooldownDays = 3;

/// Experience ramp: new hands get easy days; seasoned hands get depth.
int maxDifficulty(Save s) {
  final done = s.log.values.fold<int>(0, (a, b) => a + b);
  if (done < 5) return 1;
  if (done < 15) return 2;
  return 3;
}

bool eligible(ActionItem a, Save s, EngineLocal st, String today,
    {bool ignorePrefs = false}) {
  if (a.status != 'approved') return false; // editorial gate
  if (a.diff > maxDifficulty(s)) return false;
  final done = st.lastDone[a.slug];
  if (done != null && daysBetween(done, today) < _doneCooldownDays) {
    return false;
  }
  final dis = st.dismissed[a.slug];
  if (dis != null && daysBetween(dis, today) < _dismissCooldownDays) {
    return false;
  }
  if (!ignorePrefs) {
    if (st.mode != 'any' && a.mod != st.mode) return false;
    if (st.minutes > 0 && a.min > st.minutes) return false;
  }
  return true;
}

// ---------- the primary pick: PWA parity, verbatim semantics ----------
/// Pool = the actions of the user's chosen causes (in content order,
/// first-seen dedupe), else every action. Index = dailyIndex(len, 'a').
List<String> causesPool(AppContent c, Save s) {
  final causes = (s.extra['causes'] as List?)
          ?.map((e) => e.toString())
          .toSet() ??
      {};
  if (causes.isEmpty) return c.actions.keys.toList();
  final pool = <String>[];
  for (final w in c.worlds) {
    if (!causes.contains(w.slug)) continue;
    for (final slug in w.acts) {
      if (c.actions.containsKey(slug) && !pool.contains(slug)) {
        pool.add(slug);
      }
    }
  }
  return pool.isEmpty ? c.actions.keys.toList() : pool;
}

Pick? primary(AppContent c, Save s, EngineLocal st, String today) {
  if (c.actions.isEmpty) return null;
  // A chosen alternate holds for the rest of the day.
  if (st.override.isNotEmpty && c.actions.containsKey(st.override)) {
    return Pick(c.actions[st.override]!, WhyCopy.chosen);
  }
  final pool = causesPool(c, s);
  final idx = _dailyIndexFor(pool.length, today);
  final a = c.actions[pool[idx]]!;
  final personalized = pool.length != c.actions.length;
  return Pick(a, personalized ? WhyCopy.fromCauses : WhyCopy.sharedClock);
}

int _dailyIndexFor(int len, String today) {
  final d = '${today}a';
  var h = 0;
  for (var i = 0; i < d.length; i++) {
    h = ((h * 31) + d.codeUnitAt(i)) & 0xFFFFFFFF;
  }
  return h % len;
}

// ---------- alternatives: reasoned, deterministic, never a feed ----------
List<Pick> alternates(AppContent c, Save s, EngineLocal st, String today,
    {int count = 3}) {
  final primarySlug = primary(c, s, st, today)?.a.slug;
  final gid = Guardianship.activeId(s);
  final gWorlds = gid == null
      ? const <String>{}
      : (c.guardianById(gid)?.cats.toSet() ?? const <String>{});
  final scored = <(ActionItem, int, String)>[];
  for (final a in c.actions.values) {
    if (a.slug == primarySlug) continue;
    if (!eligible(a, s, st, today)) continue;
    var score = 0;
    var reason = WhyCopy.fresh;
    final worlds = c.worldsOfAction(a.slug).toSet();
    if (gWorlds.isNotEmpty && worlds.intersection(gWorlds).isNotEmpty) {
      score += 3;
      reason = WhyCopy.forGuardian;
    }
    if (st.mode != 'any' && a.mod == st.mode) {
      score += 2;
      if (reason == WhyCopy.fresh) reason = WhyCopy.fitsMode(a.mod);
    }
    if (st.minutes > 0 && a.min <= st.minutes) score += 1;
    if (a.diff == maxDifficulty(s)) {
      score += 1; // grown into it
      if (reason == WhyCopy.fresh) reason = WhyCopy.grown;
    }
    // Deterministic daily rotation as the tiebreaker: same day, same
    // order; a new day, a fresh but stable shuffle.
    final rot = _hash('$today${a.slug}') % 100;
    scored.add((a, score * 1000 + rot, reason));
  }
  scored.sort((x, y) => y.$2.compareTo(x.$2));
  return [for (final e in scored.take(count)) Pick(e.$1, e.$3)];
}

int _hash(String s) {
  var h = 0;
  for (var i = 0; i < s.length; i++) {
    h = ((h * 31) + s.codeUnitAt(i)) & 0xFFFFFFFF;
  }
  return h;
}

/// A journey the completed action opens a door to, if one fits.
Journey? relatedJourney(AppContent c, String actionSlug) {
  final worlds = c.worldsOfAction(actionSlug);
  for (final w in worlds) {
    final stem = w.split('-').first; // oceans -> ocean...
    for (final j in c.journeys) {
      if (j.slug.contains(stem) ||
          (stem.length > 3 && j.slug.contains(stem.substring(0, 4)))) {
        return j;
      }
    }
  }
  return null;
}

// ---------- the engine's voice: every pick carries its why ----------
class WhyCopy {
  static const sharedClock =
      'Chosen by the shared daily clock - the same today, everywhere.';
  static const fromCauses = 'From the causes you chose.';
  static const chosen = 'You chose this one for today.';
  static const forGuardian = 'For the world you watch over.';
  static const fresh = 'Something you have not done in a while.';
  static const grown = 'You have grown into this one.';
  static String fitsMode(String mod) => switch (mod) {
        'home' => 'Doable without leaving home.',
        'outdoor' => 'A reason to step outside.',
        'online' => 'Doable from where you sit.',
        'financial' => 'A small act of giving.',
        _ => 'Fits the way you like to help.',
      };
}

/// Impact language guard: ranges and honesty, never savior claims.
/// (Impact figures render as "about" + metric; no certainty theater.)
String impactLine(ActionItem a) {
  if (a.val <= 0 || a.metric.isEmpty) return '';
  return 'roughly ${a.val} ${a.metric} - an estimate, not a promise';
}

/// Completion bookkeeping shared by grove, letters, and future widgets.
rules.CompleteOutcome recordCompletion(Save s, ActionItem a, String today) {
  final out = rules.complete(s, today);
  final done = (s.extra['done'] as Map?)?.map(
          (k, v) => MapEntry(k.toString(), v)) ??
      <String, dynamic>{};
  done[a.slug] = true; // PWA parity: done marks the slug forever
  s.extra['done'] = done;
  return out;
}

// ---------- today, assembled (fact + engine pick) ----------
class DayContent {
  final String factText;
  final String factSrc;
  final ActionItem act;
  final String reason;
  final bool fromCache;
  DayContent(
      this.factText, this.factSrc, this.act, this.reason, this.fromCache);
}

ActionItem fallbackAction() => ActionItem(
    'refuse-plastic',
    'Refuse one single-use plastic today',
    'Most ocean plastic starts as one convenient moment on land.',
    '', '', 'home', '', '', 'approved', 2, 1, 0, const [], const []);

// ---------- device-local engine state, persisted ----------
Future<EngineLocal> loadEngineLocal([String? today]) async {
  final p = await SharedPreferences.getInstance();
  Map<String, String> readMap(String key) {
    try {
      final raw = p.getString(key);
      if (raw == null) return {};
      return (jsonDecode(raw) as Map)
          .map((k, v) => MapEntry(k.toString(), v.toString()));
    } catch (_) {
      return {};
    }
  }

  return EngineLocal(
    lastDone: readMap('actLast'),
    dismissed: readMap('actDismissed'),
    override: p.getString('actOverride_${today ?? todayStr()}') ?? '',
    mode: p.getString('actMode') ?? 'any',
    minutes: p.getInt('actMin') ?? 0,
  );
}

Future<void> saveOverride(String slug) async {
  final p = await SharedPreferences.getInstance();
  await p.setString('actOverride_${todayStr()}', slug);
}

Future<void> saveDismiss(String slug) async {
  final p = await SharedPreferences.getInstance();
  final st = await loadEngineLocal();
  final m = Map<String, String>.from(st.dismissed)..[slug] = todayStr();
  await p.setString('actDismissed', jsonEncode(m));
}

Future<void> recordDoneLocally(String slug) async {
  final p = await SharedPreferences.getInstance();
  final st = await loadEngineLocal();
  final m = Map<String, String>.from(st.lastDone)..[slug] = todayStr();
  await p.setString('actLast', jsonEncode(m));
}

Future<void> savePrefsMode(String mode, int minutes) async {
  final p = await SharedPreferences.getInstance();
  await p.setString('actMode', mode);
  await p.setInt('actMin', minutes);
}

Future<DayContent> loadToday() async {
  final c = await loadContent();
  final s = await Store.load();
  final st = await loadEngineLocal();
  final today = todayStr();
  String factText = 'Sharks were swimming in the sea before trees existed.';
  String factSrc = 'National Geographic';
  if (c.facts.isNotEmpty) {
    final f = c.facts[dailyIndex(c.facts.length, 'f')];
    factText = f[0];
    if (f.length > 1) factSrc = f[1];
  }
  final pick = primary(c, s, st, today);
  return DayContent(factText, factSrc, pick?.a ?? fallbackAction(),
      pick?.reason ?? WhyCopy.sharedClock, c.fromCache);
}
