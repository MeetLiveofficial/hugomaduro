import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'gpupixel_beauty_params.dart';

/// Puente Dart ↔ nativo GPUPixel.
///
/// - Frames: se quedan en nativo (Camera → Beauty → Reshape → Texture).
/// - Canal: solo floats de belleza + lifecycle.
class GpuPixelController extends ChangeNotifier {
  static const MethodChannel _channel = MethodChannel('krimson/gpupixel');

  GpuPixelBeautyParams _params = const GpuPixelBeautyParams();
  int? _textureId;
  bool _available = false;
  bool _running = false;
  bool _checked = false;
  Timer? _debounce;

  GpuPixelBeautyParams get params => _params;
  int? get textureId => _textureId;
  bool get isAvailable => _available;
  bool get isRunning => _running;
  bool get hasTexture => _textureId != null;

  /// Comprueba si el motor nativo cargó (AAR / framework).
  Future<bool> checkAvailable() async {
    if (kIsWeb) {
      _available = false;
      _checked = true;
      return false;
    }
    try {
      final v = await _channel.invokeMethod<bool>('isAvailable');
      _available = v == true;
    } catch (_) {
      _available = false;
    }
    _checked = true;
    notifyListeners();
    return _available;
  }

  /// Inicia cámara nativa + pipeline + Flutter [Texture].
  ///
  /// Si la cámara está ocupada (p. ej. LiveKit), falla y [isRunning] queda false.
  Future<int?> start({int width = 720, int height = 1280}) async {
    if (kIsWeb) return null;
    if (!_checked) await checkAvailable();
    if (!_available) return null;

    try {
      final id = await _channel.invokeMethod<int>('start', {
        'width': width,
        'height': height,
        'frontCamera': true,
      });
      _textureId = id;
      _running = id != null;
      if (_running) {
        await applyParams(_params, debounce: false);
      }
      notifyListeners();
      return id;
    } on PlatformException catch (e) {
      debugPrint('GpuPixel start failed: ${e.message}');
      _running = false;
      _textureId = null;
      notifyListeners();
      return null;
    }
  }

  Future<void> applyParams(
    GpuPixelBeautyParams p, {
    bool debounce = true,
  }) async {
    _params = p;
    notifyListeners();
    if (!_running) return;

    _debounce?.cancel();
    if (!debounce) {
      await _pushBeauty();
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 16), _pushBeauty);
  }

  Future<void> _pushBeauty() async {
    if (kIsWeb || !_running) return;
    try {
      await _channel.invokeMethod('setBeauty', _params.toNative());
    } catch (e) {
      debugPrint('GpuPixel setBeauty: $e');
    }
  }

  Future<void> setSmooth(double v) =>
      applyParams(_params.copyWith(smooth: v.clamp(0, 1)));
  Future<void> setWhiten(double v) =>
      applyParams(_params.copyWith(whiten: v.clamp(0, 1)));
  Future<void> setSlimFace(double v) =>
      applyParams(_params.copyWith(slimFace: v.clamp(0, 1)));
  Future<void> setBigEye(double v) =>
      applyParams(_params.copyWith(bigEye: v.clamp(0, 1)));
  Future<void> setEnabled(bool v) =>
      applyParams(_params.copyWith(enabled: v));

  Future<void> stop() async {
    _debounce?.cancel();
    if (kIsWeb) return;
    try {
      await _channel.invokeMethod('stop');
    } catch (_) {}
    _textureId = null;
    _running = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    if (!kIsWeb && _running) {
      _channel.invokeMethod('stop').catchError((_) {});
    }
    _textureId = null;
    _running = false;
    super.dispose();
  }
}
