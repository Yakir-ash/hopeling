// Collections: quietly saved, always private. A heart on a species tucks
// it into your pocket for later.

import 'package:flutter/foundation.dart' show ValueNotifier;
import 'package:shared_preferences/shared_preferences.dart';

final savedTick = ValueNotifier<int>(0);

Future<List<String>> savedSpecies() async {
  final p = await SharedPreferences.getInstance();
  return p.getStringList('savedSpecies') ?? [];
}

Future<bool> isSaved(String name) async =>
    (await savedSpecies()).contains(name);

Future<bool> toggleSaved(String name) async {
  final p = await SharedPreferences.getInstance();
  final list = p.getStringList('savedSpecies') ?? [];
  final now = !list.contains(name);
  if (now) {
    list.add(name);
  } else {
    list.remove(name);
  }
  await p.setStringList('savedSpecies', list);
  savedTick.value++;
  return now;
}
