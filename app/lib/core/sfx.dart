// Hopeling's voice, first pass: a small set of synthesized, watery
// sounds (scripts/sfx.py) - a fingertip tick, a dewdrop, a bloom
// pop, a leap of air, a splash, a soft underwater thud, three bells
// up the pentatonic for done, and a leaf-brush flip. Everything
// warm, nothing ever a buzzer.
//
// One switch rules them all: the parent's Sounds toggle ('sfx'
// pref). Narration is separate and unaffected.

import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Sfx {
  static bool enabled = true;
  static final Map<String, AudioPool> _pools = {};
  static bool _ready = false;

  static const names = [
    'tick', 'drop', 'pop', 'whoosh',
    'splash', 'bump', 'chime', 'flip',
  ];

  /// Load the preference and warm the pools. Cheap, call once at
  /// startup; safe to call again.
  static Future<void> init() async {
    final p = await SharedPreferences.getInstance();
    enabled = p.getBool('sfx') ?? true;
    if (_ready) return;
    _ready = true;
    for (final n in names) {
      // real recorded files first (drop an mp3 into assets/sfx/ and
      // it wins), synthesized wav as the fallback
      try {
        _pools[n] = await AudioPool.createFromAsset(
            path: 'sfx/$n.mp3', maxPlayers: 3);
        continue;
      } catch (_) {}
      try {
        _pools[n] = await AudioPool.createFromAsset(
            path: 'sfx/$n.wav', maxPlayers: 3);
      } catch (_) {
        // a missing sound is silence, never a crash
      }
    }
  }

  static Future<void> setEnabled(bool v) async {
    enabled = v;
    final p = await SharedPreferences.getInstance();
    await p.setBool('sfx', v);
  }

  /// Fire and forget. Unknown names and unloaded pools are silence.
  static void play(String name, {double volume = 1.0}) {
    if (!enabled) return;
    _pools[name]?.start(volume: volume).catchError((_) => () {});
  }
}
