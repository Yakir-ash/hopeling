// The Lab's library - nine experiments across seven wings, all
// running on the graph engine (lab_engine.dart). Every edge
// carries its why; every scenario carries Under the Hood; every
// number was tuned against a python mirror before shipping.
// The words are human-written and stay that way.

import 'lab_engine.dart';

export 'lab_engine.dart';

const labScenarios = <LabScenario>[
  // ================= MEADOW WING =================
  LabScenario(
    id: 'meadow',
    emoji: '🐝',
    title: 'The Meadow Web',
    wing: 'Meadow',
    question: 'What would happen if the bees disappeared?',
    leverName: 'The bees',
    steps: 12,
    predictIndex: 2, // ask about the foxes - the distal surprise
    nodes: [
      EcoNode('f', 'Wildflowers', '🌼', init: 0.8, g: 0.05),
      EcoNode('r', 'Rabbits', '🐰', init: 0.5, s: -0.10),
      EcoNode('x', 'Foxes', '🦊', init: 0.4, s: -0.08),
    ],
    edges: [
      EcoEdge('r', 'f', -0.15,
          why: 'Rabbits graze the flowers and their greens. More '
              'rabbits, harder-working meadow.'),
      EcoEdge('f', 'r', 0.25,
          why: 'The flowers and their seeds and greens feed the '
              'rabbits - a meadow in bloom is a full pantry.'),
      EcoEdge('r', 'x', 0.20,
          why: 'Foxes eat rabbits. When rabbits thin, foxes hunt '
              'longer for less - the loss travels upward.'),
    ],
    options: [
      LabOption('all the bees stay', {'f': NodeDrive(dg: 0.25)}, [
        LabMoment(2,
            'The flowers set seed, season after season. The '
                'meadow hums.'),
        LabMoment(6,
            'Rabbits find plenty. Foxes find rabbits. The web '
                'holds its shape.'),
      ], 'A meadow with its bees is a wheel with all its spokes: '
          'it turns, and nothing about it looks like luck.'),
      LabOption('half the bees are lost',
          {'f': NodeDrive(dg: 0.125)}, [
        LabMoment(2,
            'Fewer visits, fewer seeds. The flowers thin - not a '
                'catastrophe, a fading.'),
        LabMoment(5,
            'The rabbits notice before we would: a little less '
                'each spring.'),
        LabMoment(9,
            'The foxes eat last, so they feel it last - but they '
                'feel it.'),
      ], 'Half the pollinators does not mean half the meadow - '
          'the losses compound as they climb.'),
      LabOption('no bees at all', {}, [
        LabMoment(1,
            'The flowers bloom once more on stored strength - '
                'and set almost no seed.'),
        LabMoment(4,
            'The second spring is the quiet one. Wind carries '
                'some pollen; it cannot carry a meadow.'),
        LabMoment(8,
            'The rabbits are hungry in the open. The foxes hunt '
                'longer for less.'),
      ], 'Nobody starves on day one. That is what makes it '
          'dangerous: the unraveling is slower than attention.'),
    ],
    repair: RepairAct(
        'Plant the native patch',
        'A strip of native flowers, left unmowed - food and home '
            'for whatever pollinators remain.',
        {'f': NodeDrive(dg: 0.30)},
        [
          LabMoment(2,
              'The patch blooms. The surviving pollinators find '
                  'it - they were never all gone, only starving.'),
          LabMoment(7,
              'Seeds set again. Slowly: recovery climbs a hill '
                  'that decline slid down.'),
        ],
        'The meadow comes back - but compare the curves: the way '
            'back is longer than the way down. That slope has a '
            'name: hysteresis. It is the strongest argument for '
            'never needing the repair.',
        drag: 0.6),
    hood: UnderHood(
        know: 'About three quarters of the world\'s food crops '
            'and most wild flowering plants depend at least '
            'partly on animal pollinators.',
        estimate: 'How fast an unpollinated meadow thins varies '
            'by plant community; our interaction strengths are '
            'plausible mid-range values, run at 80%, 100%, and '
            '120% to draw the band.',
        simplified: 'Real meadows have wind-pollinated grasses, '
            'seed banks that wait years, other pollinators, and '
            'weather. We drew three threads from a rope of '
            'thousands.',
        uncertain: 'Trust the foxes\' curve least - predators '
            'integrate everything, including much we left out.'),
    citation:
        'Model, not prophecy - but the direction is real: about '
        'three quarters of food crops depend at least partly on '
        'animal pollinators.',
  ),

  // ================= MOUNTAIN WING =================
  LabScenario(
    id: 'wolves',
    emoji: '🐺',
    title: 'The Wolves Come Home',
    wing: 'Mountain',
    question: 'What would happen if the top predator returned?',
    leverName: 'The wolves',
    steps: 25, // years, so history can be laid over the model
    predictIndex: 1, // ask about the willows
    nodes: [
      EcoNode('elk', 'Elk', '🦌', init: 0.95, g: 0.10),
      EcoNode('wil', 'Willows', '🌿', init: 0.25, g: 0.22),
      EcoNode('bv', 'Beavers', '🦫', init: 0.15, s: -0.075),
    ],
    edges: [
      EcoEdge('elk', 'wil', -0.20,
          why: 'Elk browse young willows before they can grow '
              'tall - and without fear of wolves, they linger in '
              'the open river valleys where willows live.',
          cite: 'The "ecology of fear": predators change prey '
              'behavior, not just numbers.'),
      EcoEdge('wil', 'bv', 0.25,
          why: 'Beavers eat willow and build with it. No tall '
              'willows, no beavers - no beavers, no ponds.'),
    ],
    options: [
      LabOption('no wolves - as it was for 70 years', {}, [
        LabMoment(3,
            'The elk graze where they please, as long as they '
                'please - especially the tender riverbanks.'),
        LabMoment(12,
            'The young willows never get past knee height. No '
                'willows, no beavers.'),
        LabMoment(20,
            'The rivers run wide, shallow, and warm. Nobody '
                'remembers them otherwise.'),
      ], 'Remove one animal and you do not get the same landscape '
          'minus one animal. You get a different landscape.'),
      LabOption('the wolves are brought home',
          {'elk': NodeDrive(dl: -0.11)}, [
        LabMoment(2,
            'The elk do not just become fewer - they become '
                'careful. They stop lingering where they can be '
                'cornered.'),
        LabMoment(8,
            'Ungrazed, the willows and aspens come back tall '
                'along the banks.'),
        LabMoment(14,
            'The beavers return to willow country and build. '
                'Ponds appear. Songbirds follow the thickets.'),
        LabMoment(22,
            'The dammed, shaded, deepened streams change shape. '
                'It is fair to say the wolves redrew the rivers.'),
      ], 'Fear is part of an ecosystem. The elk\'s caution, not '
          'just their numbers, let the valleys regrow.'),
    ],
    repair: RepairAct(
        'Now remove them again (a rewind)',
        'History run backward: take the recovered valley and '
            'take the wolves away a second time.',
        {},
        [
          LabMoment(4,
              'The elk resurge within a few seasons - growth is '
                  'always faster than growing back.'),
          LabMoment(14,
              'The willows begin to fall to the browsing. The '
                  'beavers hold on - living for now on banks the '
                  'wolves built.'),
          LabMoment(22,
              'The slowest debts are still unpaid at the edge of '
                  'the chart. Unraveling outlives our window.'),
        ],
        'Recovered is not the same as safe. What took decades to '
            'rebuild begins unbuilding in years - the fragility '
            'of mended things is the lesson history keeps '
            'teaching.',
        drag: 1.0),
    realData: RealData(
        'elk',
        'Northern-range elk winter counts, normalized '
            '(approximate; real counts are bumpier - harsh '
            'winters and hunting also moved these numbers)',
        'US National Park Service annual northern-range elk '
            'counts, 1994-2019',
        {
          0: 0.95,
          1: 0.84,
          4: 0.59,
          7: 0.60,
          10: 0.42,
          13: 0.34,
          16: 0.23,
          19: 0.20,
          22: 0.27,
          24: 0.29,
        }),
    hood: UnderHood(
        know: 'Wolves returned to Yellowstone in 1995; northern '
            'range elk declined from roughly 19,000 toward '
            '4,000-6,000; riparian willows and beaver colonies '
            'increased in many (not all) valleys.',
        estimate: 'How much of the elk decline belongs to wolves '
            'versus winters, drought, bears, and hunting is '
            'still argued in the literature - our wolf-pressure '
            'strength is a mid-range reading, banded.',
        simplified: 'No bears, cougars, hunters, winters, or '
            'drought in this model; real trophic cascades are '
            'tangled ropes, and scientists still debate how '
            'strong this one is.',
        uncertain: 'The beavers\' curve is least certain - their '
            'return varied valley by valley, and other factors '
            'helped and hindered.'),
    citation:
        'This really happened: wolves returned to Yellowstone in '
        '1995. Toggle the dots to compare the model with the '
        'real counted elk.',
    citationUrl:
        'https://en.wikipedia.org/wiki/History_of_wolves_in_Yellowstone',
  ),

  // ================= OCEAN WING =================
  LabScenario(
    id: 'sea',
    emoji: '🌊',
    title: 'The Warming Sea',
    wing: 'Ocean',
    question:
        'What would happen if the water warmed by two degrees?',
    leverName: 'The warming',
    predictIndex: 2, // the catch
    nodes: [
      EcoNode('c', 'Coral', '🪸',
          init: 0.75, g: 0.05, collapseBelow: 0.28),
      EcoNode('fi', 'Reef fish', '🐠', init: 0.6, s: -0.12),
    ],
    edges: [
      EcoEdge('c', 'fi', 0.22,
          why: 'A reef is nursery, pantry, and hiding place at '
              'once - about a quarter of ocean fish species '
              'touch a reef in their lifetime.'),
    ],
    derived: [
      DerivedSeries('fi', 'The catch', '🎣', base: 0.85),
    ],
    options: [
      LabOption('the sea stays as it was', {}, [
        LabMoment(3,
            'The coral builds slowly, as it has for centuries - '
                'a city that is also its citizens.'),
        LabMoment(8, 'The nursery is full. The boats come home '
            'heavy enough.'),
      ], 'A reef is not scenery for the fish - it is the whole '
          'town.'),
      LabOption('one degree warmer', {'c': NodeDrive(dl: -0.06)}, [
        LabMoment(2,
            'One degree does not sound like weather. To a coral '
                'it is a fever that will not break.'),
        LabMoment(6,
            'Bleached patches appear - the coral expels its '
                'algae partners and turns ghost-white, starving.'),
        LabMoment(10,
            'The fish thin with their city. The boats work '
                'harder for less.'),
      ], 'Corals can survive a short fever. It is the fever that '
          'stays that unbuilds the city.'),
      LabOption('two degrees warmer', {'c': NodeDrive(dl: -0.12)}, [
        LabMoment(1,
            'Bleaching arrives early and broadly. The white is '
                'beautiful and terrible.'),
        LabMoment(5,
            'The reef is unbuilt faster than it can build.'),
        LabMoment(9,
            'The nursery empties; the catch follows it down '
                'within a few seasons.'),
      ], 'The people in this story are not villains - they are '
          'the third curve, the one that follows the other two.'),
    ],
    repair: RepairAct(
        'Cool water, shade, and a nursery',
        'The heat relents; coral gardeners plant nursery-grown '
            'fragments and shade the shallows.',
        {'c': NodeDrive(dg: 0.10)},
        [
          LabMoment(3,
              'Where the old colonies survived, the planted '
                  'fragments take hold.'),
          LabMoment(9,
              'Where the reef fell past its threshold, the '
                  'rubble grows algae faster than coral - the '
                  'door did not close entirely, but it closed '
                  'mostly.'),
        ],
        'After a collapse, restoration is planting a forest one '
            'branch at a time - possible, heroic, and no match '
            'for simply not boiling the sea.',
        drag: 0.6),
    hood: UnderHood(
        know: 'Mass bleaching events have followed marine '
            'heatwaves on the Great Barrier Reef repeatedly '
            'since 1998; sustained heat kills coral at scale.',
        estimate: 'How fast fish communities follow their reef '
            'down varies by species and place; our coupling is '
            'mid-range, banded 80-120%.',
        simplified: 'No acidity in this model (it is its own '
            'experiment, coming), no currents, no coral '
            'adaptation, no fishing pressure on top.',
        uncertain: 'The catch curve is the least certain: people '
            'change boats, gear, and species long before the '
            'last fish - human adaptability is not modeled.'),
    citation:
        'The direction is real: mass bleaching on the Great '
        'Barrier Reef has followed marine heatwaves repeatedly '
        'since 1998.',
    citationUrl: 'https://en.wikipedia.org/wiki/Coral_bleaching',
  ),

  // ================= RIVER WING =================
  LabScenario(
    id: 'beaver',
    emoji: '🦫',
    title: 'The Engineer Returns',
    wing: 'River',
    question:
        'What would happen if beavers came back to a straightened '
        'stream?',
    leverName: 'The beavers',
    predictIndex: 2, // the herons
    nodes: [
      EcoNode('p', 'Ponds and pools', '💧', init: 0.5, s: -0.04),
      EcoNode('fs', 'Fish', '🐟', init: 0.5, s: -0.10),
      EcoNode('hr', 'Herons and kin', '🪿', init: 0.4, s: -0.09),
    ],
    edges: [
      EcoEdge('p', 'fs', 0.22,
          why: 'Dammed pools are deep, cool, and slow - young '
              'fish shelter and feed where fast water would '
              'sweep them away.'),
      EcoEdge('fs', 'hr', 0.20,
          why: 'Herons, kingfishers, and otters fish the pools. '
              'The wading birds are the visible dividend of '
              'invisible engineering.'),
    ],
    options: [
      LabOption('the stream stays empty of beavers', {}, [
        LabMoment(3,
            'Unmaintained, the old pools silt in one by one. '
                'Water moves through like it is late for '
                'something.'),
        LabMoment(8,
            'Fast, shallow, warm: fine for passing through, poor '
                'for growing up. The fish thin.'),
      ], 'A stream without its engineer still flows - it just '
          'stops holding life the way a shelf without brackets '
          'stops holding books.'),
      LabOption('the beavers come back',
          {'p': NodeDrive(dg: 0.22)}, [
        LabMoment(2,
            'The first dam. It looks like a mess of sticks; it '
                'is a public works project.'),
        LabMoment(5,
            'Pools deepen and cool. Wet ground spreads sideways '
                'into the banks - the stream grows a floodplain.'),
        LabMoment(9,
            'Fish fill the slow water; the herons arrive like a '
                'verdict.'),
      ], 'One rodent with strong opinions about hydrology '
          'rebuilds the whole street. Ecologists call it a '
          'keystone; the fish would call it a landlord.'),
    ],
    hood: UnderHood(
        know: 'Beaver dams raise water tables, create wetland '
            'habitat, trap sediment, and buffer both floods and '
            'droughts - the evidence base is broad and old.',
        estimate: 'How fast the pond-to-fish-to-bird dividend '
            'pays varies with stream gradient and geology; '
            'couplings are mid-range, banded.',
        simplified: 'No floods, no droughts, no conflict with '
            'roads and fields (real beaver restoration spends '
            'most of its time on that last one).',
        uncertain: 'The birds\' curve is least certain - they '
            'have opinions and wings, and arrive on their own '
            'schedule.'),
    citation:
        'Beaver-led stream restoration is a real and growing '
        'practice across Europe and North America.',
  ),

  LabScenario(
    id: 'runoff',
    emoji: '🚜',
    title: 'The Overfed River',
    wing: 'River',
    question:
        'What would happen if the fields upstream doubled their '
        'fertilizer?',
    leverName: 'The runoff',
    predictIndex: 1, // the oxygen - the counterintuitive victim
    nodes: [
      EcoNode('a', 'Algae', '🟢', init: 0.3, s: -0.05),
      EcoNode('o', 'Oxygen', '💨', init: 0.8, g: 0.12),
      EcoNode('fs', 'Fish', '🐟', init: 0.6, s: -0.12),
    ],
    edges: [
      EcoEdge('a', 'o', -0.30,
          why: 'The villain is food: when the algal boom dies, '
              'its decomposition consumes the water\'s oxygen. '
              'Too much dinner suffocates the diner.'),
      EcoEdge('o', 'fs', 0.18,
          why: 'Fish breathe dissolved oxygen. Below a threshold '
              'they gasp at the surface, then they do not.'),
    ],
    options: [
      LabOption('the fields hold steady', {}, [
        LabMoment(3,
            'A little algae is just the river\'s garden. The '
                'oxygen holds.'),
      ], 'Nutrients are not poison - they are food. The dose '
          'writes the story.'),
      LabOption('the fertilizer doubles',
          {'a': NodeDrive(dg: 0.30, dl: 0.05)}, [
        LabMoment(2,
            'The water greens. From the bank it looks like '
                'abundance - it is.'),
        LabMoment(5,
            'The boom dies as booms do, and the decay draws '
                'down the oxygen like a held breath.'),
        LabMoment(9,
            'The fish leave or fail. The green water is quiet '
                'water.'),
      ], 'Eutrophication is the strangest murder in ecology: the '
          'weapon is food, and the death is suffocation.'),
    ],
    repair: RepairAct(
        'Plant the buffer strip',
        'A ribbon of trees and deep-rooted plants between field '
            'and water - the river\'s kidney, replanted.',
        {'a': NodeDrive(dl: -0.10)},
        [
          LabMoment(3,
              'The roots drink the runoff before the river '
                  'does. The green thins.'),
          LabMoment(8,
              'Oxygen climbs back slowly - decay finishes '
                  'before recovery begins.'),
        ],
        'A few meters of rooted ground fixes what no amount of '
            'effort in the water can. The repair was never in '
            'the river; it was on the bank.',
        drag: 0.7),
    hood: UnderHood(
        know: 'Fertilizer runoff drives algal blooms and oxygen '
            'crashes from farm ponds to the Gulf of Mexico\'s '
            'seasonal dead zone.',
        estimate: 'Bloom and decay rates vary with temperature '
            'and flow; ours are mid-range, banded.',
        simplified: 'No seasons, no flow, no toxin-producing '
            'algae (a real and separate danger), one river with '
            'no tributaries.',
        uncertain: 'The fish rebound is least certain - '
            'recolonization needs somewhere to come back from.'),
    citation:
        'The direction is real: the Gulf of Mexico dead zone, '
        'fed by Mississippi basin runoff, recurs every summer.',
    citationUrl:
        'https://en.wikipedia.org/wiki/Dead_zone_(ecology)',
  ),

  // ================= OCEAN WING (fishing) =================
  LabScenario(
    id: 'overfish',
    emoji: '🎣',
    title: 'The Bottomless Net',
    wing: 'Ocean',
    question: 'How much fishing can a fish population bear?',
    leverName: 'The fishing pressure',
    predictIndex: 2, // the catch - the paradox lives there
    slider: true, // the threshold hunt: find the cliff yourself
    nodes: [
      EcoNode('c', 'Cod', '🐟',
          init: 0.7, g: 0.16, collapseBelow: 0.10),
      EcoNode('sb', 'Seabirds', '🕊️', init: 0.5, s: -0.06),
    ],
    edges: [
      EcoEdge('c', 'sb', 0.12,
          why: 'Seabird colonies rise and fall with the fish '
              'that feed their chicks.'),
    ],
    derived: [
      DerivedSeries('c', 'The catch', '⚓', base: 0.3, mul: 2.6),
    ],
    options: [
      LabOption('light fishing', {'c': NodeDrive(dl: -0.06)}, [
        LabMoment(4,
            'The stock replaces what the boats take. This can '
                'run forever - the interest, never the '
                'principal.'),
      ], 'A fished ocean can be a full ocean. The lever has a '
          'safe range - the whole question is where it ends.',
          scalar: 0.05),
      LabOption('heavy fishing', {'c': NodeDrive(dl: -0.16)}, [
        LabMoment(2,
            'The catch is excellent. That is the trap - the '
                'boats are eating principal and calling it '
                'interest.'),
        LabMoment(7,
            'Each year the fish are smaller and further out. '
                'The birds\' colonies thin first.'),
      ], 'Decline reads as "a bad year" for a long time. The '
          'sea does not send an invoice; it just stops.',
          scalar: 0.14),
      LabOption('relentless fishing', {'c': NodeDrive(dl: -0.30)},
          [
        LabMoment(1,
            'The best catches ever recorded. Ports boom.'),
        LabMoment(5,
            'The stock crosses a line no one can see in the '
                'water. Below it, recovery physics change.'),
        LabMoment(9,
            'The boats find nothing. Not less - nothing.'),
      ], 'This curve is not hypothetical. It has a name and a '
          'date: the Grand Banks cod, 1992.',
          scalar: 0.24),
    ],
    repair: RepairAct(
        'Total moratorium',
        'All fishing stops. Everyone waits for the sea to '
            'forgive.',
        {},
        [
          LabMoment(4,
              'Nothing much happens. That is the sentence: '
                  'below the threshold, the old rules stopped '
                  'applying.'),
          LabMoment(10,
              'The ecosystem reorganized without the cod - '
                  'other species now hold the room the cod '
                  'would need back.'),
        ],
        'The Grand Banks moratorium of 1992 was meant to last '
            'two years. Three decades later the cod have still '
            'not truly returned. Some doors close - which is '
            'why the entire art is staying in the safe range of '
            'the lever.',
        drag: 0.5),
    hood: UnderHood(
        know: 'The Grand Banks cod fishery - five hundred years '
            'old - collapsed in 1992 and has not recovered '
            'despite a moratorium; 30,000 people lost their '
            'work in a season.',
        estimate: 'Where a stock\'s collapse threshold sits is '
            'genuinely hard to know before crossing it - which '
            'is the strongest argument for margins.',
        simplified: 'One stock, no ecosystem reshuffling '
            '(in reality other species occupied the cod\'s '
            'room, which is partly why it cannot return), no '
            'economics of desperate ports.',
        uncertain: 'The threshold\'s exact position - in the '
            'model AND in every real ocean.'),
    citation:
        'This really happened: the Atlantic northwest cod '
        'collapse, 1992 - the most instructive fisheries '
        'dataset ever recorded.',
    citationUrl:
        'https://en.wikipedia.org/wiki/Collapse_of_the_Atlantic_northwest_cod_fishery',
  ),

  LabScenario(
    id: 'mpa',
    emoji: '🛟',
    title: 'The Protected Third',
    wing: 'Ocean',
    question:
        'If a third of the sea is closed to fishing, do the '
        'boats starve?',
    leverName: 'The reserve',
    predictIndex: 1, // the catch - the counterintuitive answer
    nodes: [
      EcoNode('fs', 'Fish', '🐠', init: 0.6, g: 0.12),
    ],
    edges: [],
    derived: [
      DerivedSeries('fs', 'The catch', '⚓', base: 1.3, mul: -1.3),
    ],
    options: [
      LabOption('no reserve', {'fs': NodeDrive(dl: -0.12)}, [
        LabMoment(4,
            'Every reef is fished. The fish have no address '
                'where they can grow old and large.'),
        LabMoment(9,
            'Old, large fish - the ones that spawn most - are '
                'the first to vanish and the last to return.'),
      ], 'Everywhere-open is a commons running down: fine this '
          'year, thinner every year after.', scalar: 0.0),
      LabOption('a small reserve',
          {'fs': NodeDrive(dg: 0.021, dl: -0.102)}, [
        LabMoment(5,
            'Inside the lines, the fish grow older, larger, '
                'louder with eggs.'),
      ], 'Even a small no-take zone is a savings account the '
          'whole coast draws interest on.', scalar: 0.15),
      LabOption('a third protected',
          {'fs': NodeDrive(dg: 0.046, dl: -0.080)}, [
        LabMoment(3,
            'The reserve fills first - big fish, dense schools.'),
        LabMoment(7,
            'The overflow begins: fish born inside drift and '
                'swim out. Fishers call it spillover and start '
                'fishing the lines.'),
        LabMoment(10,
            'The boats fish two thirds of the water - and land '
                'roughly what they always did, from a far '
                'richer sea.'),
      ], 'The catch is no worse. The sea is far richer. That is '
          'the whole astonishing arithmetic of marine reserves - '
          'protection is not the opposite of harvest; it is its '
          'bank.', scalar: 0.33),
    ],
    hood: UnderHood(
        know: 'Well-enforced no-take reserves reliably hold '
            'more, larger, and more fecund fish inside, and '
            'spillover across their boundaries is documented '
            'worldwide.',
        estimate: 'How much spillover reaches the nets varies '
            'with species mobility and reserve design; our '
            'coupling is deliberately modest.',
        simplified: 'One stock, perfect enforcement, no '
            'displacement of effort (real fleets crowd the '
            'lines), no politics - and real reserve design is '
            'mostly politics.',
        uncertain: 'The timeline: real spillover dividends take '
            'five to ten years, and the lean years in between '
            'are exactly when reserves get repealed.'),
    citation:
        'The direction is real: documented spillover from '
        'no-take marine reserves is among the strongest results '
        'in conservation science.',
  ),

  // ================= FOREST WING =================
  LabScenario(
    id: 'fire',
    emoji: '🔥',
    title: 'The Fire Debt',
    wing: 'Forest',
    question:
        'What happens to a forest where every small fire is put '
        'out?',
    leverName: 'The fire policy',
    predictIndex: 0, // the fuel - the debt itself
    nodes: [
      EcoNode('l', 'Fuel load', '🪵', init: 0.35, s: 0.06),
      EcoNode('t', 'Old trees', '🌲', init: 0.8, g: 0.03),
      EcoNode('w', 'Fire flowers', '🌸', init: 0.4, g: 0.05),
    ],
    edges: [
      EcoEdge('l', 't', -0.10,
          why: 'Deep fuel turns every eventual spark into a '
              'crown fire that can kill even the giants that '
              'shrug off ground fire. High fuel is standing '
              'risk - this thread is that risk, chronic.'),
      EcoEdge('l', 'w', -0.12,
          why: 'The fire-followers - some with seeds that wait '
              'decades for heat to open them - are shaded and '
              'buried where litter piles unburned.'),
    ],
    options: [
      LabOption('suppress every fire', {}, [
        LabMoment(3,
            'The forest looks saved. The floor deepens with '
                'deadwood - the debt account opens.'),
        LabMoment(7,
            'The fire flowers wait underground for a heat that '
                'never comes.'),
        LabMoment(10,
            'Every unburned year raises what the eventual fire '
                'will collect. Suppression does not cancel '
                'fire; it consolidates it.'),
      ], 'A century of putting out every small fire is how you '
          'save up one unstoppable one.'),
      LabOption('let the small fires burn',
          {'l': NodeDrive(dl: -0.09)}, [
        LabMoment(2,
            'Low flames walk the floor, eating litter, '
                'sparing the thick-barked giants.'),
        LabMoment(6,
            'Lodgepole cones open in the heat - some seeds '
                'are literally locked until fire turns the '
                'key.'),
        LabMoment(10,
            'A mosaic forest: burned patches, meadows, old '
                'groves - more kinds of home than any unburned '
                'acre holds.'),
      ], 'In fire country, fire is not the forest\'s enemy - '
          'it is the forest\'s editor. The catastrophe is not '
          'flame; it is arrears.'),
    ],
    hood: UnderHood(
        know: 'Many conifer forests evolved with frequent '
            'low-intensity fire; serotinous cones (lodgepole, '
            'jack pine) require heat to open; a century of '
            'suppression has measurably deepened fuel loads '
            'across the American West.',
        estimate: 'Fuel accumulation and risk rates vary '
            'enormously by forest type; ours are mid-range for '
            'dry conifer country, banded.',
        simplified: 'The big one itself is not simulated - we '
            'show the risk as chronic pressure rather than one '
            'terrible deterministic day, and we say so '
            'plainly: real fire is weather, chance, and wind.',
        uncertain: 'The old trees\' curve - the difference '
            'between a fuel-loaded forest and a burning one is '
            'a lightning strike we do not roll dice for.'),
    citation:
        'The direction is real: fire suppression and fuel '
        'accumulation are central to the modern western '
        'megafire problem.',
    citationUrl:
        'https://en.wikipedia.org/wiki/Fire_ecology',
  ),

  // ================= ARCTIC WING =================
  LabScenario(
    id: 'ice',
    emoji: '❄️',
    title: 'The Mirror That Melts',
    wing: 'Arctic',
    question: 'What happens to sea ice as the Arctic warms?',
    leverName: 'The warming',
    predictIndex: 1, // the seals
    nodes: [
      EcoNode('i', 'Sea ice', '🧊', init: 0.85, g: 0.05),
      EcoNode('sl', 'Ice seals', '🦭', init: 0.5, s: -0.11),
    ],
    edges: [
      EcoEdge('i', 'sl', 0.16,
          why: 'Ringed seals give birth in snow dens ON the '
              'ice; no platform, no pups - and the polar bear\'s '
              'whole hunting method needs the same floor.'),
    ],
    options: [
      LabOption('no further warming', {}, [
        LabMoment(4,
            'The white mirror does its quiet planetary job: '
                'bouncing sunlight back before it becomes '
                'heat.'),
      ], 'Ice is not just habitat. It is the planet\'s '
          'reflector - the coolant is the countertop.'),
      LabOption('one degree warmer',
          {'i': NodeDrive(dl: -0.045)}, [
        LabMoment(3,
            'The melt season stretches at both ends. Dark '
                'water opens where white ice was.'),
        LabMoment(8,
            'Dark water swallows the sunlight the ice would '
                'have returned - the melting feeds the '
                'melting.'),
      ], 'The Arctic warms fastest on Earth for exactly this '
          'reason: the mirror shrinks, and its absence is a '
          'heater.'),
      LabOption('two degrees warmer',
          {'i': NodeDrive(dl: -0.08)}, [
        LabMoment(2,
            'The old thick ice - years in the making - breaks '
                'and drains away first.'),
        LabMoment(6,
            'Seal nurseries collapse with their floors. What '
                'hunts seals goes hungry inland.'),
        LabMoment(10,
            'An open dark ocean in summer: a different Arctic, '
                'with a different guest list.'),
      ], 'Every fraction of a degree here is louder than '
          'anywhere else - the feedback loop hands the '
          'thermostat its own dial.'),
    ],
    repair: RepairAct(
        'Cool it back down',
        'The one repair that works here is the biggest one '
            'there is: the warming itself reversed.',
        {'i': NodeDrive(dl: 0.02)},
        [
          LabMoment(4,
              'Sea ice, unlike a glacier, can regrow in cold '
                  'years - this door, unusually, reopens.'),
          LabMoment(9,
              'The mirror spreads; the feedback runs backward, '
                  'now helping.'),
        ],
        'Sea ice is the rare system where recovery physics are '
            'kind - IF the cold returns. The hard part was '
            'never the ice.',
        drag: 0.8),
    hood: UnderHood(
        know: 'Arctic sea ice extent and thickness have '
            'declined for four decades; the ice-albedo feedback '
            'is textbook physics; the Arctic warms several '
            'times faster than the global average.',
        estimate: 'Melt-per-degree is drawn from observed '
            'trends, mid-range, banded.',
        simplified: 'The albedo feedback itself is folded into '
            'the warming strength rather than simulated as its '
            'own loop - say it plainly: our model borrows the '
            'conclusion of physics it does not contain.',
        uncertain: 'The seals\' curve: ice seals are declining '
            'where ice is, but populations are hard to count '
            'in a place with no witnesses.'),
    citation:
        'The direction is real: Arctic sea ice has declined '
        'for four decades, and the region warms several times '
        'faster than the global average.',
    citationUrl:
        'https://en.wikipedia.org/wiki/Arctic_sea_ice_decline',
  ),
  // ================= CITY WING =================
  LabScenario(
    id: 'corridor',
    emoji: '🌉',
    title: 'The Green Line',
    wing: 'City',
    question:
        'Two parks, one road between them. What does connecting '
        'them change?',
    leverName: 'The corridor',
    predictIndex: 0, // genetic health - the invisible one
    nodes: [
      EcoNode('g', 'Genetic health', '🧬', init: 0.5, s: -0.05),
      EcoNode('h', 'Hedgehogs', '🦔',
          init: 0.4, g: 0.03, s: -0.07),
    ],
    edges: [
      EcoEdge('g', 'h', 0.10,
          why: 'A small, sealed-off population breeds with itself '
              'until old troubles surface. Fresh arrivals carry '
              'fresh genes - resilience walks in on new feet.'),
    ],
    options: [
      LabOption('two islands, as they are', {}, [
        LabMoment(3,
            'Each park holds its little population, going '
                'steady - and going nowhere.'),
        LabMoment(7,
            'Nobody new ever arrives. The gene pool is a gene '
                'puddle, and puddles shrink.'),
        LabMoment(10,
            'The decline is quiet and looks like bad luck: a '
                'thin litter, a hard winter, an empty hedge.'),
      ], 'A park can be a home or an island. The difference is '
          'not its size - it is whether anyone can leave and '
          'arrive.'),
      LabOption('plant the green line',
          {'g': NodeDrive(dl: 0.09), 'h': NodeDrive(dg: 0.06)}, [
        LabMoment(2,
            'A hedgerow, a rough verge, a dark culvert under '
                'the road - not a park, just a path.'),
        LabMoment(5,
            'The first crossing happens at night, unwitnessed, '
                'as most important things are.'),
        LabMoment(9,
            'New arrivals, new genes, new litters. Two puddles '
                'became one pool.'),
      ], 'The corridor is the cheapest trick in conservation: '
          'you do not build more habitat, you let the habitat '
          'that exists finally reach itself.'),
    ],
    hood: UnderHood(
        know: 'Habitat fragmentation is a leading driver of '
            'local extinctions, and corridors measurably '
            'increase movement and gene flow between patches.',
        estimate: 'How much flow a given corridor carries '
            'depends on species and design; our coupling is '
            'modest and banded.',
        simplified: 'Two patches, one species, no roads-kill '
            'model, no predators using the same corridor '
            '(they do - the line serves everyone).',
        uncertain: 'The timeline: genetic rescue is real but '
            'its pace varies wildly with who walks first.'),
    citation:
        'The direction is real: corridor studies from hedgerows '
        'to highway crossings show increased movement and gene '
        'flow between fragments.',
  ),
  LabScenario(
    id: 'light',
    emoji: '💡',
    title: 'The Stolen Dark',
    wing: 'City',
    question: 'What does a streetlight cost the night shift?',
    leverName: 'The lights',
    predictIndex: 2, // the songbirds - the indirect bill
    nodes: [
      EcoNode('m', 'Moths', '🦋', init: 0.6, g: 0.06, s: -0.02),
      EcoNode('ff', 'Fireflies', '✨',
          init: 0.5, g: 0.05, s: -0.02),
      EcoNode('b', 'Songbirds', '🐦', init: 0.5, s: -0.06),
    ],
    edges: [
      EcoEdge('m', 'b', 0.15,
          why: 'Moth caterpillars are the single most important '
              'nestling food for many songbirds - the night '
              'shift feeds the day shift\'s children.'),
    ],
    options: [
      LabOption('bright, all night',
          {'m': NodeDrive(dl: -0.09), 'ff': NodeDrive(dl: -0.13)},
          [
        LabMoment(2,
            'The moths orbit the lamps until morning - hours '
                'of navigation spent on a false moon, unfed '
                'and unmated.'),
        LabMoment(5,
            'The fireflies\' code of flashes is drowned out. '
                'They cannot find each other in a lit room.'),
        LabMoment(9,
            'Fewer caterpillars in spring; the songbirds '
                'raise thinner broods on the day shift\'s '
                'budget.'),
      ], 'Nothing was paved, nothing was cut. The habitat that '
          'was destroyed was the darkness itself.'),
      LabOption('shielded, warm, and dimmed',
          {'m': NodeDrive(dl: -0.03), 'ff': NodeDrive(dl: -0.04)},
          [
        LabMoment(3,
            'Hoods point the light down at the pavement, '
                'where people actually need it.'),
        LabMoment(8,
            'The garden past the fence returns to the moths. '
                'Most of the night comes back for the price of '
                'a lampshade.'),
      ], 'Light where feet are, dark where wings are - the '
          'rare environmental fix that costs nearly nothing '
          'and starts working the same night.'),
      LabOption('a dark-sky street', {}, [
        LabMoment(4,
            'The fireflies\' conversation resumes mid-'
                'sentence, as if no decades had passed.'),
        LabMoment(9,
            'Moths navigate by the true moon again; the '
                'birds\' pantry refills.'),
      ], 'Darkness is not the absence of something. To half '
          'the living world, it is the room they live in.'),
    ],
    hood: UnderHood(
        know: 'Artificial light at night measurably disrupts '
            'moth navigation and firefly signaling, and moth '
            'declines ripple to the songbirds that feed '
            'nestlings on caterpillars.',
        estimate: 'The per-lamp toll varies with spectrum and '
            'shielding; our pressures are mid-range, banded.',
        simplified: 'No spectrum modeling (blue-white is '
            'worse; warm is kinder), no migration disruption '
            '(real and large, its own story), one street '
            'standing for a city.',
        uncertain: 'The songbird curve - their pantry has '
            'more than moths in it, and we did not draw the '
            'rest.'),
    citation:
        'The direction is real: light pollution is a '
        'documented driver of insect decline, and dark-sky '
        'lighting reverses much of it immediately.',
    citationUrl:
        'https://en.wikipedia.org/wiki/Light_pollution',
  ),
  LabScenario(
    id: 'sill',
    emoji: '🪴',
    title: 'The Windowsill',
    wing: 'City',
    question: 'Can one balcony matter to anything wild?',
    leverName: 'The balcony',
    predictIndex: 1, // the wild bees
    nodes: [
      EcoNode('p', 'Blooms', '🌸', init: 0.15, s: -0.03),
      EcoNode('wb', 'Wild bees', '🐝',
          init: 0.25, s: -0.06),
    ],
    edges: [
      EcoEdge('p', 'wb', 0.22,
          why: 'A city bee\'s life is a flight between filling '
              'stations. Every blooming balcony shortens the '
              'gaps - and the gaps are what kill.'),
    ],
    options: [
      LabOption('bare concrete', {}, [
        LabMoment(4,
            'The bees pass without slowing. To them this '
                'street is the desert between oases.'),
      ], 'A city is not hostile to bees because it is a city - '
          'it is hostile where it is bare.'),
      LabOption('three pots of natives',
          {'p': NodeDrive(dg: 0.18)}, [
        LabMoment(2,
            'The first scout finds the pots within days. '
                'Word, in bee, travels.'),
        LabMoment(7,
            'A filling station now exists where a gap was. '
                'The street is a little more crossable.'),
      ], 'Three pots will not save a species. They move a '
          'number by a fraction - and every fraction on this '
          'chart is real animals, really fed.'),
      LabOption('a wild window box',
          {'p': NodeDrive(dg: 0.30)}, [
        LabMoment(2,
            'Natives, staggered blooms, no pesticide, a dish '
                'of wet sand - a service station with all the '
                'amenities.'),
        LabMoment(6,
            'Leafcutters take the petals, mason bees the mud. '
                'You are hosting species you have never heard '
                'of.'),
        LabMoment(10,
            'Chain enough sills and the map changes: a '
                'corridor made of windowsills, crossing a city '
                'no single garden could cross.'),
      ], 'This is the smallest lever in the whole Lab. Notice '
          'that it still moves - that is the entire message of '
          'this room.'),
    ],
    hood: UnderHood(
        know: 'Urban pollinator diversity responds strongly to '
            'flower availability, and native plantings '
            'outperform ornamentals; connectivity between '
            'green patches matters as much as their size.',
        estimate: 'One balcony\'s catchment is genuinely small; '
            'our couplings keep it honest - the curves move '
            'fractions, not miracles.',
        simplified: 'One sill standing for a street; no '
            'pesticide drift from neighbors; no winter; the '
            'city\'s other ten thousand balconies not yet '
            'joining in.',
        uncertain: 'The chain effect - when do many sills '
            'become a corridor? Nobody has measured the '
            'threshold; it is one of ecology\'s open small '
            'questions.'),
    citation:
        'The direction is real: urban pollinator studies '
        'consistently find that flower-rich patches, however '
        'small, raise wild bee abundance and diversity.',
  ),
];

/// The threshold hunt: build the lever setting for a slider
/// position v in 0..1. Quantized by the UI to fixed stops, so the
/// same stop always yields the same curves - a book, not a slot
/// machine. The words come from whichever preset bracket the
/// setting falls into.
LabOption leverAt(LabScenario s, double v) {
  switch (s.id) {
    case 'overfish':
      // tuned so the cliff hides around v = 0.7 - findable, but
      // only by walking toward it
      final preset = v < 0.30
          ? s.options[0]
          : (v < 0.68 ? s.options[1] : s.options[2]);
      return LabOption(
        'fishing at ${(v * 100).round()}% of the fleet\'s appetite',
        {'c': NodeDrive(dl: -0.40 * v)},
        preset.moments,
        preset.epilogue,
        scalar: 0.24 * v,
      );
  }
  return s.options[0];
}

/// The Atlas cross-links: species -> the experiment where her
/// thread runs, with the honest one-line why. Only links that
/// are true earn a place here.
const labThreads = <String, (String, String)>{
  'honeybee': ('meadow',
      'She is the lever of the whole meadow - pull her out and '
          'watch the loss climb to the foxes.'),
  'fox': ('meadow',
      'She eats last, so she feels every loss last - the top of '
          'the meadow\'s web is where all its troubles arrive.'),
  'hedgehog': ('corridor',
      'She is exactly who the green line is for - a walker who '
          'cannot cross a road, rescued by a hedgerow.'),
  'oak': ('fire',
      'Old thick-barked trees shrug off the small fires and are '
          'killed by the saved-up one - her fate is the fuel '
          'load\'s.'),
  'salmon': ('beaver',
      'The engineer\'s pools are her nursery - deep, cool, slow '
          'water is where young fish survive.'),
  'owl': ('light',
      'The night shift\'s hunter needs the night itself - and '
          'the moths her prey depend on orbit streetlamps until '
          'dawn.'),
  'admiral': ('sill',
      'A city crossing is a chain of flowers - every blooming '
          'windowsill shortens the gaps her wings must survive.'),
  'swallow': ('light',
      'She feeds on flying insects - the same night-shift '
          'insects the lamps are quietly unwinding.'),
  'frog': ('runoff',
      'She breathes through her skin - water quality IS her '
          'air, and the overfed river suffocates her first.'),
};

LabScenario? labScenarioById(String id) {
  for (final s in labScenarios) {
    if (s.id == id) return s;
  }
  return null;
}

/// The wings, in display order, with their scenarios.
List<(String, List<LabScenario>)> labWings() {
  final order = <String>[];
  final map = <String, List<LabScenario>>{};
  for (final s in labScenarios) {
    if (!map.containsKey(s.wing)) {
      order.add(s.wing);
      map[s.wing] = [];
    }
    map[s.wing]!.add(s);
  }
  return [for (final w in order) (w, map[w]!)];
}
