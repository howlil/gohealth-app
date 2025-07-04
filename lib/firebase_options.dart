// File generated by FlutterFire CLI.
// ignore_for_file: type=lint
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
    apiKey: 'AIzaSyARy9SyIw05ZdNAUGCi1iavoyrywwBc5wI',
    appId: '1:241189504127:web:75233d3ddb45985cdbeb4a',
    messagingSenderId: '241189504127',
    projectId: 'tangkapin-317d2',
    authDomain: 'tangkapin-317d2.firebaseapp.com',
    storageBucket: 'tangkapin-317d2.firebasestorage.app',
    measurementId: 'G-TGGRX1Z2QY',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBNVgNtZyTp2OBnU1XhPtdJNrH0vNvvnXY',
    appId: '1:241189504127:android:79db19487014dc94dbeb4a',
    messagingSenderId: '241189504127',
    projectId: 'tangkapin-317d2',
    storageBucket: 'tangkapin-317d2.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBDiIHgbNSQSStRU9slVa2oslRNvUynDIU',
    appId: '1:241189504127:ios:fe445ad9ba2a7533dbeb4a',
    messagingSenderId: '241189504127',
    projectId: 'tangkapin-317d2',
    storageBucket: 'tangkapin-317d2.firebasestorage.app',
    iosBundleId: 'com.example.gohealth',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyBDiIHgbNSQSStRU9slVa2oslRNvUynDIU',
    appId: '1:241189504127:ios:fe445ad9ba2a7533dbeb4a',
    messagingSenderId: '241189504127',
    projectId: 'tangkapin-317d2',
    storageBucket: 'tangkapin-317d2.firebasestorage.app',
    iosBundleId: 'com.example.gohealth',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyARy9SyIw05ZdNAUGCi1iavoyrywwBc5wI',
    appId: '1:241189504127:web:fd9643fbb37e5472dbeb4a',
    messagingSenderId: '241189504127',
    projectId: 'tangkapin-317d2',
    authDomain: 'tangkapin-317d2.firebaseapp.com',
    storageBucket: 'tangkapin-317d2.firebasestorage.app',
    measurementId: 'G-V0RRE3D6CE',
  );

}