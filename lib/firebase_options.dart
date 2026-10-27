// GENERATED FILE — do not edit manually.
// Run `flutterfire configure` in your terminal to regenerate this file
// with your actual Firebase project credentials.
//
// Steps:
//   1. Install FlutterFire CLI:  dart pub global activate flutterfire_cli
//   2. Create a Firebase project at https://console.firebase.google.com
//   3. In this project directory run:  flutterfire configure
//   4. Select your Firebase project and target platforms
//   5. This file will be overwritten with real credentials

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not configured for this platform. '
          'Run `flutterfire configure` to generate real credentials.',
        );
    }
  }

  // ⚠️  PLACEHOLDER — replace by running `flutterfire configure`
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'REPLACE_ME',
    appId: 'REPLACE_ME',
    messagingSenderId: 'REPLACE_ME',
    projectId: 'REPLACE_ME',
    authDomain: 'REPLACE_ME',
    storageBucket: 'REPLACE_ME',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDY4tH1rkVbTvz_ToA8sh1xhXaFbOCYj10',
    appId: '1:56764875423:android:1d2c71b983052b846518aa',
    messagingSenderId: '56764875423',
    projectId: 'oneoftwo-4a094',
    storageBucket: 'oneoftwo-4a094.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDK3IsZiRVWDaa-qQ85VQpItEQtYG_Mc6Q',
    appId: '1:56764875423:ios:e0409029a47f47876518aa',
    messagingSenderId: '56764875423',
    projectId: 'oneoftwo-4a094',
    storageBucket: 'oneoftwo-4a094.firebasestorage.app',
    iosBundleId: 'com.example.rememebering',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'REPLACE_ME',
    appId: 'REPLACE_ME',
    messagingSenderId: 'REPLACE_ME',
    projectId: 'REPLACE_ME',
    storageBucket: 'REPLACE_ME',
    iosBundleId: 'REPLACE_ME',
  );
}