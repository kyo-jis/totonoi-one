const CACHE_NAME = 'subly-v3';
const ASSETS = [
  '/subly',
  '/subly.html',
  '/manifest-subly.json',
  '/icon-subly-192.png',
  '/icon-subly-512.png',
  '/apple-touch-icon-subly.png',
];

// インストール時にキャッシュ
self.addEventListener('install', function(e) {
  e.waitUntil(
    caches.open(CACHE_NAME).then(function(cache) {
      return cache.addAll(ASSETS);
    })
  );
  self.skipWaiting();
});

// 古いキャッシュを削除
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

// ネットワーク優先・失敗時はキャッシュ
self.addEventListener('fetch', function(e) {
  // Google Fonts・Favicon APIはキャッシュしない
  if (e.request.url.includes('fonts.googleapis') ||
      e.request.url.includes('google.com/s2/favicons')) {
    return;
  }
  e.respondWith(
    fetch(e.request)
      .then(function(res) {
        // 成功したらキャッシュを更新
        var resClone = res.clone();
        caches.open(CACHE_NAME).then(function(cache) {
          cache.put(e.request, resClone);
        });
        return res;
      })
      .catch(function() {
        // オフライン時はキャッシュから返す
        return caches.match(e.request);
      })
  );
});
