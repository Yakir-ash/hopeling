// The Errand - the first law of Hopeling School made real:
// NOTHING IS LEARNED UNTIL IT IS SEEN. Every day carries one small
// task that cannot be completed on a phone. The pick is
// deterministic (a book, not a slot machine), tuned to season and
// darkness, and completing it is self-reported the Hopeling way:
// you say you looked, we believe you, the Field Guide grows a page.

import 'almanac.dart' show dayOfYear, season;
import 'fieldguide.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Errand {
  final String id;
  final String emoji;
  final String text; // imperative, gentle, specific
  final String note; // past tense - the line the guide keeps
  final Set<String>? seasons; // null = any season
  final bool? dark; // true = night only, false = day only, null = any
  const Errand(this.id, this.emoji, this.text, this.note,
      {this.seasons, this.dark});
}

const errands = <Errand>[
  // ---- any season, daylight ----
  Errand('leaf-lace', '🍃',
      'Find a leaf something has been eating. Look closely at the '
          'edges - chewed, or turned to lace?',
      'I found the leaf the small ones ate, and saw the lace.',
      dark: false),
  Errand('one-tree', '🌳',
      'Pick the nearest tree and touch its bark. Rough or smooth? '
          'Warm side and cool side?',
      'I met the nearest tree with my hands.',
      dark: false),
  Errand('bird-count', '🐦',
      'Stand still for two minutes and count how many different '
          'bird voices you can hear - names not required.',
      'I stood still and counted the voices.',
      dark: false),
  Errand('cloud-watch', '☁️',
      'Look up. Are the clouds moving? Which way? Watch one until '
          'it changes shape.',
      'I watched a cloud until it became another cloud.'),
  Errand('small-hunt', '🔍',
      'Find something alive that is smaller than your fingernail. '
          'Watch it work for one minute.',
      'I watched a very small life doing its very big work.',
      dark: false),
  Errand('crack-garden', '🌱',
      'Find a plant growing where it should not be able to grow - '
          'a crack, a wall, a gutter.',
      'I found the plant that never asked permission.',
      dark: false),
  Errand('wind-reader', '💨',
      'Find three signs of wind without feeling it: a flag, a '
          'branch, a seed in the air.',
      'I read the wind by what it touched.',
      dark: false),
  Errand('edge-walk', '🚶',
      'Walk to the nearest edge where one habitat meets another - '
          'lawn to hedge, pavement to soil - and look for who lives '
          'exactly on the border.',
      'I walked the border between two small countries.',
      dark: false),
  Errand('sun-shadow', '🕐',
      'Find your shadow. Note where it points. Nature keeps time '
          'without a single clock.',
      'I told the time by my own shadow.',
      dark: false),
  Errand('feather-find', '🪶',
      'Look for a feather on the ground today. If you find one, '
          'leave it - but study the colors before you go.',
      'I looked for a lost feather and studied what I found.',
      dark: false),
  Errand('water-listen', '💧',
      'Find water outdoors - a puddle counts - and look at what '
          'the surface is doing: still, ringed, riding the wind?',
      'I read the face of the water.'),
  Errand('two-greens', '🟢',
      'Find two leaves from different plants and hold them side by '
          'side. Count the differences: shape, edge, shine, vein.',
      'I learned that green is a thousand colors.',
      dark: false),

  // ---- spring, daylight ----
  Errand('spring-song', '🎶',
      'Someone new is singing this month. Step out and listen for '
          'a voice you have not heard all winter.',
      'I heard the voice that came back.',
      seasons: {'spring'}, dark: false),
  Errand('spring-buds', '🌸',
      'Find one branch and look at its buds. Closed, cracking, or '
          'open? Check the same branch again in three days.',
      'I caught a branch in the act of spring.',
      seasons: {'spring'}, dark: false),
  Errand('spring-builders', '🪹',
      'Watch for a bird carrying something that is not food - '
          'grass, twigs, moss. Someone is building.',
      'I saw a builder with a beak full of house.',
      seasons: {'spring'}, dark: false),

  // ---- summer, daylight ----
  Errand('summer-bees', '🐝',
      'Find one flowering plant and watch it for three minutes. '
          'Count the visitors. Who comes? Who stays longest?',
      'I kept the guest book of a single flower.',
      seasons: {'summer'}, dark: false),
  Errand('summer-shade', '🌡️',
      'Stand in full sun, then deep shade under a tree. Feel the '
          'difference trees make - that is their air conditioning.',
      'I felt the cool machine a tree runs all summer.',
      seasons: {'summer'}, dark: false),
  Errand('summer-ants', '🐜',
      'Find an ant trail and follow it - gently, from a height - '
          'to one of its two ends.',
      'I followed the ant road to where it was going.',
      seasons: {'summer'}, dark: false),

  // ---- autumn, daylight ----
  Errand('autumn-one-leaf', '🍂',
      'Catch one falling leaf before it lands. It may take a '
          'while. That is the point.',
      'I caught a leaf between branch and ground.',
      seasons: {'autumn'}, dark: false),
  Errand('autumn-seeds', '🌰',
      'Find three different seeds today: a helicopter, a berry, a '
          'burr - anything built to travel.',
      'I found three travelers dressed for three journeys.',
      seasons: {'autumn'}, dark: false),
  Errand('autumn-fungus', '🍄',
      'After rain, look at the base of old trees and in mulch for '
          'fungus - look, admire, and leave it be.',
      'I found the quiet ones who eat the fallen.',
      seasons: {'autumn'}, dark: false),

  // ---- winter, daylight ----
  Errand('winter-tracks', '🐾',
      'Cold ground tells stories. Look in mud, frost, or snow for '
          'a print that is not a shoe.',
      'I read one sentence of the ground\'s diary.',
      seasons: {'winter'}, dark: false),
  Errand('winter-green', '🌲',
      'Find three plants that are still green in the middle of '
          'winter. They have a trick. Wonder what it is.',
      'I found the ones winter cannot switch off.',
      seasons: {'winter'}, dark: false),
  Errand('winter-birds', '🫘',
      'Watch where the birds are feeding today. Winter makes them '
          'braver and closer - notice how near they let you be.',
      'I stood close to the brave and hungry.',
      seasons: {'winter'}, dark: false),

  // ---- night, any season ----
  Errand('night-moon', '🌙',
      'Step out and find the moon. Which side is lit? That side '
          'points the way to the sun, under the world.',
      'I found the moon and read its compass.',
      dark: true),
  Errand('night-listen', '👂',
      'Stand outside for two minutes in the dark and count the '
          'sounds that are not human. The night shift is working.',
      'I listened to the night shift at work.',
      dark: true),
  Errand('night-light', '💡',
      'Find an outdoor light and see who came to it - moths, '
          'gnats, a hunting spider at the edge of the glow.',
      'I visited the little town around a lamp.',
      dark: true),
  Errand('night-star', '⭐',
      'Find the brightest point of light in the sky tonight. Is '
          'it steady or twinkling? Steady may be a planet.',
      'I found the brightest light and asked its name.',
      dark: true),
  Errand('night-window', '🏠',
      'Look at your window from outside reach: who is on the '
          'glass tonight, drawn to the warmth of your rooms?',
      'I met the neighbors on my own window.',
      dark: true),
];

/// Deterministic errand for a date and darkness. Same day, same
/// errand - a book, not a slot machine.
Errand errandOfDay(DateTime t, {required bool dark}) {
  final s = season(t);
  final pool = errands
      .where((e) =>
          (e.seasons == null || e.seasons!.contains(s)) &&
          (e.dark == null || e.dark == dark))
      .toList();
  return pool[(dayOfYear(t) * 13 + t.year) % pool.length];
}

Errand? errandById(String id) {
  for (final e in errands) {
    if (e.id == id) return e;
  }
  return null;
}

// ---------- walking an errand ----------

int _daysSinceEpoch(DateTime t) =>
    DateTime.utc(t.year, t.month, t.day)
        .difference(DateTime.utc(2020, 1, 1))
        .inDays;

/// Field-note chapter ids for errands carry the day, because the
/// same errand can honestly be walked in different weeks.
String errandNoteId(Errand e, DateTime t) =>
    'err:${e.id}:${_daysSinceEpoch(t)}';

class Errands {
  /// Was today's errand already walked?
  static Future<bool> walkedToday() async {
    final p = await SharedPreferences.getInstance();
    return p.getInt('errandDoneDay') ==
        _daysSinceEpoch(DateTime.now());
  }

  /// Walk it: one field note, one quiet day-mark. Believing the
  /// tap is the design.
  static Future<void> walk(Errand e) async {
    final now = DateTime.now();
    await FieldGuide.earn('errand', errandNoteId(e, now));
    final p = await SharedPreferences.getInstance();
    await p.setInt('errandDoneDay', _daysSinceEpoch(now));
  }
}
