# Hopeling App - Product Review, QA Audit and Roadmap

Date: 2026-07-21. Reviewed as: principal engineer, product designer, UX
researcher, QA lead, accessibility specialist, child-experience designer,
architect. Scope: the full Flutter app (slices 1-14 plus Me/Good News/comics).

Verdict up front: the foundations are unusually strong for a pre-release app.
The save contract, forgiveness rules, offline-first content, idempotent queues
and constitution-by-test are better than most shipped apps. The weaknesses are
in seams, not pillars: first-run experience, cross-feature consistency, and
accessibility in the newest surfaces.

---

## Phase 1 - Feature-by-feature audit

**Foundation / design system.** Excellent: one theme file, serif/kicker voice,
Motion.still respected in every animated surface. Weak: fixed font sizes
everywhere means large Dynamic Type is unsupported (see a11y). No dark theme
(PWA has one) - noted for later; the dawnlight identity is deliberate.

**Onboarding.** Was missing entirely: a newcomer landed on a seed, a fact and
an unlabeled hold button. The Thumb Promise is the app's signature and nothing
taught it. FIXED: a one-time welcome card on the grove (only for xp==0, only
once) that explains the daily shape, the hold, and forgiveness in five lines.
Deliberately not a multi-screen onboarding carousel: the app itself is simple
enough that a carousel would be padding.

**Grove / tree.** Excellent: living tree with seasons/wind, growth ceremony,
welcome-back fog, presence-first header. The good-news section grounds the
whole "hope" premise with real sources. Minor: header now very quiet (by
design after Me moved to tabs).

**Daily Action Engine.** Excellent: explainable pick, alternates with reasons,
cooldowns, editorial gate. Consistent with Act tab. No issues found in review.

**Act tab.** Good. The Missions entry card gives it a second job cleanly.

**Explore / species.** Strong: PWA grouping, photo fallbacks, prewarming,
offline empty state (_FirstWind) exists. Deep links work. Minor: species
search typo-tolerance only 1 edit - fine.

**Learn.** Strong reader. GAP FOUND: with no cached content (first launch
offline) Learn showed a bare header over nothing. FIXED: honest empty state
with a retry ("The library arrives with your first connection").

**Guardians.** Constitutionally sound (non-ownership scans in tests), archive
without guilt, welcome letter. No changes.

**Missions.** BUG FOUND (the most important in this audit): completing a
mission rained one drop into the world pulse but never credited the person's
own grove - no log entry, no streak touch, no tree growth, no cloud backup.
Real field work counted for everyone except the person who did it. This broke
the "equal drops" principle from the inside. FIXED: first completion now runs
the same rules.complete path as any action (once, guarded by the same rained
flag; submitting later never double-credits). Test added.
Also FIXED: the mission cache only invalidated while the missions screen was
open; a content refresh followed by a deep link could serve stale missions.
loadMissions now self-subscribes to contentTick.

**Rain / Pulse.** Excellent and truthful. Now reached from Me; close
affordance added when pushed. The queue survived every corruption test.

**Circles.** Sound. Quiet-member mode, equal drops, no leaderboards. Cheers
column stale-week exclusion verified in tests.

**Kids Mode.** V1 is genuinely good (bands, gate, data minimization by
construction). The comic reader was visually rich but silent to screen
readers - FIXED (see a11y). Session end is enforced on the home screen but
does not yank an open comic away mid-page; reviewed and kept: never take a
book out of a child's hands, the gentle end comes on return.

**Robin.** The notification constitution holds. Resync-on-launch covers DST.
Edge case reviewed: notification opened after content changed - LinkResolver
falls back to home gracefully.

**Cloud sync / account.** One-document merge is deterministic and tested.
Account switching keeps device-local queues (pulse, observations, kids) -
reviewed and kept: queues are device history, not account property; the
save document itself is account-scoped.

**Me.** New this week; storyHead/timeline/graph tested. Feedback posts to the
same table as the PWA. Impact calculator is PWA-exact.

**Deep links.** All routes parse and resolve with home fallback. Mission ids
pass through un-lowercased (slugs are lowercase by construction) - fine.

**Error/loading/empty states.** LoadingSeed everywhere, OfflineLeaf on
network surfaces, _FirstWind on Explore, now Learn too. Feedback failure
shows an honest retry line.

---

## Phase 2 - User journeys (friction found)

New adult: landed unexplained (fixed with welcome card). Two-minute user:
grove alone serves them fully - good. Bird person / ocean person: Explore
grouping serves both; species deep links shareable. Parent: parent gate is
quick but the multiplication can be hard under a watching child - acceptable,
it is meant to be adult-hard. Child: comics + explore + discoveries is a
full loop. Offline user: every tab now has an honest state. Accessibility
user: was the weakest journey; see Phase 6.

Dead ends checked: none fatal. Archived circle, restored guardian, cancelled
mission draft, notification after uninstall/reinstall (resync) all land
somewhere sensible.

## Phase 3 - UX polish notes

Hierarchy and voice are consistent (kicker + serif + tx2 triad). Spacing is
mostly 4/8-grid. Transitions: risePush everywhere - consistent. Two nits
logged for later: Act filter chips wrap awkwardly on very narrow screens;
the Me room could surface the guardian emblem larger. Neither blocks release.

## Phase 4 - Technical review

Strengths: pure logic split from widgets (rules, missions, comic, me helpers
all unit-testable); one save document; queues share one pattern; asStrMap
defends every parse. Debts logged: (1) three near-identical bottom-sheet
scaffolds could be one helper - low value, high churn, deferred; (2) emoji
"icons" trade a11y for warmth - mitigated with labels/tooltips; (3) no
integration tests on real device - deferred to release hardening; (4) fixed
type scale (see a11y). No memory leaks found: every controller and listener
reviewed for dispose symmetry this pass.

## Phase 5 - QA attack notes

Airplane mode first launch: all tabs honest (after Learn fix). Duplicate
submissions: UUID-keyed at both queues, server-side `on conflict do nothing` -
safe. Interrupted upload: backoff + dead-letter. Stale content vs missions:
fixed this pass. Rotation/tablet: layouts are column-flow and survive width;
comic close-up crop verified clipped. Small screens: comic bubbles cap at
150-char single-panel fallback. Notification actions while app dead: handled
in background isolate. Deleted guardian id in save vs content: guardianById
returns null, UI hides row - safe.

## Phase 6 - Accessibility

Done this pass: comic pages now expose one clean semantic label per page
("Page 2 of 5. <the story words>", button, double-tap to hear) with all
decorative emoji, props and sound lettering excluded; page dots excluded.
Already good: tree rhythm label, hold button semantics, tooltips on all icon
buttons, Motion.still honored everywhere including comics.
Logged for release hardening: Dynamic Type audit (fixed px sizes), TalkBack
traversal order on Explore grids, Hebrew/RTL localization pass (structures
already use Directional geometry in key places), high-contrast check of
mint-on-white chips.

## Phase 7 - Kids Mode v2 brainstorm (no coins, no streak anxiety, ever)

Near-term, high-wonder, offline-friendly:
- Bedtime mode: night-scene comics + slower narration + hushed sounds after
  sunset; the shelf turns to "one more story, then sleep".
- Window scavenger hunts: "can you find something that flies / three greens /
  a cloud shaped like an animal" - observation, not collection.
- A nature journal: one drawing or one sentence per day, kept in the kid
  profile, shown as a little museum to the parent on request.
- Listen walks: play one real animal sound (from content, sourced), child
  guesses; then "now go hear a real bird - what did yours sound like?"
- Seasonal discoveries: the explore worlds gently reorder by month.
- Family mission Sundays: the existing family-eligible missions surfaced as
  a "do it together" card in kids mode with the parent gate on completion.
Future: AR leaf-viewer, cooperative circle drawing, memory book export.

## Phase 8 - Missing magic (moments, not features)

The moments people would remember: the first hold (exists), the fog after
absence (exists), a guardian letter arriving (partial), the tree's growth
crescendo (exists). Missing and worth building: the day the tree changes
stage while you watch after a mission (now possible - missions grow the
tree); a yearly "solstice letter" from the grove summarizing the year in
presence language; the first time a child finishes a comic and the star
appears on the shelf while they watch. Logged for the hardening slice.

## Phase 9 - Prioritized roadmap

CRITICAL (all fixed in this pass):
1. Mission completion never credited the personal grove - fixed + tested.
2. Stale mission cache after content refresh - fixed.
3. Comic reader unusable with a screen reader - fixed.
4. Learn dead-end on offline first launch - fixed.
5. No first-run explanation of the app's one core gesture - fixed.

HIGH IMPACT (next):
- Release hardening slice: signing, Play internal track, performance pass.
- Dynamic Type + TalkBack traversal audit.
- Bedtime mode for kids (small: time-gated shelf variant).
- Solstice/yearly letter.

NICE TO HAVE: sheet-scaffold refactor, Act chip layout on narrow screens,
guardian emblem in Me, dark theme.

FUTURE VISION: Hebrew/RTL localization, AR, cooperative kid activities,
iOS.

## Phase 10 - Implemented in this pass

- data/missions.dart: equal-drop credit (rules.complete on first completion,
  idempotent), cloud push, saveTick; self-invalidating mission cache.
- features/kids/comic.dart: full semantics pass (one label per page,
  decoratives excluded, dots excluded).
- features/learn/learn_screen.dart: offline-first-launch empty state.
- features/grove/grove_screen.dart: one-time newcomer welcome card
  (xp==0 only, dismissed forever, forgiveness stated plainly).
- Tests: mission grove-credit (missions_test), all prior suites unchanged.
