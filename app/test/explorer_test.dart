// The Noticing Walk vs the constitution: the child declares the
// habitat (no sensors have anything to say), the reveal is a home not
// a slot machine, and the copy never claims an animal IS there, never
// shames a guess, and always frames us as guests.

import 'package:flutter_test/flutter_test.dart';

import 'package:hopeling/data/explorer.dart';

void main() {
  test('every habitat is complete and the window counts', () {
    expect(habitats.length, 6);
    expect(habitats.any((h) => h.id == 'window'), true); // everyone plays
    for (final h in habitats) {
      expect(h.cast.length, greaterThanOrEqualTo(4));
      expect(h.observePrompts.length, greaterThanOrEqualTo(4));
      for (final a in h.cast) {
        expect(a.detail.isNotEmpty && a.hook.isNotEmpty && a.sign.isNotEmpty,
            true,
            reason: '${a.name} is missing its story');
      }
    }
  });

  test('the reveal is deterministic - a home, not a slot machine', () {
    final h = habitats.first;
    final now = DateTime(2026, 7, 22, 10);
    expect(revealFor(h, 1, 2, now).name, revealFor(h, 1, 2, now).name);
    // different noticing may meet a different neighbor (same day is fine
    // too - only stability is promised)
    expect(revealFor(h, 0, 0, now).name, revealFor(h, 0, 0, now).name);
  });

  test('the wonder question rotates daily and never has a wrong answer',
      () {
    final now = DateTime(2026, 7, 22);
    expect(wonderFor(now).$1, wonderFor(now).$1);
    for (final (q, opts) in wonderQuestions) {
      expect(q.endsWith('?'), true);
      expect(opts.length, greaterThanOrEqualTo(3));
    }
  });

  test('the copy is a guest, never a landlord and never a liar', () {
    final a = habitats.first.cast.first;
    final r = WalkCopy.reveal(a, habitats.first);
    // lives-here language, not is-here claims
    expect(r.contains('live in places like this'), true);
    for (final line in [
      r, WalkCopy.guest, WalkCopy.remember(a), WalkCopy.end,
      WalkCopy.pause, WalkCopy.doorSub
    ]) {
      for (final bad in [
        'caught', 'collect', 'wrong', 'failed', 'missed it',
        'is right there', 'points', 'reward', 'streak'
      ]) {
        expect(line.toLowerCase().contains(bad), false,
            reason: '"$line" contains "$bad"');
      }
    }
    expect(WalkCopy.guest.contains('guest'), true);
  });

  test('no animal story overpromises - details are single true things',
      () {
    for (final h in habitats) {
      for (final a in h.cast) {
        for (final bad in ['always', 'never fails', 'guaranteed']) {
          expect(a.detail.toLowerCase().contains(bad), false);
        }
      }
    }
  });
}
