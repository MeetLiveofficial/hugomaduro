import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'facebetter_beauty_params.dart';

/// Puente Dart ↔ nativo FaceBetter (PlatformView GL + MethodChannel).
class FaceBetterController extends ChangeNotifier {
  static const MethodChannel _channel = MethodChannel('krimson/facebetter');

  FaceBetterBeautyParams _params = const FaceBetterBeautyParams();
  MethodChannel? _viewChannel;
  bool _available = false;
  bool _running = false;
  bool _checked = false;
  Timer? _debounce;
  int? _viewId;

  FaceBetterBeautyParams get params => _params;
  bool get isAvailable => _available;
  bool get isRunning => _running;
  bool get hasTexture => _running;
  /// Compat con preview Texture antiguo (ya no se usa).
  int? get textureId => _running ? (_viewId ?? 1) : null;
  int? get viewId => _viewId;

  void attachView(int viewId) {
    _viewId = viewId;
    _viewChannel = MethodChannel('krimson/facebetter/view_$viewId');
    _running = true;
    applyParams(_params, debounce: false);
    notifyListeners();
  }

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

  /// El preview real se crea con [FaceBetterPlatformPreview] (AndroidView).
  /// Este método solo marca estado listo para la UI.
  Future<int?> start({
    required String appId,
    required String appKey,
    int width = 720,
    int height = 1280,
  }) async {
    if (kIsWeb) return null;
    if (!_checked) await checkAvailable();
    if (!_available) return null;
    if (appId.isEmpty || appKey.isEmpty) return null;
    _running = true;
    notifyListeners();
    return 1;
  }

  Future<void> applyParams(
    FaceBetterBeautyParams p, {
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
    final args = _params.toNative();
    try {
      final view = _viewChannel;
      if (view != null) {
        await view.invokeMethod('setBeauty', args);
      } else {
        await _channel.invokeMethod('setBeauty', args);
      }
    } catch (e) {
      debugPrint('FaceBetter setBeauty: $e');
    }
  }

  Future<void> stop() async {
    _debounce?.cancel();
    if (kIsWeb) return;
    try {
      await _channel.invokeMethod('stop');
    } catch (_) {}
    _viewChannel = null;
    _viewId = null;
    _running = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    if (!kIsWeb && _running) {
      _channel.invokeMethod('stop').catchError((_) {});
    }
    _viewChannel = null;
    _viewId = null;
    _running = false;
    super.dispose();
  }
}
