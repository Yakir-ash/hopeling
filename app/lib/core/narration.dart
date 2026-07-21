// The recorded Storyteller. If a story was narrated ahead of time by
// scripts/narrate.js (a real neural voice, generated once, shipped as
// static files), children hear that; otherwise the device Storyteller
// reads with its prosody engine. The rule is all-or-nothing per line:
// a sentence the recordings do not cover means the whole line falls
// back to the device voice - never a mid-sentence voice change.
//
// Privacy shape: audio is fetched from hopeling.app like any photo,
// cached on device, and no third-party service is ever contacted from
// a child's session.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'storyteller.dart';

/// Do the recordings cover every sentence of this line?
bool fullyNarrated(List<String> sents, Map<String, dynamic>? files) =>
    files != null &&
    sents.isNotEmpty &&
    sents.every((s) => files.containsKey(s));

class StoryVoice {
  final Storyteller fallback = Storyteller();
  final AudioPlayer _player = AudioPlayer();
  static const _base = 'https://hopeling.app/audio';
  Map<String, dynamic>? _manifest;
  bool _fetchedOnce = false;
  int _gen = 0;

  Future<Map<String, dynamic>?> _loadManifest() async {
    if (_manifest != null) return _manifest;
    final p = await SharedPreferences.getInstance();
    final cached = p.getString('audioManifest');
    if (cached != null) {
      try {
        _manifest = jsonDecode(cached) as Map<String, dynamic>;
      } catch (_) {}
    }
    if (!_fetchedOnce) {
      _fetchedOnce = true;
      try {
        final c = HttpClient()
          ..connectionTimeout = const Duration(seconds: 6);
        final req = await c.getUrl(Uri.parse('$_base/manifest.json'));
        final res = await req.close();
        if (res.statusCode == 200) {
          final t = await res.transform(utf8.decoder).join();
          _manifest = jsonDecode(t) as Map<String, dynamic>;
          await p.setString('audioManifest', t);
        }
      } catch (_) {
        // offline: cached manifest or the device voice carry the night
      }
    }
    return _manifest;
  }

  Future<void> speak(String text,
      {bool bedtime = false, String band = 'ranger'}) async {
    final gen = ++_gen;
    await _player.stop();
    await fallback.stop();
    final sents = storySentences(text)
        .map(speakable)
        .where((s) => s.isNotEmpty)
        .toList();
    final m = await _loadManifest();
    if (gen != _gen) return;
    final files = (m?['sentences'] as Map?)?.cast<String, dynamic>();
    if (!fullyNarrated(sents, files)) {
      await fallback.speak(text, bedtime: bedtime, band: band);
      return;
    }
    try {
      // bedtime slows the recording itself, pitch preserved
      await _player.setSpeed(bedtime ? 0.85 : 1.0);
      for (var i = 0; i < sents.length; i++) {
        if (gen != _gen) return;
        final f = await DefaultCacheManager()
            .getSingleFile('$_base/${files![sents[i]]}');
        if (gen != _gen) return;
        await _player.setFilePath(f.path);
        if (gen != _gen) return;
        await _player.play(); // completes when the sentence ends
        if (gen != _gen) return;
        if (i < sents.length - 1) {
          final pr = sentenceProsody(sents[i], i, sents.length,
              bedtime: bedtime, band: band);
          await Future.delayed(Duration(milliseconds: pr.pauseMs));
        }
      }
    } catch (_) {
      // a missing file mid-story: finish with the device voice
      if (gen == _gen) {
        await fallback.speak(text, bedtime: bedtime, band: band);
      }
    }
  }

  Future<void> stop() async {
    _gen++;
    await _player.stop();
    await fallback.stop();
  }
}
