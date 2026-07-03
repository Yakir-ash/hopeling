# WildHope — Database Schema (PostgreSQL)
*Deliverable 6*

## Design rationale
- **Content vs. user data separated** cleanly: content tables (species, actions, courses, news…) are admin-curated and cacheable/CDN-able; user tables are per-user and privacy-sensitive. This enables offline-first sync (content = pull-only, user data = push queue).
- **`sources` as a first-class table** — every fact/action/threat row can cite sources. Evidence is a product feature, so it's a schema feature.
- **Taxonomy via `categories`** (species AND ecosystems AND domains in one polymorphic table) so adding a new species/country/cause is an INSERT, not a migration — the scalability requirement.
- **i18n-ready:** user-visible text columns duplicated in `*_translations` tables keyed by locale; MVP ships English rows only.
- UUID PKs (offline-generated client IDs merge without collisions). `created_at/updated_at` everywhere. Soft-delete via `is_active`.

```sql
-- ============ CONTENT ============
CREATE TABLE sources (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,             -- e.g. 'IUCN Red List'
  url TEXT,
  credibility TEXT NOT NULL DEFAULT 'high',  -- high|peer_reviewed|gov|ngo
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE categories (          -- species, ecosystems, domains
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  slug TEXT UNIQUE NOT NULL,       -- 'sea-turtles'
  kind TEXT NOT NULL,              -- species|ecosystem|domain
  name TEXT NOT NULL,
  emoji TEXT,
  hero_image_url TEXT,
  summary TEXT,
  scientific_info TEXT,
  iucn_status TEXT,                -- EX|EW|CR|EN|VU|NT|LC|NA
  population_trend TEXT,           -- increasing|stable|decreasing|unknown
  is_active BOOLEAN NOT NULL DEFAULT true,
  sort_order INT NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE facts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  category_id UUID REFERENCES categories(id),
  body TEXT NOT NULL,
  source_id UUID REFERENCES sources(id),
  is_daily_eligible BOOLEAN NOT NULL DEFAULT true,
  is_active BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE threats (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  category_id UUID NOT NULL REFERENCES categories(id),
  title TEXT NOT NULL,
  description TEXT NOT NULL,
  severity TEXT NOT NULL DEFAULT 'medium',   -- low|medium|high|critical
  source_id UUID REFERENCES sources(id),
  is_active BOOLEAN NOT NULL DEFAULT true
);

CREATE TABLE actions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  slug TEXT UNIQUE NOT NULL,
  title TEXT NOT NULL,
  why_it_matters TEXT NOT NULL,
  estimated_impact TEXT NOT NULL,           -- human-readable, evidence-based
  impact_metric TEXT,                       -- maps to impact tracker: plastic_kg|trees|money|hours|animals|carbon_kg|generic
  impact_value NUMERIC DEFAULT 0,           -- default increment per completion
  difficulty TEXT NOT NULL,                 -- easy|medium|high_impact
  modality TEXT NOT NULL DEFAULT 'home',    -- home|outdoor|online|financial
  cost_level TEXT NOT NULL DEFAULT 'free',  -- free|low|medium|high
  time_minutes INT NOT NULL DEFAULT 5,
  steps JSONB NOT NULL DEFAULT '[]',        -- ["step1","step2"]
  evidence JSONB NOT NULL DEFAULT '[]',     -- [{"source":"IUCN","url":"..."}]
  xp INT NOT NULL DEFAULT 10,
  is_active BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE action_categories (            -- M:N action↔cause
  action_id UUID REFERENCES actions(id) ON DELETE CASCADE,
  category_id UUID REFERENCES categories(id) ON DELETE CASCADE,
  PRIMARY KEY (action_id, category_id)
);

CREATE TABLE organizations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  description TEXT,
  website TEXT,
  logo_url TEXT,
  is_vetted BOOLEAN NOT NULL DEFAULT false, -- admin-verified
  focus TEXT,                                -- oceans|wildlife|farm|pets|...
  country_code TEXT,
  is_active BOOLEAN NOT NULL DEFAULT true
);

CREATE TABLE org_categories (
  org_id UUID REFERENCES organizations(id) ON DELETE CASCADE,
  category_id UUID REFERENCES categories(id) ON DELETE CASCADE,
  PRIMARY KEY (org_id, category_id)
);

CREATE TABLE stories (                       -- success/rescue stories & campaigns
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  kind TEXT NOT NULL,                        -- success|rescue|campaign
  title TEXT NOT NULL,
  body TEXT NOT NULL,
  image_url TEXT,
  hope_tag TEXT DEFAULT 'progress',          -- victory|progress|rescue
  category_id UUID REFERENCES categories(id),
  country_code TEXT,
  source_id UUID REFERENCES sources(id),
  published_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  is_active BOOLEAN NOT NULL DEFAULT true
);

CREATE TABLE news_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title TEXT NOT NULL,
  summary TEXT NOT NULL,
  url TEXT,
  image_url TEXT,
  sentiment TEXT NOT NULL DEFAULT 'positive', -- positive|neutral|context
  topic TEXT,                                  -- rescue|science|policy|reserve|community
  category_id UUID REFERENCES categories(id),
  source_id UUID REFERENCES sources(id),
  published_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  is_active BOOLEAN NOT NULL DEFAULT true
);

CREATE TABLE courses (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  slug TEXT UNIQUE NOT NULL,
  title TEXT NOT NULL,
  description TEXT,
  image_url TEXT,
  badge_id UUID,                              -- awarded on completion
  is_premium BOOLEAN NOT NULL DEFAULT false,
  sort_order INT NOT NULL DEFAULT 0,
  is_active BOOLEAN NOT NULL DEFAULT true
);

CREATE TABLE lessons (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  course_id UUID NOT NULL REFERENCES courses(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  duration_minutes INT NOT NULL DEFAULT 7,
  content_blocks JSONB NOT NULL DEFAULT '[]', -- [{type:text|image|quiz, ...}]
  quiz JSONB NOT NULL DEFAULT '[]',           -- [{q, options[], answer_idx, explain}]
  sort_order INT NOT NULL DEFAULT 0
);

CREATE TABLE challenges (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  slug TEXT UNIQUE NOT NULL,
  title TEXT NOT NULL,
  description TEXT NOT NULL,
  points INT NOT NULL DEFAULT 50,
  cadence TEXT NOT NULL DEFAULT 'weekly',     -- daily|weekly|monthly
  starts_at TIMESTAMPTZ,
  ends_at TIMESTAMPTZ,
  impact_metric TEXT,
  impact_value NUMERIC DEFAULT 0,
  is_active BOOLEAN NOT NULL DEFAULT true
);

CREATE TABLE badges (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  slug TEXT UNIQUE NOT NULL,
  name TEXT NOT NULL,
  description TEXT,
  icon TEXT,                                   -- emoji or asset key
  criteria JSONB NOT NULL DEFAULT '{}'         -- {"actions_completed": 10}
);

CREATE TABLE map_regions (                     -- Global Map content per country
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  country_code TEXT NOT NULL,                  -- ISO 3166-1 alpha-2
  layer TEXT NOT NULL,                         -- threatened|projects|trade|pollution|deforestation|poaching|reserves|parks|success
  title TEXT NOT NULL,
  description TEXT,
  lat DOUBLE PRECISION, lng DOUBLE PRECISION,
  category_id UUID REFERENCES categories(id),
  source_id UUID REFERENCES sources(id),
  is_active BOOLEAN NOT NULL DEFAULT true
);
CREATE INDEX idx_map_regions_country ON map_regions(country_code, layer);

-- ============ USERS ============
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  firebase_uid TEXT UNIQUE,                    -- NULL for guest-only until link
  display_name TEXT,
  email TEXT,
  avatar_url TEXT,
  locale TEXT NOT NULL DEFAULT 'en',
  causes JSONB NOT NULL DEFAULT '[]',          -- ["oceans","pets"]
  xp INT NOT NULL DEFAULT 0,
  level INT NOT NULL DEFAULT 1,
  streak_days INT NOT NULL DEFAULT 0,
  last_active_date DATE,
  is_premium BOOLEAN NOT NULL DEFAULT false,
  is_admin BOOLEAN NOT NULL DEFAULT false,
  notification_prefs JSONB NOT NULL DEFAULT '{"daily_fact":true,"weekly_challenge":true,"victories":true,"events":false,"goals":true}',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE action_completions (
  id UUID PRIMARY KEY,                         -- client-generated for offline sync
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  action_id UUID NOT NULL REFERENCES actions(id),
  completed_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  note TEXT,
  UNIQUE (user_id, action_id, completed_at)
);

CREATE TABLE challenge_completions (
  id UUID PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  challenge_id UUID NOT NULL REFERENCES challenges(id),
  completed_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE lesson_progress (
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  lesson_id UUID REFERENCES lessons(id) ON DELETE CASCADE,
  completed_at TIMESTAMPTZ,
  quiz_score INT,
  PRIMARY KEY (user_id, lesson_id)
);

CREATE TABLE user_badges (
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  badge_id UUID REFERENCES badges(id) ON DELETE CASCADE,
  earned_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (user_id, badge_id)
);

CREATE TABLE impact_entries (                  -- the Impact Tracker ledger
  id UUID PRIMARY KEY,                         -- client-generated
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  metric TEXT NOT NULL,                        -- plastic_kg|trees|money|hours|animals|carbon_kg|generic
  value NUMERIC NOT NULL,
  source_kind TEXT NOT NULL,                   -- action|challenge|manual|event
  source_id UUID,
  occurred_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_impact_user_metric ON impact_entries(user_id, metric);

-- ============ COMMUNITY (v1.x) ============
CREATE TABLE groups_ (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL, description TEXT,
  country_code TEXT, city TEXT,
  owner_id UUID REFERENCES users(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE TABLE group_members (
  group_id UUID REFERENCES groups_(id) ON DELETE CASCADE,
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  role TEXT NOT NULL DEFAULT 'member',
  PRIMARY KEY (group_id, user_id)
);
CREATE TABLE events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  group_id UUID REFERENCES groups_(id) ON DELETE CASCADE,
  title TEXT NOT NULL, kind TEXT NOT NULL DEFAULT 'cleanup',
  starts_at TIMESTAMPTZ, lat DOUBLE PRECISION, lng DOUBLE PRECISION,
  created_by UUID REFERENCES users(id)
);
CREATE TABLE posts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  group_id UUID REFERENCES groups_(id),
  kind TEXT NOT NULL DEFAULT 'share',          -- share|question|recommendation|celebration
  body TEXT NOT NULL,
  image_url TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ============ i18n (pattern; one example) ============
CREATE TABLE category_translations (
  category_id UUID REFERENCES categories(id) ON DELETE CASCADE,
  locale TEXT NOT NULL,
  name TEXT, summary TEXT, scientific_info TEXT,
  PRIMARY KEY (category_id, locale)
);

-- Full-text search
CREATE INDEX idx_actions_fts ON actions USING GIN (to_tsvector('english', title || ' ' || why_it_matters));
CREATE INDEX idx_categories_fts ON categories USING GIN (to_tsvector('english', name || ' ' || coalesce(summary,'')));
```

## Sync model (offline-first)
- **Content pull:** client stores `last_synced_at`; `GET /sync/content?since=` returns changed rows per table. Room mirrors content tables.
- **User push:** completions/impact entries created offline with client UUIDs, queued in Room, POSTed in batch when online; server upserts by PK (idempotent).
- **Why:** guarantees the app is fully usable on a plane or in the field (beach cleanups often have no signal — a core use case).
