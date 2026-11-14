#!/usr/bin/env node
/* Renders a cut of the film.
     node film/render.cjs main            -> film/out/hopeling-film.video.mp4 (silent; film/build.sh adds the sound)
     node film/render.cjs main 0 900      -> frames 0..899 only (for rendering in halves)
     node film/render.cjs main still 12.5 31 62   -> jpg stills at those seconds, for review
     node film/render.cjs poster          -> film/poster.jpg and brand/og.jpg
   Needs: node, sharp, ffmpeg. */
const path = require('path'), fs = require('fs'), { spawn } = require('child_process');
const sharp = require('sharp');
const F = require('./film.cjs');
const cuts = { main: F.MAIN, social: F.SOCIAL, loop: F.LOOP };
const [, , which = 'main', a, ...rest] = process.argv;
const cut = cuts[which], OUT = path.join(__dirname, 'out'); fs.mkdirSync(OUT, { recursive: true });

(async () => {
  if (which === 'poster') {
    await sharp(Buffer.from(F.poster())).jpeg({ quality: 88 }).toFile(path.join(__dirname, 'poster.jpg'));
    await sharp(Buffer.from(F.poster(1200, 630))).jpeg({ quality: 88 }).toFile(path.join(__dirname, '..', 'brand', 'og.jpg'));
    console.log('poster.jpg, brand/og.jpg'); return;
  }
  if (a === 'still') {
    for (const t of rest.map(Number)) {
      await sharp(Buffer.from(F.frame(cut, t))).jpeg({ quality: 86 }).toFile(path.join(OUT, `still-${which}-${String(t).padStart(5, '0')}.jpg`));
    }
    console.log('stills', rest.length); return;
  }
  const total = Math.round(cut.dur * F.FPS), from = a ? +a : 0, to = rest[0] ? +rest[0] : total;
  const file = path.join(OUT, `${cut.name}.${from}-${to}.mp4`);
  const ff = spawn('ffmpeg', ['-y', '-loglevel', 'error', '-f', 'rawvideo', '-pix_fmt', 'rgb24', '-s', `${F.W}x${F.H}`, '-r', String(F.FPS), '-i', '-',
    '-c:v', 'libx264', '-preset', 'medium', '-crf', '16', '-pix_fmt', 'yuv420p', '-movflags', '+faststart', file], { stdio: ['pipe', 'inherit', 'inherit'] });
  const t0 = Date.now();
  for (let i = from; i < to; i++) {
    const buf = await sharp(Buffer.from(F.frame(cut, i / F.FPS))).removeAlpha().raw().toBuffer();
    if (!ff.stdin.write(buf)) await new Promise(r => ff.stdin.once('drain', r));
    if ((i - from) % 150 === 0) console.log(`${which} frame ${i}/${to}  ${((Date.now() - t0) / 1000).toFixed(0)}s`);
  }
  ff.stdin.end(); await new Promise(r => ff.on('close', r));
  console.log('done', file, ((Date.now() - t0) / 1000).toFixed(0) + 's');
})();
