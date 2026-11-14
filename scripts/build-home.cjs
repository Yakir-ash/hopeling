#!/usr/bin/env node
/* Builds the homepage (index.html) from:
     brand/home.css, brand/home.js, brand/creatures.cjs  - the look and the behaviour
     app/lib/data/almanac.dart                            - what the neighbours are doing this season
     app/assets/knowledge/swaps.json                      - the this-not-that card
     audio/manifest.json                                  - the storyteller's recorded lines
   so the page and the app cannot drift apart. Everything is inlined: one
   request for the page, plus the fonts.

   Run:  node scripts/build-home.cjs
   Preview variants (self-contained, fonts embedded) for visual checks:
         node scripts/build-home.cjs --preview=lab-done --out=/some/dir/x.html */

const fs = require('fs');
const path = require('path');
const ROOT = path.join(__dirname, '..');
const B = require(path.join(ROOT, 'brand', 'creatures.cjs'));
const { C, f } = B;
const arg = k => { const a = process.argv.find(x => x.startsWith('--' + k + '=')); return a ? a.slice(k.length + 3) : ''; };
const PREVIEW = arg('preview'), OUT = arg('out');
const read = p => fs.readFileSync(path.join(ROOT, p), 'utf8');
const esc = s => String(s).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');

// a tiny deterministic random, so the meadow is the same meadow every build
let seed = 7; const rnd = () => (seed = (seed * 16807) % 2147483647) / 2147483647;
const wrap = (cls, inner, extra = '') => `<g class="${cls}"${extra}>${inner}</g>`;
const LIGHT = '#8FCBA4';

/* ---------------- data from the app ---------------- */
const dartStr = block => (block.match(/'(?:[^'\\]|\\.)*'/g) || []).map(s => s.slice(1, -1).replace(/\\'/g, "'")).join('');
function neighbours(ids) {
  const src = read('app/lib/data/almanac.dart');
  const out = {};
  for (const id of ids) {
    const i = src.indexOf(`id: '${id}'`); if (i < 0) continue;
    const blk = src.slice(i, src.indexOf('look:', i));
    const name = /name: '([^']+)'/.exec(blk)[1];
    const now = {};
    for (const s of ['spring', 'summer', 'autumn', 'winter']) {
      const m = new RegExp(`'${s}':\\s*((?:'(?:[^'\\\\]|\\\\.)*'\\s*)+),`).exec(blk);
      if (m) now[s] = dartStr(m[1]);
    }
    out[id] = { name, now };
  }
  return out;
}
const NEAR = neighbours(['fox', 'hedgehog', 'frog']);
const SWAP = JSON.parse(read('app/assets/knowledge/swaps.json')).swaps.find(s => s.id === 'detergent');
const MAN = JSON.parse(read('audio/manifest.json')).sentences;
const voice = lines => lines.map(l => MAN[l] ? '/audio/' + MAN[l] : null).filter(Boolean);

const HL = {
  lab: {
    // app/lib/data/lab.dart, scenario 'meadow' - copied number for number
    nodes: [{ id: 'f', init: 0.8, g: 0.05, s: 0 }, { id: 'r', init: 0.5, g: 0, s: -0.10 }, { id: 'x', init: 0.4, g: 0, s: -0.08 }],
    edges: [['r', 'f', -0.15], ['f', 'r', 0.25], ['r', 'x', 0.20]],
    driven: 'f', steps: 12, stay: 0.25,
    names: ['Wildflowers', 'Rabbits', 'Foxes'], colors: [C.fern, C.gold, C.rust],
    slots: { f: 16, r: 6, x: 3, b: 4 },
    levers: [
      { label: 'half the bees are lost', dg: 0.125, bees: 2,
        moments: [[2, 'Fewer visits, fewer seeds. The flowers thin - not a catastrophe, a fading.'], [5, 'The rabbits notice before we would: a little less each spring.'], [9, 'The foxes eat last, so they feel it last - but they feel it.']],
        epi: 'Half the pollinators does not mean half the meadow - the losses compound as they climb.' },
      { label: 'no bees at all', dg: 0, bees: 0,
        moments: [[1, 'The flowers bloom once more on stored strength - and set almost no seed.'], [4, 'The second spring is the quiet one. Wind carries some pollen; it cannot carry a meadow.'], [8, 'The rabbits are hungry in the open. The foxes hunt longer for less.']],
        epi: 'Nobody starves on day one. That is what makes it dangerous: the unraveling is slower than attention.' },
    ],
    repair: { dg: 0.30, drag: 0.6,
      moments: [[2, 'The patch blooms. The surviving pollinators find it - they were never all gone, only starving.'], [7, 'Seeds set again. Slowly: recovery climbs a hill that decline slid down.']],
      epi: 'The meadow comes back - but compare the curves: the way back is longer than the way down. That slope has a name: hysteresis.' },
  },
  who: {
    curious: { lede: 'Hopeling is honest science you can play with, the wildlife around you by the hour, and one real thing to do each day. For families, classrooms, and anyone who has wanted to help and not known where to start.',
      c1: ['Pull one thread', '#lab'], c2: ['Open the web app', '/hopeling-web/Hopeling.html'] },
    parent: { lede: 'For your child: stories read in a warm voice, animal neighbours, and games where nothing can be lost. No ads, no chat, no strangers, no scores. And whatever they choose, the story ends in repair.',
      c1: ['See Hopeling Kids', '#kids'], c2: ['Ask for early access', 'mailto:contant.hopeling@gmail.com?subject=Hopeling%20Kids%20early%20access'] },
    teacher: { lede: 'For your class: a real ecosystem model the whole room predicts and argues with, an errand that cannot be done on a phone, and six weeks that end with something planted. No student accounts.',
      c1: ['Run a lesson now', '/bench/'], c2: ['Hopeling for schools', '/schools/'] },
    partner: { lede: 'For your organisation: the day after the field trip. A six-week program your partner schools can run in their own schoolyard, built on honest models and real counting.',
      c1: ['Talk to us', 'mailto:contant.hopeling@gmail.com?subject=Hopeling%20partnership'], c2: ['See the schools page', '/schools/'] },
  },
  near: NEAR,
  kids: {
    growing: 'Look - the flowers found the sun, and the bees found the flowers.',
    closing: 'The meadow came back because someone helped. Helpers change everything.',
    audio: voice(['Look - the flowers found the sun, and the bees found the flowers.', 'The meadow came back because someone helped.', 'Helpers change everything.']),
  },
  pulse: { url: 'https://cpdjabynilymlfouozcc.supabase.co/rest/v1/pulse?select=actions', key: 'sb_publishable_M6ZB-wVDNOvrhzvFE5Fa8A_9jz9L8eL' },
};

/* ---------------- scenes ---------------- */
function heroScene() {
  const W = 1440, H = 800, o = [];
  const stars = []; for (let i = 0; i < 46; i++) stars.push(`<circle class="tw${['', ' b', ' c'][i % 3]}" cx="${f(rnd() * W)}" cy="${f(210 + rnd() * 230)}" r="${f(0.8 + rnd() * 1.3)}" fill="#F4F1E6"/>`);
  o.push(wrap('stars', stars.join('')));
  o.push(`<circle id="halo" class="orb" cx="900" cy="330" r="112" opacity=".17"/><circle id="orb" class="orb" cx="900" cy="330" r="46"/>`);
  o.push(wrap('daylife', wrap('cloudm', B.cloud({ x: 1040, y: 262, s: 1.4, op: 0.75 })) + wrap('cloudm', B.cloud({ x: 1330, y: 330, s: 1.0, op: 0.6 })) + B.bird({ x: 716, y: 372, s: 1.2 }) + B.bird({ x: 762, y: 352, s: 0.9, flap: 0.8 })));
  const h1 = [500, 34, 0.4], h2 = [578, 40, 2.1], h3 = [668, 26, 4.0];
  const hy = (x, h) => B.hillY(x, W, h[0], h[1], h[2]);
  const land = [];
  land.push(B.hill(W, H, ...h1, 'K1').replace('fill="K1"', 'class="hill1"'));
  land.push(B.tree({ x: 612, y: hy(612, h1) + 22, s: 1.12 }));
  land.push(B.tree({ x: 1262, y: hy(1262, h1) + 16, s: 0.7 }));
  land.push(B.hill(W, H, ...h2, 'K2').replace('fill="K2"', 'class="hill2"'));
  land.push(B.fox({ x: 905, y: hy(905, h2) + 40, s: 1.5 }));
  land.push(wrap('daylife', B.rabbit({ x: 505, y: hy(505, h2) + 46, s: 1.3 }) + B.rabbit({ x: 1120, y: hy(1120, h2) + 38, s: 1.05, flip: true, ear: 0.5 })));
  land.push(B.hill(W, H, ...h3, 'K3').replace('fill="K3"', 'class="hill3"'));
  for (let i = 0; i < 9; i++) land.push(B.tuft({ x: 50 + i * 168 + rnd() * 40, y: hy(50 + i * 168, h3) + 60 + rnd() * 50, s: 1.5, color: C.fernDeep }));
  const fl = [];
  for (let i = 0; i < 19; i++) {
    const x = 60 + i * 73 + rnd() * 30, y = hy(x, h3) + 22 + rnd() * 78;
    fl.push([y, wrap('sway' + ['', ' b', ' c'][i % 3], B.flower({ x, y, s: 1.15 + rnd() * 0.7, petal: [C.cream, C.blush, '#fff'][i % 3], stem: LIGHT }))]);
  }
  fl.sort((a, b) => a[0] - b[0]).forEach(x => land.push(x[1]));
  o.push(wrap('dim', land.join('')));
  o.push(wrap('daylife', wrap('drift', B.bee({ x: 760, y: 640, s: 1.5 })) + wrap('drift b', B.bee({ x: 430, y: 668, s: 1.2, flip: true })) + wrap('drift', B.bee({ x: 1090, y: 676, s: 1.1 }), ' style="animation-delay:-4s"')));
  const flies = []; for (let i = 0; i < 12; i++) flies.push(`<circle class="tw${['', ' b', ' c'][i % 3]}" cx="${f(430 + rnd() * 620)}" cy="${f(590 + rnd() * 150)}" r="2.3" fill="${C.gold}"/>`);
  o.push(wrap('flies', flies.join('')));
  return `<svg viewBox="0 0 ${W} ${H}" preserveAspectRatio="xMidYMax slice" aria-hidden="true" focusable="false">${o.join('')}</svg>`;
}

const { benchScene } = require(path.join(ROOT, 'brand', 'scenes.cjs'));

const SPOTS = [[0.12, 0.75], [0.30, 0.87], [0.50, 0.78], [0.68, 0.86], [0.84, 0.74], [0.42, 0.93]]; // little_meadow.dart
function kidsScene() {
  const W = 600, H = 320, o = [];
  seed = 5;
  for (let i = 0; i < 22; i++) o.push(`<circle class="tw${['', ' b', ' c'][i % 3]}" cx="${f(rnd() * W)}" cy="${f(rnd() * 110)}" r="${f(0.8 + rnd())}" fill="#FFF6E0"/>`);
  o.push(`<circle cx="470" cy="150" r="60" fill="#F3C987" opacity=".25"/><circle cx="470" cy="150" r="34" fill="#F8D9A0"/>`);
  o.push(B.hill(W, H, 170, 14, 1.0, '#4E7B78'));
  o.push(B.tree({ x: 120, y: 196, s: 0.7, leaf: ['#3E6B63', '#4E7B78', '#2C5450'] }));
  o.push(wrap('sp late off', B.fox({ x: 420, y: 204, s: 0.9 })));
  o.push(B.hill(W, H, 214, 10, 3.3, '#3E6B63'));
  o.push(B.hill(W, H, 262, 6, 0.4, '#2C5450'));
  o.push(B.rabbit({ x: 250, y: 252, s: 0.8 }));
  o.push(wrap('sp late off', B.rabbit({ x: 520, y: 246, s: 0.72, flip: true })));
  const xs = [40, 78, 130, 176, 214, 268, 322, 366, 404, 452, 498, 540, 572, 300];
  xs.forEach((x, i) => {
    const late = !(i === 2 || i === 6 || i === 9 || i === 12);
    o.push(wrap('sp fl' + (late ? ' late off' : ''), B.flower({ x, y: 282 + (i % 3) * 10, s: 0.82 + (i % 4) * 0.08, petal: [C.cream, C.blush, '#fff'][i % 3], stem: LIGHT })));
  });
  SPOTS.forEach((p, i) => o.push(`<g id="sprout${i}" class="sp off">${B.sprout({ x: p[0] * W, y: p[1] * H + 8, s: 1.5 })}</g>`));
  [[150, 214], [330, 200], [470, 226]].forEach((p, i) => o.push(wrap('sp late off', wrap('drift' + (i % 2 ? ' b' : ''), B.bee({ x: p[0], y: p[1], s: 1.05 })))));
  return `<svg viewBox="0 0 ${W} ${H}" aria-hidden="true" focusable="false">${o.join('')}</svg>`;
}
const icon = (fn, opts, vb) => `<svg viewBox="${vb}" aria-hidden="true" focusable="false">${fn(opts)}</svg>`;
const leafMark = `<svg viewBox="0 0 24 24" aria-hidden="true"><path d="M12 22C12 14 12 9 12 4M12 13C6 12 3 8 3 3C9 3 12 7 12 13ZM12 16C17 15 21 12 21 7C16 7 12 10 12 16Z" fill="none" stroke="currentColor" stroke-width="2.1" stroke-linecap="round" stroke-linejoin="round"/></svg>`;

/* ---------------- the page ---------------- */
const mail = (subject, body) => `mailto:contant.hopeling@gmail.com?subject=${encodeURIComponent(subject)}${body ? '&body=' + encodeURIComponent(body) : ''}`;
const sparks = HL.lab.names.map((n, i) => `<div class="spark"><div class="nm"><span style="color:${HL.lab.colors[i]}">${n}</span><span id="end${i}"></span></div><svg id="spark${i}" viewBox="0 0 220 92" role="img" aria-label="${n} over twelve seasons, with and without the bees"></svg></div>`).join('');
const spots = SPOTS.map((p, i) => `<button class="spot" type="button" style="left:${f(p[0] * 100)}%;top:${f(p[1] * 100)}%" aria-label="Soft ground. Plant a seed."></button>`).join('');
const nearHtml = [['fox', B.fox, '-48 -64 92 68'], ['hedgehog', B.hedgehog, '-26 -30 56 34'], ['frog', B.frog, '-26 -30 52 34']].map(([id, fn, vb]) =>
  `<div class="nb">${icon(fn, {}, vb)}<div><b>${esc(NEAR[id].name)}</b><p id="near-${id}">${esc(NEAR[id].now.spring)}</p></div></div>`).join('');

let css = read('brand/home.css'), js = read('brand/home.js');
if (PREVIEW) {
  const b64 = p => fs.readFileSync(path.join(ROOT, 'fonts', p)).toString('base64');
  css = css.replace(/url\(\/fonts\/([a-z-]+\.woff)\)/g, (_, p) => `url(data:font/woff;base64,${b64(p)})`);
}

const TITLE = 'Hopeling - learn the living world, then do one small thing for it';
const DESC = 'Honest science you can play with, the wildlife around you by the hour, and one real action a day. For families, classrooms, and anyone who has wanted to help and not known where to start. Free, no ads.';

const html = `<!doctype html>
<html lang="en" data-sky="day">
<head>
<meta charset="utf-8"/>
<meta name="viewport" content="width=device-width, initial-scale=1"/>
<title>${TITLE}</title>
<meta name="description" content="${esc(DESC)}"/>
<link rel="canonical" href="https://hopeling.app/"/>
<meta property="og:type" content="website"/>
<meta property="og:site_name" content="Hopeling"/>
<meta property="og:title" content="${esc(TITLE)}"/>
<meta property="og:description" content="${esc(DESC)}"/>
<meta property="og:url" content="https://hopeling.app/"/>
<meta property="og:image" content="https://hopeling.app/brand/og.jpg"/>
<meta name="twitter:card" content="summary_large_image"/>
<meta name="theme-color" content="#2E6B4F"/>
<link rel="icon" href="/hopeling-web/icon-192.png"/>
<link rel="apple-touch-icon" href="/hopeling-web/apple-touch-icon.png"/>
<link rel="preload" href="/fonts/hopeling-serif-regular.woff" as="font" type="font/woff" crossorigin/>
<link rel="preload" href="/fonts/hopeling-serif-italic.woff" as="font" type="font/woff" crossorigin/>
<script>(function(){var h=new Date().getHours();document.documentElement.setAttribute('data-sky',h<5||h>=21?'night':h<8?'dawn':h<17?'day':'dusk');})();</script>
<script type="application/ld+json">${JSON.stringify({ '@context': 'https://schema.org', '@graph': [
  { '@type': 'Organization', '@id': 'https://hopeling.app/#org', name: 'Hopeling', url: 'https://hopeling.app/', logo: 'https://hopeling.app/hopeling-web/icon-512.png', slogan: 'small actions, real hope', email: 'contant.hopeling@gmail.com' },
  { '@type': 'WebSite', '@id': 'https://hopeling.app/#site', url: 'https://hopeling.app/', name: 'Hopeling', description: DESC, publisher: { '@id': 'https://hopeling.app/#org' } },
] })}</script>
<style>${css}</style>
</head>
<body>
<a class="skip" href="#main">Skip to the page</a>
<header class="nav"><div class="wrap">
  <a class="brand" href="/" aria-label="Hopeling, home">${leafMark}hopeling</a>
  <nav aria-label="Main"><a href="#lab">The Lab</a><a href="/schools/">Schools</a><a href="#kids">Kids</a><a href="/atlas/">Atlas</a><a href="/wins/">Wins</a></nav>
  <a class="btn btn-quiet" href="/hopeling-web/Hopeling.html" data-goal="open-app-nav">Open the app</a>
</div></header>

<main id="main">
<section class="hero" aria-labelledby="h-hero">
  <div class="wrap">
    <p class="kicker">A companion for the living world</p>
    <h1 id="h-hero"><span>Learn the living world.</span> <em>Then do one small thing for it.</em></h1>
    <p class="lede" id="lede">${esc(HL.who.curious.lede)}</p>
    <div class="cta">
      <a class="btn btn-go" id="cta1" href="#lab" data-goal="hero-primary">Pull one thread</a>
      <a class="btn btn-quiet" id="cta2" href="/hopeling-web/Hopeling.html" data-goal="hero-secondary">Open the web app</a>
    </div>
    <div class="who" role="group" aria-label="Who is visiting">
      <span>I am here as</span>
      <button class="chip" type="button" data-who="curious" aria-pressed="true">someone curious</button>
      <button class="chip" type="button" data-who="parent" aria-pressed="false">a parent</button>
      <button class="chip" type="button" data-who="teacher" aria-pressed="false">a teacher</button>
      <button class="chip" type="button" data-who="partner" aria-pressed="false">a partner</button>
    </div>
    <p class="avail">The daily companion runs in any browser today. The full Hopeling, with School, the Lab and Kids, is in testing on iPhone, with Android to follow.</p>
  </div>
  <div class="scene">${heroScene()}</div>
  <p class="skynote" id="skynote"></p>
</section>

<section class="sec lab" id="lab" aria-labelledby="h-lab">
  <div class="wrap">
    <div class="sec-head rev">
      <p class="kicker">The Lab</p>
      <h2 id="h-lab">Pull one thread, <em>and watch the web answer.</em></h2>
      <p class="lede">Two meadows, one difference. This is a real experiment from the Hopeling Lab, with the same equations and the same numbers as the app. Guess first. Nothing here is graded.</p>
    </div>
    <div class="bench rev" id="bench">
      <div class="bench-top">
        <p class="q">Take the bees out of the meadow on the right.</p>
        <div class="levers" id="levers" role="group" aria-label="How many bees are lost">
          <button class="chip" type="button" aria-pressed="false">Lose half the bees</button>
          <button class="chip" type="button" aria-pressed="true">Lose all the bees</button>
        </div>
      </div>
      <div class="benches">
        <div class="plot" id="plot-a"><span class="tag">Bench A <b>all the bees stay</b></span>${benchScene('a')}</div>
        <div class="plot" id="plot-b"><span class="tag">Bench B <b id="tag-b">no bees at all</b></span>${benchScene('b')}</div>
      </div>
      <div class="clock"><div class="bar" aria-hidden="true"><i id="bar"></i></div><div class="when" id="when" aria-live="off">spring, year 1</div></div>
      <div class="stage">
        <div id="stage-pre">
          <h3>Before it runs, your guess</h3>
          <p>Three years from now, where do the <b>foxes</b> on bench B finish, compared with the meadow that kept its bees?</p>
          <div class="guess" id="guess" role="group" aria-label="Your guess">
            <button class="chip" type="button" data-g="higher" aria-pressed="false">higher</button>
            <button class="chip" type="button" data-g="lower" aria-pressed="false">lower</button>
            <button class="chip" type="button" data-g="about the same" aria-pressed="false">about the same</button>
          </div>
          <p class="small">A guess is how a scientist says hello to a question.</p>
          <div class="go"><button class="btn btn-go" id="run" type="button" disabled data-goal="lab-run">Run both benches</button></div>
        </div>
        <div id="stage-post" hidden>
          <p class="said" id="said" aria-live="polite"></p>
          <div class="sparks">${sparks}</div>
          <div class="legend"><span><i class="dash"></i>bench A, the bees stay</span><span><i></i>bench B, best estimate</span><span><i class="band"></i>cautious to severe: the model run three ways</span></div>
          <p style="margin-top:18px;max-width:46em" id="verdict" aria-live="polite"></p>
          <div class="go">
            <button class="btn btn-go" id="repair" type="button" hidden data-goal="lab-repair">Plant the native patch</button>
            <button class="btn btn-quiet" id="again" type="button" hidden>Start again</button>
          </div>
        </div>
        <p class="hood">A model, honestly small: three populations and three threads drawn from a rope of thousands. It shows directions, not destinies. Trust the foxes' line least, because predators add up everything, including much we left out. The Lab in the app holds twelve experiments like this one, from wolves in Yellowstone to a single windowsill, and every thread in each of them can be opened to see why it is there.</p>
      </div>
    </div>
  </div>
</section>

<section class="sec near" id="near" aria-labelledby="h-near">
  <div class="wrap split">
    <div class="rev">
      <p class="kicker">Explore</p>
      <h2 id="h-near">A world that knows <em>what time it is.</em></h2>
      <p class="lede" style="margin-top:20px">Most field guides tell you what an animal is. Hopeling tells you what she is doing right now, this season, tonight. Ten neighbours who live by the hour, an atlas of the wider world, and an archive of good news that has never deleted an entry.</p>
      <div class="facts"><div><b>28</b>worlds in the atlas</div><div><b>129</b>species portraits</div><div><b>10</b>neighbours by the hour</div></div>
      <p style="margin-top:26px"><a class="textlink" href="/atlas/" data-goal="atlas">Open the atlas</a> &nbsp; <a class="textlink" href="/wins/" data-goal="wins">Read the good news</a></p>
    </div>
    <div class="now rev" aria-label="What three neighbours are doing this season">
      <p class="kicker" id="near-when">This spring</p>
      ${nearHtml}
      <p class="small">Northern seasons. The app also keeps the real sky at your real minute.</p>
    </div>
  </div>
</section>

<section class="sec school" id="school" aria-labelledby="h-school">
  <div class="wrap split" style="align-items:start">
    <div class="rev">
      <p class="kicker">Hopeling School</p>
      <h2 id="h-school">Nothing is learned <em>until it is seen.</em></h2>
      <p class="lede" style="margin-top:20px">That is the School's first law. So it opens with one thing to do outside, and only then with something to read. Five jobs, not a library with a lobby.</p>
      <ol class="jobs">
        <li><b>Do one thing outside today</b><span>The Errand. Today's might be: stand still for two minutes and count how many different bird voices you can hear. Names not required.</span></li>
        <li><b>Continue</b><span>The walk you were on. Each chapter is one true idea, one thing to notice, and a field note earned that can never be lost.</span></li>
        <li><b>Five minutes of wonder</b><span>One short thing, chosen by the calendar: a bird to learn by ear from a real recording, a clue in this week's mystery, a neighbour awake right now.</span></li>
        <li><b>Experiment</b><span>This fortnight's question in the Lab. Guess, run, open the threads, repair.</span></li>
        <li><b>Go deeper</b><span>Paths and long reads, on one shelf.</span></li>
      </ol>
    </div>
    <div class="teach rev">
      <p class="kicker">For the grown-up at the front of the room</p>
      <p class="board">If the bees go, who feels it last?</p>
      <p>The Classroom Bench runs any experiment with a whole class. The room predicts together, each group pulls a different lever, and every world runs at once on one clock.</p>
      <div class="rail" aria-hidden="true"><div class="on">brief</div><div class="on">hands</div><div class="on">run</div><div>compare</div><div>discuss</div><div>close</div></div>
      <div class="first"><b>What the room usually says first</b>The room answers "the flowers" almost immediately, and that answer is right and it is the easy half. Hold the question open until somebody says a word that is not a plant.</div>
      <p style="margin-top:16px">Every experiment carries a plan like this one, written by a person. No student accounts. Nothing is scored.</p>
      <a class="btn" href="/bench/" data-goal="bench">Run this lesson with a room</a>
      <p style="margin-top:14px;font-size:14.5px"><a href="/schools/" data-goal="schools" style="color:#F4F1E6;font-weight:700">Hopeling for schools</a></p>
    </div>
  </div>
</section>

<section class="sec kids" id="kids" aria-labelledby="h-kids">
  <div class="wrap split">
    <div class="rev">
      <p class="kicker">Hopeling Kids</p>
      <h2 id="h-kids">A child can never <em>end in the ruins.</em></h2>
      <p class="lede" style="margin-top:20px">A gentler Hopeling behind a parent's gate. The same science as the grown-ups, told as a story, with one law added: whatever a child chooses, the last act is repair.</p>
      <ul class="laws">
        <li>No scores, no timers, no losing</li>
        <li>No ads, no chat, no strangers, nothing to buy</li>
        <li>No location, no camera, no microphone</li>
        <li>Stories read aloud in a warm recorded voice</li>
      </ul>
    </div>
    <div class="rev">
      <div class="meadow" id="meadow">${kidsScene()}${spots}</div>
      <div class="story">
        <p id="story">The bees flew away, and the flowers made fewer seeds. Can you help the meadow come back? Tap the soft ground and plant a wild patch.</p>
        <p class="small" id="seedcount">0 of 6 seeds in the ground</p>
        <button class="btn btn-quiet" id="hear" type="button" hidden>Hear the storyteller</button>
      </div>
    </div>
  </div>
</section>

<section class="sec act" id="act" aria-labelledby="h-act">
  <div class="wrap split">
    <div class="rev">
      <p class="kicker">Act</p>
      <h2 id="h-act">Knowledge that ends <em>in a decision.</em></h2>
      <p class="lede" style="margin-top:20px">Every day, one small thing and the honest reason it matters. And for the choices you make once and live with for years, we already read the label: one thing to avoid, one to prefer, one pick, and the neighbour it reaches.</p>
      <p class="lede" style="margin-top:14px">Eight seconds if you are on the fence. An afternoon behind "why?" if you are not. No ranking exists, so nothing can buy a place in one.</p>
      <p class="pulse" id="pulse" hidden><b id="pulse-n"></b>small actions taken together so far, and counting</p>
    </div>
    <div class="card8 rev">
      <p class="kicker">This, not that</p>
      <p class="q">${esc(SWAP.question)}</p>
      <div class="row"><b style="color:#B05B5B">AVOID</b><span>${esc(SWAP.avoid[0].ingredient)}</span></div>
      <div class="row"><b style="color:var(--fern)">PREFER</b><span>${esc(SWAP.prefer[0].trait)}</span></div>
      <div class="row"><b>PICK</b><span>${esc(SWAP.pick.label)}<small>checked ${esc(SWAP.reviewed)}</small></span></div>
      <div class="reach">${icon(B.frog, {}, '-26 -30 52 34')}<span>${esc(SWAP.consequence.line)}</span></div>
      <a class="btn btn-go" href="/swaps/${SWAP.id}/" data-goal="swap-card">Why? Open the whole card</a>
    </div>
  </div>
</section>

<section class="sec film" id="film" aria-labelledby="h-film">
  <div class="wrap">
    <div class="sec-head rev">
      <p class="kicker">The film</p>
      <h2 id="h-film">The little meadow, in ninety seconds.</h2>
      <p class="lede">Told in the storyteller's own voice, on the Lab's own numbers.</p>
    </div>
    <video class="rev" controls preload="none" playsinline poster="/film/poster.jpg" aria-label="Hopeling: the little meadow. A ninety second film.">
      <source src="/film/hopeling-film.mp4" type="video/mp4"/>
    </video>
  </div>
</section>

<section class="sec never" aria-labelledby="h-never">
  <div class="wrap">
    <div class="sec-head rev">
      <p class="kicker">The constitution</p>
      <h2 id="h-never">What Hopeling will never be.</h2>
    </div>
    <ul class="nlist rev">
      <li>A scoreboard<span>No points, no streak guilt, no leaderboards. Your tree grows rings, and a missed week is a rest.</span></li>
      <li>An advertisement<span>No ads and nothing sold inside. No ranking that money could move.</span></li>
      <li>A doom feed<span>Severity is shown, never performed. Every model admits what it leaves out.</span></li>
      <li>A place a child can lose<span>No fail states, no timers, no chatbot. Every children's story ends in repair.</span></li>
      <li>A collector of your life<span>No tracking. The daily companion needs no account at all.</span></li>
      <li>Fake "live" data<span>The same minute gives the same sky, everywhere. A book, not a slot machine.</span></li>
    </ul>
    <p class="foot rev">These are not a mood. They are written into the app's tests, and a change that breaks one does not ship.</p>
  </div>
</section>

<section class="sec doors" aria-labelledby="h-doors">
  <div class="wrap">
    <div class="sec-head rev"><p class="kicker">Begin</p><h2 id="h-doors">Where would you like to start?</h2></div>
    <div class="dgrid rev">
      <a class="door" href="/hopeling-web/Hopeling.html" data-goal="door-family"><b>At home</b><span>One fact and one small act a day, in any browser, with no account. Ask us for early access to the full app and to Hopeling Kids.</span><i>Open the web app</i></a>
      <a class="door" href="/schools/" data-goal="door-school"><b>In a classroom</b><span>A six-week unit for grades 4 to 6 built on the Lab, the Errand and one real change to your schoolyard. The first lesson runs in your browser today, and we are looking for our first pilot classrooms.</span><i>Hopeling for schools</i></a>
      <a class="door" href="${mail('Hopeling partnership', 'Hello,\n\nI work with (organisation) and would like to talk about:\n\n')}" data-goal="door-partner"><b>With an organisation</b><span>Aquariums, museums, watershed groups and outdoor programs: Hopeling can be the six weeks after the field trip.</span><i>Write to us</i></a>
    </div>
  </div>
</section>
</main>

<footer><div class="wrap">
  <div><a class="brand" href="/">${leafMark}hopeling</a><p style="margin-top:10px">small actions, real hope</p></div>
  <nav aria-label="Footer"><a href="/today/">Today</a><a href="/atlas/">Atlas</a><a href="/wins/">Wins</a><a href="/facts/">Facts</a><a href="/guardians/">Guardians</a><a href="/swaps/">This, not that</a><a href="/schools/">Schools</a><a href="/privacy.html">Privacy</a><a href="mailto:contant.hopeling@gmail.com">Contact</a></nav>
  <p class="fine">© ${new Date().getFullYear()} Hopeling. Made by a small team and a growing forest of helpers. The sky on this page is drawn from your own clock, and nothing about your visit is tracked.</p>
</div></footer>

<script>window.HL=${JSON.stringify(HL)};${PREVIEW ? `window.__PREVIEW=${JSON.stringify(PREVIEW)};` : ''}</script>
<script>${js}</script>
</body>
</html>
`;

const out = OUT || path.join(ROOT, 'index.html');
fs.writeFileSync(out, html);
console.log(`homepage: ${(html.length / 1024).toFixed(1)} KB -> ${out}${PREVIEW ? '  [preview ' + PREVIEW + ']' : ''}`);
