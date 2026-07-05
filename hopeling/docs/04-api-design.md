# Hopeling - API Design (FastAPI, REST)
*Deliverable 7*

Base URL: `https://api.hopeling.app/v1` - versioned path so v2 can evolve without breaking clients.

## Conventions
- JSON everywhere; snake_case; UTC ISO-8601 timestamps.
- Auth: `Authorization: Bearer <Firebase ID token>` - verified server-side (Firebase Admin SDK). Guest endpoints are public read-only. **Why Firebase:** offloads password security, gives Google/Apple sign-in free, and tokens work offline-cached on device.
- Pagination: `?limit=&cursor=` (cursor = opaque base64 of last id+ts) - plays well with Android Paging 3.
- Errors: RFC 7807 problem+json `{type, title, status, detail}`.
- Rate limit: 60 r/min per token (slowapi) on write endpoints.

## Endpoints

### Public content (no auth, CDN-cacheable)
```
GET  /home/today                 → {fact, action, challenge, story, spotlight, attention[]}  # one call renders Home
GET  /facts/daily
GET  /categories?kind=&q=
GET  /categories/{slug}          → full detail: threats, stories, orgs, facts, actions
GET  /actions?difficulty=&modality=&category=&cost=&max_minutes=&q=&limit=&cursor=
GET  /actions/{slug}
GET  /stories?kind=&category=&limit=&cursor=
GET  /news?topic=&category=&limit=&cursor=     # positive-first ordering server-side
GET  /courses  ·  GET /courses/{slug}          # includes lessons
GET  /challenges?active=true
GET  /organizations?category=&vetted=true
GET  /map/{country_code}?layers=threatened,projects,reserves
GET  /search?q=                                # federated: categories+actions+courses+news
GET  /sync/content?since=<iso>                 # offline-first delta pull
```
**Why `/home/today` as a single aggregate:** the dashboard must render in one round-trip on cold start (mobile latency), and its composition logic (personalization, rotation) belongs server-side so it can improve without app releases.

### Authenticated user
```
POST /users/me                       # upsert profile after Firebase sign-in (or guest link)
GET  /users/me                       # profile + xp/level/streak
PATCH /users/me                      # causes, locale, notification_prefs
POST /me/completions/actions         # body: [{id, action_id, completed_at}] batch, idempotent
POST /me/completions/challenges
POST /me/impact                      # batch impact entries (manual + derived)
GET  /me/impact/summary              # totals per metric + streak + level
GET  /me/badges
POST /me/lessons/{lesson_id}/complete  # {quiz_score}
```
**Why batch+idempotent writes:** the offline queue may replay; client-generated UUID PKs make retries safe.

### Community (v1.x)
```
GET/POST /groups · POST /groups/{id}/join · GET/POST /groups/{id}/events
GET/POST /posts?group_id=
```

### AI Helper (v1.x)
```
POST /ai/ask        # {question, context?} → {answer, sources[], safety_note?}
```
Server-side RAG over the curated content corpus + vetted external sources; the model never answers uncited. Emergency intents (injured animal) short-circuit to a rules-based triage flow + local rescue directory - **why:** correctness over eloquence in safety-relevant cases.

### Admin (JWT + is_admin)
```
CRUD /admin/{categories|facts|threats|actions|stories|news|courses|lessons|challenges|badges|organizations|map_regions|sources}
GET  /admin/stats                    # content counts, DAU hooks
```

### Notifications
Server schedules FCM topics: `daily_fact_{locale}`, `weekly_challenge`, `victories`. Personal-goal notifications computed by a daily job.

## Architecture notes
- Layering: `routers → services → repositories → SQLAlchemy models`; providers (IUCN, NOAA, GBIF pullers) implement a `ContentProvider` interface and write into the same content tables via the admin service - **why:** "add more providers later" becomes writing one adapter class, and the app/API never changes.
- Read-heavy: content endpoints get `Cache-Control: public, max-age=300` + ETag; Postgres read replicas when needed.
