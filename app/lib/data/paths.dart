// Paths - learning as walking, not school. A Path is a run of short
// chapters; every chapter is three things: one true idea, one thing
// to notice outside today, and one Field Note earned into your own
// field guide. Two tracks per chapter: Curious (anyone) and Keeper
// (the deeper cut). Knowledge is earned as an artifact, never as
// points - a note can never be lost, and nothing ever decays.

class Chapter {
  final String id;
  final String emoji;
  final String title;
  final String idea; // one true idea, told well
  final String notice; // the world is the exercise
  final String keeper; // the deeper layer, for the hungry
  final String note; // the field note this chapter writes
  final String? speciesId; // a door into the Living Atlas
  const Chapter({
    required this.id,
    required this.emoji,
    required this.title,
    required this.idea,
    required this.notice,
    required this.keeper,
    required this.note,
    this.speciesId,
  });
}

class Path {
  final String id;
  final String emoji;
  final String name;
  final String promise; // what you will be able to DO
  final String capstone; // the real-world ending, not a certificate
  final List<Chapter> chapters;
  const Path({
    required this.id,
    required this.emoji,
    required this.name,
    required this.promise,
    required this.capstone,
    required this.chapters,
  });
}

/// How far along a path is, given the set of earned chapter ids.
int pathProgress(Path p, Set<String> earned) =>
    p.chapters.where((c) => earned.contains(c.id)).length;

/// The next unearned chapter, or null when the path is walked.
Chapter? nextChapter(Path p, Set<String> earned) {
  for (final c in p.chapters) {
    if (!earned.contains(c.id)) return c;
  }
  return null;
}

/// The path a home card should suggest: the one furthest along but
/// unfinished, else the first untouched one, else null (all done).
Path? continuePath(Set<String> earned) {
  Path? best;
  var bestProg = -1;
  for (final p in paths) {
    final prog = pathProgress(p, earned);
    if (prog >= p.chapters.length) continue; // walked
    if (prog > bestProg) {
      bestProg = prog;
      best = p;
    }
  }
  return best;
}

const paths = [
  Path(
    id: 'birds',
    emoji: '🐦',
    name: 'Birds Where You Are',
    promise: 'From "that\'s a bird" to knowing five neighbors by '
        'shape, flight, and voice.',
    capstone: 'The five-neighbor walk: one walk, this week, on which '
        'you greet five species by name. Your street will never '
        'sound the same again.',
    chapters: [
      Chapter(
        id: 'b1',
        emoji: '👀',
        title: 'The three questions',
        idea: 'Beginners ask "what color was it?" - but light lies '
            'about color all day long. Birders ask three better '
            'questions: how BIG (sparrow-size, pigeon-size, '
            'goose-size)? What SHAPE (round, slim, crested, '
            'long-tailed)? What was it DOING (ground-hopping, '
            'trunk-climbing, air-hunting)? Size, shape, and behavior '
            'survive bad light. Color does not.',
        notice: 'Next bird you see: say its size class, its shape, '
            'and its behavior out loud. Skip the color entirely.',
        keeper: 'Professionals compress this into "GISS" (general '
            'impression, size, and shape) - the split-second gestalt '
            'that lets a watcher name a distant speck. You already '
            'do this with friends at a distance: nobody recognizes '
            'a friend by their coat color.',
        note: 'Size, shape, behavior - the three questions that '
            'survive bad light.',
      ),
      Chapter(
        id: 'b2',
        emoji: '✂️',
        title: 'Silhouettes',
        idea: 'Every bird family has a cut-out shape you can learn '
            'like an alphabet. Pigeon: plump chest, small head. '
            'Crow: heavy bill, square tail. Sparrow: round ball, '
            'stubby bill. Wagtail: a teaspoon with a long handle. '
            'Learn three today and you will never see "just a bird" '
            'again - you will see letters.',
        notice: 'Watch birds against the bright sky, where they are '
            'ALL silhouettes, and sort them: pigeon-shaped, '
            'crow-shaped, small-and-round.',
        keeper: 'Field guides print silhouette plates first for a '
            'reason: shape is inherited deep in the family tree, '
            'while color evolves fast and varies. Shape is the '
            'surname; color is the outfit.',
        note: 'Shape is the surname; color is the outfit.',
      ),
      Chapter(
        id: 'b3',
        emoji: '🌊',
        title: 'How they fly',
        idea: 'Flight style names a bird at any distance. Pigeons '
            'row steadily. Crows flap loose and slow. Finches and '
            'woodpeckers BOUNCE - flap-flap-close, dipping through '
            'the air like a thrown ball. Swallows carve. Gulls '
            'glide stiff-winged. The sky is full of handwriting.',
        notice: 'Pick one flying bird and watch only its wingbeats: '
            'steady, loose, bouncing, carving, or gliding?',
        keeper: 'The bounding flight of small birds saves energy: '
            'closing the wings entirely between bursts costs less '
            'than continuous flapping at their size. Physics writes '
            'the handwriting.',
        note: 'Steady, loose, bouncing, carving, gliding - flight '
            'is handwriting.',
      ),
      Chapter(
        id: 'b4',
        emoji: '🌅',
        title: 'The dawn clock',
        idea: 'The dawn chorus is not a jumble - it is a schedule. '
            'Robins and blackbirds sing first, in the half-dark '
            '(big eyes, early risers). Wrens and tits join as light '
            'grows. By full sunrise the early singers are already '
            'quieting to feed. Dawn is a clock you can hear.',
        notice: 'Once this week, listen at first light for five '
            'minutes. Notice: one voice starts before all the '
            'others. That is probably a robin or a blackbird.',
        keeper: 'The order tracks eye size: birds with bigger eyes '
            'relative to their body start singing in dimmer light. '
            'You can nearly sort the chorus by eyeball.',
        note: 'Dawn is a clock: robin and blackbird strike first.',
        speciesId: 'robin',
      ),
      Chapter(
        id: 'b5',
        emoji: '🎵',
        title: 'Learn one song',
        idea: 'You cannot learn "birdsong." You can learn ONE song '
            'this week, and the robin\'s is the place to start: a '
            'thin, silvery, wandering stream - unhurried phrases '
            'with pauses, like someone thinking out loud. Once one '
            'song is YOURS, every other song becomes "not-robin," '
            'and the untangling has begun.',
        notice: 'Find any singing bird and stay with the song for '
            'two whole minutes. Describe it in words: fast or '
            'slow? Repeated or wandering? Sweet or scratchy?',
        keeper: 'Birders describe songs with mnemonics ("teacher! '
            'teacher!" for the great tit) because human memory '
            'grips words better than melodies. Invent your own - '
            'the sillier, the stickier.',
        note: 'One song learned unlocks all the others as '
            '"not-that."',
        speciesId: 'robin',
      ),
      Chapter(
        id: 'b6',
        emoji: '📣',
        title: 'The news network',
        idea: 'That sharp, repeated "chip! chip!" is not singing - '
            'it is an alarm, and everyone is subscribed. Squirrels '
            'react to bird alarms; birds react to squirrel scolds. '
            'When you walk into a hedge\'s alarm calls, you are '
            'the news. Stand still for two minutes and listen to '
            'yourself being un-reported.',
        notice: 'When you hear urgent repeated chipping, stop. '
            'Wait. Notice how long it takes for the alarms to '
            'settle once you are still.',
        keeper: 'Some species have different alarms for hawk versus '
            'cat versus human - studied most famously in chickadees, '
            'whose "dee-dee-dee" count scales with threat. It is '
            'not noise; it is grammar.',
        note: 'Alarm calls are the forest\'s news, and I am '
            'sometimes the headline.',
      ),
      Chapter(
        id: 'b7',
        emoji: '🥄',
        title: 'Beaks are menus',
        idea: 'A beak is a tool, and the tool tells you the diet. '
            'Thick cone: seed-cracker (finches). Thin tweezer: '
            'insect-picker (warblers, robins). Hook: meat (hawks). '
            'Chisel: wood (woodpeckers). Flat bill: water-strainer '
            '(ducks). Read the beak and you know what the bird is '
            'looking for - which tells you where it will be.',
        notice: 'Look at any bird\'s beak and guess its menu. '
            'Then watch one minute to check your guess.',
        keeper: 'Darwin\'s finches made this principle famous: one '
            'ancestral finch radiating into cracker-beaks, '
            'probe-beaks, and tool-users across the Galapagos. '
            'The beak IS the niche.',
        note: 'Read the beak, know the menu, predict the place.',
      ),
      Chapter(
        id: 'b8',
        emoji: '🪵',
        title: 'The edge habit',
        idea: 'Birds love edges: hedge meets lawn, reeds meet water, '
            'forest meets field. Edges offer food from two worlds '
            'and cover one hop away. Scan any landscape and spend '
            'your attention on its seams - that is where the life '
            'is stitched.',
        notice: 'Find one edge (fence line, hedge, water margin) '
            'and watch only the edge for three minutes.',
        keeper: 'Ecologists call it the edge effect: species '
            'richness concentrates where habitats meet. It is also '
            'why hedgerows matter so much more than their area '
            'suggests - a hedge is nearly ALL edge.',
        note: 'Life stitches itself along the seams. Watch edges.',
      ),
      Chapter(
        id: 'b9',
        emoji: '🌦️',
        title: 'Weather birds',
        idea: 'Birds read the sky before you do. Swallows often '
            'hunt low before rain - the insects they chase ride '
            'low on the falling pressure and damp air. Gulls drift '
            'inland ahead of storms. A sudden hush in the garden '
            'can mean a hawk - or weather. The birds are a '
            'forecast with wings.',
        notice: 'On the next changing-weather day, watch how high '
            'the birds are flying and what they are doing '
            'differently.',
        keeper: 'The folklore is old ("swallows high, staying dry") '
            'and imperfect - but the mechanism is real enough to '
            'be useful: insect-eaters follow insects, and insects '
            'follow the air.',
        note: 'Birds are a forecast with wings - imperfect, but '
            'real.',
        speciesId: 'swallow',
      ),
      Chapter(
        id: 'b10',
        emoji: '🔢',
        title: 'Count one minute',
        idea: 'Here is the strangest trick in birdwatching: '
            'counting changes what you see. Watch casually and you '
            'will see "some birds." Count for one minute and you '
            'will suddenly see individuals: THAT sparrow, chased by '
            'THAT one, while a third watches. Numbers force the '
            'eyes to separate the crowd into lives.',
        notice: 'One minute, one count: how many individual birds '
            'can you see or hear right now, exactly?',
        keeper: 'This is why citizen science counts work: the '
            'protocol is a seeing-machine. The Big Garden '
            'Birdwatch\'s single hour, repeated by hundreds of '
            'thousands, maps whole national populations.',
        note: 'Counting turns "some birds" into individual lives.',
      ),
      Chapter(
        id: 'b11',
        emoji: '🏘️',
        title: 'Your patch',
        idea: 'Every serious birder has a "patch" - one ordinary '
            'place, visited often, known deeply. A patch beats an '
            'exotic trip: on your patch you notice CHANGE, and '
            'change is where all the stories are. First arrival, '
            'last departure, the new singer on the old aerial. '
            'Adopt a patch this week: a park corner, a street, '
            'a stretch of window.',
        notice: 'Choose your patch. Name it. Visit it twice this '
            'week and notice one difference between visits.',
        keeper: 'Long-run patch lists are quietly scientific '
            'gold: local first-arrival dates across decades are '
            'exactly how we know spring is shifting.',
        note: 'My patch: one place, known deeply, where change '
            'shows.',
      ),
      Chapter(
        id: 'b12',
        emoji: '🖐️',
        title: 'Capstone: five neighbors',
        idea: 'The walk that ends this path: one unhurried walk on '
            'which you identify five species yourself - by shape, '
            'flight, voice, or beak, color allowed now as garnish. '
            'Five is the threshold where a street stops being '
            'scenery and becomes a neighborhood you belong to.',
        notice: 'Take the walk. Five neighbors, greeted by name. '
            'There is no timer and no judge - the walk counts '
            'when you say it does.',
        keeper: 'After five, the next forty come almost by '
            'themselves - recognition compounds. Every birder '
            'alive started with these same five.',
        note: 'Five neighbors known by name. The street is a '
            'neighborhood now.',
      ),
    ],
  ),
  Path(
    id: 'night',
    emoji: '🌙',
    name: 'Night Nature',
    promise: 'The dark half of nature is on a schedule you can '
        'learn: eyes, ears, moths, owls, and the moon.',
    capstone: 'The dusk sit: one evening, one quiet spot, from '
        'sunset until true dark. Watch the day shift clock out '
        'and the night shift clock in.',
    chapters: [
      Chapter(
        id: 'n1',
        emoji: '👁️',
        title: 'Your night eyes',
        idea: 'You own night vision; it just needs twenty minutes '
            'to boot. In darkness your eyes slowly rebuild a '
            'pigment called rhodopsin that one glance at a phone '
            'screen destroys. And the trick of the ancients: look '
            'slightly BESIDE a dim thing to see it - your eye\'s '
            'edges are built for darkness, the center for day.',
        notice: 'Tonight, stand in the dark ten minutes without '
            'any screen. Then find a dim star or shape and catch '
            'it by looking just beside it.',
        keeper: 'Averted vision works because rod cells (dim-light '
            'sensors) crowd the retina\'s periphery while the '
            'fovea is packed with cones. Astronomers, sailors, '
            'and soldiers have leaned on this for millennia.',
        note: 'Twenty dark minutes buys night eyes; look beside '
            'dim things, not at them.',
      ),
      Chapter(
        id: 'n2',
        emoji: '🌗',
        title: 'The moon is a clock',
        idea: 'The moon\'s phase tells you its schedule. Full moon: '
            'up all night, sunset to sunrise. New moon: up all '
            'day, invisible in the glare - which is why new-moon '
            'nights are the dark ones. First quarter rides the '
            'evening; last quarter rules the small hours. Learn '
            'this and you will always know tonight\'s lighting '
            'before it arrives.',
        notice: 'Check tonight\'s moon (Hopeling\'s sky knows it). '
            'Predict: will it light the evening, the small hours, '
            'or neither? Then verify with your own eyes.',
        keeper: 'The rule compresses to: the moon rises about '
            'fifty minutes later each day. Every phase\'s schedule '
            'follows from that one lag.',
        note: 'The moon keeps a schedule: full rules the night, '
            'new leaves it dark.',
      ),
      Chapter(
        id: 'n3',
        emoji: '🦇',
        title: 'Who flies at dusk',
        idea: 'That flutter over the rooftops at dusk: bird or '
            'bat? Read the flight. Birds keep steady lines and '
            'smooth turns. Bats flicker - sudden jinks, dives, '
            'reversals - because they are chasing insects they '
            'hear rather than see. Jerky is sonar; smooth is '
            'sight.',
        notice: 'At next dusk, watch the sky over rooftops or '
            'trees for five minutes. Sort the fliers: smooth or '
            'flickering?',
        keeper: 'A bat can catch hundreds of midges an hour, '
            'eating up to a third of its body weight in a night - '
            'the flicker you see is a mouth working the air like '
            'a net.',
        note: 'Smooth is sight, jinking is sonar: birds versus '
            'bats at dusk.',
      ),
      Chapter(
        id: 'n4',
        emoji: '🦉',
        title: 'Owls by ear',
        idea: 'You will hear ten owls for every one you see, so '
            'learn them by voice. The classic "twit-twoo" is a '
            'DUET: a tawny female calls "ke-wick," a male answers '
            '"hoooo." The barn owl never hoots at all - it '
            'shrieks, a long dry hiss. Learn two sounds and the '
            'night has speakers.',
        notice: 'On a still night, open a window and give the '
            'dark ten minutes. Any repeated far call: describe '
            'its rhythm out loud.',
        keeper: 'Owl ears sit asymmetrically - one higher than '
            'the other - so a sound\'s tiny arrival-time '
            'difference gives a vertical fix too. An owl hears '
            'in 3D.',
        note: 'Twit-twoo is two owls talking; the barn owl '
            'shrieks instead.',
        speciesId: 'owl',
      ),
      Chapter(
        id: 'n5',
        emoji: '🦋',
        title: 'The night shift of flowers',
        idea: 'Some flowers save their perfume for dusk - '
            'honeysuckle, evening primrose, night-scented stock - '
            'because their couriers are moths. Moths out-number '
            'butterflies many times over and pollinate quietly in '
            'the dark. The sweetest hour to smell a garden is the '
            'hour the day-shift goes home.',
        notice: 'Just after sunset, smell your way around any '
            'flowers you can reach. Which smells STRONGER now '
            'than at noon?',
        keeper: 'Night flowers converge on pale colors and heavy '
            'scent because color is useless in the dark - white '
            'reflects moonlight, and perfume travels where sight '
            'cannot.',
        note: 'The garden smells loudest at dusk, calling its '
            'night couriers.',
        speciesId: 'admiral',
      ),
      Chapter(
        id: 'n6',
        emoji: '✨',
        title: 'Eyeshine',
        idea: 'Sweep a torch low across a lawn or field edge at '
            'night and tiny stars answer: eyeshine, from mirror '
            'layers in night-animals\' eyes. Spiders scatter tiny '
            'green-white sparks in grass. A fox burns back '
            'white-green; a cat gold. The dark is full of eyes, '
            'politely reflecting.',
        notice: 'Hold a torch at your temple (beam along your '
            'line of sight) and sweep a lawn slowly. Count the '
            'sparks.',
        keeper: 'The mirror is the tapetum lucidum, bouncing '
            'missed photons back through the retina for a second '
            'chance - the same reason night animals\' eyes glow '
            'in headlights and photos.',
        note: 'Torch at the temple: the grass answers with tiny '
            'burning eyes.',
        speciesId: 'fox',
      ),
      Chapter(
        id: 'n7',
        emoji: '🔊',
        title: 'The night sound map',
        idea: 'Night hearing beats night seeing, so build a sound '
            'map: stand still, close your eyes, and place every '
            'sound on a clock face around you - rustle at two '
            'o\'clock, far dog at nine, something small at six. '
            'Two minutes of this and the dark stops being a wall '
            'and becomes a room.',
        notice: 'Tonight: two minutes, eyes closed, place three '
            'sounds on your clock face.',
        keeper: 'You locate sound by microsecond delays between '
            'your ears - the same cue the owl uses, just coarser. '
            'Turning your head slightly re-triangulates: you are '
            'steering a pair of antennas.',
        note: 'Eyes closed, the dark becomes a room with a '
            'clock-face of sounds.',
      ),
      Chapter(
        id: 'n8',
        emoji: '🌡️',
        title: 'Why nights are louder in cold',
        idea: 'Cold, still nights carry sound absurdly far: air '
            'cools fastest near the ground, and sound bends back '
            'down through that cold layer instead of escaping up. '
            'Distant trains, bells, and owls arrive from '
            'kilometers beyond their daytime range. Winter nights '
            'are natural amphitheaters.',
        notice: 'On the next cold still night, listen for the '
            'farthest identifiable sound - then try the same on '
            'a windy night and compare.',
        keeper: 'It is called a temperature inversion waveguide - '
            'the same physics that lets whale song cross oceans '
            'in deep sound channels.',
        note: 'Cold still air bends sound back to earth: winter '
            'nights are amphitheaters.',
      ),
      Chapter(
        id: 'n9',
        emoji: '⭐',
        title: 'Stars keep the seasons',
        idea: 'The stars are a calendar older than any almanac: '
            'Orion strides up in winter evenings, the Summer '
            'Triangle owns July, and when the Pleiades rise late '
            'in the year, ancient farmers knew to finish the '
            'harvest. Learn ONE seasonal marker and the night sky '
            'starts telling you the month.',
        notice: 'Find one bright pattern tonight and note where '
            'it stands. Check it again in a month - it will have '
            'moved west. The year is turning over your head.',
        keeper: 'The shift is four minutes a night - Earth\'s '
            'orbit showing. Four minutes a night is two hours a '
            'month, a full lap a year: the sky is the original '
            'year wheel.',
        note: 'The stars shift four minutes a night: a calendar '
            'overhead.',
      ),
      Chapter(
        id: 'n10',
        emoji: '🌆',
        title: 'Capstone: the dusk sit',
        idea: 'The path ends with the changing of the guard: one '
            'evening, one comfortable spot, from sunset until true '
            'dark, doing nothing but noticing. Day birds go quiet '
            'in order. Bats punch in. The first star. The first '
            'owl. Nobody who has truly watched a dusk ever calls '
            'it "getting dark" again - it is a shift change with '
            'a thousand employees.',
        notice: 'Take the sit. Sunset to dark. Note three '
            'handovers: something stopping, something starting, '
            'something you did not expect.',
        keeper: 'Ecologists call these crepuscular hours - some '
            'species live almost entirely inside them. The dusk '
            'sit is the closest thing nature has to intermission, '
            'and you had a front-row seat.',
        note: 'Dusk is a shift change with a thousand employees. '
            'I watched the handover.',
      ),
    ],
  ),
];

Path? pathById(String id) {
  for (final p in paths) {
    if (p.id == id) return p;
  }
  return null;
}
