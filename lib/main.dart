import 'dart:async';
import 'dart:ui';

import 'package:audio_session/audio_session.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:krimson/common/manager/firebase_notification_manager.dart';
import 'package:krimson/common/manager/logger.dart';
import 'package:krimson/common/manager/session_manager.dart';
import 'package:krimson/common/service/subscription/subscription_manager.dart';
import 'package:krimson/common/widget/restart_widget.dart';
import 'package:krimson/firebase_options.dart';
import 'package:krimson/languages/dynamic_translations.dart';
import 'package:krimson/screen/splash_screen/splash_screen.dart';
import 'package:krimson/utilities/app_platform.dart';
import 'package:krimson/utilities/theme_res.dart';

import 'common/service/network_helper/network_helper.dart';

String? _bootError;

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  Loggers.success("Handling a background message: ${message.data}");
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  if (AppPlatform.isIOS) {
    FirebaseNotificationManager.instance.showNotification(message);
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // En release también mostrar errores en pantalla (evita pantalla blanca sin log).
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    Loggers.error('FlutterError: ${details.exceptionAsString()}\n${details.stack}');
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    Loggers.error('PlatformError: $error\n$stack');
    return true;
  };
  ErrorWidget.builder = (details) {
    return Material(
      color: Colors.white,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Error UI:\n${details.exceptionAsString()}',
            style: const TextStyle(color: Colors.red, fontSize: 12),
          ),
        ),
      ),
    );
  };

  Future<T?> _withTimeout<T>(Future<T> future, String label) async {
    try {
      return await future.timeout(const Duration(seconds: 8));
    } catch (e, st) {
      Loggers.error('$label timeout/error: $e\n$st');
      return null;
    }
  }

  try {
    await _withTimeout(
      Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform),
      'Firebase.initializeApp',
    );
    if (!kIsWeb && Firebase.apps.isNotEmpty) {
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    }
  } catch (e, st) {
    // En web no bloquear la app: se usa auth API Laravel si Firebase no está listo.
    Loggers.error('Firebase.initializeApp: $e\n$st');
    if (!kIsWeb) {
      _bootError = 'Firebase.initializeApp: $e';
    }
  }

  try {
    await _withTimeout(GetStorage.init('krimson'), 'GetStorage.init');
  } catch (e, st) {
    _bootError ??= 'GetStorage.init: $e';
    Loggers.error('GetStorage.init: $e\n$st');
  }

  try {
    await _withTimeout(
      SubscriptionManager.shared.initPlatformState(),
      'SubscriptionManager',
    );
  } catch (e, st) {
    Loggers.error('SubscriptionManager init error: $e\n$st');
  }

  // AudioSession / Ads no aportan en Web y pueden colgar el arranque.
  if (!kIsWeb) {
    try {
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.speech());
    } catch (e, st) {
      Loggers.error('AudioSession init error: $e\n$st');
    }

    try {
      await MobileAds.instance.initialize();
    } catch (e, st) {
      Loggers.error('MobileAds init error: $e\n$st');
    }
  }

  try {
    NetworkHelper().initialize();
  } catch (e, st) {
    Loggers.error('NetworkHelper init error: $e\n$st');
  }

  if (!Get.isRegistered<DynamicTranslations>()) {
    Get.put(DynamicTranslations());
  }

  // NUNCA dejar de llamar runApp: si falla el init, antes se quedaba en blanco.
  runApp(RestartWidget(child: MyApp(bootError: _bootError)));
}

class MyApp extends StatelessWidget {
  final String? bootError;

  const MyApp({super.key, this.bootError});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      builder: (context, child) =>
          ScrollConfiguration(behavior: MyBehavior(), child: child!),
      translations: Get.find<DynamicTranslations>(),
      locale: Locale(SessionManager.instance.getLang()),
      fallbackLocale: Locale(SessionManager.instance.getFallbackLang()),
      themeMode: ThemeMode.light,
      darkTheme: ThemeRes.darkTheme(context),
      theme: ThemeRes.lightTheme(context),
      debugShowCheckedModeBanner: false,
      home: bootError != null
          ? _BootErrorScreen(message: bootError!)
          : const SplashScreen(),
    );
  }
}

class _BootErrorScreen extends StatelessWidget {
  final String message;

  const _BootErrorScreen({required this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Error al iniciar Krimson',
                style: TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold, color: Colors.red),
              ),
              const SizedBox(height: 12),
              Text(message, style: const TextStyle(fontSize: 13)),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Get.offAll(() => const SplashScreen()),
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MyBehavior extends ScrollBehavior {
  @override
  Widget buildOverscrollIndicator(
      BuildContext context, Widget child, ScrollableDetails details) {
    return child;
  }
}
