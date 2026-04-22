const CACHE_NAME = 'finflow-v1';

// Assets to cache on install
const PRECACHE_ASSETS = [
    '/dashboard',
    '/offline',
];

// ── Install ──────────────────────────────────────────────────────────────────
self.addEventListener('install', (event) => {
    event.waitUntil(
        caches.open(CACHE_NAME).then((cache) => {
            return cache.addAll(PRECACHE_ASSETS).catch(() => {
                // Silently fail if some assets can't be cached during install
            });
        })
    );
    self.skipWaiting();
});

// ── Activate ─────────────────────────────────────────────────────────────────
self.addEventListener('activate', (event) => {
    event.waitUntil(
        caches.keys().then((keys) =>
            Promise.all(
                keys
                    .filter((key) => key !== CACHE_NAME)
                    .map((key) => caches.delete(key))
            )
        )
    );
    self.clients.claim();
});

// ── Fetch ─────────────────────────────────────────────────────────────────────
self.addEventListener('fetch', (event) => {
    const { request } = event;

    // Skip non-GET and chrome-extension requests
    if (request.method !== 'GET') return;
    if (request.url.startsWith('chrome-extension://')) return;

    // Network-first strategy for HTML pages (always fresh data)
    if (request.headers.get('accept')?.includes('text/html')) {
        event.respondWith(
            fetch(request)
                .then((response) => {
                    // Cache a copy
                    const clone = response.clone();
                    caches.open(CACHE_NAME).then((cache) => cache.put(request, clone));
                    return response;
                })
                .catch(() =>
                    caches.match(request).then((cached) => {
                        if (cached) return cached;
                        return caches.match('/offline');
                    })
                )
        );
        return;
    }

    // Cache-first strategy for static assets (CSS, JS, fonts, images)
    if (
        request.url.match(/\.(css|js|woff2?|ttf|eot|svg|png|jpg|jpeg|gif|ico|webp)$/)
    ) {
        event.respondWith(
            caches.match(request).then((cached) => {
                if (cached) return cached;
                return fetch(request).then((response) => {
                    const clone = response.clone();
                    caches.open(CACHE_NAME).then((cache) => cache.put(request, clone));
                    return response;
                });
            })
        );
        return;
    }
});