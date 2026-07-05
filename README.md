# 🌿 Hopeling

**Help ordinary people reduce animal suffering through practical, evidence-based daily action.**
*Hope > Fear. Every open: learn one thing, do one thing today.*

> © 2026 Yakir. All rights reserved. This repository is public for transparency and
> credibility, **not** open source: the code, content, design, and the Hopeling name
> may not be copied, modified, redistributed, or used commercially without written
> permission. Wildlife facts cite their original sources (IUCN, NOAA, etc.).

## Repository layout

| Path | What |
|---|---|
| `hopeling-web/` | **The app.** Installable, offline-capable PWA (`Hopeling.html` + `content.json` + service worker). This is the live product. |
| `hopeling/docs/` | Product strategy, design system, schema, API design, deployment guide, AI roadmap, and the Flutter+Supabase production blueprint (`07`). |
| `hopeling/HANDOFF.md` | **Read first** - self-contained context brief for continuing work (any session, any model). |
| `hopeling/STATUS.md` | One-page repo status / decision log. |

## Run it

```bash
cd hopeling-web
python -m http.server 8000
# open http://localhost:8000/Hopeling.html
```

A service worker needs http(s) - don't open the file directly.

## Deploy (free)

**GitHub Pages:** repo Settings → Pages → Source: `main` → app lives at
`https://<user>.github.io/hopeling/hopeling-web/Hopeling.html`.
Or drag `hopeling-web/` onto **app.netlify.com/drop**.

## Update content without touching code

Edit `hopeling-web/content.json`, bump `version` + `updated`, push. The app
fetches it network-first, so all installed users get new content on next open.
Species photos/summaries (Wikipedia) and sighting counts (GBIF) load live
client-side and cache on-device - no maintenance needed.

## Roadmap (short)

PWA validates the habit loop → auto-generate `content.json` from open APIs
(GitHub Actions cron) → wrap for stores with Capacitor → Flutter + Supabase
native app only if/when needed. Full plan: `hopeling/docs/07-production-blueprint.md`.
