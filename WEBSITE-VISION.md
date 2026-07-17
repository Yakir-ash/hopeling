# Hopeling - The Next Generation
### The Creative Director's build document. Every criticism from WEBSITE-REVIEW.md, redesigned. Every idea classified: 🟢 Website only · 🟡 Shared · 🔵 Native app only.

---

## 0. The one sentence everything obeys

**The app is where one person keeps a promise. The website is where the world keeps its evidence.**

The app: personal, daily, quiet, offline, yours. 🔵 Streaks, progress, ceremonies, reminders, circles, notifications, widgets - all of it stays in the pocket.
The website: public, communal, big-screen, open to everyone forever, no login existing anywhere on it. 🟢 Knowledge, stories, archives, experiences, classrooms, proof.
The membrane between them is thin and one-way by design: the website plants the feeling; the app grows the habit. The only things that live on both sides 🟡 are the content contract (content.json), the pledge, and the rain - because those three ARE the brand.

The test for every future decision, verbatim from the brief: "Would this be better on a large desktop screen than on a phone?" Yes → website. No → app. Both → it is probably the rain.

---

## 1. The World - what the website IS

The website stops being pages that share a stylesheet and becomes **a place: one continuous meadow under one continuous sky.**

Three site-wide systems make this true, and they are systems, not decorations:

### 1a. The Sky (already half-built - finish it) 🟢
One sky, everywhere, always matching the visitor's real hour, persisting across page navigations (View Transitions API: the sky layer never blinks, only the ground content crossfades beneath it). Evolution beyond today: the sky also knows the **season** (four palette sets, shifted a half-degree, two weeks around each solstice and equinox) and the **weather of hope** (rain density is driven by the real pulse, see 1c). Night gets true stars with one slow satellite. Winter nights get sparse snow instead of rain. Dawn is always the warmest render the engine can make, because dawn is the thesis.

### 1b. The Ground Line 🟢 - the new signature motif
A single hand-drawn 2px soil line runs horizontally through every page of the site, at a consistent height rhythm. Everything grows from it: headings rise out of it, cards sprout above it, the footer is literally below it (roots, seeds, the sitemap as buried treasure). This one motif kills the "white rounded template" problem site-wide, because content no longer floats in a void - it stands on the same earth on every page. It is cheap (a repeating SVG border and a layout rule) and it is instantly ownable: see a ground line with things growing from it, think Hopeling.

The motion rule that comes with it: **nothing fades up out of nowhere anymore.** Content enters by growing up from the ground line - a 300ms rise with a 1 to 2 degree settle, like a stem finding vertical. Fade-up-on-scroll (the stock photography of motion) is deleted from the vocabulary.

### 1c. The Rain of Record 🟡 - the heartbeat
The rain stops being ambience and becomes evidence, everywhere on the site:
- On load: fetch the true pulse. The counter renders as a slow odometer settling onto the real number.
- Every 45s: poll. If the number grew while you watched, it ticks up one digit at a time and exactly that many drops fall through the page. You watched someone, somewhere, act. This is the site's single most important micro-interaction and it costs thirty lines.
- On return: localStorage remembers your last-seen count. "While you were away, 214 drops fell." Then the difference falls, gently, over a minute.
- Drops are 2x today's size on heroes. The signature is never again a whisper.
In the app 🔵 the rain stays personal (your drop joins it). On the site 🟢 it is the public weather. Same rain, two roles - the one correctly shared thing.

---

## 2. The Homepage - "One Day on Earth"

Throw the section-stack away. The homepage becomes one continuous scroll through a single day, on one persistent ground line, under one moving sky. Five chapters, no cards, no phone mockup anywhere.

**Chapter 1 - DAWN / The Seed.** You arrive at first light (or your real hour, then the scroll takes over the sky). Near-empty screen: the ground line, a seed in the soil, six words in serif: "The news is heavy. Hope is a habit." Below the seed, small: "scroll." As you scroll, the seed cracks - one gold gleam, the only gold on the page.
**Chapter 2 - MORNING / The Sprout: learn.** The sky warms. The sprout rises AS YOU SCROLL - one drawn SVG tree, continuous growth bound to scroll progress, branch paths extending by interpolation, never emoji, never steps. Beside it, today's real fact (from dailyIndex, never frozen) set as a museum plate with a real photograph.
**Chapter 3 - AFTERNOON / The Tree: act.** Full daylight. The tree is waist-high now, first bird lands (2s glide, settles, stays). Today's real action appears - one, not a menu - with its honest why. This chapter states the whole product in twelve seconds.
**Chapter 4 - DUSK into NIGHT / The Rain: together.** The sky performs its best scene: dusk pours in, stars arrive, and in the dark the true counter glows and ticks, drops falling, each one captioned once: "one person, somewhere, just now." The forgiveness copy lives here ("miss a week - it rests; it never dies") because night is where forgiveness belongs.
**Chapter 5 - DAWN AGAIN / The Grove.** The scroll ends where it began, light returning, the tree now full with friends in its branches. "Night always ends. Your tree is waiting." One CTA. One. Then the footer-below-the-ground-line: roots, sitemap, and the promoted human line in full-size serif: "Made by one person and a growing forest of helpers."

Mobile: identical story, lighter physics - sky gradients and the growing tree survive; parallax layers and cursor systems do not. The story is the design, so nothing is lost but weight.
Signature moment: someone screen-records the dusk-to-dawn turn with the live counter ticking, posts it, and the recording is the ad.

---

## 3. Motion Language - "Grown, not animated"

Four named movements. Everything on the site uses one of them or does not move.

- **RISE** (content entering): 300ms grow-up from the ground line, ease-out, 1deg overshoot settle. Replaces every fade-up.
- **SWAY** (the world living): 4 to 7s sine loops, amplitude under 3px, desynchronized per element. Leaves, grass, branch tips, moth wings. Never on text.
- **FALL** (rain, leaves, snow, petals): linear gravity with per-particle drift. Only FALL may cross the whole viewport.
- **BLOOM** (joy only): a spring curve, reserved for exactly three events sitewide - the counter ticking, a pledge completing, a poster downloading. Scarcity is what keeps joy feeling like joy.

Hover is its own rule: **LEAN.** Interactive elements tilt 1.5deg toward the cursor and brighten half a step, like plants noticing light. No scale-up-and-shadow (that is every startup's hover). Buttons press DOWN 1px on click (into soil), not up.
Page transitions: sky persists, ground content crossfades 200ms. The world never reloads; you just walk somewhere else in it.
The cursor at night hours becomes a faint firefly glow (desktop only); grass blades near it lean away as it passes. Reduced-motion: RISE becomes opacity, SWAY/FALL/LEAN/firefly stop, BLOOM becomes a color change. The site must be fully beautiful frozen.

---

## 4. Visual Language - beyond the white card

The white rounded card is retired as the default container. Its replacements, by content type:

- **The Plate** (facts, daily content): full-bleed photograph, serif overlay, source in small caps, per-world color wash (Deepwater for oceans, Fern for forests, dawn gold for gardens - the same wash system as the app's atlas). With build-time Wikipedia baking, every plate gets a real photo. Downloadable as a poster with a small gold seed-seal stamped in the corner - the seal is the watermark and the brand ad in one.
- **The Field Note** (threats, hope, science blocks): paper-textured journal entry with a pressed-leaf duotone in the corner and a taped-photo aesthetic for images. Content reads as collected from the field, not generated by a CMS.
- **The Ring** (every number on the site): statistics render inside concentric tree-ring marks, the number in serif at center. "12,400" in a ring print says grown-over-time; the same number in a stat card says dashboard.
- **The Chip Path** (navigation between species/worlds): chips become small footprints along the ground line.
Typography evolution: ship self-hosted Fraunces (one variable font, cached by the SW, zero third-party requests) for every serif moment; system sans for UI. Color evolution: today's palette holds, plus the four seasonal half-degree sets, plus enforcement of the gold law - gold appears ONLY at: the seed's gleam, pledge rings, poster seals, equinox lines. Four uses. If a fifth appears in a mockup, the mockup is wrong.
Illustration direction: "pressed botanical duotone" (DESIGN.md) graduates from the app to the site for empty states, chapter dividers, the 404 fox, and classroom printables - one hand, one style, everywhere.

---

## 5. Every page, redesigned

**/today → The Daily Plate** 🟢 (content 🟡 shared with app via dailyIndex)
Purpose: the bookmark habit. Emotion: morning calm. The build-day fact and action are baked statically (crawlers finally see content); JS swaps only if the visitor's date differs. Full-bleed plate with photo, the action as a field note beneath, and two whispers: at the bottom, "Yesterday, this page said..." (one line, builds the returning rhythm), and during night hours, "The fact changes at midnight. You could be the first to see tomorrow." Signature: the page quietly says the day of week in the kicker, set from the visitor's clock - it always feels freshly printed.

**/wins → The Archive of Good** 🟢
Purpose: the antidote page; the shareable link for someone having a bad news day. Emotion: relief, then awe at accumulation. Redesign: magnitude hierarchy - each month one pinned win renders large with photo (chosen by simple heuristic: longest source coverage), the rest as field notes; filters as footprint chips (🐋 oceans, 🌳 forests, all); after the twentieth item, a full-width quiet interstitial in serif, no container: "Every one of these actually happened." Counter framing changes from "16 and counting" to what it truly is: "This archive has never deleted an entry. It only grows." Signature: the year dividers are drawn as tree rings you scroll through - the archive literally reads as a trunk in cross-section.

**/atlas → The Worlds** 🟢
Index: 28 dioramas, not tiles - each card washed in its world's own atmosphere with its baked hero photo behind a color gradient, name in serif, one sway element per card (a fin, a leaf, a wing; 6s loops, desynchronized). Hovering a diorama leans it and deepens its wash. World pages: hero becomes the world's baked photograph under its wash; content blocks become field notes; the IUCN bar keeps its draw-in and gains text labels; every world keeps its "ends in agency" actions. Signature: each world's header contains one slow ambient inhabitant - a whale surfacing across the oceans header over 8 seconds, once, per visit. People will reload pages to see it again, and that is the point.

**/species → The Portraits** 🟢
Build-time baked (photo at 800px, extract, attribution) so every portrait is real HTML: photograph full-bleed top, name in serif over it, the IUCN draw, population ring, "one thing you can do for them today," sources block for the student citing it. The homework kid finds the answer in the first screenful; the crawler finds it too. Remove: "Loading portrait..." forever.

**/guardians → The Vows** 🟡 (the pledge is the shared object)
The portraits stay; the door opens: hold-to-pledge works on the web - press and hold, a gold ring draws around the portrait (the sacred gold, its sacred use), and a certificate renders on canvas: species, date, the visitor's first name if they offer it, the seed-seal. Downloadable, shareable, and a quiet line: "Your pledge will be waiting in the app." The certificate is the only conversion device on the entire site, and it converts by being beautiful. 🔵 The pledge's living consequences (guardian news arriving as YOUR news, anniversaries) stay in the app.

**/facts → The Vault** 🟢
Every plate gets its photo and its world's wash - nineteen posters that finally look like nineteen posters. Download-as-poster via canvas (photo, serif, source, seal). Index becomes a gallery wall on the ground line, not a tile grid. Signature: one plate per week is stamped "THIS WEEK'S PLATE" and featured; teachers learn the rhythm.

**/rain → The Night Window** 🟢 (new, one evening)
A nearly empty page: the real-hour sky, the live counter, the rain of record, optional single distant birdsong (off by default). No nav on entry (it slides in on mouse move). Made to be left open on second monitors, classroom projectors, waiting-room TVs. The URL people share with "just leave this open."

**/classroom + /kids** 🟢 (phase 3 of WEBSITE.md, unchanged in role, upgraded in dress)
The weekly class pack auto-builds from the current fact, action, and win - one printable page, duotone illustrated, ink-friendly. The kids corner runs on simpleText and the Little Helpers film. These two pages are the compounding channel: one teacher is thirty children a year.

**/about → The Letter** 🟢
Not a mission statement - a letter, first person, serif, on paper texture: tired of the news, built a small hope machine, here is what it refuses to do (ads, tracking, guilt). The films embedded. Signed with the seed-seal. Community begins here, because for a one-person project the honest human IS the community's first member.

**Community → The Letters Wall** 🟡 (new, when real material exists - and it already starts to)
No forum, no feed, no moderation swamp. Instead: real sentences from real users (the feedback box already receives them; ask permission, publish with first name and country only): "the legacy of change and hope" deserves a wall, not a screenshot folder. Rendered as handwritten-style letters pinned above the ground line. Grows slowly, curated by you, every entry true. 🔵 Actual member-to-member community (circles, cheers, named rain) stays in the app where identity and safety live. Long-term dream 🟢: the Map of Drops - coarse, country-level, anonymous dots of where rain came from; only when the plumbing can be privacy-true.

**404 → The Lost Trail** 🟢
The duotone fox on the ground line: "This trail does not exist yet. But every trail started as no trail." Four doors home. The curious deserve the best page.

---

## 6. Website-only experiences worth returning for (invented, not copied)

1. **The Red List Walk** 🟢 - the flagship educational experience and the site's award piece. One horizontal scroll-driven walk along the ground line from Least Concern toward Extinct. As you walk, the light dims by degrees, and species stand along the path at their true positions - each one a portrait, a number, one sentence. At the far dark end: the ones we lost, in silhouette. And then the path TURNS, and you walk back through species that came back - the whale, the condor, the kakapo climbing - with the light returning as you go, ending at a dawn signpost: "Extinction is a direction, not a destiny. So is recovery." Ten minutes, unforgettable, linkable, teachable, and buildable with the data and photos we already have. If Hopeling ever wins a design award, it is for this page.
2. **Perspective** 🟢 - the answer to "does my small action even matter?" as an experience. You press and hold; one drop falls; the view pulls back: your drop among today's real drops, then among the archive's total, then the counter ticking live as strangers join while you watch. Three zooms, one truth, no text needed.
3. **The Year Ring** 🟢 - the wins archive rendered as an interactive tree ring: one ring per year, wins as bright cells in the wood; hover to read, click to open. The archive as the trunk of something growing. (This becomes the /wins year-divider motif's grown-up sibling.)
4. **The Night Window** (/rain, above).
5. **The Weekly Plate + Class Pack** (above) - the returning rituals for teachers and families.
🔵 Deliberately NOT on the website: personal impact dashboards, habit tools, challenges with progress, anything with a login. The moment the site asks who you are, it stops being a commons.

---

## 7. Twenty signature moments

1. The counter ticking while you watch, one drop falling with it 🟢
2. "While you were away, 214 drops fell" 🟢
3. The seed cracking gold at the top of the homepage 🟢
4. The dusk-to-dawn turn in chapter 4 to 5 🟢
5. The idle fox: 45 seconds of stillness on the homepage, a fox trots across the footer, gone; never documented anywhere 🟢
6. The whale surfacing once across the oceans header 🟢
7. The walk-back of the recovered species in the Red List Walk 🟢
8. The equinox line: "Today, day and night are exactly equal. Everywhere. For everyone." 🟢
9. Winter's first snow replacing rain on the night hero 🟢
10. The gold ring completing around a pledged species under your held thumb 🟡
11. The certificate rendering with your name and the seed-seal 🟡
12. "Every one of these actually happened." after twenty scrolled wins 🟢
13. The night whisper on /today: "You could be the first to see tomorrow." 🟢
14. The poster download stamping its gold seal with a BLOOM 🟢
15. Grass leaning away from your cursor at the ground line 🟢
16. The firefly cursor appearing only at night hours 🟢
17. The 404 fox 🟢
18. The footer roots: the sitemap buried under the ground line, with one tiny seedling that is one pixel taller each time you visit (localStorage) 🟢
19. A satellite crossing the night sky once every few minutes, because someone is always watching over the Earth 🟢
20. The letter signed with a seed instead of a signature on /about 🟢
Every one is quiet, none is a gimmick, and eleven of them cost under an hour each.

---

## 8. Content strategy - storytelling over explanation

The copy rules from here forward: no sentence that explains what a visitor can already feel (if the counter ticks visibly, delete "updated in real time"); every page opens with its emotional line, not its functional one; the word "features" never appears on the website; numbers always arrive dressed as stories ("an archive that has never deleted an entry" not "500 cap"); the four appcta variants replace the cloned block - each section type gets its own quiet closing sentence, and the guardian pages' version is simply "Stand for them."
SEO holds WEBSITE.md's plan and gains: baked photos (image search, the second door into every species page), the Red List Walk as the linkable asset editors cite, the weekly plate as the recurring content object, question-shaped species H1s. Five-year IA is unchanged from WEBSITE.md - it was right; this document is how it should feel.

---

## 9. The roadmap, ranked (effort → emotional/user/SEO/viral impact, 1 to 5)

### Phase 1 - under 30 minutes each 🟢
1. Mobile sheet menu (effort 1 · user 5 · the boat hole - first)
2. Kill every invented number; guardian cards from real data (1 · trust 5)
3. Hero fact fed from dailyIndex (1 · trust 4)
4. Rain visibility 2x on heroes (1 · emotional 4)
5. Active nav states + focus-visible in fern (1 · user 3)
6. 404 Lost Trail (1 · emotional 3 · viral 2)
7. Footer human line promoted to serif size (1 · trust 4)
8. CTA dedupe in hero (1 · 2)

### Phase 2 - under 2 hours each 🟢
9. The living counter with odometer tick + drop (2 · emotional 5 · viral 4 · the best ROI on this list)
10. Return-rain from localStorage (2 · emotional 5)
11. /today statically baked + yesterday whisper + night whisper (2 · SEO 5 · user 4)
12. appcta variants, four voices (1 · 3)
13. /wins magnitude pass: pinned win, interstitial, archive framing (2 · emotional 4)
14. Seasonal palette sets + equinox/solstice lines (2 · emotional 4 · viral 3)

### Phase 3 - one evening each 🟢
15. **Build-time Wikipedia baking** (photos + text into species, worlds, facts; 800px thumbnails; attribution) (3 · SEO 5 · emotional 5 · the single biggest transformation per hour on this page)
16. Ground line system + RISE motion replacing all fade-ups (3 · brand 5)
17. Atlas dioramas + world washes (3 · emotional 4)
18. Poster downloads with gold seal (3 · viral 4)
19. Web pledge + certificate (3 · viral 5 · the conversion device)
20. The Night Window /rain (2 · viral 3 · emotional 4)
21. Fraunces self-hosted (2 · brand 4)
22. Client-side search (3 · user 3)

### Phase 4 - weekend projects 🟢
23. **One Day on Earth homepage** with the drawn scroll-growing tree (5 · emotional 5 · viral 5; build AFTER photos and ground line, so the cinema does not sit above a template)
24. **The Red List Walk** (5 · emotional 5 · SEO 4 · viral 5 · the award piece)
25. Perspective (4 · emotional 5)
26. /classroom pack generator + /kids (4 · user 4 · the compounding channel)
27. The Letters Wall, first ten letters (2 once permissions exist · trust 5)

### Phase 5 - wait for Flutter 🔵
Everything personal: pledge consequences, guardian anniversaries, streak repair, ceremonies, circles, named rain, cheers, notifications, widgets, offline. The website never grows a login. Also deliberately withheld from web: sound design beyond the one birdsong toggle, gamification of any kind.

### Phase 6 - the five-year dreams 🟢
The Map of Drops (privacy-true, country-level). The Year Ring as full interactive. Seasonal events (Migration Week, Night of the Owls) as annual site transformations. The globe, if ever, as the Atlas's final form. Translations (the content contract makes the site translatable wholesale; Hebrew first). And the illustrated tree asset shared 🟡 between the Flutter app and the homepage - one tree, one face, both halves of the ecosystem finally wearing the same living crown.

---

## 10. The final answer

"What would you build?"

A place, a walk, and a heartbeat.

**The place:** one meadow under one real-time sky, standing on one ground line, from the homepage to the 404 - so that visiting Hopeling feels like going somewhere, and returning feels like coming back.
**The walk:** the Red List Walk - the one educational experience on the internet that takes extinction seriously in both directions, dark and back. That page earns the citations, the classrooms, the awards, and the right to be called the best nature website of its year.
**The heartbeat:** the true counter, ticking while strangers watch, raining what it counts. No beautiful agency site can compete with it, because theirs would be fiction and ours is a fact that increments.

Timeless is the discipline underneath all three: no trends, no logins, no ads, no guilt, nothing that moves except what is alive, and nothing on any page that is not true. The app changes one person's day. The website proves the world is worth it. Build the place, build the walk, keep the heart beating - and Hopeling is not a website about hope; it is where hope is kept.
