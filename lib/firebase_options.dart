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
    apiKey: 'AIzaSyDMAAE4J9i0hE6CrLpG3RXCWulWjBLoyXk',
    appId: '1:1088021463056:web:6ebaed5dd2bb412203ca95',
    messagingSenderId: '1088021463056',
    projectId: 'vastavik-computers',
    authDomain: 'vastavik-computers.firebaseapp.com',
    storageBucket: 'vastavik-computers.firebasestorage.app',
    measurementId: 'G-CXVMH59V0S',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBI2_Fpcdy3UNNDdJ2q4qb3OYwuY_mx0oo',
    appId: '1:1088021463056:android:06b0ac472699d45b03ca95',
    messagingSenderId: '1088021463056',
    projectId: 'vastavik-computers',
    storageBucket: 'vastavik-computers.firebasestorage.app',
  );
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAaiya3XEUAF6wiOmW_GfqYkCAMNwv3_jw',
    appId: '1:1088021463056:ios:6160a23fb4f948fd03ca95',
    messagingSenderId: '1088021463056',
    projectId: 'vastavik-computers',
    storageBucket: 'vastavik-computers.firebasestorage.app',
    iosClientId: '1088021463056-7ct94uassgjvcvdjmfsstk9tqa7rf5c5.apps.googleusercontent.com',
    iosBundleId: 'com.example.vastavikComputer',
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
