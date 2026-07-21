#!/usr/bin/env node
// The recorded Storyteller - pre-generates warm narration for every
// kids story using OpenAI TTS, so children hear a human-sounding voice
// with no runtime API calls, no keys in the app, and no third parties
// on a child's device. Audio is static content, like the photos.
//
// Runs on YOUR machine (Node 18+). The key lives in your environment,
// never in the repo:
//
//   set OPENAI_API_KEY=sk-...        (Windows)
//   node scripts/narrate.js --samples   # 4 voices read one line; listen,
//                                       # then pick with --voice
//   node scripts/narrate.js --voice fable
//
// Output: audio/manifest.json + audio/*.mp3 (one file per unique
// sentence, named by content hash - rerunning only generates what
// changed). Commit the audio/ folder; GitHub Pages serves it at
// hopeling.app/audio/. Cost: the whole catalog is a dollar or two.

const fs = require('fs');
const path = require('path');
const crypto = require('crypto');

const ROOT = path.join(__dirname, '..');
const OUT = path.join(ROOT, 'audio');
const KEY = process.env.OPENAI_API_KEY;
const args = process.argv.slice(2);
const SAMPLES = args.includes('--samples');
const VOICE = args.includes('--voice')
    ? args[args.indexOf('--voice') + 1] : 'fable';

if (!KEY) {
  console.error('Set OPENAI_API_KEY first (it never enters the repo).');
  process.exit(1);
}

// mirrors the app: what the voice says (emoji stay on the page)
const speakable = t => t
    .replace(/[^\p{L}\p{N}\s.,!?;:'"()-]/gu, ' ')
    .replace(/\s+/g, ' ').trim();
const sentences = t => t.split(/(?<=[.!?])\s+/)
    .map(s => speakable(s)).filter(Boolean);
const slug = s => s.toLowerCase().replace(/[^a-z0-9]+/g, '-')
    .replace(/^-|-$/g, '');
const fname = (voice, text) => crypto.createHash('sha1')
    .update(voice + '|' + text).digest('hex').slice(0, 16) + '.mp3';

const STYLE =
    'Read this warmly and gently, like a parent reading a picture book ' +
    'to a young child at bedtime. Unhurried, kind, a little wonder in ' +
    'questions, soft landings at the ends of sentences. Never theatrical.';

async function tts(text, voice, file) {
  for (const model of ['gpt-4o-mini-tts', 'tts-1-hd']) {
    const body = { model, voice, input: text, response_format: 'mp3' };
    if (model === 'gpt-4o-mini-tts') body.instructions = STYLE;
    const r = await fetch('https://api.openai.com/v1/audio/speech', {
      method: 'POST',
      headers: { 'Authorization': `Bearer ${KEY}`,
                 'Content-Type': 'application/json' },
      body: JSON.stringify(body),
    });
    if (r.ok) {
      fs.writeFileSync(file, Buffer.from(await r.arrayBuffer()));
      return true;
    }
    if (r.status !== 404 && r.status !== 400) {
      throw new Error(`${model}: HTTP ${r.status} ${await r.text()}`);
    }
    // model unavailable on this account: try the older one
  }
  return false;
}

async function main() {
  fs.mkdirSync(OUT, { recursive: true });

  if (SAMPLES) {
    const line = 'Once upon a time, a little seed found the sun. ' +
        'Do you know what happened next? It grew.';
    fs.mkdirSync(path.join(OUT, 'samples'), { recursive: true });
    for (const v of ['fable', 'nova', 'shimmer', 'alloy']) {
      const f = path.join(OUT, 'samples', `${v}.mp3`);
      await tts(line, v, f);
      console.log('sample:', f);
    }
    console.log('\nListen, pick one, then run:  node scripts/narrate.js --voice <name>');
    return;
  }

  const content = JSON.parse(fs.readFileSync(
      path.join(ROOT, 'hopeling-web', 'content.json'), 'utf8'));

  // every kid story: the lesson's simple telling, plus its title
  const stories = {};
  const wanted = new Map(); // speakable sentence -> filename
  for (const j of content.courses || []) {
    for (const l of j.lessons || []) {
      const body = (l.body_simple || '').trim();
      if (!body) continue;
      const sents = [speakable(l.t), ...sentences(body)].filter(Boolean);
      for (const s of sents) wanted.set(s, fname(VOICE, s));
      stories[slug(l.t)] = sents;
    }
  }

  let made = 0, kept = 0;
  for (const [text, file] of wanted) {
    const full = path.join(OUT, file);
    if (fs.existsSync(full)) { kept++; continue; }
    process.stdout.write(`  ♪ ${text.slice(0, 50)}...\n`);
    await tts(text, VOICE, full);
    made++;
  }

  const manifest = {
    v: 1,
    voice: VOICE,
    generated: new Date().toISOString().slice(0, 10),
    // exact speakable sentence -> file, so the app needs no hashing
    sentences: Object.fromEntries(wanted),
    stories,
  };
  fs.writeFileSync(path.join(OUT, 'manifest.json'),
      JSON.stringify(manifest, null, 1));
  console.log(`\nnarration: ${wanted.size} sentences ` +
      `(${made} new, ${kept} unchanged) across ` +
      `${Object.keys(stories).length} stories, voice "${VOICE}".`);
  console.log('Commit the audio/ folder and push.');
}

main().catch(e => { console.error(e); process.exit(1); });
