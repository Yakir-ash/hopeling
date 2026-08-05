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

// ---------- alive right now: iNaturalist ----------

/// One species really seen near the user this month, logged by a
/// real person on iNaturalist.
class NatureSighting {
  final String name; // common name when known, else scientific
  final String sci;
  final int count; // observations this month within the radius
  final String? photo; // small square taxon photo
  const NatureSighting(this.name, this.sci, this.count, {this.photo});

  Map<String, dynamic> toJson() => {
        'n': name,
        's': sci,
        'c': count,
        if (photo != null) 'f': photo,
      };

  static NatureSighting fromJson(Map<String, dynamic> j) =>
      NatureSighting((j['n'] ?? '').toString(), (j['s'] ?? '').toString(),
          (j['c'] as num?)?.toInt() ?? 0,
          photo: j['f']?.toString());
}

/// The species-counts query: which species were observed within
/// [radiusKm] of the (rounded) point since [since]. Keyless reads,
/// per iNaturalist's API terms.
Uri inatUri(double lat, double lon, DateTime since,
    {int radiusKm = 20}) {
  String two(int v) => v.toString().padLeft(2, '0');
  return Uri.https('api.inaturalist.org', '/v1/observations/species_counts', {
    'lat': '$lat',
    'lng': '$lon',
    'radius': '$radiusKm',
    'd1': '${since.year}-${two(since.month)}-${two(since.day)}',
    'verifiable': 'true',
    'per_page': '12',
    'locale': 'en',
  });
}

/// Turn a species-counts response into sightings. Defensive; the
/// nameless are skipped, common names win over Latin.
List<NatureSighting> parseSightings(Map<String, dynamic> json) {
  final out = <NatureSighting>[];
  for (final r in (json['results'] as List? ?? const [])) {
    if (r is! Map) continue;
    final taxon = (r['taxon'] as Map?) ?? const {};
    final sci = (taxon['name'] ?? '').toString();
    var common = (taxon['preferred_common_name'] ?? '').toString();
    if (common.isNotEmpty) {
      common = common[0].toUpperCase() + common.substring(1);
    }
    final name = common.isNotEmpty ? common : sci;
    if (name.isEmpty) continue;
    out.add(NatureSighting(
      name,
      sci,
      (r['count'] as num?)?.toInt() ?? 0,
      photo: ((taxon['default_photo'] as Map?)?['square_url'])
          ?.toString(),
    ));
  }
  return out;
}

/// Does any recent sighting match this species? Matched on the
/// species' family word ("fox", "robin", "oak"), so kin count:
/// an American Robin near San Diego honestly answers for the
/// robin's page. Null when nothing close was logged.
NatureSighting? sightingFor(
    String speciesName, List<NatureSighting> sightings) {
  final words = speciesName.trim().toLowerCase().split(' ');
  if (words.isEmpty) return null;
  final family = words.last;
  final re = RegExp('\\b$family\\b', caseSensitive: false);
  for (final s in sightings) {
    if (re.hasMatch(s.name)) return s;
  }
  return null;
}

// ---------- adopt: RescueGroups.org via our worker ----------

/// One adoptable animal, exactly the fields the worker forwards.
class AdoptablePet {
  final int id;
  final String name;
  final String type; // Dog | Cat | Rabbit | Bird | ...
  final String? breed, age, photo, city;
  final String? sex, size;
  final String desc; // her story, as the rescue wrote it; may be ''
  final String url; // her exact page when it exists, else her rescue
  final String? orgEmail, orgPhone;
  const AdoptablePet({
    required this.id,
    required this.name,
    required this.type,
    required this.url,
    this.breed,
    this.age,
    this.photo,
    this.city,
    this.sex,
    this.size,
    this.desc = '',
    this.orgEmail,
    this.orgPhone,
  });

  /// The same CDN photo, big enough for a detail sheet.
  String? get photoLarge =>
      photo?.replaceAll('width=300', 'width=600');
}

/// Parse the worker's /animals response. Anything without a name
/// or a page to meet them on is skipped.
List<AdoptablePet> parsePets(Map<String, dynamic> json) {
  final out = <AdoptablePet>[];
  for (final a in (json['animals'] as List? ?? const [])) {
    if (a is! Map) continue;
    final name = (a['name'] ?? '').toString().trim();
    final url = (a['url'] ?? '').toString();
    if (name.isEmpty || url.isEmpty) continue;
    out.add(AdoptablePet(
      id: (a['id'] as num?)?.toInt() ?? 0,
      name: name,
      type: (a['type'] ?? '').toString(),
      url: url,
      breed: a['breed']?.toString(),
      age: a['age']?.toString(),
      photo: a['photo']?.toString(),
      city: a['city']?.toString(),
      sex: a['sex']?.toString(),
      size: a['size']?.toString(),
      desc: (a['desc'] ?? '').toString(),
      orgEmail: a['orgEmail']?.toString(),
      orgPhone: a['orgPhone']?.toString(),
    ));
  }
  return out;
}

/// Live adoption exists where the data does (North America) and
/// only once the worker is deployed and its URL set below.
bool adoptionAvailable(String countryCode) =>
    adoptProxy.isNotEmpty &&
    (countryCode == 'us' || countryCode == 'ca');

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

  /// POST a form body (Overpass prefers POST for long queries).
  static Future<String> _post(Uri uri, String body) async {
    final c = HttpClient()
      ..connectionTimeout = const Duration(seconds: 12)
      ..userAgent = _ua;
    try {
      final req = await c.postUrl(uri);
      req.headers.contentType =
          ContentType('application', 'x-www-form-urlencoded');
      req.write(body);
      final res = await req.close();
      if (res.statusCode != 200) {
        throw HttpException('HTTP ${res.statusCode}');
      }
      return await res.transform(utf8.decoder).join();
    } finally {
      c.close();
    }
  }

  /// The public Overpass servers, tried in order. The main
  /// instance rate-limits shared IPs freely; the mirrors exist for
  /// exactly this. First answer wins.
  static const overpassHosts = [
    'overpass-api.de',
    'overpass.kumi.systems',
    'overpass.private.coffee',
  ];

  static Future<String> _overpass(String query) async {
    Object? last;
    for (final host in overpassHosts) {
      try {
        return await _post(Uri.https(host, '/api/interpreter'),
            'data=${Uri.encodeQueryComponent(query)}')
            .timeout(const Duration(seconds: 30));
      } catch (e) {
        last = e; // try the next mirror
      }
    }
    throw last ?? const HttpException('overpass unreachable');
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
      final body = await _overpass(overpassQuery(a.lat, a.lon));
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

  /// What people really saw within 20km this month. Cached two
  /// days per area; offline the cache answers; failing quietly is
  /// fine - this section simply does not appear.
  static Future<List<NatureSighting>> sightings(HubArea a) async {
    final p = await SharedPreferences.getInstance();
    final key = 'inatCache_${a.lat}_${a.lon}';
    final cached = p.getString(key);
    Map<String, dynamic>? cj;
    if (cached != null) {
      try {
        cj = jsonDecode(cached) as Map<String, dynamic>;
      } catch (_) {}
    }
    final fresh = cj != null &&
        DateTime.now()
                .difference(DateTime.fromMillisecondsSinceEpoch(
                    (cj['t'] as num).toInt()))
                .inHours <
            48;
    List<NatureSighting> fromCache() => [
          for (final j in (cj!['s'] as List))
            NatureSighting.fromJson(j as Map<String, dynamic>)
        ];
    if (fresh) return fromCache();
    try {
      final since = DateTime.now().subtract(const Duration(days: 30));
      final body = await _get(inatUri(a.lat, a.lon, since));
      final s = parseSightings(jsonDecode(body) as Map<String, dynamic>);
      await p.setString(
          key,
          jsonEncode({
            't': DateTime.now().millisecondsSinceEpoch,
            's': [for (final x in s) x.toJson()],
          }));
      return s;
    } catch (_) {
      return cj != null ? fromCache() : const [];
    }
  }

  /// Adoptable animals through our worker. Only called when
  /// [adoptionAvailable] says so; coordinates are already rounded.
  static Future<List<AdoptablePet>> adoptablePets(HubArea a,
      {String type = ''}) async {
    final uri = Uri.parse(adoptProxy).replace(
        path: '/animals',
        queryParameters: {
          'lat': '${a.lat}',
          'lon': '${a.lon}',
          if (type.isNotEmpty) 'type': type,
        });
    final body = await _get(uri);
    return parsePets(jsonDecode(body) as Map<String, dynamic>);
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

/// A country's wildlife rescue contact: a phone line, a directory
/// site, or both - because the right answer differs by country
/// (the US has no national number; it has an excellent directory).
/// IMPORTANT: entries ship only after a human has verified them
/// against the organization's own site. Verified entries carry the
/// date; everything else falls back to honest search guidance.
class RescueLine {
  final String org;
  final String? phone; // dialable text; may be a short code
  final String? url; // a directory or finder site
  final String note;
  final String verified; // yyyy-mm-dd of last human check
  const RescueLine(this.org, this.note, this.verified,
      {this.phone, this.url});
}

const rescueLines = <String, RescueLine>{
  // VERIFY-BEFORE-RELEASE: confirm each entry against the
  // organization's own site, then update the date. The US and CA
  // entries are the co-founder's to verify - North America is the
  // flagship market.
  'us': RescueLine(
      'Animal Help Now',
      'The US has no single national number - Animal Help Now is '
          'the nationwide directory: enter your location and it '
          'shows the nearest wildlife emergency services, 24/7.',
      'unverified',
      url: 'https://ahnow.org'),
  'ca': RescueLine(
      'Provincial wildlife rescue',
      'Canada organizes wildlife rescue by province. Search your '
          'province plus "wildlife rehabilitation" - most SPCAs '
          'and provincial wildlife centres take these calls and '
          'will route you.',
      'unverified'),
  'il': RescueLine(
      'Israel Nature and Parks Authority (מוקד רט"ג)',
      'The national hotline for injured wild animals in Israel. '
          'For wild animals only - for dogs and cats call your '
          'municipality.',
      'unverified',
      phone: '*3639'),
  'gb': RescueLine(
      'RSPCA (England & Wales)',
      'The national animal emergency line. In Scotland call the '
          'Scottish SPCA on 03000 999 999.',
      'unverified',
      phone: '0300 1234 999'),
};

/// The adoption proxy endpoint (North America, backed by
/// RescueGroups.org). Empty until the Cloudflare Worker in
/// proxy/rescuegroups-worker.js is deployed; the app shows live
/// adoptable animals only when this is set.
const adoptProxy = 'https://hopeling-adopt.hopeling.workers.dev';

/// Guidance for countries we have not verified yet - honest, and
/// still genuinely useful.
const rescueFallback =
    'Search for "wildlife rescue" or "wildlife rehabilitator" plus '
    'your city - most regions have a rescue center or hotline. A '
    'local veterinarian will also know whom to call, and many will '
    'stabilize wild animals at no charge.';
