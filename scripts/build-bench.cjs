#!/usr/bin/env node
/* Builds /bench/ : the Classroom Bench in the browser, for one lesson
   (The Meadow Web). Everything on the page is read from the app's own
   source, and the build stops if the numbers it expects are not there:
     app/lib/data/lab.dart    the model, the levers, the threads, the repair, the hood
     app/lib/data/bench.dart  the lesson plan
   Run:  node scripts/build-bench.cjs
   Preview variants: node scripts/build-bench.cjs --preview=stage=3,hands=6-17-4 --out=/some/file.html */

const fs = require('fs');
const path = require('path');
const ROOT = path.join(__dirname, '..');
const B = require(path.join(ROOT, 'brand', 'creatures.cjs'));
const { benchScene } = require(path.join(ROOT, 'brand', 'scenes.cjs'));
const { C } = B;
const arg = k => { const a = process.argv.find(x => x.startsWith('--' + k + '=')); return a ? a.slice(k.length + 3) : ''; };
const PREVIEW = arg('preview'), OUT = arg('out');
const read = p => fs.readFileSync(path.join(ROOT, p), 'utf8');
const esc = s => String(s).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');
const must = (v, what) => { if (v === null || v === undefined || v === false) throw new Error('build-bench: could not read ' + what + ' from the app source'); return v; };
const STR = "((?:'(?:[^'\\\\]|\\\\.)*'\\s*)+)";
const dstr = b => (b.match(/'(?:[^'\\]|\\.)*'/g) || []).map(x => x.slice(1, -1).replace(/\\'/g, "'")).join('');

/* ---------------- the experiment, from lab.dart ---------------- */
const lab = read('app/lib/data/lab.dart');
const m0 = lab.indexOf("id: 'meadow'"), m1 = lab.indexOf('LabScenario(', m0);
const M = must(m0 >= 0 && lab.slice(m0, m1 > 0 ? m1 : undefined), 'the meadow scenario');
const nodes = [...M.matchAll(/EcoNode\('(\w+)', '([^']+)', '[^']*',([^)]*)\)/g)].map(m => ({
  id: m[1], name: m[2], init: +(/init: ([\d.]+)/.exec(m[3]) || [0, 0])[1], g: +(/\bg: (-?[\d.]+)/.exec(m[3]) || [0, 0])[1], s: +(/\bs: (-?[\d.]+)/.exec(m[3]) || [0, 0])[1],
}));
const edges = [...M.matchAll(new RegExp(`EcoEdge\\('(\\w+)', '(\\w+)', (-?[\\d.]+),\\s*why:\\s*${STR}`, 'g'))].map(m => [m[1], m[2], +m[3], dstr(m[4])]);
const options = [...M.matchAll(/LabOption\(\s*'([^']+)',\s*\{([^}]*)\}/g)].map(m => ({ label: m[1], dg: +(/dg: ([\d.]+)/.exec(m[2]) || [0, 0])[1] }));
const rep = must(new RegExp(`repair: RepairAct\\(\\s*'([^']+)',\\s*${STR},\\s*\\{'f': NodeDrive\\(dg: ([\\d.]+)\\)\\},[\\s\\S]*?\\],\\s*${STR},\\s*drag: ([\\d.]+)\\)`).exec(M), 'the repair act');
const hood = k => dstr(must(new RegExp(`${k}:\\s*${STR}`).exec(M.slice(M.indexOf('hood: UnderHood('))), 'the hood: ' + k)[1]);
const question = must(/question: '([^']+)'/.exec(M), 'the question')[1];
const title = must(/title: '([^']+)'/.exec(M), 'the title')[1];
const predictIndex = +must(/predictIndex: (\d+)/.exec(M), 'predictIndex')[1];
must(nodes.length === 3 && edges.length === 3 && options.length === 3, 'three nodes, three threads, three levers');
must(options[0].dg === 0.25 && options[1].dg === 0.125 && options[2].dg === 0, 'the lever strengths this page was checked against');

/* ---------------- the lesson, from bench.dart ---------------- */
const bench = read('app/lib/data/bench.dart');
const b0 = bench.indexOf("'meadow': BenchLesson("), b1 = bench.indexOf("': BenchLesson(", b0 + 10);
const L = must(b0 >= 0 && bench.slice(b0, b1), 'the meadow lesson');
const lesson = {
  board: dstr(must(new RegExp(`board:\\s*${STR},`).exec(L), 'board')[1]),
  first: dstr(must(new RegExp(`misconception:\\s*${STR},`).exec(L), 'misconception')[1]),
  ask: +must(/ask: (\d+)/.exec(L), 'ask')[1],
  discuss: must(/discuss: \[([\s\S]*?)\],\s*closing/.exec(L), 'discuss')[1].split(/,\n\s{6}(?=')/).map(dstr).filter(Boolean),
  closing: dstr(must(new RegExp(`closing:\\s*${STR},`).exec(L), 'closing')[1]),
  minutes: +must(/minutes: (\d+)/.exec(L), 'minutes')[1],
};
must(lesson.ask > 0 && lesson.ask < options.length && lesson.discuss.length === 3, 'a lesson that asks about a lever, with three prompts');

const names = nodes.map(n => n.name);
const BX = {
  title, question, nodes: nodes.map(({ id, init, g, s }) => ({ id, init, g, s })), edges: edges.map(e => e.slice(0, 3)), driven: 'f', steps: 12,
  names, colors: [C.fern, C.gold, C.rust], focus: { index: predictIndex, name: names[predictIndex] },
  options: options.map((o, i) => ({ label: o.label, dg: o.dg, bees: [4, 2, 0][i] })), slots: { f: 16, r: 6, x: 3, b: 4 },
  repair: { dg: +rep[3], drag: +rep[5] }, lesson: { ask: lesson.ask, discuss: lesson.discuss },
};

/* ---------------- the page ---------------- */
const leaf = `<svg viewBox="0 0 24 24" aria-hidden="true"><path d="M12 22C12 14 12 9 12 4M12 13C6 12 3 8 3 3C9 3 12 7 12 13ZM12 16C17 15 21 12 21 7C16 7 12 10 12 16Z" fill="none" stroke="currentColor" stroke-width="2.1" stroke-linecap="round" stroke-linejoin="round"/></svg>`;
const STAGES = ['brief', 'hands', 'run', 'compare', 'discuss', 'close'], ANS = ['higher', 'lower', 'about the same'];
const which = ['a', 'c', 'b'], roles = i => (i === 0 ? ' · the control' : '') + (i === lesson.ask ? ' · the room asked about this one' : '');
const span = BX.steps === 12 ? 'three years' : 'the years';
const nameOf = id => nodes.find(n => n.id === id).name;
const pilot = 'mailto:contant.hopeling@gmail.com?subject=' + encodeURIComponent('A Hopeling pilot at our school') + '&body=' + encodeURIComponent('Hello,\n\nI ran the meadow lesson in the browser.\n\nSchool or organisation:\nMy role:\nGrades and number of classes:\nWhat happened in the room:\n\n');

let css = read('brand/bench.css');
if (PREVIEW) css = css.replace(/url\(\/fonts\/([a-z-]+\.woff)\)/g, (_, p) => `url(data:font/woff;base64,${fs.readFileSync(path.join(ROOT, 'fonts', p)).toString('base64')})`);
const TITLE = `The Classroom Bench: ${title} - a lesson to run with a whole room`;
const DESC = `${lesson.board} A ${lesson.minutes}-minute lesson for a whole class, in the browser: the room predicts together, three groups pull three levers, and every meadow runs on one clock. No accounts, nothing saved, nothing scored.`;

const html = `<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8"/>
<meta name="viewport" content="width=device-width, initial-scale=1"/>
<title>${esc(TITLE)}</title>
<meta name="description" content="${esc(DESC)}"/>
<link rel="canonical" href="https://hopeling.app/bench/"/>
<meta property="og:type" content="website"/>
<meta property="og:site_name" content="Hopeling"/>
<meta property="og:title" content="${esc(TITLE)}"/>
<meta property="og:description" content="${esc(DESC)}"/>
<meta property="og:url" content="https://hopeling.app/bench/"/>
<meta property="og:image" content="https://hopeling.app/brand/og.jpg"/>
<meta name="twitter:card" content="summary_large_image"/>
<meta name="theme-color" content="#2E6B4F"/>
<link rel="icon" href="/hopeling-web/icon-192.png"/>
<link rel="preload" href="/fonts/hopeling-serif-regular.woff" as="font" type="font/woff" crossorigin/>
<style>${css}</style>
</head>
<body>
<header class="top">
  <a class="brand" href="/" aria-label="Hopeling, home">${leaf}hopeling</a>
  <span class="lesson">The Classroom Bench · <b>${esc(title)}</b></span>
  <ol class="rail" aria-label="The six moves of the lesson">${STAGES.map((s, i) => `<li><button type="button" id="rail${i}">${s}</button></li>`).join('')}</ol>
  <button class="ghost" type="button" id="fs">Full screen</button>
  <a class="ghost" href="/schools/">Leave</a>
</header>

<main id="main">
<section class="stage" id="s-brief" aria-labelledby="h-brief">
  <p class="kicker">For the board</p>
  <h1 class="board" id="h-brief">${esc(lesson.board)}</h1>
  <div class="stats"><div><b>${lesson.minutes} min</b><span>start to last word</span></div><div><b>${options.length} groups</b><span>one lever each</span></div><div><b>0 marks</b><span>nothing is scored</span></div></div>
  <div class="two">
    <div class="first"><p class="kicker">What the room usually says first</p><p>${esc(lesson.first)}</p></div>
    <div>
      <div class="groups">${options.map((o, i) => `<div class="group"><i>${i + 1}</i><span><small>Group ${i + 1}${roles(i)}</small>${esc(o.label)}</span></div>`).join('')}</div>
      <p class="note" style="margin-top:14px">Same meadow, same equations, one difference each. That is the whole shape of a controlled experiment, and the room can see it without being told.</p>
    </div>
  </div>
  <p class="note" style="margin-top:22px">This is the meadow lesson exactly as it is written in the Hopeling app, on the Lab's own model. Nothing here is saved or sent anywhere: close the tab and the room's hands are gone. Arrow keys or a presenter's clicker move the lesson along.</p>
</section>

<section class="stage" id="s-hands" aria-labelledby="h-hands" hidden>
  <p class="kicker">The whole room predicts</p>
  <h2 id="h-hands">After ${span}, where do the ${esc(BX.focus.name.toLowerCase())} finish under <em>${esc(options[lesson.ask].label)}</em>, compared with bench one, <em>${esc(options[0].label)}</em>?</h2>
  <div class="hands">${ANS.map((k, i) => `<div class="hand"><button class="add" type="button" id="add${i}"><span>${esc(BX.focus.name)}: ${k}</span><span class="n" id="n${i}">0</span></button><button class="less" type="button" id="less${i}" aria-label="Take one hand back from ${k}">−</button></div>`).join('')}</div>
  <p class="note" style="margin-top:18px">Read it aloud, then count the hands, one press per hand. No names, no marks, no record kept: a guess is how a scientist says hello to a question, and thirty at once is a louder hello.</p>
</section>

<section class="stage" id="s-run" aria-labelledby="h-run" hidden>
  <p class="kicker">One clock, every bench</p>
  <h2 id="h-run">${esc(question)}</h2>
  <div class="plots">${options.map((o, i) => `<div class="plot" id="plot-${i}"><span class="tag">Group ${i + 1} <b>${esc(o.label)}</b></span>${benchScene(which[i])}<div class="read" aria-hidden="true">${names.map((n, j) => `<span><b id="ro-${i}-${j}" style="color:${BX.colors[j]}">0</b>${esc(n.toLowerCase())}</span>`).join('')}</div></div>`).join('')}</div>
  <div class="clock"><button class="play" type="button" id="play" aria-label="Play every bench together">▶</button><input type="range" id="scrub" min="0" max="${BX.steps - 1}" step="0.01" value="0" aria-label="The clock, in seasons"/><span class="when" id="when" aria-live="off">season 1 of ${BX.steps}</span></div>
  <p class="note">One clock drives every meadow on this screen. The only thing that differs between them is the lever, which is the entire definition of a controlled experiment.</p>
</section>

<section class="stage" id="s-compare" aria-labelledby="h-compare" hidden>
  <div class="cols">
    <div>
      <p class="kicker">Where the room stood</p>
      <h3 id="h-compare" style="margin-top:8px">${esc(BX.focus.name)} under "${esc(options[lesson.ask].label)}", against bench one</h3>
      <div class="bars">${ANS.map((k, i) => `<div class="bar" id="barrow${i}"><span>${k}</span><span class="t"><i id="bar${i}" style="width:0"></i></span><b id="bn${i}">0</b></div>`).join('')}</div>
      <p class="verdict" id="verdict" aria-live="polite"></p>
    </div>
    <div>
      <p class="kicker">Every bench, after the years</p>
      <div class="after" style="margin-top:10px">${options.map((o, i) => `<div><small>Group ${i + 1} · ${esc(o.label)}${roles(i)}</small><span id="after${i}"></span></div>`).join('')}</div>
      <div class="chart"><svg id="focuschart" viewBox="0 0 520 190" role="img" aria-label="${esc(BX.focus.name)} over ${span}, one line for each group"></svg>
        <div class="legend">${options.map((o, i) => `<span><i style="border-color:${['#16241C', '#5E9B79', '#C8683A'][i]}${i === 0 ? ';border-top-style:dashed' : ''}"></i>${esc(o.label)}</span>`).join('')}</div></div>
      <p class="note" style="margin-top:10px">Numbers are the model's own scale, best-estimate run. The benches never disagree about the world: only the levers differ.</p>
    </div>
  </div>
</section>

<section class="stage" id="s-discuss" aria-labelledby="qk" hidden>
  <p class="kicker" id="qk">Question 1 of ${lesson.discuss.length}</p>
  <h2 class="qcard" id="qcard" style="max-width:none;margin-bottom:0" aria-live="polite"></h2>
  <details>
    <summary>If somebody asks: every thread in this model, in plain words</summary>
    <div class="asks">${edges.map(e => `<div><b>${esc(nameOf(e[0]))} ${e[2] >= 0 ? 'feed' : 'check'} the ${esc(nameOf(e[1]).toLowerCase())}</b>${esc(e[3])}</div>`).join('')}
      <div><small>What we know</small>${esc(hood('know'))}</div><div><small>What this model simplifies</small>${esc(hood('simplified'))}</div><div><small>Where the uncertainty lives</small>${esc(hood('uncertain'))}</div></div>
  </details>
</section>

<section class="stage" id="s-close" aria-labelledby="h-close" hidden>
  <p class="kicker">The repair, in front of them</p>
  <p style="margin:10px 0 12px;max-width:46em">${esc(dstr(rep[2]))}</p>
  <button class="btn go inline" type="button" id="plant" style="margin-left:0">${esc(rep[1])}</button>
  <div id="repaired" hidden>
    <div class="sparks">${names.map((n, i) => `<div class="spark"><div class="nm"><span style="color:${BX.colors[i]}">${esc(n)}</span><span id="end${i}"></span></div><svg id="spark${i}" viewBox="0 0 220 92" role="img" aria-label="${esc(n)}: ${span} of loss, then ${span} of repair"></svg></div>`).join('')}</div>
    <p class="note" id="repairline" style="margin-bottom:10px"></p>
    <p class="epi">${esc(dstr(rep[4]))}</p>
    <p class="note" style="margin-top:10px">${esc(hood('uncertain'))}</p>
  </div>
  <p class="kicker" style="margin-top:clamp(20px,3vh,36px)">Leave this one standing</p>
  <h2 class="standing" id="h-close" style="max-width:none">${esc(lesson.closing)}</h2>
  <p class="note">Nothing was scored, nobody was named, and no hand counted here was ever saved. What the room keeps is the argument it had.</p>
  <p class="note" style="margin-top:14px">This is one of twelve lessons; the other eleven are in the Hopeling app, which is in testing. If you ran this with a class, we would like to hear what happened. <a href="${pilot}" style="font-weight:700;color:var(--fern)">Tell us, or ask about a pilot</a>.</p>
</section>
</main>

<footer class="barx">
  <button class="btn quiet" type="button" id="back">Back</button>
  <span class="hint">← and →, or a clicker</span>
  <button class="btn go" type="button" id="next">Begin: the show of hands</button>
</footer>

<script>window.BX=${JSON.stringify(BX)};${PREVIEW ? `window.__PREVIEW=${JSON.stringify(PREVIEW)};` : ''}</script>
<script>${read('brand/bench.js')}</script>
</body>
</html>
`;
const out = OUT || path.join(ROOT, 'bench', 'index.html');
fs.mkdirSync(path.dirname(out), { recursive: true });
fs.writeFileSync(out, html);
console.log(`bench: ${(html.length / 1024).toFixed(1)} KB -> ${out}${PREVIEW ? '  [preview ' + PREVIEW + ']' : ''}  | ${title}: ${options.map(o => o.label).join(' / ')}`);
