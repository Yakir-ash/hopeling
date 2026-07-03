# WildHope — Deployment Guide
*Deliverable 19*

## Overview
Three deployables: **backend** (FastAPI + Postgres), **admin panel** (static, served by backend at `/admin`), **Android app** (Play Store). All config is via env vars (12-factor) so one image runs in every environment.

## 1. Backend

### Local (fastest path — SQLite, no external services)
```bash
cd backend
python -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
export AUTH_MODE=dev
uvicorn app.main:app --reload
# docs: http://localhost:8000/docs · admin: http://localhost:8000/admin
```

### Docker / production (Postgres)
```bash
cd backend
docker compose up --build      # api + postgres, auto-seeded
```

### Managed cloud (recommended: Cloud Run + Cloud SQL)
1. Provision **Cloud SQL for PostgreSQL 16**; note the connection string.
2. Build & push: `gcloud builds submit --tag gcr.io/PROJECT/wildhope-api`.
3. Deploy:
   ```bash
   gcloud run deploy wildhope-api \
     --image gcr.io/PROJECT/wildhope-api \
     --set-env-vars DATABASE_URL=postgresql+psycopg2://USER:PASS@/wildhope?host=/cloudsql/INSTANCE,AUTH_MODE=firebase,SEED_ON_START=false \
     --add-cloudsql-instances INSTANCE --allow-unauthenticated
   ```
4. Run the seed once against prod (`SEED_ON_START=true` on first boot, then set back to false), or run migrations + a controlled seed job.
5. Set `GOOGLE_APPLICATION_CREDENTIALS` (Firebase Admin service account) as a mounted secret so token verification works.
6. Lock CORS: `CORS_ORIGINS=["https://admin.wildhope.app"]`.

### Migrations
MVP uses `Base.metadata.create_all`. For production schema evolution, add **Alembic**: `alembic init`, autogenerate against the models, and run `alembic upgrade head` in the container entrypoint (replace `create_all`).

## 2. Admin panel
Served automatically at `/admin` from `backend/static/admin.html`. In production it authenticates with a real admin JWT (set `AUTH_MODE=firebase` and give the admin user `is_admin=true`). Put it behind SSO / IP allowlist. It is a single static file — also deployable to any CDN pointing at the same API.

## 3. Android app
1. **Firebase:** create a project → add an Android app (`org.wildhope.app`) → download `google-services.json` into `app/`, and enable the `com.google.gms.google-services` plugin lines in the two Gradle files.
2. **Maps:** create a Maps SDK for Android key, restrict it to the app's SHA-1, put it in the manifest `meta-data`.
3. **API URL:** set `API_BASE_URL` (BuildConfig) to your Cloud Run URL for release builds; keep `http://10.0.2.2:8000/v1/` for local emulator dev.
4. **Build & sign:**
   ```bash
   ./gradlew :app:bundleRelease            # produces an .aab
   ```
   Configure an upload keystore in `signingConfigs` (or Play App Signing).
5. **Release:** upload the `.aab` to the Play Console → internal testing → closed → production. Provide a privacy policy (guest device id + optional account data).

## Observability & ops
- Backend: enable Cloud Run request logging; add Sentry for exceptions.
- Analytics: Firebase Analytics events already implied by the client (screen views, `action_completed`, `challenge_completed`, `course_completed`) → funnel dashboards for activation (first action) and D1/D7 retention.
- Content freshness: run provider pullers (IUCN/NOAA/GBIF adapters) on Cloud Scheduler → they upsert into content tables; no app release needed.

## Rollback
Cloud Run keeps revisions — `gcloud run services update-traffic wildhope-api --to-revisions PREV=100`. Android: staged rollout percentages in Play Console; halt if crash-free rate drops.
