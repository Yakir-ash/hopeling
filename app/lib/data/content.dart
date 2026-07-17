// The content contract (Contract 2): the same content.json the website
// and PWA read, cached whole for offline. The app never shows an error
// for missing network - it shows yesterday's world instead.

import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart' show ValueNotifier;
import 'package:shared_preferences/shared_preferences.dart';

import '../core/clock.dart';

const contentUrl = 'https://hopeling.app/hopeling-web/content.json';

// ---------- models ----------

class World {
  final String slug, emo, name, iucn, sum, overview, science;
  final List<List<String>> stats; // [label, value]
  final List<List<String>> facts; // [text, src]
  final List<List<String>> threats; // [title, text, src]
  final List<List<String>> doing; // [title, text]
  final List<List<String>> hope; // [title, text]
  final List<String> species;
  final List<String> acts;

  World({
    required this.slug,
    required this.emo,
    required this.name,
    required this.iucn,
    required this.sum,
    required this.overview,
    required this.science,
    required this.stats,
    required this.facts,
    required this.threats,
    required this.doing,
    required this.hope,
    required this.species,
    required this.acts,
  });

  static List<List<String>> _pairs(dynamic v) => ((v as List?) ?? [])
      .map((e) => (e as List).map((x) => x.toString()).toList())
      .toList();

  factory World.fromJson(Map<String, dynamic> j) => World(
        slug: (j['slug'] ?? '').toString(),
        emo: (j['emo'] ?? '🌿').toString(),
        name: (j['name'] ?? '').toString(),
        iucn: (j['iucn'] ?? '').toString(),
        sum: (j['sum'] ?? '').toString(),
        overview: (j['overview'] ?? '').toString(),
        science: (j['science'] ?? '').toString(),
        stats: _pairs(j['stats']),
        facts: _pairs(j['facts']),
        threats: _pairs(j['threats']),
        doing: _pairs(j['doing']),
        hope: _pairs(j['hope']),
        species:
            ((j['species'] as List?) ?? []).map((e) => e.toString()).toList(),
        acts: ((j['acts'] as List?) ?? []).map((e) => e.toString()).toList(),
      );
}

class ActionItem {
  final String slug, t, why;
  final int min;
  ActionItem(this.slug, this.t, this.why, this.min);
}

class AppContent {
  final int version;
  final List<World> worlds;
  final Map<String, ActionItem> actions;
  final List<List<String>> facts; // [text, src, catSlug, simple]
  final bool fromCache;
  AppContent(this.version, this.worlds, this.actions, this.facts, this.fromCache);

  factory AppContent.fromJson(Map<String, dynamic> doc, bool cached) {
    final worlds = ((doc['categories'] as List?) ?? [])
        .map((e) => World.fromJson(e as Map<String, dynamic>))
        .toList();
    final actions = <String, ActionItem>{};
    ((doc['actions'] as Map<String, dynamic>?) ?? {}).forEach((k, v) {
      final a = v as Map<String, dynamic>;
      actions[k] = ActionItem(k, (a['t'] ?? '').toString(),
          (a['why'] ?? '').toString(), (a['min'] is int) ? a['min'] as int : 2);
    });
    final facts = ((doc['facts'] as List?) ?? [])
        .map((e) => (e as List).map((x) => x.toString()).toList())
        .toList();
    return AppContent(
        (doc['version'] is int) ? doc['version'] as int : 0,
        worlds,
        actions,
        facts,
        cached);
  }
}

// ---------- loading: cache-first, instantly; network quietly after ----------
// The world is on your phone the moment the app opens. The network only
// ever makes it fresher, never makes you wait.

/// Bumps whenever fresher content arrives; screens listen and re-read.
final contentTick = ValueNotifier<int>(0);

AppContent? _memo;
bool _refreshing = false;

Future<Map<String, dynamic>?> _fetchDoc(SharedPreferences prefs) async {
  try {
    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 8);
    final req = await client.getUrl(Uri.parse(contentUrl));
    final res = await req.close();
    if (res.statusCode == 200) {
      final body = await res.transform(utf8.decoder).join();
      final doc = jsonDecode(body) as Map<String, dynamic>;
      await prefs.setString('contentCache', body);
      return doc;
    }
  } catch (_) {}
  return null;
}

Future<void> refreshContent() async {
  if (_refreshing) return;
  _refreshing = true;
  try {
    final prefs = await SharedPreferences.getInstance();
    final doc = await _fetchDoc(prefs);
    if (doc != null) {
      _memo = AppContent.fromJson(doc, false);
      contentTick.value++;
    }
  } finally {
    _refreshing = false;
  }
}

Future<AppContent> loadContent() async {
  if (_memo != null) return _memo!;
  final prefs = await SharedPreferences.getInstance();
  final cached = prefs.getString('contentCache');
  if (cached != null) {
    try {
      _memo =
          AppContent.fromJson(jsonDecode(cached) as Map<String, dynamic>, true);
      refreshContent(); // quietly, in the background
      return _memo!;
    } catch (_) {}
  }
  // First ever launch: nothing cached yet, so we do wait for the world once.
  final doc = await _fetchDoc(prefs);
  if (doc != null) {
    _memo = AppContent.fromJson(doc, false);
    return _memo!;
  }
  _memo = AppContent(0, [], {}, [], true);
  return _memo!;
}

// ---------- today's picks ----------

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

DayContent _fallbackDay() => DayContent(
      'Sharks were swimming in the sea before trees existed.',
      'National Geographic',
      'Refuse one single-use plastic today',
      'Most ocean plastic starts as one convenient moment on land.',
      2,
      true,
    );

Future<DayContent> loadDay() async {
  final c = await loadContent();
  if (c.facts.isEmpty || c.actions.isEmpty) return _fallbackDay();
  final f = c.facts[dailyIndex(c.facts.length, 'f')];
  final keys = c.actions.keys.toList();
  final a = c.actions[keys[dailyIndex(keys.length, 'a')]]!;
  return DayContent(f[0], f.length > 1 ? f[1] : '', a.t, a.why, a.min, c.fromCache);
}
