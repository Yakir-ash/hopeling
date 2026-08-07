# Shipping Hopeling - the release walkthrough

Everything between "it runs on my machine" and "testers have it on
theirs." Written to be followed top to bottom; each section says
who does it (Yakir / Codemagic / one-time) and whether it blocks.

The state of play: Android signing config is wired (reads
android/key.properties when present, falls back to debug keys so
local runs never break). codemagic.yaml has both workflows. What
remains is the one-time account plumbing below.

---

## 0. Before ANY store upload - the human gates

- [ ] Rescue hotlines verified against each org's own site
      (data/hub.dart rescueLines, all marked 'unverified'):
      US + CA = co-founder, IL + GB = Yakir. Update each entry's
      `verified` field to the check date.
- [ ] Pet-care guides reviewed word by word by BOTH Yakir and the
      co-founder (data/petcare.dart - all twelve, especially every
      red-flags list). Then set `guidesReviewed` to the date. The
      guides do not ship marked 'unverified'.
- [ ] Real sound mp3s in place per ASSETS.md (the synth wavs are
      placeholders and sound like it).
- [ ] `flutter test` green on Yakir's machine.
- [ ] One full manual pass of kids mode on a real phone.

## 1. The Android keystore (one-time, Yakir's machine, 5 min)

The keystore IS the app's identity on Google Play. Lose it and
Hopeling can never be updated again; leak it and someone else can
publish as us. So: generated locally, never committed (gitignored),
backed up somewhere safe OUTSIDE the repo (password manager,
family cloud drive - anywhere that survives a dead laptop).

PowerShell (keytool ships with Android Studio's JDK; adjust the
path if Android Studio lives elsewhere):

    & "C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe" `
      -genkey -v -keystore $env:USERPROFILE\hopeling.jks `
      -keyalg RSA -keysize 2048 -validity 10000 `
      -alias hopeling

It asks for a store password, then identity questions (name/org -
answer plainly, they are cosmetic), then a key password (Enter =
same as store password, which is fine).

Then create `app/android/key.properties` (this exact filename;
git already ignores it):

    storeFile=C:\\Users\\Yakir\\hopeling.jks
    storePassword=<the password>
    keyAlias=hopeling
    keyPassword=<the password>

From then on `flutter build appbundle --release` in app/ produces
a store-ready, properly signed bundle.

- [ ] hopeling.jks generated
- [ ] backed up outside the repo
- [ ] key.properties created locally

## 2. Google Play internal track (one-time account, then minutes)

1. play.google.com/console -> create a developer account
   ($25 once, any country, activates in a day or two).
2. Create app: name Hopeling, default language, app/game = app,
   free. Declarations: no ads.
3. Internal testing -> create release -> upload the .aab from
   `app\build\app\outputs\bundle\release\`.
4. Testers tab -> create an email list (Yakir, co-founder, the
   7-year-old's guardian account). They get an opt-in link.
5. Store listing essentials can be minimal for internal testing;
   the full listing (screenshots, descriptions, data-safety form)
   is only needed for open testing / production.

Data safety form notes (when asked): the app collects nothing.
Location is typed by the user, rounded, kept on-device; no
analytics, no accounts, no ads. This is rare and worth stating
plainly - reviewers read it.

- [ ] Play developer account created
- [ ] Internal release uploaded
- [ ] Both phones installed via the opt-in link

## 3. Apple - TestFlight (blocked on enrollment email)

Codemagic builds iOS in the cloud; no Mac needed after the
one-time setup in codemagic.yaml's header comment (App Store
Connect API key -> Codemagic integration -> create the app record
-> run the ios-testflight workflow -> add both iPhones as internal
testers). Internal TestFlight needs NO Apple review; builds land
on phones minutes after upload.

- [ ] Enrollment email arrived, appstoreconnect.apple.com opens
- [ ] API key generated + added to Codemagic
- [ ] App record created (bundle id app.hopeling.hopeling)
- [ ] First TestFlight build on both iPhones

## 4. Codemagic (one-time, free tier is plenty)

1. codemagic.io -> sign in with GitHub -> add Yakir-ash/hopeling.
   It auto-detects codemagic.yaml.
2. Android: Environment variables -> group `keystore` -> add
   CM_KEYSTORE (the .jks file base64-encoded), CM_KEYSTORE_PASSWORD,
   CM_KEY_ALIAS, CM_KEY_PASSWORD - each marked Secure.
   PowerShell to get the base64:
       [Convert]::ToBase64String([IO.File]::ReadAllBytes("$env:USERPROFILE\hopeling.jks")) | Set-Clipboard
3. iOS: the Developer Portal integration per section 3.
4. Builds are started manually from the Codemagic UI - nothing
   builds on push by design.

## 5. Versioning (every release)

pubspec.yaml `version: X.Y.Z+N`:
- X.Y.Z is what humans see (start 1.0.0, bump Z for fixes, Y for
  features).
- +N is the build number both stores use to order uploads: it must
  INCREASE on every upload to either store, and never repeat.
  Simplest rule: bump +N every time either store gets a build,
  even if X.Y.Z stays put.

## 6. What deliberately does NOT ship

- The synth .wav sounds (deleted once real mp3s land).
- Any 'unverified' rescue hotline (section 0 gate).
- Personal media (Sylvia film, Wings.mp4, butterfly clips) - all
  untracked, and must stay that way.
- API keys of any kind: the app contains none, by architecture.
  The RescueGroups key lives only in Cloudflare; the worker URL in
  the app is public by design.
