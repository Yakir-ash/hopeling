#!/usr/bin/env node
/* Hopeling website generator.
   Reads hopeling-web/content.json and generates the public website:
   /today /wins /atlas /atlas/<world> /species/<name> /guardians /guardians/<id> /facts /facts/<n>
   plus site.css and sitemap.xml. Run: node scripts/build-site.mjs
   Runs in the same GitHub Action as the news bot, so the site regrows Mon+Thu automatically. */

import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const ROOT = path.join(path.dirname(fileURLToPath(import.meta.url)), '..');
const C = JSON.parse(fs.readFileSync(path.join(ROOT, 'hopeling-web', 'content.json'), 'utf8'));
const SITE = 'https://hopeling.app';
const APP = '/hopeling-web/Hopeling.html';

const slug = s => s.toLowerCase().replace(/['’.]/g, '').replace(/[^a-z0-9]+/g, '-').replace(/^-|-$/g, '');
const esc = s => String(s == null ? '' : s).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');
const IUCN = { CR: ['#B3261E', 'Critically Endangered', .92], EN: ['#D97706', 'Endangered', .74], VU: ['#CA8A04', 'Vulnerable', .56], NT: ['#65A30D', 'Near Threatened', .38], LC: ['#16A34A', 'Least Concern', .12] };
const catBySlug = {}; C.categories.forEach(k => catBySlug[k.slug] = k);
const written = [];

/* ---------- wikipedia bake ----------
   Fetches summaries + photos at build time. The GitHub Action has network, this sandbox may not;
   successes are cached in site-data/wiki-cache.json (committed), so every later build reuses them. */
const CACHE_FILE = path.join(ROOT, 'site-data', 'wiki-cache.json');
let WIKI = {};
try { WIKI = JSON.parse(fs.readFileSync(CACHE_FILE, 'utf8')); } catch {}
async function fetchSummary(title) {
  try {
    const ctl = new AbortController(); const t = setTimeout(() => ctl.abort(), 8000);
    const r = await fetch('https://en.wikipedia.org/api/rest_v1/page/summary/' + encodeURIComponent(title),
      { signal: ctl.signal, headers: { 'user-agent': 'HopelingSiteBuilder/1.0 (https://hopeling.app; contant.hopeling@gmail.com)' } });
    clearTimeout(t);
    if (!r.ok) return null;
    const j = await r.json();
    if (!j.extract) return null;
    let img = (j.thumbnail && j.thumbnail.source) || '';
    img = img.replace(/\/(\d+)px-/, '/800px-');
    return { x: j.extract, img };
  } catch { return null; }
}
const wantWiki = new Set();
C.categories.forEach(k => { (k.species || []).forEach(n => wantWiki.add(n)); if (k.wiki) wantWiki.add(k.wiki); });
(C.guardians || []).forEach(g => wantWiki.add(g.wiki || g.name));
const missing = [...wantWiki].filter(n => !WIKI[n]);
let fetched = 0;
for (let i = 0; i < missing.length; i += 8) {
  await Promise.all(missing.slice(i, i + 8).map(async n => {
    const r = await fetchSummary(n); if (r) { WIKI[n] = r; fetched++; }
  }));
}
if (fetched) { fs.mkdirSync(path.dirname(CACHE_FILE), { recursive: true }); fs.writeFileSync(CACHE_FILE, JSON.stringify(WIKI)); }
const catImg = cat => (cat && ((cat.wiki && WIKI[cat.wiki]) || WIKI[(cat.species || [])[0]] || null)) || null;

/* ---------- shared shell ---------- */

function shell({ title, desc, canon, body, hero, jsonld, extraJs = '', bodyClass = '' }) {
  return `<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8"/>
<meta name="viewport" content="width=device-width, initial-scale=1"/>
<title>${esc(title)}</title>
<meta name="description" content="${esc(desc)}"/>
<link rel="canonical" href="${SITE}${canon}"/>
<meta property="og:site_name" content="Hopeling"/>
<meta property="og:title" content="${esc(title)}"/>
<meta property="og:description" content="${esc(desc)}"/>
<meta property="og:url" content="${SITE}${canon}"/>
<meta property="og:image" content="${SITE}/hopeling-web/og-image.png"/>
<meta name="twitter:card" content="summary_large_image"/>
<link rel="icon" href="/hopeling-web/icon-192.png"/>
<link rel="stylesheet" href="/site.css"/>
${jsonld ? `<script type="application/ld+json">${JSON.stringify(jsonld)}</script>` : ''}
</head>
<body class="${bodyClass}">
<nav class="topnav" id="topnav">
  <a class="brand" href="/"><span class="branddot">•</span> hopeling</a>
  <div class="navlinks">
    ${[['Today', '/today/'], ['Atlas', '/atlas/'], ['Wins', '/wins/'], ['Facts', '/facts/'], ['Guardians', '/guardians/']].map(([n, u]) => {
    const here = canon.startsWith(u.slice(0, -1)) || (u === '/atlas/' && canon.startsWith('/species'));
    return `<a href="${u}"${here ? ' aria-current="page"' : ''}>${n}</a>`;
  }).join('')}
  </div>
  <a class="navbtn" href="${APP}">Open the app</a>
  <button class="menubtn" aria-label="Open menu" aria-expanded="false">☰</button>
</nav>
${hero || ''}
<main class="wrap">
${body}
</main>
<footer class="floor">
  <div class="wrap frow">
    <span class="fbrand"><span class="branddot">•</span> hopeling</span>
    <span class="fmoto">small actions, real hope</span>
  </div>
  <div class="wrap frow flinks">
    <a href="/today/">Today</a><a href="/atlas/">Atlas</a><a href="/wins/">Wins</a><a href="/facts/">Facts</a><a href="/guardians/">Guardians</a>
    <a href="/privacy.html">Privacy</a><a href="mailto:contant.hopeling@gmail.com">Contact</a><a href="${APP}">The app</a>
  </div>
  <div class="wrap frow fsmall">Made by one person and a growing forest of helpers. © ${new Date().getFullYear()} Hopeling.</div>
</footer>
<script>
(function(){
  var mb=document.querySelector('.menubtn');
  if(mb)mb.addEventListener('click',function(){
    var open=document.getElementById('topnav').classList.toggle('open');
    mb.setAttribute('aria-expanded',open?'true':'false');mb.textContent=open?'✕':'☰';
  });
  var h=new Date().getHours();
  var sky=h>=5&&h<9?'sky-dawn':h>=9&&h<17?'sky-day':h>=17&&h<20?'sky-dusk':'sky-night';
  var el=document.querySelector('.pagehero');if(el)el.classList.add(sky);
  var io=new IntersectionObserver(function(es){es.forEach(function(e){if(e.isIntersecting){e.target.classList.add('on');io.unobserve(e.target);}});},{threshold:.12});
  document.querySelectorAll('.rev').forEach(function(el){io.observe(el);});
  var host=document.querySelector('.pagehero .rain');
  if(host&&!matchMedia('(prefers-reduced-motion: reduce)').matches){
    setInterval(function(){if(document.hidden)return;
      var d=document.createElement('i');d.style.left=Math.random()*100+'%';
      d.style.animationDuration=(1.6+Math.random()*1.6)+'s';d.style.opacity=String(.25+Math.random()*.45);
      host.appendChild(d);setTimeout(function(){d.remove();},3600);},800);
  }
  ${extraJs}
})();
</script>
</body>
</html>`;
}

function hero({ kicker, h1, sub, rain, big }) {
  return `<header class="pagehero${big ? ' big' : ''}">
  <div class="stars"></div>${rain ? '<div class="rain"></div>' : ''}
  <div class="wrap">
    ${kicker ? `<div class="kicker">${kicker}</div>` : ''}
    <h1>${h1}</h1>
    ${sub ? `<p class="herosub">${sub}</p>` : ''}
  </div>
</header>`;
}

function page(rel, html) {
  const dir = path.join(ROOT, rel);
  fs.mkdirSync(dir, { recursive: true });
  fs.writeFileSync(path.join(dir, 'index.html'), html);
  written.push('/' + rel.replace(/\\/g, '/') + '/');
}

function iucnBar(code) {
  const i = IUCN[code]; if (!i) return '';
  return `<div class="iucnwrap"><div class="iucnbar"><span class="iucnmark" style="left:${i[2] * 100}%;background:${i[0]}"></span></div>
  <div class="iucnlbl"><span>Least Concern</span><span style="color:${i[0]};font-weight:800">${i[1]}</span><span>Extinct</span></div></div>`;
}

/* The institution speaks quietly about its companion (INSTITUTION.md rule 6). */
const appCta = (line) => `<p class="appline rev">${line || 'Hopeling is also a pocket companion: one fact, one small act a day.'} <a href="${APP}">Open the app</a></p>`;

/* ---------- site.css ---------- */

fs.writeFileSync(path.join(ROOT, 'site.css'), `/* Hopeling website - generated by scripts/build-site.mjs (Dawnlight system) */
:root{--ink:#16241C;--fern:#2E6B4F;--mint:#B2F1CC;--gold:#E8B04B;--paper:#FAF8F2;--deep:#0B3D4C;--tx2:#55645B;--serif:Georgia,'Iowan Old Style',Palatino,serif}
*{box-sizing:border-box;margin:0}
html{scroll-behavior:smooth}
body{font-family:-apple-system,BlinkMacSystemFont,"Segoe UI",Roboto,sans-serif;color:var(--ink);background:var(--paper)}
@media (prefers-reduced-motion:reduce){*{animation:none!important;transition:none!important}}
a{color:var(--fern)}
.wrap{max-width:980px;margin:0 auto;padding:0 24px}
.topnav{position:sticky;top:0;z-index:50;display:flex;align-items:center;gap:26px;padding:14px 28px;
  background:rgba(250,248,242,.82);backdrop-filter:blur(12px);-webkit-backdrop-filter:blur(12px);border-bottom:1px solid rgba(22,36,28,.07)}
.brand{font-family:var(--serif);font-size:21px;font-weight:700;color:var(--ink);text-decoration:none}
.branddot{color:var(--gold)}
.navlinks{display:flex;gap:22px;margin-left:8px}
.navlinks a{color:var(--ink);text-decoration:none;font-weight:600;font-size:15px;opacity:.82}
.navlinks a:hover{opacity:1;color:var(--fern)}
.navbtn{margin-left:auto;background:var(--fern);color:#F7F3E8;text-decoration:none;font-weight:700;padding:9px 20px;border-radius:12px;font-size:14px}
.navlinks a[aria-current]{opacity:1;color:var(--fern);box-shadow:0 2px 0 var(--mint)}
.menubtn{display:none;background:none;border:none;font-size:22px;color:var(--ink);cursor:pointer;padding:4px 8px}
:focus-visible{outline:3px solid var(--fern);outline-offset:2px;border-radius:4px}
.pagehero{position:relative;overflow:hidden;padding:88px 0 60px;text-align:left}
.pagehero.big{padding:130px 0 90px}
.pagehero.sky-dawn{background:linear-gradient(180deg,#ffeccb,#fdf8ec 70%,var(--paper))}
.pagehero.sky-day{background:linear-gradient(180deg,#dff2e8,#f4faf3 70%,var(--paper))}
.pagehero.sky-dusk{background:linear-gradient(180deg,#ffd9b3,#f9efe2 70%,var(--paper))}
.pagehero.sky-night{background:linear-gradient(180deg,#0d1b2b,#13251f 75%,#182019);color:#ECF3ED}
.pagehero.sky-night .herosub,.pagehero.sky-night .kicker{color:#A9BDAE}
.pagehero.sky-night .stars{opacity:1}
.stars{position:absolute;inset:0;opacity:0;pointer-events:none;background-image:radial-gradient(1.5px 1.5px at 18% 22%,rgba(255,255,255,.6),transparent),radial-gradient(1px 1px at 66% 14%,rgba(255,255,255,.5),transparent),radial-gradient(1.3px 1.3px at 42% 30%,rgba(255,255,255,.5),transparent),radial-gradient(1px 1px at 84% 34%,rgba(255,255,255,.4),transparent)}
.rain{position:absolute;inset:0;pointer-events:none;overflow:hidden}
.rain i{position:absolute;top:-24px;width:3px;height:19px;border-radius:3px;background:linear-gradient(180deg,transparent,rgba(74,178,120,.85));animation:fall linear forwards}
@keyframes fall{to{transform:translateY(60vh)}}
.kicker{font-size:12px;letter-spacing:2.5px;text-transform:uppercase;color:var(--fern);font-weight:800}
h1{font-family:var(--serif);font-weight:600;font-size:clamp(34px,4.5vw,58px);line-height:1.12;margin:12px 0 10px;letter-spacing:-.4px}
h2{font-family:var(--serif);font-weight:600;font-size:clamp(24px,3vw,34px);line-height:1.2;margin:0 0 14px}
.herosub{font-size:18px;line-height:1.6;color:var(--tx2);max-width:36em}
main.wrap{padding-top:44px;padding-bottom:80px}
section.block{margin-bottom:56px}
.rev{opacity:0;transform:translateY(20px);transition:opacity .7s ease,transform .7s ease}
.rev.on{opacity:1;transform:none}
.lead{font-size:17px;line-height:1.75;color:var(--tx2);max-width:42em}
.prose{font-size:17px;line-height:1.8;max-width:42em}
.prose p{margin-bottom:14px}
.card{background:#fff;border-radius:22px;padding:24px 26px;box-shadow:0 14px 34px -22px rgba(20,37,28,.35);margin-bottom:14px}
.plate{background:linear-gradient(125deg,var(--fern),var(--deep));color:#fff;border-radius:26px;padding:44px 40px;box-shadow:0 24px 60px -24px rgba(11,61,76,.5)}
.plate .k{font-size:11px;letter-spacing:2px;opacity:.85;font-weight:700}
.plate .f{font-family:var(--serif);font-style:italic;font-size:clamp(22px,2.6vw,30px);line-height:1.5;margin:16px 0}
.plate .simple{font-size:15px;opacity:.85;margin-top:6px;font-style:normal}
.grid{display:grid;grid-template-columns:repeat(auto-fill,minmax(280px,1fr));gap:16px}
.tile{background:#fff;border-radius:20px;padding:22px;box-shadow:0 12px 30px -20px rgba(20,37,28,.35);text-decoration:none;color:var(--ink);display:block;transition:transform .18s ease,box-shadow .18s ease}
.tile:hover{transform:translateY(-3px);box-shadow:0 18px 40px -20px rgba(20,37,28,.4)}
.tile .emo{font-size:34px}
.tile b{display:block;font-family:var(--serif);font-size:19px;margin:8px 0 4px}
.tile p{font-size:13.5px;color:var(--tx2);line-height:1.5}
.badge{display:inline-block;font-size:11px;font-weight:800;letter-spacing:.5px;padding:3px 10px;border-radius:99px;margin-top:10px}
.win{background:#fff;border-radius:18px;padding:18px 22px;box-shadow:0 10px 26px -18px rgba(20,37,28,.3);margin-bottom:12px;display:flex;gap:14px;align-items:flex-start}
.win .we{font-size:22px;line-height:1.3}
.win b{font-size:16px;line-height:1.45;display:block;font-weight:650}
.win a{color:inherit;text-decoration:none}
.win a:hover b{color:var(--fern)}
.win .wm{font-size:12.5px;color:var(--tx2);margin-top:5px}
.yeardiv{font-family:var(--serif);font-size:22px;color:var(--tx2);margin:34px 0 16px}
.iucnwrap{margin:18px 0 6px;max-width:520px}
.iucnbar{position:relative;height:10px;border-radius:99px;background:linear-gradient(90deg,#16A34A,#CA8A04,#D97706,#B3261E)}
.iucnmark{position:absolute;top:-4px;width:18px;height:18px;border-radius:50%;border:3px solid #fff;transform:translateX(-50%) scale(0);box-shadow:0 2px 8px rgba(0,0,0,.3);transition:transform .8s cubic-bezier(.2,1.4,.4,1) .4s}
.on .iucnmark,.pagehero .iucnmark{transform:translateX(-50%) scale(1)}
.iucnlbl{display:flex;justify-content:space-between;font-size:11.5px;color:var(--tx2);margin-top:8px;letter-spacing:.4px}
.chips{display:flex;flex-wrap:wrap;gap:10px;margin-top:12px}
.chip{background:#fff;border:1px solid rgba(46,107,79,.25);color:var(--ink);text-decoration:none;font-weight:600;font-size:14px;padding:8px 16px;border-radius:99px;transition:all .15s}
.chip:hover{background:var(--mint);border-color:var(--mint)}
.statgrid{display:grid;grid-template-columns:repeat(auto-fill,minmax(200px,1fr));gap:12px;margin:8px 0}
.stat{background:#fff;border-radius:16px;padding:16px 18px;box-shadow:0 10px 26px -18px rgba(20,37,28,.3)}
.stat b{font-family:var(--serif);font-size:20px;display:block}
.stat span{font-size:12.5px;color:var(--tx2)}
.fact-src{font-size:12px;color:var(--tx2);letter-spacing:1px;text-transform:uppercase}
.hopelist .card{border-left:4px solid var(--mint)}
.threatlist .card{border-left:4px solid #e3b8a5}
.card b.ct{font-size:16px;display:block;margin-bottom:6px}
.card p{font-size:14.5px;color:var(--tx2);line-height:1.6}
.appline{margin-top:56px;padding-top:18px;border-top:1px solid rgba(22,36,28,.09);font-size:14.5px;color:var(--tx2)}
.appline a{font-weight:700}
.pinwin{position:relative;border-radius:26px;overflow:hidden;background:linear-gradient(125deg,var(--fern),var(--deep));color:#fff;padding:44px 40px;margin-bottom:26px;box-shadow:0 24px 60px -24px rgba(11,61,76,.5)}
.pinwin .bg{position:absolute;inset:0;width:100%;height:100%;object-fit:cover;opacity:.35}
.pinwin>*{position:relative}
.pinwin .k{font-size:11px;letter-spacing:2px;opacity:.9;font-weight:700}
.pinwin .t{font-family:var(--serif);font-size:clamp(22px,2.6vw,30px);line-height:1.4;margin:14px 0 8px}
.pinwin .t a{color:#fff;text-decoration:none}
.pinwin .m{font-size:13px;opacity:.85}
.interstitial{font-family:var(--serif);font-size:clamp(20px,2.4vw,26px);text-align:center;margin:64px auto;color:var(--ink);max-width:24em}
.worldimg{width:100%;max-height:340px;object-fit:cover;border-radius:24px;margin:4px 0 26px;box-shadow:0 20px 50px -24px rgba(20,37,28,.45)}
.plate.photo .bg{position:absolute;inset:0;width:100%;height:100%;object-fit:cover;opacity:.38;border-radius:26px}
.plate.photo{position:relative;overflow:hidden}
.plate.photo>*:not(.bg){position:relative}
.imgcredit{font-size:10.5px;letter-spacing:.5px;color:var(--tx2);opacity:.8;margin-top:6px}
.btn{display:inline-block;background:var(--fern);color:#F7F3E8;text-decoration:none;font-weight:700;padding:13px 28px;border-radius:14px;font-size:15px;box-shadow:0 10px 26px -12px rgba(46,107,79,.5);transition:transform .15s}
.btn:hover{transform:translateY(-2px)}
.acthero{background:#fff;border-radius:22px;padding:28px;box-shadow:0 14px 34px -22px rgba(20,37,28,.35)}
.acthero .at{font-family:var(--serif);font-size:23px;margin-bottom:10px}
.acthero .why{font-style:italic;color:var(--tx2);font-size:15.5px;line-height:1.65;border-left:3px solid var(--mint);padding-left:14px;margin:12px 0}
.steps{margin:14px 0 0;padding-left:20px;font-size:15px;line-height:1.9;color:var(--ink)}
.meta-row{display:flex;gap:16px;flex-wrap:wrap;font-size:13px;color:var(--tx2);margin-top:12px}
.spimg{width:100%;max-width:640px;border-radius:22px;box-shadow:0 20px 50px -24px rgba(20,37,28,.45);display:none;margin:6px 0 18px}
.spsum{max-width:42em}
.floor{background:#101712;color:#9db0a2;padding:40px 0 34px;font-size:14px;margin-top:40px}
.frow{display:flex;gap:22px;align-items:center;flex-wrap:wrap;margin-bottom:14px}
.fbrand{font-family:var(--serif);font-size:19px;color:#ECF3ED;font-weight:700}
.fmoto{font-variant:small-caps;letter-spacing:2px}
.flinks a{color:#B2F1CC;text-decoration:none}
.fsmall{font-size:12.5px;opacity:.75}
.crumb{font-size:13.5px;margin-bottom:6px}
.crumb a{text-decoration:none;font-weight:600}
@media (max-width:760px){
  .navlinks{display:none}
  .menubtn{display:block}
  .topnav.open .navlinks{display:flex;flex-direction:column;position:absolute;top:100%;left:0;right:0;background:rgba(250,248,242,.98);padding:20px 24px;gap:18px;border-bottom:1px solid rgba(22,36,28,.09);box-shadow:0 20px 30px -20px rgba(20,37,28,.25)}
  .topnav{gap:12px;padding:12px 18px}
  .pagehero{padding:60px 0 44px}
  .plate{padding:32px 26px}
}
`);
written.push('/site.css');

/* ---------- /today ---------- */

const todayFacts = C.facts.map(f => [f[0], f[1], f[2], f[3] || '']);
const actKeys = Object.keys(C.actions);
const todayActs = actKeys.map(k => { const a = C.actions[k]; return { t: a.t, why: a.why, min: a.min, mod: a.mod, steps: (a.steps || []).slice(0, 4) }; });
/* Bake the build-day pick statically so crawlers see real content; JS re-picks only if the visitor's local date differs. */
const diNode = (len, salt, d) => { const x = d + salt; let h = 0; for (let i = 0; i < x.length; i++) h = (h * 31 + x.charCodeAt(i)) >>> 0; return h % len; };
const BUILD_DAY = new Date().toISOString().slice(0, 10);
const bf = todayFacts[diNode(todayFacts.length, 'f', BUILD_DAY)];
const ba = todayActs[diNode(todayActs.length, 'a', BUILD_DAY)];
const modLabel = m => m === 'home' ? '🏠 at home' : m === 'outdoor' ? '🌳 outdoors' : m === 'online' ? '💻 online' : '💚 giving';
page('today', shell({
  title: "Today at Hopeling - one fact, one small action",
  desc: "Every day: one wild fact worth repeating at dinner, and one small real action for the living world. It changes at midnight. No signup, ever.",
  canon: '/today/',
  bodyClass: 'today',
  hero: hero({ kicker: 'Changes at midnight, every night', h1: 'Today', sub: 'One fact worth repeating at dinner. One small action the living world will feel. The same today the app is holding, right now.', rain: true }),
  jsonld: { "@context": "https://schema.org", "@type": "WebPage", name: "Today at Hopeling", isPartOf: { "@type": "WebSite", name: "Hopeling", url: SITE } },
  body: `
<section class="block rev">
  <div class="kicker" id="tkick">TODAY'S FACT</div>
  <div class="plate" style="margin-top:14px">
    <div class="f" id="tf">${esc(bf[0])}</div>
    <div class="k" id="tfs">- ${esc(bf[1]).toUpperCase()}</div>
    <div class="simple" id="tfsimple">${bf[3] ? 'For young helpers: ' + esc(bf[3]) : ''}</div>
  </div>
</section>
<section class="block rev">
  <div class="kicker">TODAY'S ACTION</div>
  <div class="acthero" style="margin-top:14px">
    <div class="at" id="tat">${esc(ba.t)}</div>
    <div class="why" id="taw">${esc(ba.why)}</div>
    <ol class="steps" id="tas">${ba.steps.map(s => `<li>${esc(s)}</li>`).join('')}</ol>
    <div class="meta-row" id="tam"><span>~${ba.min} minutes</span><span>${modLabel(ba.mod)}</span></div>
  </div>
</section>
<p class="lead rev">Tomorrow this page will hold a different fact and a different action, chosen by the same quiet clock the app uses. Nothing repeats until the clock says so.</p>
<p class="lead rev" id="tnight" style="display:none;font-family:var(--serif);font-style:italic">The fact changes at midnight. You could be the first to see tomorrow.</p>
${appCta('Make today a streak.')}
`,
  extraJs: `
  var F=${JSON.stringify(todayFacts)},A=${JSON.stringify(todayActs)},BD=${JSON.stringify(BUILD_DAY)};
  function tdy(){var d=new Date();return d.getFullYear()+'-'+String(d.getMonth()+1).padStart(2,'0')+'-'+String(d.getDate()).padStart(2,'0');}
  function di(len,salt){var d=tdy()+salt,h=0;for(var i=0;i<d.length;i++){h=(h*31+d.charCodeAt(i))>>>0;}return h%len;}
  if(tdy()!==BD){
    var f=F[di(F.length,'f')];
    document.getElementById('tf').textContent=f[0];
    document.getElementById('tfs').textContent='- '+f[1].toUpperCase();
    document.getElementById('tfsimple').textContent=f[3]?'For young helpers: '+f[3]:'';
    var a=A[di(A.length,'a')];
    document.getElementById('tat').textContent=a.t;
    document.getElementById('taw').textContent=a.why;
    document.getElementById('tas').innerHTML=a.steps.map(function(s){return '<li>'+s.replace(/</g,'&lt;')+'</li>';}).join('');
    document.getElementById('tam').innerHTML='<span>~'+a.min+' minutes</span><span>'+(a.mod==='home'?'🏠 at home':a.mod==='outdoor'?'🌳 outdoors':a.mod==='online'?'💻 online':'💚 giving')+'</span>';
  }
  var dow=['SUNDAY','MONDAY','TUESDAY','WEDNESDAY','THURSDAY','FRIDAY','SATURDAY'][new Date().getDay()];
  document.getElementById('tkick').textContent=dow+" · TODAY'S FACT";
  if(h>=21||h<5)document.getElementById('tnight').style.display='block';
`
}));

/* ---------- /wins ---------- */

const allWins = [...(C.news || []).map(n => ({ d: n.d, t: n.t, src: n.src, url: n.url, tag: n.tag })), ...(C.wins || []).map(w => ({ d: w.d, t: w.t, src: w.src }))]
  .sort((a, b) => b.d.localeCompare(a.d));
/* The newest story is pinned large; the archive follows; a quiet truth interrupts the scroll. */
const pin = allWins[0];
const pinCat = pin && C.categories.find(k => k.emo === pin.tag);
const pinImgData = pinCat ? catImg(pinCat) : null;
let winsHtml = '';
if (pin) winsHtml += `<div class="pinwin rev">${pinImgData && pinImgData.img ? `<img class="bg" src="${esc(pinImgData.img)}" alt=""/>` : ''}
  <div class="k">THE NEWEST ENTRY · ${pin.d}</div>
  <div class="t">${pin.url ? `<a href="${esc(pin.url)}" rel="noopener">` : ''}${esc(pin.t)}${pin.url ? '</a>' : ''}</div>
  <div class="m">${pin.tag || '🌿'} · ${esc(pin.src)}</div>
</div>`;
let lastYear = '', wi = 0;
for (const w of allWins.slice(1)) {
  const y = w.d.slice(0, 4);
  if (y !== lastYear) { winsHtml += `<div class="yeardiv rev">${y}</div>`; lastYear = y; }
  const inner = `<span class="we">${w.tag || '🌿'}</span><span>${w.url ? `<a href="${esc(w.url)}" rel="noopener">` : ''}<b>${esc(w.t)}</b>${w.url ? '</a>' : ''}<span class="wm">${w.d} · ${esc(w.src)}</span></span>`;
  winsHtml += `<div class="win rev">${inner}</div>`;
  if (++wi === 20) winsHtml += `<p class="interstitial rev">Every one of these actually happened.</p>`;
}
if (wi < 20 && allWins.length > 3) winsHtml += `<p class="interstitial rev">Every one of these actually happened.</p>`;
page('wins', shell({
  title: "While The World Worried - a permanent archive of wildlife good news",
  desc: "Real, sourced good news about wildlife and the living planet, collected twice a week and never deleted. This archive only grows.",
  canon: '/wins/',
  hero: hero({ kicker: 'Updated every Monday and Thursday · nothing is ever deleted', h1: 'While the world worried,<br/>all of this went right.', sub: `Real, sourced good news about the living world. This archive has never deleted an entry. It only grows - currently ${allWins.length} stories, gathered while you were living your life.`, rain: true, big: true }),
  jsonld: { "@context": "https://schema.org", "@type": "CollectionPage", name: "While The World Worried", description: "A permanent archive of wildlife good news", url: SITE + '/wins/' },
  body: winsHtml + appCta('Good news finds you in the app.')
}));

/* ---------- species pages ---------- */

const speciesIndex = [];
for (const cat of C.categories) {
  for (const name of (cat.species || [])) {
    const s = slug(name);
    speciesIndex.push({ name, s, cat });
    const w = WIKI[name];
    page(path.join('species', s), shell({
      title: `${name} - facts, status and one thing you can do`,
      desc: `What is happening to the ${name.toLowerCase()}? Photo, conservation status and plain answers, and one real thing you can do for them today.`,
      canon: `/species/${s}/`,
      hero: hero({ kicker: `${cat.emo} From the world of ${esc(cat.name)}`, h1: esc(name), sub: '' }),
      jsonld: { "@context": "https://schema.org", "@type": "Article", headline: `${name}: status and how to help`, about: name, publisher: { "@type": "Organization", name: "Hopeling" } },
      body: `
<div class="crumb"><a href="/atlas/">Atlas</a> → <a href="/atlas/${cat.slug}/">${cat.emo} ${esc(cat.name)}</a></div>
${w && w.img ? `<img class="spimg" id="spimg" style="display:block" src="${esc(w.img)}" alt="${esc(name)}"/>` : `<img class="spimg" id="spimg" alt="${esc(name)}"/>`}
<div class="prose spsum rev" id="spsum"><p>${w ? esc(w.x) : esc(cat.sum)}</p></div>
<p class="fact-src" id="spsrc" style="margin-top:10px">${w ? 'PORTRAIT AND PHOTO VIA WIKIPEDIA, CC BY-SA' : ''}</p>
<section class="block" style="margin-top:36px">
  <h2 class="rev">Their world</h2>
  <p class="lead rev">${esc(cat.sum)}</p>
  ${cat.iucn ? `<div class="rev">${iucnBar(cat.iucn)}<p class="fact-src" style="margin-top:8px">Red List status of ${esc(cat.name.toLowerCase())} as a group</p></div>` : ''}
  <div class="chips rev"><a class="chip" href="/atlas/${cat.slug}/">${cat.emo} Explore the world of ${esc(cat.name)}</a></div>
</section>
${(cat.acts && cat.acts[0] && C.actions[cat.acts[0]]) ? `
<section class="block rev">
  <h2>One thing you can do for them today</h2>
  <div class="acthero">
    <div class="at">${esc(C.actions[cat.acts[0]].t)}</div>
    <div class="why">${esc(C.actions[cat.acts[0]].why)}</div>
  </div>
</section>` : ''}
${appCta(`Adopt a daily habit the ${esc(name.toLowerCase())} will feel.`)}
`,
      extraJs: w ? '' : `
  fetch('https://en.wikipedia.org/api/rest_v1/page/summary/'+encodeURIComponent(${JSON.stringify(name)}))
  .then(function(r){return r.json();}).then(function(j){
    if(j.extract){document.getElementById('spsum').innerHTML='<p>'+j.extract.replace(/</g,'&lt;')+'</p>';
      document.getElementById('spsrc').textContent='PORTRAIT VIA WIKIPEDIA, CC BY-SA';}
    if(j.thumbnail&&j.thumbnail.source){var im=document.getElementById('spimg');
      im.src=j.thumbnail.source.replace(/\\/(\\d+)px-/,'/800px-');im.style.display='block';}
  }).catch(function(){});
`
    }));
  }
}

/* ---------- world pages ---------- */

for (const cat of C.categories) {
  const sp = (cat.species || []).map(n => `<a class="chip" href="/species/${slug(n)}/">${esc(n)}</a>`).join('');
  const facts = (cat.facts || []).slice(0, 4).map(f => `<div class="card rev"><p style="font-family:var(--serif);font-style:italic;font-size:17px;color:var(--ink);line-height:1.6">${esc(f[0])}</p><p class="fact-src" style="margin-top:8px">- ${esc(f[1])}</p></div>`).join('');
  const threats = (cat.threats || []).map(t => `<div class="card rev"><b class="ct">${esc(t[0])}</b><p>${esc(t[1])}</p><p class="fact-src" style="margin-top:6px">${esc(t[2] || '')}</p></div>`).join('');
  const doing = (cat.doing || []).map(t => `<div class="card rev"><b class="ct">${esc(t[0])}</b><p>${esc(t[1])}</p></div>`).join('');
  const hope = (cat.hope || []).map(t => `<div class="card rev"><b class="ct">${esc(t[0])}</b><p>${esc(t[1])}</p></div>`).join('');
  const stats = (cat.stats || []).map(s => `<div class="stat rev"><b>${esc(s[1])}</b><span>${esc(s[0])}</span></div>`).join('');
  const acts = (cat.acts || []).filter(a => C.actions[a]).map(a => `<div class="acthero rev" style="margin-bottom:12px"><div class="at">${esc(C.actions[a].t)}</div><div class="why">${esc(C.actions[a].why)}</div><div class="meta-row"><span>~${C.actions[a].min} min</span></div></div>`).join('');
  const orgs = (cat.orgs || []).map(o => `<a class="chip" href="${esc(o[1])}" rel="noopener">${esc(o[0])} ↗</a>`).join('');
  page(path.join('atlas', cat.slug), shell({
    title: `${cat.name} - what is happening, what is working, and how to help`,
    desc: `${cat.sum} The honest picture: real threats with sources, what conservation is achieving, and small actions that help.`,
    canon: `/atlas/${cat.slug}/`,
    hero: hero({ kicker: `${cat.emo} A world in the atlas`, h1: esc(cat.name), sub: esc(cat.sum) }),
    jsonld: { "@context": "https://schema.org", "@type": "Article", headline: `${cat.name}: threats, hope and how to help`, publisher: { "@type": "Organization", name: "Hopeling" } },
    body: `
<div class="crumb"><a href="/atlas/">← The Atlas</a></div>
${(() => { const ci = catImg(cat); return ci && ci.img ? `<img class="worldimg rev" src="${esc(ci.img)}" alt="${esc(cat.name)}"/><p class="imgcredit">PHOTO VIA WIKIPEDIA, CC BY-SA</p>` : ''; })()}
${cat.iucn ? `<div class="rev">${iucnBar(cat.iucn)}</div>` : ''}
${cat.overview ? `<section class="block rev" style="margin-top:30px"><h2>The picture</h2><div class="prose"><p>${esc(cat.overview)}</p></div></section>` : ''}
${cat.science ? `<section class="block rev"><h2>The science</h2><div class="prose"><p>${esc(cat.science)}</p></div></section>` : ''}
${stats ? `<section class="block"><h2 class="rev">In numbers</h2><div class="statgrid">${stats}</div></section>` : ''}
${facts ? `<section class="block"><h2 class="rev">Worth repeating at dinner</h2>${facts}</section>` : ''}
${threats ? `<section class="block threatlist"><h2 class="rev">What they face</h2>${threats}</section>` : ''}
${doing ? `<section class="block hopelist"><h2 class="rev">What is already working</h2>${doing}</section>` : ''}
${hope ? `<section class="block hopelist"><h2 class="rev">Reasons for hope</h2>${hope}</section>` : ''}
${sp ? `<section class="block rev"><h2>Meet them</h2><div class="chips">${sp}</div></section>` : ''}
${acts ? `<section class="block"><h2 class="rev">Small actions that reach them</h2>${acts}</section>` : ''}
${orgs ? `<section class="block rev"><h2>People doing the big work</h2><div class="chips">${orgs}</div></section>` : ''}
${appCta()}
`
  }));
}

/* atlas index */
const worldTiles = C.categories.map(cat => {
  const i = IUCN[cat.iucn];
  return `<a class="tile rev" href="/atlas/${cat.slug}/"><span class="emo">${cat.emo}</span><b>${esc(cat.name)}</b><p>${esc(cat.sum)}</p>${i ? `<span class="badge" style="color:${i[0]};background:${i[0]}18">${i[1]}</span>` : ''}</a>`;
}).join('');
page('atlas', shell({
  title: "The Atlas - explore the living world, honestly",
  desc: `${C.categories.length} worlds of wildlife: real threats with sources, real progress, and in every single one, something you can do. An atlas that ends in agency.`,
  canon: '/atlas/',
  hero: hero({ kicker: `${C.categories.length} worlds · ${speciesIndex.length} portraits · every page ends in something you can do`, h1: 'The Atlas', sub: 'Most encyclopedias tell you what is dying. This one also tells you what is working, and hands you one thing to do before dinner.', big: true }),
  body: `<div class="grid">${worldTiles}</div>${appCta()}`
}));

/* ---------- guardians ---------- */

for (const g of (C.guardians || [])) {
  page(path.join('guardians', g.id), shell({
    title: `${g.name} - ${g.count}. Someone should know their name.`,
    desc: `${g.story.slice(0, 150)}...`,
    canon: `/guardians/${g.id}/`,
    hero: hero({ kicker: `${g.emo} One of the rarest lives on Earth`, h1: esc(g.name), sub: `<i>${esc(g.sci)}</i> · ${esc(g.count)}`, big: true }),
    jsonld: { "@context": "https://schema.org", "@type": "Article", headline: `${g.name}: ${g.count}`, publisher: { "@type": "Organization", name: "Hopeling" } },
    body: `
<div class="crumb"><a href="/guardians/">← All guardians</a></div>
${(() => { const gw = WIKI[g.wiki || g.name]; return gw && gw.img ? `<img class="worldimg rev" src="${esc(gw.img)}" alt="${esc(g.name)}"/><p class="imgcredit">PHOTO VIA WIKIPEDIA, CC BY-SA</p>` : ''; })()}
<div class="prose rev" style="margin-top:10px"><p style="font-family:var(--serif);font-size:20px;line-height:1.75">${esc(g.story)}</p></div>
${g.story_simple ? `<div class="card rev" style="margin-top:26px;border-left:4px solid var(--gold)"><b class="ct">For young readers</b><p>${esc(g.story_simple)}</p></div>` : ''}
<section class="block rev" style="margin-top:40px">
  <h2>Become their guardian</h2>
  <p class="lead">In the app, you can press and hold to take a quiet pledge for the ${esc(g.name.toLowerCase())}. From that day, when good news comes about them - and it does come - it is your news too.</p>
</section>
${appCta(`Stand for the ${esc(g.name.toLowerCase())}.`)}
`
  }));
}
const gTiles = (C.guardians || []).map(g => `<a class="tile rev" href="/guardians/${g.id}/"><span class="emo">${g.emo}</span><b>${esc(g.name)}</b><p>${esc(g.count)}</p></a>`).join('');
page('guardians', shell({
  title: "The Guardians - the rarest lives on Earth, and the people standing for them",
  desc: "Some of the rarest animals alive, each with a story and a pledge. Choose one. When good news comes about them, it becomes your news too.",
  canon: '/guardians/',
  hero: hero({ kicker: 'The rarest lives on Earth', h1: 'Someone should know their names.', sub: 'Each of these species is down to its last few. Each has a story, and each has people quietly winning them back. Choose one to stand for.', big: true, rain: true }),
  body: `<div class="grid">${gTiles}</div>${appCta()}`
}));

/* ---------- facts ---------- */

const factPages = C.facts.map((f, i) => {
  const s = slug(f[0].split(' ').slice(0, 6).join(' '));
  const cat = catBySlug[f[2]];
  page(path.join('facts', s), shell({
    title: `${f[0]} - true, sourced`,
    desc: `${f[0]} Source: ${f[1]}. One of Hopeling's dinner-table facts about the living world.`,
    canon: `/facts/${s}/`,
    jsonld: { "@context": "https://schema.org", "@type": "Article", headline: f[0], publisher: { "@type": "Organization", name: "Hopeling" } },
    hero: '',
    body: `
<div class="crumb" style="margin-top:30px"><a href="/facts/">← The Fact Vault</a></div>
<div class="plate rev${(() => { const ci = catImg(cat); return ci && ci.img ? ' photo' : ''; })()}" style="margin-top:16px">
  ${(() => { const ci = catImg(cat); return ci && ci.img ? `<img class="bg" src="${esc(ci.img)}" alt=""/>` : ''; })()}
  <div class="k">A TRUE THING ABOUT THE LIVING WORLD</div>
  <div class="f">${esc(f[0])}</div>
  <div class="k">- ${esc(f[1]).toUpperCase()}</div>
  ${f[3] ? `<div class="simple">For young helpers: ${esc(f[3])}</div>` : ''}
</div>
<div class="chips rev" style="margin-top:18px">
  ${cat ? `<a class="chip" href="/atlas/${cat.slug}/">${cat.emo} More from the world of ${esc(cat.name)}</a>` : ''}
  <a class="chip" href="#" id="sharef">Share this fact</a>
</div>
${appCta('A fact like this, every single day.')}
`,
    extraJs: `
  var sb=document.getElementById('sharef');
  sb.addEventListener('click',function(e){e.preventDefault();
    var txt=${JSON.stringify(f[0] + ' (' + f[1] + ') - via hopeling.app')};
    if(navigator.share){navigator.share({text:txt,url:location.href});}
    else{navigator.clipboard.writeText(txt+' '+location.href);sb.textContent='Copied!';}});
`
  }));
  return { f, s, cat };
});
const factTiles = factPages.map(({ f, s, cat }) => `<a class="tile rev" href="/facts/${s}/"><span class="emo">${cat ? cat.emo : '🌿'}</span><b style="font-style:italic;font-weight:600">${esc(f[0])}</b><p>- ${esc(f[1])}</p></a>`).join('');
page('facts', shell({
  title: "The Fact Vault - wildlife facts worth repeating at dinner",
  desc: "Every fact true, every fact sourced, every fact astonishing. The living world is stranger and more wonderful than fiction.",
  canon: '/facts/',
  hero: hero({ kicker: 'Every one true, every one sourced', h1: 'The Fact Vault', sub: 'Facts about the living world worth repeating at dinner. Take one. They are free.', big: true }),
  body: `<div class="grid">${factTiles}</div>${appCta()}`
}));

/* ---------- sitemap + robots ---------- */

fs.writeFileSync(path.join(ROOT, 'sitemap.xml'),
  `<?xml version="1.0" encoding="UTF-8"?>\n<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">\n` +
  ['/', ...written.filter(u => u !== '/site.css')].map(u => `  <url><loc>${SITE}${u}</loc></url>`).join('\n') +
  `\n</urlset>\n`);
if (!fs.existsSync(path.join(ROOT, 'robots.txt')))
  fs.writeFileSync(path.join(ROOT, 'robots.txt'), `User-agent: *\nAllow: /\nDisallow: /staging/\nSitemap: ${SITE}/sitemap.xml\n`);

console.log(`built ${written.length} files: ${C.categories.length} worlds, ${speciesIndex.length} species, ${(C.guardians || []).length} guardians, ${C.facts.length} facts, wins feed with ${allWins.length} entries`);
console.log(`wikipedia: ${Object.keys(WIKI).length} portraits cached (${fetched} newly fetched, ${[...wantWiki].filter(n => !WIKI[n]).length} unavailable this run)`);
