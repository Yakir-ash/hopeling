// The Hub's pure heart: coordinates that protect privacy by
// construction, distances that are true, an Overpass query that
// asks for exactly what we show, a parser that never chokes, and
// rescue guidance that is calm and complete.

import 'package:flutter_test/flutter_test.dart';
import 'package:hopeling/data/hub.dart';

void main() {
  group('privacy by construction', () {
    test('coordinates round to ~2km before anything else', () {
      expect(roundCoord(32.7941), closeTo(32.80, 0.0001));
      expect(roundCoord(34.9896), closeTo(34.98, 0.0001));
      // rounding is idempotent
      expect(roundCoord(roundCoord(31.7683)),
          roundCoord(31.7683));
    });
  });

  group('distance', () {
    test('Haifa to Tel Aviv is about 80 km', () {
      final km = distanceKm(32.794, 34.989, 32.08, 34.78);
      expect(km, inInclusiveRange(70, 95));
    });
    test('zero distance to yourself', () {
      expect(distanceKm(32.0, 34.0, 32.0, 34.0), closeTo(0, 0.001));
    });
  });

  group('the overpass query', () {
    test('asks for exactly what the Hub shows', () {
      final q = overpassQuery(32.80, 34.98);
      for (final needle in [
        'animal_shelter',
        'nature_reserve',
        'national_park',
        'bird_hide',
        'botanical',
        'around:20000,32.8,34.98',
        'out:json',
      ]) {
        expect(q.contains(needle), isTrue, reason: needle);
      }
    });
  });

  group('the parser', () {
    final sample = {
      'elements': [
        {
          'type': 'node',
          'id': 1,
          'lat': 32.81,
          'lon': 34.99,
          'tags': {
            'amenity': 'animal_shelter',
            'name': 'Haifa Animal Shelter',
            'phone': '+972 4 0000000',
          },
        },
        {
          'type': 'way',
          'id': 2,
          'center': {'lat': 32.75, 'lon': 35.05},
          'tags': {
            'leisure': 'nature_reserve',
            'name': 'Carmel Reserve',
            'website': 'https://example.org',
          },
        },
        {
          // a relation duplicating the way: deduped by kind+name
          'type': 'relation',
          'id': 3,
          'center': {'lat': 32.751, 'lon': 35.051},
          'tags': {
            'leisure': 'nature_reserve',
            'name': 'Carmel Reserve'
          },
        },
        {
          // unnamed: skipped without complaint
          'type': 'node',
          'id': 4,
          'lat': 32.7,
          'lon': 35.0,
          'tags': {'leisure': 'nature_reserve'},
        },
        {
          // no coordinates at all: skipped
          'type': 'relation',
          'id': 5,
          'tags': {'boundary': 'national_park', 'name': 'Ghost'},
        },
      ],
    };

    test('parses, dedupes, and skips the unusable', () {
      final places = parseOverpass(sample);
      expect(places.length, 2);
      final shelter = places.firstWhere((p) => p.isShelter);
      expect(shelter.name, 'Haifa Animal Shelter');
      expect(shelter.phone, '+972 4 0000000');
      expect(shelter.emoji, '🐾');
      final reserve = places.firstWhere((p) => !p.isShelter);
      expect(reserve.kind, 'reserve');
      expect(reserve.website, 'https://example.org');
      expect(reserve.lat, closeTo(32.75, 0.001));
    });

    test('an empty or malformed response yields an empty list', () {
      expect(parseOverpass(const {}), isEmpty);
      expect(parseOverpass(const {'elements': []}), isEmpty);
    });

    test('round-trips through the cache format', () {
      final places = parseOverpass(sample);
      for (final p in places) {
        final back = HubPlace.fromJson(p.toJson());
        expect(back.name, p.name);
        expect(back.kind, p.kind);
        expect(back.website, p.website);
        expect(back.phone, p.phone);
      }
    });
  });

  group('help a wild animal', () {
    test('the guidance is present and calm', () {
      expect(WildRescue.doList.length, greaterThanOrEqualTo(4));
      expect(WildRescue.dontList.length, greaterThanOrEqualTo(3));
      final all = [
        ...WildRescue.doList,
        ...WildRescue.dontList,
        rescueFallback,
        for (final l in rescueLines.values) ...[l.org, l.note],
      ].join(' ');
      for (final bad in ['panic', 'hurry', 'you must not fail']) {
        expect(all.toLowerCase().contains(bad), isFalse);
      }
      expect(all.contains('—'), isFalse);
      expect(all.contains('–'), isFalse);
    });

    test('country lines are lowercase iso2 with a way to reach help',
        () {
      for (final e in rescueLines.entries) {
        expect(e.key, matches(RegExp(r'^[a-z]{2}$')));
        expect(e.value.org.trim(), isNotEmpty);
        // every entry offers a phone, a directory, or clear
        // in-note guidance - never a dead end
        expect(
            (e.value.phone?.trim().isNotEmpty ?? false) ||
                (e.value.url?.trim().isNotEmpty ?? false) ||
                e.value.note.length > 40,
            isTrue,
            reason: '${e.key} offers no road to help');
      }
      // North America is the flagship; Israel is home
      expect(rescueLines.containsKey('us'), isTrue);
      expect(rescueLines.containsKey('ca'), isTrue);
      expect(rescueLines.containsKey('il'), isTrue);
      expect(rescueLines['us']!.url, contains('ahnow'));
    });

    test('unknown countries get honest fallback guidance', () {
      expect(rescueLines['zz'], isNull);
      expect(rescueFallback, contains('wildlife'));
    });
  });
}
