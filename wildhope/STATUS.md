# WildHope - repository status (single source of truth)
_Last updated: 2026-07-03. Read this before touching any code._

There are three generations of work here. Only one is "current." This file exists
so the codebase doesn't drift into confusion.

## ✅ CURRENT - build here
| Path | What it is | Status |
|---|---|---|
| `../wildhope-web/` | Installable PWA (HTML/JS). Offline, impact graph, real content. | **LIVE MVP - actively developed.** This is the app right now. |
| `docs/07-production-blueprint.md` | Production plan: **Flutter + Supabase**, data/licensing, roadmap. | **Current go-forward target** for the eventual native app. |

## 🟡 PLANNED - not started
| Item | Notes |
|---|---|
| Flutter + Supabase app | The native step **after** the PWA validates the habit loop. Do not start yet. |

## 🗄️ SUPERSEDED - reference only, do NOT maintain
| Path | Why it exists | Status |
|---|---|---|
| `android/` | 1st-gen native app (Kotlin/Compose/Hilt/Room). | Superseded by the Flutter decision (Doc 07). Reference only. |
| `backend/` | 1st-gen backend (FastAPI/Postgres). | Superseded by the Supabase decision (Doc 07). Reference only. Data model still informs the Supabase schema. |
| `android-quickstart/` | Abandoned zero-config demo copy of `android/`. | **DEAD / does not compile.** Delete when possible (this environment blocked deletion). Ignore. |

## Decision log
1. v1: built native Kotlin app + FastAPI backend + admin + HTML prototype.
2. Pivot: user wants production, cross-platform, solo/bootstrapped → chose **Flutter + Supabase** (Doc 07). Kotlin/FastAPI become reference.
3. Current: user chose to **keep improving the PWA** as the live MVP before any native rewrite. → `wildhope-web/` is the working product; Flutter is the planned next platform.

## Rule
One codebase at a time. No hand-synced parallel apps. When the PWA is validated and you
commit to native, `wildhope-web` + Doc 07 become the spec for a **single** Flutter app,
and `android/` / `android-quickstart/` / `backend/` get archived or deleted.
