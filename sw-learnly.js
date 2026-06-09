const CACHE_NAME = 'learnly-v2';
const ASSETS = [
  '/learnly',
  '/learnly.html',
  '/manifest-learnly.json',
];

self.addEventListener('install', function(e) {
  e.waitUntil(caches.open(CACHE_NAME).then(function(cache) { return cache.addAll(ASSETS); }));
  self.skipWaiting();
});

self.addEventListener('activate', function(e) {
  e.waitUntil(caches.keys().then(function(keys) {
    return Promise.all(keys.filter(function(k){ return k !== CACHE_NAME; }).map(function(k){ return caches.delete(k); }));
  }));
  self.clients.claim();
});

self.addEventListener('fetch', function(e) {
  if (e.request.url.includes('fonts.googleapis') || e.request.url.includes('google.com/s2/favicons')) return;
  e.respondWith(
    fetch(e.request).then(function(res) {
      var clone = res.clone();
      caches.open(CACHE_NAME).then(function(cache){ cache.put(e.request, clone); });
      return res;
    }).catch(function(){ return caches.match(e.request); })
  );
});
