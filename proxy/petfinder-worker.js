// Hopeling's Petfinder proxy - a Cloudflare Worker (~free tier).
//
// WHY THIS EXISTS: Petfinder's API needs an OAuth client secret,
// and secrets must never ship inside the app. This tiny worker
// holds the keys server-side, caches the token, and exposes one
// read-only endpoint the app can call. North America only, by
// Petfinder's own coverage.
//
// DEPLOY (one-time, ~15 minutes, no server to maintain):
//   1. Sign up at www.petfinder.com/developers (a normal Petfinder
//      account, then Developer Settings). Basic access is granted
//      automatically: 1,000 requests/day, free. App name
//      "Hopeling", URL "https://hopeling.app".
//   2. npm install -g wrangler && wrangler login
//   3. In this folder: wrangler deploy petfinder-worker.js \
//        --name hopeling-petfinder
//   4. wrangler secret put PETFINDER_ID
//      wrangler secret put PETFINDER_SECRET
//   5. Put the worker URL into `petfinderProxy` in
//      app/lib/data/hub.dart and the app lights up.
//
// ENDPOINT:
//   GET /animals?lat=..&lon=..   -> nearest adoptable animals
//     optional: &type=dog|cat|rabbit|bird  &page=1
//
// The worker never sees users: no cookies, no logging of query
// params beyond Cloudflare's defaults, coordinates arrive already
// rounded to ~2km by the app.

let tokenCache = { token: null, expires: 0 };

async function getToken(env) {
  if (tokenCache.token && Date.now() < tokenCache.expires - 60000) {
    return tokenCache.token;
  }
  const res = await fetch('https://api.petfinder.com/v2/oauth2/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: 'grant_type=client_credentials' +
        '&client_id=' + encodeURIComponent(env.PETFINDER_ID) +
        '&client_secret=' + encodeURIComponent(env.PETFINDER_SECRET),
  });
  if (!res.ok) throw new Error('token ' + res.status);
  const j = await res.json();
  tokenCache = {
    token: j.access_token,
    expires: Date.now() + (j.expires_in || 3600) * 1000,
  };
  return tokenCache.token;
}

export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    if (url.pathname !== '/animals') {
      return new Response('hopeling petfinder proxy', { status: 200 });
    }
    const lat = parseFloat(url.searchParams.get('lat'));
    const lon = parseFloat(url.searchParams.get('lon'));
    if (!isFinite(lat) || !isFinite(lon)) {
      return json({ error: 'lat and lon required' }, 400);
    }
    const type = url.searchParams.get('type') || '';
    const page = url.searchParams.get('page') || '1';
    try {
      const token = await getToken(env);
      const qs = new URLSearchParams({
        location: lat.toFixed(2) + ',' + lon.toFixed(2),
        distance: '40',
        sort: 'distance',
        limit: '20',
        page,
        status: 'adoptable',
      });
      if (type) qs.set('type', type);
      const res = await fetch(
          'https://api.petfinder.com/v2/animals?' + qs, {
            headers: { Authorization: 'Bearer ' + token },
          });
      if (!res.ok) return json({ error: 'upstream ' + res.status }, 502);
      const j = await res.json();
      // trim to exactly what the app shows - smaller, kinder, and
      // no accidental leakage of fields we never audited
      const animals = (j.animals || []).map((a) => ({
        id: a.id,
        name: a.name,
        type: a.type,
        breed: a.breeds && a.breeds.primary,
        age: a.age,
        photo: a.primary_photo_cropped && a.primary_photo_cropped.medium,
        city: a.contact && a.contact.address && a.contact.address.city,
        url: a.url,
      }));
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
