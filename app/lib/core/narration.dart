// The recorded Storyteller. If a story was narrated ahead of time by
// scripts/narrate.js (the fable voice, generated once, shipped as
// static files), children hear that; anything the recordings do not
// cover simply stays silent - the robotic device voice never speaks.
// Fable or silence, by Yakir's decree. New lines earn a voice by being
// added to narrate.js and regenerated (cents at a time).
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

/// One voice for the whole app - the adult Atlas and the kids'
/// rooms share it, so two pages never talk over each other.
final storyVoice = StoryVoice();

class StoryVoice {
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
    final sents = storySentences(text)
        .map(speakable)
        .where((s) => s.isNotEmpty)
        .toList();
    var m = await _loadManifest();
    if (gen != _gen) return;
    var files = (m?['sentences'] as Map?)?.cast<String, dynamic>();
    if (!fullyNarrated(sents, files)) {
      // self-heal: our cached manifest may predate newly recorded
      // lines - fetch a fresh one once and try again
      _manifest = null;
      _fetchedOnce = false;
      m = await _loadManifest();
      if (gen != _gen) return;
      files = (m?['sentences'] as Map?)?.cast<String, dynamic>();
      if (!fullyNarrated(sents, files)) {
        return; // fable or silence - the robotic voice never speaks
      }
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
      // a missing file mid-story: the rest of the line rests in silence
    }
  }

  Future<void> stop() async {
    _gen++;
    await _player.stop();
  }
}
