// Nature Mysteries - the week tells a whodunit. One mystery per
// week, one clue per day (Monday through Friday); guess whenever
// you like, and the reveal teaches the observation skill that
// solves it. A mystery waits forever and never expires: coming
// back is anticipation, never anxiety, and a wrong guess is just
// a shorter path to a good story.

class Mystery {
  final String id;
  final String emoji;
  final String title;
  final String scene; // the setup, told Monday morning
  final List<String> clues; // five, one per weekday
  final List<String> suspects; // three, one true
  final int answer; // index into suspects
  final String reveal; // the story of what really happened
  final String lesson; // the skill this mystery taught
  final String? speciesId; // a door into the Living Atlas
  const Mystery({
    required this.id,
    required this.emoji,
    required this.title,
    required this.scene,
    required this.clues,
    required this.suspects,
    required this.answer,
    required this.reveal,
    required this.lesson,
    this.speciesId,
  });
}

/// ISO-ish week number, stable across the year for scheduling.
/// Date-only arithmetic in UTC, so a daylight-saving change can
/// never make a 23-hour day shift the week mid-week.
int weekOfYear(DateTime t) {
  final start = DateTime(t.year, 1, 1);
  final days = DateTime.utc(t.year, t.month, t.day)
      .difference(DateTime.utc(t.year, 1, 1))
      .inDays;
  return (days + start.weekday - 1) ~/ 7;
}

/// This week's mystery - deterministic, rotating through the shelf.
Mystery mysteryOfWeek(DateTime t) =>
    mysteries[(weekOfYear(t) + t.year) % mysteries.length];

/// How many clues are on the table today: Monday brings the first,
/// Friday the fifth, and the weekend lays out the whole hand.
int cluesOpen(DateTime t) => t.weekday.clamp(1, 5);

const mysteries = [
  Mystery(
    id: 'anvil',
    emoji: '🐌',
    title: 'The Case of the Broken Shells',
    scene: 'By the garden path lies a flat stone, and around it - '
        'a scatter of snail shells, every one of them broken. No '
        'other stone in the garden has a single shell near it. '
        'Something chose this exact spot.',
    clues: [
      'The shells are all around ONE flat stone - a workshop, not '
          'an accident.',
      'Each shell is cracked open the same way, and the insides '
          'are gone. Someone was eating.',
      'A neighbor says she hears a quick tap-tap-tap from the '
          'garden early in the morning.',
      'There are no tooth marks on the shells - whoever did this '
          'has no teeth.',
      'A speckle-chested bird has been seen standing on that very '
          'stone, head down, busy.',
    ],
    suspects: [
      'A hedgehog, crunching snails at night',
      'A song thrush, using the stone as a tool',
      'A squirrel, hiding shells like nuts'
    ],
    answer: 1,
    reveal: 'The stone is an anvil, and the worker is a song '
        'thrush. Thrushes are one of the few birds with a tool '
        'habit: a snail is held in the beak and whacked - tap-tap- '
        'tap - against a favorite stone until the shell gives. The '
        'same anvil is used for weeks, which is why one stone '
        'wears all the shells. A hedgehog would have left tooth '
        'marks; a squirrel would have carried them away.',
    lesson: 'One spot, many remains means a workshop - find the '
        'worker by asking what tools they have (and teeth count '
        'as tools).',
  ),
  Mystery(
    id: 'lawn',
    emoji: '🕳️',
    title: 'The Midnight Digger',
    scene: 'Morning, and the lawn is dotted with small shallow '
        'holes - cone-shaped scoops, each just a few centimeters '
        'wide, with the moss flipped over beside them. Last night '
        'the lawn was perfect.',
    clues: [
      'The holes are shallow cones, scooped, not tunnels going '
          'down.',
      'No hills of earth anywhere - whoever dug was not coming '
          'from below.',
      'The flipped moss lies NEXT to each hole, turned over '
          'almost gently.',
      'A dropping near the fence: dark, glossy, packed with '
          'shiny beetle cases.',
      'Late that night, a slow snuffling sound crosses the lawn, '
          'like a tiny busy vacuum cleaner.',
    ],
    suspects: [
      'A mole, tunneling up from below',
      'A crow, stabbing for worms at dawn',
      'A hedgehog, sniffing out grubs by night'
    ],
    answer: 2,
    reveal: 'The digger is a hedgehog on its nightly round. The '
        'cone scoops are nose-work: a hedgehog smells a grub '
        'through the turf, then snout-and-claws it out - shallow, '
        'from above, moss flipped aside. A mole works from below '
        'and raises hills; a crow stabs neat narrow holes in '
        'daylight. The beetle-filled dropping and the vacuum- '
        'cleaner snuffle close the case.',
    lesson: 'Read a hole by asking which direction the digger '
        'came from - above, below, or the side tells you almost '
        'everything.',
    speciesId: 'hedgehog',
  ),
  Mystery(
    id: 'hazel',
    emoji: '🌰',
    title: 'The Nibbled Hazelnuts',
    scene: 'Under the hazel at the park\'s edge, a little heap of '
        'empty nutshells. But they are not all opened the same '
        'way - and the way a nut is opened is a signature.',
    clues: [
      'Most shells are split cleanly into two neat halves, like '
          'tiny opened boats.',
      'A few others instead have a round hole gnawed in the '
          'side, edged with tooth marks.',
      'The neat-halved shells lie under the tree; the holed ones '
          'are tucked near the roots and the wall.',
      'Splitting a hazelnut in half takes serious leverage - '
          'strong jaws, worked from the point of the nut.',
      'The holed shells\' tooth marks run across the rim of the '
          'hole, made by something small working patiently.',
    ],
    suspects: [
      'One animal opened them all',
      'Squirrels split the halves; mice gnawed the holes',
      'Birds hammered them all open'
    ],
    answer: 1,
    reveal: 'Two workers, two signatures. A squirrel\'s jaws can '
        'wedge a hazelnut apart at the point, leaving two clean '
        'halves. A wood mouse cannot - so it gnaws patiently '
        'through the side, leaving a round window rimmed with '
        'tooth marks, usually somewhere sheltered. One nut heap, '
        'two species, no witnesses needed: the shells confessed.',
    lesson: 'Feeding signs are signatures - HOW something was '
        'opened names who opened it.',
    speciesId: 'oak',
  ),
  Mystery(
    id: 'feather',
    emoji: '🪶',
    title: 'The Feather on the Doorstep',
    scene: 'A single large feather lies on the doorstep - banded, '
        'beautiful, and suspiciously perfect. Was there a drama '
        'here last night? The feather itself will testify.',
    clues: [
      'The feather is complete: the shaft ends in a clean, '
          'rounded tip, not a break.',
      'No other feathers nearby - dramas usually leave a scatter, '
          'not a single souvenir.',
      'The vanes are crisp but the colors slightly faded, like a '
          'shirt worn all season.',
      'It is late summer - and the garden\'s birds have been '
          'looking strangely scruffy lately.',
      'A plucked feather ends differently: pulled shafts come '
          'out with a stretched, damaged base, and predators '
          'leave feathers in heaps.',
    ],
    suspects: [
      'A cat caught a bird here',
      'A hawk struck in the night',
      'Nobody - the bird is fine, and simply molting'
    ],
    answer: 2,
    reveal: 'No crime at all. The clean-rooted, season-faded, '
        'SOLITARY feather is a molted one: every year, mostly in '
        'late summer, birds replace their worn feathers one by '
        'one and simply drop the old ones where they fall. A cat '
        'or hawk leaves a heap of bent, broken, plucked feathers. '
        'One perfect feather on a doorstep is not evidence of an '
        'ending - it is a receipt for a new coat.',
    lesson: 'Before assuming a drama, check whether the evidence '
        'is damage or just change - nature replaces itself '
        'constantly, and most single feathers are receipts, not '
        'remains.',
    speciesId: 'swallow',
  ),
];
