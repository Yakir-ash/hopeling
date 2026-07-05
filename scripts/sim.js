/* Headless DOM-stub simulation for WildHope v23 (grove + home refocus) */
const fs = require('fs');
const html = fs.readFileSync(__dirname + '/../wildhope-web/WildHope.html', 'utf8');
const m = html.match(/<script>\n([\s\S]*?)<\/script>\n<\/body>/);
if (!m) { console.error('FAIL: could not extract main script'); process.exit(1); }
const src = m[1];

// ---- stubs ----
const store = {};
global.localStorage = {
  getItem: k => (k in store ? store[k] : null),
  setItem: (k, v) => { store[k] = String(v); },
  removeItem: k => { delete store[k]; }
};
function el() {
  return {
    innerHTML: '', textContent: '', style: { setProperty(){}, }, value: '',
    classList: { add(){}, remove(){}, contains(){ return false; } },
    setAttribute(){}, getAttribute(){ return null; }, focus(){},
    addEventListener(){}, appendChild(){}, click(){},
    scrollLeft: 0, scrollWidth: 0
  };
}
const els = {};
global.document = {
  getElementById: id => (els[id] = els[id] || el()),
  documentElement: { setAttribute(){}, getAttribute(){ return null; } },
  createElement: () => el(),
  addEventListener(){}, body: el()
};
global.window = global;
global.__vibes = 0;
Object.defineProperty(globalThis, 'navigator', { configurable: true, value: { onLine: false, share: undefined, vibrate(){ global.__vibes++; }, serviceWorker: { register: () => Promise.reject(new Error('sim')) } } });
global.matchMedia = () => ({ matches: false, addEventListener(){} });
global.history = { pushState(){}, back(){}, state: null };
global.fetch = () => Promise.reject(new Error('offline sim'));
global.confirm = () => true;
global.alert = () => {};
global.URL = class { constructor(u){ this.href=u; } static createObjectURL(){ return 'blob:x'; } static revokeObjectURL(){} };
global.Blob = class {};
global.addEventListener = () => {};
global.scrollTo = () => {};
global.Image = class {
  set src(v) {
    this._s = v;
    const fail = global.__fail640 && v.indexOf('640px-') > -1;
    const t = () => { if (fail) { this.onerror && this.onerror(); } else { this.onload && this.onload(); } };
    t();
  }
};
global.setTimeout = fn => { try { fn(); } catch(e){} return 0; };

let failures = 0;
function check(name, cond) {
  if (cond) console.log('  ok  ' + name);
  else { failures++; console.log('  FAIL ' + name); }
}

// ---- load app ----
eval(src);
console.log('script evaluated, APP_V=' + APP_V);
check('APP_V is v34', APP_V === 'v34');

const dk = d => dkey(d);
const daysAgo = n => dk(new Date(Date.now() - 86400000 * n));

// ---- 1. render all tabs fresh-state ----
['home','explore','act','learn','me'].forEach(t => { tab = t; render(); check('render ' + t, document.getElementById('app').innerHTML.length > 100); });
tab = 'home'; render();
let h = document.getElementById('app').innerHTML;
check('grove card on home', h.indexOf('openGrove') > -1);
check('fresh state = sleeping seed', h.indexOf('Sleeping seed') > -1);
check('fresh caption = plant your grove', h.indexOf('Plant your grove') > -1);
check('no separate streak card anymore', h.indexOf('>🔥 Streak<') === -1);
check('core order: grove before fact before action',
  h.indexOf('openGrove') < h.indexOf("TODAY'S FACT") &&
  h.indexOf("TODAY'S FACT") < h.indexOf("Today's action"));
check('challenge folded into missions card', h.indexOf('doChallenge') > -1 && h.indexOf('>Missions<') > -1 && h.indexOf('Daily challenge') === -1);
check('animals-needing-attention gone from home', h.indexOf('Animals needing attention') === -1);

// ---- 2. first action: sprout + sparkle ----
doAction('refuse-plastic');
h = document.getElementById('app').innerHTML;
check('after action: streak 1', state.streak === 1);
check('after action: Sprout', h.indexOf('Sprout') > -1);
check('after action: sparkle shown', h.indexOf('✨') > -1);
check('after action: growing caption', h.indexOf('your grove is growing') > -1);
check('next text mentions Seedling in 2 days', h.indexOf('🌿 Seedling in 2 days') > -1);

// ---- 3. simulate a 7-day streak → robin arrives ----
// rewind: pretend the last 6 days were active, last action yesterday, streak 6
state.streak = 6; state.last = daysAgo(1); state.log = {};
for (let i = 1; i <= 6; i++) state.log[daysAgo(i)] = 1;
state.milestones = {}; save();
doAction('meatless-meal');
check('streak hits 7', state.streak === 7);
check('robin milestone recorded', state.milestones['friend7'] === 1);
check('freeze earned at 7', state.freezes >= 1);
h = document.getElementById('app').innerHTML;
check('young tree at 7', h.indexOf('Young tree') > -1);
check('robin visible in friends row', h.indexOf('🐦') > -1);
check('next: bee in 7 days', h.indexOf('a bee 🐝 arrives in 7 days') > -1);

// ---- 4. streak breaks → friends stay, tree rests ----
state.streak = 0; state.last = daysAgo(5); save(); render();
h = document.getElementById('app').innerHTML;
check('broken streak: resting caption (no guilt)', h.indexOf('resting, not gone') > -1);
check('broken streak: robin still there (best streak)', h.indexOf('🐦') > -1);
check('broken streak: back to sleeping seed', h.indexOf('Sleeping seed') > -1);

// ---- 5. grove sheet ----
openGrove();
const sh = document.getElementById('sheet').innerHTML;
check('grove sheet renders', sh.indexOf('Growth stages') > -1 && sh.indexOf('Grove friends') > -1);
check('sheet shows robin earned', sh.indexOf('robin') > -1);
check('sheet shows locked friend day', sh.indexOf('day 14') > -1);
check('sheet hope framing', sh.indexOf('never dies') > -1);

// ---- 6. no re-announce of earned friend after streak rebuilt ----
state.streak = 6; state.last = daysAgo(1); state._newFriend = null; save();
doAction('save-water');
check('streak 7 again', state.streak === 7);
check('robin NOT re-announced', !state._newFriend);

// ---- 7. groveNextText across boundaries ----
state.streak = 99; check('next at 99: ancient grove in 1 day', groveNextText().indexOf('Ancient grove in 1 day') > -1);
state.streak = 130; state.log[daysAgo(0)] = 1;
check('no next at max (150 needed? none)', typeof groveNextText() === 'string');

// ---- 8. stage idx sanity ----
check('stage idx 0 @0', groveStageIdx(0) === 0);
check('stage idx sprout @1', GROVE_STAGES[groveStageIdx(1)][2] === 'Sprout');
check('stage idx seedling @5', GROVE_STAGES[groveStageIdx(5)][2] === 'Seedling');
check('stage idx flourishing @45', GROVE_STAGES[groveStageIdx(45)][2] === 'Flourishing tree');
check('stage idx ancient @200', GROVE_STAGES[groveStageIdx(200)][2] === 'Ancient grove');

// ---- 8b. photo hero ----
tab='home'; render();
let hh = document.getElementById('app').innerHTML;
check('hero markup present', hh.indexOf('heroimg') > -1 && hh.indexOf('heroscrim') > -1 && hh.indexOf('herocap') > -1);
check('gradient fallback kept', hh.indexOf('g-forest hero') > -1);
check('fillFactPhoto exists + offline-safe', (() => { try { fillFactPhoto(); return true; } catch(e) { console.log('   err:', e.message); return false; } })());
check('thumb resize regex', "https://u.wiki/thumb/a/320px-x.jpg".replace(/\/(\d+)px-/, '/640px-') === 'https://u.wiki/thumb/a/640px-x.jpg');
check('hero before action card', hh.indexOf('heroimg') < hh.indexOf("Today's action"));

// ---- 8c. photo fallback chain (v31: photo matches today's fact's category) ----
const todaysFact = FACTS[dailyIndex(FACTS.length,'f')];
const photoCat = (todaysFact && todaysFact[2] && CATS.filter(c=>c.slug===todaysFact[2])[0]) || CATS[dailyIndex(CATS.length,'p')];
const wikiTitle = photoCat.wiki || CAT_WIKI[photoCat.slug] || photoCat.name;
store['wh_wiki_'+wikiTitle] = JSON.stringify({ts: Date.now(), d: {t:'TestArticle', x:'x', desc:'', img:'https://up.wm/thumb/9/9d/O.png/320px-O.png', big:null, url:null}});
global.__fail640 = false; _heroUrl = null;
render(); // triggers fillFactPhoto
let bg1 = document.getElementById('heroimg').style.backgroundImage || '';
check('photo set (640 ok)', bg1.indexOf('640px-O.png') > -1);
check('caption set + tappable', (document.getElementById('herocap').innerHTML || '').indexOf('TestArticle') > -1);
global.__fail640 = true; _heroUrl = null; document.getElementById('heroimg').style.backgroundImage = '';
render();
let bg2 = document.getElementById('heroimg').style.backgroundImage || '';
check('640 fails -> raw thumb fallback', bg2.indexOf('320px-O.png') > -1);
// article without image -> species fallback
store['wh_wiki_'+wikiTitle] = JSON.stringify({ts: Date.now(), d: {t:'TestArticle', x:'x', desc:'', img:null, big:null, url:null}});
const firstSpecies = catSpecies(photoCat)[0];
if (firstSpecies) {
  store['wh_wiki_'+firstSpecies] = JSON.stringify({ts: Date.now(), d: {t:firstSpecies, x:'x', desc:'', img:'https://up.wm/thumb/1/11/S.jpg/320px-S.jpg', big:null, url:null}});
  global.__fail640 = false; _heroUrl = null; document.getElementById('heroimg').style.backgroundImage = '';
  render();
  let bg3 = document.getElementById('heroimg').style.backgroundImage || '';
  check('no article image -> species photo fallback', bg3.indexOf('640px-S.jpg') > -1);
} else { check('photo category has curated species', false); }
global.__fail640 = false;

// ---- 8d. celebration burst ----
check('celebrateBurst exists + safe', (() => { try { celebrateBurst(); return true; } catch(e) { return false; } })());
const vBefore = global.__vibes;
state.chDone = null; tab='home'; render(); doChallenge();
check('challenge triggers haptic', global.__vibes > vBefore);
const vBefore2 = global.__vibes;
doAction('educate-child');
check('action triggers haptic', global.__vibes > vBefore2);
// reduced motion: burst skipped but no crash
global.matchMedia = () => ({ matches: true, addEventListener(){} });
check('reduced-motion safe', (() => { try { celebrateBurst(); return true; } catch(e) { return false; } })());
global.matchMedia = () => ({ matches: false, addEventListener(){} });


// ---- explain-simply toggle (content.json v6) ----
const CJ = JSON.parse(require('fs').readFileSync(__dirname + '/../wildhope-web/content.json','utf8'));
check('content.json is v10', CJ.version === 10);
applyContent(CJ);
check('every category has sci_simple', CATS.every(c => !c.science || c.sci_simple));
check('every lesson has body_simple', COURSES.every(co => co.lessons.every(l => !l.body || l.body_simple)));
const cat0 = CATS.filter(c=>c.slug==='sea-turtles')[0];
const les0 = COURSES.filter(c=>c.slug==='ocean-pollution')[0];
// full mode
state.simple = false;
check('simpleText full when off', simpleText(cat0.science, cat0.sci_simple) === cat0.science);
openCat('sea-turtles'); catTab('sea-turtles',0);
let cb = document.getElementById('catBody').innerHTML;
check('overview shows full science (off)', cb.indexOf(cat0.science) > -1);
check('chip present + says Explain simply', cb.indexOf('Explain simply</button>') > -1 || cb.indexOf('Explain simply<') > -1);
check('chip not selected when off', cb.indexOf('chip sel') === -1 || cb.indexOf('Explain simply: on') === -1);
// simple mode
state.simple = true;
check('simpleText simple when on', simpleText(cat0.science, cat0.sci_simple) === cat0.sci_simple);
catTab('sea-turtles',0);
cb = document.getElementById('catBody').innerHTML;
check('overview shows simple science (on)', cb.indexOf(cat0.sci_simple) > -1 && cb.indexOf(cat0.science) === -1);
check('chip now says on', cb.indexOf('Explain simply: on') > -1);
// lesson simple
openLesson('ocean-pollution',0);
let lb = document.getElementById('sheet').innerHTML;
check('lesson shows simple body (on)', lb.indexOf(les0.lessons[0].body_simple) > -1 && lb.indexOf(les0.lessons[0].body) === -1);
// toggle round-trip via toggleSimple (reopens lesson)
toggleSimple('lesson','ocean-pollution',0);
check('toggleSimple flipped to off', state.simple === false);
lb = document.getElementById('sheet').innerHTML;
check('lesson back to full body (off)', lb.indexOf(les0.lessons[0].body) > -1);
check('simple persisted in SAVE_KEYS', SAVE_KEYS.indexOf('simple') > -1);
// missing-variant safety: fake lesson with no simple text still renders, no chip
state.simple = true;
const fakeCourse = {slug:'zz', t:'Z', d:'', badge:'⭐', lessons:[{t:'L', min:1, body:'ONLY FULL', quiz:[{q:'?',opts:['a','b'],a:0}]}]};
COURSES.push(fakeCourse);
openLesson('zz',0);
let fb = document.getElementById('sheet').innerHTML;
check('no-simple lesson still shows full body', fb.indexOf('ONLY FULL') > -1);
check('no-simple lesson has no chip', fb.indexOf('Explain simply') === -1);
COURSES.pop();
state.simple = false;

// ---- 8e. fact/photo category tagging ----
tab='home'; render();
const _tf = FACTS[dailyIndex(FACTS.length,'f')];
check('today fact tagged to a real category (or intentionally untagged)', !_tf[2] || !!CATS.filter(c=>c.slug===_tf[2])[0]);
check('all tagged facts resolve to real categories', FACTS.every(f=>!f[2] || !!CATS.filter(c=>c.slug===f[2])[0]));
check('fillFactPhoto safe for every fact', (()=>{ try { for(let k=0;k<FACTS.length;k++){ fillFactPhoto(); } return true; } catch(e){ return false; } })());

// ---- 9. me tab still fine, challenge works ----
tab = 'me'; render(); check('me tab renders post-changes', document.getElementById('app').innerHTML.indexOf('Badges') > -1);
tab = 'home'; render(); state.chDone = null; doChallenge();
check('challenge done', state.chDone === today());


// ---- 9b. event banner collapses once badge earned ----
state.eventBadges = [['X','Plastic-Free July 2026','pfj-2026']];
tab='home'; render();
let ce = document.getElementById('app').innerHTML;
check('completed event shows one-liner', ce.indexOf('badge earned') > -1 && ce.indexOf('DAYS LEFT') === -1);
state.eventBadges = []; render();
check('active event shows full banner again', document.getElementById('app').innerHTML.indexOf('DAYS LEFT') > -1);

// ---- 10. tree rings ----
state.rings = null; state.log = {};
// history: a 4-day run two weeks ago, a 2-day run last week (too short), current day
for (let i = 14; i >= 11; i--) state.log[daysAgo(i)] = 1;
state.log[daysAgo(6)] = 1; state.log[daysAgo(5)] = 1;
state.log[daysAgo(0)] = 1;
migrateRings();
check('migration found the 4-day ring', state.rings.length === 1 && state.rings[0].n === 4);
check('short runs and live run excluded', !state.rings.some(r => r.n === 2 || r.n === 1));
// breaking a streak records a ring
state.streak = 5; state.last = daysAgo(3); state.freezes = 0;
doAction('native-plant');
check('break recorded 5-day ring', state.rings[0].n === 5 && state.streak === 1);
openGrove();
check('rings shown in grove sheet', document.getElementById('sheet').innerHTML.indexOf('Tree rings') > -1);

// ---- 11. seasonal event (Plastic-Free July active on 2026-07-04) ----
check('event active', !!activeEvent() && activeEvent().id === 'pfj-2026');
tab='home'; render();
let eh = document.getElementById('app').innerHTML;
check('event banner on home', eh.indexOf('Plastic-Free July') > -1 && eh.indexOf('DAYS LEFT') > -1);
check('event banner under grove, above fact', eh.indexOf('openGrove') < eh.indexOf('Plastic-Free July') && eh.indexOf('Plastic-Free July') < eh.indexOf("TODAY'S FACT"));
state.eventProg = {}; state.eventBadges = [];
doAction('refuse-plastic');
check('refusal counts twice (refuse + any)', state.eventProg['pfj-2026']['pfj-refuse'] === 1 && state.eventProg['pfj-2026']['pfj-any'] >= 1);
// finish all missions
const xpBefore = state.xp;
state.eventProg['pfj-2026'] = { 'pfj-refuse': 4, 'pfj-clean': 2, 'pfj-any': 7 };
doAction('refuse-plastic');
check('event badge awarded on completion', state.eventBadges.length === 1 && state.eventBadges[0][2] === 'pfj-2026');
check('badge in gallery defs', badgeDefs().some(d => d[1] === 'Plastic-Free July 2026' && d[2] >= d[3]));
doAction('refuse-plastic');
check('badge not re-awarded', state.eventBadges.length === 1);
// no event -> no banner, no crash
const savedEv = EVENT; EVENT = null;
render(); check('no banner without event', document.getElementById('app').innerHTML.indexOf('Plastic-Free July') === -1);
EVENT = savedEv;


// ---- 12. spirit species quiz ----
state.spirit = null; state.spiritDismissed = false;
tab='home'; render();
check('quiz teaser on home when untaken', document.getElementById('app').innerHTML.indexOf('spirit species') > -1);
openQuiz();
check('quiz question 1 shown', document.getElementById('sheet').innerHTML.indexOf('1/7') > -1);
[0,3,1,3,3,0,0].forEach(p => quizPick(p)); // water / playful / social picks
check('result after 7 answers', !!state.spirit && !!SPIRITS[state.spirit.id]);
check('result sheet rendered', document.getElementById('sheet').innerHTML.indexOf('YOUR SPIRIT SPECIES') > -1);
check('watery playful answers give a water spirit', ['otter','dolphin'].includes(state.spirit.id));
render();
check('teaser gone once taken', document.getElementById('app').innerHTML.indexOf('7 questions, 60 seconds') === -1);
tab='me'; render();
check('me shows spirit', document.getElementById('app').innerHTML.indexOf('Your spirit species') > -1);
// every species must be reachable: brute-force all 4^7 combos
const winners = new Set();
const combo = [0,0,0,0,0,0,0];
for (let n = 0; n < 16384; n++) {
  let v = n;
  for (let q = 0; q < 7; q++) { combo[q] = v & 3; v >>= 2; }
  winners.add(spiritScore(combo));
}
check('all 12 spirits reachable (got '+winners.size+')', winners.size === Object.keys(SPIRITS).length);
check('shareSpirit defined', typeof shareSpirit === 'function');
state.spirit = null; state.spiritDismissed = true; tab='home'; render();
check('dismissed teaser stays hidden', document.getElementById('app').innerHTML.indexOf('7 questions, 60 seconds') === -1);

console.log(failures === 0 ? '\nALL CHECKS PASSED' : '\n' + failures + ' FAILURES');
process.exit(failures === 0 ? 0 : 1);
