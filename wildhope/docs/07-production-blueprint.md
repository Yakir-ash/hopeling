# WildHope — Production Blueprint
### From HTML prototype to a world-class, cross-platform conservation platform
*Written for: a solo/bootstrapped founder · Stack decision: Flutter · Business model: to be chosen (recommendation inside)*

---

## 0. How to read this document
This is the plan to turn WildHope from a prototype into a real product on the App Store and Google Play. I've written it as a senior team would hand it to a founder: opinionated, with trade-offs shown, and with your assumptions challenged where I think you're about to spend money or time in the wrong place. Sections:

1. Strategic reframes (where I disagree with the brief)
2. Recommended technology stack, with trade-offs
3. System architecture (API-first, real-time, offline, moderation)
4. **Data strategy & real sources** — the licensing reality, with a decision table
5. Community & social design (positivity over competition)
6. Gamification system
7. AI features (yours + ones you didn't list)
8. 100+ future features, scored
9. Product critique (what's weak, what's missing, what drives retention/virality)
10. Business model recommendation
11. Roadmap: MVP → millions of users
12. The honest MVP (what to actually build first)

---

## 1. Strategic reframes — where I'd push back on the brief

You asked me to challenge assumptions. Five that matter most:

**1.1 "Cover ALL animals and ecosystems" is a positioning risk, not a strength.**
A product that is about everything is about nothing in the app-store search bar and in a new user's head. The broad mission is right; the *wedge* should be narrow. Pick one hero use case to win first (my recommendation: **"a daily habit that turns you into someone who acts for wildlife"**, anchored on the action + streak loop), then expand breadth. Duolingo didn't launch with 40 languages.

**1.2 A social network is the hardest possible thing to build, and you're solo.**
Community features (feeds, follows, photo upload, comments, teams, events) are a cold-start problem *and* a moderation liability *and* a huge build. If you ship them empty, the app feels dead — the opposite of "alive." **Sequence it:** launch as a beautiful single-player habit app with *asymmetric* social (shareable cards, public impact profiles, global aggregate counters), and only open user-generated content once you have thousands of daily users to fill it. More on this in §5.

**1.3 "No fake data" collides head-on with the licensing reality.** (This is the big one.)
The most authoritative wildlife datasets — IUCN Red List, eBird, Movebank, iNaturalist's identification model — are **explicitly non-commercial and several specifically restrict mobile-app use.** You cannot legally build a commercial app on IUCN Red List data via their API. This doesn't kill the vision; it *shapes* it (see §4 and §10). The honest answer: your species/threat content will be a **curated editorial layer you own**, cross-checked against these sources, plus live data only from the sources that permit app/commercial use (GBIF, NASA, NOAA, Global Forest Watch, Our World in Data, Petfinder). Registering the project as/with a nonprofit unlocks the restricted sources legitimately.

**1.4 Real-time sync is mostly a cost, not a feature, for a habit app.**
Users don't need millisecond sync to log "I did a beach cleanup." Real-time matters for *social presence* (live event feeds, team activity) — which is Phase 2+. For MVP, offline-first with eventual sync (what your prototype already implies) is cheaper, simpler, and enough. Don't pay the real-time tax before you have social features that need it.

**1.5 Gamified guilt is the failure mode to design against.**
Strava and Duolingo also *lose* users who feel shamed by broken streaks and leaderboards. Your instinct ("positivity over competition") is correct and under-served in this category — lean into it as a *differentiator*, not a footnote. Concretely: streak insurance, "we" counters instead of "you vs. them," and cooperative goals as the default (see §5–6).

---

## 2. Recommended technology stack (with trade-offs)

Your constraints — **solo, bootstrapped, iOS + Android + shared code, wants to ship** — dominate every choice below. The theme: **buy managed services, don't run servers, keep one codebase.**

### 2.1 Client: Flutter ✅ (your pick — I agree, here's why)
| Option | Pros | Cons | Verdict |
|---|---|---|---|
| **Flutter** | One Dart codebase → iOS, Android, web. Own rendering engine = pixel-perfect, buttery animations (your gamified, illustrated UI *needs* this). Great offline libs. Strong for a solo dev (one language, one build). | Dart is less common than JS. Larger app binary. Some native integrations need platform channels. | **Chosen.** Best fit for a design-forward, animation-heavy solo build. |
| React Native / Expo | Huge JS ecosystem, easiest hiring, Expo simplifies builds/OTA updates. | Animation/perf ceiling lower; bridge quirks; more moving parts. | Strong runner-up if you already know React. |
| Native (Kotlin+Swift) | Max fidelity/perf. | Two codebases = ~2× work. Fatal for solo. | No. |

**Flutter specifics to adopt:** Riverpod (state management), `drift` or `isar` (offline DB), `dio` (networking), `go_router` (navigation), `flutter_animate` + Rive/Lottie (the delightful moments), `melos` only if you later split packages.

### 2.2 Backend: managed BaaS — **Supabase (recommended)** vs Firebase
For a solo founder, running your own FastAPI + Postgres + Redis + infra (what I built earlier) is the wrong default now — it's ops you don't have time for. Use a Backend-as-a-Service.

| | **Supabase (recommend)** | Firebase |
|---|---|---|
| Database | **Postgres** (real SQL, relational, portable — you keep the schema I designed) | Firestore (NoSQL; painful for leaderboards, joins, analytics) |
| Auth | Built-in (email, Google, Apple, magic link) | Best-in-class, incl. phone |
| Realtime | Postgres changes + broadcast | Excellent |
| Storage | Yes (photos) | Yes |
| Functions | Edge Functions (Deno/TS) | Cloud Functions |
| Offline | Client caches; you add local DB | Firestore offline is superb out-of-box |
| Lock-in | **Low — it's just Postgres; you can leave** | High (proprietary) |
| Cost curve | Predictable; generous free tier | Cheap to start, can spike unpredictably at scale |
| Why for you | Keeps SQL data model, easy analytics, portable, no vendor trap | Fastest offline, but NoSQL fights your relational/leaderboard needs |

**Recommendation: Supabase.** It preserves the relational schema from the earlier design, gives you auth + realtime + storage + serverless functions in one managed product, and — critically — it's Postgres, so if you outgrow it you migrate the database, not rewrite the app. Use **Firebase only for the two things it's still best at**: Cloud Messaging (push) and Crashlytics (crash reporting). Mixing is normal and free.

### 2.3 The rest of the stack (all chosen for low solo-ops burden)
- **Push notifications:** Firebase Cloud Messaging (free, cross-platform).
- **Analytics:** PostHog (product analytics, funnels, free self-serve tier, privacy-friendly) + Firebase Analytics if you want Google's funnels. Pick one to start — **PostHog**.
- **Crash reporting:** Sentry (Flutter SDK, errors + performance) or Firebase Crashlytics. **Sentry** for richer context.
- **CI/CD:** **Codemagic** (built for Flutter — builds, signs, ships to both stores) or GitHub Actions + Fastlane. Start with Codemagic to save days.
- **API-first layer:** Supabase auto-generates a REST + GraphQL API from your Postgres schema; put your *custom* logic (content ingestion, AI proxying, moderation actions) in **Edge Functions** behind a versioned path. This satisfies "API-first" without you hand-writing a server.
- **Admin dashboard & moderation:** **Retool** or **Appsmith** wired to Supabase (build internal tools in hours, not weeks) for MVP; graduate to a custom Next.js admin later. This replaces the hand-built admin panel for now.
- **Content/editorial CMS:** **Sanity** or **Directus** for your owned species/action/story content (writers edit without touching the DB).
- **Feature flags / remote config:** PostHog or Firebase Remote Config (ship dark, roll out gradually).

**One-paragraph summary:** Flutter app → Supabase (Postgres, auth, realtime, storage, edge functions) → Firebase (push, crash) → PostHog (analytics) → Codemagic (CI/CD) → Retool (admin/moderation) → Sanity (editorial content). A solo dev can actually run this.

---

## 3. System architecture

```
                 ┌─────────────────────────────────────────┐
                 │            Flutter app (iOS/Android/web)  │
                 │  Riverpod · local DB (drift) · go_router  │
                 │  offline-first cache + sync queue         │
                 └───────────────┬───────────────────────────┘
                                 │ HTTPS (REST/GraphQL + Realtime WS)
                 ┌───────────────▼───────────────────────────┐
                 │                SUPABASE                    │
                 │  Auth  │  Postgres (RLS)  │ Realtime │ Storage
                 │  Edge Functions: /ingest /ai /moderate /feed
                 └───┬───────────┬──────────────┬────────────┘
                     │           │              │
        ┌────────────▼──┐  ┌─────▼──────┐  ┌────▼─────────────┐
        │ Scheduled jobs│  │ AI provider│  │ External data     │
        │ (data pullers)│  │ (LLM/vision)│  │ GBIF·NASA·NOAA·GFW│
        └───────────────┘  └────────────┘  │ Petfinder·Every.org│
                                            └───────────────────┘
   Cross-cutting: FCM (push) · Sentry (crash) · PostHog (analytics) · Retool (admin/mod)
```

**Key principles**
- **Row-Level Security (RLS)** in Postgres is your authorization backbone: users can read public content and write only their own rows. This is what makes a BaaS safe.
- **Offline-first:** the app writes to a local queue (idempotent client-UUID keys, exactly as the earlier design) and syncs when online. Content is cached for offline reading/lessons.
- **Ingestion is decoupled:** scheduled Edge Functions/cron pull external data on a schedule into *your* tables, normalized. The app never calls IUCN/GBIF directly — it reads your cache. This gives resilience, caching, rate-limit safety, and a clean seam to add/replace providers (the modularity you wanted).
- **AI is proxied server-side** (Edge Function) so keys never ship in the app and you can moderate/limit usage.
- **Moderation hooks** live in the write path for any user content (see §5.4).

---

## 4. Data strategy & real sources (the licensing reality)

This is the section that most changes your plan. I researched current terms for the major sources. **The pattern:** the best scientific data is free for *research/education* but **restricted for commercial apps**; the data that's safe for a commercial app is either public-domain government data, permissively-licensed aggregators, or purpose-built app APIs.

### 4.1 Decision table — what you can actually use

| Source | Covers | License reality (2025–26) | Use in a commercial app? | How to use it |
|---|---|---|---|---|
| **IUCN Red List API** | Endangered status, population trend | **Non-commercial only; explicitly discourages mobile-app use;** commercial = license via IBAT | ❌ not commercially. ✅ if you're a nonprofit/education | Use as an *editorial reference* you read and cite; or get nonprofit access; or license via IBAT |
| **GBIF** | Species occurrences, taxonomy, images | Open; data under CC0/CC-BY per record | ✅ yes (attribute) | Live occurrence maps, "seen near you", taxonomy backbone |
| **iNaturalist API + CV model** | Observations, species image ID | API for data; **CV model free ≈200 req/mo**; commercial ID needs arrangement | ⚠️ limited | Prototype species-ID; for scale use a licensed/own model |
| **Pl@ntNet API** | Plant ID | Free ≤500 IDs/day; **paid commercial tier** | ✅ (paid at scale) | Plant/habitat ID feature |
| **Google Cloud Vision / Vertex AutoML** | General + custom image ID | Commercial, pay-per-use | ✅ | Train a **custom species model** (camera-trap/iNat-derived) — your long-term ID moat |
| **NASA Earthdata / NASA APIs** | Climate, Earth observation, imagery | **Public domain, any purpose** | ✅ | Climate impact, satellite imagery, "your region" context |
| **NOAA ERDDAP / CoastWatch** | Ocean temp, coral heat stress, fisheries | US Gov, generally public domain | ✅ (check per-dataset) | Ocean health, coral bleaching alerts, marine spotlight |
| **OBIS** | 120k+ marine species observations | Open (CC-BY/CC0 per node) | ✅ (attribute) | Marine life maps & facts |
| **Global Forest Watch Data API** | Deforestation alerts (GLAD/RADD), tree-cover loss | Free/open, API key | ✅ | Deforestation map layers, near-real-time alerts |
| **Our World in Data** | Conservation/climate statistics | **CC-BY** (their own data); third-party series keep origin license | ✅ (attribute) | Charts, "global stats", learning content |
| **Petfinder API** | Adoptable pets, 14.5k shelters | Free API key; review ToS | ✅ (per ToS) | Pet adoption/foster feature (US/CA) |
| **RescueGroups.org API** | Adoptable animals, orgs | Free, generous limits | ✅ (per ToS) | Adoption + rescue-org directory |
| **Every.org API** | 1M+ nonprofits, donations | **Free for non-commercial; enterprise plan for for-profit** | ✅ (plan depends on model) | In-app donations to vetted orgs, fundraisers, webhooks |
| **Charity Navigator API** | Charity ratings/vetting | Register; commercial terms vary | ✅ (verify) | Vet the orgs you list (trust layer) |
| **eBird API** | Bird observations/hotspots | **Non-commercial license** | ❌ commercially | Nonprofit route only; else use GBIF bird data |
| **Movebank** | Animal tracking | Non-commercial research; per-dataset terms | ❌ mostly | Nonprofit/education partnerships only |
| **GDELT** | Global news (incl. environment) | Free, open | ✅ | Conservation news feed (needs heavy filtering/curation) |
| **NewsAPI / Mediastack** | News headlines | Free tier tiny + **no commercial**; paid from ~$449/mo | ⚠️ paid | Alternative news source if you pay |

### 4.2 The resulting data architecture (three layers)
1. **Owned editorial layer (your moat & your legal safety):** species profiles, threats, actions, success stories, courses — written by you/contributors, *cross-checked* against IUCN/authoritative sources and cited, but **stored as your content.** This is what makes the app trustworthy *and* legally clean, and it's the part competitors can't copy.
2. **Live public/commercial-safe data (via scheduled ingestion → your DB):** GBIF occurrences, NASA/NOAA climate & ocean, Global Forest Watch deforestation alerts, Our World in Data stats, Petfinder/RescueGroups adoptions, Every.org donations. Cached, normalized, attributed.
3. **AI/derived data:** species ID (start Pl@ntNet/iNat/Vision, evolve to a custom model), personalized recommendations, news summarization/classification (turn GDELT firehose into positive, verified items).

### 4.3 The nonprofit unlock (strategic)
Several gold-standard sources (IUCN, eBird, Movebank) become *legitimately usable* if WildHope operates as, or partners with, a **registered nonprofit / educational entity.** Given the mission, this is likely the right structure anyway (see §10) and it converts your biggest data constraint into an advantage competitors structured as for-profits can't easily match.

---

## 5. Community & social design (positivity over competition)

### 5.1 Sequence social; don't launch it cold
- **Phase 1 (MVP):** *asymmetric social only* — no user-generated content to moderate.
  - Public **impact profile** (shareable link/card): "Maya has taken 47 actions, avoided 3.1 kg plastic."
  - **Global "we" counters:** live aggregate of everyone's actions ("Together we removed 12,481 pieces of trash this week"). Makes the app feel alive from day one with zero UGC risk.
  - **Share cards** to Instagram/WhatsApp (viral loop, §9).
- **Phase 2:** follows, activity feed of *structured events* (badges, milestones — not free text), reactions (only positive reactions, no dislike).
- **Phase 3:** photo posts, comments, local communities, events, teams. Full UGC + moderation.

### 5.2 Positivity mechanics (the differentiator)
- **"We," not "vs.":** default surfaces are cooperative (team totals, global goals), not rankings.
- **Reactions are all positive** (🌱 👏 💚) — no downvote, no dislike. Removes pile-on dynamics.
- **Leaderboards are opt-in and cohort-based** (this week's newcomers, your team) — never a global all-time board that demoralizes.
- **Milestones are celebrated publicly by default; failures are private.** Broken streak → "Welcome back 🌱," never a red X shown to others.
- **Kindness by design:** first-time posters get a gentle guideline; comments support only supportive templates early on.

### 5.3 Local & real-world
- **Local communities** (geo, opt-in): find cleanups, tree plantings, shelter volunteering near you.
- **Events:** create/join, RSVP, log collective impact (pins on the global map). Partner with existing orgs so events aren't empty.
- **Teams/challenges:** cooperative goals ("our team plants 100 trees this month").

### 5.4 Moderation (non-negotiable once UGC opens)
- **Pre-publish automated screening:** image safety (Vision SafeSearch / AWS Rekognition), text toxicity (Perspective API), and a **graphic-animal-content classifier** (your ethics rule: no graphic imagery).
- **Report + queue → Retool moderation console** (human review), with soft-hide on report threshold.
- **Trust levels** (Discourse-style): new users rate-limited; established users gain privileges.
- **Clear community guidelines + appeals.** Budget for this before you ship UGC; it's a legal and brand risk if you don't.

---

## 6. Gamification system

Borrowing the *right* lesson from each reference, avoiding their failure modes.

| From | Borrow | Avoid |
|---|---|---|
| **Duolingo** | Streaks, daily goals, gentle loss-aversion, delightful mascot moments | Aggressive guilt notifications, streak panic |
| **Strava** | Real-world logged effort → identity ("I'm someone who acts"), segments/clubs | Comparison anxiety, pay-to-see-your-own-data |
| **GitHub** | The **contribution graph** — a calendar of green squares is deeply motivating | — |
| **Fitbit** | Ambient progress (rings), weekly summaries, badges for milestones | Nagging |

### 6.1 The core loop
**Open → learn one thing → do one action → see impact grow → streak advances → gentle nudge to return.** Everything below feeds this loop.

### 6.2 Systems
- **XP & Levels:** XP per action/lesson/challenge; level curve fast early (hook), slower later (mastery). Nature-themed level names (Seed → Sapling → … → WildHope Champion).
- **Impact graph (signature feature):** a GitHub-style calendar of your daily actions — a year of green leaves. Screenshot-worthy, identity-forming.
- **Streaks with humane design:** daily goal (1 action), **streak freeze/insurance** (earn or buy 1–2), "repair yesterday" grace. Streak loss is private and framed as a fresh start.
- **Daily goals & weekly missions:** "Do 1 action today," "Complete 3 ocean actions this week."
- **Badges/achievements:** milestone (10/50/500 actions), category mastery, learning (course complete), community (first event), rare seasonal.
- **Seasonal events:** "Plastic-Free July," "World Oceans Day week," "Winter bird-feeding" — time-boxed, themed, with limited-edition badges (drives return + urgency without dark patterns).
- **Community milestones:** global goals everyone contributes to ("1 million actions by Earth Day"), with a live progress bar on the home screen.
- **Team challenges:** cooperative, not zero-sum.
- **Unlockable content:** advanced courses, new species dossiers, app themes/illustrations unlocked by progress (free) — makes leveling feel rewarding without paywalling core value.

### 6.3 Anti-patterns to ban
No pay-to-win, no shaming notifications, no global all-time leaderboard, no streak-anxiety spam, no loot-box mechanics.

---

## 7. AI features

### 7.1 Your list — how I'd actually build each
| Feature | Build approach | Notes / risk |
|---|---|---|
| **Animal rescue guidance** | **Rules-based triage flow** + local rescue directory (Petfinder/RescueGroups geodata), LLM only to classify the situation | Safety-critical → scripted, verified content beats free-form generation |
| **Species ID from photos** | Start Pl@ntNet (plants) + iNat/Vision (animals); evolve to a **custom Vertex AutoML model** on licensed/own data | The custom model is a real long-term moat |
| **Local conservation action suggestions** | Rank your action catalog by geo + season + user causes (GBIF "what's near you", GFW alerts, NOAA) | Mostly a recommender, light AI |
| **Personalized learning plans** | LLM sequences your course/lesson library to the user's interests & level | Keep content owned; AI only orders it |
| **Ethical shopping assistant** | Barcode scan → match against vetted databases (palm-oil, seafood guides, cruelty-free) + LLM explanation | Sourcing the product database is the hard part |
| **Environmental impact calculator** | Deterministic model (diet, transport, plastic) with sources; AI explains results | Must be transparent & cited, not a black box |
| **Personalized recommendations** | Contextual bandit over actions/content; cold-start from onboarding causes | Standard rec-sys |

### 7.2 AI features you didn't list (higher-leverage than some above)
1. **News curator/verifier:** turn the GDELT firehose into a *positive-first, de-duplicated, credibility-checked* feed — solves your "no doomscroll" news requirement, which is otherwise very hard to do by hand.
2. **"Explain this like I'm 10":** one tap to re-level any science content for kids/accessibility (huge for families/schools).
3. **Auto-generated impact narratives:** "This month you helped pollinators 6 times — here's what that adds up to," with citations. Retention gold.
4. **Photo → action:** snap any scene (a beach, a garden, a supermarket shelf) → AI suggests the most relevant action right there.
5. **Multilingual on the fly:** LLM translation of your owned content into any language cheaply (unlocks global reach without hand-translating everything).
6. **Accessibility copilot:** image alt-text generation, audio narration of lessons, dyslexia-friendly rewrites.
7. **Grant/impact reports for NGOs & teachers:** auto-summaries of a community's collective impact (a B2B wedge, §10).
8. **Misinformation guard:** flags conservation myths in UGC and offers a cited correction (protects brand trust).
9. **Content-ops copilot (internal):** drafts new species/action content from primary sources for a human to verify — how you scale the editorial layer as a solo founder.

### 7.3 AI guardrails
Cite-or-abstain; safety flows scripted not generative; server-side proxy with rate limits; on-device where privacy matters (photo ID); human-in-the-loop for anything published.

---

## 8. 100+ future features, scored

Legend — **Difficulty:** S (small), M (medium), L (large), XL (very large). **Phase:** MVP · v1.x · v2 · v3+ (moonshot).

### Core habit & action
| # | Feature | Why valuable | Who | Diff | Phase |
|---|---|---|---|---|---|
|1|Daily action + streak (core loop)|The habit engine; drives DAU|All|M|MVP|
|2|Impact tracker (9 metrics)|Makes small acts feel real; retention|All|M|MVP|
|3|GitHub-style impact graph|Identity + screenshot virality|All|M|MVP|
|4|Action difficulty/cost/time filters|Right action for right moment|All|S|MVP|
|5|"Why it matters" + citations|Trust; differentiates from feel-good apps|Skeptics, David|S|MVP|
|6|Streak freeze/insurance|Kills streak anxiety; retention|All|S|v1.x|
|7|Weekly missions|Medium-term goals|Engaged|S|v1.x|
|8|Seasonal events + limited badges|Urgency + return spikes|All|M|v1.x|
|9|Action reminders (smart time)|Re-engagement|All|M|v1.x|
|10|"Photo → suggested action" (AI)|Contextual, magical|All|L|v2|
|11|Habit pairing ("after coffee, 1 action")|Behavioral science boost|All|S|v2|
|12|Undo/edit logged actions|Trust, correctness|All|S|v1.x|

### Education & content
|13|Micro-courses + quizzes + badges|Education pillar; gamified learning|Learners, students|M|MVP|
|14|Daily fact|The "learn one thing" promise|All|S|MVP|
|15|Species dossiers (owned editorial)|Depth; the content moat|All|L|MVP|
|16|"Explain like I'm 10" toggle (AI)|Families, accessibility|Kids, parents|M|v2|
|17|Offline course downloads|Field use, premium hook|Travelers|M|v1.x|
|18|Audio narration of lessons|Accessibility, commuters|Many|M|v2|
|19|Kids mode (simplified, safe)|Families, schools|Children|L|v2|
|20|Teacher/classroom mode + lesson plans|Schools distribution channel|Teachers|L|v2|
|21|AR species facts (point at zoo animal)|Wow factor, kids|Families|XL|v3+|
|22|Personalized learning path (AI)|Keeps learners progressing|Learners|M|v2|
|23|Citations/source explorer|Credibility for power users|Scientists|S|v1.x|
|24|Interactive data stories (OWID/NOAA)|Makes stats emotional|All|M|v2|
|25|Myth-busting cards|Counters misinformation|All|S|v1.x|

### Community & social
|26|Public impact profile + share card|Viral loop; feels alive|All|M|MVP|
|27|Global "we" counters|Alive with zero UGC risk|All|S|MVP|
|28|Follows + positive activity feed|Social retention|Engaged|L|v2|
|29|Photo posts (moderated)|UGC richness|Engaged|L|v2|
|30|Positive-only reactions|Kind community by design|All|S|v2|
|31|Comments (templated early)|Connection|Engaged|M|v2|
|32|Local communities (geo)|Real-world action|Volunteers, Lena|L|v2|
|33|Volunteer events + RSVP|Turns app into action|Volunteers|L|v2|
|34|Teams + cooperative challenges|Belonging, retention|Engaged|L|v2|
|35|Global community milestones|Collective purpose|All|M|v1.x|
|36|Mentor/buddy matching|Onboarding retention|New users|M|v3+|
|37|Org/NGO verified accounts|Trust + content supply|NGOs|M|v2|
|38|Success-story submissions (moderated)|Hope content at scale|All|M|v2|
|39|In-app fundraisers (Every.org)|Real money to causes|All|L|v2|
|40|Local leaderboards (opt-in, cohort)|Motivation w/o shame|Some|M|v2|
|41|Friend milestone celebrations|Positive social pings|All|S|v2|
|42|Group trips/expeditions board|Ecotourism, travelers|Travelers|L|v3+|

### Maps & real-world data
|43|Global map w/ threat/reserve layers|Exploration, context|All|L|v1.x|
|44|"Wildlife near you" (GBIF/OBIS)|Local relevance|All|M|v1.x|
|45|Deforestation alerts (GFW)|Live, urgent, real|All|M|v2|
|46|Coral bleaching/ocean alerts (NOAA)|Marine spotlight|Ocean fans|M|v2|
|47|Protected areas & parks directory|Trip planning|Travelers|M|v2|
|48|Report a sighting/incident|Citizen science + rescue|All|L|v3+|
|49|Community event pins on map|Real-world density|Volunteers|M|v2|
|50|"Adopt a place" (track a reserve)|Ongoing attachment|Engaged|M|v3+|

### AI features
|51|Species ID from photo|Magical, sticky|All|L|v2|
|52|Rescue triage assistant|Life-saving, trust|All|M|v1.x|
|53|Ethical shopping/barcode scanner|Daily utility|Conscious buyers|XL|v3+|
|54|Impact calculator|Self-awareness → action|All|M|v2|
|55|News curator/verifier (positive-first)|Solves doomscroll problem|All|L|v2|
|56|Personalized recommendations|Right content/action|All|M|v2|
|57|Auto impact narratives|Retention, delight|All|M|v2|
|58|Multilingual content (AI translate)|Global reach|Global|M|v2|
|59|Accessibility copilot (alt-text, TTS)|Inclusion|Disabled users|M|v2|
|60|Content-ops copilot (internal)|Scales editorial solo|You|M|v1.x|

### Families, schools, children
|61|Family accounts + shared goals|Household engagement|Families|M|v2|
|62|Kid-safe walled garden|Trust for parents|Children|L|v2|
|63|School challenges/leaderboards|Viral in schools|Teachers|L|v2|
|64|Printable activities/worksheets|Classroom utility|Teachers|S|v2|
|65|Allowance-of-actions for kids|Habit for children|Families|S|v3+|
|66|Bedtime animal story mode|Daily family ritual|Families|M|v3+|
|67|Scavenger hunts (backyard bioblitz)|Outdoor kids fun|Families|M|v3+|

### NGOs, scientists, governments, business
|68|NGO partner portal + campaigns|Content + distribution|NGOs|L|v2|
|69|Verified donation routing + receipts|Trust, tax|Donors|L|v2|
|70|Impact reports for NGOs (AI)|B2B value, revenue|NGOs|M|v3+|
|71|Citizen-science data contribution (GBIF)|Real scientific value|Scientists|L|v3+|
|72|Researcher dashboards|Data for good|Scientists|L|v3+|
|73|Corporate/team sustainability programs|B2B revenue|Businesses|L|v3+|
|74|Gov/park co-branded experiences|Distribution, credibility|Governments|L|v3+|
|75|Grant-ready impact analytics|Funding orgs|NGOs|M|v3+|
|76|API/SDK for partners|Ecosystem|Partners|L|v3+|

### Pets & animal welfare
|77|Adoption/foster finder (Petfinder)|High-emotion action|Pet lovers|M|v1.x|
|78|Report animal abuse (localized)|Real welfare impact|All|M|v1.x|
|79|Lost & found pet board|Community utility|Pet owners|L|v3+|
|80|Pet-care ethical guides|Everyday relevance|Pet owners|S|v2|
|81|Vet/rescue directory|Emergency utility|Pet owners|M|v2|
|82|Wildlife-friendly pet tips (cats indoors)|Bird conservation|Pet owners|S|v1.x|

### Travelers & ecotourism
|83|Responsible wildlife tourism guide|Prevents harm|Travelers|M|v2|
|84|"Don't buy" wildlife-product warnings|Reduces trafficking demand|Travelers|S|v2|
|85|Ethical sanctuary finder|Trip planning|Travelers|M|v3+|
|86|Offline field guide by region|No-signal utility|Travelers|M|v2|
|87|Carbon offset for trips (vetted)|Actionable|Travelers|M|v3+|

### Monetization & sustainability
|88|Premium tier (offline, stats, AI)|Revenue|Power users|M|v2|
|89|Recurring donations/round-ups|Revenue to causes|Donors|L|v2|
|90|Affiliate ethical marketplace|Revenue|Conscious buyers|L|v3+|
|91|Gift subscriptions/badges|Revenue + virality|Gifters|S|v3+|
|92|Sponsored (clearly-labeled) campaigns|Revenue, mission-aligned|Brands/NGOs|M|v3+|

### Accessibility & inclusion
|93|Full screen-reader + dynamic type|Inclusion, compliance|Disabled|M|MVP|
|94|High-contrast + reduce-motion|Inclusion|Disabled|S|MVP|
|95|Low-bandwidth/lite mode|Global South reach|Global|M|v2|
|96|RTL + many languages|Global reach|Global|M|v1.x|
|97|Voice-first interaction|Hands-free, accessibility|Some|L|v3+|

### Delight, retention & virality
|98|Beautiful share cards (per milestone)|Organic growth|All|M|MVP|
|99|Year-in-review "Wrapped"|Annual viral spike|All|M|v2|
|100|Widgets (home-screen streak/impact)|Ambient re-engagement|All|M|v2|
|101|Apple Watch / wearable glance|Ambient|Some|L|v3+|
|102|Live activities (event countdowns)|Presence|Some|M|v3+|
|103|Collectible seasonal illustrations|Delight, unlockables|All|M|v2|
|104|"Random act of hope" surprise|Delight, surprise|All|S|v1.x|
|105|Referral rewards (both give to a cause)|Viral + mission-aligned|All|M|v2|

---

## 9. Product critique (unvarnished)

### What's weak
- **Scope is the enemy.** The brief describes 6 products (habit app + social network + LMS + map + news + marketplace). Solo, you can build *one* well. Weakness #1 is trying to do all of it.
- **"No fake data" + commercial app is partly contradictory** given licensing (§4). Unaddressed, this is a legal risk and a launch-blocker.
- **Cold-start community.** Social features shipped empty make the app feel *dead*, undermining "alive."
- **Undifferentiated in one sentence.** Right now it's "an app about helping animals." That's not a wedge. Needs a sharper hook.
- **Trust/verification burden.** Claiming impact ("you avoided 3 kg plastic") invites "says who?" — you must be rigorous or lose credibility.

### What's missing
- A **single, crisp value proposition** and hero use case.
- A **content pipeline** — who writes/verifies the editorial layer, at what cadence (this is the real bottleneck, not code).
- **Trust & safety plan** before UGC (moderation, guidelines, appeals, minors/COPPA).
- **A reason the impact is real** (partnerships where a logged action maps to a verifiable outcome — e.g., "1 action = 1 tree via a partner").
- **Monetization decision** (you deferred it; §10 recommends).
- **Retention instrumentation** from day one (activation = first action; D1/D7/D30).

### What users may dislike
- Guilt/pressure (streak anxiety, comparison) — design against it (§5–6).
- "Slacktivism" skepticism — counter with *verifiable* impact and real-world actions.
- Notification fatigue — conservative defaults, per-type control.
- Feeling their data/impact is made up — cite everything.
- Paywalls on core value — keep the core free forever.

### What increases retention
Daily reason to open (fresh fact + action + streak), the impact graph (sunk-cost identity), streak insurance, weekly missions, push done *well* (timely, kind), auto impact narratives, seasonal events, and — most of all — **visible proof that actions matter.**

### What makes it go viral
- **Share cards** (impact profile, milestone, year-in-review "Wrapped").
- **Referral where both people give to a cause** (mission-aligned growth).
- **Screenshot-worthy identity** (the green impact graph = the "GitHub for good").
- **Seasonal global goals** that people rally friends around.
- **School/team challenges** (built-in network effects).

### What makes people return every day
One completable action every day, a streak they don't want to lose (but won't be shamed by), a global counter ticking up, and a notification that teaches them something true and small.

### What could make it the world's leading conservation platform
1. **Own the "daily habit for the planet" positioning** before anyone else does (no clear leader exists).
2. **Make impact verifiable** via NGO partnerships (action → real outcome).
3. **Become the distribution layer for conservation orgs** (they bring content + users; you bring the habit engine and audience). This two-sided flywheel is the defensible endgame.
4. **Win schools and families** (next-generation lock-in + viral network effects).
5. **The custom species-ID model + owned editorial corpus** as compounding data moats.

---

## 10. Business model recommendation

You said "not decided." Here's the call.

| Model | Pros | Cons | Fit |
|---|---|---|---|
| Freemium subscription | Recurring revenue, aligns with power users | Risk of paywalling mission; conversion is hard early | Later, yes |
| Nonprofit / grants / donations | **Unlocks IUCN/eBird/Movebank data**, mission-authentic, grant funding, tax-advantaged | Slower, grant-dependent, governance overhead | Strong for the mission |
| Free + partnerships | Growth-first, NGO/brand revenue, affiliate | Revenue later; partnership sales effort | Good bridge |

**Recommendation: a hybrid, staged.**
1. **Structure as (or under) a nonprofit / fiscally-sponsored project.** This is authentic to the mission *and* legally unlocks the best datasets (§4.3) — a rare case where the "nice" choice is also the strategically optimal one.
2. **Launch 100% free** to maximize growth and impact (growth is your scarcest asset as a solo founder).
3. **Add revenue without paywalling the mission:** (a) an optional **"Supporter" membership** (offline downloads, advanced stats, AI assistant, badge — Wikipedia/Strava-style), (b) **NGO partnerships** (verified campaigns, impact reports — a future B2B line), (c) **round-up donations & affiliate ethical shopping** (revenue *to causes* and a small platform share). Never gate core learning or action behind a paywall.

This keeps the app "always useful for free users" (your ethics rule), funds sustainability, and turns your biggest constraint (data licensing) into an advantage.

---

## 11. Roadmap: MVP → millions

**Phase 0 — Foundations (Weeks 1–4).** Flutter app skeleton, Supabase project (schema, RLS, auth), CI/CD (Codemagic), Sentry + PostHog wired, design system in Flutter. Decide nonprofit structure. Draft the first 30 species profiles + 40 actions + 6 courses (content is the critical path).

**Phase 1 — MVP / "single-player habit app" (Months 2–4).** Onboarding, Home (fact+action+streak+global counter), Explore (owned content), Action Center, Impact tracker + impact graph, Learn (courses/quizzes/badges), search, push, offline, public share cards, accessibility. **Ship to both stores.** Goal: nail activation (first action) and D7 retention.

**Phase 2 — "It's alive" (Months 5–9).** Global map (GBIF/GFW/NOAA layers), news curator (AI), follows + positive feed, teams + cooperative challenges, local communities + events, Petfinder adoption, in-app donations (Every.org), Supporter membership, species ID v1. Add moderation stack *before* UGC. Goal: social retention + first revenue.

**Phase 3 — Platform & scale (Months 10–18+).** NGO partner portal, verified impact (action→outcome), schools/family modes, custom species-ID model, ethical shopping assistant, impact reports (B2B), API/SDK, more languages, Year-in-Review "Wrapped." Goal: two-sided flywheel + scale to millions.

**Scaling notes:** Supabase carries you a long way; the migration path if you outgrow it is Postgres → managed Postgres (RDS/Cloud SQL) + your own services for the hot paths (feed, leaderboards), which you can extract one at a time because the data model is already relational and API-first. Add read replicas, a CDN for content/images, and a queue for ingestion/AI jobs as load grows.

---

## 12. The honest MVP (build this first)

If you cut everything non-essential, the MVP is: **onboarding → daily fact + daily action (with real, cited "why") → one-tap "I did this" → impact tracker + green impact graph → streak → a handful of owned courses → beautiful share card → push reminder.** Single-player. No feed, no UGC, no map, no real-time. That is a *complete, shippable, differentiated* product, and it's the loop your HTML prototype already proves people can grasp in 30 seconds.

Everything else in this document is earned by traction against that core.

---

## Sources (data & licensing research)
- IUCN Red List API & terms — https://api.iucnredlist.org/ · https://www.iucnredlist.org/terms/terms-of-use
- GBIF API — https://techdocs.gbif.org/en/openapi/
- iNaturalist API & computer vision — https://www.inaturalist.org/pages/api+reference · https://www.inaturalist.org/pages/computer_vision_demo
- Pl@ntNet API & licensing — https://my.plantnet.org/ · https://my.plantnet.org/terms_of_use
- Google Cloud Vision / AutoML — https://cloud.google.com/vision
- NASA Earthdata / APIs — https://www.earthdata.nasa.gov/ · https://api.nasa.gov/
- NOAA ERDDAP / OBIS — https://coastwatch.noaa.gov/erddap · https://obis.org/
- Global Forest Watch Data API — https://data-api.globalforestwatch.org/ · https://www.globalforestwatch.org/help/developers/
- Our World in Data (CC-BY) — https://ourworldindata.org/easier-to-reuse-our-data
- Petfinder API — https://www.petfinder.com/developers/v2/docs/
- RescueGroups API — https://rescuegroups.org/services/adoptable-pet-data-api/
- Every.org API — https://www.every.org/charity-api
- Charity Navigator API — https://developer.charitynavigator.org/
- eBird API terms — https://www.birds.cornell.edu/home/ebird-api-terms-of-use/
- Movebank API — https://github.com/movebank/movebank-api-doc
- GDELT — https://blog.gdeltproject.org/gdelt-doc-2-0-api-debuts/
