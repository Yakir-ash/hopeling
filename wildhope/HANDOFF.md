# WildHope — Project Handoff / Context Brief
_For continuing this project in a new session or with another model. Self-contained; read top to bottom._
_Last updated: 2026-07-04._

## 0. START HERE (state as of the last session)
- **Repo:** `C:\Users\Yakir\Documents\wildhope` (this folder). GitHub `Yakir-ash/wildhope`, currently **private** (Pages needs active Pro while private — flip public or move to Netlify before Pro lapses).
- **Live app:** `https://yakir-ash.github.io/wildhope/wildhope-web/WildHope.html` (short URL `…/wildhope/` redirects to it).
- **Current versions:** app shell `APP_V v23` / SW cache `wildhope-v23`; content.json `version 5` (39 actions, 7 courses, 17 facts, 22 categories, hand-curated `news[]`).
- **Pending at handoff:** commit `283ffff` (grove + Home refocus, v23) is committed locally but **not pushed** — the session sandbox couldn't reach GitHub (proxy 403). Owner must run `git push`.
- **Publish:** `git add . && git commit -m "…" && git push` → GitHub Pages auto-deploys (~1–2 min, occasionally flaky — re-run the Action). Phone updates on 2nd launch after deploy; check the version in the **Me** tab footer.
- **Pending push at handoff time:** README.md + this HANDOFF.md have uncommitted edits — commit them.
- **Every shell/content change is validated** with `node --check` + a headless DOM-stub simulation before committing (see any recent session log entry). Keep `APP_V` in sync with the SW cache version on every shell change; bump both.
- **Deferred deliberately:** content.json auto-generator (owner shelved it; hand-curated for now); the three integrity tweaks (day-based badges, diminishing daily XP) — only the honesty-cue of that set was done. Recommended actual next step: **a week of real daily use + watch GoatCounter**, then let data drive the roadmap. Other parked items: Capacitor store-wrap (real push, ends the update dance), iOS/Safari pass, local content-refresh script.

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

**Grove companion + focused Home (2026-07-04):** "Your Grove" — a living companion card at the top of Home. Grows with the *current* streak through 8 stages (🌰 seed → 🌲 ancient grove, emoji scales with stage, gentle CSS sway, ✨ when today's action is done). **Friends** (🐦🐝🦋🐿️🦔🦊🦉🦌) arrive at streak milestones 7/14/21/30/45/60/90/120 and are keyed to *best-ever* streak — a broken streak makes the tree "rest" (never die) but friends stay: hope > fear. Friend arrivals announced once in the action toast (persisted in `milestones` as `friend<N>`). Tap grove → sheet with stages, friends grid, next-milestone countdown (`groveNextText()`, friend wins ties). Home reordered to a core loop: repair banner → grove → fact → action → challenge (full-width); install/recap/backup banners + missions/news/spotlight/attention moved below; duplicate streak mini-card removed. Owner explicitly deferred the integrity tweaks (day-based badges, diminishing XP) — single-player, not worth it now. SW `wildhope-v23`. **Sandbox gotchas hit this session:** (a) large-file mount sync stalled (WildHope.html stuck truncated at old byte-length on Linux side; fixed by splicing mount content + HEAD tail and copying back); (b) mount forbids `unlink` — stale `.git/index.lock` blocks git ops, but `mv` (rename) works: `mv .git/index.lock .git/lockjunk` before each add/commit; leftover `lockjunk*`/`index.lock.old` files in `.git/` are harmless; (c) `git push` blocked by proxy → owner pushes from Windows.

**Tappable badges (2026-07-04):** every badge in the Me gallery opens a detail sheet — plain-language "how to earn it", progress bar (or "Earned ✓"), and a CTA button routing to Act / Home / the specific course. `badgeDefs()` is the single source; `openBadge(i)` renders detail. SW `wildhope-v22`.

**Explore groups + more actions (2026-07-04):** Explore grid now grouped: 🌊 Oceans & marine life / 🌳 Land & wild / 🏡 Closer to home (unknown future slugs fall into "More"). content.json **v5**: actions 29→39 (walk/bike trips, green energy plan, nest box, plant milk, cold wash, fashion detox, local seasonal meal, write representative, volunteer hour, tree-planting search engine), wired into categories. Also: honesty cue on first-ever action; Explore category sheet merged 7→5 tabs (Threats & Hope = challenge→doing→hope story arc); year graph removed from Home (kept in Me). SW `wildhope-v21`.

**Content batch + Home polish (2026-07-04):** Home "Ocean Spotlight" replaced with a **Hope Spotlight** that rotates daily through all categories' hope items and taps into the category. content.json → **v4**: actions 19→29 (compost, brake-for-wildlife, bird-safe windows, secondhand, no-mow, microplastic-free, rain-garden, citizen-science, shade coffee, fence gap — each wired into relevant categories), new 7th course **"Living with Urban Wildlife"** (🦔, 3 lessons), facts 12→17. Validated: no dangling act refs, all action/quiz shapes valid, full render of loaded content across every tab. SW `wildhope-v18`. NOTE: the bundled offline seed inside WildHope.html is still the older set (fine — content.json overrides on load; only a first-run *offline* user sees the smaller seed).

**Retention v2 (2026-07-03):** badge gallery in Me (all badges incl. course badges visible; locked = greyed with n/m progress); weekly recap banner on Home at each new week (last-7-days actions/days, share + dismiss, `recapWeek` state); backup nudge banner on Home (xp≥50 and no export for 14+ days; export/import set `lastBackup`). Home merged "Success story" into Good news (stories are the fallback when `news[]` empty); dark-mode contrast fixed (`button{color:inherit}` + light text on dark-green surfaces). Owner set repo back to **private** (Pages requires active Pro — flip public or move to Netlify before Pro lapses). Copyright notice added to README (all rights reserved, not open source). SW `wildhope-v17` / `APP_V v17`.

**SW update fix (2026-07-03):** service worker install now fetches the shell with `cache:'reload'` — without it, a new SW could populate its cache from the browser HTTP cache (GitHub Pages `max-age=600`) and permanently serve a stale shell (this bit us: phones stuck on an old version). Cache `wildhope-v14`. Keep `APP_V` (Me footer) in sync with the SW cache version on every shell change.

**Good news section (2026-07-03, same session):** hand-curated feed on Home (top 3 shown), driven by `news[]` in content.json — item shape `{d, tag, t, x, src, url?}`, newest first; bundled `NEWS` seed for offline first-run; add items → bump `version`+`updated` → push (no app rebuild). Also: visible app version in Me footer (`APP_V`, keep in sync with SW cache version) + "app updated, reopen" toast; search-result race fixed (results no longer call closeSheet before opening). SW cache `wildhope-v13`, content.json `version:3`.

**Impact calculator (2026-07-03, same session):** Me tab → "🔮 Impact calculator" sheet. Habit simulator (any action × frequency → yearly impact with tangible equivalences: CO₂→km driven, plastic→bags, trees→CO₂/yr) + "Your pace" projection from `state.log`/`state.totals` (needs ≥3 active days, else friendly fallback). SW cache `wildhope-v10`. **Decision: the content.json auto-generator (former task #1) is deprioritized by the owner** — hand-curated content continues; revisit later.

**Retention bundle (2026-07-03, same session):** today's action rotates to the next undone action (walks the pool from the daily index); onboarding lands the user directly in their first action sheet; Settings has a **calendar reminder** — prompts for a time, downloads a recurring-daily `.ics` (works with the app closed; real push waits for Capacitor). SW cache `wildhope-v8`.

**Also done (2026-07-03, same session):** GoatCounter analytics (script tag in `WildHope.html`, per-tab events; site code `wildhope` — owner must register it at goatcounter.com; dashboard at `wildhope.goatcounter.com`); root `index.html` redirect (short URL `https://yakir-ash.github.io/wildhope/` opens the app); share-on-milestone prompts (celebration sheet w/ share button at every 7-day streak multiple, level-ups ≥2, course completion — each fires once, persisted in `milestones` state key); SW now bypasses cross-origin requests (Wikipedia/GBIF/analytics), cache `wildhope-v7`.

Next tasks, in priority order:
1. Build the `content.json` **auto-generator**: script + **GitHub Actions cron workflow** pulling GBIF/NASA/NOAA/GFW/OWID → normalized content.json → commit → Pages redeploys → app self-updates. (Generator updates numbers/news/species data only; the hand-written editorial layer — hope framing, action steps — stays untouched; it's the moat.)
2. Add an **impact calcula