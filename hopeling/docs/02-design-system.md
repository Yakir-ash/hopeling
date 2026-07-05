# Hopeling - Design System, Wireframes & UI Components
*Deliverables 8-10*

---

## 1. Design Language

Material 3 (Material You) with a nature-inspired custom color scheme. **Why M3:** dynamic color, built-in accessibility contrast roles, first-class Compose support, and users' muscle memory on Android. We keep M3 structure but brand it with earth tones and organic shapes (24dp+ corner radii, blob-shaped hero illustrations).

### 1.1 Color - "Earth & Hope" palette

| Token | Light | Dark | Use |
|---|---|---|---|
| primary | #2E6B4F (Forest) | #8FD5AF | Buttons, active nav, streak |
| onPrimary | #FFFFFF | #00391F | |
| primaryContainer | #B2F1CC | #14513A | Action cards |
| secondary | #3E6373 (Ocean) | #A6CCDF | Ocean spotlight, links |
| secondaryContainer | #C2E8FA | #254B5A | |
| tertiary | #A2652F (Terra) | #F0BE8C | Badges, warm accents |
| tertiaryContainer | #FFDCC0 | #7F4A17 | |
| surface | #F8FAF5 | #101512 | |
| surfaceVariant | #DCE5DB | #3F4942 | |
| error | #BA1A1A | #FFB4AB | Sparingly; never for threat content |
| success (custom) | #386A20 | #9CD67D | "I did this", victories |

Gradients (hero cards only): Forest→Ocean `#2E6B4F→#3E6373`; Sunrise `#F0BE8C→#E88D67` (achievements); Deep Sea `#0B3D4C→#123A2E` (ocean spotlight). **Why:** gradients reserved for celebration/hero moments keeps the rest of the UI calm and content-first.

Threat severity uses **amber-to-terra**, never blood-red - supports the "informative, not alarming" ethics rule.

### 1.2 Typography

- Display/Headlines: **Fraunces** (soft serif - warm, editorial, "nature journal" feel)
- Body/Labels: **Inter** (neutral, superb legibility, excellent i18n coverage)
- Scale: M3 default type scale; all sizes in `sp`; supports 200% font scaling without truncation (test gate in UI tests).

### 1.3 Shape & Motion
- Cards: 24dp radius (large, friendly). Chips/buttons: full-pill.
- Motion: M3 `EmphasizedEasing`, 200-350ms. Signature moments: "I did this" → seed-sprout animation (Lottie); streak flame gentle pulse; page transitions fade-through. **Why soft/slow-ish:** calm brand, and respects `Reduce motion` (all Lottie gated on `LocalAccessibilityManager`).

### 1.4 Iconography & Illustration
- Icons: Material Symbols Rounded (professional, consistent weights).
- Illustrations: flat organic style with grain texture; animals always dignified, never suffering. Every category has a hero illustration + emoji fallback.
- Photos: curated, hopeful (animals in habitat, rescuers at work). Admin flag `is_graphic` blocks publication.

### 1.5 Accessibility (first-class, MVP-gated)
- All touch targets ≥48dp; contrast ≥4.5:1 (M3 roles enforce this).
- Full TalkBack semantics on custom components; contentDescription lint rule set to error.
- Dynamic type to 200%; RTL support (Hebrew/Arabic ready); reduce-motion honored.
- Color never sole signal (difficulty = color + label + icon count).

---

## 2. Core UI Components (Compose)

| Component | Description |
|---|---|
| `WildCard` | Base elevated card, 24dp radius, optional gradient header |
| `ActionCard` | Title, cause chip, difficulty pips (●○○), time & cost labels, CTA |
| `FactCard` | Fraunces quote-style fact + source attribution + share |
| `ChallengeBanner` | Progress ring, points, days left |
| `StreakFlame` | Animated flame + day count; dormant (not dead) state when broken |
| `ImpactStat` | Big number + unit + sparkline |
| `CauseChip` | Emoji + label filter chip, selectable |
| `StatusBadge` | IUCN status (EX/EW/CR/EN/VU/NT/LC) with standard IUCN colors |
| `StoryCard` | Success story: image, headline, "hope tag" (🎉 Victory / 🌱 Progress) |
| `LessonTile` | Course lesson with duration, done-check, offline icon |
| `QuizSheet` | Bottom-sheet quiz with instant feedback |
| `BadgeMedal` | Achievement medal with unlock animation |
| `EmptyState` | Illustrated, always suggests an action ("Nothing here yet - try a challenge") |
| `EvidenceRow` | Source favicon + citation + external-link |
| `SectionHeader` | Title + "See all" |

---

## 3. Wireframes (annotated)

### 3.1 Home
```
┌─────────────────────────────┐
│ 🌿 Hopeling        🔔  🔍   │ top bar
│ Good morning, Maya   🔥 6   │ greeting + streak
│ ┌─────────────────────────┐ │
│ │ 🐙 TODAY'S FACT         │ │ FactCard (gradient hero)
│ │ "Octopuses have three   │ │
│ │  hearts…"    [Share] ⋯  │ │
│ └─────────────────────────┘ │
│ ┌─────────────────────────┐ │
│ │ ⚡ TODAY'S ACTION  5min │ │ ActionCard
│ │ Switch one product to   │ │
│ │ palm-oil-free   [Do it] │ │
│ └─────────────────────────┘ │
│ ┌───────────┐┌───────────┐  │
│ │🏆 Daily   ││📈 Impact  │  │ two half-cards
│ │Challenge  ││ 12 actions│  │
│ └───────────┘└───────────┘  │
│ ── Success story of the day │ StoryCard
│ ── Animals needing attention│ horizontal carousel
│ ── 🌊 Ocean Spotlight       │ deep-sea gradient card
│ ── Rescue story             │
├─────────────────────────────┤
│ 🏠   🧭   (⚡)   🎓   👤    │ bottom nav, Act center-emphasized
└─────────────────────────────┘
```
*Why this order:* fact (dopamine/learning) → action (mission) → gamification → hope content. The user's first two scroll-stops always satisfy "learn one thing, do one thing."

### 3.2 Explore
```
┌─────────────────────────────┐
│ Explore            [Search] │
│ [All][Oceans][Wildlife][Farm]… filter chips
│ ┌─────┐ ┌─────┐ ┌─────┐    │ 3-col grid,
│ │ 🐘  │ │ 🐢  │ │ 🐋  │    │ illustrated tiles
│ │Eleph│ │Turtl│ │Whale│    │
│ …22+ categories…            │
└─────────────────────────────┘
```

### 3.3 Category Detail (e.g., Sea Turtles)
```
┌─────────────────────────────┐
│ ← Sea Turtles        [♡]    │ collapsing hero image
│ [EN Endangered] ▼ trend     │ StatusBadge + population
│ Tabs: Overview·Threats·Hope·│
│       Act·Orgs·Media        │
│ Overview: science, habitat, │
│ facts, IUCN citation        │
│ Hope tab: success stories   │ ← "Hope" is a TAB, structurally
│ Act tab: filtered actions   │    equal to "Threats"
└─────────────────────────────┘
```

### 3.4 Action Center
```
┌─────────────────────────────┐
│ ⚡ Act                      │
│ [Easy ●][Medium ●●][High ●●●] difficulty segmented
│ [🏠 Home][🌳 Outdoor][💻 Online][💰 Donate]
│ ┌─────────────────────────┐ │
│ │ Install a bee hotel ●●  │ │
│ │ 🐝 Pollinators · 2h · $15│ │
│ └─────────────────────────┘ │
│ …list…                      │
└─────────────────────────────┘
Action detail:
│ Why it matters (evidence)   │
│ Estimated impact            │
│ Steps 1-2-3                 │
│ Sources: [IUCN] [FAO]       │
│ [ ✓ I did this ]            │ → sprout animation → impact logged
```

### 3.5 Impact Tracker ("Me")
```
│ Level 4 · Seedling → Sapling │ XP ring
│ 🔥 12-day streak             │
│ ┌────┐┌────┐┌────┐          │ ImpactStat grid:
│ │2.4kg││ 3  ││ $45│          │ plastic · trees · donated
│ │ 8h ││ 5  ││31kg│          │ hours · animals · CO₂
│ Badges shelf · Courses done  │
```

### 3.6 Learn / Challenges / News / Map - follow the same card grammar; Map uses Google Maps with country polygons + layer FABs; News feed is StoryCards with hope-tags, "heavier" news collapsed behind a "context" expander (positive-first, never hidden - honest but hopeful).
