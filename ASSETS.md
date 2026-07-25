# Animation assets - the Lottie slots

Hopeling Kids declares named animation slots; you fill them by dropping
files into `app/assets/lottie/`, one file per slot name. Both formats
work: `.lottie` (Optimized dotLottie - the recommended download, small)
or `.json` (Lottie JSON). A slot with no file shows its fallback (emoji
or nothing), so the app is always whole - every file you add upgrades
exactly one moment, no code changes.

## How to download (premium workspace)

1. Find an animation on lottiefiles.com / app.lottiefiles.com.
2. Save to workspace → My Drafts → hover the file → ⋯ →
   **Download as** → **Optimized dotLottie** (hover the row - the
   Download button appears on the right).
3. Rename to the exact slot name below and drop into
   `app/assets/lottie/`.
4. `git reset`, `git add app/assets/lottie`, commit, `flutter run`.

Taste guide: warm, rounded, flat-illustration styles that sit well on
cream paper. Nothing neon, corporate, or busy. Prefer files under
~300KB; loops for ambient slots, single-play is fine for celebrations.

## The full shopping list

### Characters and companions
| File name | Where it lives | Search terms |
|---|---|---|
| `guide_fox.json` ✅ | Kids home - the guide (default) | have it - the waving fox |
| `guide_<id>.lottie` | The guide when the child chose that guardian: `guide_vaquita`, `guide_elephant`, `guide_tiger`... one per guardian you care about | the animal's name + "cute" |
| `owl_night.lottie` | Bedtime (wired on arrival) | "owl sleeping", "night owl cute" |

### Ambient life
| File name | Where it lives | Search terms |
|---|---|---|
| `butterfly.lottie` | Kids home sky | your monarch (in My Drafts) |
| `sun.lottie` | Kids home sky corner (the tappable sun - keep it sun-shaped, the rainbow secret depends on it) | "sun shine cute" |
| `sleepy_moon.lottie` | Bedtime header | "sleeping moon", "moon and stars" |
| `bee_flower.lottie` | Adventure decor (wired on arrival) | "bee flower" |
| `fish_bowl.lottie`* | River / ocean moments (wired on arrival) | "fish swimming cute" |

### Room welcomes (centered under each room's painted header)
| File name | Where it lives | Search terms |
|---|---|---|
| `adventure_pack.lottie` | Adventure room | "backpack adventure", "hiking", "map compass" |
| `play_time.lottie` | Play room | "kids playing", "kite flying", "balloon" |
| `reading_time.lottie` | Stories room | "book reading", "open book pages" |
| `making_art.lottie` | My Stuff room | "painting kids", "art palette brush" |

### Moments
| File name | Where it lives | Search terms |
|---|---|---|
| `celebrate.lottie` | Wind Garden full bloom + future finishes | "flower burst", "nature confetti", "sparkle celebration" |
| `cinema_ticket.lottie` | Cinema lobby (wired on arrival) | "movie ticket", "popcorn" |
| `seedling.lottie` | First-run welcome + journal moments (wired on arrival) | "seed growing", "plant sprout" |
| `star_shine.lottie` | My discoveries (wired on arrival) | "star twinkle cute" |
| `rain_gentle.lottie` | The grown-up app's Rain screen, one day | "rain cloud cute" |

✅ = file already in place. "Wired on arrival" = the slot point is
chosen; tell Claude when the file exists and it goes live in one line.
Everything else is wired now with an invisible fallback - the moment
the file lands, it appears.

## Adding future slots

Any moment can become a slot in one line:

    KidLottie(slot: 'name', size: 60, fallback: <today's widget>)

---

# The sound shelf

My synthesized sounds were horrible (Yakir, 2026). The wiring stays;
the files get replaced. Download real recordings, name them EXACTLY
as below, and drop them into `app/assets/sfx/`. An `.mp3` with the
right name automatically wins over my `.wav` fallback - no code
changes, just `flutter run` again.

## Where to download (no account needed)

- **pixabay.com/sound-effects** - real recordings, free for apps, no
  attribution, downloads as mp3. The best first stop.
- **kenney.nl/assets** (category: Audio) - CC0 zip packs, good for
  UI ticks and pops.

## The eight slots

| Save as | What to look for | Search terms | Keep it |
|---|---|---|---|
| `tick.mp3` | tiny soft click, like a fingernail on wood | "soft click", "bubble click", "wood tap" | under 0.2s, quiet |
| `drop.mp3` | one real water drop into a pool | "water drop", "drip echo" | under 0.5s |
| `pop.mp3` | small happy pop, bubble or cork | "bubble pop", "pop cartoon" | under 0.3s |
| `whoosh.mp3` | soft air swish, breath not jet | "soft whoosh", "swish air" | under 0.5s |
| `splash.mp3` | small splash, pebble in a pond | "small splash", "water plop" | under 0.8s |
| `bump.mp3` | soft muffled thud - must NOT sound like an error | "soft thud", "underwater thud" | under 0.4s |
| `chime.mp3` | gentle success bells, warm not corporate | "gentle chime", "marimba success", "wind chime short" | under 1.5s |
| `flip.mp3` | one page or card turning | "page flip", "card flip" | under 0.3s |

Rules of the shelf: nothing harsh, nothing that could read as a
buzzer or a scold, and quieter is better - the volumes are already
set in code per moment.

## Later (ambience, optional)

When we add ambient loops these names will light up the same way:
`amb_stream.mp3` (gentle brook), `amb_night.mp3` (crickets, soft),
`amb_rain.mp3` (steady gentle rain), `amb_birds.mp3` (morning
songbirds). Look for "loop" in the search; 30-60s files are ideal.
