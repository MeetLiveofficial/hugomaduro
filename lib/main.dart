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
import 'package:krimson/common/manager/firebase_app_helper.dart';
import 'package:krimson/common/manager/firebase_notification_manager.dart';
import 'package:krimson/common/manager/logger.dart';
import 'package:krimson/common/manager/screen_security.dart';
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

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    Loggers.error(
        'FlutterError: ${details.exceptionAsString()}\n${details.stack}');
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    Loggers.error('PlatformError: $error\n$stack');
    return true;
  };
  ErrorWidget.builder = (details) {
    final msg = details.exceptionAsString();
    if (msg.contains('core/no-app') || msg.contains('FirebaseApp')) {
      Loggers.error('ErrorWidget Firebase suppressed: $msg');
      return const SizedBox.shrink();
    }
    return Material(
      color: const Color(0xFF1A0010),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Error UI:\n$msg',
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ),
      ),
    );
  };

  // GetStorage antes del primer frame (locale/session). Timeout corto.
  try {
    await GetStorage.init('krimson').timeout(const Duration(seconds: 3));
  } catch (e, st) {
    _bootError = 'GetStorage.init: $e';
    Loggers.error('GetStorage.init: $e\n$st');
  }

  if (!Get.isRegistered<DynamicTranslations>()) {
    Get.put(DynamicTranslations());
  }

  // Pintar YA — no esperar Firebase/Ads (en BlueStacks Ads puede tumbar nativo).
  runApp(const RestartWidget(child: MyApp()));

  // Bloquear screenshots en cuanto arranca (nativo; no Web).
  if (!kIsWeb) {
    unawaited(ScreenSecurity.enable());
  }

  unawaited(_bootstrap());
}

Future<void> _bootstrap() async {
  Future<T?> withTimeout<T>(Future<T> future, String label) async {
    try {
      return await future.timeout(const Duration(seconds: 5));
    } catch (e, st) {
      Loggers.error('$label timeout/error: $e\n$st');
      return null;
    }
  }

  try {
    await withTimeout(
      FirebaseAppHelper.ensureInitialized(),
      'Firebase.ensureInitialized',
    );
    if (FirebaseAppHelper.isReady && !kIsWeb) {
      FirebaseMessaging.onBackgroundMessage(
          _firebaseMessagingBackgroundHandler);
    } else if (!FirebaseAppHelper.isReady) {
      Loggers.error(
          'Firebase no inicializado: ${FirebaseAppHelper.lastError}');
    }
  } catch (e, st) {
    Loggers.error('Firebase.initializeApp: $e\n$st');
  }

  try {
    await withTimeout(
      SubscriptionManager.shared.initPlatformState(),
      'SubscriptionManager',
    );
  } catch (e, st) {
    Loggers.error('SubscriptionManager init error: $e\n$st');
  }

  try {
    NetworkHelper().initialize();
  } catch (e, st) {
    Loggers.error('NetworkHelper init error: $e\n$st');
  }

  // Ads / AudioSession diferidos: en emulador x86 (BlueStacks) el init
  // nativo temprano deja pantalla blanca.
  if (!kIsWeb) {
    // ignore: unawaited_futures
    Future<void>.delayed(const Duration(seconds: 5), () async {
      try {
        final session = await AudioSession.instance
            .timeout(const Duration(seconds: 3));
        await session
            .configure(const AudioSessionConfiguration.speech())
            .timeout(const Duration(seconds: 3));
      } catch (e) {
        Loggers.error('AudioSession deferred skip: $e');
      }
      try {
        await MobileAds.instance
            .initialize()
            .timeout(const Duration(seconds: 5));
      } catch (e) {
        Loggers.error('MobileAds deferred skip: $e');
      }
    });
  }

  if (_bootError != null) {
    Loggers.error('Boot warning: $_bootError');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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
      home: const SplashScreen(),
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
