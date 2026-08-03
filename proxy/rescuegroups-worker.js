// Hopeling's adoption proxy - a Cloudflare Worker (free tier),
// backed by RescueGroups.org (nonprofit, API running since 2006).
//
// WHY THIS EXISTS: the API key must never ship inside the app.
// This worker holds it server-side and exposes one read-only
// endpoint. North America coverage, per RescueGroups' data.
// (Petfinder's developer portal is closed as of mid-2026; this
// replaces proxy/petfinder-worker.js, which is kept shelved in
// case it ever reopens. The app-facing response shape is
// identical, so the app does not care which worker answers.)
//
// DEPLOY (one-time, ~15 minutes, no server to maintain):
//   1. Request a free API key: rescuegroups.org/services/
//      adoptable-pet-data-api/ (a short human-reviewed form).
//   2. npm install -g wrangler && wrangler login
//   3. In this folder: wrangler deploy rescuegroups-worker.js \
//        --name hopeling-adopt
//   4. wrangler secret put RESCUEGROUPS_KEY   (paste the key)
//   5. Put the worker URL into `adoptProxy` in
//      app/lib/data/hub.dart and the app lights up.
//
// ENDPOINT (same contract the app already speaks):
//   GET /animals?lat=..&lon=..   -> nearest adoptable animals
//     optional: &type=dog|cat|rabbit|bird  &page=1
//
// The worker never sees users: no cookies, no logging beyond
// Cloudflare's defaults, coordinates arrive already rounded to
// ~2km by the app.

const API = 'https://api.rescuegroups.org/v5';

// the app speaks singular, RescueGroups views are plural
const typeViews = {
  dog: 'dogs',
  cat: 'cats',
  rabbit: 'rabbits',
  bird: 'birds',
};

export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    if (url.pathname !== '/animals') {
      return new Response('hopeling adoption proxy', { status: 200 });
    }
    const lat = parseFloat(url.searchParams.get('lat'));
    const lon = parseFloat(url.searchParams.get('lon'));
    if (!isFinite(lat) || !isFinite(lon)) {
      return json({ error: 'lat and lon required' }, 400);
    }
    const type = url.searchParams.get('type') || '';
    const page = url.searchParams.get('page') || '1';
    const view = typeViews[type];
    const path = '/public/animals/search/available/' +
        (view ? view + '/' : '') + 'haspic/';
    const qs = new URLSearchParams({
      limit: '20',
      page,
      sort: 'distance',
    });
    qs.append('fields[animals]',
        'name,ageGroup,breedPrimary,pictureThumbnailUrl,url');
    qs.append('fields[orgs]', 'citystate');
    qs.append('include', 'orgs,species');
    try {
      const res = await fetch(API + path + '?' + qs, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/vnd.api+json',
          Authorization: env.RESCUEGROUPS_KEY,
        },
        body: JSON.stringify({
          data: { filterRadius: { miles: 40, lat, lon } },
        }),
      });
      if (!res.ok) return json({ error: 'upstream ' + res.status }, 502);
      const j = await res.json();
      // resolve included orgs/species so each animal can carry
      // its shelter city and species name
      const orgs = {};
      const species = {};
      for (const inc of j.included || []) {
        if (inc.type === 'orgs') {
          orgs[inc.id] = (inc.attributes || {}).citystate;
        }
        if (inc.type === 'species') {
          species[inc.id] = (inc.attributes || {}).singular;
        }
      }
      const rel = (a, name) => {
        const r = a.relationships && a.relationships[name];
        const d = r && r.data;
        const first = Array.isArray(d) ? d[0] : d;
        return first && first.id;
      };
      // trim to exactly what the app shows - the same shape the
      // Petfinder worker promised, so the app changes nothing
      const animals = (j.data || []).map((a) => {
        const at = a.attributes || {};
        return {
          id: parseInt(a.id, 10) || 0,
          name: at.name,
          type: species[rel(a, 'species')] || type || '',
          breed: at.breedPrimary,
          age: at.ageGroup,
          photo: at.pictureThumbnailUrl,
          city: orgs[rel(a, 'orgs')],
          url: at.url,
        };
      });
      return json({ animals }, 200, 600);
    } catch (e) {
      return json({ error: 'proxy failure' }, 502);
    }
  },
};

function json(body, status = 200, cacheSecs = 0) {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      'Content-Type': 'application/json',
      'Access-Control-Allow-Origin': '*',
      ...(cacheSecs ? { 'Cache-Control': 'public, max-age=' + cacheSecs } : {}),
    },
  });
}
