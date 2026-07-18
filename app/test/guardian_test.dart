// Guardianship vs the constitution: idempotent beginnings, shame-free
// archives, history that survives everything, letters with sources,
// and not one word of ownership anywhere.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:hopeling/core/deeplink.dart';
import 'package:hopeling/data/content.dart';
import 'package:hopeling/data/guardian.dart';
import 'package:hopeling/data/save.dart';

GuardianDef _vaquita() => GuardianDef.fromJson({
      'id': 'vaquita',
      'emo': '🐋',
      'name': 'Vaquita',
      'sci': 'Phocoena sinus',
      'count': 'Around 10 remain in the upper Gulf of California.',
      'story': 'The smallest porpoise on Earth lives in one small sea.',
      'story_simple': 'A tiny porpoise that needs safe nets.',
      'wiki': 'Vaquita',
      'cats': ['oceans'],
    });

World _oceans() => World.fromJson({
      'slug': 'oceans',
      'emo': '🌊',
      'name': 'Oceans',
      'iucn': 'EN',
      'sum': 'The blue heart.',
      'threats': [
        ['Gillnets', 'Entanglement is the main threat.', 'IUCN']
      ],
      'facts': [
        ['The ocean makes oxygen.', 'NOAA']
      ],
      'acts': ['refuse-plastic'],
      'species': ['Vaquita'],
    });

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('beginning is idempotent: the same choice changes nothing', () {
    final s = Save();
    expect(Guardianship.begin(s, 'vaquita', '2026-07-01'), true);
    expect(Guardianship.begin(s, 'vaquita', '2026-07-05'), false);
    expect(Guardianship.since(s), '2026-07-01'); // the first day holds
  });

  test('choosing another archives the current, history intact', () {
    final s = Save();
    Guardianship.begin(s, 'vaquita', '2026-07-01');
    Guardianship.begin(s, 'kakapo', '2026-07-10');
    expect(Guardianship.activeId(s), 'kakapo');
    final p = Guardianship.past(s);
    expect(p.length, 1);
    expect(p.first['id'], 'vaquita');
    expect(p.first['end'], '2026-07-10');
  });

  test('restoring continues the original relationship, not a new one', () {
    final s = Save();
    Guardianship.begin(s, 'vaquita', '2026-07-01');
    Guardianship.archive(s, '2026-07-08');
    expect(Guardianship.activeId(s), null);
    expect(Guardianship.restore(s, 'vaquita', '2026-07-20'), true);
    expect(Guardianship.activeId(s), 'vaquita');
    expect(Guardianship.since(s), '2026-07-01'); // time together resumes
    expect(Guardianship.restore(s, 'never-met', '2026-07-20'), false);
  });

  test('guardianship rides the one-document engine to the cloud and back',
      () {
    final s = Save();
    Guardianship.begin(s, 'vaquita', '2026-07-01');
    Guardianship.begin(s, 'kakapo', '2026-07-10');
    final back = Save.fromJson(s.toJson());
    expect(Guardianship.activeId(back), 'kakapo');
    expect(Guardianship.past(back).first['id'], 'vaquita');
  });

  test('the welcome letter is sourced, framed as a dispatch, and actionable',
      () {
    final l = welcomeLetter(_vaquita(), _oceans());
    expect(l.category, 'welcome');
    expect(l.title, 'A letter from the world of the vaquita');
    expect(l.sources, isNotEmpty);
    expect(l.sources.any((s) => s.contains('Wikipedia')), true);
    expect(l.sources.any((s) => s.contains('IUCN')), true);
    expect(l.actionSlug, 'refuse-plastic');
    // never a talking animal
    expect(l.body.toLowerCase().contains("i'm"), false);
    expect(l.opening.toLowerCase().startsWith('hi '), false);
  });

  test('the copy never claims ownership and never shames leaving', () {
    final lines = [
      GCopy.explanation,
      GCopy.holdLabel,
      GCopy.began('vaquita'),
      GCopy.archiveTitle,
      GCopy.archiveBody,
      GCopy.archived,
      GCopy.anniversary('vaquita', '2026-07-01'),
      ...GCopy.timelineKinds.values,
    ];
    for (final l in lines) {
      for (final bad in [
        'you own', 'now yours', 'acquired', 'your pet', 'abandon',
        'responsible for saving', 'collect them', 'unlock'
      ]) {
        expect(l.toLowerCase().contains(bad), false,
            reason: '"$l" contains "$bad"');
      }
      // Mentioning ownership only to refuse it is allowed; claiming it is not.
      if (l.toLowerCase().contains('owning')) {
        expect(l.toLowerCase().contains('does not mean owning'), true,
            reason: '"$l" speaks of owning without refusing it');
      }
    }
  });

  test('the timeline records presence only, deduped per day', () async {
    await addTimeline('vaquita', 'letter');
    await addTimeline('vaquita', 'letter'); // same day: once
    await addTimeline('vaquita', 'reflection');
    final tl = await timelineFor('vaquita');
    expect(tl.length, 2);
    expect(GCopy.timelineKinds.keys.toSet().containsAll(
        tl.map((e) => e['k'])), true);
    // no vocabulary for absence exists
    expect(GCopy.timelineKinds.containsKey('missed'), false);
    expect(GCopy.timelineKinds.containsKey('inactive'), false);
  });

  test('reflections are private, editable, and persist', () async {
    await saveGuardianReflection('vaquita', 'Because ten is not zero.');
    expect(await guardianReflection('vaquita'), 'Because ten is not zero.');
    await saveGuardianReflection('vaquita', 'Edited.');
    expect(await guardianReflection('vaquita'), 'Edited.');
  });

  test('guardian deep links parse', () {
    final l = parseDeepLink('hopeling://guardian/vaquita');
    expect(l!.type, 'guardian');
    expect(l.id, 'vaquita');
    expect(parseDeepLink('hopeling://guardian'), null); // no id, no guess
  });
}
