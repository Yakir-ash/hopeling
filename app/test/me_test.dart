// The Me room vs the constitution: a story told with presence not
// scores, news parsed honestly from the bot-owned fields, a graph that
// waits until it has something true to show, and copy with no guilt.

import 'package:flutter_test/flutter_test.dart';

import 'package:hopeling/data/content.dart';
import 'package:hopeling/data/save.dart';
import 'package:hopeling/features/me/me_screen.dart';

void main() {
  test('news and wins parse from the content document', () {
    final c = AppContent.fromJson({
      'version': 26,
      'news': [
        {
          'd': '2026-07-18',
          'tag': '🎉',
          't': 'Wetland restored',
          'x': 'Detail',
          'src': 'mongabay.com',
          'url': 'https://example.org/story'
        },
        {'d': '2026-07-01', 't': 'No tag still fine'},
        {'d': '2026-07-02'}, // no title: dropped
      ],
      'wins': [
        {'d': '2026-07-08', 't': 'Dark earth boosts restoration'}
      ],
    }, true);
    expect(c.news.length, 2);
    expect(c.news.first.tag, '🎉');
    expect(c.news.first.url, 'https://example.org/story');
    expect(c.news[1].tag, '🎉'); // humane default
    expect(c.wins.single.t, 'Dark earth boosts restoration');
  });

  test('news age is honest and PWA-exact', () {
    expect(newsAge('2026-07-20', '2026-07-20'), 'today');
    expect(newsAge('2026-07-19', '2026-07-20'), 'yesterday');
    expect(newsAge('2026-07-08', '2026-07-20'), '12d ago');
    expect(newsAge('2026-01-01', '2026-07-20'), '2026-01-01');
  });

  test('the year graph waits for two weeks of truth', () {
    final s = Save();
    for (var i = 1; i <= 13; i++) {
      s.log['2026-07-${i.toString().padLeft(2, '0')}'] = 1;
    }
    expect(graphUnlocked(s), false);
    s.log['2026-07-14'] = 1;
    expect(graphUnlocked(s), true);
  });

  test('the story weaves your moments and the wild\'s wins, newest first',
      () {
    final s = Save();
    s.log['2026-06-01'] = 1;
    s.log['2026-06-02'] = 2;
    s.rings.add({'n': 7, 'end': '2026-06-20'});
    s.extra['guardian'] = {'id': 'vaquita', 'date': '2026-06-10'};
    final wins = [NewsItem('2026-07-08', '', 'Dark earth', '', 'mongabay.com', '')];
    final news = [
      NewsItem('2026-07-18', '🎉', 'Wetland restored', '', '', ''),
      NewsItem('2026-07-16', '🎉', 'Dark earth', '', '', ''), // dup title
    ];
    final ev = storyEvents(s, wins, news);
    expect(ev.first.$2, contains('Wetland restored'));
    expect(ev.map((e) => e.$2).where((t) => t.contains('Dark earth')).length,
        1); // deduped by title
    expect(ev.any((e) => e.$2.contains('planted your seed')), true);
    expect(ev.any((e) => e.$2.contains('7-day streak became a ring')), true);
    expect(ev.any((e) => e.$2.contains('took the pledge')), true);
    final dates = ev.map((e) => e.$1).toList();
    expect(dates, List.of(dates)..sort((a, b) => b.compareTo(a)));
  });

  test('the story head counts what is real and claims nothing', () {
    expect(storyHead(Save(), 5, '2026-07-20'),
        'Your story starts with your first action.');
    final s = Save();
    s.log['2026-07-18'] = 2;
    s.log['2026-07-19'] = 1;
    final h = storyHead(s, 4, '2026-07-20');
    expect(h, contains('3 days'));
    expect(h, contains('3 actions by you'));
    expect(h, contains('4 wins for the wild'));
    for (final bad in ['only', 'just ', 'saved the planet', 'hero']) {
      expect(h.toLowerCase().contains(bad), false);
    }
  });

  test('news links open https only', () async {
    // scheme guard: junk and non-web schemes are refused before launch
    await openNewsLink(''); // no throw
    await openNewsLink('javascript:alert(1)'); // refused by scheme guard
    await openNewsLink('file:///etc/passwd'); // refused by scheme guard
  });
}
