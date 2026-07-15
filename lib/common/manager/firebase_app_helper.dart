import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:krimson/common/manager/logger.dart';
import 'package:krimson/firebase_options.dart';

/// Garantiza que exista la app Firebase `[DEFAULT]` antes de Auth/FCM/Firestore.
class FirebaseAppHelper {
  static String? lastError;
  static Future<bool>? _inFlight;

  static bool get isReady => Firebase.apps.isNotEmpty;

  /// Nunca debe bloquear login/registro Laravel.
  static Future<bool> ensureInitialized({
    Duration timeout = const Duration(seconds: 20),
  }) {
    if (Firebase.apps.isNotEmpty) return Future.value(true);
    _inFlight ??= _doInit().whenComplete(() => _inFlight = null);
    return _inFlight!.timeout(timeout, onTimeout: () {
      lastError = 'timeout after ${timeout.inSeconds}s';
      Loggers.error('Firebase init timeout: $lastError');
      return Firebase.apps.isNotEmpty;
    });
  }

  static Future<bool> _doInit() async {
    if (Firebase.apps.isNotEmpty) return true;
    lastError = null;

    // En web: esperar a que index.html precargue los módulos ES (si aplica).
    if (kIsWeb) {
      await _waitForWebModules();
    }

    // 1) Siempre con DefaultFirebaseOptions (más fiable en release).
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      if (Firebase.apps.isNotEmpty) {
        Loggers.success('Firebase init OK (DefaultFirebaseOptions)');
        return true;
      }
    } on FirebaseException catch (e, st) {
      lastError = '${e.code}: ${e.message}';
      if (e.code == 'duplicate-app' || Firebase.apps.isNotEmpty) {
        return true;
      }
      Loggers.error('Firebase options init: ${e.code} ${e.message}\n$st');
    } catch (e, st) {
      lastError = e.toString();
      if (_isDuplicate(e) || Firebase.apps.isNotEmpty) {
        return true;
      }
      Loggers.error('Firebase options init: $e\n$st');
    }

    // 2) Fallback Android/iOS: google-services.json / GoogleService-Info.plist
    if (!kIsWeb) {
      try {
        await Firebase.initializeApp();
        if (Firebase.apps.isNotEmpty) {
          Loggers.success('Firebase init OK (native google-services)');
          return true;
        }
      } catch (e, st) {
        lastError = e.toString();
        if (_isDuplicate(e) || Firebase.apps.isNotEmpty) {
          return true;
        }
        Loggers.error('Firebase native init: $e\n$st');
      }
    }

    // Si el JS ya creó la app (preload) pero Dart no la veía aún.
    if (Firebase.apps.isNotEmpty) {
      lastError = null;
      return true;
    }

    return false;
  }

  static Future<void> _waitForWebModules() async {
    // Pequeña espera para que el <script type="module"> de index.html termine.
    for (var i = 0; i < 25; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 40));
      if (Firebase.apps.isNotEmpty) return;
    }
  }

  static bool _isDuplicate(Object e) {
    final msg = e.toString().toLowerCase();
    return msg.contains('duplicate-app') || msg.contains('already exists');
  }
}
