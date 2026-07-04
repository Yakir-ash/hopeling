# 🌿 WildHope
**Help ordinary people reduce animal suffering worldwide through practical, evidence-based action.**
*Hope > Fear. Every open: learn one thing, do one thing today.*

An Android-first application covering all animals and ecosystems - wildlife, farm
animals, marine life, pets, lab/working animals, birds, insects, oceans, forests,
freshwater - built around a **learn → act → track → belong** loop.

## What's in this repository
```
wildhope/
├── README.md                 ← you are here
├── docs/                     ← product & engineering design (deliverables 1-10, 19-20)
│   ├── 01-product-strategy.md   Vision · 20 names + pick · personas · journeys · IA · MVP/roadmap · ethics
│   ├── 02-design-system.md      Design language · components · wireframes (deliverables 8-10)
│   ├── 03-database-schema.md     Full PostgreSQL schema + sync model (deliverable 6)
│   ├── 04-api-design.md          REST API design (deliverable 7)
│   ├── 05-deployment.md          Deployment guide (deliverable 19)
│   └── 06-ai-roadmap.md          Future AI roadmap (deliverable 20)
├── backend/                  ← FastAPI + SQLAlchemy + seed + tests + admin (deliverables 12,14,15,16,17)
│   ├── app/ (models, schemas, routers, auth, gamification, seed)
│   ├── static/admin.html        Content-management admin panel (deliverable 14)
│   ├── tests/                    Unit/integration tests (deliverable 17)
│   ├── Dockerfile · docker-compose.yml · requirements.txt · README.md
└── android/                  ← Kotlin · Compose · MVVM · Clean Arch · Hilt · Room (deliverables 11,13,18)
    ├── app/src/main/java/org/wildhope/app/
    │   ├── core/ (theme, design-system components, network, util)
    │   ├── domain/ (models, repository interfaces)
    │   ├── data/ (Retrofit api, Room, DataStore, repositories, mappers)
    │   ├── feature/ (home, explore, category, action, impact, learn, onboarding, navigation)
    │   └── di/ (Hilt modules)
    ├── app/src/test · app/src/androidTest   Unit + Compose UI tests (deliverable 18)
    └── build.gradle.kts · README.md
```

## Deliverables map (all 20)
1. Product Vision → docs/01 · 2. Personas → docs/01 · 3. Journeys → docs/01 ·
4. Information Architecture → docs/01 · 5. Prioritization → docs/01 ·
6. Database Schema → docs/03 · 7. API Design → docs/04 · 8. Wireframes → docs/02 ·
9. UI Components → docs/02 + android core/ui/components · 10. Design System → docs/02 + android core/ui/theme ·
11. Folder Structure → this README + both project trees · 12. Full Backend → backend/ ·
13. Full Android App → android/ · 14. Admin Panel → backend/static/admin.html ·
15. Sample Data → backend/app/seed/seed.py · 16. Seed Database → auto on startup / seed.py ·
17. Unit Tests → backend/tests · 18. UI Tests → android/app/src/androidTest ·
19. Deployment Guide → docs/05 · 20. Future AI Roadmap → docs/06.

## Quick start
```bash
# Backend (SQLite, zero external deps)
cd backend && pip install -r requirements.txt && AUTH_MODE=dev uvicorn app.main:app --reload
# → http://localhost:8000/docs   ·   admin: http://localhost:8000/admin

# Android
# open android/ in Android Studio (JDK 17), add google-services.json + Maps key, Run.
```

## Design decisions, in one line each
- **Hope>Fear is structural**, not cosmetic: success stories and personal impact are first-class, news is positive-first.
- **Guest-first onboarding**: first action in <1 min; no sign-in wall.
- **Offline-first** (Room cache + idempotent outbox): usable on a signal-dead beach.
- **Evidence on every action**: IUCN/NOAA/FAO/OWID citations build trust.
- **Modular by construction**: new species/country/NGO/challenge = one row, not a release.
