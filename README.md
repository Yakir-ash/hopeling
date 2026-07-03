# 🌿 WildHope

**Help ordinary people reduce animal suffering through practical, evidence-based daily action.**
*Hope > Fear. Every open: learn one thing, do one thing today.*

> © 2026 Yakir. All rights reserved. This repository is public for transparency and
> credibility, **not** open source: the code, content, design, and the WildHope name
> may not be copied, modified, redistributed, or used commercially without written
> permission. Wildlife facts cite their original sources (IUCN, NOAA, etc.).

## Repository layout

| Path | What |
|---|---|
| `wildhope-web/` | **The app.** Installable, offline-capable PWA (`WildHope.html` + `content.json` + service worker). This is the live product. |
| `wildhope/docs/` | Product strategy, design system, schema, API design, deployment guide, AI roadmap, and the Flutter+Supabase production blueprint (`07`). |
| `wildhope/HANDOFF.md` | **Read first** — self-contained context brief for continuing work (any session, any model). |
| `wildhope/STATUS.md` | One-page repo status / decision log. |

## Run it

```bash
cd wildhope-web
python -m http.server 8000
# open http://localhost:8000/WildHope.html
```

A service worker needs http(s) — don't open the file directly.

## Deploy (free)

**GitHub Pages:** repo Settings → Pages → Source: `main` → app lives at
`https://<user>.github.io/wildhope/wildhope-web/WildHope.html`.
Or drag `wildhope-web/` onto **app.netlify.com/drop**.

## Update content without touching code

Edit `wildhope-web/content.json`, bump `version` + `updated`, push. The app
fetches it network-first, so all installed users get new content on next open.
Species photos/summaries (Wikipedia) and sighting counts (GBIF) load live
client-side and cache on-device — no maintenance needed.

## Roadmap (short)

PWA validates the habit loop → auto-generate `content.json` from open APIs
(GitHub Actions cron) → wrap for stores with Capacitor → Flutter + Supabase
native app only if/when needed. Full plan: `wildhope/docs/07-production-blueprint.md`.
