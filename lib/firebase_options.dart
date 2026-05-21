import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
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
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  /// Check if the configuration has been updated by the developer.
  static bool get isConfigured {
    try {
      final opts = currentPlatform;
      return !opts.apiKey.startsWith('YOUR_');
    } catch (_) {
      return false;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBvK9Z6SHrQJz75VWAbfOHl9VEPgB-Q0iU',
    appId: '1:411634199591:web:229637c7fc55d5b3953202',
    messagingSenderId: '411634199591',
    projectId: 'neurostep-4f857',
    authDomain: 'neurostep-4f857.firebaseapp.com',
    storageBucket: 'neurostep-4f857.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'YOUR_ANDROID_API_KEY',
    appId: 'YOUR_ANDROID_APP_ID',
    messagingSenderId: 'YOUR_ANDROID_MESSAGING_SENDER_ID',
    projectId: 'YOUR_ANDROID_PROJECT_ID',
    storageBucket: 'YOUR_ANDROID_PROJECT_ID.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'YOUR_IOS_API_KEY',
    appId: 'YOUR_IOS_APP_ID',
    messagingSenderId: 'YOUR_IOS_MESSAGING_SENDER_ID',
    projectId: 'YOUR_IOS_PROJECT_ID',
    storageBucket: 'YOUR_IOS_PROJECT_ID.appspot.com',
    iosBundleId: 'com.parkinsonsai.parkinsonInsoleApp',
  );
}
