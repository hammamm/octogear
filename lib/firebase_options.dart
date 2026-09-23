// Android Firebase configuration for the OctoGear Firebase project.
// Regenerate this file with `flutterfire configure --platforms=android` after
// authenticating the Firebase CLI. Do not add another platform here until it
// is configured for the OctoGear project.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError('Firebase has not been configured for web.');
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        throw UnsupportedError('Firebase has not been configured for iOS.');
      case TargetPlatform.macOS:
        throw UnsupportedError('Firebase has not been configured for macOS.');
      case TargetPlatform.windows:
        throw UnsupportedError('Firebase has not been configured for Windows.');
      case TargetPlatform.linux:
        throw UnsupportedError('Firebase has not been configured for Linux.');
      default:
        throw UnsupportedError('Firebase is not supported for this platform.');
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDvV77qO8wHEpblFX6x5-g3zwsYJQHiEEA',
    appId: '1:22022700786:android:5861d760336ec2205c5a6b',
    messagingSenderId: '22022700786',
    projectId: 'octogear-1d72b',
    storageBucket: 'octogear-1d72b.firebasestorage.app',
  );
}
