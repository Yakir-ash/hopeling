#!/usr/bin/env node
// Nature games for the shelf - generated, not scraped, because a maze
// is really a maze and a word search is really a word search: puzzle
// quality is guaranteed by the algorithm in a way drawings never were.
// Everything is seeded and deterministic (the same puzzle prints the
// same forever), pure black vector strokes for crisp ink-friendly
// printing, and every game carries its animal's story.
//
// Usage: node scripts/games.js   (writes into ./coloring/)

const fs = require('fs');
const path = require('path');

const OUT = path.join(__dirname, '..', 'coloring');

// seeded PRNG (mulberry32) - a book, not a slot machine
function rng(seed) {
  let a = seed >>> 0;
  return () => {
    a |= 0; a = (a + 0x6D2B79F5) | 0;
    let t = Math.imul(a ^ (a >>> 15), 1 | a);
    t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t;
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}
const esc = s => String(s).replace(/&/g, '&amp;').replace(/</g, '&lt;')
    .replace(/>/g, '&gt;').replace(/"/g, '&quot;');

// ---------- shared page shell ----------
const CSS = `
  * { box-sizing: border-box; }
  body { font-family: Georgia, serif; color: #16241C; margin: 0;
         background: #FAF8F2; }
  .page { max-width: 800px; margin: 0 auto; padding: 24px;
          background: #fff; min-height: 100vh; }
  h1 { font-size: 26px; margin: 0 0 4px; }
  .sub { font-size: 13.5px; color: #55645B; margin-bottom: 14px; }
  .tools { display: flex; gap: 8px; margin: 14px 0; flex-wrap: wrap; }
  .tools button, .tools a { font-family: inherit; font-size: 13px;
    padding: 8px 14px; border: 2px solid #16241C; background: #fff;
    border-radius: 10px; cursor: pointer; text-decoration: none;
    color: #16241C; }
  .tools .sel { background: #B2F1CC; }
  .lvl { display: none; }
  body.L1 .lvl1, body.L2 .lvl2, body.L3 .lvl3 { display: block; }
  .fact { border: 2px dashed #16241C; border-radius: 10px;
          padding: 10px 14px; font-size: 13px; margin-top: 12px; }
  .foot { font-size: 11px; color: #777; margin-top: 14px; }
  .words { columns: 2; font-size: 14.5px; letter-spacing: 1px;
           line-height: 2; margin-top: 10px; }
  .clues { font-size: 13.5px; line-height: 1.8; }
  .clues b { color: #2E6B4F; }
  @media print {
    .tools, .backrow { display: none !important; }
    body { background: #fff; } .page { min-height: 0; padding: 0; }
    @page { margin: 14mm; }
  }
`;
const shell = (title, sub, body, extraCss = '') =>
`<!doctype html><html lang="en"><head><meta charset="utf-8"/>
<meta name="viewport" content="width=device-width, initial-scale=1"/>
<title>${esc(title)} - Hopeling</title><style>${CSS}${extraCss}</style></head>
<body class="L2"><div class="page">
<div class="tools backrow"><a href="index.html">← The shelf</a></div>
<h1>${esc(title)}</h1><div class="sub">${esc(sub)}</div>
${body}
<div class="foot">Hopeling · hopeling.app · print me, puzzle me, keep me</div>
</div></body></html>`;
const levelBtns = (l1, l2, l3) => `
<div class="tools">
  <button onclick="setL(1)" id="b1">🐣 ${l1}</button>
  <button onclick="setL(2)" id="b2" class="sel">🦊 ${l2}</button>
  <button onclick="setL(3)" id="b3">🦉 ${l3}</button>
  <button onclick="window.print()">🖨 Print</button>
</div>
<script>function setL(n){document.body.className='L'+n;
for(var i=1;i<=3;i++)document.getElementById('b'+i).className=i===n?'sel':'';}
document.body.className='L2';</script>`;

// ---------- mazes: real recursive-backtracker mazes ----------
function maze(cols, rows, seed) {
  const r = rng(seed);
  const walls = []; // per cell: {n,s,e,w}
  for (let i = 0; i < cols * rows; i++) {
    walls.push({ n: 1, s: 1, e: 1, w: 1 });
  }
  const seen = new Array(cols * rows).fill(false);
  const stack = [0];
  seen[0] = true;
  while (stack.length) {
    const c = stack[stack.length - 1];
    const x = c % cols, y = (c / cols) | 0;
    const opts = [];
    if (y > 0 && !seen[c - cols]) opts.push(['n', c - cols]);
    if (y < rows - 1 && !seen[c + cols]) opts.push(['s', c + cols]);
    if (x > 0 && !seen[c - 1]) opts.push(['w', c - 1]);
    if (x < cols - 1 && !seen[c + 1]) opts.push(['e', c + 1]);
    if (!opts.length) { stack.pop(); continue; }
    const [dir, n] = opts[(r() * opts.length) | 0];
    walls[c][dir] = 0;
    walls[n][{ n: 's', s: 'n', e: 'w', w: 'e' }[dir]] = 0;
    seen[n] = true;
    stack.push(n);
  }
  return walls;
}

function mazeSvg(cols, rows, seed, startEmo, endEmo) {
  const cell = 560 / Math.max(cols, rows);
  const W = cols * cell, H = rows * cell, pad = 30;
  const walls = maze(cols, rows, seed);
  let lines = '';
  for (let y = 0; y < rows; y++) {
    for (let x = 0; x < cols; x++) {
      const w = walls[y * cols + x];
      const X = pad + x * cell, Y = pad + y * cell;
      if (w.n && !(y === 0 && x === 0)) // entrance: top-left opening
        lines += `<line x1="${X}" y1="${Y}" x2="${X + cell}" y2="${Y}"/>`;
      if (w.w) lines += `<line x1="${X}" y1="${Y}" x2="${X}" y2="${Y + cell}"/>`;
      if (x === cols - 1 && w.e && !(y === rows - 1))
        lines += `<line x1="${X + cell}" y1="${Y}" x2="${X + cell}" y2="${Y + cell}"/>`;
      if (y === rows - 1 && w.s && !(x === cols - 1)) // exit: bottom-right
        lines += `<line x1="${X}" y1="${Y + cell}" x2="${X + cell}" y2="${Y + cell}"/>`;
    }
  }
  return `<svg viewBox="0 0 ${W + pad * 2} ${H + pad * 2 + 10}" width="100%"
 xmlns="http://www.w3.org/2000/svg" role="img">
<g stroke="#16241C" stroke-width="3" stroke-linecap="round">${lines}</g>
<text x="${pad + cell / 2}" y="${pad - 8}" font-size="24"
 text-anchor="middle">${startEmo}</text>
<text x="${pad + W - cell / 2}" y="${pad + H + 26}" font-size="24"
 text-anchor="middle">${endEmo}</text></svg>`;
}

const MAZES = [
  { slug: 'turtle-sea', t: 'Help the sea turtle reach the sea',
    s: '🐢', e: '🌊', fact: 'Baby sea turtles hatch on the beach and find the sea by the light on the water.' },
  { slug: 'bee-flower', t: 'Help the bee find the flower',
    s: '🐝', e: '🌸', fact: 'A bee tells its hive where flowers are with a waggle dance.' },
  { slug: 'salmon-upstream', t: 'Help the salmon swim upstream',
    s: '🐟', e: '🏞️', fact: 'Salmon remember the smell of the stream where they hatched.' },
  { slug: 'fox-den', t: 'Help the fox find its den',
    s: '🦊', e: '🕳️', fact: 'A fox wraps its tail over its nose to stay warm while it sleeps.' },
  { slug: 'penguin-family', t: 'Help the penguin waddle home',
    s: '🐧', e: '🐧🐧', fact: 'Penguin parents find their own chick among thousands by its voice.' },
  { slug: 'butterfly-garden', t: 'Help the butterfly cross the garden',
    s: '🦋', e: '🌼', fact: 'Butterflies taste with their feet.' },
  { slug: 'owl-nest', t: 'Help the owl glide to its nest',
    s: '🦉', e: '🌳', fact: 'Owl feathers have soft edges so their flight makes almost no sound.' },
  { slug: 'frog-pond', t: 'Help the frog hop to the pond',
    s: '🐸', e: '🪷', fact: 'Frogs drink through their skin instead of their mouths.' },
];

// ---------- word searches ----------
const SEARCHES = [
  { slug: 'ocean', t: 'Ocean word search', emo: '🌊',
    words: ['WHALE', 'DOLPHIN', 'CORAL', 'TURTLE', 'OCTOPUS', 'SEAL',
      'CRAB', 'KELP', 'SHARK', 'WAVE'] },
  { slug: 'forest', t: 'Forest word search', emo: '🌲',
    words: ['OWL', 'FOX', 'DEER', 'MUSHROOM', 'SQUIRREL', 'BADGER',
      'MOSS', 'ACORN', 'WOLF', 'ROOTS'] },
  { slug: 'birds', t: 'Bird word search', emo: '🐦',
    words: ['ROBIN', 'FEATHER', 'NEST', 'EAGLE', 'HERON', 'PUFFIN',
      'WING', 'EGG', 'BEAK', 'SONG'] },
  { slug: 'backyard', t: 'Backyard word search', emo: '🌼',
    words: ['BEE', 'WORM', 'SNAIL', 'LADYBUG', 'CLOVER', 'SPIDER',
      'TOAD', 'SEED', 'PETAL', 'ANT'] },
  { slug: 'rivers', t: 'River word search', emo: '🏞️',
    words: ['SALMON', 'BEAVER', 'OTTER', 'STREAM', 'PEBBLE', 'REED',
      'HERON', 'MINNOW', 'RIPPLE', 'FROG'] },
  { slug: 'arctic', t: 'Arctic word search', emo: '❄️',
    words: ['PENGUIN', 'WALRUS', 'AURORA', 'SNOW', 'SEAL', 'PUFFIN',
      'ICEBERG', 'NARWHAL', 'FOX', 'CARIBOU'] },
];

function wordSearch(words, size, seed) {
  const r = rng(seed);
  const g = Array.from({ length: size }, () => new Array(size).fill(''));
  const dirs = [[1, 0], [0, 1], [1, 1], [1, -1]];
  const placed = [];
  for (const w of [...words].sort((a, b) => b.length - a.length)) {
    let ok = false;
    for (let tries = 0; tries < 300 && !ok; tries++) {
      const [dx, dy] = dirs[(r() * dirs.length) | 0];
      const x0 = (r() * size) | 0, y0 = (r() * size) | 0;
      const xe = x0 + dx * (w.length - 1), ye = y0 + dy * (w.length - 1);
      if (xe < 0 || xe >= size || ye < 0 || ye >= size) continue;
      let fits = true;
      for (let i = 0; i < w.length; i++) {
        const c = g[y0 + dy * i][x0 + dx * i];
        if (c && c !== w[i]) { fits = false; break; }
      }
      if (!fits) continue;
      for (let i = 0; i < w.length; i++) g[y0 + dy * i][x0 + dx * i] = w[i];
      placed.push(w);
      ok = true;
    }
  }
  const AZ = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
  for (let y = 0; y < size; y++) {
    for (let x = 0; x < size; x++) {
      if (!g[y][x]) g[y][x] = AZ[(r() * 26) | 0];
    }
  }
  return { grid: g, placed };
}

function searchSvg(grid) {
  const n = grid.length, cell = 560 / n, pad = 10;
  let t = '';
  for (let y = 0; y < n; y++) {
    for (let x = 0; x < n; x++) {
      t += `<text x="${pad + x * cell + cell / 2}" y="${pad + y * cell + cell * 0.72}"
 font-size="${cell * 0.55}" text-anchor="middle"
 font-family="Georgia, serif">${grid[y][x]}</text>`;
    }
  }
  return `<svg viewBox="0 0 ${n * cell + pad * 2} ${n * cell + pad * 2}"
 width="100%" xmlns="http://www.w3.org/2000/svg">
<rect x="4" y="4" width="${n * cell + 12}" height="${n * cell + 12}"
 fill="none" stroke="#16241C" stroke-width="3" rx="10"/>${t}</svg>`;
}

// ---------- criss-cross puzzles (crossword, kid-sized) ----------
const CRISSCROSS = [
  { slug: 'ocean', t: 'Ocean criss-cross', emo: '🌊', entries: [
    ['WHALE', 'I am the biggest animal that has ever lived'],
    ['OCTOPUS', 'I have eight arms and three hearts'],
    ['TURTLE', 'I carry my home on my back through the sea'],
    ['CORAL', 'I look like a rock but I am millions of tiny animals'],
    ['SEAHORSE', 'The dads in my family carry the babies'],
    ['DOLPHIN', 'I sleep with one half of my brain at a time'],
    ['CRAB', 'I walk sideways along the sand'],
  ]},
  { slug: 'forest', t: 'Forest criss-cross', emo: '🌲', entries: [
    ['WOODPECKER', 'I tap on trees to find my lunch'],
    ['SQUIRREL', 'I bury acorns and forget some - they become trees'],
    ['OWL', 'I can turn my head almost all the way around'],
    ['FOX', 'I wrap my fluffy tail over my nose to sleep'],
    ['DEER', 'I grow new antlers every single year'],
    ['MUSHROOM', 'I am the fruit of a web that lives underground'],
    ['BEAR', 'I sleep through most of the winter'],
  ]},
  { slug: 'backyard', t: 'Backyard criss-cross', emo: '🌼', entries: [
    ['EARTHWORM', 'I make the soil healthy by eating my way through it'],
    ['LADYBUG', 'Count my spots - I eat the bugs that hurt plants'],
    ['SNAIL', 'I never have to find a home - I carry mine'],
    ['BEE', 'My dance tells my friends where the flowers are'],
    ['BUTTERFLY', 'I taste with my feet'],
    ['ROBIN', 'I tilt my head to listen for worms underground'],
    ['ANT', 'I can carry things much heavier than me'],
  ]},
];

/// Try many word orders (seeded) and keep the layout that places the
/// most words - deterministic, and almost always all of them.
function crissCross(entries, seed) {
  const r = rng(seed);
  let best = null;
  const base = entries.map(e => e[0]);
  for (let attempt = 0; attempt < 80; attempt++) {
    const words = [...base];
    for (let i = words.length - 1; i > 0; i--) {
      const j = (r() * (i + 1)) | 0;
      [words[i], words[j]] = [words[j], words[i]];
    }
    const out = crissCrossOnce(words);
    if (!best || out.placedList.length > best.placedList.length) best = out;
    if (best.placedList.length === base.length) break;
  }
  return best;
}

function crissCrossOnce(words) {
  const G = 21, mid = (G / 2) | 0;
  const grid = Array.from({ length: G }, () => new Array(G).fill(''));
  const placedList = [];
  const place = (w, x, y, horiz) => {
    for (let i = 0; i < w.length; i++) {
      grid[y + (horiz ? 0 : i)][x + (horiz ? i : 0)] = w[i];
    }
    placedList.push({ w, x, y, horiz });
  };
  const canPlace = (w, x, y, horiz) => {
    if (x < 0 || y < 0) return false;
    if (horiz ? x + w.length > G : y + w.length > G) return false;
    let crosses = 0;
    for (let i = 0; i < w.length; i++) {
      const cx = x + (horiz ? i : 0), cy = y + (horiz ? 0 : i);
      const c = grid[cy][cx];
      if (c) {
        if (c !== w[i]) return false;
        crosses++;
      } else {
        // keep breathing room beside empty cells
        const sides = horiz
            ? [[cx, cy - 1], [cx, cy + 1]] : [[cx - 1, cy], [cx + 1, cy]];
        for (const [sx, sy] of sides) {
          if (grid[sy] && grid[sy][sx]) return false;
        }
      }
    }
    // no letter touching the ends
    const bx = x - (horiz ? 1 : 0), by = y - (horiz ? 0 : 1);
    const ax = x + (horiz ? w.length : 0), ay = y + (horiz ? 0 : w.length);
    if (grid[by] && grid[by][bx]) return false;
    if (grid[ay] && grid[ay][ax]) return false;
    return crosses > 0;
  };
  const first = words[0];
  place(first, mid - (first.length >> 1), mid, true);
  for (const w of words.slice(1)) {
    let done = false;
    for (const p of [...placedList]) {
      if (done) break;
      for (let i = 0; i < p.w.length && !done; i++) {
        for (let j = 0; j < w.length && !done; j++) {
          if (p.w[i] !== w[j]) continue;
          const x = p.horiz ? p.x + i : p.x - j;
          const y = p.horiz ? p.y - j : p.y + i;
          if (canPlace(w, x, y, !p.horiz)) {
            place(w, x, y, !p.horiz);
            done = true;
          }
        }
      }
    }
  }
  // trim to bounding box
  let minX = G, minY = G, maxX = 0, maxY = 0;
  for (let y = 0; y < G; y++) {
    for (let x = 0; x < G; x++) {
      if (grid[y][x]) {
        minX = Math.min(minX, x); maxX = Math.max(maxX, x);
        minY = Math.min(minY, y); maxY = Math.max(maxY, y);
      }
    }
  }
  return { grid, placedList, minX, minY, maxX, maxY };
}

function crissSvg(cc, entries) {
  const { grid, placedList, minX, minY, maxX, maxY } = cc;
  const cols = maxX - minX + 1, rows = maxY - minY + 1;
  const cell = Math.min(560 / cols, 34), pad = 8;
  let boxes = '', nums = '';
  const starts = new Map();
  placedList.forEach((p, i) => starts.set(`${p.x},${p.y}`,
      (starts.get(`${p.x},${p.y}`) || []).concat(i + 1)));
  for (let y = minY; y <= maxY; y++) {
    for (let x = minX; x <= maxX; x++) {
      if (!grid[y][x]) continue;
      const X = pad + (x - minX) * cell, Y = pad + (y - minY) * cell;
      boxes += `<rect x="${X}" y="${Y}" width="${cell}" height="${cell}"
 fill="#fff" stroke="#16241C" stroke-width="2"/>`;
    }
  }
  placedList.forEach((p, i) => {
    const X = pad + (p.x - minX) * cell, Y = pad + (p.y - minY) * cell;
    nums += `<text x="${X + 3}" y="${Y + 11}" font-size="9"
 font-family="Georgia">${i + 1}</text>`;
  });
  const clues = placedList.map((p, i) => {
    const clue = entries.find(e => e[0] === p.w)[1];
    return `<div><b>${i + 1} ${p.horiz ? 'Across' : 'Down'}:</b> ` +
        `${esc(clue)} <span style="color:#999">(${p.w.length})</span></div>`;
  }).join('');
  return `<svg viewBox="0 0 ${cols * cell + pad * 2} ${rows * cell + pad * 2}"
 width="100%" xmlns="http://www.w3.org/2000/svg">${boxes}${nums}</svg>
 <div class="clues">${clues}</div>`;
}

// ---------- build all pages ----------
let made = 0;
for (const m of MAZES) {
  const seed = 1000 + made;
  const body = `
  <div class="lvl lvl1">${mazeSvg(8, 8, seed, m.s, m.e)}</div>
  <div class="lvl lvl2">${mazeSvg(12, 12, seed + 1, m.s, m.e)}</div>
  <div class="lvl lvl3">${mazeSvg(17, 17, seed + 2, m.s, m.e)}</div>
  ${levelBtns('Little maze', 'Middle maze', 'Big maze')}
  <div class="fact">🌿 ${esc(m.fact)}</div>`;
  fs.writeFileSync(path.join(OUT, `maze-${m.slug}.html`),
      shell(m.t, 'Start at the top. No crossing walls!', body));
  made++;
}
for (const s of SEARCHES) {
  const seed = 2000 + made;
  const small = wordSearch(s.words.slice(0, 7), 10, seed);
  const mid = wordSearch(s.words, 12, seed + 1);
  const big = wordSearch(s.words, 14, seed + 2);
  const wl = w => `<div class="words">${w.map(x => `☐ ${x}`).join('<br/>')}</div>`;
  const body = `
  <div class="lvl lvl1">${searchSvg(small.grid)}${wl(small.placed)}</div>
  <div class="lvl lvl2">${searchSvg(mid.grid)}${wl(mid.placed)}</div>
  <div class="lvl lvl3">${searchSvg(big.grid)}${wl(big.placed)}</div>
  ${levelBtns('Fewer words', 'The classic', 'Bigger grid')}
  <div class="fact">Words hide across, down and diagonally. Tick each one you find.</div>`;
  fs.writeFileSync(path.join(OUT, `wordsearch-${s.slug}.html`),
      shell(`${s.emo} ${s.t}`, 'Circle the hidden nature words.', body));
  made++;
}
for (const c of CRISSCROSS) {
  const cc = crissCross(c.entries, 3000 + made);
  const placedWords = cc.placedList.map(p => p.w);
  const missing = c.entries.filter(e => !placedWords.includes(e[0]));
  const body = `${crissSvg(cc, c.entries)}
  ${missing.length ? '' : ''}
  <div class="fact">Every answer is an animal or a piece of nature.
  The number tells you how many letters.</div>
  <div class="tools"><button onclick="window.print()">🖨 Print</button></div>`;
  fs.writeFileSync(path.join(OUT, `crisscross-${c.slug}.html`),
      shell(`${c.emo} ${c.t}`, 'Read the clue, count the letters, fill the boxes.', body));
  if (missing.length) {
    console.log(`  note: ${c.slug} could not place: ${missing.map(e => e[0]).join(', ')}`);
  }
  made++;
}
console.log(`games: ${made} puzzle pages written into coloring/`);
