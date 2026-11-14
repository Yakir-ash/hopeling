// Hopeling: the little meadow. The film, as code.
//
// Every frame is an SVG drawn from the same creature library as the
// website (brand/creatures.cjs), rasterised by sharp and piped to ffmpeg.
// The Lab sequence is not an illustration of the model: it IS the model,
// the same equations and numbers as app/lib/data/lab.dart, sampled in time.
// The voice is the app's own storyteller, reading the Little Meadow's own
// lines (audio/manifest.json). Nothing on screen is a mock-up of a screen
// that does not exist; the product surfaces shown (the two benches, the
// class's show of hands, the errand, the eight-second card) are redrawn
// from the app's real content, not captured from a device. See README.md.

const path = require('path');
const ROOT = path.join(__dirname, '..');
const B = require(path.join(ROOT, 'brand', 'creatures.cjs'));
const { benchScene } = require(path.join(ROOT, 'brand', 'scenes.cjs'));
const { C, f } = B;

const W = 1920, H = 1080, FPS = 30;
const SERIF = 'TeX Gyre Pagella', SANS = 'Lato';

/* ---------------- small maths ---------------- */
const clamp = (v, a = 0, b = 1) => Math.max(a, Math.min(b, v));
const lerp = (a, b, t) => a + (b - a) * t;
const ease = t => { t = clamp(t); return t * t * (3 - 2 * t); };            // smoothstep
const easeOut = t => 1 - Math.pow(1 - clamp(t), 3);
const span = (t, a, b) => clamp((t - a) / (b - a));                          // 0..1 across [a,b]
const inout = (t, a, b, fade = 0.6) => Math.min(ease(span(t, a, a + fade)), 1 - ease(span(t, b - fade, b)));
const hex = h => [parseInt(h.slice(1, 3), 16), parseInt(h.slice(3, 5), 16), parseInt(h.slice(5, 7), 16)];
const mix = (a, b, t) => { const x = hex(a), y = hex(b); return '#' + x.map((v, i) => Math.round(lerp(v, y[i], clamp(t))).toString(16).padStart(2, '0')).join(''); };
const mix3 = (a, b, c, t) => t < 0.5 ? mix(a, b, t * 2) : mix(b, c, (t - 0.5) * 2);
let _s = 1; const srand = n => { _s = n; }; const rnd = () => (_s = (_s * 16807) % 2147483647) / 2147483647;
const escx = s => String(s).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');

/* ---------------- drawing helpers ---------------- */
function txt(s, x, y, o = {}) {
  const { size = 40, family = SERIF, style = 'normal', weight = 400, fill = C.ink, anchor = 'start', op = 1, ls = 0, dy = 0 } = o;
  if (op <= 0.005) return '';
  return `<text x="${f(x)}" y="${f(y + dy)}" font-family="${family}" font-size="${size}" font-style="${style}" font-weight="${weight}" fill="${fill}" text-anchor="${anchor}" opacity="${f(op)}"${ls ? ` letter-spacing="${ls}"` : ''}>${escx(s)}</text>`;
}
// a line of text that rises a little as it arrives and settles as it leaves
const line = (s, x, y, t, a, b, o = {}) => { const p = inout(t, a, b, o.fade || 0.7); return txt(s, x, y, { ...o, op: p * (o.op || 1), dy: (1 - ease(span(t, a, a + 0.9))) * 14 }); };
const rect = (x, y, w, h, fill, o = {}) => `<rect x="${f(x)}" y="${f(y)}" width="${f(w)}" height="${f(h)}" fill="${fill}"${o.rx ? ` rx="${o.rx}"` : ''}${o.op !== undefined ? ` opacity="${f(o.op)}"` : ''}${o.extra || ''}/>`;
const grp = (inner, o = {}) => `<g${o.t ? ` transform="${o.t}"` : ''}${o.op !== undefined ? ` opacity="${f(o.op)}"` : ''}${o.extra || ''}>${inner}</g>`;
const sky = (id, a, b, c) => `<defs><linearGradient id="${id}" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="${a}"/><stop offset=".5" stop-color="${b}"/><stop offset="1" stop-color="${c}"/></linearGradient></defs><rect width="${W}" height="${H}" fill="url(#${id})"/>`;
const vignette = `<defs><radialGradient id="vg" cx=".5" cy=".5" r=".75"><stop offset=".6" stop-color="#000" stop-opacity="0"/><stop offset="1" stop-color="#000" stop-opacity=".15"/></radialGradient></defs><rect width="${W}" height="${H}" fill="url(#vg)"/>`;
const leaf = (x, y, s, color) => `<g transform="translate(${f(x)},${f(y)}) scale(${f(s)})"><path d="M12 22C12 14 12 9 12 4M12 13C6 12 3 8 3 3C9 3 12 7 12 13ZM12 16C17 15 21 12 21 7C16 7 12 10 12 16Z" fill="none" stroke="${color}" stroke-width="2.1" stroke-linecap="round" stroke-linejoin="round"/></g>`;
// part of a quadratic curve, for threads that draw themselves
function thread(p0, p1, p2, prog, color, o = {}) {
  if (prog <= 0) return '';
  const n = Math.max(2, Math.round(40 * prog)), pts = [];
  for (let i = 0; i <= n; i++) { const u = (i / n) * prog, a = (1 - u) * (1 - u), b = 2 * (1 - u) * u, c = u * u; pts.push(`${f(a * p0[0] + b * p1[0] + c * p2[0])},${f(a * p0[1] + b * p1[1] + c * p2[1])}`); }
  const end = pts[pts.length - 1].split(',');
  return `<polyline points="${pts.join(' ')}" fill="none" stroke="#ffffff" stroke-width="${(o.w || 5) + 5}" stroke-linecap="round" opacity=".35"/>` +
    `<polyline points="${pts.join(' ')}" fill="none" stroke="${color}" stroke-width="${o.w || 5}" stroke-linecap="round" stroke-dasharray="${o.dash || '3 14'}"/>` +
    `<circle cx="${f(p0[0])}" cy="${f(p0[1])}" r="9" fill="${color}"/><circle cx="${end[0]}" cy="${end[1]}" r="${f(9 * prog)}" fill="${color}"/>`;
}

/* ---------------- the model (lab.dart, 'meadow') ---------------- */
const N = [{ id: 'f', init: 0.8, g: 0.05, s: 0 }, { id: 'r', init: 0.5, g: 0, s: -0.10 }, { id: 'x', init: 0.4, g: 0, s: -0.08 }];
const E = [['r', 'f', -0.15], ['f', 'r', 0.25], ['r', 'x', 0.20]];
function runOnce(dg, band, from, drag, steps) {
  let x = from ? from.slice() : N.map(n => n.init); const out = N.map(() => []);
  for (let s = 0; s < steps; s++) {
    N.forEach((n, i) => out[i].push(x[i])); const nx = x.slice();
    N.forEach((n, i) => {
      let g = n.g + band * (n.id === 'f' ? dg : 0); if (g > 0) g *= drag;
      let dx = g * x[i] * (1 - x[i]) + n.s * x[i];
      E.forEach(e => { if (e[1] === n.id) dx += band * e[2] * x[N.findIndex(k => k.id === e[0])] * x[i]; });
      nx[i] = Math.max(0.02, Math.min(1, x[i] + dx));
    }); x = nx;
  }
  return out;
}
const STAY = runOnce(0.25, 1, null, 1, 12), NONE = runOnce(0, 1, null, 1, 12), NONE_LO = runOnce(0, 0.8, null, 1, 12), NONE_HI = runOnce(0, 1.2, null, 1, 12);
const at = (run, t) => run.map(a => { const i = Math.floor(clamp(t, 0, a.length - 1)), j = Math.min(a.length - 1, i + 1); return lerp(a[i], a[j], clamp(t, 0, a.length - 1) - i); });

/* ---------------- the wide meadow ---------------- */
const H1 = [640, 46, 0.4], H2 = [745, 54, 2.1], H3 = [868, 34, 4.0];
const hy = (x, h) => B.hillY(x, W, h[0], h[1], h[2]);
srand(31);
const FLOWERS = Array.from({ length: 26 }, (_, i) => { const x = 50 + i * 73 + rnd() * 34; return { x, y: hy(x, H3) + 34 + rnd() * 120, s: 1.6 + rnd() * 0.9, petal: [C.cream, C.blush, '#ffffff'][i % 3], ph: rnd() * 6.28, order: rnd() }; }).sort((a, b) => a.y - b.y);
const TUFTS = Array.from({ length: 12 }, (_, i) => ({ x: 40 + i * 168 + rnd() * 50, y: 0, s: 1.9 })).map(t => ({ ...t, y: hy(t.x, H3) + 80 + rnd() * 90 }));
const STARS = Array.from({ length: 90 }, () => ({ x: rnd() * W, y: rnd() * 620, r: 0.9 + rnd() * 1.6, ph: rnd() * 6.28 }));
const BEES = [{ x: 420, y: 800, ph: 0.3 }, { x: 860, y: 842, ph: 2.1 }, { x: 1180, y: 818, ph: 4.0 }, { x: 1520, y: 858, ph: 5.2 }];
const PAL = {
  night: { sky: ['#07141D', '#0D2530', '#143437'], hills: ['#1B4142', '#153435', '#0E2627'] },
  dawn: { sky: ['#F4C79E', '#FAE4CB', '#FAF3E6'], hills: ['#B9CBA2', '#74A27E', '#3A7355'] },
  day: { sky: ['#BCDFE7', '#E3F0E9', '#F8F6EC'], hills: [C.sage, C.moss, C.fern] },
  dusk: { sky: ['#1B2643', '#575B8C', '#E4A583'], hills: ['#4E7B78', '#3E6B63', '#2C5450'] },
};
const pal = (a, b, t) => ({ sky: a.sky.map((c, i) => mix(c, b.sky[i], t)), hills: a.hills.map((c, i) => mix(c, b.hills[i], t)) });

/* o: { p (palette), sun:[x,y,r,color]|null, stars 0..1, bloom 0..1, flowers 0..1 (how many stand), bees 0..1,
        rabbits 0..1, fox 0..1, t (seconds, for sway), spots:[...], extra (svg drawn on the land) } */
function meadow(o) {
  const out = [], P = o.p, t = o.t || 0;
  // in a loop every motion is a whole number of turns, so the last frame meets the first
  const L = o.loop, osc = (k, ph, rate) => L === undefined ? Math.sin(t * rate + ph) : Math.sin(L * 2 * Math.PI * k + ph);
  out.push(sky('sk' + Math.round(t * 1000), ...P.sky));
  if (o.stars > 0.01) out.push(grp(STARS.map(s => `<circle cx="${f(s.x)}" cy="${f(s.y)}" r="${f(s.r)}" fill="#F4F1E6" opacity="${f(0.35 + 0.65 * (0.5 + 0.5 * Math.sin(t * 1.4 + s.ph)))}"/>`).join(''), { op: o.stars }));
  if (o.sun) out.push(`<circle cx="${f(o.sun[0])}" cy="${f(o.sun[1])}" r="${f(o.sun[2] * 2.5)}" fill="${o.sun[3]}" opacity=".14"/><circle cx="${f(o.sun[0])}" cy="${f(o.sun[1])}" r="${f(o.sun[2] * 1.7)}" fill="${o.sun[3]}" opacity=".2"/><circle cx="${f(o.sun[0])}" cy="${f(o.sun[1])}" r="${f(o.sun[2])}" fill="${o.sun[3]}"/>`);
  if (o.clouds > 0.01) out.push(grp(B.cloud({ x: 380 + t * 6, y: 250, s: 2.3 }) + B.cloud({ x: 1500 - t * 4, y: 180, s: 1.6 }), { op: o.clouds * 0.8 }));
  if (o.birds > 0.01) out.push(grp(B.bird({ x: 900 + t * 16, y: 330 - t * 3, s: 2, flap: Math.sin(t * 7) }) + B.bird({ x: 968 + t * 16, y: 300 - t * 3, s: 1.5, flap: Math.sin(t * 7 + 1.3) }), { op: o.birds }));
  out.push(B.hill(W, H, ...H1, P.hills[0], 16));
  out.push(B.tree({ x: 560, y: hy(560, H1) + 30, s: 1.9, leaf: [P.hills[2], P.hills[1], mix(P.hills[2], '#000000', 0.25)] }));
  out.push(B.tree({ x: 1660, y: hy(1660, H1) + 22, s: 1.1, leaf: [P.hills[2], P.hills[1], mix(P.hills[2], '#000000', 0.25)] }));
  out.push(B.hill(W, H, ...H2, P.hills[1], 16));
  if (o.fox > 0.01) out.push(B.fox({ x: 1290, y: hy(1290, H2) + 56, s: 2.35, op: o.fox }));
  if (o.rabbits > 0.01) {
    const hop = Math.abs(Math.sin(t * 2.2)) * (1 - ease(span(o.rabbits, 0.6, 1))) * 26;
    out.push(B.rabbit({ x: 700 - (1 - ease(o.rabbits)) * 260, y: hy(700, H2) + 66 - hop, s: 2.0, op: clamp(o.rabbits * 2), ear: osc(1, 0, 0.9) * 0.3 }));
    if (o.rabbits > 0.55) out.push(B.rabbit({ x: 1565, y: hy(1565, H2) + 60, s: 1.6, flip: true, op: span(o.rabbits, 0.55, 1), ear: 0.4 }));
  }
  out.push(B.hill(W, H, ...H3, P.hills[2], 16));
  TUFTS.forEach(q => out.push(B.tuft({ ...q, color: mix(P.hills[2], '#000000', 0.3) })));
  const stand = o.flowers === undefined ? 1 : o.flowers;
  FLOWERS.forEach(fl => {
    const here = clamp((stand - fl.order * 0.92) * 9);            // flowers leave and return one at a time
    if (here <= 0.01) return;
    const b = o.bloom === undefined ? 1 : ease(clamp((o.bloom - fl.order * 0.7) * 3.4));
    out.push(B.flower({ x: fl.x, y: fl.y, s: fl.s * (0.6 + 0.4 * here), petal: fl.petal, stem: mix(P.hills[2], '#ffffff', 0.5), bloom: b, rot: osc(2, fl.ph, 1.1) * 2.6, op: here }));
  });
  if (o.extra) out.push(o.extra);
  if (o.bees > 0.01) BEES.forEach((b, i) => {
    if (i / BEES.length >= o.bees + 0.01) return;
    const a = (L === undefined ? t * 0.8 : L * 2 * Math.PI) + b.ph, m = L === undefined ? [2.3, 1.3] : [2, 1];
    const bx = b.x + Math.sin(a) * 70 + Math.sin(a * m[0]) * 22, by = b.y + Math.cos(a * m[1]) * 34;
    out.push(B.bee({ x: bx, y: by, s: 2.3, flip: Math.cos(a) < 0, wing: 0.5 + 0.5 * Math.sin((L === undefined ? t * 60 : L * 2 * Math.PI * 96) + i), op: clamp((o.bees - i / BEES.length) * 4) }));
  });
  if (o.dark > 0.01) out.push(rect(0, 0, W, H, '#07141D', { op: o.dark }));
  return out.join('');
}
const POS = { flower: [868, 968], bee: [860, 842], rabbit: [712, 760], fox: [1300, 760] };

const cam = (z, cx, cy, inner) => `<g transform="translate(${f(cx)},${f(cy)}) scale(${f(z)}) translate(${f(-cx)},${f(-cy)})">${inner}</g>`;

/* ---------------- the scenes ---------------- */
// each scene: (t local seconds, cues) -> svg. Cues are the voice timings, so cuts of
// different length can share the scenes.

function sDawn(t, q) {
  const day = ease(span(t, 0.4, q.sunUp));                        // 0 night .. 1 morning
  const p = day < 0.55 ? pal(PAL.night, PAL.dawn, day / 0.55) : pal(PAL.dawn, PAL.day, (day - 0.55) / 0.45);
  const sunY = lerp(820, 300, easeOut(span(t, 1.2, q.sunUp + 2)));
  const th = t - q.threads;
  const web = th > 0 ? grp(
    thread(POS.flower, [800, 880], POS.bee, ease(span(th, 0, 1.3)), C.gold) +
    thread(POS.bee, [930, 900], [948, 960], ease(span(th, 1.6, 2.8)), C.gold) +
    thread([948, 960], [800, 880], POS.rabbit, ease(span(th, 3.0, 4.2)), C.gold) +
    thread(POS.rabbit, [1000, 640], POS.fox, ease(span(th, 3.9, 5.3)), C.gold),
    { op: 1 - ease(span(t, q.end - 1.2, q.end)) }) : '';
  return cam(lerp(1.07, 1.0, ease(span(t, 0, q.end))), 960, 760, meadow({ p, t, sun: [1400, sunY, 62, mix('#F0A24B', C.gold, day)], stars: 1 - ease(span(day, 0.15, 0.5)), clouds: ease(span(day, 0.6, 1)),
    birds: ease(span(t, q.sunUp - 1, q.sunUp + 1)), bloom: span(t, q.bloom, q.bloom + 4.2), bees: ease(span(t, q.bloom + 2.2, q.bloom + 5)), rabbits: span(t, q.bloom + 2.8, q.bloom + 6.5), fox: ease(span(t, q.bloom + 4.4, q.bloom + 6.4)),
    dark: (1 - ease(span(day, 0, 0.42))) * 0.34, extra: web }));
}

function sQuestion(t, q) {
  const p = PAL.day;
  return meadow({ p, t: t + 20, sun: [1400, 300, 62, C.gold], stars: 0, clouds: 1, birds: 0, bloom: 1, bees: 1, rabbits: 1, fox: 1, dark: 0 }) +
    rect(0, 0, W, H, '#F8F6EC', { op: 0.86 * ease(span(t, 0, 0.9)) }) +
    line('What if understanding the world', W / 2, 500, t, 0.5, q.end - 0.2, { size: 82, anchor: 'middle' }) +
    line('changed the way we care for it?', W / 2, 608, t, 1.3, q.end - 0.2, { size: 82, anchor: 'middle', style: 'italic', fill: C.fern });
}

function wordmark(t, o = {}) {
  const p = ease(span(t, 0, 1.1)), cx = W / 2, y = o.y || 560;
  return grp(leaf(cx - 372, y - 118, 5.4, o.color || C.ink) + txt('hopeling', cx - 222, y, { size: 190, weight: 700, fill: o.color || C.ink }), { op: p, t: `translate(0,${f((1 - p) * 16)})` });
}
function sMark(t, q) {
  return rect(0, 0, W, H, '#FAF8F2') + wordmark(t) + line('A companion for the living world', W / 2, 690, t, 1.0, q.end + 1, { size: 44, anchor: 'middle', family: SANS, fill: C.tx2, ls: 2 });
}

// one bench, drawn from the website's own bench scene with every sprite's presence set by the model
const BENCH = { a: benchScene('a').replace(/^<svg[^>]*>|<\/svg>$/g, ''), b: benchScene('b').replace(/^<svg[^>]*>|<\/svg>$/g, '') };
function bench(which, lv, bees, t) {
  let s = BENCH[which];
  const cnt = { fl: lv[0] * 16, rb: lv[1] * 6, fx: lv[2] * 3, be: bees };
  for (const k of ['fl', 'rb', 'fx', 'be']) { let i = 0; s = s.replace(new RegExp(`<g class="sp ${k}">`, 'g'), () => `<g opacity="${f(clamp(cnt[k] - i++ + 0.5))}">`); }
  let j = 0; s = s.replace(/<g class="drift( b)?"[^>]*>/g, () => { const a = t * 0.9 + (j++) * 1.7; return `<g transform="translate(${f(Math.sin(a) * 16)},${f(Math.cos(a * 1.4) * 8)})">`; });
  return s.replace('<g class="patch">', '<g opacity="0">');
}
const SERIES = [['Wildflowers', C.fern], ['Rabbits', C.gold], ['Foxes', C.rust]];
function sparks(prog, x0, y0, w, h, showEnds, lit = [0, 0, 0]) {
  const out = [], gw = (w - 2 * 40) / 3;
  SERIES.forEach((sr, i) => {
    const x = x0 + i * (gw + 40), X = k => x + 26 + (k / 11) * (gw - 52), Y = v => y0 + h - 30 - v * (h - 96);
    const n = Math.max(1, Math.floor(prog * 11)), fr = prog * 11 - n, pt = (run, k) => `${f(X(k))},${f(Y(run[i][k]))}`;
    const upto = run => { const a = []; for (let k = 0; k <= n && k <= 11; k++) a.push(pt(run, k)); if (n < 11) a.push(`${f(X(n + fr))},${f(Y(lerp(run[i][n], run[i][n + 1], fr)))}`); return a; };
    out.push(rect(x, y0, gw, h, '#ffffff', { rx: 26 }) + (lit[i] > 0.01 ? `<rect x="${f(x)}" y="${f(y0)}" width="${f(gw)}" height="${f(h)}" rx="26" fill="none" stroke="${sr[1]}" stroke-width="5" opacity="${f(lit[i])}"/>` : '') + txt(sr[0], x + 28, y0 + 50, { size: 30, family: SANS, weight: 700, fill: sr[1] }));
    out.push(`<polygon points="${upto(NONE_HI).concat(upto(NONE_LO).reverse()).join(' ')}" fill="${sr[1]}" opacity=".17"/>`);
    out.push(`<polyline points="${upto(STAY).join(' ')}" fill="none" stroke="${C.ink}" stroke-opacity=".42" stroke-width="4" stroke-dasharray="10 10"/>`);
    out.push(`<polyline points="${upto(NONE).join(' ')}" fill="none" stroke="${sr[1]}" stroke-width="6" stroke-linecap="round" stroke-linejoin="round"/>`);
    if (showEnds > 0.01) out.push(txt(`${Math.round(STAY[i][11] * 100)} with the bees, ${Math.round(NONE[i][11] * 100)} without`, x + gw - 28, y0 + 50, { size: 25, family: SANS, fill: C.tx2, anchor: 'end', op: showEnds }));
  });
  return out.join('');
}
function sLab(t, q) {
  const run = ease(span(t, q.run, q.runEnd)) * 11, show = ease(span(t, 0.2, 1.2));
  const bw = 880, bh = 440, x1 = 70, x2 = 970, y = 196, sc = bw / 600;
  const frame = (x, which, lv, bees, label, sub) => grp(
    `<defs><clipPath id="c${which}"><rect x="${x}" y="${y}" width="${bw}" height="${bh}" rx="34"/></clipPath><linearGradient id="g${which}" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#DCEDEA"/><stop offset=".62" stop-color="#F2F1E1"/></linearGradient></defs>` +
    grp(rect(x, y, bw, bh, `url(#g${which})`) + grp(bench(which, lv, bees, t), { t: `translate(${x},${y}) scale(${f(sc)})` }), { extra: ` clip-path="url(#c${which})"` }) +
    rect(x + 26, y + 24, 250 + sub.length * 13.5, 50, '#ffffff', { rx: 25, op: 0.9 }) + txt(label, x + 48, y + 58, { size: 22, family: SANS, weight: 700, ls: 3 }) + txt(sub, x + 176, y + 58, { size: 22, family: SANS, weight: 700, ls: 3, fill: C.fern }));
  const seasons = ['spring', 'summer', 'autumn', 'winter'], k = Math.round(run);
  return rect(0, 0, W, H, '#FAF8F2') +
    grp(txt('THE LAB', 70, 86, { size: 24, family: SANS, weight: 700, ls: 6, fill: C.fern }) +
      txt('Pull one thread,', 70, 152, { size: 64 }) + txt('and watch the web answer.', 548, 152, { size: 64, style: 'italic', fill: C.fern }) +
      frame(x1, 'a', at(STAY, run), 4, 'BENCH A', 'ALL THE BEES STAY') + frame(x2, 'b', at(NONE, run), lerp(4, 0, ease(span(t, q.run, q.run + 1.6))), 'BENCH B', 'NO BEES AT ALL') +
      rect(70, 668, 1500, 8, '#E4EAE5', { rx: 4 }) + rect(70, 668, 1500 * (run / 11), 8, C.fern, { rx: 4 }) +
      txt(`${seasons[k % 4]}, year ${Math.floor(k / 4) + 1}`, 1850, 680, { size: 26, family: SANS, weight: 700, fill: C.tx2, anchor: 'end' }) +
      grp(sparks(run / 11, 70, 716, 1780, 250, ease(span(t, q.runEnd, q.runEnd + 0.8)), (q.lit || []).map(w => inout(t, w[0], w[1], 0.5))), { op: ease(span(t, q.run - 0.4, q.run + 0.6)) }) +
      line('The real model from the Hopeling Lab, run three ways: cautious, best estimate, severe.', 70, 1024, t, q.run + 1, q.end + 2, { size: 26, family: SANS, fill: C.tx2 }),
      { op: show });
}

function card(x, y, w, h, inner, o = {}) {
  return grp(rect(x + 0, y + 14, w, h, '#0B3D4C', { rx: 40, op: 0.10 }) + rect(x, y, w, h, o.fill || '#ffffff', { rx: 40 }) + inner, { op: o.op === undefined ? 1 : o.op, t: `translate(0,${f(o.dy || 0)})` });
}
function sSchool(t, q) {
  const o = [rect(0, 0, W, H, '#FAF8F2')];
  const title = 1 - ease(span(t, q.cards - 0.3, q.cards + 0.6));
  o.push(grp(txt('HOPELING SCHOOL', W / 2, 400, { size: 24, family: SANS, weight: 700, ls: 6, fill: C.fern, anchor: 'middle', op: ease(span(t, 0.2, 1)) }) +
    line('Nothing is learned', W / 2, 520, t, 0.3, 99, { size: 120, anchor: 'middle' }) + line('until it is seen.', W / 2, 660, t, 0.9, 99, { size: 120, anchor: 'middle', style: 'italic', fill: C.fern }), { op: title }));
  const c = t - q.cards;
  if (c > 0) {
    const a1 = ease(span(c, 0.2, 1.0)), a2 = ease(span(c, 0.9, 1.7));
    o.push(txt('HOPELING SCHOOL', 110, 120, { size: 24, family: SANS, weight: 700, ls: 6, fill: C.fern, op: a1 }) + txt('Nothing is learned until it is seen.', 110, 190, { size: 60, op: a1 }));
    // the errand: today's one un-phoneable task
    o.push(card(110, 270, 760, 640, txt('THE ERRAND', 170, 356, { size: 22, family: SANS, weight: 700, ls: 5, fill: C.fern }) +
      txt('Stand still for two minutes', 170, 450, { size: 54 }) + txt('and count how many different', 170, 520, { size: 54 }) + txt('bird voices you can hear.', 170, 590, { size: 54 }) +
      txt('Names not required.', 170, 676, { size: 46, style: 'italic', fill: C.fern }) +
      B.bird({ x: 620, y: 800, s: 3.4, flap: Math.sin(t * 6) }) + B.bird({ x: 716, y: 770, s: 2.4, flap: Math.sin(t * 6 + 1) }) +
      txt('One thing a day that cannot be done on a phone.', 170, 852, { size: 26, family: SANS, fill: C.tx2 }), { op: a1, dy: (1 - a1) * 40 }));
    // the classroom bench: the show of hands
    const hands = [['higher', 6], ['lower', 17], ['about the same', 4]], gp = ease(span(c, 1.8, 4.4));
    o.push(card(930, 270, 880, 640, txt('THE CLASSROOM BENCH', 990, 356, { size: 22, family: SANS, weight: 700, ls: 5, fill: C.mint }) +
      txt('If the bees go,', 990, 446, { size: 62, fill: '#F4F1E6' }) + txt('who feels it last?', 990, 520, { size: 62, fill: '#F4F1E6', style: 'italic' }) +
      hands.map((hd, i) => { const yy = 606 + i * 78, n = Math.round(hd[1] * gp);
        return txt(hd[0], 990, yy + 30, { size: 30, family: SANS, fill: '#F4F1E6' }) + rect(1240, yy, 430, 40, '#ffffff', { rx: 20, op: 0.14 }) + rect(1240, yy, Math.max(40, 430 * (hd[1] / 17) * gp), 40, i === 1 ? C.mint : '#8FB8A0', { rx: 20 }) + txt(String(n), 1750, yy + 31, { size: 32, family: SANS, weight: 700, fill: '#F4F1E6', anchor: 'end' }); }).join('') +
      txt('The whole room predicts. Counted in public, never graded.', 990, 866, { size: 26, family: SANS, fill: '#B9CBC2' }), { op: a2, dy: (1 - a2) * 40, fill: C.fernDeep }));
  }
  return o.join('');
}

const SPOTS = [[0.12, 0.75], [0.30, 0.87], [0.50, 0.78], [0.68, 0.86], [0.84, 0.74], [0.42, 0.93]];
function sKids(t, q) {
  const warm = ease(span(t, q.grow, q.grow + 5));
  const p = pal(PAL.dusk, PAL.day, warm * 0.92);
  const planted = SPOTS.map((_, i) => ease(span(t, q.taps[i], q.taps[i] + 0.5)));
  const spots = SPOTS.map((sp, i) => {
    const x = sp[0] * W, y = 560 + sp[1] * 470, pulse = 1 + 0.08 * Math.sin(t * 3 + i), a = ease(span(t, q.spots, q.spots + 0.8)) * (1 - planted[i]);
    const ring = planted[i] > 0 && planted[i] < 1 ? `<circle cx="${f(x)}" cy="${f(y)}" r="${f(46 + planted[i] * 60)}" fill="none" stroke="${C.cream}" stroke-width="4" opacity="${f(1 - planted[i])}"/>` : '';
    return (a > 0.01 ? `<circle cx="${f(x)}" cy="${f(y)}" r="${f(44 * pulse)}" fill="${C.cream}" fill-opacity=".2" stroke="${C.cream}" stroke-width="4" stroke-dasharray="10 10" opacity="${f(a)}"/>` : '') + ring +
      (planted[i] > 0.01 ? B.sprout({ x, y: y + 12, s: 3.6 * easeOut(planted[i]), op: 1 - ease(span(t, q.grow + 1.5, q.grow + 3)) }) : '');
  }).join('');
  const g = span(t, q.grow, q.grow + 5.5);
  return meadow({ p, t: t + 40, sun: [1400, lerp(520, 330, warm), 62, mix('#F8D9A0', C.gold, warm)], stars: (1 - warm) * 0.9, clouds: warm, birds: 0,
    bloom: 1, flowers: lerp(0.3, 1, ease(g)), bees: ease(span(g, 0.35, 0.9)), rabbits: 0.5 + 0.5 * ease(span(g, 0.3, 0.8)), fox: ease(span(g, 0.5, 0.9)), dark: (1 - warm) * 0.16, extra: spots }) +
    grp(txt('HOPELING KIDS', 110, 120, { size: 24, family: SANS, weight: 700, ls: 6, fill: mix('#F3C987', C.fern, warm) }) +
      txt('A child can never end in the ruins.', 110, 196, { size: 64, fill: mix('#F6F1E4', C.ink, warm) }), { op: inout(t, 0.4, q.end + 1, 0.8) });
}

function sAct(t, q) {
  const o = [rect(0, 0, W, H, '#FAF8F2')], a = ease(span(t, 0.2, 1.1)), x = 1020, y = 150, press = span(t, q.press, q.press + 0.35);
  o.push(txt('ACT', 110, 380, { size: 24, family: SANS, weight: 700, ls: 6, fill: C.fern, op: a }));
  const d = t - q.press - 0.15;                                      // the decision is a drop, and the drop joins the rain
  if (d > 0) for (let i = 1; i < 22; i++) { const dd = d - 0.5 - i * 0.09; if (dd <= 0) continue; const py = lerp(-40, 1140, Math.pow(span(dd, 0, 1.5), 1.6)); if (py < 1120) o.push(B.drop({ x: 60 + ((i * 397) % 1800), y: py, s: 1.7 + (i % 3) * 0.4, op: 0.32 })); }
  o.push(line('Knowledge that ends', 110, 506, t, 0.3, 99, { size: 86 }) + line('in a decision.', 110, 610, t, 0.8, 99, { size: 86, style: 'italic', fill: C.fern }));
  o.push(line('One thing to avoid, one to prefer, one pick,', 110, 712, t, 1.6, 99, { size: 34, family: SANS, fill: C.tx2 }) + line('and the neighbour it reaches.', 110, 762, t, 1.8, 99, { size: 34, family: SANS, fill: C.tx2 }));
  const row = (yy, k, col, s1, s2, tt) => { const p = ease(span(t, tt, tt + 0.6)); return grp(rect(x + 56, yy - 46, 688, 2, '#16241C', { op: 0.1 }) + txt(k, x + 56, yy, { size: 20, family: SANS, weight: 700, ls: 4, fill: col }) + txt(s1, x + 210, yy + 4, { size: 36 }) + (s2 ? txt(s2, x + 210, yy + 48, { size: 36 }) : ''), { op: p }); };
  o.push(card(x, y, 800, 790,
    txt('THIS, NOT THAT', x + 56, y + 80, { size: 22, family: SANS, weight: 700, ls: 5, fill: C.fern }) +
    txt('Is what goes down your drain', x + 56, y + 150, { size: 46 }) + txt('river-safe?', x + 56, y + 206, { size: 46 }) +
    row(y + 300, 'AVOID', '#B05B5B', 'phosphates', '', 1.2) + row(y + 384, 'PREFER', C.fern, 'phosphate-free, printed', 'on the front', 1.9) + row(y + 520, 'PICK', C.ink, 'any detergent that says so', '', 2.6) +
    grp(rect(x + 56, y + 566, 688, 104, '#B2F1CC', { rx: 26, op: 0.4 }) + B.frog({ x: x + 116, y: y + 640, s: 2.3 }) + txt('The frog breathes through her skin,', x + 186, y + 612, { size: 27, family: SANS }) + txt('so the water is her air.', x + 186, y + 648, { size: 27, family: SANS }), { op: ease(span(t, 3.2, 3.9)) }) +
    grp(rect(x + 56, y + 694, 688, 66, mix(C.fern, '#0F2A1F', Math.sin(press * Math.PI)), { rx: 33 }) + txt('This one, from now on', x + 400, y + 738, { size: 30, family: SANS, weight: 700, fill: '#ffffff', anchor: 'middle' }), { op: ease(span(t, 3.6, 4.2)) }),
    { op: a, dy: (1 - a) * 40 }));
  if (d > 0 && d < 1.3) o.push(B.drop({ x: x + 400, y: lerp(y + 760, 1150, Math.pow(span(d, 0, 1.1), 1.8)), s: 3.6 }));
  return o.join('');
}

function sClose(t, q) {
  const end = ease(span(t, q.card, q.card + 1.6));
  return cam(lerp(1.0, 1.06, ease(span(t, 0, q.card + 3))), 960, 760, meadow({ p: PAL.day, t: t + 70, sun: [1400, 300, 62, C.gold], stars: 0, clouds: 1, birds: 1 - end, bloom: 1, flowers: 1, bees: 1, rabbits: 1, fox: 1, dark: 0 })) +
    rect(0, 0, W, H, '#F8F6EC', { op: 0.9 * end }) +
    (end > 0.01 ? grp(wordmark(t - q.card - 0.5, { y: 520 }) + line('small actions, real hope', W / 2, 640, t, q.card + 1.4, 999, { size: 62, anchor: 'middle', style: 'italic', fill: C.fern }) +
      line('hopeling.app', W / 2, 760, t, q.card + 2.0, 999, { size: 38, anchor: 'middle', family: SANS, weight: 700, ls: 3 }) +
      line('Narrated by Hopeling\'s storyteller, a synthetic voice. The meadow runs on the Lab\'s real model.', W / 2, 1010, t, q.card + 2.6, 999, { size: 22, anchor: 'middle', family: SANS, fill: C.tx2 })) : '');
}

/* ---------------- the cuts ---------------- */
const V = { meadow: 'This is the little meadow.', needs: 'The flowers feed the bees, the bees help the flowers, and everyone needs everyone.', flew: 'The bees flew away, and the flowers made fewer seeds.', quiet: 'Spring came up quieter.', less: 'The rabbits found less to eat.', fox: 'Even the fox felt it, all the way at the end of the line.', help: 'Can you help the meadow come back?', tap: 'Tap the soft ground and plant a wild patch.', look: 'Look - the flowers found the sun, and the bees found the flowers.', back: 'The meadow came back because someone helped.', helpers: 'Helpers change everything.' };

const MAIN = {
  name: 'hopeling-film', dur: 91,
  scenes: [
    { fn: sDawn, a: 0, b: 13.4, q: { sunUp: 4.2, bloom: 2.6, threads: 6.6, end: 13.4 } },
    { fn: sQuestion, a: 13.0, b: 18.9, q: { end: 5.9 } },
    { fn: sMark, a: 18.4, b: 22.6, q: { end: 4.2 } },
    { fn: sLab, a: 22.2, b: 45.4, q: { run: 3.2, runEnd: 20.6, end: 23.2, lit: [[3.4, 12.2], [12.6, 16.3], [16.4, 22.6]] } },
    { fn: sSchool, a: 45.0, b: 54.6, q: { cards: 3.3 } },
    { fn: sKids, a: 54.2, b: 70.0, q: { spots: 0.6, taps: [4.6, 5.3, 6.0, 6.7, 7.4, 8.1], grow: 8.7, end: 15.8 } },
    { fn: sAct, a: 69.6, b: 77.4, q: { press: 5.0 } },
    { fn: sClose, a: 77.0, b: 91, q: { card: 8.6 } },
  ],
  voice: [[2.6, V.meadow], [5.8, V.needs], [25.6, V.flew], [31.0, V.quiet], [34.9, V.less], [38.7, V.fox], [55.0, V.help], [58.3, V.tap], [63.0, V.look], [77.6, V.back], [82.0, V.helpers]],
  // sound cues for the score (film/score.py reads these)
  cues: { sunrise: 4.2, question: 13.4, mark: 18.6, lab: 22.4, loss: 25.6, school: 45.2, kids: 54.4, taps: [58.8, 59.5, 60.2, 60.9, 61.6, 62.3], grow: 62.9, act: 69.8, press: 74.6, close: 77.2, card: 85.6, end: 91 },
};
const SOCIAL = {
  name: 'hopeling-social', dur: 30.6,
  scenes: [
    { fn: sDawn, a: 0, b: 5.0, q: { sunUp: 1.8, bloom: 0.8, threads: 99, end: 5.0 } },
    { fn: sLab, a: 4.6, b: 18.1, q: { run: 1.4, runEnd: 11.6, end: 13.5, lit: [[1.8, 6.9], [0, 0], [7.2, 13.2]] } },
    { fn: sKids, a: 17.7, b: 25.5, q: { spots: 0.2, taps: [0.5, 0.8, 1.1, 1.4, 1.7, 2.0], grow: 2.3, end: 7.8 } },
    { fn: sClose, a: 25.1, b: 30.6, q: { card: 0.3 } },
  ],
  voice: [[1.5, V.meadow], [6.4, V.flew], [11.8, V.fox], [19.7, V.look], [25.9, V.helpers]],
  cues: { sunrise: 1.8, question: -1, mark: -1, lab: 4.8, loss: 6.4, school: -1, kids: 17.9, taps: [18.2, 18.5, 18.8, 19.1, 19.4, 19.7], grow: 20.0, act: -1, press: -1, close: 25.3, card: 25.4, end: 30.6 },
};
const LOOP = { name: 'hopeling-loop', dur: 12, scenes: [{ fn: (t) => meadow({ p: PAL.day, t: 0, loop: t / 12, sun: [1400, 300, 62, C.gold], stars: 0, clouds: 0, birds: 0, bloom: 1, flowers: 1, bees: 1, rabbits: 1, fox: 1, dark: 0 }), a: 0, b: 12, q: {} }], voice: [], cues: {} };

// the poster: the meadow in full day, with the line the whole site opens on
function poster(w = W, h = H) {
  const inner = rect(0, 0, W, H, PAL.day.sky[0]) +
    `<g transform="translate(0,150)">${meadow({ p: PAL.day, t: 3.3, sun: [1500, 250, 62, C.gold], stars: 0, clouds: 0, birds: 0, bloom: 1, flowers: 1, bees: 1, rabbits: 1, fox: 1, dark: 0 })}</g>` +
    leaf(108, 70, 3.1, C.ink) + txt('hopeling', 196, 134, { size: 78, weight: 700 }) +
    txt('Learn the living world.', 110, 300, { size: 100 }) + txt('Then do one small thing for it.', 110, 412, { size: 100, style: 'italic', fill: C.fern });
  return `<svg xmlns="http://www.w3.org/2000/svg" width="${w}" height="${h}" viewBox="0 0 ${W} ${H}" preserveAspectRatio="xMidYMid slice">${inner}</svg>`;
}

function frame(cut, t) {
  const live = cut.scenes.filter(s => t >= s.a && t < s.b);
  let svg = '';
  live.forEach((s, i) => {
    const inner = s.fn(t - s.a, s.q);
    svg += i === 0 ? inner : grp(inner, { op: ease(span(t, s.a, live[0].b)) });      // the incoming scene fades up over the outgoing one
  });
  const fadeIn = ease(span(t, 0, 1.2));
  return `<svg xmlns="http://www.w3.org/2000/svg" width="${W}" height="${H}" viewBox="0 0 ${W} ${H}">${svg}${cut.name === 'hopeling-loop' ? '' : vignette}` +
    (cut.name !== 'hopeling-loop' && fadeIn < 1 ? rect(0, 0, W, H, '#07141D', { op: 1 - fadeIn }) : '') + `</svg>`;
}

module.exports = { W, H, FPS, MAIN, SOCIAL, LOOP, frame, poster, V, meadow, PAL, wordmark, txt, rect, leaf, line, C, SERIF, SANS };
