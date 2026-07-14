import 'package:flutter/foundation.dart';

/// Safe platform checks for mobile + web.
/// Avoids `dart:io` Platform, which throws on web.
class AppPlatform {
  static bool get isIOS =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  static bool get isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  static bool get isMobile => isIOS || isAndroid;
}
