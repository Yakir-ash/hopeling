# The Lab - from feature to reason-to-download

The bar Yakir set: if The Lab were important enough for Apple to
feature on its own, what would it need to become? This document
is that design. What v1 got right and keeps: deterministic
honesty (same lever, same curves), curated words over generated
ones, citations where reality is claimed, and the closing
admission that models show directions, not destinies. Everything
below grows from those roots.

---

## 1. THE ARCHITECTURE SHIFT: one engine, a web of life

v1 hardcodes each scenario's equations. That cannot scale to 25
scenarios and must not scale that way. The rebuild:

An ecosystem is a GRAPH. Nodes are populations and resources
(wolves, elk, willows, soil moisture, coral). Edges are
interactions with signs and strengths (wolves suppress elk; elk
suppress willows; willows shelter beavers). Drivers are outside
hands on the web (temperature, rainfall, pesticide, fishing
pressure) - the levers users pull. A scenario is: a graph + which
drivers are exposed + the curated narrative layer.

Why this is the whole unlock:

- EVERY EDGE CARRIES ITS OWN "WHY" AND ITS OWN SOURCE. Tap the
  wolves->elk thread: "predators change prey behavior, not just
  numbers - the ecology of fear" + citation. The cause-and-effect
  explorer Yakir asked for is not a feature built next to the
  model; it IS the model, made tappable. Scientific credibility
  becomes architecture: we cite interactions, not vibes.
- New scenarios become content, not code: define nodes, edges,
  drivers, words. The co-founder can eventually draft one.
- The same graph renders at every depth: kid diorama, family
  prediction game, adult curves, expert bench.

## 2. THE DIORAMA: see the world, lift the hood - SIGNATURE

Charts stop being the first thing you see. The primary view is a
drawn, living scene rendered FROM the simulation state: the
meadow has actually-fewer flower sprites in year two; bees thin
from the air; the fox appears rarely, then not at all; in the
river scene the water's tint clears as the wetland filters it;
the reef pales sprite by sprite. Seasons pass visibly - the same
Dawnlight watercolor language as everything we make.

Then LIFT THE HOOD: a pull-up reveals the science underneath -
the curves, the numbers, the uncertainty ribbons, the citations.
The picture IS the data; the chart is its x-ray. Kids may never
lift the hood and still learn; experts may live under it.

This is the screenshot Apple features. Nobody else ships it.

## 3. THE SCIENTIST'S LOOP: predict, test, explain - SIGNATURE

No experiment runs until you have guessed.

1. PREDICT: before the lever pulls, the app asks: what happens
   to the willows? You sketch it - literally drag a finger to
   draw your expected curve (or, simpler tier: rises / falls /
   holds). No grading, ever. Your sketch is saved.
2. TEST: run. The diorama plays your three (or thirty) years.
3. COMPARE: your sketched line appears ghosted next to the
   model's. Sometimes you were right. The app treats both
   outcomes identically: "Here is where your line and the
   model's part ways - want to see why?"
4. EXPLAIN: tap through the chain (the graph edges) that
   produced the difference.

Every completed loop writes a LAB PAGE into the Field Guide: "I
predicted the beavers would starve. The model grew them. The
thread I missed: willows." The scientist's notebook, as
artifact. Over months a person literally watches their own
ecological intuition sharpen - without one point scored.

## 4. HONEST UNCERTAINTY: three runs, no dice - SIGNATURE

Ecology is not perfectly predictable, and pretending otherwise
would break our soul. But randomness disguised as science is
banned. The resolution comes from how real science communicates:

Every scenario runs THREE deterministic times: with cautious,
best-estimate, and severe published parameter values. The chart
shows a band, not a line - "scientists' range of expectation" -
exactly how climate projections are honestly shown. Same lever,
same band, every time.

And every scenario carries UNDER THE HOOD, a fixed four-part
panel, hand-written:
- What we know (well-established, cited)
- What scientists estimate (the parameter ranges we used)
- What this model simplifies (named omissions: disease, weather,
  migration...)
- Where the uncertainty lives (which curve to trust least)

No other consumer nature product tells users what its model
cannot do. That candor IS the differentiation.

## 5. WHAT ACTUALLY HAPPENED: model meets history - SIGNATURE

Scenarios based on real events carry a comparison mode: the real
observations drawn as DOTS over the model's LINE. Yellowstone:
the published elk count trajectory after 1995, plotted against
the user's simulation, with the differences honestly visible -
"the real decline was bumpier: harsh winters and hunting also
moved the numbers; a model isolates one thread from the rope."
Timeline cards with dated photographs where rights allow.

First candidates with real published datasets (small, static,
cited, shipped in-app - no live APIs needed for history):
- Yellowstone wolves: NPS northern-range elk counts, wolf
  population, and the riparian recovery literature
- Coral: NOAA bleaching event years on the Great Barrier Reef
- Overfishing: the Grand Banks cod collapse curve (the most
  instructive fisheries dataset ever recorded, and it teaches
  thresholds brutally well)
- Reforestation: Costa Rica forest-cover reversal
- DDT and raptors: bald eagle recovery after 1972 (repair-mode
  history: humanity has already fixed one of these)

Teaching "model versus observation" is a scientific literacy
lesson almost nothing in consumer software attempts.

## 6. REPAIR: the second act, everywhere - SIGNATURE (kids: law)

Every scenario has a repair act. After degradation, the bench
turns: restoration levers appear (replant natives, protect the
reserve, reconnect the corridor, reduce the runoff, reintroduce
the beaver). Two honest physics rules make repair the deepest
lesson in the Lab:

- HYSTERESIS: recovery curves are slower than damage curves.
  The way back is longer than the way down. (True, and the
  single most motivating fact in conservation.)
- THRESHOLDS: some pushes cross a line after which the old
  levers stop working - the meadow reassembles; the cod, within
  a lifetime, did not. Finding these cliff edges is a feature
  (see Threshold Hunt below), and their existence is stated,
  not dramatized.

For kids the constitution is extended: a kid scenario CANNOT END
in the degraded state. The repair act is the finale, always -
"can you help it come back?" - and the fable voice closes on
recovery. Humans can harm; humans can mend; a seven-year-old
leaves with the second fact on top.

## 7. THE LIBRARY: wings and benches

The Lab becomes a building in the Schoolhouse with ecosystem
WINGS, each holding experiments at three depths:

- Tier 1 - one lever (v1 style, the doorway drug)
- Tier 2 - three or four interacting levers
- Tier 3 - the Open Bench: all levers, the hypothesis journal,
  the uncertainty band controls, real-data overlays

The wings and their first experiments:

🌾 MEADOW: bees (v1) -> T2: pollinators x pesticide x rainfall x
   mowing (the interaction people must feel: pesticide plus
   drought is not pesticide-and-drought added - stressors
   multiply; this one insight justifies the whole T2 system)
🏞️ RIVER: the beaver (ecosystem engineer); fertilizer runoff ->
   algal bloom -> oxygen crash (eutrophication is wonderfully
   teachable: the villain is food); wetland added/removed as the
   river's kidneys
🌊 OCEAN: warming (v1); acidity (the other CO2 problem - shells
   dissolve before anything looks dramatic); overfishing with
   the threshold hunt; the marine protected area (spillover: the
   reserve that fills the nets OUTSIDE it - the counterintuitive
   star of the wing)
🪸 REEF: restore coral (repair-first scenario: nursery + shade +
   patience vs warming pressure)
🌲 FOREST: deforest vs reforest; wildfire and recovery (fire as
   part of the system, not its end - lodgepole cones NEED heat;
   the surprising lesson is that suppressing every fire loads
   the big one); the old-growth long-now
🐺 MOUNTAIN: wolves (v1) + real-data overlay
🌿 WETLAND: drain vs restore; the flood that the marsh would
   have swallowed (storm surge slider)
🏙️ CITY: the sneaky-important wing, because users live here -
   pavement vs gardens (heat + runoff), light pollution (moth
   and migration cost; darkness as habitat), the wildlife
   corridor (connect two parks with one green line and watch
   genetics and populations flow), the pollinator windowsill
   (smallest scale in the Lab: one balcony, real effect)
❄️ ARCTIC: ice-albedo feedback (the loop that feeds itself -
   the cleanest teachable feedback loop on Earth)
🦁 SAVANNA: elephants as landscape architects; remove them and
   watch the bush close over the grassland
🌵 DESERT: the crust (the living soil skin one footstep breaks
   and decades rebuild - patience physics)
🌳 RAINFOREST: the flying rivers (forests MAKE rain downwind -
   deforestation here is drought there; teaches action at a
   distance)

Invasives get scenarios in three wings (the cane toad pattern:
introduction is easy, removal is not - an asymmetry lesson) so
users meet the concept where it lives, not as an abstraction.

## 8. INVESTIGATION MECHANICS (beyond predict-test-explain)

- THRESHOLD HUNT: "find the most fishing this stock can bear."
  The user moves the lever hunting the cliff edge; the discovery
  IS the lesson (nonlinearity, MSY, tipping points). No score -
  the found threshold is written into the lab page.
- THE TWO BENCHES: run two settings side by side, split screen.
  This is the concept of a CONTROLLED EXPERIMENT itself, turned
  into UI. "Same meadow, one difference." Ask any scientist
  what the Lab should teach first - it is this.
- THE LONG NOW: a time-scale switch - 3 years / 30 / 100. Fast
  variables (algae, insects) vs slow ones (soil, old growth,
  cod). Some curves only tell the truth at 100 years; showing
  that is a lesson about patience no chart usually teaches.
- SEEDED BY YOUR SKY: default rainfall and temperature start
  from the user's real season and region (almanac + Hub area) -
  "your meadow begins in your August." The Lab and the world
  interlock.

## 9. LEARN -> EXPERIMENT -> UNDERSTAND -> ACT

Every wing ends by turning to the user's world:
- Pollinator lab -> the Errand engine issues a pollinator errand
  and the pollinator-garden mission opens
- Wetland lab -> the Hub surfaces wetlands near the user's area
- Plastic and runoff labs -> existing Missions link in
- Native-plants lab -> the Atlas opens on the user's regional
  species; city wing -> the corridor mission ("find the green
  line between your two nearest parks")
- Atlas pages link BACK: any species that is a node in a graph
  shows "see her role in the web" -> opens the Lab with her
  thread highlighted

## 10. DEPTHS FOR AUDIENCES (one engine, four rooms)

- KIDS: dioramas only, one big friendly lever, fable narration,
  repair-always endings, no charts, no percentages, tactile
  planting (drag flowers in). Lives in their Games/Adventure
  rooms, never labeled school.
- FAMILIES: the prediction game aloud - "everyone guess before
  we pull" - plus one discussion question per scenario, written
  for a parent to read out.
- ADULTS: everything above the hood plus everything below it.
- THE OPEN BENCH (advanced): all drivers, parameter ranges
  shown, real datasets overlaid, and the model's own equations
  readable in plain language ("elk next season = elk + growth -
  wolf pressure x fear factor"). We are the only app that would
  dare show its math. Show the math.

## 11. THE CLASSROOM BENCH (the school pilot's demo) - BUILT

Teacher mode: the class predicts by show of hands (A/B/C on the
board), the teacher pulls the lever on the projector, the room
watches the diorama answer. Then the two-bench comparison for
"what if we had done less/more." This is the single best
demonstration of Hopeling School that can exist in a classroom,
and it is a rendering mode, not a new engine.

SHIPPED, and it went further than the sketch above. The Bench
runs the LESSON, not the learner, in six moves:

- BRIEF: the sentence for the board, the honest running time,
  the group assignments, and the one thing lesson plans never
  print - WHAT THE ROOM USUALLY SAYS FIRST, plus why that first
  answer is a reasonable one. A teacher should never be
  surprised by her own material.
- HANDS: the whole room predicts at once, counted in public,
  long-press to take one back. The question is COMPARATIVE
  ("compared with bench one, where does this line finish?"),
  because a comparison is the only question a controlled
  experiment can actually answer. Bench one is always the
  control, so a lesson may never ask about it.
- RUN: every group's lever runs simultaneously, side by side,
  on ONE clock. The controlled experiment stops being a concept
  and becomes furniture.
- COMPARE: where the room stood, where the model stands, and
  the disagreement stated as the BEST outcome, not the failed
  one. No percentage right, no marks, no names, nothing stored.
- DISCUSS: three prompts revealed one at a time so nobody reads
  ahead (notice, explain, carry it outside), with every thread
  of the web listed underneath in plain words so a sharp
  question from the back row never has to wait.
- CLOSE: the repair act run in front of them, the hysteresis
  visible, and one sentence left standing in the room.

Twelve lesson plans, one per experiment, hand-written. The
physics are not softened for a classroom any more than they are
for a seven-year-old (see the Little Meadow): same engine, same
three honest runs, same thresholds. We changed who is holding
the question, and nothing else.

Files: `data/bench.dart` (the plans, the comparative verdict,
the reading of the room), `features/school/classroom_bench.dart`
(the six-move session), doors from the Schoolhouse hall and from
every Lab page that carries a plan.

## 12. THE UNASKED IDEAS

- THE BENCH JOURNAL AS A CALIBRATION MIRROR: because every loop
  stores predict/observe/explain, the Lab can occasionally
  reflect: "Six months ago you predicted rivers would not care
  about wolves. Today you predicted the beavers first." Not a
  score - a mirror. Software that shows you your own scientific
  growth in your own words may be the most durable retention
  mechanic we will ever build, and it costs a text diff.
- ECO-HISTORY REWINDS: scenarios that run BACKWARD from the
  present: start with today's Yellowstone and remove the wolves
  again; start with the recovered eagle and re-ban-then-unban
  DDT. Teaching by undoing history makes the fragility of
  recovered things visceral.
- THE HUMAN NODE: in every graph, one node is us - the farmer's
  yield in the meadow, the fisher's catch (v1 already does
  this), the city's flood bill in the wetland, the tourist
  economy on the reef. Never villain, never hero: a node in the
  web like everyone else. The quiet lesson underneath the whole
  Lab: we are not outside the graph.

## 13. WHAT I WOULD ACTUALLY BUILD, IN ORDER

1. ENGINE: the graph core (nodes/edges/drivers, three-run
   bands, thresholds, repair acts) - port the three v1 scenarios
   onto it; tests port with them.
2. PREDICT-TEST-EXPLAIN v1 (rises/falls/holds tier) + lab pages
   into the Field Guide.
3. THE DIORAMA for the Meadow wing (painter work; one wing
   done beautifully beats five done adequately).
4. WHAT ACTUALLY HAPPENED for Yellowstone (real elk data,
   in-app, cited) + Under the Hood panels for all scenarios.
5. WAVE ONE of new scenarios on the engine, chosen for spread:
   beaver river, eutrophication, overfishing + threshold hunt,
   marine protected area, wildfire, ice-albedo, corridor, light
   pollution, pollinator windowsill. (Nine, each = graph + words.)
6. REPAIR ACTS everywhere + the kids' meadow reskin (their
   first Lab toy, repair-always).
7. TWO BENCHES + LONG NOW + curve-sketch prediction.
8. City wing complete; classroom bench mode; Open Bench.

The words - every moment, every Under the Hood panel, every
citation - stay human-written and review-gated, like everything
in this app that a person is meant to trust.

## 14. What the Lab must never become

No randomness dressed as realism. No doom porn - severity is
shown, never performed. No gamified destruction (wrecking an
ecosystem must never be satisfying juice; the diorama degrades
quietly, and the interesting act is always repair). No fake
precision - bands, not false confidence. No unsourced claims of
reality. And no kid ever left standing in the ruins.
