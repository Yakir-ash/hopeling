# Accessibility in Hopeling

Target: WCAG 2.2 AA where it applies to mobile, plus the Android
and Apple accessibility guidelines. Accessibility is not a feature
here; it is a constraint every feature is built inside, and much of
Hopeling's constitution already IS accessibility by another name.

## What the constitution already guarantees

- **No timers, no hurry, no fail states** - the entire app is
  usable at any pace, which is the single biggest accessibility
  property a kids' product can have (WCAG 2.2.1, exceeded).
- **No precision gestures.** Every game is whole-surface taps or
  broad drags: Salmon Run taps anywhere, Pond Hopper taps anywhere
  on water, the Window needs no input at all. Nothing requires
  small targets, double taps, or steady hands (WCAG 2.5.1, 2.5.7).
- **Reduced motion respected everywhere**: the Living Sky's night
  ticker, fireflies, and shooting star stay still; the Breath is
  off; games run calmer physics; Lottie freezes to first frame
  (WCAG 2.3.3).
- **Recorded narration** (fable or silence) reads kid content
  aloud - pre-readers, dyslexic readers, and tired eyes all get
  the same stories.
- **Nothing is color-only.** Progress is leaves and words, dipped
  pads sink in shape as well as shade, mystery verdicts carry
  glyphs and labels, matched memory cards now carry a leaf mark
  (WCAG 1.4.1).
- **Consistent, predictable navigation**: four kid rooms, always
  in the same order, always labeled (WCAG 3.2.3).

## What this pass fixed

- **Contrast**: kidInkLight (all kid-mode secondary text) was
  3.67:1 on cream - below AA. Now 0xFF756878 at 4.99:1. Adult tx2
  was audited and passes at 5.88:1 (WCAG 1.4.3).
- **Screen reader labels and states**: kid nav announces the
  selected room; nocturnal neighbors announce "awake right now";
  path chapters speak "walked / not walked yet" instead of a bare
  glyph; mystery verdict marks speak "the true answer" / "your
  guess"; the Daily Wonder's expander is a real button with an
  expanded state; Atlas cards read as one sentence (MergeSemantics)
  instead of fragments.
- **Decorative elements silenced**: the ambient butterfly and
  similar ornaments are ExcludeSemantics so readers never stumble
  through decoration.
- **Touch targets**: chapter tiles and mystery suspect rows
  enlarged comfortably past 48dp.
- **Automated guards**: test/a11y_test.dart runs the Android
  tap-target and labeled-target guidelines against the Atlas,
  Paths, Mystery, and Field Guide screens on every test run.
  Regressions fail CI, not children.

## Honest open items (the next passes)

1. **Dynamic type audit.** Text scales, but fixed-height surfaces
   (108px room headers, game HUDs) need a max-scale walkthrough on
   device and probably FittedBox guards. Test at 200% font size.
2. **Full TalkBack/VoiceOver walkthrough on hardware.** Labels are
   in place; the lived experience (focus order, back gestures,
   game canvases announcing their intro copy) needs a real session
   with the screen reader on. Games should gain a Semantics
   description of how to play on the canvas itself.
3. **Captions for the cinema.** The kids' film has narrationless
   audio and no subtitle track yet. Needs a .srt authored and a
   caption overlay in the player (WCAG 1.2.2). The Storyteller
   text content is inherently its own transcript; the film is the
   gap.
4. **Keyboard and switch access** matter mainly for future web/
   desktop builds; Flutter's defaults carry most of it, but focus
   states should be verified when we ship those targets.
5. **Localization posture**: the app is English-only today. When
   Hebrew arrives, RTL layout and narration coverage become
   accessibility issues too - flagging now so the content pipeline
   plans for it.
6. **Sky-dependent text**: adaptive ink on the living sky is
   luminance-driven (skyIsDark), but dawn/dusk mid-tones deserve a
   contrast sweep across the full 24h palette.

## The standing rule for every new feature

Before merging anything new, answer four questions: Can it be used
slowly? Can it be used by ear? Can it be used without seeing
color? Is every tappable thing big and labeled? If any answer is
no, it is not done - beauty that excludes is not Hopeling beauty.
