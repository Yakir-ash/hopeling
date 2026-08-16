// The Listening Post - SCHOOL.md's third signature. Ear training
// on real recordings: five voices of the neighborhood, a memory
// hook for each, a who-is-singing quiz that is a game of
// meeting (never a test), and the Dawn Sit - the rite that
// graduates the ear outdoors.
//
// The recordings are real people's field work, hosted on
// hopeling.app beside the fable voice, cached after first
// listen. Every recordist is credited by name - that is the
// license's price and their due. The quiz is deterministic by
// day (a book, not a slot machine): the same morning asks the
// same questions.

import 'almanac.dart' show dayOfYear;
import 'package:shared_preferences/shared_preferences.dart';

const birdAudioBase = 'https://hopeling.app/audio/birds';

class BirdVoice {
  final String id;
  final String emoji;
  final String name;
  final String sci;
  final String file; // under birdAudioBase
  final String hook; // how to remember the sound, in words
  final String story; // one warm line about the voice
  final String when; // when to listen for her
  final String recordist;
  final String xc; // xeno-canto number, e.g. XC1138978
  const BirdVoice({
    required this.id,
    required this.emoji,
    required this.name,
    required this.sci,
    required this.file,
    required this.hook,
    required this.story,
    required this.when,
    required this.recordist,
    required this.xc,
  });

  String get url => '$birdAudioBase/$file';
  String get xcUrl =>
      'https://xeno-canto.org/${xc.replaceAll('XC', '')}';
}

/// The North America pack - the flagship market's dawn chorus.
/// (An Israel pack joins when its shelf is stocked.)
const birdVoices = <BirdVoice>[
  BirdVoice(
    id: 'robin',
    emoji: '🐦',
    name: 'American Robin',
    sci: 'Turdus migratorius',
    file: 'na_robin.mp3',
    hook: 'A cheerful carol in short phrases with pauses - like '
        'someone singing "cheerily, cheer-up, cheerio" and '
        'thinking between the lines.',
    story: 'The opening act of the dawn chorus - often the first '
        'voice before light, and one of the last at dusk.',
    when: 'First light, from rooftops and high branches - '
        'earliest singer of the morning.',
    recordist: 'Greg Irving',
    xc: 'XC1138978',
  ),
  BirdVoice(
    id: 'dove',
    emoji: '🕊️',
    name: 'Mourning Dove',
    sci: 'Zenaida macroura',
    file: 'na_dove.mp3',
    hook: 'A soft, low "coo-OO-oo, oo, oo" - so owl-like that '
        'half the neighborhood thinks they have owls.',
    story: 'The sigh of the suburbs. That mournful sound is '
        'mostly a male advertising, gently, forever.',
    when: 'Warm, still parts of the day, from wires and '
        'rooftops - and listen for the whistling wings when '
        'she bursts into flight.',
    recordist: 'Thomas Ryder Payne',
    xc: 'XC636552',
  ),
  BirdVoice(
    id: 'finch',
    emoji: '🎶',
    name: 'House Finch',
    sci: 'Haemorhous mexicanus',
    file: 'na_finch.mp3',
    hook: 'A fast, cheerful jumble that tumbles downhill and '
        'often ends on a buzzy, slurred note - a warble with a '
        'question mark.',
    story: 'The optimist on the wire. A hundred years ago they '
        'lived only in the west; now their song strings the '
        'whole continent.',
    when: 'All day, anywhere people are - wires, gutters, '
        'porch feeders.',
    recordist: 'Alicia Min',
    xc: 'XC1157203',
  ),
  BirdVoice(
    id: 'sparrow',
    emoji: '🪶',
    name: 'Song Sparrow',
    sci: 'Melospiza melodia',
    file: 'na_sparrow.mp3',
    hook: 'Two or three clear opening notes, then a jumbled '
        'trill - old birders hear "maids, maids, maids, put on '
        'your tea-kettle-ettle-ettle."',
    story: 'Every song sparrow sings the family song with his '
        'own arrangement - neighbors can tell each other apart '
        'by ear, and so can you, eventually.',
    when: 'Sunny mornings from a low bush or fence post, '
        'usually near water or damp thickets.',
    recordist: 'Thomas Magarian',
    xc: 'XC540249',
  ),
  BirdVoice(
    id: 'goldfinch',
    emoji: '💛',
    name: 'Lesser Goldfinch',
    sci: 'Spinus psaltria',
    file: 'na_goldfinch.mp3',
    hook: 'Wiry, bouncy, and full of borrowed phrases - a tiny '
        'DJ sampling the other birds, with sweet drawn-out '
        'notes in between.',
    story: 'A mimic in yellow. Much of what he sings is quotes '
        '- listen long enough and you will hear your other '
        'four neighbors inside his song.',
    when: 'Late morning in treetops and weedy patches, often '
        'in small chattering groups.',
    recordist: 'Jarrod Swackhamer',
    xc: 'XC522398',
  ),
];

BirdVoice? birdVoiceById(String id) {
  for (final v in birdVoices) {
    if (v.id == id) return v;
  }
  return null;
}

// ---------- the who-is-singing quiz (deterministic) ----------

class QuizRound {
  final BirdVoice answer;
  final List<BirdVoice> options; // three, answer among them
  const QuizRound(this.answer, this.options);
}

/// Five rounds for the day - every voice appears exactly once as
/// the answer, in an order that rotates with the date, each with
/// two deterministic companions. Same day, same quiz.
List<QuizRound> quizRounds(DateTime t) {
  final n = birdVoices.length;
  final seed = dayOfYear(t) * 5 + t.year;
  final rounds = <QuizRound>[];
  for (var r = 0; r < n; r++) {
    final a = (seed + r * 3) % n;
    final b = (a + 1 + (seed + r) % (n - 1)) % n;
    var c = (a + 1 + (seed + r * 7) % (n - 1)) % n;
    if (c == b) c = (c + 1) % n;
    if (c == a) c = (c + 1) % n;
    // order the three options deterministically but not
    // answer-first: rotate by round
    final opts = [birdVoices[a], birdVoices[b], birdVoices[c]];
    final rot = (seed + r) % 3;
    rounds.add(QuizRound(birdVoices[a],
        [for (var i = 0; i < 3; i++) opts[(i + rot) % 3]]));
  }
  return rounds;
}

// ---------- progress: met and named, never scored ----------

class Listening {
  /// Voices the user has listened to at least once.
  static Future<Set<String>> met() async {
    final p = await SharedPreferences.getInstance();
    return (p.getStringList('voicesMet') ?? []).toSet();
  }

  static Future<void> meet(String id) async {
    final p = await SharedPreferences.getInstance();
    final s = (p.getStringList('voicesMet') ?? []).toSet();
    if (s.add(id)) {
      await p.setStringList('voicesMet', s.toList()..sort());
    }
  }

  /// Voices the user has named correctly at least once, ever -
  /// a met-neighbor state, not a score. It only grows.
  static Future<Set<String>> named() async {
    final p = await SharedPreferences.getInstance();
    return (p.getStringList('voicesNamed') ?? []).toSet();
  }

  static Future<void> name(String id) async {
    final p = await SharedPreferences.getInstance();
    final s = (p.getStringList('voicesNamed') ?? []).toSet();
    if (s.add(id)) {
      await p.setStringList('voicesNamed', s.toList()..sort());
    }
  }

  /// The Dawn Sit opens when every voice has been named - the
  /// ear is ready for the real chorus.
  static Future<bool> dawnSitOpen() async =>
      (await named()).length >= birdVoices.length;
}
