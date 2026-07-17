// Species portraits from Wikipedia (the same pipeline as the PWA and
// website), cached to disk so a portrait seen once is yours forever.

import 'dart:convert';
import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart';

class WikiSummary {
  final String extract;
  final String img; // upscaled attempt (800px), may not exist upstream
  final String imgSmall; // the guaranteed thumbnail as Wikipedia served it
  WikiSummary(this.extract, this.img, this.imgSmall);
}

Future<WikiSummary?> wikiSummary(String title) async {
  final prefs = await SharedPreferences.getInstance();
  // v2: earlier caches stored only an upscaled URL that can 404; ignore them.
  final key = 'wiki2_$title';
  final cached = prefs.getString(key);
  if (cached != null) {
    try {
      final j = jsonDecode(cached) as Map<String, dynamic>;
      final img = (j['img'] ?? '').toString();
      return WikiSummary((j['x'] ?? '').toString(), img,
          (j['imgs'] ?? img).toString());
    } catch (_) {}
  }
  try {
    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 8);
    final req = await client.getUrl(Uri.parse(
        'https://en.wikipedia.org/api/rest_v1/page/summary/${Uri.encodeComponent(title)}'));
    req.headers.set('user-agent', 'Hopeling/1.0 (https://hopeling.app)');
    final res = await req.close();
    if (res.statusCode != 200) return null;
    final body = await res.transform(utf8.decoder).join();
    final j = jsonDecode(body) as Map<String, dynamic>;
    final extract = (j['extract'] ?? '').toString();
    if (extract.isEmpty) return null;
    var small = '';
    final thumb = j['thumbnail'];
    if (thumb is Map && thumb['source'] != null) {
      small = thumb['source'].toString();
    }
    // Prefer the original if it is not absurdly heavy; else a larger thumb.
    var big = small.replaceFirst(RegExp(r'/(\d+)px-'), '/800px-');
    final orig = j['originalimage'];
    if (orig is Map && orig['source'] != null) {
      final ow = (orig['width'] is int) ? orig['width'] as int : 9999;
      if (ow <= 900) big = orig['source'].toString();
    }
    await prefs.setString(
        key, jsonEncode({'x': extract, 'img': big, 'imgs': small}));
    return WikiSummary(extract, big, small);
  } catch (_) {
    return null;
  }
}
