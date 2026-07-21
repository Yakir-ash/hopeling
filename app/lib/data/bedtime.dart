// Bedtime - the forest quietly preparing for sleep. Not a dark theme:
// a nightly ritual. The engine here is pure and device-local: a parent
// -set window (default from 19:00, an honest stand-in for local sunset
// that never asks where you are), a deterministic single story for
// tonight, one gentle question, and a healthy ending. Nothing is
// collected: the reflection is a moment, not a data point.

import 'package:shared_preferences/shared_preferences.dart';

import '../core/clock.dart';

class BedtimePrefs {
  bool auto; // slide into bedtime inside the window
  int startMin; // minutes from midnight, e.g. 19:00 -> 1140
  int endMin; // e.g. 07:00 -> 420 (wraps past midnight)
  int maxMinutes; // the bedtime session is even shorter than the day's
  BedtimePrefs(
      {this.auto = true,
      this.startMin = 19 * 60,
      this.endMin = 7 * 60,
      this.maxMinutes = 10});

  static Future<BedtimePrefs> load() async {
    final p = await SharedPreferences.getInstance();
    return BedtimePrefs(
      auto: p.getBool('bt_auto') ?? true,
      startMin: p.getInt('bt_start') ?? 19 * 60,
      endMin: p.getInt('bt_end') ?? 7 * 60,
      maxMinutes: p.getInt('bt_max') ?? 10,
    );
  }

  Future<void> save() async {
    final p = await SharedPreferences.getInstance();
    await p.setBool('bt_auto', auto);
    await p.setInt('bt_start', startMin);
    await p.setInt('bt_end', endMin);
    await p.setInt('bt_max', maxMinutes);
  }
}

/// Inside the bedtime window? Handles windows that wrap past midnight
/// (19:00 -> 07:00) and ones that do not. Uses the device's own clock -
/// the timezone travels with the child, and no location is ever asked.
bool inBedtimeWindow(DateTime now, BedtimePrefs p) {
  final m = now.hour * 60 + now.minute;
  if (p.startMin == p.endMin) return false;
  if (p.startMin < p.endMin) return m >= p.startMin && m < p.endMin;
  return m >= p.startMin || m < p.endMin;
}

/// One story for tonight - chosen, not browsed. Deterministic by the
/// day (the PWA's dailyIndex hash with a bedtime salt), so "one more
/// story" cannot be renegotiated by reopening the app.
int tonightIndex(int count, [DateTime? now]) {
  if (count <= 0) return 0;
  return dailyIndex(count, 'bed', now);
}

/// One gentle question, rotating daily. Answering is a tap or a word
/// spoken into the room - never typed, never stored, never required.
const reflectionQuestions = [
  'What was your favorite animal today?',
  'What surprised you today?',
  'What would you like to discover tomorrow?',
  'What sound do you think the forest makes at night?',
  'If you could say goodnight to one animal, who would it be?',
];

String reflectionQuestion([DateTime? now]) =>
    reflectionQuestions[dailyIndex(reflectionQuestions.length, 'ref', now)];

/// How a guardian sleeps, told plainly. Biology, not bedtime theater:
/// each line is something the real animal is known to do at night.
String guardianRest(String worldSlug, String name) {
  const rests = {
    'oceans': 'rests near the surface, rising gently to breathe',
    'dolphins': 'sleeps with half its brain awake, gliding slowly',
    'whales': 'hangs quietly in the water, rising to breathe',
    'bees': 'sleeps deep in the hive, wings folded still',
    'birds': 'fluffs its feathers and grips its branch, fast asleep',
    'owls': 'is awake now - the night is when it lives',
    'bats': 'is awake now - listening to the dark with its ears',
    'penguins': 'tucks its beak under a flipper against the cold',
    'elephants': 'dozes standing, and lies down only for deep sleep',
    'foxes': 'curls into a circle, tail wrapped over its nose',
    'wolves': 'curls close to its family in the den',
    'pandas': 'sleeps where it ate, paws full of bamboo dreams',
    'frogs': 'floats with just its eyes above the water',
    'turtles': 'tucks into its shell in the shallows',
    'forests': 'goes quiet as the day shift sleeps and the night shift wakes',
  };
  final r = rests[worldSlug] ?? 'settles into its safe place for the night';
  return 'Your $name $r. Sleep well, both of you.';
}

class BedtimeCopy {
  static const shelf = 'One more story before sleep';
  static const shelfSub = 'the forest picked this one for tonight';
  static const ending =
      'The forest is getting sleepy too. Your next adventure will be '
      'waiting tomorrow.';
  static const reflectionSkip = 'Just sleepy';
  static const reflectionThanks = 'Goodnight, little ranger. 🌙';
  static const arriving = 'The forest is getting ready for sleep...';
}
