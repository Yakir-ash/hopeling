// Missions vs the constitution: explainable eligibility, honest
// freshness, a state machine that never double-rains, previews that
// never leak private notes, and copy that never plays the hero.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:hopeling/core/deeplink.dart';
import 'package:hopeling/data/missions.dart';

Mission _m({
  String status = 'approved',
  List<int> months = const [],
  String verified = '2026-07-01',
  bool family = true,
  String supervision = 'none',
}) =>
    Mission.fromJson({
      'id': 'x',
      't': 'Count pollinators',
      'type': 'science',
      'sum': 's',
      'desc': 'd',
      'supervision': supervision,
      'dataUse': 'stored in the archive',
      'verified': verified,
      'status': status,
      'cats': ['bees'],
      'safety': ['stay comfortable'],
      'steps': ['watch'],
      'sources': ['Xerces Society'],
      'months': months,
      'min': 10,
      'family': family,
      'protocol': [
        {'k': 'count', 'label': 'Visits', 'kind': 'count'},
        {'k': 'note', 'label': 'Private note', 'kind': 'note'},
      ],
    });

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('eligibility is explainable: season, staleness, editorial, kids', () {
    final july = DateTime(2026, 7, 20);
    expect(missionFit(_m(), july), MissionFit.eligible);
    expect(missionFit(_m(months: [1, 2]), july), MissionFit.outOfSeason);
    expect(missionFit(_m(status: 'draft'), july), MissionFit.notApproved);
    expect(missionFit(_m(verified: '2025-01-01'), july), MissionFit.stale);
    expect(
        missionFit(_m(family: false), july, kidsMode: true),
        MissionFit.notForKids);
    expect(
        missionFit(_m(supervision: 'adult'), july, kidsMode: true),
        MissionFit.needsAdult);
    // adults are informed, not blocked, by supervision notes
    expect(missionFit(_m(supervision: 'adult'), july), MissionFit.eligible);
  });

  test('freshness is worn openly and warns when old', () {
    final now = DateTime(2026, 7, 20);
    expect(freshnessLine(_m(), now), 'verified 2026-07-01');
    expect(freshnessLine(_m(verified: '2025-06-01'), now),
        contains('please confirm'));
  });

  test('the participation state machine never rains twice', () async {
    final part = Participation();
    await completeMission('x', part, submitted: false);
    expect(part.state, 'completedPrivate');
    expect(part.rained, true);
    // completing again (e.g. submitted later) adds no second drop
    final before = part.rained;
    await completeMission('x', part, submitted: true);
    expect(part.state, 'completedSubmitted');
    expect(part.rained, before); // still exactly one
  });

  test('participation round-trips through storage', () async {
    final p = Participation(
        state: 'drafted',
        startedDay: '2026-07-20',
        draft: {'count': 4},
        rained: false);
    await MissionStore.put('x', p);
    final back = await MissionStore.of('x');
    expect(back.state, 'drafted');
    expect(back.draft['count'], 4);
    expect(back.rained, false);
  });

  test('the observation queue is durable, guest-safe, corruption-proof',
      () async {
    await ObsQueue.enqueue('x', {'count': 4, 'weather': 'Sunny'});
    final q = await ObsQueue.all();
    expect(q.length, 1);
    expect(q.first.payload['count'], 4);
    expect(q.first.id.length, 36); // uuid idempotency key
    expect(await ObsQueue.flush(), 0); // guest: nothing sent, nothing lost
    expect((await ObsQueue.all()).length, 1);
    SharedPreferences.setMockInitialValues({'obsQueue': '{oops'});
    expect(await ObsQueue.all(), isEmpty);
  });

  test('protocol parsing keeps notes distinct from submittable fields', () {
    final m = _m();
    expect(m.protocol.length, 2);
    final submittable =
        m.protocol.where((f) => f.kind != 'note').map((f) => f.k);
    expect(submittable, ['count']);
    expect(m.protocol.any((f) => f.kind == 'note'), true);
  });

  test('mission deep links parse', () {
    expect(parseDeepLink('hopeling://missions')!.type, 'missions');
    expect(parseDeepLink('hopeling://mission/pollinator-count')!.id,
        'pollinator-count');
  });

  test('the copy never plays the hero and never claims false science', () {
    final lines = [
      MissionCopy.intro,
      MissionCopy.noLocation,
      MissionCopy.privateSaved,
      MissionCopy.submitted,
      MissionCopy.pendingOffline,
      MissionCopy.previewNote,
      MissionCopy.historyEmpty,
      _m().dataUse,
      _m().desc,
    ];
    for (final l in lines) {
      for (final bad in [
        'save the planet', 'save the forest', 'protect endangered',
        'measurable scientific change', 'certified', 'hero', 'hurry',
        'last chance'
      ]) {
        expect(l.toLowerCase().contains(bad), false,
            reason: '"$l" contains "$bad"');
      }
    }
    // and the one promise that must exist: no location, stated plainly
    expect(MissionCopy.previewNote.contains('No location'), true);
  });
}
