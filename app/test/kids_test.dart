// Kids Mode vs the constitution: policy in one place, safety by
// construction, profiles riding the parent's save document, and not one
// line of parasocial guilt anywhere near a child.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:hopeling/core/deeplink.dart';
import 'package:hopeling/data/content.dart';
import 'package:hopeling/data/kids.dart';
import 'package:hopeling/data/save.dart';

ActionItem _act(String mod, {int diff = 1, int min = 5, String status = 'approved'}) =>
    ActionItem.fromJson('x',
        {'t': 't', 'why': 'w', 'mod': mod, 'diff': diff, 'min': min, 'status': status});

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('the policy engine keeps money, difficulty and time away from kids',
      () {
    expect(KidPolicy.actionEligible(_act('home')), true);
    expect(KidPolicy.actionEligible(_act('financial')), false);
    expect(KidPolicy.actionEligible(_act('home', diff: 2)), false);
    expect(KidPolicy.actionEligible(_act('home', min: 30)), false);
    expect(KidPolicy.actionEligible(_act('home', status: 'draft')), false);
  });

  test('supervision is declared, never small print', () {
    expect(KidPolicy.supervision(_act('outdoor')), KidCopy.withGrownUp);
    expect(KidPolicy.supervision(_act('online')), KidCopy.grownUpNearby);
    expect(KidPolicy.supervision(_act('home')), KidCopy.byYourself);
    expect(KidPolicy.supervision(_act('financial')), null); // not suitable
  });

  test('structural safety: no child notifications, no external links', () {
    expect(KidPolicy.childNotificationsAllowed(), false);
    expect(KidPolicy.externalLinksAllowed(), false);
  });

  test('sessions are short by design, per band', () {
    expect(KidPolicy.sessionMinutes('early'), 5);
    expect(KidPolicy.sessionMinutes('ranger'), 8);
    expect(KidPolicy.sessionMinutes('young'), 12);
  });

  test('gentle intensity hides threat framing', () {
    expect(KidPolicy.showThreats('gentle'), false);
    expect(KidPolicy.showThreats('balanced'), true);
    expect(KidPolicy.showThreats('full'), true);
  });

  test('the parent gate is arithmetic for adults, validated exactly', () {
    final g = ParentGate(17, 14);
    expect(g.check('238'), true);
    expect(g.check(' 238 '), true);
    expect(g.check('237'), false);
    expect(g.check('a lot'), false);
    // rolled gates stay in the two-digit adult range
    final r = ParentGate.roll();
    expect(r.a >= 12 && r.a <= 19, true);
    expect(r.b >= 13 && r.b <= 19, true);
  });

  test('profiles ride the parent save document, siblings stay separate', () {
    final s = Save();
    final noya = KidProfile(id: 'k1', name: 'Noya', band: 'early');
    final ori = KidProfile(id: 'k2', name: 'Ori', band: 'young');
    Kids.put(s, noya);
    Kids.put(s, ori);
    noya.speciesMet.add('Vaquita');
    Kids.put(s, noya);
    // round-trip through the contract (cloud restore path)
    final back = Save.fromJson(s.toJson());
    final kids = Kids.list(back);
    expect(kids.length, 2);
    expect(kids.firstWhere((k) => k.id == 'k1').speciesMet, ['Vaquita']);
    expect(kids.firstWhere((k) => k.id == 'k2').speciesMet, isEmpty);
    Kids.remove(back, 'k1');
    expect(Kids.list(back).length, 1);
  });

  test('data minimization: the profile has no fields to leak', () {
    final j = KidProfile(id: 'k1', name: 'Noya').toJson();
    for (final forbidden in [
      'email', 'phone', 'birthday', 'school', 'location', 'photo'
    ]) {
      expect(j.containsKey(forbidden), false);
    }
  });

  test('simple variants are preferred everywhere', () {
    final l = Lesson('T', 3, 'complex body', 'simple body', const []);
    expect(KidPolicy.lessonText(l), 'simple body');
    final l2 = Lesson('T', 3, 'complex body', '', const []);
    expect(KidPolicy.lessonText(l2), 'complex body'); // honest fallback
  });

  test('the child copy never guilts, pressures, or pretends dependency', () {
    final p = KidProfile(id: 'k', name: 'Noya', actions: 2)
      ..lessonsRead.add('x')
      ..speciesMet.add('Vaquita');
    final lines = [
      KidCopy.welcome,
      KidCopy.gentleWrong,
      KidCopy.done,
      KidCopy.sessionEnd,
      KidCopy.guardianAsk,
      KidCopy.guardianYes,
      KidCopy.summary(p),
    ];
    for (final l in lines) {
      for (final bad in [
        'waiting for you', 'i missed you', 'lonely', 'come back',
        'don\'t leave', 'streak', 'wrong again', 'you own', 'yours now',
        'buy', 'donate'
      ]) {
        expect(l.toLowerCase().contains(bad), false,
            reason: '"$l" contains "$bad"');
      }
    }
  });

  test('kids deep link routes to the parent area, never a child surface',
      () {
    expect(parseDeepLink('hopeling://kids')!.type, 'kids');
  });
}
