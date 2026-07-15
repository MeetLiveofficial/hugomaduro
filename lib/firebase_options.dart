// ignore_for_file: lines_longer_than_80_chars
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Opciones Firebase del proyecto krimson-20f2c (com.nexus.krimson).
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
        return android;
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyD21n5_2v0BpA2tMji10W27bZKD3B2xmy8',
    appId: '1:972743641868:android:07caec9f5b51d88a375729',
    messagingSenderId: '972743641868',
    projectId: 'krimson-20f2c',
    storageBucket: 'krimson-20f2c.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCkX-RxNVfkjwyNmEIp0fKSE3iqBRXbvR0',
    appId: '1:972743641868:ios:a29c7666b6802a27375729',
    messagingSenderId: '972743641868',
    projectId: 'krimson-20f2c',
    storageBucket: 'krimson-20f2c.firebasestorage.app',
    iosBundleId: 'com.nexus.krimson',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCHozRzfcxnfw98h0fgID3Xkiuc6mivyyU',
    appId: '1:972743641868:web:f8606b100b42e1e6375729',
    messagingSenderId: '972743641868',
    projectId: 'krimson-20f2c',
    authDomain: 'krimson-20f2c.firebaseapp.com',
    storageBucket: 'krimson-20f2c.firebasestorage.app',
  );
}
