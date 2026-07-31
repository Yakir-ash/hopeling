// The Almanac - Hopeling's knowledge of the living year. V2's heart.
//
// Three ideas live here, all pure and testable:
//   Wonder      - the daily question that makes you look outside;
//                 its answer arrives tomorrow morning
//   AtlasSpecies - a Living Atlas page: what this species is doing
//                 RIGHT NOW (per season, day and night), how to
//                 actually look for it, and one true wonder
//   happeningNow - today's one seasonal line for the home page
//
// Everything is keyed to the real calendar, because content keyed
// to time renews itself: the same page is new again in October.
// This starter pack is baked in (offline-first); the bot pipeline
// extends it through content.json in later slices.

// ---------- the living calendar ----------

/// The season, northern-hemisphere meteorological: it matches what
/// people see out the window better than equinox dates do.
String season(DateTime t) => switch (t.month) {
      3 || 4 || 5 => 'spring',
      6 || 7 || 8 => 'summer',
      9 || 10 || 11 => 'autumn',
      _ => 'winter',
    };

/// Day of year via date-only UTC arithmetic - immune to the
/// 23-hour and 25-hour days that daylight saving creates.
int dayOfYear(DateTime t) =>
    DateTime.utc(t.year, t.month, t.day)
        .difference(DateTime.utc(t.year, 1, 1))
        .inDays +
    1;

// ---------- the Daily Wonder ----------

class Wonder {
  final String q; // the question, asked in the morning
  final String notice; // what to actually do outside, today, free
  final String a; // the answer, revealed tomorrow morning
  final int? month; // preferred month (1..12), or null = any time
  const Wonder(this.q, this.notice, this.a, {this.month});
}

/// Today's wonder: deterministic all day, prefers wonders written
/// for this month, never repeats yesterday's.
Wonder wonderOfDay(DateTime t, [List<Wonder>? pool]) {
  final all = pool ?? wonders;
  final monthly =
      all.where((w) => w.month == t.month).toList(growable: false);
  final general =
      all.where((w) => w.month == null).toList(growable: false);
  // monthly wonders lead on the first days they apply; the general
  // pool carries the rest of the month
  final deck = [...monthly, ...general];
  if (deck.isEmpty) return const Wonder('', '', '');
  return deck[(dayOfYear(t) * 7 + t.year) % deck.length];
}

/// Yesterday's wonder - its answer is this morning's small gift.
Wonder wonderOfYesterday(DateTime t, [List<Wonder>? pool]) =>
    wonderOfDay(t.subtract(const Duration(days: 1)), pool);

const wonders = [
  // any-time wonders: questions the world can answer all year
  Wonder(
      'Why do birds go quiet in the middle of the day?',
      'Listen for one minute at noon, then again an hour before sunset.',
      'Singing costs energy and midday is for feeding. Dawn and dusk '
      'are the concert hours: the air is calm, sound carries farther, '
      'and territories need announcing.'),
  Wonder(
      'Where do all the city pigeons sleep?',
      'Look at building ledges and under bridges just after sunset.',
      'Ledges, bridges, and roof corners - anywhere that mimics the '
      'cliff faces their wild ancestors, rock doves, still nest on. '
      'A city is a canyon to a pigeon.'),
  Wonder(
      'Why do moths circle lamps?',
      'Watch one lamp for five minutes after dark.',
      'Moths navigate by keeping a distant light - the moon - at a '
      'steady angle. A nearby lamp breaks the trick: keeping IT at a '
      'steady angle pulls them into a spiral.'),
  Wonder(
      'What is the busiest flower within one minute of your door?',
      'Find a flowering plant and give it two quiet minutes.',
      'Almost any open flower feeds more than bees: hoverflies '
      'disguised as wasps, beetles, ants taking shortcuts. A single '
      'flower patch is a small airport.'),
  Wonder(
      'Why do spider webs appear overnight?',
      'Check a corner, fence, or bush early tomorrow morning.',
      'Many orb-weavers build fresh each night and often eat '
      'yesterday\'s web first - silk is protein, too expensive to '
      'waste. You walk past a rebuilt city every morning.'),
  Wonder(
      'Do trees have a smell?',
      'Smell the bark of two different trees - really put your nose '
      'on them.',
      'Yes, and each species has its own: pines breathe resin, '
      'poplars smell of balsam. After rain the whole forest exhales '
      'petrichor and green leaf scents.'),
  Wonder(
      'Why are puddle edges muddy with tiny footprints?',
      'Find a puddle and study its muddy rim like a detective.',
      'A puddle is a village well. Birds bathe and drink at the '
      'shallow edge, and the mud takes attendance: look for the '
      'three-toed arrows of songbirds.'),
  Wonder(
      'What is the oldest living thing on your street?',
      'Find the thickest tree trunk you can and touch it.',
      'Almost certainly a tree. A trunk too wide to hug is often '
      'older than every building around it - it was here first, and '
      'it remembers different weather.'),
  Wonder(
      'Why do ants walk in lines?',
      'Watch an ant trail for three minutes. Interrupt it gently '
      'with a leaf and see what happens.',
      'Each ant lays an invisible scent thread; the others read it '
      'with their antennae. Your leaf broke the thread - watch how '
      'fast they re-tie it.'),
  Wonder(
      'Which direction do the clouds travel where you live?',
      'Look up three times today and note the direction each time.',
      'Weather usually arrives from the same compass point - many '
      'places have prevailing winds. Sailors and farmers knew their '
      'sky\'s habit by heart; now you know yours.'),
  Wonder(
      'Why is dew only on some mornings?',
      'Touch the grass early tomorrow. Wet or dry? Look at the sky.',
      'Clear, calm nights let the ground cool until the air\'s water '
      'settles on it as dew. Cloudy nights keep the ground warm - no '
      'dew. Wet grass means last night was clear.'),
  Wonder(
      'What lives under one stone?',
      'Lift one stone gently, look for ten seconds, put it back '
      'exactly as it was.',
      'A whole apartment: woodlice (tiny land crustaceans - cousins '
      'of crabs), springtails, sometimes a beetle or a centipede. '
      'Putting the roof back matters: you visited someone\'s home.'),
  Wonder(
      'Why do small birds mob big birds?',
      'If you hear sudden frantic chirping, look for the crowd - '
      'and then for the one big bird they surround.',
      'Small birds gang up to escort hawks and crows away from '
      'their nests. Loud, agile, and together, they are safer than '
      'hiding - the little ones are doing the chasing.'),
  Wonder(
      'Where does the rain go after it lands?',
      'After the next rain, follow one trickle downhill as far as '
      'you can.',
      'Every trickle is already a river. It joins gutters, streams, '
      'and eventually the sea - your street is part of a watershed, '
      'and everything dropped on it travels along.'),
  Wonder(
      'Why does the moon look bigger near the horizon?',
      'Compare: look at a low moon, then again when it is higher.',
      'It is not bigger - photograph it and measure. Your brain '
      'compares the low moon to trees and rooftops and inflates it. '
      'One of the oldest optical illusions there is.'),
  Wonder(
      'What is the loudest natural sound where you live?',
      'Step outside, close your eyes for one minute, and rank what '
      'you hear: machine sounds versus living sounds.',
      'For most of human history the answer was birds, wind, or '
      'water. Finding the living sounds under the machine sounds is '
      'a skill - and it comes back fast with practice.'),
  Wonder(
      'Do flowers face a direction?',
      'Find three flowers of the same kind. Which way do they point?',
      'Many track or face the sun\'s path for warmth and visitors - '
      'young sunflowers famously follow it east to west all day, '
      'and reset east again overnight.'),
  Wonder(
      'Why do cats and dogs eat grass?',
      'If you know a cat or dog, watch what it sniffs on a walk.',
      'Even meat-eaters use plants - grass adds fiber and may settle '
      'their stomachs. Wild wolves and lions do it too. The lawn is '
      'part pharmacy.'),
  // month-tuned wonders: the year writes the schedule
  Wonder(
      'Why is January the loudest month for foxes?',
      'Crack a window after dark tonight and listen for a sharp, '
      'repeated bark - or an eerie scream.',
      'It is fox mating season. The screams are conversation, not '
      'trouble - January nights are the fox\'s town square.',
      month: 1),
  Wonder(
      'Who is singing this early in February?',
      'Listen at dawn. One confident song in the cold usually means '
      'one particular bird.',
      'Robins and great tits start rehearsing weeks before spring - '
      'an early song claims a garden before rivals even wake. The '
      'year\'s first singers are staking claims.',
      month: 2),
  Wonder(
      'What is the first flower you can find this March?',
      'Hunt for one open flower - garden, crack in the pavement, '
      'anywhere.',
      'The earliest flowers - crocuses, celandines, dandelions - are '
      'diners opening before the rush: the first hungry bees of the '
      'year depend on exactly these.',
      month: 3),
  Wonder(
      'Why is the dawn so loud in April?',
      'Wake fifteen minutes before sunrise once this week. Open the '
      'window and count the different voices.',
      'You heard the dawn chorus - the year\'s greatest concert. '
      'Birds sing hardest now: territories, partners, and calm '
      'morning air that carries a song the farthest.',
      month: 4),
  Wonder(
      'Whose beak is that hammering in May?',
      'Follow any fast drumming sound to its tree.',
      'Woodpeckers drum loudest in spring - it is their song, played '
      'on wood. Each species has its own rhythm, and a good hollow '
      'branch is a drum kit worth defending.',
      month: 5),
  Wonder(
      'Why do June evenings smell so strong?',
      'Step outside just after sunset and smell the air near any '
      'flowers or mown grass.',
      'Many flowers save their perfume for evening to call in moths, '
      'the night shift of pollination. Cut grass adds its own green '
      'alarm scent. June nights are the year\'s most fragrant.',
      month: 6),
  Wonder(
      'Where have all the birds gone in July?',
      'Compare: how many birds do you SEE today versus how many you '
      'HEAR?',
      'They are hiding on purpose. After breeding, many birds molt '
      'their worn feathers and lie low while the new ones grow - '
      'quiet, scruffy, and deliberately unseen.',
      month: 7),
  Wonder(
      'Why are there suddenly so many spiders in August?',
      'Count the webs you can find on one fence or hedge.',
      'This year\'s spiderlings have grown up - and grown webs worth '
      'noticing. Late summer is web season: more spiders, bigger '
      'orbs, and misty mornings that hang them with beads.',
      month: 8),
  Wonder(
      'Who is planting the forests this September?',
      'Watch for a pinkish crow-sized bird flying with something in '
      'its beak.',
      'Jays. One jay buries thousands of acorns each autumn and '
      'forgets a share of them - forgotten acorns become oaks. '
      'Forests are partly planted by birds\' imperfect memory.',
      month: 9),
  Wonder(
      'Why do leaves turn the colors they turn in October?',
      'Collect three fallen leaves of different colors from the '
      'same kind of tree.',
      'The yellows were there all summer, hidden under green '
      'chlorophyll; when the tree withdraws it, they show. The reds '
      'are new - made fresh in autumn, a sunscreen for the leaf\'s '
      'last weeks.',
      month: 10),
  Wonder(
      'Where do insects go in November?',
      'Check under a windowsill, a loose bark flake, or a shed '
      'corner - look, then leave everything as found.',
      'They are all around you, paused: butterflies folded in sheds, '
      'ladybirds packed in crevices, queens of next year\'s wasp '
      'nests sleeping alone. Winter is full of waiting insects.',
      month: 11),
  Wonder(
      'Why can you hear farther on a cold December night?',
      'Step out on the next cold, still night and listen for the '
      'farthest sound you can identify.',
      'Cold air near the ground bends sound waves back down instead '
      'of letting them escape upward - December nights are natural '
      'amphitheaters. Distant trains, owls, and church bells arrive '
      'from farther than in summer.',
      month: 12),
];

// ---------- the Living Atlas ----------

class AtlasSpecies {
  final String id;
  final String emoji;
  final String name;
  final String wikiTitle; // portrait + intro via the wiki pipeline
  final bool nocturnal;
  final bool flora; // trees are met, but they do not go visiting
  final Map<String, String> now; // season -> what it is doing
  final String look; // how to actually find it
  final String wonder; // the fact you tell someone at dinner
  final String kidLine; // the same page, in the kid voice
  const AtlasSpecies({
    required this.id,
    required this.emoji,
    required this.name,
    required this.wikiTitle,
    this.nocturnal = false,
    this.flora = false,
    required this.now,
    required this.look,
    required this.wonder,
    required this.kidLine,
  });

  String nowLine(DateTime t) => now[season(t)] ?? '';
}

const atlas = [
  AtlasSpecies(
    id: 'fox',
    emoji: '🦊',
    name: 'Red fox',
    wikiTitle: 'Red fox',
    now: {
      'spring':
          'Cubs are being raised in an underground den. The parents '
              'are hunting overtime - if you see a fox trotting with '
              'purpose at dusk, it is probably on a food run.',
      'summer': 'This year\'s cubs are above ground, learning the '
          'famous pounce - leaping high and diving front-paws-first. '
          'Their practice looks exactly like play, because it is both.',
      'autumn': 'The young leave home to find territories of their '
          'own, sometimes traveling far through towns by night. '
          'Autumn foxes on the move are often this year\'s teenagers.',
      'winter': 'The loudest season: January is mating time, and '
          'night air carries barks and startling screams. It sounds '
          'alarming - it is conversation.',
    },
    look: 'Dusk and dawn, along hedgerows, field edges, and quiet '
        'streets. Foxes prefer the seams of places. Stand still: a '
        'fox that thinks you have not seen it will carry on.',
    wonder: 'A fox can hear a mouse moving under deep snow - and '
        'researchers found foxes pounce most successfully facing '
        'north-east, possibly steering by the Earth\'s magnetic '
        'field.',
    kidLine: 'The fox listens so well she can hear tiny feet running '
        'under the snow - then she jumps like a diver to catch her '
        'dinner.',
  ),
  AtlasSpecies(
    id: 'robin',
    emoji: '🐦',
    name: 'Robin',
    wikiTitle: 'European robin',
    now: {
      'spring': 'Singing at first light to claim a garden, and '
          'nesting somewhere low and secret - an old kettle or an '
          'open shed will do fine.',
      'summer': 'Quieter now, and by late summer almost invisible: '
          'robins molt their worn feathers and keep a low profile '
          'until the new coat is ready.',
      'autumn': 'Back on the fence and singing again - one of very '
          'few birds that sings in autumn, because robins hold a '
          'winter territory too, and it needs announcing.',
      'winter': 'Bold as ever. A robin will follow anyone who turns '
          'soil, waiting for worms - a job its ancestors learned '
          'from wild boar rooting the forest floor.',
    },
    look: 'Low perches - fence posts, spade handles, branch stubs. '
        'Dig anywhere in a garden and wait: the robin often finds '
        'you.',
    wonder: 'Robins sometimes sing in the middle of the night under '
        'streetlights, and are regularly mistaken for nightingales.',
    kidLine: 'The robin sings almost all year round - and if you dig '
        'in the garden, one might come stand beside you, waiting for '
        'worms like a tiny supervisor.',
  ),
  AtlasSpecies(
    id: 'swallow',
    emoji: '🕊️',
    name: 'Barn swallow',
    wikiTitle: 'Barn swallow',
    now: {
      'spring': 'Arriving - each one has just flown thousands of '
          'kilometers from Africa, often returning to the very barn '
          'where it was born. Watch the sky: the first swallow is a '
          'real event.',
      'summer': 'Building mud-cup nests on beams and feeding '
          'nonstop, catching insects entirely on the wing in long '
          'swooping loops.',
      'autumn': 'Gathering in chattering lines on wires - the '
          'year\'s great departure meeting. One morning soon, the '
          'wires will be empty.',
      'winter': 'Not here. She is over Africa now, hunting insects '
          'in the southern summer. The page rests until spring - '
          'and that is the honest truth of migration.',
    },
    look: 'Open sky over fields and water in the warm months; wires '
        'and barn eaves. Low swooping flight, deep tail forks, a '
        'dry chittering call.',
    wonder: 'A swallow drinks without landing - it skims a pond and '
        'scoops water in flight. It can even sleep on the wing '
        'during migration.',
    kidLine: 'The swallow flies all the way from Africa to build a '
        'little mud cup house - and she drinks by sipping the pond '
        'while flying, like a tiny airplane refueling.',
  ),
  AtlasSpecies(
    id: 'honeybee',
    emoji: '🐝',
    name: 'Honeybee',
    wikiTitle: 'Western honey bee',
    now: {
      'spring': 'The colony is growing at full speed, and crowded '
          'hives may swarm - a queen and half her workers pouring '
          'out to found a new city. A hanging swarm is calm, not '
          'angry: it is a city between homes.',
      'summer': 'Peak foraging. Scouts dance the waggle dance on '
          'the comb - a figure-eight whose angle and length are a '
          'map to the flowers they found.',
      'autumn': 'The colony turns inward: stores are checked, '
          'entrances guarded, and the drones - the males - are '
          'shown the door before winter.',
      'winter': 'No hibernation: the bees cluster around their '
          'queen and shiver their wing muscles to keep the center '
          'warm, eating the summer\'s honey. The hive hums quietly '
          'all winter.',
    },
    look: 'Pick one flower patch on a warm morning and watch it for '
        'ten minutes. Follow one bee from flower to flower - notice '
        'she keeps to one kind of flower per trip.',
    wonder: 'A bee tells her hive exactly where flowers are by '
        'dancing a figure-eight - the dance\'s angle points at the '
        'food, using the sun as north.',
    kidLine: 'Bees tell each other where the best flowers are by '
        'dancing - a little waggle dance that works like a treasure '
        'map.',
  ),
  AtlasSpecies(
    id: 'owl',
    emoji: '🦉',
    name: 'Barn owl',
    wikiTitle: 'Barn owl',
    nocturnal: true,
    now: {
      'spring': 'Nesting in barns, church towers, and hollow trees. '
          'Listen on still nights for long hissing screeches - barn '
          'owls do not hoot.',
      'summer': 'Owlets are growing, and they snore: a hungry brood '
          'sounds like soft sawing coming from a barn roof.',
      'autumn': 'The young disperse to find their own hunting '
          'grounds - low, silent patrols over field edges in the '
          'lengthening nights.',
      'winter': 'The hard season: hunting longer hours over frosty '
          'grass. A ghost-white shape crossing headlights on a '
          'country road is often her.',
    },
    look: 'After dark, rough grassland, field margins, and quiet '
        'roads. She flies low and utterly silently - you look for '
        'a pale shape, not a sound.',
    wonder: 'A barn owl\'s heart-shaped face is a sound dish: it '
        'funnels the faintest rustle to ears set at different '
        'heights, letting her strike a mouse in total darkness by '
        'hearing alone.',
    kidLine: 'The barn owl\'s face is shaped like a satellite dish '
        'for sounds - she can catch her dinner in the pitch dark '
        'just by listening.',
  ),
  AtlasSpecies(
    id: 'hedgehog',
    emoji: '🦔',
    name: 'Hedgehog',
    wikiTitle: 'European hedgehog',
    nocturnal: true,
    now: {
      'spring': 'Waking from hibernation, thin and very hungry, and '
          'setting out on noisy nighttime rounds - a surprising '
          'amount of snuffling for such a small animal.',
      'summer': 'Walking up to two kilometers a night through '
          'gardens, eating beetles, caterpillars, and slugs. A hole '
          'in the bottom of a fence is a hedgehog highway.',
      'autumn': 'Eating urgently to reach hibernation weight, and '
          'inspecting leaf piles for a winter nest. Autumn leaf '
          'piles may already be someone\'s bedroom - check before '
          'moving one.',
      'winter': 'Hibernating in a nest of packed leaves, heartbeat '
          'slowed to a few beats a minute. Asleep is not gone: the '
          'quiet pile in the corner is alive.',
    },
    look: 'After dark in gardens and parks, by ear first: a loud, '
        'busy snuffling in the undergrowth. Torchlight briefly and '
        'low; never pick one up unless it is in danger.',
    wonder: 'A hedgehog wears about six thousand spines, and each '
        'one is a hollowed hair - strong, light, and springy enough '
        'to cushion a fall.',
    kidLine: 'The hedgehog wears a coat of six thousand prickles '
        'and walks farther every night than most people do - all '
        'while snuffling like a tiny vacuum cleaner.',
  ),
  AtlasSpecies(
    id: 'oak',
    emoji: '🌳',
    name: 'Oak',
    wikiTitle: 'Oak',
    flora: true,
    now: {
      'spring': 'Leafing out and flowering at once - those dangling '
          'yellow-green tassels are catkins, the oak\'s flowers, '
          'dusting the wind with pollen.',
      'summer': 'A full canopy running the busiest hotel in the '
          'landscape: a single old oak can host hundreds of species '
          'of insects, birds, lichens, and mammals at once.',
      'autumn': 'Acorn season. Jays and squirrels cart the crop '
          'away and bury it - the oak\'s deal with animal memory, '
          'and animal forgetfulness, plants the next forest.',
      'winter': 'Bare but fully alive: next spring\'s buds are '
          'already formed and waiting, wrapped in weatherproof '
          'scales, decided since last summer.',
    },
    look: 'Look for the lobed, wavy-edged leaf and deeply fissured '
        'bark. In winter, look up: big, twisting, elbowed branches '
        'mean oak even without a single leaf.',
    wonder: 'An old oak supports more life than almost any other '
        'tree in its landscape - hundreds of species live in, on, '
        'and off one single tree.',
    kidLine: 'One big oak tree is like a whole apartment building '
        'for animals - beetles in the bark, birds in the branches, '
        'squirrels in the pantry.',
  ),
  AtlasSpecies(
    id: 'admiral',
    emoji: '🦋',
    name: 'Red admiral',
    wikiTitle: 'Vanessa atalanta',
    now: {
      'spring': 'Arriving from the south - red admirals are '
          'migrants, riding warm winds north in waves you can '
          'sometimes notice as "suddenly, butterflies."',
      'summer': 'Laying eggs on nettles (the caterpillars\' only '
          'menu) and patrolling gardens. A butterfly bath: they '
          'love rotting fruit even more than flowers.',
      'autumn': 'Feeding hard on ivy flowers and fallen fruit; many '
          'head south, while some tuck themselves into sheds and '
          'log piles to try wintering here.',
      'winter': 'Mostly still and hidden, wings folded to look like '
          'dark bark - but a warm, sunny winter day can wake one '
          'for a surprise flight.',
    },
    look: 'Buddleia, ivy flowers, fallen fruit, and sunny walls. '
        'Wings open: black velvet with red-orange bands. Wings '
        'closed: vanishing act.',
    wonder: 'Butterflies taste with their feet - a red admiral '
        'landing on fruit knows instantly whether it is worth '
        'uncoiling her straw-like tongue.',
    kidLine: 'This butterfly tastes things by standing on them - '
        'her feet work like a tongue, so landing on an apple is '
        'taking a bite.',
  ),
  AtlasSpecies(
    id: 'frog',
    emoji: '🐸',
    name: 'Common frog',
    wikiTitle: 'Common frog',
    now: {
      'spring': 'Spawning season: ponds fill with croaking males '
          'and clouds of jelly-dotted spawn. A pond that was silent '
          'all winter becomes a choir almost overnight.',
      'summer': 'This year\'s froglets - fingernail-sized and '
          'perfect - leave the ponds in waves, usually on rainy '
          'days. A wet July path can suddenly be full of tiny '
          'travelers.',
      'autumn': 'Feeding hard and choosing winter quarters: log '
          'piles, compost heaps, and the mud at the bottom of '
          'ponds.',
      'winter': 'Dormant, and pulling the amphibian trick: a frog '
          'wintering underwater can take in oxygen through its '
          'skin, sitting out the cold without a single breath '
          'taken.',
    },
    look: 'Pond edges at dusk, damp evenings after rain, and under '
        'anything that keeps the ground moist. Move slowly: frogs '
        'freeze before they flee.',
    wonder: 'A frog can breathe through its skin - underwater in '
        'winter, its skin does the work of lungs.',
    kidLine: 'In winter a frog can sleep at the bottom of a pond '
        'and breathe through its SKIN - the whole frog works like '
        'one big gentle lung.',
  ),
  AtlasSpecies(
    id: 'salmon',
    emoji: '🐟',
    name: 'Atlantic salmon',
    wikiTitle: 'Atlantic salmon',
    now: {
      'spring': 'Young salmon (smolts) that grew up in rivers turn '
          'silver and slip downstream to the sea - the great '
          'leaving, mostly unseen.',
      'summer': 'At sea, feeding and growing fast in cold northern '
          'water, sometimes thousands of kilometers from the river '
          'where they hatched.',
      'autumn': 'The run home: adults push upstream, leaping falls '
          'and weirs, to spawn in the very gravel where they '
          'hatched. Below any weir is the season\'s best theater.',
      'winter': 'The next generation waits as eggs buried in '
          'gravel nests called redds, washed by cold clean water '
          'all winter long.',
    },
    look: 'In autumn, watch below weirs and small waterfalls on '
        'salmon rivers, especially after rain raises the water. '
        'Patience buys leaps.',
    wonder: 'A salmon finds its way home from the open ocean '
        'largely by SMELL - the chemical signature of its home '
        'stream, learned as a juvenile and remembered for years.',
    kidLine: 'A salmon remembers the smell of the river where it '
        'was born - and years later it smells its way home across '
        'the whole sea.',
  ),
];

/// Who is visiting the hillside this hour, drawn from the species
/// this device has MET. Deterministic per hour (a living world, not
/// a slot machine), the night shift visits after dark, and flora
/// stays politely rooted. An empty guide means a quiet hill - the
/// more you meet, the busier your world.
List<AtlasSpecies> visitorsFor(
  Iterable<String> metIds,
  DateTime t, {
  required bool dark,
  int max = 3,
}) {
  final ids = metIds.toList()..sort();
  final pool = <AtlasSpecies>[
    for (final id in ids)
      if (atlasById(id) case final AtlasSpecies s)
        if (!s.flora && s.nocturnal == dark) s
  ];
  if (pool.isEmpty) return const [];
  final start = (dayOfYear(t) * 31 + t.hour) % pool.length;
  return [
    for (var i = 0; i < pool.length && i < max; i++)
      pool[(start + i) % pool.length]
  ];
}

/// The shy one: a neighbor this device has NOT met, who will only
/// step out for someone willing to be truly still. Deterministic
/// per day, keeps the night shift's hours, and flora - patient by
/// profession - never needs coaxing. Null when every neighbor of
/// this hour is already a friend.
AtlasSpecies? shyOfDay(Iterable<String> metIds, DateTime t,
    {required bool dark}) {
  final met = metIds.toSet();
  final pool = [
    for (final s in atlas)
      if (!s.flora && !met.contains(s.id) && s.nocturnal == dark) s
  ];
  if (pool.isEmpty) return null;
  return pool[dayOfYear(t) % pool.length];
}

AtlasSpecies? atlasById(String id) {
  for (final s in atlas) {
    if (s.id == id) return s;
  }
  return null;
}

// ---------- the home page's seasonal line ----------

/// One line a day about what a neighbor species is doing right now.
/// Nocturnal species take the evening slot when the sky is dark.
AtlasSpecies speciesOfDay(DateTime t, {bool dark = false}) {
  final pool = dark
      ? atlas.where((s) => s.nocturnal).toList(growable: false)
      : atlas;
  final list = pool.isEmpty ? atlas : pool;
  return list[(dayOfYear(t) * 3 + t.month) % list.length];
}
