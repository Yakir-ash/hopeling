// The Living Atlas: search finds with forgiveness, slugs agree with the
// website, deep links parse every shape, atmospheres always answer.

import 'package:flutter_test/flutter_test.dart';

import 'package:hopeling/core/atmosphere.dart';
import 'package:hopeling/core/deeplink.dart';
import 'package:hopeling/core/slugify.dart';
import 'package:hopeling/data/content.dart';
import 'package:hopeling/data/search.dart' as srch;

AppContent _fixture() => AppContent.fromJson({
      'version': 1,
      'categories': [
        {
          'slug': 'oceans',
          'emo': '🌊',
          'name': 'Oceans',
          'iucn': 'EN',
          'sum': 'The blue heart of the planet.',
          'facts': [
            ['The ocean produces much of the oxygen we breathe.', 'NOAA']
          ],
          'species': ['Vaquita', 'Giant Pacific octopus'],
          'acts': ['refuse-plastic']
        },
        {
          'slug': 'forests',
          'emo': '🌳',
          'name': 'Forests',
          'iucn': 'VU',
          'sum': 'Green lungs.',
          'species': ['Red squirrel'],
          'acts': []
        }
      ],
      'actions': {
        'refuse-plastic': {
          't': 'Refuse one single-use plastic',
          'why': 'Less plastic, more ocean.',
          'min': 2
        }
      },
      'facts': [],
    }, false);

void main() {
  test('search finds species, worlds, actions - ranked', () {
    final c = _fixture();
    final hits = srch.search(c, 'vaquita');
    expect(hits.first.kind, 'species');
    expect(hits.first.title, 'Vaquita');
    expect(srch.search(c, 'ocean').any((h) => h.kind == 'world'), true);
    expect(srch.search(c, 'plastic').any((h) => h.kind == 'action'), true);
  });

  test('search forgives a typo', () {
    final c = _fixture();
    expect(srch.search(c, 'vaquta').any((h) => h.title == 'Vaquita'), true);
  });

  test('search ignores one-letter queries', () {
    expect(srch.search(_fixture(), 'v'), isEmpty);
  });

  test('slugify agrees with the website generator', () {
    expect(slugify('Vaquita'), 'vaquita');
    expect(slugify("Kemp's ridley sea turtle"), 'kemps-ridley-sea-turtle');
    expect(slugify('Giant Pacific octopus'), 'giant-pacific-octopus');
    expect(slugify("Portuguese man o' war"), 'portuguese-man-o-war');
  });

  test('deep links parse every shape', () {
    expect(parseDeepLink('hopeling://species/vaquita')!.type, 'species');
    expect(parseDeepLink('hopeling://species/vaquita')!.id, 'vaquita');
    expect(parseDeepLink('hopeling://world/oceans')!.id, 'oceans');
    expect(parseDeepLink('/species/vaquita')!.id, 'vaquita');
    expect(parseDeepLink('/atlas/oceans')!.type, 'world');
    expect(parseDeepLink('/'), null);
    expect(parseDeepLink(null), null);
    expect(parseDeepLink('hopeling://nonsense'), null);
  });

  test('every world slug gets an atmosphere, unknowns get the forest', () {
    expect(atmosphereOf('oceans').deep, isNot(atmosphereOf('bees').deep));
    expect(atmosphereOf('never-heard-of-it').deep,
        atmosphereOf('forests').deep);
  });
}
