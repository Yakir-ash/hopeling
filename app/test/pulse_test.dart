// Rain & Pulse vs the constitution: stable identity, bounded retries,
// honest freshness, humble copy, and a queue that survives everything.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:hopeling/data/pulse.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('uuid4 is well-formed and unique', () {
    final seen = <String>{};
    for (var i = 0; i < 200; i++) {
      final u = uuid4();
      expect(
          RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$')
              .hasMatch(u),
          true,
          reason: u);
      expect(seen.add(u), true);
    }
  });

  test('backoff grows exponentially and is bounded at an hour', () {
    expect(backoff(0), const Duration(minutes: 1));
    expect(backoff(1), const Duration(minutes: 2));
    expect(backoff(3), const Duration(minutes: 8));
    expect(backoff(10), const Duration(minutes: 60));
  });

  test('events queue durably with stable identity', () async {
    await Pulse.add();
    await Pulse.add();
    final q = await Pulse.queue();
    expect(q.length, 2);
    expect(q[0].id == q[1].id, false);
    expect(q[0].day.length, 10);
    // reload from storage: identity survives
    final q2 = await Pulse.queue();
    expect(q2[0].id, q[0].id);
  });

  test('flush without a session keeps every drop safe', () async {
    await Pulse.add();
    final joined = await Pulse.flush(); // guest: nothing sent, nothing lost
    expect(joined, 0);
    expect((await Pulse.queue()).length, 1);
  });

  test('a corrupted queue recovers to empty, never crashes', () async {
    SharedPreferences.setMockInitialValues({'pulseQueue': '{broken'});
    expect(await Pulse.queue(), isEmpty);
  });

  test('drop json round-trips', () {
    final d = PendingDrop('abc', '2026-07-17', 1,
        attempts: 3, nextRetryMs: 999);
    final back = PendingDrop.fromJson(d.toJson());
    expect(back.id, 'abc');
    expect(back.attempts, 3);
    expect(back.nextRetryMs, 999);
  });

  test('freshness wears the truth openly', () {
    final now = DateTime(2026, 7, 17, 12, 0);
    expect(PulseSnap(5, now.subtract(const Duration(seconds: 30)))
        .freshness(now), 'live');
    expect(PulseSnap(5, now.subtract(const Duration(minutes: 10)))
        .freshness(now), 'updated 10 min ago');
    expect(PulseSnap(5, now.subtract(const Duration(hours: 3)))
        .freshness(now), 'updated 3h ago');
    expect(PulseSnap(5, now.subtract(const Duration(days: 3)))
        .freshness(now), 'offline snapshot');
  });

  test('the copy stays humble: no grandiosity, no false causality', () {
    final lines = [
      RainCopy.joined,
      RainCopy.pending,
      RainCopy.guest,
      RainCopy.quiet,
      RainCopy.unavailable,
      RainCopy.offlineJoined(3),
      RainCopy.watched(2),
    ];
    for (final l in lines) {
      for (final bad in [
        'saved the planet', 'changed the world', 'changed everything',
        'millions', 'watching', 'hurry'
      ]) {
        expect(l.toLowerCase().contains(bad), false,
            reason: '"$l" contains "$bad"');
      }
    }
    expect(RainCopy.offlineJoined(1), contains('drop '));
    expect(RainCopy.offlineJoined(4), contains('4 drops'));
  });
}
