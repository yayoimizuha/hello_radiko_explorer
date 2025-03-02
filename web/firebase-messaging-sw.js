importScripts("https://www.gstatic.com/firebasejs/10.11.1/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/10.11.1/firebase-messaging-compat.js");

console.log('Service Worker script loaded.');

self.addEventListener('install', (event) => {
    console.log('Service Worker installing...');
    self.skipWaiting();
});

self.addEventListener('activate', (event) => {
    console.log('Service Worker activating...');
    event.waitUntil(self.clients.claim());
});

firebase.initializeApp({
    apiKey: "AIzaSyBnLBxvDm_LH1dYDZAaqoPs5R4q6iFcjlc",
    authDomain: "hello-radiko.firebaseapp.com",
    projectId: "hello-radiko",
    storageBucket: "hello-radiko.firebasestorage.app",
    messagingSenderId: "872135031945",
    appId: "1:872135031945:web:40402bd368daf0af2dda58",
    measurementId: "G-4JV8NZXGWZ"
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage(async (payload) => {
    console.log("payload.data=", payload.data);
    console.log("onBackgroundMessage", payload);
    var db_req = indexedDB.open("subscribed");
    db_req.onsuccess = function () {
        var db = db_req.result;
        var transaction = db.transaction("entry", 'readonly');
        var store = transaction.objectStore("entry");
        var values_req = store.getAll();
        values_req.onsuccess = function () {
            var values = values_req.result;
            for (var _i = 0, values_1 = values; _i < values_1.length; _i++) {
                var value = values_1[_i];
                console.log(value);
                try {
                    var data_payload = value;
                    if (data_payload["key"] == "subscribed") {
                        var subscribed_member = data_payload["value"].split(",");
                        var matched_member = [];
                        for (var _a = 0, _b = payload.data["target"].split(","); _a < _b.length; _a++) {
                            var target_member = _b[_a];
                            console.log("target_member=", target_member);
                            if (subscribed_member.includes(target_member)) {
                                matched_member.push(target_member);
                            }
                        }
                        console.log("matched_member=", matched_member);
                        if (matched_member.length == 0) {
                            return;
                        }
                        self.registration.showNotification(payload.data["title"] + "が間もなく始まります。", { body: matched_member.join(",") + "が出演します。\n" + payload.data["ft"] + "～" });
                    }
                }
                catch (error) {
                    console.error(error);
                }
            }
        };
    };
});