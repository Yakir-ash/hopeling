#!/usr/bin/env node
// Hand-authored Lottie animations for the Hopeling Kids slots - vector
// keyframe animation in our exact palette, fully ours, no licenses.
// Written as a generator so every animation is tweakable by numbers.
// Usage: node scripts/lottie_gen.js   (writes app/assets/lottie/*.json)

const fs = require('fs');
const nodePath = require('path');
const OUT = nodePath.join(__dirname, '..', 'app', 'assets', 'lottie');

// palette (0..1 rgb)
const C = {
  fox: [0.878, 0.463, 0.180], // E0762E
  foxDark: [0.760, 0.365, 0.130],
  cream: [1.0, 0.976, 0.925], // FFF9EC
  ink: [0.275, 0.227, 0.271], // 463A45
  sun: [1.0, 0.878, 0.541], // FFE08A
  berry: [0.851, 0.761, 0.941], // D9C2F0
  sky: [0.741, 0.890, 1.0], // BDE3FF
  leaf: [0.710, 0.890, 0.608], // B5E39B
  coral: [1.0, 0.722, 0.620], // FFB89E
  moon: [0.965, 0.937, 0.757], // F6EFC1
  night: [0.102, 0.141, 0.259], // 1A2440
};

// ---------- tiny lottie helpers ----------
const st = k => ({ a: 0, k }); // static value
// animated value: [[t, value], ...] with smooth ease
function anim(frames) {
  const k = frames.map(([t, s], i) => {
    const f = { t, s: Array.isArray(s) ? s : [s] };
    if (i < frames.length - 1) {
      f.i = { x: [0.45], y: [1] };
      f.o = { x: [0.55], y: [0] };
    }
    return f;
  });
  return { a: 1, k };
}
const el = (x, y, w, h) => ({ ty: 'el', p: st([x, y]), s: st([w, h]) });
const fill = c => ({ ty: 'fl', c: st([...c, 1]), o: st(100) });
const path = (pts, closed = true) => ({
  ty: 'sh',
  ks: st({
    c: closed,
    v: pts,
    i: pts.map(() => [0, 0]),
    o: pts.map(() => [0, 0]),
  }),
});
const tr = (over = {}) => ({
  ty: 'tr', p: st([0, 0]), a: st([0, 0]), s: st([100, 100]),
  r: st(0), o: st(100), ...over,
});
const group = (name, items, transform = tr()) => ({
  ty: 'gr', nm: name, it: [...items, transform],
});
const layer = (ind, name, shapes, op, ks = {}) => ({
  ddd: 0, ind, ty: 4, nm: name, sr: 1,
  ks: {
    o: st(100), r: st(0), p: st([256, 256, 0]),
    a: st([0, 0, 0]), s: st([100, 100, 100]), ...ks,
  },
  ao: 0, shapes, ip: 0, op, st: 0,
});
const doc = (name, op, layers) => ({
  v: '5.7.4', fr: 60, ip: 0, op, w: 512, h: 512, nm: name,
  ddd: 0, assets: [], layers,
});

// ---------- guide_fox: breathe, blink, tail sway ----------
function guideFox() {
  const op = 180;
  const tail = group('tail', [
    path([[150, 120], [40, 60], [70, 160]]),
    fill(C.fox),
  ], tr({ a: st([150, 120]), r: anim([[0, -6], [90, 8], [180, -6]]) }));
  const tailTip = group('tailtip', [
    el(52, 78, 44, 40), fill(C.cream),
  ], tr({ a: st([150, 120]), r: anim([[0, -6], [90, 8], [180, -6]]) }));
  const body = group('body', [el(256, 330, 190, 150), fill(C.fox)]);
  const earL = group('earL', [
    path([[170, 120], [140, 30], [225, 90]]), fill(C.fox),
  ], tr({ a: st([180, 100]), r: anim([[0, 0], [40, -5], [70, 0], [180, 0]]) }));
  const earR = group('earR', [
    path([[342, 120], [372, 30], [287, 90]]), fill(C.fox),
  ], tr({ a: st([332, 100]), r: anim([[0, 0], [50, 5], [80, 0], [180, 0]]) }));
  const earLin = group('earLin', [path([[176, 108], [158, 55], [210, 92]]), fill(C.cream)]);
  const earRin = group('earRin', [path([[336, 108], [354, 55], [302, 92]]), fill(C.cream)]);
  const head = group('head', [el(256, 190, 210, 180), fill(C.fox)]);
  const cheekL = group('cheekL', [el(190, 225, 95, 85), fill(C.cream)]);
  const cheekR = group('cheekR', [el(322, 225, 95, 85), fill(C.cream)]);
  const nose = group('nose', [el(256, 232, 30, 22), fill(C.ink)]);
  // eyes blink twice per loop via vertical squash
  const blink = anim([
    [0, [100, 100]], [62, [100, 100]], [66, [100, 8]], [70, [100, 100]],
    [140, [100, 100]], [144, [100, 8]], [148, [100, 100]], [180, [100, 100]],
  ]);
  const eyeL = group('eyeL', [el(0, 0, 22, 26), fill(C.ink)],
      tr({ p: st([206, 180]), s: blink }));
  const eyeR = group('eyeR', [el(0, 0, 22, 26), fill(C.ink)],
      tr({ p: st([306, 180]), s: blink }));
  // gentle smile: a thin arc made of a squashed ellipse under the nose
  const smile = group('smile', [el(256, 254, 44, 10), fill(C.foxDark)]);

  return doc('guide_fox', op, [
    layer(1, 'fox', [
      tail, tailTip, body, earL, earR, earLin, earRin, head,
      cheekL, cheekR, smile, nose, eyeL, eyeR,
    ], op, {
      // the whole fox breathes
      s: anim([[0, [100, 100, 100]], [90, [103, 103, 100]], [180, [100, 100, 100]]]),
      a: st([256, 300, 0]), p: st([256, 300, 0]),
    }),
  ]);
}

// ---------- butterfly: wing flaps and a floating drift ----------
function butterfly() {
  const op = 90;
  const flapL = anim([[0, [100, 100]], [8, [25, 100]], [16, [100, 100]],
    [24, [25, 100]], [32, [100, 100]], [56, [100, 100]],
    [64, [25, 100]], [72, [100, 100]], [90, [100, 100]]]);
  const flapR = anim([[0, [-100, 100]], [8, [-25, 100]], [16, [-100, 100]],
    [24, [-25, 100]], [32, [-100, 100]], [56, [-100, 100]],
    [64, [-25, 100]], [72, [-100, 100]], [90, [-100, 100]]]);
  const wingL = group('wingL', [
    el(-72, -40, 120, 110), fill(C.berry),
  ], tr({ a: st([0, 0]), s: flapL }));
  const wingL2 = group('wingL2', [
    el(-58, 48, 90, 80), fill(C.sky),
  ], tr({ a: st([0, 0]), s: flapL }));
  const wingR = group('wingR', [
    el(-72, -40, 120, 110), fill(C.berry),
  ], tr({ a: st([0, 0]), s: flapR }));
  const wingR2 = group('wingR2', [
    el(-58, 48, 90, 80), fill(C.sky),
  ], tr({ a: st([0, 0]), s: flapR }));
  const bodyG = group('bfbody', [el(0, 6, 26, 120), fill(C.ink)]);
  const antL = group('antL', [path([[-4, -56], [-26, -96]], false),
    { ty: 'st', c: st([...C.ink, 1]), o: st(100), w: st(6), lc: 2, lj: 2 }]);
  const antR = group('antR', [path([[4, -56], [26, -96]], false),
    { ty: 'st', c: st([...C.ink, 1]), o: st(100), w: st(6), lc: 2, lj: 2 }]);

  return doc('butterfly', op, [
    layer(1, 'butterfly', [wingL, wingL2, wingR, wingR2, bodyG, antL, antR],
        op, {
      p: anim([[0, [256, 262, 0]], [45, [256, 244, 0]], [90, [256, 262, 0]]]),
      r: anim([[0, -4], [45, 4], [90, -4]]),
    }),
  ]);
}

// ---------- sleepy_moon: a rocking crescent and floating Zs ----------
function sleepyMoon() {
  const op = 240;
  const moon = group('moon', [el(256, 256, 240, 240), fill(C.moon)]);
  const bite = group('bite', [el(310, 210, 200, 200), fill(C.night)]);
  const z = (x0, y0, delay, scale) => {
    const zPath = path(
        [[x0 - 18 * scale, y0 - 14 * scale], [x0 + 18 * scale, y0 - 14 * scale],
         [x0 - 18 * scale, y0 + 14 * scale], [x0 + 18 * scale, y0 + 14 * scale]],
        false);
    const rise = anim([[delay, [0, 0]], [delay + 10, [0, -20]],
      [delay + 80, [0, -90]], [op, [0, -90]]]);
    const fade = anim([[0, 0], [delay, 0], [delay + 12, 100],
      [delay + 70, 100], [delay + 85, 0], [op, 0]]);
    return group('z' + delay, [
      zPath,
      { ty: 'st', c: st([...C.moon, 1]), o: st(100), w: st(9 * scale), lc: 2, lj: 2 },
    ], tr({ p: rise, o: fade }));
  };
  return doc('sleepy_moon', op, [
    layer(1, 'zs', [z(350, 130, 20, 1.0), z(395, 95, 110, 0.7)], op),
    layer(2, 'moonface', [moon, bite], op, {
      a: st([256, 256, 0]), p: st([256, 276, 0]),
      r: anim([[0, -6], [120, 6], [240, -6]]),
    }),
  ]);
}

// ---------- celebrate: petals burst outward, once ----------
function celebrate() {
  const op = 75;
  const layers = [];
  const cols = [C.coral, C.sun, C.berry, C.leaf, C.sky, C.coral, C.sun, C.berry];
  for (let i = 0; i < 8; i++) {
    const a = (i * Math.PI * 2) / 8;
    const dist = 190;
    const petal = group('petal' + i, [el(0, 0, 46, 64), fill(cols[i])],
        tr({
          p: anim([[0, [0, 0]],
            [40, [Math.cos(a) * dist, Math.sin(a) * dist]],
            [op, [Math.cos(a) * (dist + 26), Math.sin(a) * (dist + 26)]]]),
          s: anim([[0, [0, 0]], [18, [110, 110]], [55, [90, 90]], [op, [0, 0]]]),
          r: st((a * 180) / Math.PI + 90),
        }));
    layers.push(petal);
  }
  const heart = group('heart', [el(0, 0, 70, 70), fill(C.sun)],
      tr({ s: anim([[0, [0, 0]], [14, [130, 130]], [30, [100, 100]], [60, [100, 100]], [op, [0, 0]]]) }));
  return doc('celebrate', op, [layer(1, 'burst', [...layers, heart], op)]);
}

// ---------- write ----------
fs.mkdirSync(OUT, { recursive: true });
const files = {
  'guide_fox.json': guideFox(),
  'butterfly.json': butterfly(),
  'sleepy_moon.json': sleepyMoon(),
  'celebrate.json': celebrate(),
};
for (const [name, d] of Object.entries(files)) {
  fs.writeFileSync(nodePath.join(OUT, name), JSON.stringify(d));
  console.log(name, JSON.stringify(d).length, 'bytes');
}
