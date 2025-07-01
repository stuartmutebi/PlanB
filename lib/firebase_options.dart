import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyASlcfID4YEfWpgMmx2eiBegDTBpUqPyuo',
    appId: '1:888519882525:web:e028719ffccaee04e2d3f4',
    messagingSenderId: '888519882525',
    projectId: 'lost-and-found-6678f',
    authDomain: 'lost-and-found-6678f.firebaseapp.com',
    storageBucket: 'lost-and-found-6678f.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDHAQzewb-jP23BbgKO1Eqt55duI_Yq2aw',
    appId: '1:888519882525:android:48d3b2c6703de890e2d3f4',
    messagingSenderId: '888519882525',
    projectId: 'lost-and-found-6678f',
    storageBucket: 'lost-and-found-6678f.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyA3E95smOSps_X5MXWkXNBZOwnw2tkVEU4',
    appId: '1:888519882525:ios:d573159e701cdc6ee2d3f4',
    messagingSenderId: '888519882525',
    projectId: 'lost-and-found-6678f',
    storageBucket: 'lost-and-found-6678f.firebasestorage.app',
    iosBundleId: 'com.example.lostandfound',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'YOUR-MACOS-API-KEY',
    appId: 'YOUR-MACOS-APP-ID',
    messagingSenderId: 'YOUR-SENDER-ID',
    projectId: 'YOUR-PROJECT-ID',
    storageBucket: 'YOUR-STORAGE-BUCKET',
    iosClientId: 'YOUR-MACOS-CLIENT-ID',
    iosBundleId: 'YOUR-MACOS-BUNDLE-ID',
  );
} 