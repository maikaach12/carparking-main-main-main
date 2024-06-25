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
    apiKey: 'AIzaSyBNf5j4FORoXK3CZ2zFZskLvieSO_4zOo0',
    appId: '1:437756517706:web:0427dae0a50da740c675b3',
    messagingSenderId: '437756517706',
    projectId: 'parkingseven-13555',
    authDomain: 'parkingseven-13555.firebaseapp.com',
    storageBucket: 'parkingseven-13555.appspot.com',
    measurementId: 'G-S5F6SGDQZ4',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDBhH9gpKPLF9hlrYHnFdiDRNQm8SWnugU',
    appId: '1:437756517706:android:39731dc9597c7aa0c675b3',
    messagingSenderId: '437756517706',
    projectId: 'parkingseven-13555',
    storageBucket: 'parkingseven-13555.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCBeeW30P1XGNaiYnbQlZYD2p9XTI2YNzU',
    appId: '1:437756517706:ios:fcb66c72c3824ffdc675b3',
    messagingSenderId: '437756517706',
    projectId: 'parkingseven-13555',
    storageBucket: 'parkingseven-13555.appspot.com',
    iosBundleId: 'com.example.carparking',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyCBeeW30P1XGNaiYnbQlZYD2p9XTI2YNzU',
    appId: '1:437756517706:ios:fcb66c72c3824ffdc675b3',
    messagingSenderId: '437756517706',
    projectId: 'parkingseven-13555',
    storageBucket: 'parkingseven-13555.appspot.com',
    iosBundleId: 'com.example.carparking',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyBNf5j4FORoXK3CZ2zFZskLvieSO_4zOo0',
    appId: '1:437756517706:web:8afa9a0dc0154f45c675b3',
    messagingSenderId: '437756517706',
    projectId: 'parkingseven-13555',
    authDomain: 'parkingseven-13555.firebaseapp.com',
    storageBucket: 'parkingseven-13555.appspot.com',
    measurementId: 'G-DH95ZNRX36',
  );

}