# Hopeling V2 - the simplification audit

Written after reading every screen in `app/lib`, the content model,
the drops engine, and the site builder. Not a wish list: every
verdict below names a file. The standard is the one Yakir set:
five minutes should feel incredibly simple, six months should still
not reach the bottom.

The rule that decided most verdicts: **a thing earns a place on a
top-level surface only if it is a job, not a feature.** Features
live behind jobs. Containers are not organization.

---

## 1. The verdicts, feature by feature

### The shell (`main.dart`)
Five tabs: Grove, Me, Explore, Act, School.
**KEEP.** Five jobs: your place, yourself, the world, doing, learning.
The clutter is inside the tabs, not in the count.

### Home - the Hillside (`home/hillside_home.dart`, `grove/grove_screen.dart`)
**KEEP, and protect.** It already obeys "things, not cards": the
real sky, the wonder as a signpost note, the mystery as footprints,
your path as leaf markers, the species out on the hill, the shy one
who comes for a still hand. Below it: the tree, today's fact, the
Thumb Promise. That is the entire home, and it is right.
**IMPROVE (one thing only):** the guardian species is absent
(co-founder's catch, confirmed: it lives only in Me). She belongs on
the hill as a resident behaving by the real hour - asleep at noon if
an owl, out at dusk if a fox. The hill's vertical band map makes
overlap impossible by construction, so this needs a visual pass on
a device, not a blind edit. **Not built in this round; specified in
section 8.**
**REMOVE from Home:** nothing. And nothing gets added to solve
discoverability. Home answers "what is meaningful today", full stop.

### Me (`me/me_screen.dart`)
**SIMPLIFY.** Fourteen doors. It is a junk drawer wearing a nice
gradient. The rows:
- My Field Guide - **KEEP.** This is the notebook; it is the one
  thing Me is for.
- The rain - **KEEP.**
- Year-of-action graph - **KEEP.**
- Guardian row - **KEEP** until the hill takes her.
- "While you were here" and "Impact calculator" - **MERGE into the
  Rain screen.** Both are the same job: what did my drops mean.
- "Your field record" (Missions) - **RELOCATE** to Act, where
  Missions already live. It is the same screen reached twice.
- My door (Doorkeeper), Account, Robin, Circles, Kids mode,
  Feedback, Freshen - **KEEP, as one quiet "Rooms" card.**
- "Freshen the world" - **REMOVE** as a visible row; pull-to-refresh
  exists everywhere it matters.
Result: Me = notebook, rain, guardian, one rooms card. Six things.

### Explore - the Atlas of worlds (`explore/*`)
**KEEP.** Twenty-eight worlds with atmospheres, species pages,
search. This is the encyclopedia and it is good.
**MERGE (naming):** there are TWO things called "Atlas" - this one,
and the almanac's ten hour-aware neighbours (`atlas/atlas_screen.dart`,
reached from School as "Atlas: who is awake now"). Kids already call
the second one "The Neighbors". **Rename the almanac species
"Neighbours" everywhere adults see it, and give it a shelf at the
top of Explore ("awake right now").** One word for one thing.
**IMPROVE (connection):** a species page should show her thread in
the Lab (the almanac species already do, via `labThreads`) and,
where one exists, the everyday decision that reaches her
(this-not-that). Built this round for the almanac species.

### Act (`act/*`)
**KEEP.** The shelf of approved actions, each carrying its why and
an honest impact line. Near You (the Hub) and Missions are correctly
housed here.
**SIMPLIFY:** two rows of chips (difficulty x place, nine chips)
above the shelf. The engine already ramps difficulty by experience
(`maxDifficulty`), so the difficulty row is a control for a thing
the app already decides. **Remove the difficulty chips; keep place.**
**ADD (this round):** This-not-that as Act's second shelf - three
cards, adults only. Section 5.

### The Hub - Near You (`hub/*`)
**KEEP.** It is a product inside the product (863 + 374 + 175 lines),
but it is the whole answer to the doorkeeper's "an animal" door, and
it has its own privacy law. It stays behind Act and the doorkeeper,
never on Home.

### Missions (`missions/*`)
**KEEP.** Real field work is the strongest kind of act. **IMPROVE:**
reachable from the Lab's repair acts and from swaps (section 7).

### Circles (`circles/*`)
**KEEP, quietly.** Social is not why people come; it is why some
stay. One row in Me's rooms card. Not on Home, not in Act.

### Rain (`rain/*`)
**KEEP.** Absorbs the impact calculator and the "while you were
here" story (both are "what my drops meant").

### Robin - reminders (`robin/*`)
**KEEP.** It is settings with a name. One row in Me's rooms.

### Doorkeeper (`home/doorkeeper.dart`)
**KEEP.** Asked once, changeable in Me. It is the only
personalization signal we have besides behaviour, and School V2 uses
it (section 3).

### Guardian (`guardian/*`)
**KEEP, RELOCATE to the hill** (see Home). The screen itself is good.

### Field Guide (`fieldguide/*`)
**KEEP.** It is the memory of the whole app: notes walked, neighbours
met, mysteries solved. School V2's "continue" reads from it. It must
never become a trophy case - that rule is already in its comments.

### Paths (`paths/*`) and Journeys/courses (`learn/reader_screen.dart`, content.json)
**MERGE at the interface.** Two systems doing one job: structured
learning. Paths are hand-written walks with field notes earned;
Journeys are the co-founder's courses, chapters read. They differ in
code and should stay separate in code. They must not be two doors.
**One shelf, "Go deeper", listing paths and journeys as one kind of
thing: a walk with chapters.** Built this round.

### Mysteries (`mystery/*`)
**KEEP.** Weekly, five clues, deterministic. It already lives on the
hill as footprints. It does not need a second door in School.

### The Errand (`school/errand_card.dart`, `data/errands.dart`)
**KEEP, and promote.** It is the School's first law made real. It is
the first thing in School V2, not the third.

### The Lab (`school/lab_*`, `diorama.dart`, `two_bench.dart`, `data/lab*.dart`)
**KEEP.** The jewel. Twelve experiments, three living worlds, the
threshold hunt, the Two Benches. Its own screen stays exactly as it
is. In School it is one job: "Experiment", headlined by this
fortnight's experiment.

### The Classroom Bench (`school/classroom_bench.dart`)
**KEEP, RELOCATE.** A teacher's tool does not need a door in a
family hall. It moves inside the Lab screen as "For teachers".
Built this round.

### The Listening Post (`school/listening_post.dart`)
**KEEP.** It is the five-minute experience on the days the calendar
picks it, and it is always reachable from "Everything in the
Schoolhouse". It loses its own hall door. Built this round.

### The Notice Board (`learn/learn_screen.dart`)
**REMOVE.** Four pins: today's wonder, the species of the hour,
this week's mystery, this fortnight's experiment. The first three are
ALREADY ON THE HILL as things you can tap. The Notice Board is a
text copy of Home, one tab over. The fourth pin becomes the
headline of the Experiment job. The board goes. Built this round.

### The hall doors row (Mystery / Atlas / My Guide)
**REMOVE.** Mystery is on the hill. Atlas (the neighbours) moves to
Explore. My Guide is in Me. Three doors to three places that already
have doors. Built this round.

### Kids (`kids/*`)
**KEEP the five rooms** (Home, Adventure, Games, Stories, My stuff).
It is already the right shape: a child never sees a list of
features, only rooms with a few things in them.
- Home room: the sky, the guide animal, tonight's story, one small
  thing - **KEEP.**
- Adventure: explore the wild, the neighbours, one small thing -
  **SIMPLIFY:** "one small thing" appears in Home AND Adventure.
  Remove it from Adventure. Built this round.
- Games: memory meadow, pond hopper, river keeper, salmon run, the
  little meadow - **KEEP.** Every one obeys the constitution.
- Stories: comic, cinema, bedtime - **KEEP.**
- My stuff: journal, field guide - **KEEP.**
Nothing in Kids inherits the adult structure, and it must not.
**Missing from Kids, worth adding later:** more repair-always
reskins of Lab wings (the valley, the reef) as games - the meadow
proved the pattern.

---

## 2. What School is actually for

Five jobs, in the order a person needs them:

1. **Do one thing outside today** - the Errand. The first law.
2. **Continue** - the walk you were on, or the experiment you
   guessed at and never repaired.
3. **Five minutes of wonder** - one short thing, chosen by the
   calendar: a voice to learn by ear, a mystery clue, an experiment's
   question, a neighbour awake right now.
4. **Experiment** - the Lab, headlined by this fortnight's experiment.
5. **Go deeper** - paths and journeys as one shelf of walks.

That is the whole front of the Schoolhouse. Below it, one quiet line:
"Everything in the Schoolhouse" - a plain list of every room (Lab,
Listening Post, Mysteries, Paths, Journeys, Classroom Bench). The
library is enormous; the door is five things and a line.

**What a new user does first:** the Errand (it needs no account, no
content, no decision). Then "Five minutes".
**What an experienced user does:** "Continue" is at the top and
knows where she stopped.
**Where the Lab belongs:** job 4, one door, and inside the door its
own full screen unchanged.
**Where short interactive things belong:** job 3, one at a time,
deterministic by day, never a carousel.
**Where full courses belong:** job 5, beside paths, as walks.
**What is NOT visible on School's front:** the Notice Board, the
Atlas, the Field Guide, the Mystery door, the Classroom Bench, the
Listening Post door, the list of every journey. All reachable, none
shouting.
**What is surfaced elsewhere:** wonder/mystery/species (Home),
neighbours (Explore), notebook (Me).

---

## 3. Discovery without carousels

School V2 uses three signals it already has:
- **the calendar** (every "five minutes" pick is deterministic by
  day, like everything else in the app - a book, not a slot machine),
- **the notebook** (what was earned, met, solved, guessed - the Field
  Guide and the Lab's remembered guesses tell "Continue" where you
  were),
- **the door** (the doorkeeper's answer: "wonder" leans the
  five-minute pick toward the Listening Post and Mysteries; "act"
  leans it toward an experiment with a repair act).

No feed, no recommendations engine, no "for you". Understanding the
user here means remembering what she did and knowing what day it is.

---

## 4. Home V2 hierarchy (unchanged in shape, sharpened in law)

1. The place: sky, hills, and at most FIVE things in it - the wonder
   note, the mystery footprints, your path marker, the species of the
   hour, and (once built) your guardian as a resident.
2. The one thing: today's action, the Thumb Promise.
3. The one fact.
4. Nothing else, ever. A new feature never earns a Home slot by
   being new. It earns one by being what today is for.

---

## 5. This-not-that - built this round

**What it is:** the everyday decision as a card, for adults, in Act.
Three cards to start: **laundry detergent** (the frog, the overfed
river), **the garden** (the hedgehog, slug pellets and sprays), **the
apple** (the honeybee, and the shine that stops you looking).

**The 8-second surface:** one thing to avoid, one thing to prefer,
one pick, one neighbour, one tap. "Why?" is a door, never a
paragraph on the card.

**The decision is the act.** Tapping "this one, from now on" runs the
same completion path as any action: `rules.complete`, a drop, the
rain, the pulse. We never verify purchases and never will. We witness
a decision.

**The knowledge is infrastructure, not copy.** One file,
`app/assets/knowledge/swaps.json`, is the single source of truth.
The app reads it as an asset. The site builder reads the same file
and publishes `/swaps/<id>/` (cited, dated, human-readable) and
`/swaps.json` (machine-readable, beside content.json). Every card
carries: ingredients to avoid (with aliases so a label can be read),
traits to prefer, the pick, the nearby alternative, the consequence
in one line, the neighbour species and the Lab experiment it lives
in, the existing action it feeds, sources, a reviewed date, and a
reviewer. Nothing is generated. Everything is dated.

**No ranking exists, so revenue cannot corrupt one.** The pick is a
trait ("says phosphate-free on the front"), and the schema has an
optional, dated `link` slot for the day a verified product is named.
It is empty today, on purpose.

---

## 6. Connections - journeys, not tabs

Built this round, all as one-line doors, none as new containers:
- **Lab -> swap:** the runoff experiment's repair act ("plant the
  buffer strip") now ends with "the buffer strip in your kitchen"
  (the detergent card). The meadow's repair act leads to the garden
  card. Same for corridor -> garden.
- **Swap -> Lab and neighbour:** every card's "why?" opens the
  species and the experiment where her thread runs.
- **Swap -> mission/action:** every card names the existing action
  it strengthens (`cold-wash`, `reduce-pesticides`) so a decision
  can become a habit on the shelf.
- **Neighbour -> swap:** an almanac species page shows "one decision
  that reaches her".
- **Explore -> neighbours:** the hour-aware species get a shelf at
  the top of the Atlas.

Proposed, not built: Missions detail -> the swap that prevents the
thing being surveyed (litter, runoff); the Field Guide as the
"continue" memory for the Lab (today the Lab remembers guesses on
its own, and that is enough).

---

## 7. What we are missing (genuine value, not clutter)

1. **The Long Record** (first signs, class mode) - the measurement
   layer for the six-week school program and the only feature that
   makes the app worth more every year. Next build.
2. **The guardian on the hill** - specified above; needs a device.
3. **One continue-state for the whole app** - not a screen, a small
   store the notebook writes and every "continue" reads. School V2
   starts it (paths and Lab); Explore and Missions should join.
4. **The Keeper's Desk** - a child's question, answered by a person
   in a day. Later, and only with a human at the desk.

Not missing, and should stay missing: a product database, a Games
tab for adults, a feed, streak guilt, any kind of score.

---

## 8. Guardian on the hill - the spec (for the device pass)

Slot: the visitors' strip (top 212, height 36) currently holds two
met species and the shy one at centre. The guardian takes the
greeting row instead, as a small resident beside the greeting text,
behaving by the hour: `hourState(guardian, now)` returns
sleeping/awake/out based on the species' real rhythm from the
almanac where it exists, else day/night. Tap opens GuardianHome. No
new band; no overlap with the strip. One sprite, one tap.

---

## 9. Built in this round (the clearly beneficial set)

- This-not-that: knowledge file, Dart model, three cards, the 8-second
  UI, "why?" door, decision -> drops, Act shelf, Lab and Neighbour
  cross-links, public pages, `/swaps.json`, tests.
- School V2 front: five jobs + one line; Notice Board removed; hall
  doors removed; Paths and Journeys as one "Go deeper" shelf;
  Classroom Bench moved inside the Lab; Listening Post reached via
  "five minutes" and the room list.
- Act: difficulty chips removed.
- Explore: "Neighbours" shelf at the top; the almanac species renamed
  Neighbours for adults.
- Me: rows trimmed to notebook, rain, guardian, one rooms card;
  impact calculator and "while you were here" reached from Rain.
- Kids: duplicate "one small thing" removed from Adventure.

Deferred with a reason: the guardian on the hill (needs a device),
the Long Record (next, and it deserves its own round).
