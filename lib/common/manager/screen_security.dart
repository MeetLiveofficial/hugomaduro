import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:krimson/common/manager/logger.dart';
import 'package:krimson/utilities/app_platform.dart';

/// Bloqueo global de capturas.
/// Android: FLAG_SECURE en MainActivity (nativo).
/// iOS: canal nativo (UITextField secure + overlay de grabación).
/// Web: no hay bloqueo de sistema fiable.
class ScreenSecurity {
  ScreenSecurity._();

  static const _channel = MethodChannel('krimson/screen_security');
  static bool _enabled = false;

  static Future<void> enable() async {
    if (kIsWeb || _enabled) return;

    if (AppPlatform.isAndroid) {
      // FLAG_SECURE ya se aplica en MainActivity.
      _enabled = true;
      return;
    }

    if (!AppPlatform.isIOS) {
      _enabled = true;
      return;
    }

    for (var attempt = 0; attempt < 15; attempt++) {
      try {
        await _channel.invokeMethod<void>('enableSecure');
        _enabled = true;
        Loggers.info('ScreenSecurity: enabled (iOS)');
        return;
      } on MissingPluginException {
        await Future<void>.delayed(const Duration(milliseconds: 200));
      } catch (e) {
        Loggers.error('ScreenSecurity enable: $e');
        await Future<void>.delayed(const Duration(milliseconds: 200));
      }
    }
    Loggers.error('ScreenSecurity: iOS channel no disponible');
  }
}
