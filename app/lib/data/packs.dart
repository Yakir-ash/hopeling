// World Packs: keep a whole world - portraits, photos, text - on the
// phone forever. Built generically: any world can be packed; the pack is
// just the sum of caches its species would have filled anyway, fetched
// eagerly. No special formats, no migrations, nothing to break.

import 'dart:convert';

import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/clock.dart';
import 'content.dart';
import 'wiki.dart';

Future<bool> hasPack(String slug) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.containsKey('pack_$slug');
}

/// Downloads every species portrait and photo for a world.
/// Reports progress; safe to interrupt (already-fetched pieces persist).
Future<int> downloadWorldPack(World world,
    {void Function(int done, int total)? onProgress}) async {
  var done = 0;
  final total = world.species.length;
  for (final name in world.species) {
    final sum = await wikiSummary(name);
    if (sum != null && sum.img.isNotEmpty) {
      try {
        await DefaultCacheManager().downloadFile(sum.img);
      } catch (_) {}
    }
    done++;
    onProgress?.call(done, total);
  }
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(
      'pack_${world.slug}', jsonEncode({'at': todayStr(), 'n': total}));
  return done;
}
