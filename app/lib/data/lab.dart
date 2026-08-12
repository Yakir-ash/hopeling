// The Lab - "what would happen if?" made honest. Three rules,
// straight from SCHOOL.md:
//
//   SMALL    each model is a few coupled difference equations,
//            hand-tuned for qualitative truth, never pretending
//            to be a forecast
//   HONEST   every scenario says on screen that it is a model,
//            and the ones that really happened carry citations
//   DETERMINISTIC  same lever, same curves, every time - science
//            is reproducible and we do not run slot machines
//
// The curves come from the model; the words come from a human.
// Kid reskins come later and must end in repair, per the kids
// constitution.

class LabSeries {
  final String name;
  final String emoji;
  const LabSeries(this.name, this.emoji);
}

class LabMoment {
  final int step; // which season the moment belongs to
  final String text;
  const LabMoment(this.step, this.text);
}

class LabOption {
  final String label; // the lever setting, e.g. "no bees at all"
  final List<LabMoment> moments; // curated, per option
  final String epilogue;
  const LabOption(this.label, this.moments, this.epilogue);
}

class LabScenario {
  final String id;
  final String emoji;
  final String title;
  final String question; // the "what would happen if...?"
  final String leverName;
  final List<LabOption> options;
  final List<LabSeries> series;
  final String? citation; // "this really happened" line
  final String? citationUrl;
  const LabScenario({
    required this.id,
    required this.emoji,
    required this.title,
    required this.question,
    required this.leverName,
    required this.options,
    required this.series,
    this.citation,
    this.citationUrl,
  });
}

/// Twelve seasons - three years - of each tracked population,
/// normalized 0..1. Pure function of (scenario, option): no
/// randomness anywhere.
List<List<double>> simulate(String scenarioId, int option) {
  double clamp(double v) => v < 0.02 ? 0.02 : (v > 1.0 ? 1.0 : v);
  const steps = 12;

  switch (scenarioId) {
    case 'meadow':
      // lever: how many bees remain
      final b = [1.0, 0.5, 0.0][option];
      var f = 0.8, r = 0.5, x = 0.4; // flowers, rabbits, foxes
      final fs = <double>[], rs = <double>[], xs = <double>[];
      for (var i = 0; i < steps; i++) {
        fs.add(f);
        rs.add(r);
        xs.add(x);
        final fNext =
            f + (0.05 + 0.25 * b) * f * (1 - f) - 0.15 * r * f;
        final rNext = r + 0.25 * r * (f - 0.4);
        final xNext = x + 0.2 * x * (r - 0.4);
        f = clamp(fNext);
        r = clamp(rNext);
        x = clamp(xNext);
      }
      return [fs, rs, xs];

    case 'wolves':
      // lever: wolves absent / brought home
      final w = [0.0, 1.0][option];
      var e = 0.9, wl = 0.25, bv = 0.15; // elk, willows, beavers
      final es = <double>[], ws = <double>[], bs = <double>[];
      for (var i = 0; i < steps; i++) {
        es.add(e);
        ws.add(wl);
        bs.add(bv);
        final eNext =
            e + 0.10 * e * (1 - e) - 0.13 * w * e;
        final wNext =
            wl + 0.22 * wl * (1 - wl) - 0.20 * e * wl;
        final bNext = bv + 0.25 * bv * (wl - 0.3);
        e = clamp(eNext);
        wl = clamp(wNext);
        bv = clamp(bNext);
      }
      return [es, ws, bs];

    case 'sea':
      // lever: how much warmer, in degrees
      final h = [0.0, 1.0, 2.0][option];
      var c = 0.75, fi = 0.6; // coral, fish
      final cs = <double>[], fs2 = <double>[], ks = <double>[];
      for (var i = 0; i < steps; i++) {
        cs.add(c);
        fs2.add(fi);
        ks.add(clamp(fi * 0.85)); // the fishers' catch follows
        final cNext = c + 0.05 * c * (1 - c) - 0.06 * h * c;
        final fNext = fi + 0.2 * fi * (c - 0.35);
        c = clamp(cNext);
        fi = clamp(fNext);
      }
      return [cs, fs2, ks];
  }
  return const [];
}

const labScenarios = <LabScenario>[
  LabScenario(
    id: 'meadow',
    emoji: '🐝',
    title: 'The Meadow Web',
    question: 'What would happen if the bees disappeared?',
    leverName: 'The bees',
    series: [
      LabSeries('Wildflowers', '🌼'),
      LabSeries('Rabbits', '🐰'),
      LabSeries('Foxes', '🦊'),
    ],
    options: [
      LabOption('all the bees stay', [
        LabMoment(2,
            'The flowers set seed, season after season. The meadow '
                'hums.'),
        LabMoment(6,
            'Rabbits find plenty. Foxes find rabbits. The web '
                'holds its shape.'),
      ], 'A meadow with its bees is a wheel with all its spokes: '
          'it turns, and nothing about it looks like luck.'),
      LabOption('half the bees are lost', [
        LabMoment(2,
            'Fewer visits, fewer seeds. The flowers thin - not a '
                'catastrophe, a fading.'),
        LabMoment(5,
            'The rabbits notice before we would: a little less to '
                'eat each spring.'),
        LabMoment(9,
            'The foxes eat last, so they feel it last - but they '
                'feel it.'),
      ], 'Half the pollinators does not mean half the meadow - the '
          'losses travel up the web, quietly compounding.'),
      LabOption('no bees at all', [
        LabMoment(1,
            'The flowers bloom once more on stored strength - and '
                'set almost no seed.'),
        LabMoment(4,
            'The second spring is the quiet one. Wind can carry '
                'some pollen; it cannot carry a meadow.'),
        LabMoment(7,
            'The rabbits are hungry in the open. The foxes hunt '
                'longer for less.'),
        LabMoment(10,
            'What is left is green, but simple - a lawn where a '
                'library used to be.'),
      ], 'Nobody starves on day one. That is what makes it '
          'dangerous: the unraveling is slower than attention.'),
    ],
    citation:
        'Model, not prophecy - but the direction is real: about '
        'three quarters of food crops depend at least partly on '
        'animal pollinators.',
  ),
  LabScenario(
    id: 'wolves',
    emoji: '🐺',
    title: 'The Wolves Come Home',
    question: 'What would happen if the top predator returned?',
    leverName: 'The wolves',
    series: [
      LabSeries('Elk', '🦌'),
      LabSeries('Willows', '🌿'),
      LabSeries('Beavers', '🦫'),
    ],
    options: [
      LabOption('no wolves - as it was for 70 years', [
        LabMoment(2,
            'The elk graze where they please, as long as they '
                'please - especially the tender riverbanks.'),
        LabMoment(6,
            'The young willows never get past knee height. No '
                'willows, no beavers.'),
        LabMoment(10,
            'The rivers run wide, shallow, and warm. Nobody '
                'remembers them otherwise.'),
      ], 'Remove one animal and you do not get the same landscape '
          'minus one animal. You get a different landscape.'),
      LabOption('the wolves are brought home', [
        LabMoment(1,
            'The elk do not just become fewer - they become '
                'careful. They stop lingering in the open river '
                'valleys.'),
        LabMoment(4,
            'Ungrazed, the willows and aspens come back tall '
                'along the banks.'),
        LabMoment(7,
            'The beavers return to willow country and build. '
                'Ponds appear. Songbirds follow the new thickets.'),
        LabMoment(11,
            'The dammed, shaded, deepened streams change shape. '
                'It is fair to say the wolves redrew the rivers.'),
      ], 'Fear is part of an ecosystem. The elk\'s caution, not '
          'just their numbers, is what let the valleys regrow.'),
    ],
    citation:
        'This really happened: wolves returned to Yellowstone in '
        '1995, and the changes that followed are among the most '
        'studied in ecology.',
    citationUrl:
        'https://en.wikipedia.org/wiki/History_of_wolves_in_Yellowstone',
  ),
  LabScenario(
    id: 'sea',
    emoji: '🌊',
    title: 'The Warming Sea',
    question: 'What would happen if the water warmed by two degrees?',
    leverName: 'The warming',
    series: [
      LabSeries('Coral', '🪸'),
      LabSeries('Reef fish', '🐠'),
      LabSeries('The catch', '🎣'),
    ],
    options: [
      LabOption('the sea stays as it was', [
        LabMoment(3,
            'The coral builds slowly, as it has for centuries - '
                'a city that is also its citizens.'),
        LabMoment(8,
            'A quarter of all ocean fish species touch a reef at '
                'some point in their lives. The city is full.'),
      ], 'A reef is not scenery for the fish - it is nursery, '
          'pantry, and hiding place at once.'),
      LabOption('one degree warmer', [
        LabMoment(2,
            'One degree does not sound like weather. To a coral '
                'it is a fever that will not break.'),
        LabMoment(6,
            'Bleached patches appear - the coral expels its '
                'algae partners and turns ghost-white, starving.'),
        LabMoment(10,
            'The fish thin with their city. The boats work '
                'harder for less.'),
      ], 'Corals can recover from a short fever. It is the fever '
          'that stays that unbuilds the city.'),
      LabOption('two degrees warmer', [
        LabMoment(1,
            'Bleaching arrives early and broadly. The white is '
                'beautiful and terrible.'),
        LabMoment(5,
            'The reef stops being built faster than the sea '
                'unbuilds it.'),
        LabMoment(8,
            'The nursery empties; the catch follows it down '
                'within a few seasons.'),
        LabMoment(11,
            'What remains is rubble and algae - alive, but no '
                'longer a city.'),
      ], 'The people in this story are not villains - they are '
          'the third curve, the one that follows the other two.'),
    ],
    citation:
        'The direction is real: mass bleaching events on the '
        'Great Barrier Reef have followed marine heatwaves '
        'repeatedly since 1998.',
    citationUrl: 'https://en.wikipedia.org/wiki/Coral_bleaching',
  ),
];

LabScenario? labScenarioById(String id) {
  for (final s in labScenarios) {
    if (s.id == id) return s;
  }
  return null;
}
