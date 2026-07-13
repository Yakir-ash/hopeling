# Hopeling - installable web app (PWA)

This folder is a complete, offline-capable Progressive Web App. It installs to your
home screen like a native app and works with no internet after the first load.

## Files
- `Hopeling.html` - the app
- `manifest.json` - app name, icons, colors (makes it installable)
- `sw.js` - service worker (offline caching)
- `icon-192.png`, `icon-512.png`, `icon-maskable.png`, `apple-touch-icon.png` - icons

## Put it on your phone (2 minutes, free)
A service worker needs a real web address (https), so host the folder first:

1. On your computer, go to **app.netlify.com/drop** (or **tiiny.host**).
2. Drag this whole **hopeling-web** folder onto the page.
3. You get a link like `hopeling.netlify.app`.
4. Open that link on your phone:
   - **iPhone (Safari):** Share button → **Add to Home Screen**.
   - **Android (Chrome):** you'll see an **Install** prompt, or menu → **Install app**.
5. It installs an icon and opens full-screen. Your streak, impact, and the action
   graph are saved on your device between opens, even offline.

## Test on your computer first (optional)
A service worker won't run from a double-clicked file, so serve it locally:
```
cd hopeling-web
python3 -m http.server 8000
# open http://localhost:8000/Hopeling.html
```

## What changed in this version
- **Installable PWA + full offline support** (icon, manifest, service worker).
- **Impact graph** - a GitHub-style calendar of your daily actions on Home and Me.
- **Share cards** - tap "Share impact" (Me tab) to generate a branded image of your
  streak + impact + mini graph, and share it or save it (📤).
- **Progress backup/restore** - Settings → Export saves a JSON file; Import restores it,
  so a cleared browser or new phone never wipes your streak.
- **Streak freeze + repair** - you earn a ❄️ freeze every 7-day streak; it auto-bridges
  a single missed day. Missed exactly yesterday? A "Repair" banner restores your streak.
- **Custom actions & manual impact logging** - Act tab → "＋ Add your own action";
  Me tab → "＋ Log impact" to record real numbers (trees planted, kg cleaned…).
- **Search + weekly missions** - 🔍 in the top bar searches everything; Home shows 3
  rotating weekly missions with progress bars and XP rewards.
- **22 species/ecosystems, 19+ actions, 4 courses**, dark mode, accessibility.

Note: after re-hosting, the app updates automatically (service worker cache bumped to v2).

Note on reminders: the toggle nudges you when you open the app and haven't acted that
day. True scheduled background push notifications require the hosted backend from the
production blueprint.

## Updating the app's content online (no app update needed)
All species, actions, courses, facts and stories now live in **content.json**.
The app fetches it when online, caches it on the device, and falls back to the
cached (or built-in) copy offline.

To change what everyone sees:
1. Edit `content.json` (add a species, a fact, a course, fix a number…).
2. Bump the `version` and `updated` fields at the top.
3. Re-upload `content.json` to your host (e.g. drag the folder to Netlify again).
Every installed copy picks up the new content the next time it's online - no
new build, no app-store review.

### content.json shape (quick reference)
- `categories[]`: `{slug, emo, name, iucn, sum, overview, science, stats[[label,value,source]],
  facts[[text,source]], threats[[title,desc,source]], doing[[title,desc]],
  hope[[title,desc]], orgs[[name,url]], acts[slug…]}`
- `actions{slug: {t, why, imp, diff(1-3), mod, cost, min, metric, val, ev[], steps[]}}`
- `courses[]`: `{slug, t, d, badge, lessons[{t, min, body, quiz[{q, opts[], a}]}]}`
- `facts[[text,source]]`, `stories[[tag,title,body]]`

### Where the live data comes from later
Today `content.json` is hand-curated and source-attributed. The production
blueprint's next step is a scheduled job that regenerates it automatically from
commercial-safe APIs (GBIF, NASA, NOAA, Global Forest Watch, Our World in Data) -
same file, same app, just kept fresh by a script.
