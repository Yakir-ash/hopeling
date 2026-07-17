// The Nature Library: quotes you kept, reflections you wrote.
// Local, private, yours. Synced only if you ever ask.

import 'dart:convert';

import 'package:flutter/foundation.dart' show ValueNotifier;
import 'package:shared_preferences/shared_preferences.dart';

final libraryTick = ValueNotifier<int>(0);

// ---------- kept quotes ----------
Future<List<Map<String, String>>> savedQuotes() async {
  final p = await SharedPreferences.getInstance();
  final raw = p.getString('quotes');
  if (raw == null) return [];
  try {
    return (jsonDecode(raw) as List)
        .map((e) => (e as Map).map((k, v) => MapEntry(k.toString(), v.toString())))
        .toList();
  } catch (_) {
    return [];
  }
}

Future<void> keepQuote(String text, String source) async {
  final p = await SharedPreferences.getInstance();
  final list = await savedQuotes();
  if (list.any((q) => q['t'] == text)) return;
  list.insert(0, {'t': text, 's': source});
  await p.setString('quotes', jsonEncode(list.take(100).toList()));
  libraryTick.value++;
}

// ---------- reflections (one per journey) ----------
Future<String> reflection(String journeySlug) async {
  final p = await SharedPreferences.getInstance();
  return p.getString('note_$journeySlug') ?? '';
}

Future<void> saveReflection(String journeySlug, String text) async {
  final p = await SharedPreferences.getInstance();
  await p.setString('note_$journeySlug', text);
  libraryTick.value++;
}
