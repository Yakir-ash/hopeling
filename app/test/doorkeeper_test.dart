// The doorkeeper greets; it never files, pressures, or locks.

import 'package:flutter_test/flutter_test.dart';
import 'package:hopeling/features/home/doorkeeper.dart';

void main() {
  test('five doors, unique, each with a warm sub-line', () {
    expect(valleyDoors.length, 5);
    expect(valleyDoors.map((d) => d.id).toSet().length, 5);
    for (final d in valleyDoors) {
      expect(d.title.trim().isNotEmpty, isTrue);
      expect(d.sub.length, greaterThan(20), reason: d.id);
      expect(d.emoji.isNotEmpty, isTrue);
    }
  });

  test('a greeting, not a funnel: no pressure words, no dashes', () {
    final all = [
      for (final d in valleyDoors) ...[d.title, d.sub]
    ].join(' ').toLowerCase();
    for (final bad in [
      'sign up', 'subscribe', 'unlock', 'premium', 'limited',
      'hurry', 'don\'t miss',
    ]) {
      expect(all.contains(bad), isFalse, reason: bad);
    }
    expect(all.contains('—'), isFalse);
    expect(all.contains('–'), isFalse);
  });

  test('the expected rooms exist behind the doors', () {
    expect(valleyDoors.map((d) => d.id),
        containsAll(['animal', 'quiet', 'child', 'act', 'wonder']));
  });
}
