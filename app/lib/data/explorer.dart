// The Noticing Walk (Wild Explorer v1) - Pause, Observe, Wonder,
// Reveal, Remember. Built from the Wild Explorer definition with its
// constitutional trims: the child DECLARES where they are (six habitat
// chips, including the window - every child gets to play), no GPS, no
// camera, no microphone - the child's own ears and eyes do all the
// noticing, and we trust their answers the way the whole app trusts
// its people. The reveal is deterministic from the habitat, the day
// and what the child chose - the mystery lives in the world, never in
// a roll - and the copy never claims an animal IS there, only that it
// lives in places like this. You are a guest in their home.

import '../core/clock.dart';

// ---------- the habitats ----------

class Habitat {
  final String id, emo, name;
  final List<WalkAnimal> cast;
  final List<String> observePrompts;
  const Habitat(this.id, this.emo, this.name, this.cast,
      this.observePrompts);
}

class WalkAnimal {
  final String emo, name;
  final String sign; // what it leaves behind - the noticing clue
  final String detail; // one unforgettable thing, true
  final String hook; // how to know it again without the app
  const WalkAnimal(this.emo, this.name, this.sign, this.detail, this.hook);
}

const habitats = [
  Habitat('window', '🪟', 'By my window', [
    WalkAnimal('🐦', 'House sparrow',
        'quick shapes hopping on ledges and wires',
        'Sparrows take dust baths to keep their feathers clean.',
        'Small, brown, loud, always in a gang.'),
    WalkAnimal('🕊', 'Pigeon', 'soft cooing and bobbing heads',
        'Pigeons find their way home from hundreds of kilometers away.',
        'Walks like its head is on a spring.'),
    WalkAnimal('🐝', 'Bee', 'a small hum passing the glass',
        'A bee visits hundreds of flowers in one trip.',
        'Fuzzy, busy, never in a straight line.'),
    WalkAnimal('☁️', 'Swift', 'fast sickle wings high in the sky',
        'Swifts can eat, drink and even sleep while flying.',
        'Never lands on a wire - always in the air.'),
  ], [
    'Look out and find something that moves without wind.',
    'Can you hear a sound that repeats?',
    'Count every living thing you can see from here.',
    'Find three different colors that nature made.',
  ]),
  Habitat('garden', '🌼', 'A garden or backyard', [
    WalkAnimal('🐌', 'Snail', 'a silver ribbon on the path',
        'A snail can sleep for months when the weather is wrong.',
        'Follow the shiny trail to the traveler.'),
    WalkAnimal('🐞', 'Ladybug', 'tiny red domes on stems and leaves',
        'One ladybug eats thousands of plant-hurting bugs in its life.',
        'Count the spots - each kind has its own number.'),
    WalkAnimal('🪱', 'Earthworm', 'little soil doors in the ground',
        'Earthworms breathe through their skin.',
        'After rain, look at the pavement edges.'),
    WalkAnimal('🐦', 'Robin', 'a head tilted at the ground, listening',
        'A robin tilts its head to hear worms moving under the soil.',
        'Red-orange chest, hops then freezes, hops then freezes.'),
  ], [
    'Explore one square of ground as if it were a whole world.',
    'Find something with three different colors on it.',
    'Can you spot evidence that an animal was here?',
    'Find the oldest living thing you can see.',
  ]),
  Habitat('street', '🏙', 'A street or city', [
    WalkAnimal('🐦‍⬛', 'Crow', 'a black watcher on a lamp post',
        'Crows remember human faces for years.',
        'Struts like it owns the street - it sort of does.'),
    WalkAnimal('🕊', 'Pigeon', 'gathered commuters of the pavement',
        'Pigeon parents make milk for their chicks - birds with milk!',
        'Look for the green-purple shine on their necks.'),
    WalkAnimal('🦇', 'Bat', 'quick shadows around the streetlights at dusk',
        'One bat can catch a thousand insects in an hour.',
        'At dusk, watch the streetlights - not the sky.'),
    WalkAnimal('🌿', 'Wall plants', 'green pushing through every crack',
        'Some city wall plants can live for decades in a fingernail of soil.',
        'The wild never really left the city.'),
  ], [
    'Look up, look down, and look between buildings for something alive.',
    'Find a plant growing where nobody planted it.',
    'Can you hear a bird over the traffic?',
    'Find the place on this street where an animal could drink.',
  ]),
  Habitat('trees', '🌲', 'Among trees or a park', [
    WalkAnimal('🐿', 'Squirrel', 'a spiral of claw-scratches up the bark',
        'Squirrels plant thousands of trees by forgetting where they buried acorns.',
        'Watch the tail - it talks more than the squirrel does.'),
    WalkAnimal('🪶', 'Woodpecker', 'a sound that taps against wood',
        'A woodpecker\'s tongue wraps around the inside of its skull.',
        'Follow the tapping, look at trunks, not the sky.'),
    WalkAnimal('🦉', 'Owl', 'a pellet or a downy feather at a tree\'s foot',
        'Owl feathers have soft edges so their flight makes almost no sound.',
        'By day, look for the quietest shape against the trunk.'),
    WalkAnimal('🐜', 'Ants', 'a moving thread on the bark road',
        'An ant colony can be older than the person walking past it.',
        'Follow the line both ways - one end is home.'),
  ], [
    'Find three different leaf shapes.',
    'Can you hear a sound that repeats against wood?',
    'Touch one kind of bark gently. What does it feel like?',
    'Find evidence that an animal was here.',
  ]),
  Habitat('water', '🏞', 'Near water - a pond, river or fountain', [
    WalkAnimal('🐸', 'Frog', 'a plip! and rings spreading on the water',
        'Frogs drink through their skin instead of their mouths.',
        'Sit still one minute - the pond forgets you and wakes up.'),
    WalkAnimal('✨', 'Dragonfly', 'a glitter that hovers and darts',
        'A dragonfly can fly backwards.',
        'It patrols the same route - wait, it will come back.'),
    WalkAnimal('🦆', 'Duck', 'upside-down tails and ripple trails',
        'Ducklings can swim within hours of hatching.',
        'Upside down means dinner time below.'),
    WalkAnimal('🪰', 'Water strider', 'tiny dimples walking ON the water',
        'Water striders walk on water using hairs on their feet.',
        'Look at the surface itself, not through it.'),
  ], [
    'Watch the ripples. What made them?',
    'Spot something alive above the water and something below.',
    'Listen quietly - can you hear a plip or a splash?',
    'Follow the edge of the water and find three kinds of life.',
  ]),
  Habitat('beach', '🌊', 'A beach or shore', [
    WalkAnimal('🦀', 'Crab', 'sideways tracks and little sand balls',
        'A crab\'s eyes stand on stalks so it can hide flat and still watch.',
        'Look where the wave just left - someone always hurries.'),
    WalkAnimal('🐚', 'Shellmakers', 'the empty houses on the tide line',
        'Every shell was built by its animal, one thin layer at a time.',
        'A shell is a finished house, never just a pebble.'),
    WalkAnimal('🕊', 'Gull', 'a cry that rides the wind',
        'Gulls stamp the sand like rain to trick worms up.',
        'Watch one do the rain dance.'),
    WalkAnimal('🪶', 'Sandpiper', 'stitch-stitch-stitch tracks by the foam',
        'Sandpipers chase each retreating wave to eat what it uncovers.',
        'The little sewing machine of the tide line.'),
  ], [
    'Wait for a wave to retreat and see what it uncovers.',
    'Find a track in the sand and guess who made it.',
    'Find something the sea built and something it borrowed.',
    'Close your eyes. How many different sounds is the water making?',
  ]),
];

// ---------- wonder: the prediction ----------

const wonderQuestions = [
  ('Who do you think has been here?', ['Someone with wings', 'Someone with legs', 'Someone very small']),
  ('What do you think they were doing?', ['Visiting', 'Feeding', 'Hiding', 'Building']),
  ('When do you think they come?', ['In the morning', 'In the day', 'At night']),
];

(String, List<String>) wonderFor([DateTime? now]) =>
    wonderQuestions[dailyIndex(wonderQuestions.length, 'wq', now)];

// ---------- reveal: deterministic, from the world not a roll ----------

/// Which animal the walk reveals: seeded by habitat + day + the
/// child's own answers. The same walk with the same noticing always
/// meets the same neighbor - a home, not a slot machine.
WalkAnimal revealFor(Habitat h, int observeChoice, int wonderChoice,
    [DateTime? now]) {
  final seed = 'rv${h.id}$observeChoice$wonderChoice';
  return h.cast[dailyIndex(h.cast.length, seed, now)];
}

class WalkCopy {
  static const door = '🥾 A noticing walk';
  static const doorSub = 'the world is full of neighbors - learn to see them';
  static const pause =
      'Put the phone down, or hold it at your side. Just look and '
      'listen. The walk starts with you, not the screen.';
  static const pauseA11y =
      'A quiet pause. Twenty seconds to look and listen around you. '
      'The screen will chime gently when time is up.';

  /// Honest presence: lives-here language, never is-here claims.
  static String reveal(WalkAnimal a, Habitat h) =>
      '${a.name}s live in places like this. You didn\'t need to see '
      'one - you noticed ${a.sign}. That is how real explorers meet '
      'their neighbors.';
  static const guest =
      'Every animal you meet is at home. You are the guest - '
      'a quiet, kind one.';
  static String remember(WalkAnimal a) =>
      'Could you know a ${a.name.toLowerCase()} tomorrow, without me? '
      'Here is the secret: ${a.hook}';
  static const drawIt = 'Want to draw what you noticed?';
  static const end =
      'The walk is finished, but noticing never is. The neighbors '
      'will be here tomorrow.';
}
