'use strict';
const MANIFEST = 'flutter-app-manifest';
const TEMP = 'flutter-temp-cache';
const CACHE_NAME = 'flutter-app-cache';

const RESOURCES = {"assets/AssetManifest.bin": "7fe2d97e6d1ae511446c9d7b1c12e8f6",
"assets/AssetManifest.bin.json": "062c3f34365da3897f0a5f59a9f1966c",
"assets/AssetManifest.json": "e4a8d9752c136179256f1f292e7065e7",
"assets/assets/fonts/Lexend-Black.ttf": "82186656fa6ebf260227c0bb491622a8",
"assets/assets/fonts/Lexend-Bold.ttf": "718f2aad8612745b0ca6eb1d48b37d96",
"assets/assets/fonts/Lexend-ExtraBold.ttf": "76711dcbeffebb272a1bd9e04b11f93a",
"assets/assets/fonts/Lexend-ExtraLight.ttf": "c36b3aef5d8dfdd7abf9c463ef51b383",
"assets/assets/fonts/Lexend-Light.ttf": "cdb31ca1dcb97666830870ed30a842c9",
"assets/assets/fonts/Lexend-Medium.ttf": "15c1a10bfb6fbe6caa9d5592bd890054",
"assets/assets/fonts/Lexend-Regular.ttf": "0d86bcd13a1526d605f31db8d067a37e",
"assets/assets/fonts/Lexend-SemiBold.ttf": "42fd5432a875a34e7cf4e685bdf3e3c9",
"assets/assets/fonts/Lexend-Thin.ttf": "0ca64c3838fda1844ca9dfbc003a9fee",
"assets/assets/images/alert-danger.png": "fa36f3f2e9cf0405dce835ea3eebcce9",
"assets/assets/images/alert-progress.png": "6745a28ea83d2a3cab67ec78ace139d7",
"assets/assets/images/alert-success.png": "de99f6bef88454ec9bde4a96d29bd2fb",
"assets/assets/images/alert-warning.png": "0f37aed7463c1d655bd2fb2df7b51962",
"assets/assets/images/arrow-up-right.png": "a794881f87839a916600000955c47ca2",
"assets/assets/images/askai.png": "f652cf7fdc849c810ef6b7e7904f8170",
"assets/assets/images/bg-1.png": "a8e09292a61abcbb88f795894d3cb286",
"assets/assets/images/bg-10.png": "2433d218c6bf17537d47c5585cef2508",
"assets/assets/images/bg-11.png": "d6f3e230eedf25e769c222f6e0cabeb8",
"assets/assets/images/bg-12.png": "3c2c53628d7021c7e8b2cc3d442f2115",
"assets/assets/images/bg-2.png": "71791d59b22cf65336de280a9f8289f4",
"assets/assets/images/bg-3.png": "84e8b25ad0dd173faefcd25871f4ada2",
"assets/assets/images/bg-4.png": "3b35b317ddfdecc68b0a10dece251234",
"assets/assets/images/bg-5.png": "1b3693bad35f2280c3d818c25cd45973",
"assets/assets/images/bg-6.png": "f443897f3ea0169187a96970b9131c52",
"assets/assets/images/bg-7.png": "d84127da021465c410a219cacf3b1076",
"assets/assets/images/bg-8.png": "a0bae95e9951bdc95f481f4af993d807",
"assets/assets/images/bg-9.png": "51c258ddf4c2c02d22e27f056eb1fd72",
"assets/assets/images/check.png": "465c412212c543d1e35f3aaee7d688a3",
"assets/assets/images/create-issue.png": "70a999312c3439bcd6cd192ce796b6e7",
"assets/assets/images/cycle.png": "8244f1222d8a46906d31f7e9acc56013",
"assets/assets/images/done-blue.png": "cd6ac24f3168495147021023f5242523",
"assets/assets/images/done-green.png": "aebc85c467beffa76d625aa2831f6276",
"assets/assets/images/done.png": "e832c16089a769f492de3c22366694ca",
"assets/assets/images/edit-gray.png": "b3747137312fd5260745fe022fac00c7",
"assets/assets/images/edit-green.png": "cc4a00865e990d74683529e017312bb8",
"assets/assets/images/edit-issue.png": "a6799ccfc2b94d088dfc8b847700bb9a",
"assets/assets/images/export-green.png": "2bb6201b0d463114689a76509a06cb2f",
"assets/assets/images/eye-close.png": "c50f2adf671efef65ca9ee4d2291649c",
"assets/assets/images/eye-open.png": "8a9a0148ace3b4d693a329815304f21d",
"assets/assets/images/factory-background.png": "1f1529642ca4e49f7d0af5693af864fc",
"assets/assets/images/fat.png": "8d03f1c0e5ad512aa88ddc15408ef7ab",
"assets/assets/images/filter-gray.png": "1d0514b76e27ad04dfd36248aedba595",
"assets/assets/images/filter-green.png": "f3ba18b4119c818a23f8add0fe9d2b7f",
"assets/assets/images/graph.png": "1ca0fca578f856ecae6edf704267d983",
"assets/assets/images/import-export-green.png": "0dca690297a67015c1bc540bb3c8c603",
"assets/assets/images/import-green.png": "7b92e1fc38847db3a35175de865b30b4",
"assets/assets/images/in.png": "49da34b6a9f590290d81ad1a0f3d1140",
"assets/assets/images/issue-no.png": "70e6d2ffb565a51a58adbbdf84416430",
"assets/assets/images/issue-yes.png": "084fdef8683c619d375563d383a0ae83",
"assets/assets/images/logo.jpeg": "8c6e3314a34ba07bd7663f37d8a54121",
"assets/assets/images/logo.png": "fee01847472d837e2a1f73cfe6a71ae0",
"assets/assets/images/logout.png": "d95a4e27012689d96a45f8073519d5b8",
"assets/assets/images/logo_app.jpeg": "8c6e3314a34ba07bd7663f37d8a54121",
"assets/assets/images/logo_app.png": "6222cdacae2a417cb31dde15da82c788",
"assets/assets/images/mail-config.png": "dafe8e81e62b2d7738dc1a161f933854",
"assets/assets/images/menu-close.png": "1c30f923461626596e8a509a1b24272f",
"assets/assets/images/menu-open.png": "ecee8fffb612f9bd2a5487c4ec78f72a",
"assets/assets/images/message.png": "6f3095856fdc5a6dac927de3d568efd8",
"assets/assets/images/new-yellow.png": "2b9fb0499d2e2dc78eac8591f0caab22",
"assets/assets/images/no-status-gray.png": "ea7f6ae7a95a8062c8be2e20f1a73154",
"assets/assets/images/office.png": "00aa5f268e19df0e41311306b4099772",
"assets/assets/images/on-block-red.png": "aeeb4732e12156a67c473a917207f7fc",
"assets/assets/images/on-progress-blue.png": "4d0fa41c5b21ad7e4da928920e70428a",
"assets/assets/images/out.png": "9cc47ab98efadc2d270ddcd674d3c7f1",
"assets/assets/images/package.png": "dfd98bd4ba4c82dd6ea1f8e5ccdc87e2",
"assets/assets/images/panel-off.png": "9290eea8fc375dcff93740bae60a4517",
"assets/assets/images/panel-on.png": "eaa8b4b57810d851155bc9a4f5cf67b5",
"assets/assets/images/panel.png": "45e0b5cd9d161856e30bfdde8e82536b",
"assets/assets/images/plus.png": "30dbe62ba6d65c957e58d4ffea027c14",
"assets/assets/images/production.png": "03dba1b8fa137c9e43b377c70736f946",
"assets/assets/images/profile-off.png": "9924cb469dffaba969adeea8e63f355a",
"assets/assets/images/profile-on.png": "978758ba8a01b465aefc0f48d87d9474",
"assets/assets/images/progress-bolt-blue.png": "3affece9f3da39a67367c8ba7e39b0e6",
"assets/assets/images/progress-bolt-green.png": "3e0e3586b3d6bc498a49121397fc7510",
"assets/assets/images/progress-bolt-orange.png": "c47dde531db63af6557cb96ca4a0287c",
"assets/assets/images/progress-bolt-red.png": "fe618ce1b571784210edb251ced24fbf",
"assets/assets/images/progress_load.png": "6c093b78f06d0a8267549351176480cc",
"assets/assets/images/remarks.png": "0c85201da5002e4402f8853a82e6d2a6",
"assets/assets/images/reopen-issue.png": "18012754dc1202146d4fc970a9cd4822",
"assets/assets/images/send-chat.png": "0fdb51bff5b4017e4e5b29a3d79f7dd7",
"assets/assets/images/send.png": "3cd4fb6978f93512f40a7b8fafcc92ae",
"assets/assets/images/solve-issue.png": "102fc4f0ffc14bcb6fa78e82d28f08c0",
"assets/assets/images/Transfer%2520to%2520FAT.png": "b58ec32ba25684fdfe962e773e7a9b12",
"assets/assets/images/Transfer%2520to%2520Production.png": "189ca9fad761f764cdf44a5c31ce1362",
"assets/assets/images/Transfer%2520to%2520Warehouse.png": "154207cd1396964ce72b14bcc2b110a8",
"assets/assets/images/trash.png": "e75e1ad46b0dfd15886093d20e011efc",
"assets/assets/images/uncheck.png": "4dcdf2de42aca7f545554ad04d6d8d9e",
"assets/assets/images/user.png": "fa73b20ace593797dbac78e4ef0d9fe8",
"assets/assets/images/vendor.png": "db42c318fba2aa5843233842171b8161",
"assets/assets/images/view-detail.png": "99f153c09f7553dfdb1fa4ea601a882e",
"assets/assets/images/warehouse.png": "0e864dba03839a6dd198b795ccf2dd56",
"assets/assets/videos/factory-background.gif": "b25bf558d665552afd1a3d7334ebedee",
"assets/assets/videos/factory-background.mp4": "f0acf86af5be4cd7fa3dc9a7e87731fc",
"assets/FontManifest.json": "4223046c222ee08b0a7928309a162848",
"assets/fonts/MaterialIcons-Regular.otf": "f2fc827a58784c21974779cc9e3de3dd",
"assets/NOTICES": "9d16466a33b0038ee367bc4f68d32f52",
"assets/packages/cupertino_icons/assets/CupertinoIcons.ttf": "33b7d9392238c04c131b6ce224e13711",
"assets/shaders/ink_sparkle.frag": "ecc85a2e95f5e9f53123dcaf8cb9b6ce",
"canvaskit/canvaskit.js": "728b2d477d9b8c14593d4f9b82b484f3",
"canvaskit/canvaskit.js.symbols": "bdcd3835edf8586b6d6edfce8749fb77",
"canvaskit/canvaskit.wasm": "7a3f4ae7d65fc1de6a6e7ddd3224bc93",
"canvaskit/chromium/canvaskit.js": "8191e843020c832c9cf8852a4b909d4c",
"canvaskit/chromium/canvaskit.js.symbols": "b61b5f4673c9698029fa0a746a9ad581",
"canvaskit/chromium/canvaskit.wasm": "f504de372e31c8031018a9ec0a9ef5f0",
"canvaskit/skwasm.js": "ea559890a088fe28b4ddf70e17e60052",
"canvaskit/skwasm.js.symbols": "e72c79950c8a8483d826a7f0560573a1",
"canvaskit/skwasm.wasm": "39dd80367a4e71582d234948adc521c0",
"favicon.png": "5dcef449791fa27946b3d35ad8803796",
"flutter.js": "83d881c1dbb6d6bcd6b42e274605b69c",
"flutter_bootstrap.js": "e78e9659e9761881a62eb7fb18755bf3",
"icons/Icon-192.png": "ac9a721a12bbc803b44f645561ecb1e1",
"icons/Icon-512.png": "96e752610906ba2a93c65f8abe1645f1",
"icons/Icon-maskable-192.png": "c457ef57daa1d16f64b27b786ec2ea3c",
"icons/Icon-maskable-512.png": "301a7604d45b3e739efc881eb04896ea",
"icons/logo_app.jpeg": "8c6e3314a34ba07bd7663f37d8a54121",
"index.html": "f88b44cf66297cd909cb419ddd4022cf",
"/": "f88b44cf66297cd909cb419ddd4022cf",
"main.dart.js": "f480664a63e61ba7108ba882640f59b8",
"manifest.json": "6c6aa9029f3e1c8c14b4d743faab9e12",
"version.json": "2cbb8f86cf2ac6463741ba740564e528"};
// The application shell files that are downloaded before a service worker can
// start.
const CORE = ["main.dart.js",
"index.html",
"flutter_bootstrap.js",
"assets/AssetManifest.bin.json",
"assets/FontManifest.json"];

// During install, the TEMP cache is populated with the application shell files.
self.addEventListener("install", (event) => {
  self.skipWaiting();
  return event.waitUntil(
    caches.open(TEMP).then((cache) => {
      return cache.addAll(
        CORE.map((value) => new Request(value, {'cache': 'reload'})));
    })
  );
});
// During activate, the cache is populated with the temp files downloaded in
// install. If this service worker is upgrading from one with a saved
// MANIFEST, then use this to retain unchanged resource files.
self.addEventListener("activate", function(event) {
  return event.waitUntil(async function() {
    try {
      var contentCache = await caches.open(CACHE_NAME);
      var tempCache = await caches.open(TEMP);
      var manifestCache = await caches.open(MANIFEST);
      var manifest = await manifestCache.match('manifest');
      // When there is no prior manifest, clear the entire cache.
      if (!manifest) {
        await caches.delete(CACHE_NAME);
        contentCache = await caches.open(CACHE_NAME);
        for (var request of await tempCache.keys()) {
          var response = await tempCache.match(request);
          await contentCache.put(request, response);
        }
        await caches.delete(TEMP);
        // Save the manifest to make future upgrades efficient.
        await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
        // Claim client to enable caching on first launch
        self.clients.claim();
        return;
      }
      var oldManifest = await manifest.json();
      var origin = self.location.origin;
      for (var request of await contentCache.keys()) {
        var key = request.url.substring(origin.length + 1);
        if (key == "") {
          key = "/";
        }
        // If a resource from the old manifest is not in the new cache, or if
        // the MD5 sum has changed, delete it. Otherwise the resource is left
        // in the cache and can be reused by the new service worker.
        if (!RESOURCES[key] || RESOURCES[key] != oldManifest[key]) {
          await contentCache.delete(request);
        }
      }
      // Populate the cache with the app shell TEMP files, potentially overwriting
      // cache files preserved above.
      for (var request of await tempCache.keys()) {
        var response = await tempCache.match(request);
        await contentCache.put(request, response);
      }
      await caches.delete(TEMP);
      // Save the manifest to make future upgrades efficient.
      await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
      // Claim client to enable caching on first launch
      self.clients.claim();
      return;
    } catch (err) {
      // On an unhandled exception the state of the cache cannot be guaranteed.
      console.error('Failed to upgrade service worker: ' + err);
      await caches.delete(CACHE_NAME);
      await caches.delete(TEMP);
      await caches.delete(MANIFEST);
    }
  }());
});
// The fetch handler redirects requests for RESOURCE files to the service
// worker cache.
self.addEventListener("fetch", (event) => {
  if (event.request.method !== 'GET') {
    return;
  }
  var origin = self.location.origin;
  var key = event.request.url.substring(origin.length + 1);
  // Redirect URLs to the index.html
  if (key.indexOf('?v=') != -1) {
    key = key.split('?v=')[0];
  }
  if (event.request.url == origin || event.request.url.startsWith(origin + '/#') || key == '') {
    key = '/';
  }
  // If the URL is not the RESOURCE list then return to signal that the
  // browser should take over.
  if (!RESOURCES[key]) {
    return;
  }
  // If the URL is the index.html, perform an online-first request.
  if (key == '/') {
    return onlineFirst(event);
  }
  event.respondWith(caches.open(CACHE_NAME)
    .then((cache) =>  {
      return cache.match(event.request).then((response) => {
        // Either respond with the cached resource, or perform a fetch and
        // lazily populate the cache only if the resource was successfully fetched.
        return response || fetch(event.request).then((response) => {
          if (response && Boolean(response.ok)) {
            cache.put(event.request, response.clone());
          }
          return response;
        });
      })
    })
  );
});
self.addEventListener('message', (event) => {
  // SkipWaiting can be used to immediately activate a waiting service worker.
  // This will also require a page refresh triggered by the main worker.
  if (event.data === 'skipWaiting') {
    self.skipWaiting();
    return;
  }
  if (event.data === 'downloadOffline') {
    downloadOffline();
    return;
  }
});
// Download offline will check the RESOURCES for all files not in the cache
// and populate them.
async function downloadOffline() {
  var resources = [];
  var contentCache = await caches.open(CACHE_NAME);
  var currentContent = {};
  for (var request of await contentCache.keys()) {
    var key = request.url.substring(origin.length + 1);
    if (key == "") {
      key = "/";
    }
    currentContent[key] = true;
  }
  for (var resourceKey of Object.keys(RESOURCES)) {
    if (!currentContent[resourceKey]) {
      resources.push(resourceKey);
    }
  }
  return contentCache.addAll(resources);
}
// Attempt to download the resource online before falling back to
// the offline cache.
function onlineFirst(event) {
  return event.respondWith(
    fetch(event.request).then((response) => {
      return caches.open(CACHE_NAME).then((cache) => {
        cache.put(event.request, response.clone());
        return response;
      });
    }).catch((error) => {
      return caches.open(CACHE_NAME).then((cache) => {
        return cache.match(event.request).then((response) => {
          if (response != null) {
            return response;
          }
          throw error;
        });
      });
    })
  );
}
