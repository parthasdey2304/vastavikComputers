import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
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
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
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
    apiKey: 'AIzaSyA-MOCK-API-KEY-FOR-WEB',
    appId: '1:123456789:web:abcdef',
    messagingSenderId: '123456789',
    projectId: 'vastavik-mock-project',
    authDomain: 'vastavik-mock-project.firebaseapp.com',
    storageBucket: 'vastavik-mock-project.appspot.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyA-MOCK-API-KEY-FOR-ANDROID',
    appId: '1:123456789:android:abcdef',
    messagingSenderId: '123456789',
    projectId: 'vastavik-mock-project',
    storageBucket: 'vastavik-mock-project.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyA-MOCK-API-KEY-FOR-IOS',
    appId: '1:123456789:ios:abcdef',
    messagingSenderId: '123456789',
    projectId: 'vastavik-mock-project',
    storageBucket: 'vastavik-mock-project.appspot.com',
    iosBundleId: 'com.example.vastavikComputers',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyA-MOCK-API-KEY-FOR-MACOS',
    appId: '1:123456789:ios:abcdef',
    messagingSenderId: '123456789',
    projectId: 'vastavik-mock-project',
    storageBucket: 'vastavik-mock-project.appspot.com',
    iosBundleId: 'com.example.vastavikComputers',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyA-MOCK-API-KEY-FOR-WINDOWS',
    appId: '1:123456789:web:abcdef',
    messagingSenderId: '123456789',
    projectId: 'vastavik-mock-project',
    authDomain: 'vastavik-mock-project.firebaseapp.com',
    storageBucket: 'vastavik-mock-project.appspot.com',
  );
}
