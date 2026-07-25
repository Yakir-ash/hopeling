# The WOW Roadmap

The goal is one second of stillness: someone opens Hopeling and pauses,
because no app has ever looked back at them like a place before.

The thesis, stolen honestly from Ghibli and Nintendo: wonder is not
complexity. It is coherence plus one impossible detail. A world feels
alive when everything in it obeys the same weather, and magical when it
knows one true thing it should not know (the real moon, the real
sunset). We can do both with what we already have: procedural light and
water (proven), emoji and licensed Lottie actors (proven), pure math
(free), and restraint.

---

## The three laws of Hopeling wonder

**1. One sky, everywhere.** The app's sky is the real sky. Time of day,
real sunset, real moon phase, real season, computed on device from the
clock, no permissions, no network. A parent checks the moon outside and
it matches. That is the moment they show a friend.

**2. One wind, everywhere.** A single global wind value that every leaf,
reed, butterfly, grass blade, and cloud on a screen obeys together.
Coherence is what reads as handcrafted. Ten particle systems ignoring
each other read as a tech demo; one gust bending everything at once
reads as a place.

**3. The world notices you, gently.** Touch grass and it parts. Sit
still and life resumes. Idle is not empty: something small is always
breathing, and it never begs for attention. Animal Crossing's secret is
patience, not fireworks.

---

## Signature moments (the ones people remember months later)

**The Golden Minute.** Hopeling knows today's actual sunset. For that
one real minute, every screen turns to gold, the wind settles, and a
single quiet line appears ("The sun is setting on your forest too").
Miss it and it is gone until tomorrow. People will open the app at
sunset on purpose, and tell others to. No streak, no badge, no reward.
The minute IS the reward.

**The Tree That Grows in Real Weeks.** One personal tree on the home
screen. It grows with real actions, over real weeks, too slowly to
notice day to day, unmistakable month to month. Day 1 a seed, week 2 a
sapling, month 2 the first bird lands in it. You cannot rush it and you
cannot lose it. It becomes the reason the app is opened in January.

**The Shooting Star.** At night, rarely (a true 1 in 7 of night opens),
one star falls. Tap nothing; it just happens. Children will tell each
other it exists. Rarity is the feature; a shooting star every night is
just a screensaver.

**The Fox Falls Asleep.** Sit still on the kids' home after dark for a
minute and the guide fox circles twice, curls up, and sleeps; the
screen dims to embers. The app itself says goodnight first. Parents
will film this.

---

## Screen review, gasp-first

**Home (grown-ups).** Today: a dashboard with a sky-gradient hat.
Should be: a hillside at the real hour, tree in the foreground (the
Tree), weather passing, cards resting IN the scene like signposts, not
floating over it. The scene is the app; the UI visits.

**Kids Home.** The painted rooms are good bones. Missing: inhabitants.
A butterfly that crosses between the room cards. A bird that lands on
the top of a card, pecks twice, leaves. Touch reactions: tap the grass
and fireflies startle up (dusk), tap the pond and it ripples.

**Grove.** The golden answer-light is our best moment so far. Extend
it: after the gold fades, one new blade of grass stays. Actions leave
permanent, tiny, visible residue. Doing good literally grows the place.

**Me / story timeline.** Should read like the end of a picture book:
scroll and the sky behind the timeline moves from your first day's
season to today's.

**Bedtime.** Already the strongest mood. Add the slow blink: the whole
scene's lights dim in a breath rhythm, 4 seconds in, 6 out. Children
entrain to it without being told anything.

**Journal, missions, museum, empty states.** Nothing is ever blank. An
empty journal page has a ladybug walking across it. Finished missions
show the birds napping. An empty museum has dust motes in a sunbeam.

**Transitions.** One signature: the leaf-turn. Screens change the way a
leaf flips in wind, and the room card you tapped is the leaf. Used
everywhere, it becomes Hopeling's page-turn the way Mario's pipe is a
pipe.

---

## The roadmap

### Quick wins (1 to 2 days each)

1. **Living Sky v1.** Real time-of-day sky on both homes: dawn, day,
   golden hour, dusk, night gradients; sun and moon positioned by the
   clock; real moon phase (pure math, no permissions). The single
   highest wonder-per-line-of-code item on this list.
2. **Fireflies after sunset + the Shooting Star.** Home only, night
   only, star truly rare.
3. **The Breath.** Every home scene inhales and exhales at scale
   1.000 to 1.015 over 8 seconds. Reduced motion: off.
4. **Alive empty states.** Journal ladybug, napping birds, museum dust
   motes.
5. **Greeting that knows the sky.** "Good evening, Adam. Thin crescent
   moon tonight." Correct, every time, forever.
6. **Grass that parts.** Touch-down on home scenery scatters a few
   blades and petals with spring-back physics.

### Medium impact (1 to 2 weeks)

1. **One Wind.** Global wind vector service; migrate every ambient
   element on the two homes to it. Gusts arrive, everything leans,
   gusts pass. This is the craft item; nobody will name it and
   everybody will feel it.
2. **Ambient actor system.** A tiny scheduler that walks licensed
   Lottie and emoji actors through scenes on long random intervals:
   butterfly crossings, bird landings, a snail by the journal. One
   system, every screen.
3. **The Golden Minute.** Real local sunset (coarse, from timezone
   or an optional city pick), the gold wash, the one line.
4. **The kid weather dial.** The child sets the weather and the world
   obeys: rain with ripples, snow that settles on card tops, fog.
   Agency instead of permissions; no location ever.
5. **Season dressing.** Foliage palette and falling things (petals,
   seeds, leaves, snow) follow the real calendar on both homes.
6. **Sound identity.** The dewdrop open-chime, per-room ambience,
   soft interaction ticks. Needs one CC0 pack decision, then wiring.

### Flagship experiences (define the product)

1. **The Tree That Grows in Real Weeks.** Growth engine driven by
   grove actions, drawn stages (commissioned or Rive), birds arriving
   at milestones, a shareable seasonal portrait of your tree.
2. **The living guide (Rive).** The fox with a state machine: eyes
   follow touches, ears react to taps, sleeps after dark, sneezes
   when tickled three times. This is where the commissioned artist
   goes first.
3. **The Window.** Gyroscope parallax on the home scene: tilt the
   phone and you look INTO the hillside, layers shifting like a
   diorama. No camera, no AR framework, pure gyro. Monument Valley
   depth for one afternoon of work per scene, once layers exist.
4. **The Fox Falls Asleep** (needs the Rive fox, so it lands here).

---

## What we deliberately will not do

No confetti, no badges, no streaks, no mascot begging, no notification
"we miss you". Wonder and neediness cannot share a room. The app never
asks to be loved; it just keeps being a place worth visiting, at the
pace of a real forest.
