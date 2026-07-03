/* WildHope service worker — offline-first shell + self-updating content.
   Bump CACHE when you change cached shell files. content.json is network-first
   so content updates propagate without an app update. */
const CACHE = 'wildhope-v9';
const SHELL = [
  './WildHope.html', './manifest.json', './content.json',
  './icon-192.png', './icon-512.png', './icon-maskable.png', './apple-touch-icon.png'
];

self.addEventListener('install', (e) => {
  e.waitUntil(caches.open(CACHE).then((c) => c.addAll(SHELL)).then(() => self.skipWaiting()));
});

self.addEventListener('activate', (e) => {
  e.waitUntil(
    caches.keys().then((keys) => Promise.all(keys.filter((k) => k !== CACHE).map((k) => caches.delete(k))))
      .then(() => self.clients.claim())
  );
});

self.addEventListener('fetch', (e) => {
  const req = e.request;
  if (req.method !== 'GET') return;
  const url = new URL(req.url);

  // cross-origin (Wikipedia, GBIF, analytics) → let the browser handle it;
  // the app caches what it needs in localStorage itself.
  if (url.origin !== location.origin) return;

  // content.json → network-first so the latest content wins; fall back to cache offline.
  if (url.pathname.endsWith('/content.json') || url.pathname.endsWith('content.json')) {
    e.respondWith(
      fetch(req).then((res) => {
        const copy = res.clone();
        caches.open(CACHE).then((c) => c.put('./content.json', copy)).catch(() => {});
        return res;
      }).catch(() => caches.match('./content.json'))
    );
    return;
  }

  // everything else → cache-first (offline app shell), network fallback.
  e.respondWith(
    caches.match(req).then((cached) => cached || fetch(req).then((res) => {
      const copy = res.clone();
      caches.open(CACHE).then((c) => c.put(req, copy)).catch(() => {});
      return res;
    }).catch(() => caches.match('./WildHope.html')))
  );
});
