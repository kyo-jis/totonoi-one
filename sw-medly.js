const CACHE_NAME = 'medly-v3';
const ASSETS = ['/medly','/medly.html','/manifest-medly.json','/icon-medly-192.png','/icon-medly-512.png'];
self.addEventListener('install', function(e) { e.waitUntil(caches.open(CACHE_NAME).then(function(c){ return c.addAll(ASSETS); })); self.skipWaiting(); });
self.addEventListener('activate', function(e) { e.waitUntil(caches.keys().then(function(keys){ return Promise.all(keys.filter(function(k){ return k!==CACHE_NAME; }).map(function(k){ return caches.delete(k); })); })); self.clients.claim(); });
self.addEventListener('fetch', function(e) { e.respondWith(fetch(e.request).then(function(r){ caches.open(CACHE_NAME).then(function(c){ c.put(e.request,r.clone()); }); return r; }).catch(function(){ return caches.match(e.request); })); });