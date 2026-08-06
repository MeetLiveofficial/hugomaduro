import 'package:flutter/foundation.dart';
import 'package:krimson/common/manager/session_manager.dart';
import 'package:krimson/model/general/settings_model.dart';

/// Gate DeepAR vs MediaPipe según Settings del panel.
class DeepArRuntime {
  DeepArRuntime._();

  /// DeepAR solo en Android/iOS con `is_deepAR=1` y license key de la plataforma.
  static bool useDeepAr([Setting? settings]) {
    if (kIsWeb) return false;
    final s = settings ?? SessionManager.instance.getSettings();
    if (s == null || (s.isDeepAr ?? 0) != 1) return false;
    if (defaultTargetPlatform == TargetPlatform.android) {
      return (s.deeparAndroidKey ?? '').trim().isNotEmpty;
    }
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return (s.deeparIOSKey ?? '').trim().isNotEmpty;
    }
    return false;
  }

  static String? androidKey([Setting? settings]) {
    final s = settings ?? SessionManager.instance.getSettings();
    final key = (s?.deeparAndroidKey ?? '').trim();
    return key.isEmpty ? null : key;
  }

  static String? iosKey([Setting? settings]) {
    final s = settings ?? SessionManager.instance.getSettings();
    final key = (s?.deeparIOSKey ?? '').trim();
    return key.isEmpty ? null : key;
  }

  static List<DeepARFilters> filters([Setting? settings]) {
    final s = settings ?? SessionManager.instance.getSettings();
    return s?.deepARFilters ?? const <DeepARFilters>[];
  }
}
