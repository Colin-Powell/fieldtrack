importScripts('https://www.gstatic.com/firebasejs/10.13.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.13.0/firebase-messaging-compat.js');

const firebaseConfig = {
  apiKey: 'AIzaSyDh4CUIZH4BuS2FOJSdNevbSXxaFXkbRb8',
  authDomain: 'fieldtrack-ba6f7.firebaseapp.com',
  projectId: 'fieldtrack-ba6f7',
  storageBucket: 'fieldtrack-ba6f7.firebasestorage.app',
  messagingSenderId: '634022886076',
  appId: '1:634022886076:web:91f2fc372eb2ba31e7eeb9',
  measurementId: 'G-6JYX73LEKH',
};

firebase.initializeApp(firebaseConfig);
const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  const title = payload?.notification?.title || 'FieldTrack Notification';
  const body = payload?.notification?.body || 'You have a new update';

  self.clients.matchAll({ type: 'window', includeUncontrolled: true }).then((clients) => {
    clients.forEach((client) => client.postMessage({
      type: 'FCM_BACKGROUND_MESSAGE',
      payload,
    }));
  });

  return self.registration.showNotification(title, {
    body,
    icon: '/icons/Icon-192.png',
    tag: 'fieldtrack-notification',
  });
});
