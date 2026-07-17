// Learn: journeys parse from the contract, completion keys match the PWA
// byte for byte, search reaches into chapters, reflections persist.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:hopeling/data/content.dart';
import 'package:hopeling/data/notes.dart';
import 'package:hopeling/data/search.dart' as srch;

AppContent _fixture() => AppContent.fromJson({
      'version': 1,
      'categories': [],
      'actions': {},
      'facts': [],
      'courses': [
        {
          'slug': 'ocean-pollution',
          't': 'Ocean Pollution 101',
          'd': 'How plastic affects marine life.',
          'badge': '🌊',
          'lessons': [
            {
              't': 'Where ocean plastic comes from',
              'min': 6,
              'body':
                  'Most ocean plastic begins on land.\nRivers carry it to the sea.',
              'body_simple': 'Plastic travels from land to sea.',
              'quiz': [
                {
                  'q': 'Most ocean plastic originates...',
                  'opts': ['On land', 'From ships only', 'From reefs'],
                  'a': 0
                }
              ]
            },
            {'t': 'What actually works', 'min': 4, 'body': 'Bans work.'}
          ]
        }
      ],
    }, false);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('journeys parse from the contract', () {
    final c = _fixture();
    expect(c.journeys.length, 1);
    final j = c.journeys.first;
    expect(j.t, 'Ocean Pollution 101');
    expect(j.lessons.length, 2);
    expect(j.lessons.first.quiz.first.opts.length, 3);
    expect(j.lessons.first.quiz.first.a, 0);
    expect(j.lessons.first.bodySimple, isNotEmpty);
  });

  test('lesson keys match the PWA format exactly (slug+index)', () {
    final j = _fixture().journeys.first;
    expect(j.lessonKey(0), 'ocean-pollution0');
    expect(j.lessonKey(2), 'ocean-pollution2');
  });

  test('search finds journeys by title and by chapter body', () {
    final c = _fixture();
    expect(
        srch.search(c, 'pollution').any((h) => h.kind == 'journey'), true);
    expect(srch.search(c, 'rivers').any((h) => h.kind == 'journey'), true);
  });

  test('reflections persist per journey', () async {
    await saveReflection('ocean-pollution', 'The rivers surprised me.');
    expect(await reflection('ocean-pollution'), 'The rivers surprised me.');
    expect(await reflection('other'), '');
  });

  test('kept quotes accumulate without duplicates', () async {
    await keepQuote('Rivers carry it to the sea.', 'Ocean Pollution 101');
    await keepQuote('Rivers carry it to the sea.', 'Ocean Pollution 101');
    await keepQuote('Bans work.', 'Ocean Pollution 101');
    final q = await savedQuotes();
    expect(q.length, 2);
    expect(q.first['t'], 'Bans work.');
  });
}
