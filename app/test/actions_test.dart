// The Daily Action Engine vs its constitution: contract-true primary,
// honest eligibility, cooldowns that breathe, deterministic alternatives,
// and a reason on everything.

import 'package:flutter_test/flutter_test.dart';

import 'package:hopeling/core/clock.dart';
import 'package:hopeling/data/actions.dart' as engine;
import 'package:hopeling/data/content.dart';
import 'package:hopeling/data/save.dart';

AppContent _fix() => AppContent.fromJson({
      'version': 1,
      'categories': [
        {
          'slug': 'oceans',
          'emo': '🌊',
          'name': 'Oceans',
          'iucn': 'EN',
          'sum': 's',
          'acts': ['refuse-plastic', 'beach-clean'],
          'species': []
        },
        {
          'slug': 'bees',
          'emo': '🐝',
          'name': 'Bees',
          'iucn': 'NA',
          'sum': 's',
          'acts': ['plant-natives'],
          'species': []
        },
      ],
      'actions': {
        'refuse-plastic': {'t': 'Refuse plastic', 'why': 'w', 'min': 2, 'diff': 1, 'mod': 'home'},
        'beach-clean': {'t': 'Clean a beach', 'why': 'w', 'min': 30, 'diff': 3, 'mod': 'outdoor'},
        'plant-natives': {'t': 'Plant natives', 'why': 'w', 'min': 15, 'diff': 2, 'mod': 'outdoor'},
        'draft-thing': {'t': 'Unreviewed', 'why': 'w', 'min': 2, 'diff': 1, 'mod': 'home', 'status': 'draft'},
      },
      'facts': [],
      'courses': [
        {'slug': 'ocean-pollution', 't': 'Ocean Pollution 101', 'd': 'd', 'badge': '🌊', 'lessons': []}
      ],
      'guardians': [
        {'id': 'vaquita', 'emo': '🐋', 'name': 'Vaquita', 'cats': ['oceans']}
      ],
    }, false);

const st0 = engine.EngineLocal();

void main() {
  test('primary matches the PWA clock exactly (no causes)', () {
    final c = _fix();
    final s = Save();
    final pick = engine.primary(c, s, st0, '2026-07-17')!;
    // reproduce the oracle by hand
    var h = 0;
    for (final ch in '2026-07-17a'.codeUnits) {
      h = ((h * 31) + ch) & 0xFFFFFFFF;
    }
    final keys = c.actions.keys.toList();
    expect(pick.a.slug, keys[h % keys.length]);
    expect(pick.reason, engine.WhyCopy.sharedClock);
  });

  test('causes narrow the pool, in content order, with its reason', () {
    final c = _fix();
    final s = Save(extra: {'causes': ['bees']});
    final pick = engine.primary(c, s, st0, '2026-07-17')!;
    expect(pick.a.slug, 'plant-natives'); // pool of one
    expect(pick.reason, engine.WhyCopy.fromCauses);
  });

  test('a chosen alternate holds for the day', () {
    final c = _fix();
    const st = engine.EngineLocal(override: 'beach-clean');
    final pick = engine.primary(c, Save(log: {for (var i = 0; i < 20; i++) addDays('2026-06-01', i): 1}), st, '2026-07-17')!;
    expect(pick.a.slug, 'beach-clean');
    expect(pick.reason, engine.WhyCopy.chosen);
  });

  test('eligibility: editorial gate, difficulty ramp, cooldowns, prefs', () {
    final c = _fix();
    final newbie = Save(); // 0 completions: only diff 1
    expect(engine.eligible(c.actions['draft-thing']!, newbie, st0, '2026-07-17'),
        false); // draft never shows
    expect(engine.eligible(c.actions['beach-clean']!, newbie, st0, '2026-07-17'),
        false); // diff 3 too soon
    final veteran = Save(log: {
      for (var i = 0; i < 20; i++) addDays('2026-06-01', i): 1
    });
    expect(engine.eligible(c.actions['beach-clean']!, veteran, st0, '2026-07-17'),
        true);
    // done 3 days ago: resting
    const done = engine.EngineLocal(lastDone: {'refuse-plastic': '2026-07-15'});
    expect(engine.eligible(c.actions['refuse-plastic']!, veteran, done, '2026-07-17'),
        false);
    expect(engine.eligible(c.actions['refuse-plastic']!, veteran, done, '2026-07-25'),
        true); // cooldown breathed out
    // dismissed yesterday: respected briefly
    const dis = engine.EngineLocal(dismissed: {'refuse-plastic': '2026-07-16'});
    expect(engine.eligible(c.actions['refuse-plastic']!, veteran, dis, '2026-07-17'),
        false);
    expect(engine.eligible(c.actions['refuse-plastic']!, veteran, dis, '2026-07-20'),
        true);
    // mode and minutes preferences
    const homeOnly = engine.EngineLocal(mode: 'home');
    expect(engine.eligible(c.actions['plant-natives']!, veteran, homeOnly, '2026-07-17'),
        false);
    const tenMin = engine.EngineLocal(minutes: 10);
    expect(engine.eligible(c.actions['beach-clean']!, veteran, tenMin, '2026-07-17'),
        false);
  });

  test('alternates are deterministic, reasoned, guardian-aware', () {
    final c = _fix();
    final s = Save(log: {
      for (var i = 0; i < 20; i++) addDays('2026-06-01', i): 1
    }, extra: {
      'guardian': {'id': 'vaquita', 'date': '2026-07-01'}
    });
    final a1 = engine.alternates(c, s, st0, '2026-07-17');
    final a2 = engine.alternates(c, s, st0, '2026-07-17');
    expect([for (final p in a1) p.a.slug], [for (final p in a2) p.a.slug]);
    expect(a1.every((p) => p.reason.isNotEmpty), true);
    // an ocean action carries the guardian's reason
    final ocean = a1.where((p) =>
        c.worldsOfAction(p.a.slug).contains('oceans'));
    expect(ocean.any((p) => p.reason == engine.WhyCopy.forGuardian), true);
  });

  test('completion marks done (PWA parity) and returns the outcome', () {
    final c = _fix();
    final s = Save();
    final out = engine.recordCompletion(
        s, c.actions['refuse-plastic']!, '2026-07-17');
    expect(out.firstOfDay, true);
    expect((s.extra['done'] as Map)['refuse-plastic'], true);
    expect(s.streak, 1);
  });

  test('related journeys open doors from ocean actions', () {
    final c = _fix();
    expect(engine.relatedJourney(c, 'refuse-plastic')?.slug,
        'ocean-pollution');
    expect(engine.relatedJourney(c, 'plant-natives'), null);
  });

  test('impact language is a range, never a rescue', () {
    final a = ActionItem.fromJson('x',
        {'t': 't', 'why': 'w', 'min': 2, 'val': 3, 'metric': 'kg plastic'});
    final line = engine.impactLine(a);
    expect(line.contains('estimate'), true);
    expect(line.toLowerCase().contains('saved'), false);
  });
}
