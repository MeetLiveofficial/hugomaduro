import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:krimson/common/manager/logger.dart';

/// Bloqueo global de capturas.
/// Android: FLAG_SECURE en MainActivity (nativo).
/// iOS: canal nativo (si está disponible).
/// Web: no hay bloqueo de sistema fiable.
class ScreenSecurity {
  ScreenSecurity._();

  static const _channel = MethodChannel('krimson/screen_security');
  static bool _enabled = false;

  static Future<void> enable() async {
    if (kIsWeb || _enabled) return;
    try {
      await _channel.invokeMethod<void>('enableSecure');
      _enabled = true;
      Loggers.info('ScreenSecurity: enabled');
    } on MissingPluginException {
      // Android ya aplica FLAG_SECURE en MainActivity.
      _enabled = true;
    } catch (e) {
      Loggers.error('ScreenSecurity enable: $e');
    }
  }
}
