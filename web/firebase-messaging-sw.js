// Please see this file for the latest firebase-js-sdk version:
// https://github.com/firebase/flutterfire/blob/master/packages/firebase_core/firebase_core_web/lib/src/firebase_sdk_version.dart
importScripts("https://www.gstatic.com/firebasejs/10.11.1/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/10.11.1/firebase-messaging-compat.js");

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

// Optional:
messaging.onBackgroundMessage(async(message) => {
    console.log("onBackgroundMessage", message);
    self.registration.showNotification("ローカル生成タイトル",{body:JSON.stringify(message)});
});

