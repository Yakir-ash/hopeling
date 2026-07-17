// The content contract (Contract 2): the same content.json the website
// and PWA read, cached whole for offline. The app never shows an error
// for missing network - it shows yesterday's world instead.

import 'dart:convert';
import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart';

import '../core/clock.dart';

const contentUrl = 'https://hopeling.app/hopeling-web/content.json';

class DayContent {
  final String factText;
  final String factSrc;
  final String actTitle;
  final String actWhy;
  final int actMin;
  final bool fromCache;
  DayContent(this.factText, this.factSrc, this.actTitle, this.actWhy,
      this.actMin, this.fromCache);
}

DayContent _fallback() => DayContent(
      'Sharks were swimming in the sea before trees existed.',
      'National Geographic',
      'Refuse one single-use plastic today',
      'Most ocean plastic starts as one convenient moment on land.',
      2,
      true,
    );

DayContent _pick(Map<String, dynamic> doc, bool cached) {
  final facts = (doc['facts'] as List?) ?? [];
  var factText = '', factSrc = '';
  if (facts.isNotEmpty) {
    final f = facts[dailyIndex(facts.length, 'f')] as List;
    factText = f[0].toString();
    factSrc = f[1].toString();
  }
  final actions = (doc['actions'] as Map<String, dynamic>?) ?? {};
  var actTitle = '', actWhy = '';
  var actMin = 2;
  if (actions.isNotEmpty) {
    final keys = actions.keys.toList();
    final a = actions[keys[dailyIndex(keys.length, 'a')]] as Map<String, dynamic>;
    actTitle = (a['t'] ?? '').toString();
    actWhy = (a['why'] ?? '').toString();
    actMin = (a['min'] is int) ? a['min'] as int : 2;
  }
  if (factText.isEmpty || actTitle.isEmpty) return _fallback();
  return DayContent(factText, factSrc, actTitle, actWhy, actMin, cached);
}

Future<DayContent> loadDay() async {
  final prefs = await SharedPreferences.getInstance();
  try {
    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 8);
    final req = await client.getUrl(Uri.parse(contentUrl));
    final res = await req.close();
    if (res.statusCode == 200) {
      final body = await res.transform(utf8.decoder).join();
      final doc = jsonDecode(body) as Map<String, dynamic>;
      await prefs.setString('contentCache', body);
      return _pick(doc, false);
    }
  } catch (_) {}
  // Offline: yesterday's world, gracefully.
  final cached = prefs.getString('contentCache');
  if (cached != null) {
    try {
      return _pick(jsonDecode(cached) as Map<String, dynamic>, true);
    } catch (_) {}
  }
  return _fallback();
}
