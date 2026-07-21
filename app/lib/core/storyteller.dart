// The Storyteller - narration that reads like a grown-up reading to a
// child, not a screen reader reading a form. Two ingredients:
//
// 1. Delivery. Text is spoken one sentence at a time, with a breath
//    between sentences, a lift at questions, a small brightness at
//    exclamations, a slower settling-in on the first line and a soft
//    landing on the last. The shaping is deterministic (seeded by the
//    sentence itself), so the same story is always read the same way -
//    a familiar bedtime voice, not a slot machine.
//
// 2. The voice itself. Device engines ship many voices; the local
//    default is usually the most robotic. We prefer the most natural
//    installed English voice (network/neural variants when present)
//    and let parents choose and preview a different one.
//
// All of it degrades gracefully: engines that ignore pitch or rate
// still get the sentence pacing, which alone removes most of the
// monotone.

import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ---------- pure prosody (tested) ----------

class Prosody {
  final double rate, pitch;
  final int pauseMs; // breath after the sentence
  const Prosody(this.rate, this.pitch, this.pauseMs);
}

int _hash(String s) {
  var h = 0;
  for (final c in s.codeUnits) {
    h = (h * 31 + c) & 0x7fffffff;
  }
  return h;
}

/// How sentence [i] of [n] should be spoken. Warm, a little musical,
/// never theatrical.
Prosody sentenceProsody(String s, int i, int n,
    {bool bedtime = false, String band = 'ranger'}) {
  var rate = bedtime ? 0.36 : 0.44;
  var pitch = bedtime ? 0.96 : 1.06; // storybook warmth sits slightly high
  if (band == 'early') rate -= 0.03; // youngest listeners get more room
  final t = s.trim();
  if (t.endsWith('?')) {
    pitch += 0.12; // the wondering lift
  } else if (t.endsWith('!')) {
    pitch += 0.07;
    rate += 0.02;
  }
  // a tiny deterministic wobble so no two sentences are identical twins
  pitch += (_hash(t) % 5 - 2) * 0.012;
  if (i == 0) rate -= 0.02; // settle into the story
  if (n > 1 && i == n - 1) {
    rate -= 0.03; // land softly
    pitch -= bedtime ? 0.05 : 0.02;
  }
  var pause = bedtime ? 850 : 450;
  if (t.endsWith('?') || t.endsWith('!')) pause += 150;
  if (n > 1 && i == n - 1) pause += 200;
  return Prosody(
    rate.clamp(0.28, 0.55),
    pitch.clamp(0.85, 1.25),
    pause,
  );
}

List<String> storySentences(String text) => text
    .split(RegExp(r'(?<=[.!?])\s+'))
    .map((s) => s.trim())
    .where((s) => s.isNotEmpty)
    .toList();

/// What the voice actually says: words, not pictures. Engines narrate
/// emoji by name ("The end glowing star"), which breaks the spell -
/// so everything outside letters, digits and honest punctuation stays
/// on the page and off the tongue.
String speakable(String text) => text
    .replaceAll(RegExp(r"[^\p{L}\p{N}\s.,!?;:'\x22()-]", unicode: true), ' ')
    .replaceAll(RegExp(r'\s+'), ' ')
    .trim();

/// Rank an engine voice for storytelling. English first, then the
/// engine's most natural family: network and neural variants beat the
/// robotic local defaults.
int voiceScore(Map voice) {
  final name = (voice['name'] ?? '').toString().toLowerCase();
  final locale = (voice['locale'] ?? '').toString().toLowerCase();
  var score = 0;
  if (locale.startsWith('en')) score += 100;
  if (locale.startsWith('en-us') || locale.startsWith('en-gb')) score += 10;
  for (final good in ['network', 'neural', 'natural', 'wavenet']) {
    if (name.contains(good)) score += 50;
  }
  if (name.contains('local')) score -= 10;
  return score;
}

// ---------- the storyteller ----------

class Storyteller {
  final FlutterTts tts = FlutterTts();
  int _gen = 0; // a new story or a stop cancels the old read-through
  bool _ready = false;

  Future<void> _init() async {
    if (_ready) return;
    _ready = true;
    await tts.awaitSpeakCompletion(true);
    // Many devices default to a more robotic engine than the Google
    // one they also carry. Prefer Google's when installed.
    try {
      final engines = await tts.getEngines;
      if ((engines as List).contains('com.google.android.tts')) {
        await tts.setEngine('com.google.android.tts');
      }
    } catch (_) {}
    await applySavedVoice();
  }

  /// The parent's chosen voice, or the most natural installed one.
  Future<void> applySavedVoice() async {
    try {
      final p = await SharedPreferences.getInstance();
      final name = p.getString('kidVoiceName');
      final locale = p.getString('kidVoiceLocale');
      if (name != null && locale != null) {
        await tts.setVoice({'name': name, 'locale': locale});
        return;
      }
      final best = await bestVoices(limit: 1);
      if (best.isNotEmpty) {
        await tts.setVoice({
          'name': best.first['name'].toString(),
          'locale': best.first['locale'].toString(),
        });
      }
    } catch (_) {
      // an engine with no voice list still speaks - just less warmly
    }
  }

  /// The top natural English voices installed on this device.
  Future<List<Map>> bestVoices({int limit = 4}) async {
    try {
      final raw = await tts.getVoices;
      final voices = (raw as List).whereType<Map>().toList()
        ..sort((a, b) => voiceScore(b).compareTo(voiceScore(a)));
      final seen = <String>{};
      final out = <Map>[];
      for (final v in voices) {
        if (voiceScore(v) < 100) continue; // English only
        final key = v['name'].toString();
        if (seen.add(key)) out.add(v);
        if (out.length >= limit) break;
      }
      return out;
    } catch (_) {
      return [];
    }
  }

  Future<void> saveVoice(Map v) async {
    final p = await SharedPreferences.getInstance();
    await p.setString('kidVoiceName', v['name'].toString());
    await p.setString('kidVoiceLocale', v['locale'].toString());
    await tts.setVoice({
      'name': v['name'].toString(),
      'locale': v['locale'].toString(),
    });
  }

  /// Read [text] like a story: sentence by sentence, with breath.
  Future<void> speak(String text,
      {bool bedtime = false, String band = 'ranger'}) async {
    await _init();
    final gen = ++_gen;
    await tts.stop();
    final sents =
        storySentences(text).map(speakable).where((s) => s.isNotEmpty).toList();
    for (var i = 0; i < sents.length; i++) {
      if (gen != _gen) return; // a page turned, a door closed
      final p = sentenceProsody(sents[i], i, sents.length,
          bedtime: bedtime, band: band);
      await tts.setSpeechRate(p.rate);
      await tts.setPitch(p.pitch);
      if (gen != _gen) return;
      await tts.speak(sents[i]);
      if (gen != _gen) return;
      if (i < sents.length - 1) {
        await Future.delayed(Duration(milliseconds: p.pauseMs));
      }
    }
  }

  /// A short line for previewing a voice in the parent room.
  Future<void> sample() => speak(
      'Once upon a time, a little seed found the sun. '
      'Do you know what happened next? It grew!');

  Future<void> stop() {
    _gen++;
    return tts.stop();
  }
}
