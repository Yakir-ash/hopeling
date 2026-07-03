# WildHope — Project Handoff / Context Brief
_For continuing this project in a new session or with another model. Self-contained; read top to bottom._
_Last updated: 2026-07-03._

## 1. What this is
**WildHope** is a mobile-first app whose mission: *help ordinary people reduce animal suffering worldwide through practical, evidence-based daily action.* Core principle: **Hope > Fear** (celebrate progress, never guilt). Core loop: *open → learn one thing → do one action → see impact grow → keep a streak.* Covers all animals + ecosystems (wildlife, farm animals, marine life, pets, birds, pollinators, oceans, forests, freshwater, etc.).

## 2. CURRENT STATE (read this first)
The **live product is a Progressive Web App (PWA)** in `wildhope-web/`. It runs on iOS/Android via the browser, installs to the home screen, works offline, and stores progress on-device. Everything else in the repo is either a plan or superseded first-generation code.

**Three generations exist — only the PWA is "current":**
| Path | What | Status |
|---|---|---|
| `wildhope-web/` | The PWA (HTML/CSS/JS). | ✅ **LIVE — build here.** |
| `wildhope/docs/` | Design + production blueprint. | ✅ Current reference. |
| `wildhope/android/`, `wildhope/backend/`, `wildhope/android-quickstart/` | 1st-gen Kotlin app, FastAPI backend, dead demo. | 🗑️ **Deleted by owner (2026-07-03).** The FastAPI data model that informs the future Supabase schema survives in `docs/03-database-schema.md`. |

Owner profile: **solo, bootstrapped.** Chosen future native stack: **Flutter + Supabase** (not started; only pursue after the PWA validates the habit loop). See §6.

## 3. Key decisions & rationale (assumptions that were challenged)
1. **Narrow the wedge.** "Cover all animals" is the mission, but positioning is "the daily habit for the planet." Win the single-player habit loop first; breadth expands later.
2. **Sequence social; don't launch it cold.** A social network solo = cold-start + moderation liability. MVP is single-player with *asymmetric* social (share cards, global counters). UGC/community is Phase 2+.
3. **Data licensing reality (critical).** The best wildlife data is **non-commercial**: IUCN Red List (forbids commercial + restricts mobile apps), eBird, Movebank, iNaturalist CV (~200 req/mo) are all restricted. Commercial-safe sources: **GBIF, NASA, NOAA/OBIS, Global Forest Watch, Our World in Data (CC-BY), Petfinder, RescueGroups, Every.org, GDELT.** Strategy: an **owned, source-attributed editorial content layer** (this is also the moat + legal safety), plus live data only from commercial-safe APIs. Operating as/under a **nonprofit** would legitimately unlock the restricted sources.
4. **PWA is not throwaway.** It can become the real store apps via **Capacitor** (iOS + Android, adds native push/camera) or **Bubblewrap/PWABuilder** (Android APK/Play). So improving the PWA now is not wasted — it either wraps into the store apps or serves as the validated spec + content for a Flutter rewrite. Content, design, logic, and product learnings always carry over.
5. **Business model (recommended, was undecided):** structure as/under a **nonprofit** (authentic + unlocks data), launch 100% free for growth, add revenue later without paywalling the mission (Supporter membership, NGO partnerships, round-up donations).
6. **Real-time sync deferred.** Not needed for a habit app MVP; it's a Phase-2 cost tied to social presence.

## 4. The PWA — technical detail (everything a new dev needs)
Location: `wildhope-web/`. Files:
- `WildHope.html` — the entire app (HTML + inline CSS + vanilla JS, ~650 lines). No framework, no build step. (Renamed from `index.html`, which was deleted — the site root URL therefore 404s; the app URL is `/WildHope.html`. sw.js, manifest and README all point at `WildHope.html`.)
- `content.json` — **all app content** (species, actions, courses, facts, stories). Externalized so the app self-updates.
- `sw.js` — service worker. Cache `wildhope-v4`. **Cache-first** for the app shell; **network-first** for `content.json`.
- `manifest.json` + `icon-192/512/maskable.png` + `apple-touch-icon.png` — PWA install metadata + icons (icons generated with PIL). `start_url` is `./WildHope.html`.
- `README-INSTALL.md` — install + content-update instructions.

**Design system:** Material-ish, "Earth & Hope" palette (forest `#2E6B4F`, ocean `#3E6373`, terra `#F0BE8C`), dark/light via `data-theme`, rounded 20px cards, reduced-motion + a11y labels. Bottom nav: Home · Explore · Act · Learn · Me.

**State persistence:** browser `localStorage`, keys prefixed `wh_`. `SAVE_KEYS` = `xp, streak, last, done, lessons, badges, totals, causes, theme, onboarded, log, remind, lastRemind, freezes, customActions, missionWeek, missions, missionIds, lastRepair`. `log` is `{ 'YYYY-MM-DD': count }` powering the impact graph.

**Self-updating content mechanism (important):**
- On boot, `loadContent()` applies cached content immediately, then `fetch('content.json?ts=…', {cache:'no-store'})`; on success it caches to `localStorage.wh_contentCache`, calls `applyContent()` (reassigns `CATS/ACTS/COURSES/FACTS/STORIES`, recomputes `ACT_CATS`), and re-renders.
- Offline/first-run falls back to a **bundled seed** embedded in `index.html` (`BUNDLED_VERSION=1`).
- To update content for all users: edit `content.json`, bump `version` + `updated`, re-upload. No app rebuild.

**content.json schema:**
- `categories[]`: `{slug, emo, name, iucn, sum, overview, science, stats[[label,value,source]], facts[[text,source]], threats[[title,desc,source]], doing[[title,desc]], hope[[title,desc]], orgs[[name,url]], acts[slug…]}`
- `actions{slug:{t, why, imp, diff(1-3), mod(home|outdoor|online|financial), cost, min, metric(plastic_kg|carbon_kg|trees|money|animals|generic|hours), val, ev[], steps[]}}`
- `courses[]`: `{slug, t, d, badge, lessons[{t, min, body, quiz[{q, opts[], a(index)}]}]}`
- `facts[[text,source]]`, `stories[[hopeTag,title,body]]`
- Current volume: 22 categories, 19 actions, 6 courses / 18 lessons, 12 facts, 6 stories.

## 5. Features currently in the PWA
- **Home:** daily fact, personalized daily action, streak, daily challenge, weekly missions, impact graph, success story, ocean spotlight, "animals needing attention," install prompt, streak-repair banner.
- **Explore:** 22 categories → detail with 7 tabs (Overview w/ science+stats+facts + live Wikipedia "About" card, **Species**, Threats, Solutions, Hope, Act, Help/org links). **Species tab is live-enriched:** curated species lists (bundled `SPECIES` map, overridable via `categories[].species` in content.json; `categories[].wiki` overrides the Overview article title) fetch photo+summary from the Wikipedia REST API and scientific name + occurrence counts from GBIF, client-side, cached in localStorage (`wh_wiki_*`, `wh_gbif_*`, 30-day TTL) so it works offline after first view. Both APIs are CORS-open and commercially safe.
- **Act:** difficulty × modality filters; **custom user actions** ("＋ Add your own"); one-tap "I did this."
- **Learn:** 6 courses, 18 lessons w/ real teaching text + quizzes, badges on completion.
- **Me:** level/XP, streak, impact graph, 6 impact metrics, badges, **share card** (canvas image → Web Share/download), **manual impact logging**, **backup export/import (JSON)**, settings (dark mode, reminder toggle, freeze count, content-updated date).
- **Gamification:** XP + nature-themed levels, streaks with **freeze** (earn 1 per 7-day streak, auto-bridges a missed day) + **repair** (restore if you missed exactly yesterday), badges, **weekly missions** (3, rotate by week), daily challenge.
- **Search:** 🔍 top bar → searches species/actions/courses.
- **PWA:** installable, offline, dark/light, accessibility, service worker.
- All logic validated with `node --check` + headless simulations (streak/freeze math, content pipeline).

## 6. Roadmap (from the blueprint, `docs/07-production-blueprint.md`)
- **Now:** keep improving the PWA (validate the habit loop cheaply).
- **Wrap to stores:** Capacitor (iOS+Android, real push/camera) or Bubblewrap (Android) — reuses the PWA.
- **Later native (only if needed):** Flutter + Supabase (auth, Postgres, realtime, storage, edge functions) + Firebase (push/crash) + PostHog (analytics) + Codemagic (CI/CD) + Retool (admin/moderation) + Sanity (CMS).
- **Live data:** a scheduled job regenerates `content.json` from GBIF/NASA/NOAA/GFW/OWID.
- **Bigger bets:** community/UGC + moderation, species-ID from photo (custom Vertex AutoML model), AI news curator, impact calculator, NGO partner portal, schools/family modes.
- Full 105-feature scored backlog is in `docs/07-production-blueprint.md`.

## 7. Suggested next tasks (pick up here)
**Migration DONE (2026-07-03):** the project now lives in a local git repo at `C:\Users\Yakir\Documents\wildhope`, pushed to GitHub as **`Yakir-ash/wildhope`** (private repo; owner has GitHub Pro, which enables Pages on private repos — decide before renewal whether to keep Pro or make the repo public, either works).
- **Live app:** `https://yakir-ash.github.io/wildhope/wildhope-web/WildHope.html` (GitHub Pages, deploy-from-branch `main` / root; repo README renders at the site root).
- **Publish pipeline:** edit → `git add . && git commit -m "…" && git push` → Pages auto-redeploys in ~1–2 min. Content updates = edit `wildhope-web/content.json`, bump `version`+`updated`, push.
- The pre-git session folder (old Cowork outputs dir) is obsolete — the repo is the single source of truth.

**Also done (2026-07-03, same session):** GoatCounter analytics (script tag in `WildHope.html`, per-tab events; site code `wildhope` — owner must register it at goatcounter.com; dashboard at `wildhope.goatcounter.com`); root `index.html` redirect (short URL `https://yakir-ash.github.io/wildhope/` opens the app); share-on-milestone prompts (celebration sheet w/ share button at every 7-day streak multiple, level-ups ≥2, course completion — each fires once, persisted in `milestones` state key); SW now bypasses cross-origin requests (Wikipedia/GBIF/analytics), cache `wildhope-v7`.

Next tasks, in priority order:
1. Build the `content.json` **auto-generator**: script + **GitHub Actions cron workflow** pulling GBIF/NASA/NOAA/GFW/OWID → normalized content.json → commit → Pages redeploys → app self-updates. (Generator updates numbers/news/species data only; the hand-written editorial layer — hope framing, action steps — stays untouched; it's the moat.)
2. Add an **impact calculator** and **audio narration / "explain simply"** (accessibility, families).
5. When ready to ship to stores: set up **Capacitor** (config + build steps).
6. Optional: enrich content further (more species, a positive **news** section — GDELT-sourced later).

**Recent session log (2026-07-03):** app file renamed to `WildHope.html`; fixed critical weekly-missions crash (signed-shift negative index — crashed every action tap on certain weeks), repeat-action XP (+10/+5), wired daily challenge (once/day), local-midnight dates, Android back button closes sheets; added live Explore enrichment (Species tab + Wikipedia/GBIF, see §5). SW cache now `wildhope-v6`. All changes validated with node --check + headless DOM-stub simulations.

## 8. Environment gotchas (context for tooling)
- This was built in a sandbox that **cannot delete files** (only create/overwrite) — that's why `android-quickstart/` still exists. Clean it up in a real git repo.
- iOS PWA install requires **hosting over https** (a file:// won't run the service worker). Host via Netlify Drop / tiiny.host, then Safari → Share → Add to Home Screen. Android Chrome shows an Install prompt.
- True **scheduled push notifications** need the backend (Capacitor/Supabase); the current reminder only fires on app-open.
- Docs in `wildhope/docs/`: `01-product-strategy`, `02-design-system`, `03-database-schema`, `04-api-design`, `05-deployment`, `06-ai-roadmap`, `07-production-blueprint`. Repo map in `wildhope/STATUS.md`.

## 9. One-line status
_A validated, installable, self-updating PWA MVP of a hope-first wildlife-action habit app; next step is either auto-generating its content from real APIs or wrapping it into App Store / Play Store apps with Capacitor._
