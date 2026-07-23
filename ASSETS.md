# Animation assets - the Lottie slots

Hopeling Kids declares named animation slots; you fill them by dropping
Lottie .json files into `app/assets/lottie/`, one file per slot name.
A slot with no file simply shows its emoji fallback, so the app is
always whole - every file you add upgrades exactly one moment, no code
changes.

## How to get files

1. Go to lottiefiles.com and search the terms below.
2. Filter to FREE animations. Free files ship under the Lottie Simple
   License (commercial use allowed, no attribution required). Avoid
   anything marked premium unless you buy it.
3. Download as **Lottie JSON** (not dotLottie, not GIF).
4. Save into `app/assets/lottie/` with the exact slot name:
   e.g. `guide_fox.json`.
5. `flutter run` - the slot lights up. Commit the json files.

Taste guide: pick warm, rounded, flat-illustration styles that sit
well on cream paper. Skip anything neon, corporate, or busy.

## The slots

| File name | Where it lives | Search terms | Fallback today |
|---|---|---|---|
| `guide_fox.json` | Kids home - the guide beside the speech bubble | "cute fox", "fox idle" | 🦊 drifting |
| `guide_<id>.json` | Same spot when the child chose a guardian (e.g. `guide_vaquita.json`) | the animal's name | its emoji |
| `butterfly.json` | Kids home sky - ambient life | "butterfly flying" | season emoji |
| `sleepy_moon.json` | Bedtime header | "sleeping moon", "moon stars" | (empty) |
| `celebrate.json` | Wind Garden full bloom (more moments will reuse it) | "confetti nature", "flower celebration", "sparkle burst" | 🌼 |

## Adding future slots

Any new moment can become a slot in one line:

    KidLottie(slot: 'name', size: 60, fallback: <today's widget>)

Good candidates next: journal save, comic end page star, walk reveal,
river clear, rain-on-glass for rainy-day home.
