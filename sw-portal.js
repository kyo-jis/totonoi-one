const CACHE_NAME = 'portal-v1';
// HTMLはプリキャッシュしない（常に最新を取得、オフライン時のみキャッシュ利用）
const ASSETS = [
  '/manifest-portal.json',
  '/logo.png',
  '/apple-touch-icon-portal.png',
];

self.addEventListener('install', function(e) {
  e.waitUntil(
    caches.open(CACHE_NAME).then(function(c) { return c.addAll(ASSETS); })
  );
  self.skipWaiting();
});

self.addEventListener('activate', function(e) {
  e.waitUntil(
    caches.keys().then(function(keys) {
      return Promise.all(
        keys.filter(function(k) { return k !== CACHE_NAME; })
            .map(function(k) { return caches.delete(k); })
      );
    })
  );
  self.clients.claim();
});

self.addEventListener('fetch', function(e) {
  if (e.request.method !== 'GET') return;
  if (e.request.url.includes('supabase.co')) return;
  if (e.request.url.includes('fonts.googleapis')) return;

  // ネットワーク優先・オフライン時のみキャッシュ
  e.respondWith(
    fetch(e.request).then(function(res) {
      if (res.ok) {
        caches.open(CACHE_NAME).then(function(cache) { cache.put(e.request, res.clone()); });
      }
      return res;
    }).catch(function() {
      return caches.match(e.request);
    })
  );
});
