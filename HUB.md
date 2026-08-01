# The Nature & Animal Hub - design on verified ground

The idea: Hopeling becomes the place you open to ACT in your own
community - find the shelter, the reserve, the cleanup, the answer
to "my dog isn't eating." This document is the researched design:
what data actually exists in mid-2026, what is honestly possible
per region, and the architecture that keeps it alive without a
staff of ten.

The one-line verdict up front: **build it in phases on keyless
global data first (OpenStreetMap), treat events as editorial not
API, treat pet care as safety-reviewed content not data, and let
the bot pipeline - our existing living-content engine - be the
"alive" part.** And one addition that may matter more than
everything else: the wildlife rescue hotline.

---

## 1. The data reality (researched, not assumed)

**OpenStreetMap Overpass API - the backbone.** Global, keyless,
free, community-maintained, queryable by exact tags:
`amenity=animal_shelter`, `leisure=nature_reserve`,
`boundary=national_park`, `leisure=garden` + `garden:type=botanical`,
`leisure=bird_hide`, `landuse=allotments` and community gardens,
hiking via route relations. Fair-use is roughly 10k requests/day
and there are public mirrors; at our scale with device-side caching
we are far inside it. Coverage honesty: excellent for parks and
reserves worldwide; shelters coverage varies by country (good in
Europe, decent in Israel's cities, patchy elsewhere). This is the
only source that works in every country on day one.

**Petfinder API v2 - real but North America only.** The largest
adoptable-pet database, OAuth-keyed (needs a tiny proxy so the
secret never ships in the app). Worth integrating - but as a
regional enrichment, not the foundation. RescueGroups.org is the
same story. There is NO global adoption API; Israel, Europe, and
most of the world get curated organization lists instead (bot
pipeline), which is honest and still useful.

**Events - the hard truth.** Eventbrite removed public event
search in December 2019; Meetup's API went paid; there is no
reliable global API for "beach cleanups near you." Anyone who
promises live local events either scrapes (fragile, ToS-risky) or
fakes it. Our answer: events are EDITORIAL. The bot ships weekly
regional event packs (curated from org calendars: SPNI in Israel,
Wildlife Trusts in the UK, Surfrider cleanups, city park systems)
plus evergreen doors to each organization's own calendar. Fewer
events, all real, never stale-looking.

**iNaturalist API - global, keyless for reads.** Nearby
observations, active projects, and species lists per place. This is
the sleeper: "what have people actually seen within 20km this
month" is living local nature data no directory can match, and it
ties straight into our Atlas and field guide.

**Protected Planet (WDPA) API** - the UN's global protected-areas
database, global coverage for reserves and parks, good as
enrichment on top of OSM.

**Geocoding: OSM Nominatim.** Turns "Haifa" into coordinates,
keyless, 1 req/sec policy with attribution - fine for
type-a-place-name usage.

## 2. Privacy architecture (the part we get to brag about)

Manual-first, GPS-optional, nothing stored, nothing sent to us:

1. Default flow: the user TYPES a place ("Haifa", "my
   neighborhood's city") → Nominatim geocodes it → we remember the
   chosen area name and its rounded coordinates on-device only.
2. Optional "use my location": one-shot coarse position (no
   background, no tracking), immediately rounded to ~2km before
   ANY network query, never persisted beyond the session unless
   the user saves it as "my area," never attached to any account.
3. All queries go to third parties as "circle around rounded
   point" - indistinguishable from a map app.
4. Kids mode: the Hub does not exist there at all. External
   links, locations, and organizations are parent surfaces by
   constitution. Kids-mode integration is limited to a parent-area
   door ("find real-world help near you").
5. Store compliance: location permission with a purpose string,
   requested only when the button is tapped, fully functional
   without it. This passes Apple and Play review comfortably and
   matches our zero-permission brand: the app that computes the
   moon without asking for anything now asks for one thing,
   optionally, and explains exactly why.

## 3. The architecture

```
[app] --(place name)--> Nominatim  --> lat/lon (rounded)
[app] --(circle query)--> Overpass --> shelters/reserves/parks/gardens
[app] --(circle query)--> iNaturalist --> nearby life, projects
[app] <-- content.json <-- bot pipeline --> curated packs:
        - country wildlife-rescue hotlines (hand-verified)
        - adoption orgs per country (where no API exists)
        - weekly regional events (editorial)
        - pet-care guides (safety-reviewed, static)
[worker (phase 3, optional)] --> Petfinder/RescueGroups proxy
                                 (keys live server-side only)
```

- **Device cache per area**: every query result cached with its
  area key; the Hub works offline on the last-seen data with an
  honest "as of Tuesday" stamp.
- **No backend until phase 3**: phases 1-2 are entirely
  client + static-site + bot, like everything else we run. The
  only server we ever add is a ~50-line Cloudflare Worker for the
  keyed North-American adoption APIs.
- **Graceful missing data**: coverage varies, so the empty state
  is honest and useful: "OpenStreetMap doesn't know many shelters
  around here yet" + the country hotline card + a door to improve
  OSM itself (which is, fittingly, a real conservation act).

## 4. The screens

**The Hub** (adult surface, entry from Act tab + parent area):
one place-picker header ("📍 Haifa · change"), then four doors:

- **🆘 Help a wild animal** - THE HERO CARD, always first. Found
  an injured bird, a stranded hedgehog, a bat in daylight? One
  tap: the country's wildlife rescue hotline, what to do (and not
  do) until help comes, all offline-capable. Hand-verified per
  country by the bot pipeline. Nobody else does this well, it fits
  our soul exactly, and it is the moment people never forget an
  app for. Ten countries hand-verified at launch beats two hundred
  scraped and wrong.
- **🐾 Adopt & help shelters** - nearby shelters (OSM), each with
  directions, website, phone; a "how to actually help" panel
  (foster, volunteer, the wish-list idea as evergreen guidance);
  in North America later: live adoptable pets via the proxy.
- **🌿 Wild places near you** - reserves, parks, botanical
  gardens, bird hides (OSM + WDPA), each enriched with "alive
  right now": recent iNaturalist observations nearby and our own
  almanac's seasonal line. This is where the Hub stops being a
  directory and becomes Hopeling: not "a reserve exists" but "a
  reserve exists and TODAY people saw kingfishers there."
- **📅 Get involved** - the editorial events shelf per region +
  evergreen org calendars, honestly labeled with dates and
  sources.

**🩺 Pet care guides** - a separate quiet section, NOT
location-based: curated symptom guides ("my dog isn't eating",
"my cat is limping", ~12 at launch). Strict format, in this
order: (1) RED FLAGS first - "call a vet now if..." before
anything else, (2) what to observe and note down, (3) common
non-emergency causes, (4) safe comfort measures only - nothing
dosed, nothing administered, (5) the standing banner on every
page: educational only, never a substitute for a veterinarian.
Content is static, offline, versioned through the bot, and
review-gated: no guide ships without a second pair of eyes, and
the app never generates medical text dynamically. Kids mode never
sees these.

## 5. Integration with the Hopeling experience

- The hillside gains one world-thing when an area is set: a
  distant 🏞 "near you" door (band system has room in Row B's
  future third slot pattern - it gets its own band audit).
- Atlas pages gain "seen near you this month" via iNaturalist
  when an area is set - the Living Atlas becomes locally alive.
- Acts integrate: "visit a wild place this weekend" can now open
  the real list. The grove's actions stop being placeless.
- The Common Log (V2's collective almanac) eventually keys firsts
  by area - same rounded-area privacy model.

## 6. Phases, honestly costed

**Flagship market: North America.** Decided after phase-one
build: NA is the only region where every Hub layer can be fully
alive (Petfinder exists only there), OSM coverage is excellent,
and the American co-founder can verify hotlines, test with real
local data, and own the first editorial event regions. Israel
stays in from day one (already built, Yakir's daily test bed);
NA leads everything that follows.

**Phase 1 - global, keyless, DONE:** place picker (manual-first;
GPS deferred), Wild Places + Shelters via Overpass, the wildlife
rescue card (US: Animal Help Now directory; CA guidance; IL
*3639; GB RSPCA - all marked verify-before-release), honest empty
states, offline cache. No backend.

**Phase 2 - the guides:** 12 pet-care guides written to the
safety format + reviewed; "how to help shelters" evergreen
content; events shelf v1 for 2-3 launch regions (editorial).

**Phase 3 - NA depth (PROMOTED, next after guides):** the
Petfinder worker is already scaffolded in proxy/ with a 15-minute
deploy guide written for the co-founder; once deployed and its
URL set in hub.dart, live adoptable animals light up across the
US and Canada. Then more hotline countries and event regions as
editorial capacity grows.

**Explicitly rejected:** scraping event sites (fragile, and one
broken scrape makes the whole Hub feel dead), shipping API keys
in the app, any location persistence off-device, the Hub inside
kids mode, and AI-generated veterinary advice.

## 7. Risks named

- OSM shelter coverage is thin in some regions → the hotline card
  and honest empty states carry those areas; OSM-contribution door
  turns the gap into an action.
- Overpass fair-use at large scale → cache hard, add a mirror
  rotation, and self-host Overpass later if we ever have that
  problem (a good problem).
- Pet-care liability → the format above, the banner everywhere,
  review gate, and no interactivity that resembles diagnosis.
- Events staleness → editorial-only means less volume but zero
  staleness; the shelf shows its own freshness date.
