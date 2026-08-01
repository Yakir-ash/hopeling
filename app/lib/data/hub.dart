// The Nature & Animal Hub, phase one - the place you open to act
// in your own community. Design: HUB.md. The rules that matter:
//
//   PRIVACY   manual-first: the user types a place; coordinates are
//             rounded to ~2km before ANY network request; the area
//             lives on this device only, never on any server of ours
//   HONESTY   OpenStreetMap coverage varies; empty states say so;
//             cached results carry their age openly
//   SAFETY    the wildlife-rescue guidance is universal and calm;
//             country hotlines ship only after human verification
//
// Data partners (all keyless): OSM Nominatim (geocoding), OSM
// Overpass (places). The app identifies itself politely with a
// User-Agent, per both projects' usage policies.

import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

const _ua = 'Hopeling/1.0 (https://hopeling.app)';

// ---------- pure helpers (tested) ----------

/// Round a coordinate to ~2km so a precise location never leaves
/// the device. 0.02 degrees is roughly 2.2km of latitude.
double roundCoord(double v) => (v / 0.02).round() * 0.02;

/// Distance between two points in km (haversine).
double distanceKm(double lat1, double lon1, double lat2, double lon2) {
  const r = 6371.0;
  final dLat = (lat2 - lat1) * pi / 180.0;
  final dLon = (lon2 - lon1) * pi / 180.0;
  final a = sin(dLat / 2) * sin(dLat / 2) +
      cos(lat1 * pi / 180.0) *
          cos(lat2 * pi / 180.0) *
          sin(dLon / 2) *
          sin(dLon / 2);
  return 2 * r * asin(sqrt(a));
}

/// The Overpass query for everything the Hub cares about within
/// [radiusM] of a (rounded) point.
String overpassQuery(double lat, double lon, {int radiusM = 20000}) {
  final at = 'around:$radiusM,$lat,$lon';
  return '[out:json][timeout:25];('
      'nwr["amenity"="animal_shelter"]($at);'
      'nwr["leisure"="nature_reserve"]($at);'
      'nwr["boundary"="national_park"]($at);'
      'nwr["leisure"="bird_hide"]($at);'
      'nwr["leisure"="garden"]["garden:type"="botanical"]($at);'
      ');out center tags 80;';
}

/// One place from the map: a shelter, a reserve, a garden.
class HubPlace {
  final String name;
  final String kind; // shelter | reserve | park | hide | garden
  final double lat, lon;
  final String? website, phone;
  const HubPlace({
    required this.name,
    required this.kind,
    required this.lat,
    required this.lon,
    this.website,
    this.phone,
  });

  bool get isShelter => kind == 'shelter';

  String get emoji => switch (kind) {
        'shelter' => '🐾',
        'park' => '🏞️',
        'hide' => '🦆',
        'garden' => '🌷',
        _ => '🌿',
      };

  Map<String, dynamic> toJson() => {
        'n': name,
        'k': kind,
        'la': lat,
        'lo': lon,
        if (website != null) 'w': website,
        if (phone != null) 'p': phone,
      };

  static HubPlace fromJson(Map<String, dynamic> j) => HubPlace(
        name: (j['n'] ?? '').toString(),
        kind: (j['k'] ?? '').toString(),
        lat: (j['la'] as num).toDouble(),
        lon: (j['lo'] as num).toDouble(),
        website: j['w']?.toString(),
        phone: j['p']?.toString(),
      );
}

/// Turn an Overpass response into places. Defensive: unnamed or
/// coordinate-less elements are quietly skipped.
List<HubPlace> parseOverpass(Map<String, dynamic> json) {
  final out = <HubPlace>[];
  final seen = <String>{};
  for (final e in (json['elements'] as List? ?? const [])) {
    if (e is! Map) continue;
    final tags = (e['tags'] as Map?) ?? const {};
    final name = (tags['name:en'] ?? tags['name'] ?? '').toString();
    if (name.isEmpty) continue;
    final lat = (e['lat'] ?? (e['center'] as Map?)?['lat']) as num?;
    final lon = (e['lon'] ?? (e['center'] as Map?)?['lon']) as num?;
    if (lat == null || lon == null) continue;
    final kind = tags['amenity'] == 'animal_shelter'
        ? 'shelter'
        : tags['boundary'] == 'national_park'
            ? 'park'
            : tags['leisure'] == 'bird_hide'
                ? 'hide'
                : tags['leisure'] == 'garden'
                    ? 'garden'
                    : 'reserve';
    if (!seen.add('$kind:$name')) continue; // ways+relations dupes
    out.add(HubPlace(
      name: name,
      kind: kind,
      lat: lat.toDouble(),
      lon: lon.toDouble(),
      website:
          (tags['website'] ?? tags['contact:website'])?.toString(),
      phone: (tags['phone'] ?? tags['contact:phone'])?.toString(),
    ));
  }
  return out;
}

// ---------- the chosen area ----------

class HubArea {
  final String name; // what the user picked, e.g. "Haifa"
  final String countryCode; // lowercase iso2, may be ''
  final double lat, lon; // already rounded
  const HubArea(this.name, this.countryCode, this.lat, this.lon);
}

class Hub {
  static Future<HubArea?> area() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString('hubArea');
    if (raw == null) return null;
    try {
      final j = jsonDecode(raw) as Map<String, dynamic>;
      return HubArea(
          (j['n'] ?? '').toString(),
          (j['c'] ?? '').toString(),
          (j['la'] as num).toDouble(),
          (j['lo'] as num).toDouble());
    } catch (_) {
      return null;
    }
  }

  static Future<void> setArea(HubArea a) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(
        'hubArea',
        jsonEncode(
            {'n': a.name, 'c': a.countryCode, 'la': a.lat, 'lo': a.lon}));
  }

  static Future<String> _get(Uri uri) async {
    final c = HttpClient()
      ..connectionTimeout = const Duration(seconds: 12)
      ..userAgent = _ua;
    try {
      final req = await c.getUrl(uri);
      final res = await req.close();
      if (res.statusCode != 200) {
        throw HttpException('HTTP ${res.statusCode}');
      }
      return await res.transform(utf8.decoder).join();
    } finally {
      c.close();
    }
  }

  /// Geocode a typed place name. Returns up to 5 candidates.
  static Future<List<HubArea>> geocode(String query) async {
    final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
      'q': query,
      'format': 'jsonv2',
      'limit': '5',
      'addressdetails': '1',
    });
    final body = await _get(uri);
    final list = jsonDecode(body) as List;
    return [
      for (final e in list)
        if (e is Map)
          HubArea(
            _shortName(e),
            ((e['address'] as Map?)?['country_code'] ?? '')
                .toString()
                .toLowerCase(),
            roundCoord(double.parse(e['lat'].toString())),
            roundCoord(double.parse(e['lon'].toString())),
          )
    ];
  }

  static String _shortName(Map e) {
    final full = (e['display_name'] ?? '').toString();
    final parts = full.split(', ');
    if (parts.length <= 2) return full;
    return '${parts.first}, ${parts.last}';
  }

  /// Nearby places, cached for a week per rounded area. Offline or
  /// on failure, the cache answers with its age; with no cache the
  /// error is honest.
  static Future<(List<HubPlace>, DateTime)> nearby(HubArea a,
      {bool forceRefresh = false}) async {
    final p = await SharedPreferences.getInstance();
    final key = 'hubCache_${a.lat}_${a.lon}';
    final cached = p.getString(key);
    Map<String, dynamic>? cachedJson;
    if (cached != null) {
      try {
        cachedJson = jsonDecode(cached) as Map<String, dynamic>;
      } catch (_) {}
    }
    final fresh = cachedJson != null &&
        DateTime.now()
                .difference(DateTime.fromMillisecondsSinceEpoch(
                    (cachedJson['t'] as num).toInt()))
                .inDays <
            7;
    if (fresh && !forceRefresh) {
      return (
        [
          for (final j in (cachedJson!['p'] as List))
            HubPlace.fromJson(j as Map<String, dynamic>)
        ],
        DateTime.fromMillisecondsSinceEpoch(
            (cachedJson['t'] as num).toInt())
      );
    }
    try {
      final body = await _get(Uri.https(
          'overpass-api.de',
          '/api/interpreter',
          {'data': overpassQuery(a.lat, a.lon)}));
      final places =
          parseOverpass(jsonDecode(body) as Map<String, dynamic>);
      places.sort((x, y) => distanceKm(a.lat, a.lon, x.lat, x.lon)
          .compareTo(distanceKm(a.lat, a.lon, y.lat, y.lon)));
      final now = DateTime.now();
      await p.setString(
          key,
          jsonEncode({
            't': now.millisecondsSinceEpoch,
            'p': [for (final pl in places) pl.toJson()],
          }));
      return (places, now);
    } catch (_) {
      if (cachedJson != null) {
        // the network failed; yesterday's map is better than none
        return (
          [
            for (final j in (cachedJson['p'] as List))
              HubPlace.fromJson(j as Map<String, dynamic>)
          ],
          DateTime.fromMillisecondsSinceEpoch(
              (cachedJson['t'] as num).toInt())
        );
      }
      rethrow;
    }
  }
}

// ---------- help a wild animal ----------

/// Universal guidance: true everywhere, safe everywhere, calm.
class WildRescue {
  static const doList = [
    'Watch first, from a distance. Many young animals are not '
        'abandoned - a parent is often nearby, waiting for you to '
        'leave.',
    'If the animal is clearly hurt or in danger, gently cover it '
        'with a towel and place it in a ventilated box with a lid.',
    'Keep the box somewhere dark, quiet, and warm. Darkness calms '
        'a frightened animal better than comforting words.',
    'Wash your hands well after any contact.',
    'Call the rescue line before driving anywhere - they will tell '
        'you exactly what to do next.',
  ];
  static const dontList = [
    'Do not give food or water. Well-meant feeding harms shocked '
        'animals more often than it helps.',
    'Do not handle bats, snakes, or birds of prey with bare '
        'hands - call first, always.',
    'Do not keep checking on it. Every peek costs the animal '
        'energy it needs.',
    'Do not try to raise a wild animal yourself - it is illegal in '
        'most places and rarely ends well for the animal.',
  ];
}

/// A country's wildlife rescue contact.
/// IMPORTANT: entries ship only after a human has verified them
/// against the organization's own site. Verified entries carry the
/// date; everything else falls back to honest search guidance.
class RescueLine {
  final String org;
  final String phone; // as dialable text; may be short code
  final String note;
  final String verified; // yyyy-mm-dd of last human check
  const RescueLine(this.org, this.phone, this.note, this.verified);
}

const rescueLines = <String, RescueLine>{
  // VERIFY-BEFORE-RELEASE: Yakir to confirm each number against
  // the organization's site, then update the date.
  'il': RescueLine(
      'Israel Nature and Parks Authority (מוקד רט"ג)',
      '*3639',
      'The national hotline for injured wild animals in Israel. '
          'For wild animals only - for dogs and cats call your '
          'municipality.',
      'unverified'),
  'gb': RescueLine(
      'RSPCA (England & Wales)',
      '0300 1234 999',
      'The national animal emergency line. In Scotland call the '
          'Scottish SPCA on 03000 999 999.',
      'unverified'),
};

/// Guidance for countries we have not verified yet - honest, and
/// still genuinely useful.
const rescueFallback =
    'Search for "wildlife rescue" or "wildlife rehabilitator" plus '
    'your city - most regions have a rescue center or hotline. A '
    'local veterinarian will also know whom to call, and many will '
    'stabilize wild animals at no charge.';
