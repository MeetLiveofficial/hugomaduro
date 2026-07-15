import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:krimson/common/manager/logger.dart';
import 'package:krimson/common/manager/session_manager.dart';
import 'package:zego_express_engine/zego_express_engine.dart';

/// Garantiza un único motor Zego listo antes de loginRoom / preview.
class ZegoEngineManager {
  ZegoEngineManager._();

  static bool _ready = false;
  static Future<bool>? _inFlight;

  static bool get isReady => _ready;

  /// Crea el engine si hace falta. Idempotente.
  static Future<bool> ensureCreated() async {
    if (kIsWeb) {
      Loggers.info('ZegoEngineManager: skip on web');
      return false;
    }
    if (_ready) return true;
    if (_inFlight != null) return _inFlight!;

    _inFlight = _create();
    try {
      return await _inFlight!;
    } finally {
      _inFlight = null;
    }
  }

  static Future<bool> _create() async {
    final settings = SessionManager.instance.getSettings();
    final rawId = (settings?.zegoAppId ?? '').trim();
    final appId = int.tryParse(rawId) ?? 0;
    final appSign = (settings?.zegoAppSign ?? '').trim();

    if (appId == 0) {
      Loggers.error('ZegoEngineManager: zego_app_id not configured');
      _ready = false;
      throw Exception(
          'Zego App ID is not configured. Set it in admin Settings.');
    }
    if (appSign.isEmpty) {
      Loggers.error('ZegoEngineManager: zego_app_sign not configured');
      _ready = false;
      throw Exception(
          'Zego App Sign is not configured. Set it in admin Settings.');
    }

    try {
      await ZegoExpressEngine.createEngineWithProfile(
        ZegoEngineProfile(
          appId,
          ZegoScenario.Default,
          appSign: appSign,
        ),
      );
      _ready = true;
      Loggers.info('ZegoEngineManager: engine created (appId=$appId)');
      return true;
    } on MissingPluginException catch (e) {
      _ready = false;
      Loggers.error('ZegoEngineManager: MissingPluginException ${e.message}');
      rethrow;
    } catch (e) {
      // Si ya existe, marcamos listo; si no, propagamos.
      final msg = e.toString().toLowerCase();
      if (msg.contains('already') ||
          msg.contains('exist') ||
          msg.contains('created')) {
        _ready = true;
        Loggers.info('ZegoEngineManager: engine already present');
        return true;
      }
      _ready = false;
      Loggers.error('ZegoEngineManager: create failed $e');
      rethrow;
    }
  }

  /// Ejecuta [action] ignorando fallos (útil al cerrar live/call).
  static Future<void> safe(Future<void> Function() action) async {
    try {
      await action();
    } catch (e) {
      Loggers.info('ZegoEngineManager.safe ignored: $e');
    }
  }

  static void markDestroyed() {
    _ready = false;
  }
}
