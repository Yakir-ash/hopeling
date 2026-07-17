// User preferences: quiet, persistent, loaded before the first frame.
// (Local-only; deliberately NOT part of the cloud save - device choices
// belong to devices, per Contract 1's rule for `theme`.)

import 'package:shared_preferences/shared_preferences.dart';

class Settings {
  static final Settings instance = Settings._();
  Settings._();

  bool reduceMotion = false;
  bool lowPower = false;
  bool haptics = true;

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    reduceMotion = p.getBool('pref_reduceMotion') ?? false;
    lowPower = p.getBool('pref_lowPower') ?? false;
    haptics = p.getBool('pref_haptics') ?? true;
  }

  Future<void> set(String key, bool value) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool('pref_$key', value);
    if (key == 'reduceMotion') reduceMotion = value;
    if (key == 'lowPower') lowPower = value;
    if (key == 'haptics') haptics = value;
  }
}
