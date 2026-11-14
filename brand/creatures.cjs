// The Hopeling illustration language - one source for the website and
// the film. Paper-cut shapes, flat colour, no outlines, the Dawnlight
// palette. Every creature is drawn in its own small coordinate space
// with the origin where it touches the ground (or its centre, for the
// flyers), facing right. Callers place it with x, y, s (scale), flip.
//
// Used by: scripts/build-home.cjs (inlined into index.html),
//          film/render.cjs (rasterised frame by frame with sharp).

const C = {
  ink: '#16241C', fern: '#2E6B4F', fernDeep: '#1E4533', moss: '#5E9B79',
  sage: '#9CC5A8', mint: '#B2F1CC', gold: '#E8B04B', paper: '#FAF8F2',
  deep: '#0B3D4C', tx2: '#55645B', rust: '#C8683A', sand: '#E2CFB4',
  cream: '#FFF6E0', blush: '#F2B8A0', bark: '#6B4E3A', night: '#0E1F2B',
};

const f = n => (Math.round(n * 100) / 100).toString();
const place = (o, inner) => {
  const { x = 0, y = 0, s = 1, flip = false, rot = 0, op = 1, cls = '', id = '' } = o;
  const t = `translate(${f(x)},${f(y)})${rot ? ` rotate(${f(rot)})` : ''} scale(${f(flip ? -s : s)},${f(s)})`;
  return `<g${id ? ` id="${id}"` : ''}${cls ? ` class="${cls}"` : ''} transform="${t}"${op < 1 ? ` opacity="${f(op)}"` : ''}>${inner}</g>`;
};

// ---- flower: stem, one leaf, five petals. bloom 0..1 opens the head.
function flower(o = {}) {
  const { petal = C.cream, bloom = 1, stem = C.fern, heart = C.gold } = o;
  const head = bloom > 0.03
    ? `<g transform="translate(0,-48) scale(${f(bloom)})">${[0, 72, 144, 216, 288].map(a =>
        `<ellipse cx="0" cy="-9" rx="5.6" ry="9" fill="${petal}" transform="rotate(${a})"/>`).join('')}<circle r="5" fill="${heart}"/></g>`
    : `<circle cx="0" cy="-47" r="2.6" fill="${stem}"/>`;
  return place(o, `<path d="M0 0C-2-16 3-30 0-46" stroke="${stem}" stroke-width="2.6" fill="none" stroke-linecap="round"/><path d="M0-20C8-24 14-22 16-28C8-30 3-27 0-20Z" fill="${stem}"/>${head}`);
}

// ---- grass tuft
function tuft(o = {}) {
  const { color = C.fern } = o;
  return place(o, `<path d="M-7 0C-7-8-9-13-11-17M-2 0C-2-10-1-16 0-22M4 0C4-8 7-12 10-15" stroke="${color}" stroke-width="2.4" fill="none" stroke-linecap="round"/>`);
}

// ---- bee: origin at the body centre. wing 0..1 flaps.
function bee(o = {}) {
  const { wing = 0.5 } = o;
  const wy = 3.2 + 1.4 * wing;
  return place(o,
    `<ellipse cx="-3" cy="-8.5" rx="6.2" ry="${f(wy)}" fill="#fff" opacity=".86" transform="rotate(-24 -3 -8.5)"/>` +
    `<ellipse cx="3.5" cy="-9.5" rx="6.2" ry="${f(wy)}" fill="#fff" opacity=".7" transform="rotate(18 3.5 -9.5)"/>` +
    `<ellipse cx="0" cy="0" rx="9.2" ry="6.6" fill="${C.gold}"/>` +
    `<path d="M-3.2-5.6V5.6M1.8-6V6" stroke="${C.ink}" stroke-width="2.7" stroke-linecap="round"/>` +
    `<circle cx="8.6" cy="-.4" r="4.3" fill="${C.ink}"/>`);
}

// ---- rabbit, sitting. ear -1..1 tilts the ears.
function rabbit(o = {}) {
  const { fur = C.sand, ear = 0 } = o;
  const e1 = -12 + ear * 10, e2 = 8 + ear * 10;
  return place(o,
    `<circle cx="-17.5" cy="-12" r="4.6" fill="${C.cream}"/>` +
    `<ellipse cx="11" cy="-45" rx="3.7" ry="11.5" fill="${fur}" transform="rotate(${f(e1)} 12 -36)"/>` +
    `<ellipse cx="17" cy="-46" rx="3.7" ry="11.5" fill="${fur}" transform="rotate(${f(e2)} 16 -36)"/>` +
    `<ellipse cx="17" cy="-46" rx="1.7" ry="8" fill="${C.blush}" transform="rotate(${f(e2)} 16 -36)"/>` +
    `<ellipse cx="0" cy="-14" rx="17.5" ry="14" fill="${fur}"/>` +
    `<circle cx="15" cy="-28.5" r="9.6" fill="${fur}"/>` +
    `<ellipse cx="12" cy="-2.4" rx="5.4" ry="2.6" fill="${fur}"/>` +
    `<circle cx="18.6" cy="-30.4" r="1.5" fill="${C.ink}"/>` +
    `<circle cx="24" cy="-27.6" r="1.2" fill="${C.blush}"/>`);
}

// ---- fox, sitting, tail wrapped behind.
function fox(o = {}) {
  const { fur = C.rust } = o;
  return place(o,
    `<path d="M-8-3C-36 0-44-26-28-40C-27-25-18-15-6-12Z" fill="${fur}"/>` +
    `<path d="M-28-40C-37-35-41-27-39-19C-33-24-29-31-28-40Z" fill="${C.cream}"/>` +
    `<path d="M-11 0C-15-22-3-35 7-35C16-35 19-20 17 0Z" fill="${fur}"/>` +
    `<path d="M7-31C14-28 16-14 14 0H8C10-12 9-22 7-31Z" fill="${C.cream}"/>` +
    `<path d="M6-44L7.5-59L15.5-47.5Z" fill="${fur}"/><path d="M14-47.5L19.5-60L23.5-45.5Z" fill="${fur}"/>` +
    `<path d="M16.2-48.5L19.4-56L21.6-47Z" fill="${C.ink}" opacity=".55"/>` +
    `<path d="M3-37C3-47 10-51 17-49C23-47 27-42 34-38C27-33.500 20-31.500 13-31.500C7-31.500 3-33 3-37Z" fill="${fur}"/>` +
    `<path d="M12.5-31.600C20-31.600 27-33.600 34-38C27-36.600 20-35.800 14.5-36.400Z" fill="${C.cream}"/>` +
    `<circle cx="33.2" cy="-38" r="1.9" fill="${C.ink}"/><circle cx="20.4" cy="-41.6" r="1.5" fill="${C.ink}"/>`);
}

// ---- frog, facing the viewer.
function frog(o = {}) {
  const { skin = '#6FB58A' } = o;
  return place(o,
    `<ellipse cx="-15" cy="-4" rx="7.5" ry="4.2" fill="${skin}"/><ellipse cx="15" cy="-4" rx="7.5" ry="4.2" fill="${skin}"/>` +
    `<ellipse cx="0" cy="-9.500" rx="17" ry="10.5" fill="${skin}"/>` +
    `<ellipse cx="0" cy="-6" rx="10" ry="5.6" fill="${C.mint}" opacity=".7"/>` +
    `<circle cx="-8" cy="-18.500" r="5.6" fill="${skin}"/><circle cx="8" cy="-18.500" r="5.6" fill="${skin}"/>` +
    `<circle cx="-8" cy="-19" r="3" fill="#fff"/><circle cx="8" cy="-19" r="3" fill="#fff"/>` +
    `<circle cx="-7.500" cy="-19" r="1.6" fill="${C.ink}"/><circle cx="8.500" cy="-19" r="1.6" fill="${C.ink}"/>` +
    `<path d="M-7-10.500Q0-7 7-10.500" stroke="${C.fernDeep}" stroke-width="1.5" fill="none" stroke-linecap="round"/>`);
}

// ---- hedgehog, side on.
function hedgehog(o = {}) {
  const pts = [];
  for (let i = 0; i <= 14; i++) {
    const a = Math.PI * (1 - i / 14 * 0.9), r = i % 2 ? 20.5 : 15.5;
    pts.push(`${f(Math.cos(a) * r - 3)},${f(-Math.sin(a) * r * 0.86 - 2)}`);
  }
  return place(o,
    `<polygon points="-19,-1 ${pts.join(' ')} 12,-1" fill="${C.bark}"/>` +
    `<path d="M6-12C14-13 21-10 24.500-6C21-2 14-1 7-1Z" fill="#EAD9BF"/>` +
    `<circle cx="24.300" cy="-6" r="1.9" fill="${C.ink}"/><circle cx="15.500" cy="-8.600" r="1.4" fill="${C.ink}"/>` +
    `<ellipse cx="-9" cy="-.6" rx="4" ry="1.8" fill="#EAD9BF"/><ellipse cx="7" cy="-.6" rx="4" ry="1.8" fill="#EAD9BF"/>`);
}

// ---- a bird far off: two strokes. flap -1..1.
function bird(o = {}) {
  const { color = C.ink, flap = 0 } = o;
  const h = 6 + 3 * flap;
  return place(o, `<path d="M-10 0Q-5-${f(h)} 0 0Q5-${f(h)} 10 0" stroke="${color}" stroke-width="2" fill="none" stroke-linecap="round" stroke-linejoin="round"/>`);
}

// ---- the grove tree. grow 0..1 scales the canopy.
function tree(o = {}) {
  const { grow = 1, leaf = [C.fern, C.moss, C.fernDeep] } = o;
  const blobs = [[-26, -96, 30, 1], [24, -100, 32, 0], [0, -128, 34, 1], [-40, -66, 24, 2], [40, -70, 24, 2], [0, -84, 34, 0]];
  return place(o,
    `<path d="M-9 0C-6-26-5-50-3-74H4C6-50 7-26 11 0Z" fill="${C.bark}"/>` +
    `<path d="M0-52C8-58 16-60 22-70" stroke="${C.bark}" stroke-width="5" fill="none" stroke-linecap="round"/>` +
    `<g transform="translate(0,-84) scale(${f(grow)}) translate(0,84)">${blobs.map(b =>
      `<circle cx="${b[0]}" cy="${b[1]}" r="${b[2]}" fill="${leaf[b[3]]}"/>`).join('')}</g>`);
}

// ---- a cloud
function cloud(o = {}) {
  const { color = '#fff' } = o;
  return place(o, `<g fill="${color}"><ellipse cx="0" cy="0" rx="46" ry="13"/><circle cx="-16" cy="-9" r="15"/><circle cx="10" cy="-13" r="19"/><circle cx="30" cy="-4" r="11"/></g>`);
}

// ---- a seed, a sprout, a drop
const sprout = (o = {}) => place(o, `<path d="M0 0V-12" stroke="${C.fern}" stroke-width="2.4" stroke-linecap="round"/><path d="M0-12C-7-13-10-19-9-22C-3-21 0-17 0-12ZM0-12C6-13 10-18 9-22C3-21 0-17 0-12Z" fill="${C.moss}"/>`);
const drop = (o = {}) => place(o, `<path d="M0-12C5-5 7-2 7 2A7 7 0 0 1-7 2C-7-2-5-5 0-12Z" fill="${o.color || '#8CC7E8'}"/>`);

// ---- a hill: a filled band whose top is a sum of slow sines.
function hill(w, h, top, amp, phase, color, step = 12) {
  const p = [`M0 ${h}`];
  for (let x = 0; x <= w + step; x += step) {
    const y = top + amp * (Math.sin(x / w * 5.1 + phase) * 0.6 + Math.sin(x / w * 2.3 + phase * 1.7) * 0.4);
    p.push(`L${f(x)} ${f(y)}`);
  }
  p.push(`L${w} ${h}Z`);
  return `<path d="${p.join('')}" fill="${color}"/>`;
}
const hillY = (x, w, top, amp, phase) => top + amp * (Math.sin(x / w * 5.1 + phase) * 0.6 + Math.sin(x / w * 2.3 + phase * 1.7) * 0.4);

module.exports = { C, f, place, flower, tuft, bee, rabbit, fox, frog, hedgehog, bird, tree, cloud, sprout, drop, hill, hillY };
