import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }

    throw UnsupportedError(
      'DefaultFirebaseOptions are not supported for this platform.',
    );
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDh4CUIZH4BuS2FOJSdNevbSXxaFXkbRb8',
    appId: '1:634022886076:web:91f2fc372eb2ba31e7eeb9',
    messagingSenderId: '634022886076',
    projectId: 'fieldtrack-ba6f7',
    authDomain: 'fieldtrack-ba6f7.firebaseapp.com',
    storageBucket: 'fieldtrack-ba6f7.firebasestorage.app',
    measurementId: 'G-6JYX73LEKH',
  );
}
