#!/usr/bin/env node
/* Hopeling content refresher.
   Pulls positive conservation news from the outlets' own RSS feeds, merges into
   hopeling-web/content.json news[], bumps version+updated, and validates hard
   before writing. Editorial content (actions, courses, hope framing) is never
   touched - only the news feed.
   Usage:
     node scripts/refresh-content.mjs            # real run (network)
     node scripts/refresh-content.mjs --dry-run  # fetch + report, no write
     node scripts/refresh-content.mjs --selftest # offline logic tests, no network
*/
import fs from 'fs';

const CONTENT = new URL('../hopeling-web/content.json', import.meta.url).pathname;
const MAX_NEW_PER_RUN = 4;
const NEWS_CAP = 12;

const ALLOW = ['theguardian.com','bbc.com','bbc.co.uk','mongabay.com','goodnewsnetwork.org',
  'phys.org','sciencedaily.com','smithsonianmag.com','nationalgeographic.com','apnews.com',
  'reuters.com','positive.news','euronews.com','cbc.ca','abc.net.au','newscientist.com',
  'npr.org','independent.co.uk','nytimes.com','washingtonpost.com','sciencenews.org',
  'e360.yale.edu','ecowatch.com','discoverwildlife.com','birdlife.org','rewildingeurope.com','reasonstobecheerful.world'];
/* suffix match so subdomains pass (news.mongabay.com -> mongabay.com) */
function allowedDomain(dom){ return ALLOW.some(d => dom === d || dom.endsWith('.' + d)); }

const TAGS = [[/whale|dolphin|orca/i,'\u{1F40B}'],[/turtle/i,'\u{1F422}'],[/shark|\bray\b/i,'\u{1F988}'],
  [/coral|reef/i,'\u{1F41F}'],[/ocean|marine|\bsea\b/i,'\u{1F30A}'],[/forest|\btree|rainforest/i,'\u{1F333}'],
  [/bird|eagle|condor|penguin/i,'\u{1F426}'],[/\bbee|pollinat|butterfl/i,'\u{1F41D}'],[/elephant/i,'\u{1F418}'],
  [/tiger/i,'\u{1F405}'],[/rhino/i,'\u{1F98F}'],[/gorilla|orangutan|primate/i,'\u{1F98D}'],[/wol(f|ves)/i,'\u{1F43A}'],
  [/frog|amphibian/i,'\u{1F438}'],[/\bbats?\b/i,'\u{1F987}'],[/river|wetland|freshwater/i,'\u{1F4A7}'],[/panda/i,'\u{1F43C}']];

const POSITIVE = /(recover|rebound|return|comeback|success|saved|thriv|revival|record numbers|milestone|protect|restor|\bbirths?\b|hatch|released|downlisted|no longer endangered|sanctuary|\bban\b|banned|breakthrough|first time in|reintroduc|rewild|bounce[sd]? back|back from the brink|flourish|boom|surge in|good news|conservation win|\bbaby\b|\bcubs?\b|\bcalf\b|chicks?\b|new hope|rare .{0,30}spotted|discovered)/i;
const NEGATIVE = /(\bdead\b|death|killed|extinct\b|decline|crisis|threat|\bloss\b|poach|wildfire|disease outbreak)/i;

export function sanitize(s){
  return String(s||'').replace(/<[^>]*>/g,'').replace(/[\u2014\u2013]/g,'-')
    .replace(/[\u0000-\u001F\u00AD]/g,' ').replace(/\s+/g,' ').trim();
}
export function tagFor(t){ for(const [re,e] of TAGS) if(re.test(t)) return e; return '\u{1F389}'; }

export const REJECTS = { length:0, url:0, domain:0, notPositive:0, negative:0 };
export function toItem(a){
  const t = sanitize(a.title);
  if(t.length < 25 || t.length > 140){ REJECTS.length++; return null; }
  const url = String(a.url||'').replace(/^http:\/\//,'https://');
  if(!/^https:\/\//.test(url)){ REJECTS.url++; return null; }
  const dom = String(a.domain||'').replace(/^www\./,'').toLowerCase();
  if(!allowedDomain(dom)){ REJECTS.domain++; return null; }
  if(NEGATIVE.test(t)){ REJECTS.negative++; return null; }
  if(!POSITIVE.test(t)){ REJECTS.notPositive++; return null; }
  const d8 = String(a.seendate||'').slice(0,8);
  const date = /^\d{8}$/.test(d8) ? `${d8.slice(0,4)}-${d8.slice(4,6)}-${d8.slice(6,8)}`
                                   : new Date().toISOString().slice(0,10);
  return { d: date, tag: tagFor(t), t, x: '', src: dom, url };
}

export function mergeNews(existing, incoming, cap = NEWS_CAP){
  const seen = new Set();
  for(const n of existing){ seen.add(n.url||''); seen.add(n.t||''); }
  const fresh = [];
  for(const n of incoming){
    if(!n || seen.has(n.url) || seen.has(n.t)) continue;
    seen.add(n.url); seen.add(n.t);
    fresh.push(n);
    if(fresh.length >= MAX_NEW_PER_RUN) break;
  }
  return { merged: [...fresh, ...existing].slice(0, cap), added: fresh.length };
}

export function validateDoc(doc){
  const errs = [];
  if(!Number.isInteger(doc.version)) errs.push('version not an integer');
  if(!Array.isArray(doc.news)) errs.push('news missing');
  for(const n of doc.news||[]){
    if(!n.t || n.t.length > 140) errs.push('bad news title: '+JSON.stringify(n.t||'').slice(0,50));
    if(/[\u2014\u2013]/.test(JSON.stringify(n))) errs.push('long dash in news item');
    if(n.url && !/^https:\/\//.test(n.url)) errs.push('non-https url');
    if(!/^\d{4}-\d{2}-\d{2}$/.test(n.d||'')) errs.push('bad date '+n.d);
  }
  const acts = new Set(Object.keys(doc.actions||{}));
  for(const c of doc.categories||[]) for(const a of c.acts||[])
    if(!acts.has(a)) errs.push(`dangling act ${a} in ${c.slug}`);
  return errs;
}

/* RSS instead of GDELT (retired 2026-07-05 after 6 rounds of rate limits and
   query-rule roulette). The outlets publish machine-readable feeds on purpose:
   free, keyless, reliable at weekly cadence. Each feed fails independently. */
const FEEDS = [
  { url: 'https://news.mongabay.com/feed/', domain: 'mongabay.com' },
  { url: 'https://www.goodnewsnetwork.org/category/earth/feed/', domain: 'goodnewsnetwork.org' },
  { url: 'https://www.positive.news/feed/', domain: 'positive.news' },
  { url: 'https://reasonstobecheerful.world/feed/', domain: 'reasonstobecheerful.world' },
  { url: 'https://www.theguardian.com/environment/wildlife/rss', domain: 'theguardian.com' },
  { url: 'https://feeds.bbci.co.uk/news/science_and_environment/rss.xml', domain: 'bbc.com' },
  { url: 'https://www.sciencedaily.com/rss/plants_animals/endangered_animals.xml', domain: 'sciencedaily.com' },
  { url: 'https://www.sciencedaily.com/rss/plants_animals/nature.xml', domain: 'sciencedaily.com' }
];
/* keep only nature-related headlines (BBC sci feed also carries space/physics) */
const TOPIC = /(wildlif|species|conservation|nature|animal|bird|whale|dolphin|forest|ocean|reef|\bbee|turtle|elephant|rhino|panda|wol(f|ves)|frog|butterfl|coral|penguin|gorilla|orangutan|tiger|leopard|otter|seal|shark|\bbats?\b|wetland|river|marine|habitat|kakapo|vaquita|axolotl|saola|parrot)/i;

export function decodeEntities(t){
  return String(t||'')
    .replace(/<!\[CDATA\[([\s\S]*?)\]\]>/g, '$1')
    .replace(/&#(\d+);/g, (m, n) => String.fromCodePoint(parseInt(n, 10)))
    .replace(/&#x([0-9a-fA-F]+);/g, (m, n) => String.fromCodePoint(parseInt(n, 16)))
    .replace(/&amp;/g, '&').replace(/&lt;/g, '<').replace(/&gt;/g, '>')
    .replace(/&quot;/g, '"').replace(/&apos;/g, "'").trim();
}
export function parseRss(xml, domain){
  const items = [];
  const blocks = String(xml||'').match(/<item[\s>][\s\S]*?<\/item>/g) || [];
  for(const b of blocks){
    const title = decodeEntities((b.match(/<title[^>]*>([\s\S]*?)<\/title>/) || [])[1] || '');
    const link  = decodeEntities((b.match(/<link[^>]*>([\s\S]*?)<\/link>/) || [])[1] || '');
    const pub   = (b.match(/<pubDate[^>]*>([\s\S]*?)<\/pubDate>/) || [])[1] || '';
    const dt = new Date(pub);
    const seendate = isNaN(dt) ? '' :
      String(dt.getUTCFullYear()) + String(dt.getUTCMonth()+1).padStart(2,'0') + String(dt.getUTCDate()).padStart(2,'0') + '000000';
    if(title && link) items.push({ title, url: link, domain, seendate });
  }
  return items;
}
export function topicOk(title){ return TOPIC.test(title); }
async function fetchFeed(f){
  const r = await fetch(f.url, { headers: { 'user-agent': 'Hopeling-content-refresh/1.0 (+https://hopeling.app)' }, signal: AbortSignal.timeout(30000) });
  if(!r.ok) throw new Error('HTTP ' + r.status);
  return parseRss(await r.text(), f.domain);
}
async function fetchNews(){
  const all = [];
  let okCount = 0;
  for(const f of FEEDS){
    try {
      const items = (await fetchFeed(f)).filter(i => topicOk(i.title));
      console.log(`  ${f.domain}: ${items.length} nature items`);
      all.push(...items);
      okCount++;
    } catch(e){
      console.log(`  ${f.domain}: failed (${(e.cause && e.cause.code) || e.message})`);
    }
    await new Promise(r => setTimeout(r, 1500));
  }
  return okCount === 0 ? null : all;
}

function selftest(){
  const ok = (name, cond) => { console.log((cond?'  ok   ':'  FAIL ') + name); if(!cond) process.exitCode = 1; };
  const good = { title: 'Humpback whales make a stunning recovery in the South Atlantic', url: 'https://www.theguardian.com/x', domain: 'www.theguardian.com', seendate: '20260701120000' };
  ok('accepts allowlisted positive article', !!toItem(good));
  ok('date parsed', toItem(good).d === '2026-07-01');
  ok('tag matched (whale)', toItem(good).tag === '\u{1F40B}');
  ok('rejects unknown domain', !toItem({ ...good, domain: 'random-blog.biz' }));
  ok('accepts subdomain of allowlisted outlet', !!toItem({ ...good, domain: 'news.mongabay.com' }));
  ok('rejects lookalike domain', !toItem({ ...good, domain: 'fakemongabay.com' }));
  ok('upgrades http url to https', (toItem({ ...good, url: 'http://www.theguardian.com/x' })||{}).url === 'https://www.theguardian.com/x');
  ok('rejects non-http(s) url', !toItem({ ...good, url: 'ftp://www.theguardian.com/x' }));
  ok('rejects negative headline', !toItem({ ...good, title: 'Whale found dead after recovery effort at the sanctuary site' }));
  ok('rejects neutral headline', !toItem({ ...good, title: 'Scientists study whale population dynamics in the Atlantic ocean' }));
  const dash = toItem({ ...good, title: 'Rare frogs thrive again \u2014 a comeback in the wetlands of Panama' });
  ok('em dash sanitized to hyphen', !!dash && dash.t.includes(' - ') && !/[\u2014\u2013]/.test(dash.t));
  ok('strips html tags', sanitize('<b>Hello</b> world') === 'Hello world');
  const { merged, added } = mergeNews([{ t: 'old', url: 'https://a/1', d: '2026-06-01' }], [toItem(good), toItem(good), null]);
  ok('dedupes + merges (1 added)', added === 1 && merged.length === 2 && merged[0].t.startsWith('Humpback'));
  const rssFixture = '<rss><channel><item><title><![CDATA[Kakapo chicks hatch in record numbers &#8211; a comeback]]></title><link>https://news.mongabay.com/2026/04/kakapo/</link><pubDate>18 Apr 2026 11:18:53 +0000</pubDate></item><item><title>Quantum computer milestone announced</title><link>https://bbc.com/quantum</link><pubDate>18 Apr 2026 10:00:00 +0000</pubDate></item></channel></rss>';
  const parsed = parseRss(rssFixture, 'mongabay.com');
  ok('rss: parses items', parsed.length === 2);
  ok('rss: decodes CDATA + entities', parsed[0].title.indexOf('Kakapo chicks hatch in record numbers') === 0 && parsed[0].title.indexOf('CDATA') === -1);
  ok('rss: pubDate to seendate', parsed[0].seendate === '20260418000000');
  ok('rss: topic gate passes nature', topicOk(parsed[0].title));
  ok('rss: topic gate blocks off-topic', !topicOk(parsed[1].title));
  ok('rss item passes toItem pipeline', !!toItem(parsed[0]));
  const doc = JSON.parse(fs.readFileSync(CONTENT, 'utf8'));
  ok('current content.json passes validation', validateDoc(doc).length === 0);
  console.log(process.exitCode ? 'SELFTEST FAILED' : 'SELFTEST PASSED');
}

async function main(){
  if(process.argv.includes('--selftest')) return selftest();
  const dry = process.argv.includes('--dry-run');
  const doc = JSON.parse(fs.readFileSync(CONTENT, 'utf8'));
  const arts = await fetchNews();
  if(arts === null){ console.log('All feeds unreachable - skipping this run, content.json untouched.'); return; }
  const items = arts.map(toItem).filter(Boolean);
  const { merged, added } = mergeNews(doc.news || [], items);
  console.log(`Feed items: ${arts.length}, passed filters: ${items.length}, new after dedupe: ${added}`);
  console.log('Reject breakdown:', JSON.stringify(REJECTS));
  if(items.length === 0 && arts.length > 0){
    console.log('Sample rejected domains:', [...new Set(arts.slice(0,20).map(a=>String(a.domain||'')))].join(', '));
    console.log('Sample rejected titles:', arts.slice(0,5).map(a=>String(a.title||'').slice(0,80)).join(' | '));
  }
  if(!added){ console.log('No new items - content.json untouched.'); return; }
  doc.news = merged;
  doc.version = doc.version + 1;
  doc.updated = new Date().toISOString().slice(0, 10);
  const errs = validateDoc(doc);
  if(errs.length){ console.error('VALIDATION FAILED - not writing:\n' + errs.join('\n')); process.exit(1); }
  if(dry){ console.log('[dry-run] would write version', doc.version, JSON.stringify(merged.slice(0, added), null, 1)); return; }
  fs.writeFileSync(CONTENT, JSON.stringify(doc));
  console.log(`Wrote content.json version ${doc.version} (+${added} news items).`);
}
main().catch(e => { console.error(e); process.exit(1); });
