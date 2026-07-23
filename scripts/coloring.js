#!/usr/bin/env node
// The Hopeling coloring shelf - real, hand-drawn coloring pages from
// U.S. public wildlife agencies (U.S. Fish & Wildlife Service, NOAA
// and its National Marine Sanctuaries). Works of the U.S. government
// are public domain: free to print, share, and keep. We curate and
// link the originals at their official homes rather than redrawing
// what actual wildlife artists already drew better.
//
// Every entry below was found via the agencies' own education
// libraries. Artist credited where the agency credits one.
//
// Usage: node scripts/coloring.js   (writes ./coloring/index.html)

const fs = require('fs');
const path = require('path');

const OUT = path.join(__dirname, '..', 'coloring');

const SHELF = [
  {
    theme: '🌊 Ocean friends',
    items: [
      { t: 'Sea turtles - a whole coloring book', a: 'sea turtles',
        org: 'NOAA Hawaiian Islands Sanctuary', kind: 'book',
        url: 'https://nmshawaiihumpbackwhale.blob.core.windows.net/hawaiihumpbackwhale-prod/media/archive/documents/pdfs_activity_books/nonahonukai.pdf',
        note: 'in English and Hawaiian - No Nā Honu Kai' },
      { t: 'Sharks and rays coloring book', a: 'sharks, rays',
        org: 'NOAA Channel Islands Sanctuary', kind: 'book',
        url: 'https://nmssanctuaries.blob.core.windows.net/sanctuaries-prod/media/docs/2020624-shark-coloring-book.pdf' },
      { t: 'Pacific coral reef coloring book', a: 'reef fish, corals, eels',
        org: 'NOAA National Marine Sanctuaries', kind: 'book',
        url: 'https://nmssanctuaries.blob.core.windows.net/sanctuaries-prod/media/archive/about/pdfs/reef_color.pdf' },
      { t: 'Reef scene - one big page', a: 'a whole reef',
        org: 'NOAA National Marine Sanctuaries', kind: 'page',
        url: 'https://nmssanctuaries.blob.core.windows.net/sanctuaries-prod/media/archive/education/pdfs/reef_scene_color_sheet.pdf' },
      { t: 'Dolphin pages', a: 'wild dolphins',
        org: 'NOAA Dolphin SMART', kind: 'book',
        url: 'https://nmssanctuaries.blob.core.windows.net/sanctuaries-prod/media/archive/dolphinsmart/pdfs/dskids_guide.pdf' },
      { t: 'Humpback whale activity book', a: 'humpback whales',
        org: 'NOAA Hawaiian Islands Sanctuary', kind: 'book',
        url: 'https://nmshawaiihumpbackwhale.blob.core.windows.net/hawaiihumpbackwhale-prod/media/archive/documents/pdfs_activity_books/activity_book_2010.pdf' },
      { t: 'Our marine neighbors', a: 'orcas, seals, otters',
        org: 'NOAA Fisheries, Pacific Northwest', kind: 'book',
        url: 'https://media.fisheries.noaa.gov/2021-06/our-marine-neighbors.pdf' },
      { t: 'Be an ocean guardian activity book', a: 'ocean life',
        org: 'NOAA National Marine Sanctuaries', kind: 'book',
        url: 'https://nmssanctuaries.blob.core.windows.net/sanctuaries-prod/media/archive/education/pdfs/ogab.pdf' },
    ],
  },
  {
    theme: '❄️ Ice and Arctic',
    items: [
      { t: 'Polar bear', a: 'a polar bear among seals',
        org: 'U.S. Fish & Wildlife Service', kind: 'page',
        by: 'Amanda Rose Warren',
        url: 'https://www.fws.gov/sites/default/files/documents/Polar_bear_508%20compliant.pdf' },
      { t: 'Northern sea otter', a: 'a sea otter',
        org: 'U.S. Fish & Wildlife Service', kind: 'page',
        url: 'https://www.fws.gov/media/northern-sea-otter-coloring-page' },
      { t: 'Arctic and Antarctic activity book', a: 'penguins, polar animals',
        org: 'NOAA Ocean Service', kind: 'book',
        url: 'https://cdn.oceanservice.noaa.gov/oceanserviceprod/kids/aabook.pdf' },
    ],
  },
  {
    theme: '🐸 Rivers and wetlands',
    items: [
      { t: 'Wetlands coloring book', a: 'frogs, herons, dragonflies',
        org: 'U.S. Fish & Wildlife Service', kind: 'book',
        url: 'https://www.fws.gov/sites/default/files/documents/wetlands-coloring-book.pdf' },
      { t: 'Pacific salmon and steelhead coloring book', a: 'salmon',
        org: 'U.S. Fish & Wildlife Service', kind: 'book',
        url: 'https://www.fws.gov/media/pacific-salmon-and-steelhead-coloring-book' },
      { t: 'Salmon mural coloring sheet', a: 'a salmon stream mural',
        org: 'NOAA Fisheries', kind: 'page',
        url: 'https://www.fisheries.noaa.gov/resource/educational-materials/salmon-mural-coloring-sheet' },
    ],
  },
  {
    theme: '🦬 Big land animals and birds',
    items: [
      { t: 'Wood bison', a: 'a wood bison',
        org: 'U.S. Fish & Wildlife Service', kind: 'page',
        url: 'https://www.fws.gov/media/wood-bison-coloring-page' },
      { t: 'Short-tailed albatross', a: 'an albatross and chick',
        org: 'U.S. Fish & Wildlife Service', kind: 'page',
        url: 'https://www.fws.gov/media/short-tailed-albatross-coloring-page' },
      { t: 'Conservation in Color - all of Alaska’s wildlife',
        a: 'the whole Alaskan collection',
        org: 'U.S. Fish & Wildlife Service', kind: 'collection',
        url: 'https://www.fws.gov/library/collections/conservation-color-alaskas-wildlife' },
    ],
  },
];

const esc = s => String(s).replace(/&/g, '&amp;').replace(/</g, '&lt;')
    .replace(/>/g, '&gt;').replace(/"/g, '&quot;');

const KIND = { book: '📚 whole book', page: '🖼 single page', collection: '🗂 collection' };

const cards = SHELF.map(sec => `
  <h2>${sec.theme}</h2>
  <div class="grid">
    ${sec.items.map(i => `
    <a class="card" href="${i.url}" target="_blank" rel="noopener">
      <div class="k">${KIND[i.kind]}</div>
      <div class="t">${esc(i.t)}</div>
      <div class="a">${esc(i.a)}</div>
      <div class="o">${esc(i.org)}${i.by ? ` · art by ${esc(i.by)}` : ''}</div>
    </a>`).join('')}
  </div>`).join('\n');

fs.mkdirSync(OUT, { recursive: true });
fs.writeFileSync(path.join(OUT, 'index.html'), `<!doctype html>
<html lang="en"><head><meta charset="utf-8"/>
<meta name="viewport" content="width=device-width, initial-scale=1"/>
<title>Hopeling coloring shelf - real wildlife coloring pages, free to print</title>
<meta name="description" content="Hand-drawn wildlife coloring pages and books from U.S. public wildlife agencies - public domain, free to print and keep."/>
<style>
  * { box-sizing: border-box; }
  body { font-family: Georgia, serif; color: #16241C; margin: 0;
         background: #FAF8F2; }
  .wrap { max-width: 860px; margin: 0 auto; padding: 28px 20px 60px; }
  h1 { font-size: 30px; margin: 0 0 8px; }
  .intro { font-size: 14.5px; line-height: 1.65; color: #444;
           max-width: 640px; }
  h2 { font-size: 19px; margin: 30px 0 12px; color: #2E6B4F; }
  .grid { display: grid; gap: 12px;
          grid-template-columns: repeat(auto-fill, minmax(240px, 1fr)); }
  .card { display: block; background: #fff; border-radius: 16px;
          padding: 16px; text-decoration: none; color: inherit;
          box-shadow: 0 4px 14px rgba(22,36,28,.07);
          transition: transform .15s ease; }
  .card:hover { transform: translateY(-2px); }
  .k { font-size: 11px; letter-spacing: 1px; color: #55645B;
       text-transform: uppercase; }
  .t { font-size: 16px; font-weight: 700; margin: 6px 0 2px;
       line-height: 1.3; }
  .a { font-size: 13px; color: #55645B; }
  .o { font-size: 11.5px; color: #2E6B4F; margin-top: 8px; }
  .home { font-size: 13px; color: #2E6B4F; text-decoration: none; }
  .pd { margin-top: 34px; font-size: 12.5px; line-height: 1.6;
        color: #777; border-top: 1px solid #e5e1d5; padding-top: 14px; }
</style></head><body><div class="wrap">
<a class="home" href="/">← hopeling.app</a>
<h1>🖍 The coloring shelf</h1>
<p class="intro">Real wildlife coloring pages, drawn by artists working
with America’s public wildlife agencies - the U.S. Fish &amp; Wildlife
Service and NOAA. As works of the U.S. government they are
<b>public domain</b>: print them, color them, tape them to the fridge.
Each link opens the official PDF or page at its agency’s own home.
Grown-ups: everything here is free and there is nothing to buy.</p>
${cards}
<p class="pd">Curated by Hopeling. All linked works are produced by
U.S. federal agencies and are in the public domain (17 U.S.C. § 105).
Artist credits appear where the agency credits one. Links open at the
official .gov / agency sites; Hopeling hosts none of the files and
claims none of the art. If a link ever goes quiet, tell us through the
app’s “Tell us anything” door and we’ll mend the shelf.</p>
</div></body></html>`);
console.log('coloring shelf: ' +
    SHELF.reduce((n, s) => n + s.items.length, 0) + ' curated works');
