'use strict';
const CACHE_NAME = 'flutter-app-cache';
const RESOURCES = {
  "index.html": "926cd8008bef60a4e735ba8d18fbac9c",
"/": "926cd8008bef60a4e735ba8d18fbac9c",
"icons/Icon-512.png": "96e752610906ba2a93c65f8abe1645f1",
"icons/Icon-192.png": "ac9a721a12bbc803b44f645561ecb1e1",
"assets/packages/cupertino_icons/assets/CupertinoIcons.ttf": "115e937bb829a890521f72d2e664b632",
"assets/packages/open_iconic_flutter/assets/open-iconic.woff": "3cf97837524dd7445e9d1462e3c4afe2",
"assets/assets/demo_zh.md": "d58d1dd247dfb3a148b748f06a04542d",
"assets/assets/demo_en.md": "6a26abd3e005b0ea6532b66fc4e4eab5",
"assets/assets/editor.md": "a141965a59ebc1620c6e17aef2c204bf",
"assets/FontManifest.json": "96880f5cbd12a15751331cdbdac93202",
"assets/fonts/MaterialIcons-Regular.ttf": "56d3ffdef7a25659eab6a68a3fbfaf16",
"assets/AssetManifest.json": "9e4288fc8bf78d02dd0e2550fd39829c",
"assets/LICENSE": "d16e167e18faeb500f2f8165fb078f6d",
"favicon.png": "5dcef449791fa27946b3d35ad8803796",
"main.dart.js": "9a316db47d983ad2cc109eca255ac5f7",
"manifest.json": "00e0b69b49487ce4f9ff0c5fac8fda49"
};

self.addEventListener('activate', function (event) {
  event.waitUntil(
    caches.keys().then(function (cacheName) {
      return caches.delete(cacheName);
    }).then(function (_) {
      return caches.open(CACHE_NAME);
    }).then(function (cache) {
      return cache.addAll(Object.keys(RESOURCES));
    })
  );
});

self.addEventListener('fetch', function (event) {
  event.respondWith(
    caches.match(event.request)
      .then(function (response) {
        if (response) {
          return response;
        }
        return fetch(event.request);
      })
  );
});
