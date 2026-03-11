// File generated manually from GoogleService-Info.plist
// ignore_for_file: lines_longer_than_80_chars, avoid_classes_with_only_static_members
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

  // Web — uses the same project, add your web app apiKey from Firebase Console
  // if you registered a web app. These values work for web too.
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyApWPJUIYC3UGNZAV8RsWz_9sQyQmICiBk',
    appId: '1:122374147282:web:000000000000000b710b',
    messagingSenderId: '122374147282',
    projectId: 'baserentapp-0',
    authDomain: 'baserentapp-0.firebaseapp.com',
    storageBucket: 'baserentapp-0.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyApWPJUIYC3UGNZAV8RsWz_9sQyQmICiBk',
    appId: '1:122374147282:android:000000000000000b710b',
    messagingSenderId: '122374147282',
    projectId: 'baserentapp-0',
    storageBucket: 'baserentapp-0.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyApWPJUIYC3UGNZAV8RsWz_9sQyQmICiBk',
    appId: '1:122374147282:ios:696ff6d91c1f8d850b710b',
    messagingSenderId: '122374147282',
    projectId: 'baserentapp-0',
    storageBucket: 'baserentapp-0.firebasestorage.app',
    iosBundleId: 'com.example.flutterApplication1rentalf',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyApWPJUIYC3UGNZAV8RsWz_9sQyQmICiBk',
    appId: '1:122374147282:ios:696ff6d91c1f8d850b710b',
    messagingSenderId: '122374147282',
    projectId: 'baserentapp-0',
    storageBucket: 'baserentapp-0.firebasestorage.app',
    iosBundleId: 'com.example.flutterApplication1rentalf',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyApWPJUIYC3UGNZAV8RsWz_9sQyQmICiBk',
    appId: '1:122374147282:web:000000000000000b710b',
    messagingSenderId: '122374147282',
    projectId: 'baserentapp-0',
    storageBucket: 'baserentapp-0.firebasestorage.app',
  );
}
