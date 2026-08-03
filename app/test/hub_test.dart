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
    test('more than one server carries the map', () {
      // the main instance rate-limits shared IPs; mirrors are the
      // difference between "works" and "works sometimes"
      expect(Hub.overpassHosts.length, greaterThanOrEqualTo(2));
      expect(Hub.overpassHosts.first, 'overpass-api.de');
      expect(Hub.overpassHosts.toSet().length,
          Hub.overpassHosts.length); // no duplicates
    });

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

  group('alive right now (iNaturalist)', () {
    final sample = {
      'results': [
        {
          'count': 12,
          'taxon': {
            'name': 'Turdus migratorius',
            'preferred_common_name': 'american robin',
            'default_photo': {'square_url': 'https://x/robin.jpg'},
          },
        },
        {
          'count': 1,
          'taxon': {'name': 'Vulpes vulpes'}, // no common name
        },
        {'count': 3, 'taxon': {}}, // nameless: skipped
      ],
    };

    test('parses, capitalizes, prefers common names', () {
      final s = parseSightings(sample);
      expect(s.length, 2);
      expect(s[0].name, 'American robin');
      expect(s[0].sci, 'Turdus migratorius');
      expect(s[0].count, 12);
      expect(s[0].photo, 'https://x/robin.jpg');
      expect(s[1].name, 'Vulpes vulpes'); // Latin carries the day
      expect(s[1].photo, isNull);
    });

    test('round-trips through the cache format', () {
      for (final s in parseSightings(sample)) {
        final back = NatureSighting.fromJson(s.toJson());
        expect(back.name, s.name);
        expect(back.count, s.count);
        expect(back.photo, s.photo);
      }
    });

    test('the query asks for this month within 20km', () {
      final u = inatUri(32.80, 34.98, DateTime(2026, 8, 3));
      expect(u.host, 'api.inaturalist.org');
      expect(u.path, contains('species_counts'));
      expect(u.queryParameters['radius'], '20');
      expect(u.queryParameters['d1'], '2026-08-03');
      expect(u.queryParameters['verifiable'], 'true');
    });

    test('malformed responses yield an empty list', () {
      expect(parseSightings(const {}), isEmpty);
      expect(parseSightings(const {'results': []}), isEmpty);
    });

    test('kin matching: family word, whole words only', () {
      final seen = [
        const NatureSighting('American Robin', 'T. migratorius', 4),
        const NatureSighting('Coast Live Oak', 'Q. agrifolia', 2),
      ];
      // the robin's page answers with her American kin
      expect(sightingFor('European Robin', seen)?.name,
          'American Robin');
      expect(sightingFor('Oak', seen)?.count, 2);
      // no foxes were seen; the fox page stays quiet
      expect(sightingFor('Red Fox', seen), isNull);
      // "Owl" must not match "fowl" - whole words only
      expect(
          sightingFor('Owl',
              [const NatureSighting('Guineafowl', 'N. meleagris', 1)]),
          isNull);
    });
  });

  group('waiting for a home (adoption proxy)', () {
    final sample = {
      'animals': [
        {
          'id': 71,
          'name': 'Maple',
          'type': 'Dog',
          'breed': 'Terrier Mix',
          'age': 'Young',
          'photo': 'https://x/maple.jpg',
          'city': 'San Diego',
          'url': 'https://www.petfinder.com/dog/maple-71',
        },
        {'id': 72, 'name': '', 'url': 'https://x'}, // nameless: skip
        {'id': 73, 'name': 'Ghost', 'url': ''}, // no page: skip
      ],
    };

    test('parses the worker response, skips the unusable', () {
      final pets = parsePets(sample);
      expect(pets.length, 1);
      expect(pets[0].name, 'Maple');
      expect(pets[0].breed, 'Terrier Mix');
      expect(pets[0].city, 'San Diego');
      expect(pets[0].url, contains('http'));
    });

    test('malformed responses yield an empty list', () {
      expect(parsePets(const {}), isEmpty);
      expect(parsePets(const {'animals': []}), isEmpty);
    });

    test('adoption is gated by proxy AND country, together', () {
      // a North America door only, deployed or not
      expect(adoptionAvailable('il'), isFalse);
      expect(adoptionAvailable('gb'), isFalse);
      expect(adoptionAvailable(''), isFalse);
      // us/ca light up exactly when the worker URL is set - this
      // test stays green before and after the deploy
      expect(adoptionAvailable('us'), adoptProxy.isNotEmpty);
      expect(adoptionAvailable('ca'), adoptProxy.isNotEmpty);
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
