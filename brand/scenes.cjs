// Scenes shared by the homepage and the generated site pages.
const path = require('path');
const B = require(path.join(__dirname, 'creatures.cjs'));
const { C } = B;
const wrap = (cls, inner, extra = '') => `<g class="${cls}"${extra}>${inner}</g>`;
const LIGHT = '#8FCBA4';

// One bench of the meadow experiment: sixteen flower slots, six rabbits,
// three foxes, four bees. The page shows as many of each as the model says.
function benchScene(which, state) {
  const W = 600, H = 300, o = [];
  const far = [150, 13, which === 'a' ? 0.6 : 2.4], near = [196, 9, which === 'a' ? 3.1 : 5.0];
  const hy = (x, h) => B.hillY(x, W, h[0], h[1], h[2]);
  o.push(B.hill(W, H, ...far, C.sage));
  [[470, 0.92], [150, 0.86], [318, 0.8]].forEach(p => o.push(wrap('sp fx', B.fox({ x: p[0], y: hy(p[0], far) + 30, s: p[1], flip: p[0] > 300 }))));
  o.push(B.hill(W, H, ...near, C.moss));
  o.push(`<rect x="0" y="246" width="${W}" height="60" fill="${C.fern}"/>` + B.hill(W, H, 250, 6, 1.2, C.fern));
  [[92, 222], [520, 228], [268, 216], [352, 236], [436, 214], [182, 240]].forEach((p, i) => o.push(wrap('sp rb', B.rabbit({ x: p[0], y: p[1], s: 0.78, flip: i % 2 === 1 }))));
  if (which !== 'a') o.push(wrap('patch', `<rect x="372" y="246" width="212" height="48" rx="14" fill="none" stroke="${C.cream}" stroke-width="2" stroke-dasharray="6 6" opacity=".9"/>` +
    [392, 430, 468, 506, 544, 566].map((x, i) => B.flower({ x, y: 286 - (i % 2) * 8, s: 0.82, petal: C.blush, stem: LIGHT })).join('')));
  const fl = [];
  let seed = which === 'a' ? 11 : 23; const rnd = () => (seed = (seed * 16807) % 2147483647) / 2147483647;
  const xs = Array.from({ length: 16 }, (_, i) => 26 + i * 36 + rnd() * 16);
  // slot order is shuffled so thinning looks like a meadow thinning, not a row emptying
  const order = [7, 2, 12, 5, 14, 0, 9, 3, 11, 6, 15, 1, 8, 13, 4, 10];
  order.forEach((k, i) => fl.push(wrap('sp fl', B.flower({ x: xs[k], y: 262 + ((k * 7) % 5) * 7, s: 0.8 + ((k * 3) % 4) * 0.09, petal: [C.cream, '#fff', C.blush][k % 3], stem: LIGHT }))));
  o.push(fl.join(''));
  [[120, 190], [300, 176], [455, 196], [220, 208]].forEach((p, i) => o.push(wrap('sp be', wrap('drift' + (i % 2 ? ' b' : ''), B.bee({ x: p[0], y: p[1], s: 1.05, flip: i % 2 === 1 }), ` style="animation-delay:-${i * 2}s"`))));
  let svg = o.join('');
  if (state) {
    for (const k of ['fl', 'rb', 'fx', 'be']) {
      let i = 0; const n = state[k];
      svg = svg.replace(new RegExp(`class="sp ${k}"`, 'g'), () => (i++ < n ? `class="sp ${k}"` : `class="sp ${k} off"`));
    }
    if (state.patch) svg = svg.replace('class="patch"', 'class="patch on"');
  }
  return `<svg viewBox="0 0 ${W} ${H}" aria-hidden="true" focusable="false">${svg}</svg>`;
}


module.exports = { benchScene, wrap, LIGHT };
