import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      case TargetPlatform.fuchsia:
        throw UnsupportedError(
          'Firebase options are configured for Web and Android only.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBUVjdoNmRKUt7CcF1TjZowIoDni9EKAv4',
    appId: '1:724891959035:web:b3d67676774f93d1397a5e',
    messagingSenderId: '724891959035',
    projectId: 'myumrahguide-nisa',
    authDomain: 'myumrahguide-nisa.firebaseapp.com',
    storageBucket: 'myumrahguide-nisa.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCsmxHBoisJ-nndhbDUVlrNAvJWPDcPBtE',
    appId: '1:724891959035:android:cead9a698ca3676f397a5e',
    messagingSenderId: '724891959035',
    projectId: 'myumrahguide-nisa',
    storageBucket: 'myumrahguide-nisa.firebasestorage.app',
  );
}
