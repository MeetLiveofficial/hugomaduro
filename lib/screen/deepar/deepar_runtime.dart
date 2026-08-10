import 'package:krimson/model/general/settings_model.dart';
import 'package:krimson/common/manager/session_manager.dart';

/// Gate DeepAR (legacy). Desactivado: belleza vía GPUPixel.
/// Docs: https://gpupixel.pixpark.net/guide/intro
class DeepArRuntime {
  DeepArRuntime._();

  /// Siempre off — motor activo: GPUPixel (BeautyFace + FaceReshape).
  static bool useDeepAr([Setting? settings]) => false;

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
