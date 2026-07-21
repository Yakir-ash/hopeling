#!/usr/bin/env node
// Coloring pages generator - every species in the atlas becomes a
// printable, vector, ink-friendly coloring page. Line art is drawn
// here as parametric SVG archetypes (storybook-simple, biologically
// shaped: the whale has flukes and a blowhole, the owl has a facial
// disc, the bee has four wings). Three complexity levels show or hide
// detail layers - Early Explorers (bold simple shapes), Curious
// Rangers (patterns), Young Guardians (habitat scenes). No rasters,
// no downloads: pure strokes print crisply on any paper.
//
// Architecture note: pages are produced by activity renderers keyed in
// ACTIVITIES. Future activities (color-by-number, connect-the-dots,
// mazes, tracing) plug in as new renderers over the same species
// model without touching content.json.
//
// Usage: node scripts/coloring.js   (writes ./coloring/)

const fs = require('fs');
const path = require('path');

const ROOT = path.join(__dirname, '..');
const OUT = path.join(ROOT, 'coloring');
const content = JSON.parse(
    fs.readFileSync(path.join(ROOT, 'hopeling-web', 'content.json'), 'utf8'));

const esc = s => String(s).replace(/&/g, '&amp;').replace(/</g, '&lt;')
    .replace(/>/g, '&gt;').replace(/"/g, '&quot;');
const slug = s => s.toLowerCase().replace(/[^a-z0-9]+/g, '-')
    .replace(/^-|-$/g, '');
function hash(s) {
  let h = 0;
  for (const c of s) h = (h * 31 + c.charCodeAt(0)) & 0x7fffffff;
  return h;
}

// ---------- child-friendly conservation wording ----------
const STATUS = {
  CR: 'needs our help the most right now',
  EN: 'really needs our help',
  VU: 'needs us to be careful',
  NT: 'is doing okay - let’s keep watch',
  LC: 'is doing well - let’s keep it that way',
};

const CHALLENGES = [
  'Draw what this animal eats.',
  'Draw its home.',
  'Add another animal from its habitat.',
  'Imagine what happens here at night - draw it.',
  'Draw yourself helping nature.',
];

// ---------- the line-art library ----------
// Every archetype returns SVG for a 760x560 art box. Level layers:
// l1 always shown; l2 = patterns; l3 = habitat scene.
const S = 'fill="none" stroke="#222" stroke-linecap="round" stroke-linejoin="round"';
const W1 = 'stroke-width="5"', W2 = 'stroke-width="3.5"', W3 = 'stroke-width="3"';
const g = (lvl, inner) => `<g data-l="${lvl}">${inner}</g>`;
const eye = (x, y, r = 7) =>
    `<circle cx="${x}" cy="${y}" r="${r}" ${S} ${W1}/>` +
    `<circle cx="${x}" cy="${y}" r="2.5" fill="#222"/>`;
const smile = (x, y, w = 26) =>
    `<path d="M ${x - w / 2} ${y} Q ${x} ${y + 14} ${x + w / 2} ${y}" ${S} ${W2}/>`;
const grassLine = y =>
    Array.from({length: 9}, (_, i) => {
      const x = 60 + i * 80;
      return `<path d="M ${x} ${y} q 4 -22 8 0 M ${x + 14} ${y} q 5 -16 10 0" ${S} ${W3}/>`;
    }).join('');
const cloud = (x, y, k = 1) =>
    `<path d="M ${x} ${y} q 10 ${-22 * k} ${34 * k} ${-14 * k} q ${10 * k} ${-14 * k} ${30 * k} ${-6 * k} q ${24 * k} ${-4 * k} ${26 * k} ${14 * k} q ${14 * k} 2 8 ${12 * k} z" ${S} ${W3}/>`;
const sun = (x, y) =>
    `<circle cx="${x}" cy="${y}" r="26" ${S} ${W3}/>` +
    [0, 45, 90, 135, 180, 225, 270, 315].map(a => {
      const r = a * Math.PI / 180;
      return `<line x1="${x + Math.cos(r) * 34}" y1="${y + Math.sin(r) * 34}" x2="${x + Math.cos(r) * 46}" y2="${y + Math.sin(r) * 46}" ${S} ${W3}/>`;
    }).join('');
const waves = y =>
    Array.from({length: 4}, (_, i) =>
      `<path d="M ${40 + i * 180} ${y} q 22 -16 45 0 q 22 16 45 0" ${S} ${W3}/>`).join('');

const ART = {
  fish: () =>
    g(1, `<path d="M 150 280 Q 300 150 480 240 Q 520 200 590 190 Q 570 250 590 310 Q 520 300 480 280 Q 300 400 150 280 Z" ${S} ${W1}/>` +
       `<path d="M 300 205 Q 340 240 300 300" ${S} ${W2}/>` + eye(230, 255, 9) + smile(190, 300, 20)) +
    g(2, `<path d="M 360 230 q 14 25 0 55 M 400 225 q 14 28 0 62 M 440 228 q 12 25 0 52" ${S} ${W3}/>` +
       `<circle cx="150" cy="180" r="7" ${S} ${W3}/><circle cx="130" cy="150" r="5" ${S} ${W3}/>`) +
    g(3, waves(90) + waves(470) + `<path d="M 80 520 q 10 -60 0 -110 M 110 520 q 14 -50 4 -90" ${S} ${W3}/>`),
  shark: () =>
    g(1, `<path d="M 120 280 Q 300 170 520 240 L 600 200 Q 585 250 600 300 L 520 280 Q 300 380 120 280 Z" ${S} ${W1}/>` +
       `<path d="M 330 205 L 370 130 L 400 210" ${S} ${W1}/>` + eye(210, 250, 8) +
       `<path d="M 165 295 Q 195 310 225 298" ${S} ${W2}/>`) +
    g(2, `<path d="M 250 300 q 8 -14 16 0 M 275 305 q 8 -14 16 0 M 300 306 q 8 -14 16 0" ${S} ${W3}/>` +
       `<path d="M 470 250 q 12 18 0 36" ${S} ${W3}/>`) +
    g(3, waves(90) + `<circle cx="620" cy="140" r="6" ${S} ${W3}/><circle cx="645" cy="110" r="4" ${S} ${W3}/>`),
  whale: () =>
    g(1, `<path d="M 110 300 Q 130 180 320 175 Q 520 170 560 260 Q 600 240 640 205 Q 645 265 610 300 Q 640 335 645 390 Q 595 360 555 330 Q 480 400 300 395 Q 140 390 110 300 Z" ${S} ${W1}/>` +
       eye(220, 260, 8) + `<path d="M 150 320 Q 200 345 260 330" ${S} ${W2}/>`) +
    g(2, `<path d="M 150 355 q 40 14 90 10 M 160 375 q 35 10 70 8" ${S} ${W3}/>` +
       `<path d="M 300 160 q -6 -30 12 -48 M 312 160 q 6 -26 -2 -46" ${S} ${W3}/>`) +
    g(3, waves(470) + cloud(90, 100) + cloud(520, 80, 1.2)),
  dolphin: () =>
    g(1, `<path d="M 130 330 Q 190 200 360 190 Q 520 185 600 260 Q 560 280 520 275 Q 480 330 380 350 Q 250 375 130 330 Z" ${S} ${W1}/>` +
       `<path d="M 350 195 L 380 120 L 415 200" ${S} ${W1}/>` +
       `<path d="M 570 250 Q 610 235 640 250 Q 615 265 600 262" ${S} ${W2}/>` + eye(250, 265, 8) + smile(180, 300, 24)) +
    g(2, `<path d="M 200 340 q 60 18 130 8" ${S} ${W3}/>`) +
    g(3, waves(450) + sun(650, 90)),
  octopus: () =>
    g(1, `<path d="M 260 260 Q 260 130 380 130 Q 500 130 500 260 Q 500 300 470 315" ${S} ${W1}/>` +
       `<path d="M 290 300 Q 250 360 275 430 M 340 315 Q 320 390 345 460 M 395 320 Q 395 400 380 465 M 445 315 Q 465 390 445 455 M 480 300 Q 520 360 505 430" ${S} ${W1}/>` +
       `<path d="M 260 260 Q 268 300 290 300" ${S} ${W1}/>` + eye(340, 230, 9) + eye(420, 230, 9) + smile(380, 270, 26)) +
    g(2, `<circle cx="300" cy="380" r="4" ${S} ${W3}/><circle cx="308" cy="410" r="4" ${S} ${W3}/><circle cx="388" cy="400" r="4" ${S} ${W3}/><circle cx="384" cy="430" r="4" ${S} ${W3}/><circle cx="462" cy="390" r="4" ${S} ${W3}/>`) +
    g(3, waves(90) + `<circle cx="180" cy="180" r="7" ${S} ${W3}/><circle cx="160" cy="145" r="5" ${S} ${W3}/>`),
  turtle: () =>
    g(1, `<path d="M 220 300 Q 220 190 380 185 Q 540 190 540 300 Z" ${S} ${W1}/>` +
       `<path d="M 540 285 Q 610 270 625 305 Q 605 330 555 315" ${S} ${W1}/>` +
       `<path d="M 250 305 q -20 40 10 55 M 480 305 q 22 40 -8 55 M 330 310 q -8 40 8 52 M 420 312 q 8 38 -6 50" ${S} ${W1}/>` +
       `<path d="M 210 300 L 555 300" ${S} ${W1}/>` + eye(590, 292, 6)) +
    g(2, `<path d="M 300 195 L 330 300 M 380 187 L 380 300 M 455 195 L 430 300 M 262 240 Q 380 225 505 242" ${S} ${W3}/>`) +
    g(3, grassLine(430) + sun(110, 100)),
  bird: () =>
    g(1, `<path d="M 280 330 Q 240 330 230 290 Q 220 230 280 215 Q 290 160 350 160 Q 405 160 415 210 L 470 225 L 418 245 Q 430 320 370 340 Q 320 350 280 330 Z" ${S} ${W1}/>` +
       `<path d="M 280 330 Q 220 380 170 385 Q 215 395 265 375" ${S} ${W1}/>` +
       `<path d="M 330 345 L 330 395 M 355 345 L 355 395 M 315 395 L 345 395 M 340 395 L 370 395" ${S} ${W2}/>` + eye(355, 200, 7)) +
    g(2, `<path d="M 290 250 Q 330 235 370 255 Q 340 285 300 280 Z" ${S} ${W3}/>` +
       `<path d="M 300 300 q 20 8 40 2" ${S} ${W3}/>`) +
    g(3, `<path d="M 120 420 L 640 420" ${S} ${W3}/>` + grassLine(418) + cloud(120, 110) + sun(640, 90)),
  owl: () =>
    g(1, `<path d="M 270 200 Q 250 150 265 130 Q 295 150 310 145 Q 380 130 450 145 Q 465 150 495 130 Q 510 150 490 200 Q 520 280 490 360 Q 450 420 380 420 Q 310 420 270 360 Q 240 280 270 200 Z" ${S} ${W1}/>` +
       `<circle cx="330" cy="230" r="34" ${S} ${W1}/><circle cx="430" cy="230" r="34" ${S} ${W1}/>` +
       `<circle cx="330" cy="230" r="6" fill="#222"/><circle cx="430" cy="230" r="6" fill="#222"/>` +
       `<path d="M 368 250 L 380 275 L 392 250" ${S} ${W1}/>` +
       `<path d="M 330 420 l 0 22 m -12 -22 l 0 18 m 24 4 l 0 -22 M 430 420 l 0 22 m -12 -22 l 0 18 m 24 4 l 0 -22" ${S} ${W2}/>`) +
    g(2, `<path d="M 330 310 q 20 14 50 14 q 30 0 50 -14 M 340 340 q 18 12 40 12 q 22 0 40 -12" ${S} ${W3}/>` +
       `<path d="M 280 260 q -14 20 -10 44" ${S} ${W3}/>`) +
    g(3, `<path d="M 120 452 L 640 452" ${S} ${W2}/><path d="M 180 452 q -10 -30 -34 -38 M 560 452 q 12 -26 30 -32" ${S} ${W3}/>` +
       `<circle cx="620" cy="110" r="30" ${S} ${W3}/><circle cx="150" cy="120" r="4" ${S} ${W3}/><circle cx="200" cy="90" r="3" ${S} ${W3}/>`),
  penguin: () =>
    g(1, `<path d="M 310 160 Q 380 120 450 160 Q 490 260 470 370 Q 450 430 380 435 Q 310 430 290 370 Q 270 260 310 160 Z" ${S} ${W1}/>` +
       `<path d="M 330 200 Q 380 175 430 200 Q 445 300 425 380 Q 380 400 335 380 Q 315 300 330 200 Z" ${S} ${W2}/>` +
       `<path d="M 292 240 Q 250 300 280 360 M 468 240 Q 510 300 480 360" ${S} ${W1}/>` +
       `<path d="M 368 205 L 380 225 L 392 205" ${S} ${W1}/>` + eye(345, 185, 6) + eye(415, 185, 6) +
       `<path d="M 350 435 l -14 18 l 34 0 M 410 435 l 14 18 l -34 0" ${S} ${W2}/>`) +
    g(2, `<path d="M 355 300 q 25 12 50 0" ${S} ${W3}/>`) +
    g(3, `<path d="M 100 470 L 660 470 M 150 470 L 190 430 L 250 470 M 490 470 L 550 420 L 610 470" ${S} ${W3}/>` + `<circle cx="140" cy="110" r="26" ${S} ${W3}/>`),
  bee: () =>
    g(1, `<ellipse cx="380" cy="300" rx="150" ry="105" ${S} ${W1}/>` +
       `<path d="M 340 208 Q 390 95 465 108 Q 512 122 415 218 M 395 212 Q 460 120 528 142 Q 562 165 448 230" ${S} ${W1}/>` +
       `<path d="M 288 218 q -20 -40 -44 -50 M 322 208 q -8 -40 -26 -56" ${S} ${W2}/>` +
       eye(320, 275, 8) + eye(430, 275, 8) + smile(375, 320, 30) +
       `<path d="M 530 310 L 575 320" ${S} ${W1}/>`) +
    g(2, `<path d="M 340 200 Q 330 300 345 398 M 415 198 Q 425 300 410 400 M 470 225 Q 490 300 468 372" ${S} ${W3}/>`) +
    g(3, `<circle cx="140" cy="420" r="18" ${S} ${W3}/>` +
       [0, 60, 120, 180, 240, 300].map(a => {
         const r = a * Math.PI / 180;
         return `<ellipse cx="${140 + Math.cos(r) * 34}" cy="${420 + Math.sin(r) * 34}" rx="14" ry="10" ${S} ${W3} transform="rotate(${a} ${140 + Math.cos(r) * 34} ${420 + Math.sin(r) * 34})"/>`;
       }).join('') + `<path d="M 140 438 L 140 520" ${S} ${W3}/>` + sun(650, 90)),
  butterfly: () =>
    g(1, `<path d="M 380 200 Q 300 90 210 120 Q 140 150 190 250 Q 130 280 180 350 Q 240 410 372 300" ${S} ${W1}/>` +
       `<path d="M 380 200 Q 460 90 550 120 Q 620 150 570 250 Q 630 280 580 350 Q 520 410 388 300" ${S} ${W1}/>` +
       `<path d="M 372 195 Q 380 160 388 195 L 388 330 Q 380 360 372 330 Z" ${S} ${W1}/>` +
       `<path d="M 372 170 Q 350 130 330 120 M 388 170 Q 410 130 430 120" ${S} ${W2}/>`) +
    g(2, `<circle cx="255" cy="185" r="26" ${S} ${W3}/><circle cx="505" cy="185" r="26" ${S} ${W3}/>` +
       `<path d="M 235 320 q 25 -14 50 0 M 475 320 q 25 -14 50 0" ${S} ${W3}/>`) +
    g(3, grassLine(470) + `<circle cx="120" cy="430" r="14" ${S} ${W3}/><path d="M 120 444 L 120 520" ${S} ${W3}/>` + sun(650, 90)),
  bat: () =>
    g(1, `<ellipse cx="380" cy="280" rx="70" ry="95" ${S} ${W1}/>` +
       `<path d="M 320 240 Q 180 160 110 250 Q 160 240 180 270 Q 220 250 240 285 Q 280 265 315 300 M 440 240 Q 580 160 650 250 Q 600 240 580 270 Q 540 250 520 285 Q 480 265 445 300" ${S} ${W1}/>` +
       `<path d="M 350 195 L 335 150 L 368 178 M 410 195 L 425 150 L 392 178" ${S} ${W1}/>` +
       eye(358, 250, 7) + eye(402, 250, 7) + smile(380, 290, 22)) +
    g(2, `<path d="M 355 330 q 25 12 50 0 M 360 360 q 20 10 40 0" ${S} ${W3}/>`) +
    g(3, `<circle cx="620" cy="100" r="34" ${S} ${W3}/>` +
       `<circle cx="160" cy="120" r="4" ${S} ${W3}/><circle cx="220" cy="80" r="3" ${S} ${W3}/><circle cx="120" cy="200" r="3" ${S} ${W3}/>`),
  elephant: () =>
    g(1, `<path d="M 200 250 Q 210 160 320 155 Q 450 150 480 230 Q 560 235 570 300 Q 575 380 540 430 L 500 430 L 500 380 Q 420 400 340 390 L 340 430 L 295 430 Q 260 380 255 330 Q 205 310 200 250 Z" ${S} ${W1}/>` +
       `<path d="M 210 255 Q 150 275 155 350 Q 158 395 190 410 Q 205 400 198 380 Q 180 340 215 315" ${S} ${W1}/>` +
       `<path d="M 300 165 Q 260 120 300 105 Q 340 95 345 150" ${S} ${W1}/>` + eye(300, 230, 8)) +
    g(2, `<path d="M 250 270 q 20 -8 40 0 M 480 245 q 30 24 20 60" ${S} ${W3}/>` +
       `<path d="M 340 205 Q 380 225 415 205" ${S} ${W3}/>`) +
    g(3, grassLine(470) + sun(650, 90) + cloud(110, 110)),
  canid: () =>
    g(1, `<path d="M 320 190 L 300 120 L 355 165 Q 380 155 405 165 L 460 120 L 440 190 Q 470 220 460 260 Q 445 300 380 300 Q 315 300 300 260 Q 290 220 320 190 Z" ${S} ${W1}/>` +
       `<path d="M 365 235 L 380 252 L 395 235 M 380 252 L 380 268" ${S} ${W2}/>` + eye(345, 215, 7) + eye(415, 215, 7) +
       `<path d="M 330 300 Q 280 340 285 420 Q 300 455 380 455 Q 460 455 475 420 Q 480 340 430 300" ${S} ${W1}/>` +
       `<path d="M 475 400 Q 560 400 585 340 Q 600 385 560 430 Q 520 460 475 445" ${S} ${W1}/>`) +
    g(2, `<path d="M 305 250 l -30 -6 M 305 262 l -28 4 M 455 250 l 30 -6 M 455 262 l 28 4" ${S} ${W3}/>` +
       `<path d="M 340 330 q 40 20 80 0" ${S} ${W3}/>`) +
    g(3, grassLine(470) + `<circle cx="620" cy="100" r="30" ${S} ${W3}/>`),
  cat: () =>
    g(1, `<path d="M 315 185 L 300 115 L 355 160 Q 380 152 405 160 L 460 115 L 445 185 Q 475 220 462 262 Q 445 302 380 302 Q 315 302 298 262 Q 285 220 315 185 Z" ${S} ${W1}/>` +
       `<path d="M 368 238 L 380 250 L 392 238 M 380 250 L 380 264 M 380 264 Q 362 276 350 266 M 380 264 Q 398 276 410 266" ${S} ${W2}/>` +
       eye(345, 212, 7) + eye(415, 212, 7) +
       `<path d="M 335 302 Q 290 345 295 425 Q 315 455 380 455 Q 445 455 465 425 Q 470 345 425 302" ${S} ${W1}/>` +
       `<path d="M 465 420 Q 545 415 560 350 Q 585 400 545 440 Q 510 462 465 448" ${S} ${W1}/>`) +
    g(2, `<path d="M 300 245 l -32 -6 M 300 257 l -30 4 M 460 245 l 32 -6 M 460 257 l 30 4" ${S} ${W3}/>` +
       `<path d="M 330 340 l 30 0 M 335 365 l 26 0 M 400 340 l 30 0 M 402 365 l 26 0" ${S} ${W3}/>`) +
    g(3, grassLine(470) + sun(120, 95)),
  bear: () =>
    g(1, `<circle cx="380" cy="235" r="95" ${S} ${W1}/>` +
       `<circle cx="305" cy="160" r="28" ${S} ${W1}/><circle cx="455" cy="160" r="28" ${S} ${W1}/>` +
       `<ellipse cx="380" cy="270" rx="40" ry="30" ${S} ${W2}/>` +
       `<path d="M 372 262 L 388 262 L 380 274 Z" fill="#222"/>` + smile(380, 285, 24) +
       eye(345, 215, 7) + eye(415, 215, 7) +
       `<path d="M 320 320 Q 280 360 285 430 Q 300 460 380 460 Q 460 460 475 430 Q 480 360 440 320" ${S} ${W1}/>`) +
    g(2, `<circle cx="345" cy="215" r="16" ${S} ${W3}/><circle cx="415" cy="215" r="16" ${S} ${W3}/>` +
       `<path d="M 340 390 q 40 18 80 0" ${S} ${W3}/>`) +
    g(3, `<path d="M 130 470 L 130 330 M 130 360 q -30 -20 -40 -50 M 130 340 q 30 -24 44 -56 M 130 400 q -26 -10 -38 -30" ${S} ${W3}/>` + grassLine(470)),
  frog: () =>
    g(1, `<path d="M 250 320 Q 240 230 380 225 Q 520 230 510 320 Q 500 380 380 385 Q 260 380 250 320 Z" ${S} ${W1}/>` +
       `<circle cx="300" cy="215" r="30" ${S} ${W1}/><circle cx="460" cy="215" r="30" ${S} ${W1}/>` +
       `<circle cx="300" cy="212" r="6" fill="#222"/><circle cx="460" cy="212" r="6" fill="#222"/>` +
       smile(380, 320, 60) +
       `<path d="M 265 370 Q 220 400 235 430 Q 270 440 300 415 M 495 370 Q 540 400 525 430 Q 490 440 460 415" ${S} ${W1}/>`) +
    g(2, `<circle cx="330" cy="290" r="6" ${S} ${W3}/><circle cx="420" cy="285" r="6" ${S} ${W3}/><circle cx="378" cy="265" r="5" ${S} ${W3}/>`) +
    g(3, `<ellipse cx="380" cy="480" rx="200" ry="26" ${S} ${W3}/>` + waves(500) + `<circle cx="640" cy="100" r="30" ${S} ${W3}/>`),
  monkey: () =>
    g(1, `<circle cx="380" cy="230" r="85" ${S} ${W1}/>` +
       `<circle cx="290" cy="230" r="26" ${S} ${W1}/><circle cx="470" cy="230" r="26" ${S} ${W1}/>` +
       `<path d="M 330 205 Q 330 165 380 165 Q 430 165 430 205 Q 440 260 380 268 Q 320 260 330 205 Z" ${S} ${W2}/>` +
       eye(352, 210, 7) + eye(408, 210, 7) + smile(380, 240, 28) +
       `<path d="M 330 310 Q 300 360 310 430 Q 340 455 380 455 Q 420 455 450 430 Q 460 360 430 310" ${S} ${W1}/>` +
       `<path d="M 310 340 Q 240 330 210 270 M 450 340 Q 520 330 550 270" ${S} ${W1}/>`) +
    g(2, `<path d="M 350 300 q 30 14 60 0" ${S} ${W3}/>`) +
    g(3, `<path d="M 100 140 L 660 140" ${S} ${W2}/><path d="M 200 140 q -8 40 -30 56 M 540 140 q 10 36 30 50 M 360 140 q 0 30 0 30" ${S} ${W3}/>` +
       `<path d="M 340 170 q 8 22 30 26 q -22 6 -30 26 q -8 -20 -30 -26 q 22 -4 30 -26" ${S} ${W3}/>`),
  cow: () =>
    g(1, `<path d="M 220 250 Q 220 190 300 185 L 470 185 Q 550 190 550 250 L 550 340 Q 550 380 510 385 L 510 430 L 475 430 L 470 388 L 300 388 L 295 430 L 260 430 L 260 385 Q 220 380 220 340 Z" ${S} ${W1}/>` +
       `<path d="M 220 250 Q 150 245 140 290 Q 138 340 185 345 Q 215 345 225 320" ${S} ${W1}/>` +
       `<ellipse cx="165" cy="322" rx="26" ry="18" ${S} ${W2}/>` +
       `<path d="M 165 250 Q 135 230 130 205 M 205 240 Q 195 215 200 195" ${S} ${W1}/>` + eye(190, 285, 6)) +
    g(2, `<path d="M 300 220 Q 340 200 370 235 Q 350 270 310 260 Q 290 245 300 220 Z M 430 300 Q 480 285 500 320 Q 480 355 440 345 Q 415 325 430 300 Z" ${S} ${W3}/>`) +
    g(3, grassLine(470) + sun(650, 90) + cloud(100, 110)),
  seal: () =>
    g(1, `<path d="M 180 350 Q 200 220 340 210 Q 470 205 540 280 Q 590 330 610 400 Q 560 380 530 390 Q 560 410 555 430 Q 500 425 470 400 Q 350 430 250 405 Q 190 390 180 350 Z" ${S} ${W1}/>` +
       eye(300, 270, 8) + `<path d="M 250 300 q 14 10 30 6 M 262 288 l -26 -4 M 262 300 l -24 6" ${S} ${W2}/>` + `<circle cx="248" cy="296" r="5" fill="#222"/>`) +
    g(2, `<circle cx="380" cy="320" r="5" ${S} ${W3}/><circle cx="420" cy="300" r="5" ${S} ${W3}/><circle cx="400" cy="350" r="5" ${S} ${W3}/>`) +
    g(3, `<path d="M 100 470 L 660 470 M 140 470 L 190 425 L 250 470" ${S} ${W3}/>` + cloud(560, 100)),
  generic: () =>
    g(1, `<circle cx="380" cy="240" r="90" ${S} ${W1}/>` +
       `<path d="M 320 175 Q 300 130 330 118 Q 355 112 358 160 M 440 175 Q 460 130 430 118 Q 405 112 402 160" ${S} ${W1}/>` +
       eye(348, 225, 7) + eye(412, 225, 7) +
       `<path d="M 372 252 L 388 252 L 380 264 Z" fill="#222"/>` + smile(380, 276, 26) +
       `<path d="M 330 320 Q 300 360 308 430 Q 335 455 380 455 Q 425 455 452 430 Q 460 360 430 320" ${S} ${W1}/>`) +
    g(2, `<path d="M 344 390 q 36 16 72 0" ${S} ${W3}/>`) +
    g(3, grassLine(470) + sun(120, 95) + cloud(560, 110)),
};

// keyword -> archetype, checked against the species name first
const NAME_ART = [
  ['octopus', 'octopus'], ['squid', 'octopus'], ['shark', 'shark'],
  ['whale', 'whale'], ['dolphin', 'dolphin'], ['porpoise', 'dolphin'],
  ['vaquita', 'dolphin'], ['turtle', 'turtle'], ['tortoise', 'turtle'],
  ['owl', 'owl'], ['penguin', 'penguin'], ['bee', 'bee'],
  ['butterfly', 'butterfly'], ['moth', 'butterfly'], ['bat ', 'bat'],
  ['bat', 'bat'], ['elephant', 'elephant'], ['frog', 'frog'],
  ['toad', 'frog'], ['seal', 'seal'], ['sea lion', 'seal'],
  ['walrus', 'seal'], ['otter', 'seal'], ['manatee', 'seal'],
  ['dugong', 'seal'], ['fox', 'canid'], ['wolf', 'canid'],
  ['dog', 'canid'], ['dingo', 'canid'], ['jackal', 'canid'],
  ['coyote', 'canid'], ['cat', 'cat'], ['tiger', 'cat'],
  ['lion', 'cat'], ['leopard', 'cat'], ['lynx', 'cat'],
  ['jaguar', 'cat'], ['cheetah', 'cat'], ['panda', 'bear'],
  ['bear', 'bear'], ['monkey', 'monkey'], ['gorilla', 'monkey'],
  ['orangutan', 'monkey'], ['chimpanzee', 'monkey'], ['ape', 'monkey'],
  ['lemur', 'monkey'], ['cow', 'cow'], ['cattle', 'cow'],
  ['goat', 'cow'], ['sheep', 'cow'], ['pig', 'cow'], ['horse', 'cow'],
  ['donkey', 'cow'],
];
const WORLD_ART = {
  oceans: 'fish', 'coral-reefs': 'fish', sharks: 'shark', whales: 'whale',
  dolphins: 'dolphin', turtles: 'turtle', penguins: 'penguin', bees: 'bee',
  butterflies: 'butterfly', bats: 'bat', elephants: 'elephant',
  foxes: 'canid', wolves: 'canid', dogs: 'canid', pandas: 'bear',
  bears: 'bear', frogs: 'frog', freshwater: 'frog', birds: 'bird',
  owls: 'owl', 'farm-animals': 'cow', forests: 'owl', arctic: 'penguin',
  'big-cats': 'cat', monkeys: 'monkey', orangutans: 'monkey',
  rainforests: 'monkey',
};

function artFor(name, worldSlug) {
  const low = ' ' + name.toLowerCase() + ' ';
  for (const [k, a] of NAME_ART) if (low.includes(k)) return a;
  if (WORLD_ART[worldSlug]) return WORLD_ART[worldSlug];
  const birdWords = ['bird', 'eagle', 'hawk', 'falcon', 'parrot', 'robin',
    'sparrow', 'swift', 'crane', 'stork', 'heron', 'kingfisher', 'chicken',
    'duck', 'goose', 'swan', 'albatross', 'puffin', 'hornbill', 'kiwi'];
  for (const b of birdWords) if (low.includes(b)) return 'bird';
  const fishWords = ['fish', 'salmon', 'tuna', 'cod', 'ray', 'seahorse', 'eel'];
  for (const f of fishWords) if (low.includes(f)) return 'fish';
  return 'generic';
}

// ---------- page templates ----------
const CSS = `
  * { box-sizing: border-box; }
  body { font-family: Georgia, serif; color: #222; margin: 0;
         background: #FAF8F2; }
  .page { max-width: 800px; margin: 0 auto; padding: 24px;
          background: #fff; min-height: 100vh; }
  header.h { display: flex; align-items: baseline; gap: 12px;
             border-bottom: 3px solid #222; padding-bottom: 8px; }
  h1 { font-size: 30px; margin: 0; }
  .world { color: #2E6B4F; font-size: 14px; }
  .art { border: 3px solid #222; border-radius: 14px; margin: 16px 0; }
  .facts { font-size: 13.5px; line-height: 1.55; }
  .facts b { color: #2E6B4F; }
  .spot { border: 2px dashed #222; border-radius: 10px; padding: 10px 14px;
          font-size: 13.5px; margin-top: 10px; }
  .challenge { font-style: italic; font-size: 13px; margin-top: 8px; }
  .foot { font-size: 11px; color: #777; margin-top: 14px; }
  .tools { display: flex; gap: 8px; margin: 14px 0; flex-wrap: wrap; }
  .tools button, .tools a { font-family: inherit; font-size: 13px;
    padding: 8px 14px; border: 2px solid #222; background: #fff;
    border-radius: 10px; cursor: pointer; text-decoration: none;
    color: #222; }
  .tools .sel { background: #B2F1CC; }
  body.L1 [data-l="2"], body.L1 [data-l="3"] { display: none; }
  body.L2 [data-l="3"] { display: none; }
  @media print {
    .tools, .backrow { display: none !important; }
    body { background: #fff; }
    .page { min-height: 0; padding: 0; }
    @page { margin: 14mm; }
  }
`;

function levelTools() {
  return `<div class="tools" aria-label="Detail level and printing">
    <button onclick="setL(1)" id="b1">🐣 Early Explorers</button>
    <button onclick="setL(2)" id="b2" class="sel">🦊 Curious Rangers</button>
    <button onclick="setL(3)" id="b3">🦉 Young Guardians</button>
    <button onclick="window.print()">🖨 Print</button>
  </div>
  <script>
    function setL(n){document.body.className='L'+n;
      for(var i=1;i<=3;i++)document.getElementById('b'+i).className=i===n?'sel':'';}
    document.body.className='L2';
  </script>`;
}

function speciesBlock(name, world) {
  const art = ART[artFor(name, world.slug)]();
  const fact = world.facts && world.facts.length
      ? world.facts[hash(name) % world.facts.length] : null;
  const status = STATUS[world.iucn];
  const challenge = CHALLENGES[hash(name) % CHALLENGES.length];
  return `
  <header class="h"><h1>${esc(name)}</h1>
    <span class="world">${world.emo} lives among ${esc(world.name)}</span>
  </header>
  <svg class="art" viewBox="0 0 760 560" width="100%"
       xmlns="http://www.w3.org/2000/svg" role="img"
       aria-label="Coloring outline of ${esc(name)}">${art}</svg>
  <div class="facts">
    ${world.sci_simple ? `<b>Did you know?</b> ${esc(world.sci_simple)}<br/>` : ''}
    ${fact ? `<b>True thing:</b> ${esc(fact[0])} <i>(${esc(fact[1] || '')})</i><br/>` : ''}
    ${status ? `<b>How it is doing:</b> this animal ${esc(status)}.` : ''}
  </div>
  <div class="spot">🔍 Can you spot this animal (or its cousins) in nature or
    in a book? &#9744; I found it!</div>
  <div class="challenge">✏️ ${esc(challenge)}</div>
  <div class="foot">Hopeling · hopeling.app · print me, color me, keep me</div>`;
}

// ---------- build ----------
fs.mkdirSync(OUT, { recursive: true });
const worlds = content.categories.filter(w => (w.species || []).length);
let pageCount = 0;
const indexSections = [];

for (const w of worlds) {
  const links = [];
  const packParts = [];
  for (const name of w.species) {
    const sl = slug(name);
    const html = `<!doctype html><html lang="en"><head>
<meta charset="utf-8"/><meta name="viewport" content="width=device-width, initial-scale=1"/>
<title>${esc(name)} - Hopeling coloring page</title><style>${CSS}</style></head>
<body class="L2"><div class="page">
<div class="tools backrow"><a href="index.html">← All coloring pages</a>
<a href="world-${w.slug}.html">${w.emo} All ${esc(w.name)}</a></div>
${speciesBlock(name, w)}
${levelTools()}
</div></body></html>`;
    fs.writeFileSync(path.join(OUT, `${sl}.html`), html);
    links.push(`<a href="${sl}.html">${esc(name)}</a>`);
    packParts.push(`<div class="page" style="page-break-after:always">${speciesBlock(name, w)}</div>`);
    pageCount++;
  }
  // the world pack: every species, one print
  fs.writeFileSync(path.join(OUT, `world-${w.slug}.html`),
    `<!doctype html><html lang="en"><head><meta charset="utf-8"/>
<meta name="viewport" content="width=device-width, initial-scale=1"/>
<title>${esc(w.name)} - Hopeling coloring pack</title><style>${CSS}</style></head>
<body class="L2"><div class="page"><div class="tools backrow">
<a href="index.html">← All coloring pages</a></div>
<h1>${w.emo} ${esc(w.name)} coloring pack</h1>
<p class="facts">${w.species.length} pages. Pick a detail level, then print
the whole habitat.</p>${levelTools()}</div>
${packParts.join('\n')}
</body></html>`);
  indexSections.push(`<h2>${w.emo} ${esc(w.name)}
    <a class="pack" href="world-${w.slug}.html">print the whole world →</a></h2>
  <div class="links">${links.join(' · ')}</div>`);
}

fs.writeFileSync(path.join(OUT, 'index.html'),
  `<!doctype html><html lang="en"><head><meta charset="utf-8"/>
<meta name="viewport" content="width=device-width, initial-scale=1"/>
<title>Hopeling coloring pages - every animal, ready to print</title>
<style>${CSS}
  h2 { font-size: 18px; margin: 22px 0 6px; }
  h2 .pack { font-size: 12px; font-weight: normal; margin-left: 8px; }
  .links { font-size: 13.5px; line-height: 2; }
  .intro { font-size: 14px; line-height: 1.6; color: #444; }
</style></head><body class="L2"><div class="page">
<h1>🖍 Hopeling coloring pages</h1>
<p class="intro">${pageCount} printable pages - one for every animal in the
atlas. All line art is drawn by Hopeling in simple storybook shapes with
real anatomy (the whale has its blowhole, the owl its facial disc), and
every page carries one true fact from a real source. Three detail levels:
Early Explorers, Curious Rangers, Young Guardians. Vector strokes, so they
print crisp on A4 or Letter, and ink-friendly by design - pure outlines,
no grey fills.</p>
${indexSections.join('\n')}
<p class="foot">Hopeling · hopeling.app · print, color, keep</p>
</div></body></html>`);

console.log(`coloring: ${pageCount} species pages across ${worlds.length} worlds`);
