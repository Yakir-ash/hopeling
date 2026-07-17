// Species portraits from Wikipedia (the same pipeline as the PWA and
// website), cached to disk so a portrait seen once is yours forever.

import 'dart:convert';
import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart';

class WikiSummary {
  final String extract;
  final String img; // 800px thumbnail, '' if none
  WikiSummary(this.extract, this.img);
}

Future<WikiSummary?> wikiSummary(String title) async {
  final prefs = await SharedPreferences.getInstance();
  final key = 'wiki_$title';
  final cached = prefs.getString(key);
  if (cached != null) {
    try {
      final j = jsonDecode(cached) as Map<String, dynamic>;
      return WikiSummary((j['x'] ?? '').toString(), (j['img'] ?? '').toString());
    } catch (_) {}
  }
  try {
    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 8);
    final req = await client.getUrl(Uri.parse(
        'https://en.wikipedia.org/api/rest_v1/page/summary/${Uri.encodeComponent(title)}'));
    final res = await req.close();
    if (res.statusCode != 200) return null;
    final body = await res.transform(utf8.decoder).join();
    final j = jsonDecode(body) as Map<String, dynamic>;
    final extract = (j['extract'] ?? '').toString();
    if (extract.isEmpty) return null;
    var img = '';
    final thumb = j['thumbnail'];
    if (thumb is Map && thumb['source'] != null) {
      img = thumb['source']
          .toString()
          .replaceFirst(RegExp(r'/(\d+)px-'), '/800px-');
    }
    await prefs.setString(key, jsonEncode({'x': extract, 'img': img}));
    return WikiSummary(extract, img);
  } catch (_) {
    return null;
  }
}
