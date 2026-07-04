# WildHope - Project Handoff / Context Brief
_For continuing this project in a new session or with another model. Self-contained; read top to bottom._
_Last updated: 2026-07-04._

- **STYLE RULE (owner, 2026-07-04): never use em dashes (U+2014) or en dashes (U+2013) anywhere in this project - app content, docs, commit messages, UI strings. Use regular hyphens (-). All 339 existing ones were replaced on 2026-07-04.
## 0. START HERE (state as of the last session)
- **Repo:** `C:\Users\Yakir\Documents\wildhope` (this folder). GitHub `Yakir-ash/wildhope`, currently **private** (Pages needs active Pro while private - flip public or move to Netlify before Pro lapses).
- **Live app:** `https://yakir-ash.github.io/wildhope/wildhope-web/WildHope.html` (short URL `…/wildhope/` redirects to it).
- **Current versions:** app shell `APP_V v32` / SW cache `wildhope-v32`; content.json `version 10` (39 actions, 7 courses, 21 lessons, 17 facts, 26 categories, hand-curated `news[]`).
- **Pending at handoff:** commits `283ffff` (grove + Home refocus, v23), `c1ba2bf` (handoff), `dac22e3` (photo hero, v24) are committed locally but **not pushed** - the session sandbox couldn't reach GitHub (proxy 403). Owner must run `git push`.
- **Publish:** `git add . && git commit -m "…" && git push` → GitHub Pages auto-deploys (~1-2 min, occasionally flaky - re-run the Action). Phone updates on 2nd launch after deploy; check the version in the **Me** tab footer.
- **Pending push at handoff time:** README.md + this HANDOFF.md have uncommitted edits - commit them.
- **Every shell/content change is validated** with `node --check` + a headless DOM-stub simulation before committing (see any recent session log entry). Keep `APP_V` in sync with the SW cache version on every shell change; bump both.
- **Content auto-refresh is LIVE (2026-07-04, owner un-shelved it):** `scripts/refresh-content.mjs` + `.github/workflows/content-refresh.yml` - weekly (Mon 06:00 UTC) + manual-dispatch GitHub Action pulls positive conservation headlines from GDELT into `news[]` (allowlisted outlets only, positive/negative keyword gates, https-only, sanitized, deduped, capped at 12, auto version bump, hard validation gate refuses bad writes; 12-check selftest runs in CI first). Owner chose full auto-commit, no PR review. Editorial layer still hand-written, never touched by the bot. Rollback = git revert the bot commit. NOTE: never live-tested from the dev sandbox (network blocked) - the first Actions run is the real test; check the Actions tab after Monday or trigger manually.
- **Deferred deliberately:** integrity tweaks (day-based badges, diminishing daily XP) - owner explicitly passed (single-player, cheating only hurts yourself). Recommended actual next step: **a week of real daily use + watch GoatCounter**, then let data drive the roadmap. Other parked items: iOS/Safari pass, local content-refresh script.
- **DECIDED (2026-07-04): the store path is Capacitor.** Owner confirmed the end goal is real iOS + Android apps and the PWA→Capacitor wrap is the agreed route (not a Flutter rewrite; that stays a distant only-if-needed option). When owner says go: Capacitor config + icons/splash, migrate localStorage → Capacitor Preferences (iOS eviction safety), wire native push, add haptics, then store-readiness pass (screenshots, privacy policy, Apple guideline 4.2 headroom). Needs Apple Dev $99/yr + Play $25 + Mac access for the iOS build.

## 1. What this is
**WildHope** is a mobile-first app whose mission: *help ordinary people reduce animal suffering worldwide through practical, evidence-based daily action.* Core principle: **Hope > Fear** (celebrate progress, never guilt). Core loop: *open → learn one thing → do one action → see impact grow → keep a streak.* Covers all animals + ecosystems (wildlife, farm animals, marine life, pets, birds, pollinators, oceans, forests, freshwater, etc.).

## 2. CURRENT STATE (read this first)
The **live product is a Progressive Web App (PWA)** in `wildhope-web/`. It runs on iOS/Android via the browser, installs to the home screen, works offline, and stores progress on-device. Everything else in the repo is either a plan or superseded first-generation code.

**Three generations exist - only the PWA is "current":**
| Path | What | Status |
|---|---|---|
| `wildhope-web/` | The PWA (HTML/CSS/JS). | ✅ **LIVE - build here.** |
| `wildhope/docs/` | Design + production blueprint. | ✅ Current reference. |
| `wildhope/android/`, `wildhope/backend/`, `wildhope/android-quickstart/` | 1st-gen Kotlin app, FastAPI backend, dead demo. | 🗑️ **Deleted by owner (2026-07-03).** The FastAPI data model that informs the future Supabase schema survives in `docs/03-database-schema.md`. |

Owner profile: **solo, bootstrapped.** Chosen future native stack: **Flutter + Supabase** (not started; only pursue after the PWA validates the habit loop). See §6.

## 3. Key decisions & rationale (assumptions that were challenged)
1. **Narrow the wedge.** "Cover all animals" is the mission, but positioning is "the daily habit for the planet." Win the single-player habit loop first; breadth expands later.
2. **Sequence social; don't launch it cold.** A social network solo = cold-start + moderation liability. MVP is single-player with *asymmetric* social (share cards, global counters). UGC/community is Phase 2+.
3. **Data licensing reality (critical).** The best wildlife data is **non-commercial**: IUCN Red List (forbids commercial + restricts mobile apps), eBird, Movebank, iNaturalist CV (~200 req/mo) are all restricted. Commercial-safe sources: **GBIF, NASA, NOAA/OBIS, Global Forest Watch, Our World in Data (CC-BY), Petfinder, RescueGroups, Every.org, GDELT.** Strategy: an **owned, source-attributed editorial content layer** (this is also the moat + legal safety), plus live data only from commercial-safe APIs. Operating as/under a **nonprofit** would legitimately unlock the restricted sources.
4. **PWA is not throwaway.** It can become the real store apps via **Capacitor** (iOS + Android, adds native push/camera) or **Bubblewrap/PWABuilder** (Android APK/Play). So improving the PWA now is not wasted - it either wraps into the store apps or serves as the validated spec + content for a Flutter rewrite. Content, design, logic, and product learnings always carry over.
5. **Business model (recommended, was undecided):** structure as/under a **nonprofit** (authentic + unlocks data), launch 100% free for growth, add revenue later without paywalling the mission (Supporter membership, NGO partnerships, round-up donations).
6. **Real-time sync deferred.** Not needed for a habit app MVP; it's a Phase-2 cost tied to social presence.

## 4. The PWA - technical detail (everything a new dev needs)
Location: `wildhope-web/`. Files:
- `WildHope.html` - the entire app (HTML + inline CSS + vanilla JS, ~650 lines). No framework, no build step. (Renamed from `index.html`, which was deleted - the site root URL therefore 404s; the app URL is `/WildHope.html`. sw.js, manifest and README all point at `WildHope.html`.)
- `content.json` - **all app content** (species, actions, courses, facts, stories). Externalized so the app self-updates.
- `sw.js` - service worker. Cache `wildhope-v4`. **Cache-first** for the app shell; **network-first** for `content.json`.
- `manifest.json` + `icon-192/512/maskable.png` + `apple-touch-icon.png` - PWA install metadata + icons (icons generated with PIL). `start_url` is `./WildHope.html`.
- `README-INSTALL.md` - install + content-update instructions.

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
- **Wrap to stores:** Capacitor (iOS+Android, real push/camera) or Bubblewrap (Android) - reuses the PWA.
- **Later native (only if needed):** Flutter + Supabase (auth, Postgres, realtime, storage, edge functions) + Firebase (push/crash) + PostHog (analytics) + Codemagic (CI/CD) + Retool (admin/moderation) + Sanity (CMS).
- **Live data:** a scheduled job regenerates `content.json` from GBIF/NASA/NOAA/GFW/OWID.
- **Bigger bets:** community/UGC + moderation, species-ID from photo (custom Vertex AutoML model), AI news curator, impact calculator, NGO partner portal, schools/family modes.
- Full 105-feature scored backlog is in `docs/07-production-blueprint.md`.

## 7. Suggested next tasks (pick up here)
**Migration DONE (2026-07-03):** the project now lives in a local git repo at `C:\Users\Yakir\Documents\wildhope`, pushed to GitHub as **`Yakir-ash/wildhope`** (private repo; owner has GitHub Pro, which enables Pages on private repos - decide before renewal whether to keep Pro or make the repo public, either works).
- **Live app:** `https://yakir-ash.github.io/wildhope/wildhope-web/WildHope.html` (GitHub Pages, deploy-from-branch `main` / root; repo README renders at the site root).
- **Publish pipeline:** edit → `git add . && git commit -m "…" && git push` → Pages auto-redeploys in ~1-2 min. Content updates = edit `wildhope-web/content.json`, bump `version`+`updated`, push.
- The pre-git session folder (old Cowork outputs dir) is obsolete - the repo is the single source of truth.

**Explain-simply toggle v28 / content v6 (2026-07-04):** persisted `state.simple` (in SAVE_KEYS) swaps category science blurbs and lesson bodies for plain-language kid variants. `simpleText(full,simple)` returns simple only when the toggle is on AND a variant exists (else full - safe offline/first-run). `simpleChip(ctx)` renders the "🧒 Explain simply" chip on each lesson + category Overview (only where a variant exists); `toggleSimple(kind,slug,i)` flips state and reopens that exact view. Global on/off also in Me > Settings. content.json **v6**: `sci_simple` on all 22 categories, `body_simple` on all 21 lessons (opens the app to kids/families, ties to the schools/family audience in the blueprint). NOTE bundled offline seed in WildHope.html has no simple variants - chip just won't show for a first-run *offline* user until content.json loads. Sim gotcha: `catTab` writes to `#catBody` not the sheet root, assert against that element. Shell `APP_V v28` / SW `wildhope-v28`.

**Content v7 - 4 new categories v29 (2026-07-04):** 22→26 categories: 🦇 Bats, 🐸 Frogs & Amphibians, 🦋 Butterflies & Moths, 🌾 Wetlands. Each full-schema incl. `sci_simple` (kid mode), `species[]` + `wiki` (overrides bundled SPECIES/CAT_WIKI for live Wikipedia/GBIF enrichment), acts wired to existing slugs only. Explore `GROUPS` in WildHope.html updated so all 26 place cleanly (wetlands/frogs → Land & wild, butterflies/bats → Closer to home; nothing lands in the "More" fallback). Validated with a dedicated content sim (`outputs/simc.js`): parses, all 26 cats render every tab via real `applyContent`, no dangling action refs, simple-mode swap works on new cats. content.json **v7**, shell `APP_V v29` / SW `wildhope-v29`. Note: bundled offline seed in WildHope.html is still the old set (fine - content.json overrides on load).

**Sheet flash fix v27 (2026-07-04):** owner-reported: tapping a badge showed the main screen for a split second before the sheet appeared. Cause: `.sheet.open` used the opacity `fade` animation (transparent first frames over the page) + `openSheet` called `window.scrollTo(0,0)` (background visibly jumped to top). Fix: opaque `sheetin` transform-only slide-up + `s.scrollTop=0` instead of window scroll - background keeps its scroll position, so closing a sheet returns you where you were. Shell `APP_V v27` / SW `wildhope-v27`.

**Fact/photo match v31 (2026-07-04):** owner noticed the Home hero photo (daily index 'p') and today's fact (daily index 'f') rotated independently, so the animal in the photo rarely matched the fact. content.json v9: each `facts[]` entry gets a category slug as a 3rd element (`[text, source, slug]`); `fillFactPhoto()` now looks up today's fact's category and photographs that, falling back to the 'p' daily rotation for the one intentionally-untagged fact (hedgehog, idx 13) and offline first-run. Bundled seed FACTS in WildHope.html tagged too. Note: `render()` only reads `f[0]`/`f[1]`, so the extra element is safe. Shell `APP_V v31` / SW `wildhope-v31`.

**Celebration burst v26 (2026-07-04):** `celebrateBurst()` - 18-particle leaf/sparkle emoji burst (`.burst` fixed overlay, `bfall` keyframes via CSS vars `--dx/--dy/--rot`, auto-removed after 1.2s) + `navigator.vibrate(35)`, fired from `doAction` and `doChallenge` before the toast. Skips particles under prefers-reduced-motion (haptic still fires); whole thing try/catch'd. Sim gotcha: Node 21+ has a native read-only `navigator` global - stub it with `Object.defineProperty(globalThis,'navigator',{configurable:true,value:…})`, plain assignment silently no-ops. Shell `APP_V v26` / SW `wildhope-v26`. Remaining from the improvement list: seasonal events (#2), share card v2 (#3), explain-simply (#4), grove keepsakes (#5), content batch (categories/news/facts/course).

**Seasonal events + tree rings v32 / content v10 (2026-07-04):** (a) content.json `event` block (`{id,emo,name,from,to,desc,badge:[emo,name],missions:[{id,t,n,xp,acts?}]}`) drives a Home banner (under grove, above fact) with days-left + progress bars; `bumpEvent(slug)` hooks doAction/doChallenge/manual-log; missions with `acts` match those slugs, without = any action; each mission pays XP once; all done -> limited badge appended to `state.eventBadges` (`[[emo,name,eventId]]`), shown in badge gallery (in-progress while active), celebration sheet. Shipped **Plastic-Free July 2026** (to 2026-07-31). Future events = content-only. New state keys: `eventProg`, `eventBadges`. (b) **Tree rings**: broken streaks >=3 days recorded via `addRing` in touchStreak (`state.rings` `[{n,end}]` cap 24, newest first); `migrateRings()` at boot derives history from `state.log` once (rings===null sentinel); shown in the grove sheet with month/year. (c) **`scripts/sim.js` is now versioned in the repo** (repo-relative paths) - run `node scripts/sim.js` from anywhere; 85 checks. Both parallel sessions should use/extend IT, not /tmp copies.

**Photo hero fix v25 (2026-07-04):** blind 640px thumb rewrite failed silently when the original image was smaller (Wikimedia won't upscale) - owner saw gradient-only on the 'Ocean' day. `heroTry(c,title,onFail)` now runs a fallback chain: 640px → raw thumbnail (`Image.onerror`) → first curated species article of the category. All three paths sim-tested. Shell `APP_V v25` / SW `wildhope-v25`.

**Photo hero (2026-07-04, same session):** the Home fact card is now the screen's single photo moment - `fillFactPhoto()` (called at the end of `render()` for Home) picks a daily-rotating category (`dailyIndex(CATS.length,'p')`), fetches its Wikipedia lead image via the existing `wikiGet` cache, upscales the thumb URL to 640px (regex `/(\d+)px-/` → `640px-`, no-op if pattern absent), preloads it, then fades it in behind a dark scrim (`.hero/.heroimg/.heroscrim/.herobody/.herocap` CSS). Caption chip = emoji + article title, taps into the category. Offline/first-run = the old green gradient, no layout shift (min-height 150px). Design rule going forward: **max one photo per screen**; grove stays emoji. SW `wildhope-v24`.

**Grove companion + focused Home (2026-07-04):** "Your Grove" - a living companion card at the top of Home. Grows with the *current* streak through 8 stages (🌰 seed → 🌲 ancient grove, emoji scales with stage, gentle CSS sway, ✨ when today's action is done). **Friends** (🐦🐝🦋🐿️🦔🦊🦉🦌) arrive at streak milestones 7/14/21/30/45/60/90/120 and are keyed to *best-ever* streak - a broken streak makes the tree "rest" (never die) but friends stay: hope > fear. Friend arrivals announced once in the action toast (persisted in `milestones` as `friend<N>`). Tap grove 