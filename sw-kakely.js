const CACHE_NAME = 'kakely-v3';
const ASSETS = [
  '/kakely.html',
  '/kakely',
  '/manifest-kakely.json',
  '/icon-kakely-192.png',
  '/icon-kakely-512.png',
  '/apple-touch-icon-kakely.png',
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
  // APIリクエスト・POST等はキャッシュしない
  if (e.request.method !== 'GET') return;
  if (e.request.url.includes('supabase.co')) return;
  if (e.request.url.includes('fonts.googleapis')) return;

  // ネットワーク優先・失敗時にキャッシュ
  e.respondWith(
    caches.open(CACHE_NAME).then(function(cache) {
      return fetch(e.request).then(function(res) {
        if (res.ok) cache.put(e.request, res.clone());
        return res;
      }).catch(function() {
        return cache.match(e.request);
      });
    })
  );
});
