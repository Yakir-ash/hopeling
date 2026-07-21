# Recorded narration - how to run it

The kids stories can be narrated by a real neural voice, generated once
on your machine and shipped as static files. No API keys ever enter the
repo or the app; a child's device only ever fetches audio from
hopeling.app, like a photo.

## One-time setup

1. Create an OpenAI API key at platform.openai.com (API keys page).
2. In PowerShell:

    $env:OPENAI_API_KEY = "sk-..."

## Pick the voice (once)

    node scripts/narrate.js --samples

This writes `audio/samples/fable.mp3`, `nova.mp3`, `shimmer.mp3`,
`alloy.mp3` - one warm line each. Listen, pick your storyteller.

## Generate everything

    node scripts/narrate.js --voice fable

One mp3 per unique sentence, named by content hash - rerunning after a
content change only generates the new sentences. The whole catalog
costs on the order of ten cents.

## Ship it

    git add audio && git commit -m "narration" && git push

GitHub Pages serves it at hopeling.app/audio/. The app picks it up on
its own (manifest is fetched quietly and cached); anything not covered
falls back to the device Storyteller voice, so nothing ever breaks if
a story changes before you rerun the script.

Note: delete `audio/samples/` before committing if you don't want the
sample lines published.
