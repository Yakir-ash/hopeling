// This-not-that - everyday decisions, ingredients first.
//
// The knowledge is infrastructure, not copy. ONE file is the source
// of truth: assets/knowledge/swaps.json. The app reads it here; the
// site builder (scripts/build-site.mjs) reads the same file and
// publishes /swaps/<id>/ for people and /swaps.json for machines.
// Nothing below is generated. Everything carries a reviewed date.
//
// Laws of the card (V2-AUDIT.md section 5):
//   - ingredients first, never brands first
//   - no ranking exists, so revenue cannot corrupt one: the pick is
//     a trait; the link slot stays empty until a person verifies it
//   - the decision is the act: "this one, from now on" is a drop,
//     witnessed, never a purchase tracked
//   - every card names its neighbour (a species), the experiment
//     where her thread runs (the Lab), and the action it feeds
//   - adults only; no child ever sees a product

import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';

import 'rules.dart' as rules;
import 'save.dart';

class SwapAvoid {
  final String ingredient;
  final List<String> aka; // how it hides on a label
  final String why;
  const SwapAvoid(this.ingredient, this.aka, this.why);
}

class SwapPrefer {
  final String trait;
  final String why;
  const SwapPrefer(this.trait, this.why);
}

class SwapPick {
  final String label; // a trait, never a brand
  final String note;
  final String? link; // empty until a person verifies a product
  final String? linkChecked;
  const SwapPick(this.label, this.note, this.link, this.linkChecked);
}

class SwapNearby {
  final String label;
  final String why;
  const SwapNearby(this.label, this.why);
}

class SwapConsequence {
  final String line; // one sentence, the neighbour in it
  final String species; // almanac species id
  final String lab; // Lab scenario id
  final List<String> chain; // the path, in plain words
  const SwapConsequence(this.line, this.species, this.lab, this.chain);
}

class SwapSource {
  final String title;
  final String org;
  final String url;
  final String what; // the exact claim this source carries
  const SwapSource(this.title, this.org, this.url, this.what);
}

class Swap {
  final String id;
  final String emoji;
  final String title;
  final String question;
  final List<SwapAvoid> avoid;
  final List<SwapPrefer> prefer;
  final SwapPick pick;
  final SwapNearby nearby;
  final SwapConsequence consequence;
  final List<String> feeds; // action slugs this decision strengthens
  final List<SwapSource> sources;
  final String reviewed;
  final String reviewer;
  final int drops;
  const Swap({
    required this.id,
    required this.emoji,
    required this.title,
    required this.question,
    required this.avoid,
    required this.prefer,
    required this.pick,
    required this.nearby,
    required this.consequence,
    required this.feeds,
    required this.sources,
    required this.reviewed,
    required this.reviewer,
    required this.drops,
  });

  /// The eight-second surface: the one thing to avoid.
  SwapAvoid get firstAvoid => avoid.first;

  /// The eight-second surface: the one thing to prefer.
  SwapPrefer get firstPrefer => prefer.first;

  static Swap fromJson(Map<String, dynamic> j) {
    List<String> strs(dynamic v) =>
        [for (final e in (v as List? ?? const [])) e.toString()];
    final pick = j['pick'] as Map<String, dynamic>? ?? const {};
    final near = j['nearby'] as Map<String, dynamic>? ?? const {};
    final con = j['consequence'] as Map<String, dynamic>? ?? const {};
    return Swap(
      id: j['id'].toString(),
      emoji: (j['emoji'] ?? '').toString(),
      title: (j['title'] ?? '').toString(),
      question: (j['question'] ?? '').toString(),
      avoid: [
        for (final a in (j['avoid'] as List? ?? const []))
          SwapAvoid((a['ingredient'] ?? '').toString(), strs(a['aka']),
              (a['why'] ?? '').toString())
      ],
      prefer: [
        for (final p in (j['prefer'] as List? ?? const []))
          SwapPrefer(
              (p['trait'] ?? '').toString(), (p['why'] ?? '').toString())
      ],
      pick: SwapPick(
          (pick['label'] ?? '').toString(),
          (pick['note'] ?? '').toString(),
          pick['link']?.toString(),
          pick['linkChecked']?.toString()),
      nearby: SwapNearby(
          (near['label'] ?? '').toString(), (near['why'] ?? '').toString()),
      consequence: SwapConsequence(
          (con['line'] ?? '').toString(),
          (con['species'] ?? '').toString(),
          (con['lab'] ?? '').toString(),
          strs(con['chain'])),
      feeds: strs(j['feeds']),
      sources: [
        for (final s in (j['sources'] as List? ?? const []))
          SwapSource(
              (s['title'] ?? '').toString(),
              (s['org'] ?? '').toString(),
              (s['url'] ?? '').toString(),
              (s['what'] ?? '').toString())
      ],
      reviewed: (j['reviewed'] ?? '').toString(),
      reviewer: (j['reviewer'] ?? '').toString(),
      drops: (j['drops'] is int) ? j['drops'] as int : 1,
    );
  }
}

class SwapBook {
  final int v;
  final String reviewed;
  final String license;
  final String audience;
  final List<Swap> swaps;
  const SwapBook(
      this.v, this.reviewed, this.license, this.audience, this.swaps);

  Swap? byId(String id) {
    for (final s in swaps) {
      if (s.id == id) return s;
    }
    return null;
  }

  /// The card whose neighbour is this species, if one exists.
  Swap? forSpecies(String speciesId) {
    for (final s in swaps) {
      if (s.consequence.species == speciesId) return s;
    }
    return null;
  }

  /// The card whose thread runs through this experiment, if any.
  Swap? forLab(String labId) {
    for (final s in swaps) {
      if (s.consequence.lab == labId) return s;
    }
    return null;
  }
}

/// Pure and testable: the same parser the app uses.
SwapBook parseSwaps(String source) {
  final j = jsonDecode(source) as Map<String, dynamic>;
  return SwapBook(
    (j['v'] is int) ? j['v'] as int : 1,
    (j['reviewed'] ?? '').toString(),
    (j['license'] ?? '').toString(),
    (j['audience'] ?? 'adults').toString(),
    [
      for (final s in (j['swaps'] as List? ?? const []))
        Swap.fromJson(s as Map<String, dynamic>)
    ],
  );
}

SwapBook? _cache;

/// The book, from the bundled asset, once.
Future<SwapBook> loadSwaps() async {
  if (_cache != null) return _cache!;
  final raw = await rootBundle.loadString('assets/knowledge/swaps.json');
  return _cache = parseSwaps(raw);
}

/// The decisions a person has made: swap id -> the day. Local only,
/// like every quiet thing. Never a purchase; a decision.
class Swaps {
  static const _key = 'swapDecided';

  static Future<Map<String, String>> decided() async {
    final p = await SharedPreferences.getInstance();
    try {
      final raw = p.getString(_key);
      if (raw == null) return {};
      return (jsonDecode(raw) as Map)
          .map((k, v) => MapEntry(k.toString(), v.toString()));
    } catch (_) {
      return {};
    }
  }

  static Future<void> markDecided(String id, String day) async {
    final p = await SharedPreferences.getInstance();
    final m = await decided()
      ..[id] = day;
    await p.setString(_key, jsonEncode(m));
  }
}

/// The decision IS the act: the same completion path every action
/// takes (a drop, the rhythm, a ring if one forms), plus a note in
/// the save so it travels with the grove. Pure bookkeeping; the
/// caller persists, pulses, and lets it rain.
rules.CompleteOutcome recordSwapDecision(Save s, Swap sw, String today) {
  final out = rules.complete(s, today);
  final done = (s.extra['swaps'] as Map?)
          ?.map((k, v) => MapEntry(k.toString(), v)) ??
      <String, dynamic>{};
  done[sw.id] = today;
  s.extra['swaps'] = done;
  return out;
}
