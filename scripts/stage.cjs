#!/usr/bin/env node
/* Hopeling staging tool.
   node scripts/stage.cjs sync     prod (hopeling-web/) -> staging/hopeling-web/, with staging markers
   node scripts/stage.cjs promote  staging -> prod, markers stripped
   Markers: STAGING badge + noindex in the html, isolated sw cache name, renamed manifest. */
const fs = require('fs');
const path = require('path');

const ROOT = path.join(__dirname, '..');
const PROD = path.join(ROOT, 'hopeling-web');
const STAGE = path.join(ROOT, 'staging', 'hopeling-web');

const BADGE = ' <span id="stagebadge" style="background:#E88D67;color:#fff;font:700 9px -apple-system,sans-serif;padding:3px 8px;border-radius:8px;vertical-align:2px;letter-spacing:1px">STAGE</span>';
const NOINDEX = '<meta name="robots" content="noindex"/>';

function copyDir(from, to) {
  fs.mkdirSync(to, { recursive: true });
  for (const f of fs.readdirSync(from)) {
    const a = path.join(from, f), b = path.join(to, f);
    if (fs.statSync(a).isDirectory()) copyDir(a, b);
    else fs.writeFileSync(b, fs.readFileSync(a));
  }
}
function edit(file, fn) {
  fs.writeFileSync(file, fn(fs.readFileSync(file, 'utf8')));
}

const mode = process.argv[2];
if (mode === 'sync') {
  copyDir(PROD, STAGE);
  edit(path.join(STAGE, 'Hopeling.html'), s => s
    .replace('<title>Hopeling</title>', '<title>Hopeling STAGING</title>' + NOINDEX)
    .replace('<h1>🌿 Hopeling</h1>', '<h1>🌿 Hopeling' + BADGE + '</h1>'));
  edit(path.join(STAGE, 'sw.js'), s => s.replace(/const CACHE = 'hopeling-/, "const CACHE = 'hopeling-stage-"));
  edit(path.join(STAGE, 'manifest.json'), s => {
    const m = JSON.parse(s);
    m.name = 'Hopeling (staging)'; m.short_name = 'HopStage';
    return JSON.stringify(m, null, 2);
  });
  console.log('staging synced from prod (markers applied)');
} else if (mode === 'promote') {
  copyDir(STAGE, PROD);
  edit(path.join(PROD, 'Hopeling.html'), s => s
    .replace('<title>Hopeling STAGING</title>' + NOINDEX, '<title>Hopeling</title>')
    .replace(BADGE, ''));
  edit(path.join(PROD, 'sw.js'), s => s.replace(/const CACHE = 'hopeling-stage-/, "const CACHE = 'hopeling-"));
  edit(path.join(PROD, 'manifest.json'), s => {
    const m = JSON.parse(s);
    m.name = 'Hopeling'; m.short_name = 'Hopeling';
    return JSON.stringify(m, null, 2);
  });
  console.log('staging promoted to prod (markers stripped)');
} else {
  console.log('usage: node scripts/stage.cjs sync|promote');
  process.exit(1);
}
