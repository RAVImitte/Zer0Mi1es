// File generated from google-services.json / GoogleService-Info.plist
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'Zer0Mi1es is Android and iOS only.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDqBILhldMyz4PFgQmCCH2-sdEvZQao9IU',
    appId: '1:25186098269:android:f69af41428f01a99f0c1b4',
    messagingSenderId: '25186098269',
    projectId: 'zer0mi1es',
    storageBucket: 'zer0mi1es.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBV3HN_XvNpc1EuonpS57KlCK8om91eMlI',
    appId: '1:25186098269:ios:5d54749cdcc3535cf0c1b4',
    messagingSenderId: '25186098269',
    projectId: 'zer0mi1es',
    storageBucket: 'zer0mi1es.firebasestorage.app',
    iosBundleId: 'com.example.zer0mi1es',
  );
}
