# Hopeling: the little meadow

The brand film, as source. Everything in `film/` rebuilds from code with one command.

## The files

| File | What it is |
|---|---|
| `hopeling-film.mp4` | The main film. 91 seconds, 1920x1080, 30 fps, stereo, about 15 MB. |
| `hopeling-social.mp4` | The short cut. 30.6 seconds, same format. |
| `hopeling-loop.mp4` | A silent 12-second meadow that loops without a seam (1280x720, 0.4 MB). For a hero background or a waiting screen. |
| `poster.jpg` | The poster frame (also written to `brand/og.jpg` at 1200x630 for link previews). |
| `film.cjs` | The film itself: scenes, timings, the two cuts. |
| `render.cjs` | Draws each frame as SVG, rasterises it with sharp, pipes it to ffmpeg. |
| `score.py` | The music and the sound mix, synthesised with numpy. |
| `build.sh` | Builds everything. |

## Rebuilding

```
bash film/build.sh          # poster, main film, social cut, loop  (about 3 minutes on two cores)
bash film/build.sh main     # one cut
node film/render.cjs main still 12 38 64    # stills at those seconds, into film/out/
```

Needs node with `sharp`, python3 with `numpy`, and `ffmpeg`. The fonts are TeX Gyre Pagella and Lato, installed on the machine that renders.

## The story

The film is the Little Meadow, the first story in Hopeling Kids, told to grown-ups. The narrator is the app's own storyteller, reading the Little Meadow's own lines.

| Time | Scene | On screen | The voice |
|---|---|---|---|
| 0:00 | Dawn | Night lifts off a hillside. Flowers open, bees arrive, a rabbit, a fox. Gold threads draw between them. | "This is the little meadow. The flowers feed the bees, the bees help the flowers, and everyone needs everyone." |
| 0:13 | The question | The meadow recedes behind one sentence. | (music) "What if understanding the world changed the way we care for it?" |
| 0:18 | The name | hopeling. A companion for the living world. | |
| 0:22 | The Lab | Two benches on one clock. The bees leave bench B. Three charts draw themselves. | "The bees flew away, and the flowers made fewer seeds. Spring came up quieter. The rabbits found less to eat. Even the fox felt it, all the way at the end of the line." |
| 0:45 | School | "Nothing is learned until it is seen." Then the Errand, and a class's show of hands. | |
| 0:54 | Kids | The thin meadow at dusk. Six patches of soft ground. Six seeds. The meadow comes back and the sky warms. | "Can you help the meadow come back? Tap the soft ground and plant a wild patch. Look - the flowers found the sun, and the bees found the flowers." |
| 1:09 | Act | The eight-second card. "This one, from now on." A drop falls, and then rain. | |
| 1:17 | The close | The meadow, whole. Then the name. | "The meadow came back because someone helped. Helpers change everything." |

## What is real in it

- **The Lab sequence is the model, not a picture of it.** `film.cjs` carries the same equations and numbers as `app/lib/data/lab.dart` (the Meadow Web). The benches thin and the three lines draw from that model, sampled in time. The end figures on screen (58 and 32, 100 and 76, 88 and 73) are what the app shows.
- **The voice is the app's.** The eleven lines are the recorded narration the app ships (`audio/manifest.json`), unedited.
- **The words on the cards are the app's.** The errand, the lesson's board sentence, and the detergent card are taken from `errands.dart`, `bench.dart` and `swaps.json` (the card's pick line is shortened to fit).
- **The creatures are the website's.** One illustration library, `brand/creatures.cjs`, draws the homepage and every frame here.

## What is not

- **These are not screen recordings.** The two benches, the show of hands, the errand and the card are redrawn in the film's own style from the app's real content. The app's own screens look different (the app uses emoji as its actors). No interface in the film stands for a feature that does not exist, but nobody should take a frame of this for a screenshot.
- **The show-of-hands numbers (6, 17, 4) are an example**, not data from a class. No class has run a lesson yet.
- **The six seeds in the Kids scene are tapped by nobody.** The app's version waits for a child.

## For a second version: real captures

A cut with real device footage would be stronger in front of a school. Record these on a phone (screen recording, portrait, no notifications), drop them in `film/captures/`, and each can replace or sit beside the redrawn version of the same moment:

1. `lab.mp4` - The Lab, The Meadow Web: choose "no bees at all", guess, let the diorama play all three years. About 25 seconds.
2. `bench.mp4` - The Classroom Bench, meadow lesson: brief, six or seven hands, run, compare. About 30 seconds.
3. `kids.mp4` - Kids mode, The Little Meadow: "the bees fly away", then plant all six seeds. About 30 seconds.
4. `swap.mp4` - Act, the detergent card: open, read, "This one, from now on", the rain. About 12 seconds.
5. `home.mp4` - The hillside at dawn or dusk, held still for ten seconds, then one long press. About 15 seconds.

## Sound and rights

- **Music and effects:** original, synthesised from scratch in `score.py`. No samples, no loops, no third-party recordings, nothing to license. The "birds" are synthetic chirps, not recordings of any species.
- **Voice:** Hopeling's storyteller, a synthetic voice generated with OpenAI's text-to-speech (the "fable" voice) by `scripts/narrate.js`. The end card says so, because OpenAI's terms ask that listeners be told a voice is AI-generated.
- **Type:** TeX Gyre Pagella (GUST Font License) and Lato (SIL Open Font License).
- **Loudness:** about -15 LUFS integrated. Under narration the voice sits about 12 dB above the music.

## What has not been checked

The mix was built and measured, not listened to: the machine that rendered it has no speakers. The levels, the harmony and the timing against the voice are all correct on paper. Watch it once with sound before showing it to anyone, and if a section is too loud, too quiet or simply not to your taste, the gains are single numbers in `score.py`.
