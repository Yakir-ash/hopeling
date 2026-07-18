// Kids Mode - safe wonder. One centralized policy engine answers every
// child-safety question; no age checks scattered across widgets. Child
// profiles live inside the parent's one save document (Contract-1 extra),
// so parent ownership, cloud restore, and device migration are inherited
// from infrastructure already proven. Data minimization by construction:
// a nickname, a band, three toggles - nothing else exists to leak.

import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

import 'content.dart';
import 'save.dart';

// ---------- the profile (minimum necessary information) ----------
class KidProfile {
  final String id; // local id, never an account
  String name; // nickname only
  String band; // early | ranger | young
  bool narration;
  String intensity; // gentle | balanced | full
  String? guardianId; // the child's own guardian, separate from parents'
  List<String> lessonsRead;
  List<String> speciesMet;
  int actions;

  KidProfile({
    required this.id,
    required this.name,
    this.band = 'ranger',
    this.narration = true,
    this.intensity = 'gentle',
    this.guardianId,
    List<String>? lessonsRead,
    List<String>? speciesMet,
    this.actions = 0,
  })  : lessonsRead = lessonsRead ?? [],
        speciesMet = speciesMet ?? [];

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'band': band,
        'narration': narration,
        'intensity': intensity,
        'guardianId': guardianId,
        'lessonsRead': lessonsRead,
        'speciesMet': speciesMet,
        'actions': actions,
      };

  factory KidProfile.fromJson(Map<String, dynamic> j) => KidProfile(
        id: (j['id'] ?? '').toString(),
        name: (j['name'] ?? '').toString(),
        band: (j['band'] ?? 'ranger').toString(),
        narration: j['narration'] != false,
        intensity: (j['intensity'] ?? 'gentle').toString(),
        guardianId: j['guardianId']?.toString(),
        lessonsRead: ((j['lessonsRead'] as List?) ?? [])
            .map((e) => e.toString())
            .toList(),
        speciesMet: ((j['speciesMet'] as List?) ?? [])
            .map((e) => e.toString())
            .toList(),
        actions: (j['actions'] is int) ? j['actions'] as int : 0,
      );
}

class Kids {
  static List<KidProfile> list(Save s) {
    final raw = s.extra['kids'];
    if (raw is! List) return [];
    return raw
        .whereType<Map>()
        .map((e) => KidProfile.fromJson(
            e.map((k, v) => MapEntry(k.toString(), v))))
        .toList();
  }

  static void put(Save s, KidProfile p) {
    final all = list(s)..removeWhere((x) => x.id == p.id);
    all.add(p);
    s.extra['kids'] = all.map((e) => e.toJson()).toList();
  }

  static void remove(Save s, String id) {
    final all = list(s)..removeWhere((x) => x.id == id);
    s.extra['kids'] = all.map((e) => e.toJson()).toList();
  }

  static String newId() =>
      'k${DateTime.now().millisecondsSinceEpoch}${Random().nextInt(999)}';
}

// ---------- the policy engine: every decision, one place, testable ----------
class KidPolicy {
  /// Session lengths per band, in minutes. A good session ends early.
  static int sessionMinutes(String band) => switch (band) {
        'early' => 5,
        'young' => 12,
        _ => 8,
      };

  /// Child action eligibility: small, safe, cheap, home-leaning.
  static bool actionEligible(ActionItem a) {
    if (a.status != 'approved') return false;
    if (a.mod == 'financial') return false; // never money near children
    if (a.diff > 1) return false;
    if (a.min > 15) return false;
    return true;
  }

  /// Supervision states, declared before starting - never small print.
  /// null = not suitable for Kids Mode at all.
  static String? supervision(ActionItem a) {
    if (!actionEligible(a)) return null;
    if (a.mod == 'outdoor') return KidCopy.withGrownUp;
    if (a.mod == 'online') return KidCopy.grownUpNearby;
    return KidCopy.byYourself;
  }

  /// Content-intensity gate: gentle mode hides threat framing entirely;
  /// balanced summarizes; full shows the age-appropriate truth.
  static bool showThreats(String intensity) => intensity != 'gentle';

  /// External links are always behind the parent gate in Kids Mode.
  static bool externalLinksAllowed() => false;

  /// Kids never receive re-engagement notifications. Structural.
  static bool childNotificationsAllowed() => false;

  /// The child's lesson text: simple variant first, always.
  static String lessonText(Lesson l) =>
      l.bodySimple.isNotEmpty ? l.bodySimple : l.body;

  static String actionWhy(ActionItem a) =>
      a.whySimple.isNotEmpty ? a.whySimple : a.why;

  static String guardianStory(GuardianDef g) =>
      g.storySimple.isNotEmpty ? g.storySimple : g.story;
}

// ---------- the parent gate: designed for adults, not for reading ----------
class ParentGate {
  final int a;
  final int b;
  ParentGate(this.a, this.b);

  factory ParentGate.roll([Random? r]) {
    final rnd = r ?? Random();
    return ParentGate(12 + rnd.nextInt(8), 13 + rnd.nextInt(7));
  }

  String get question => 'To continue, a grown-up solves: $a × $b = ?';
  bool check(String answer) => int.tryParse(answer.trim()) == a * b;
}

// ---------- the child's voice: wonder, never dependency ----------
class KidCopy {
  static const welcome = "Let's see what is happening in the wild today.";
  static const byYourself = '🌟 You can do this yourself';
  static const withGrownUp = '🤝 Do this with a grown-up';
  static const grownUpNearby = '👀 A grown-up nearby helps';
  static const gentleWrong = "Let's look more closely.";
  static const gentleWrongHint = 'Good guess - here is a clue:';
  static const done = 'You helped today. The grove felt it.';
  static const sessionEnd =
      'That was a lovely adventure. Your next discovery will wait here.';
  static const guardianAsk =
      'Would you like to keep learning about this animal?';
  static const guardianYes = 'We will learn about them together.';
  static String summary(KidProfile p) {
    final parts = <String>[];
    if (p.lessonsRead.isNotEmpty) {
      parts.add(
          'read ${p.lessonsRead.length} ${p.lessonsRead.length == 1 ? 'story' : 'stories'}');
    }
    if (p.speciesMet.isNotEmpty) {
      parts.add('met ${p.speciesMet.length} species');
    }
    if (p.actions > 0) {
      parts.add(
          'helped ${p.actions} ${p.actions == 1 ? 'time' : 'times'}');
    }
    if (parts.isEmpty) return '${p.name} is just beginning to explore.';
    return '${p.name} ${parts.join(', ')}. A gentle week of wonder.';
  }
}

// ---------- device-local session state ----------
Future<void> startKidSession(String profileId) async {
  final p = await SharedPreferences.getInstance();
  await p.setString('kidActive', profileId);
  await p.setInt(
      'kidSessionStart', DateTime.now().millisecondsSinceEpoch);
}

Future<void> endKidSession() async {
  final p = await SharedPreferences.getInstance();
  await p.remove('kidActive');
  await p.remove('kidSessionStart');
}

Future<bool> kidSessionOver(String band) async {
  final p = await SharedPreferences.getInstance();
  final start = p.getInt('kidSessionStart');
  if (start == null) return false;
  final mins =
      (DateTime.now().millisecondsSinceEpoch - start) / 60000;
  return mins >= KidPolicy.sessionMinutes(band);
}

Future<void> extendKidSession() async {
  final p = await SharedPreferences.getInstance();
  await p.setInt(
      'kidSessionStart', DateTime.now().millisecondsSinceEpoch);
}
