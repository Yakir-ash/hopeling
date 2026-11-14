# The Hopeling look

One identity, used by the website (`index.html`, `site.css`) and the film (`film/`). If something new is drawn for Hopeling, it starts here.

## The idea

A naturalist's field guide that is alive. Paper, ink, and a meadow that keeps the real hour.

## Colour

| Name | Hex | Used for |
|---|---|---|
| Ink | `#16241C` | Text. Never pure black. |
| Paper | `#FAF8F2` | The page. Never pure white for large areas. |
| Fern | `#2E6B4F` | The one brand colour: actions, emphasis, the italic line of a headline. |
| Fern deep | `#1E4533` | Dark panels (the teacher's card, the constitution). |
| Moss, Sage | `#5E9B79`, `#9CC5A8` | Hills. Never text. |
| Mint | `#B2F1CC` | Soft highlights, on dark panels only as text. |
| Gold | `#E8B04B` | The sun, and focus rings. Sacred: never a button. |
| Rust, Sand, Cream, Blush | `#C8683A`, `#E2CFB4`, `#FFF6E0`, `#F2B8A0` | Creatures and petals only. |
| Dusk | `#23304F` | Hopeling Kids, and nothing else. |

One colour leads on every surface: paper by day, fern-deep or dusk for the two dark rooms. Gradients appear in exactly one place, the sky.

## Type

- **Hopeling Serif** (TeX Gyre Pagella): headlines, the wordmark, anything said with feeling. Regular weight for headlines, never bold. The second half of a headline is italic and fern: *"Nothing is learned / until it is seen."*
- **Hopeling Sans** (Lato): everything you read rather than feel. Kickers are 12px, bold, uppercase, tracked 0.2em, fern.
- Files and licences: `fonts/`.

## Illustration

`brand/creatures.cjs`. Paper-cut shapes: flat colour, no outlines, no gradients, no shadows. Every creature is a few ellipses and one or two paths, drawn facing right from the point where it touches the ground. If a new animal needs more than about ten shapes, it is too detailed.

The cast so far: flower, bee, rabbit, fox, frog, hedgehog, bird, tree, cloud, sprout, drop.

## Motion

Only living things move. Flowers sway, bees drift, stars twinkle, a number draws itself when the model produces it. Panels, cards and headlines arrive once (a short rise and fade) and then hold still. Nothing bounces, nothing loops for decoration, and everything stops for `prefers-reduced-motion`.

## Voice

Plain sentences. The claim first, the reason second. No exclamation marks, no superlatives, and no dash wider than a hyphen. When Hopeling does not know something or has not built it, it says so on the page.

## The sky

The homepage draws the visitor's own sky from their own clock (dawn, day, dusk, night), the same way the app does. It is the one piece of personalisation on the site and it uses nothing but the time.
