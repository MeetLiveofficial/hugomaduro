import 'dart:async';
import 'dart:html' as html;
import 'dart:js_util' as js_util;
import 'dart:ui_web' as ui_web;

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:krimson/common/manager/logger.dart';

typedef FaceCameraFrameCallback = void Function({
  dynamic nv21,
  dynamic bgra,
  required int rotationDegrees,
  required bool mirrorHorizontal,
});

/// Cámara web **sin** plugin `camera` (evita MissingPluginException).
/// Usa getUserMedia + &lt;video&gt; registrado como platform view.
class FaceCameraService {
  FaceCameraService();

  FaceCameraFrameCallback? onFrame;
  String? lastError;

  html.VideoElement? _video;
  dynamic _stream;
  String? _viewType;
  bool _ready = false;
  double _aspect = 3 / 4;

  /// Id para [HtmlElementView].
  String? get webViewType => _viewType;

  /// En web no hay [CameraController] del plugin.
  CameraController? get controller => null;

  bool get isReady => _ready && _video != null;
  bool get isFrontCamera => true;
  bool get mirrorHorizontal => true;
  int get rotationDegrees => 0;
  double get nativeAspectRatio => _aspect;

  Future<bool> requestPermissions() async {
    try {
      await _getUserMediaStream();
      return true;
    } catch (e) {
      lastError = e.toString();
      return false;
    }
  }

  Future<dynamic> _getUserMediaStream() async {
    final devices = html.window.navigator.mediaDevices;
    if (devices == null) {
      throw StateError('mediaDevices no disponible');
    }
    return js_util.promiseToFuture(
      js_util.callMethod(devices, 'getUserMedia', [
        js_util.jsify({
          'video': {
            'facingMode': 'user',
            'width': {'ideal': 720},
            'height': {'ideal': 1280},
          },
          'audio': false,
        }),
      ]),
    );
  }

  Future<bool> initialize({
    CameraLensDirection preferred = CameraLensDirection.front,
  }) async {
    lastError = null;
    await dispose();
    try {
      _stream = await _getUserMediaStream();
      final viewType =
          'krimson-web-cam-${DateTime.now().microsecondsSinceEpoch}';

      final video = html.VideoElement()
        ..autoplay = true
        ..muted = true
        ..setAttribute('playsinline', 'true')
        ..style.objectFit = 'cover'
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.transform = 'scaleX(-1)'; // mirror selfie

      // srcObject via JS (tipado MediaStream varía entre SDKs).
      js_util.setProperty(video, 'srcObject', _stream);

      ui_web.platformViewRegistry.registerViewFactory(viewType, (int id) {
        return video;
      });

      await video.play();
      // Esperar metadata para aspect ratio.
      await _waitVideoReady(video);
      final vw = video.videoWidth;
      final vh = video.videoHeight;
      if (vw > 0 && vh > 0) {
        _aspect = vh / vw;
      }

      _video = video;
      _viewType = viewType;
      _ready = true;
      if (kDebugMode) {
        debugPrint('FaceCameraService web (getUserMedia): ready ${vw}x$vh');
      }
      return true;
    } catch (e, st) {
      lastError = e.toString();
      Loggers.error('FaceCameraService web init: $e\n$st');
      _ready = false;
      return false;
    }
  }

  Future<void> _waitVideoReady(html.VideoElement video) async {
    if (video.readyState >= 2 && video.videoWidth > 0) return;
    final completer = Completer<void>();
    final sub = video.onLoadedMetadata.listen((_) {
      if (!completer.isCompleted) completer.complete();
    });
    await Future.any([
      completer.future,
      Future<void>.delayed(const Duration(seconds: 3)),
    ]);
    await sub.cancel();
  }

  Future<void> startImageStream() async {}
  Future<void> stopImageStream() async {}
  Future<void> switchCamera() async {}
  Future<void> setFlash(bool on) async {}
  Future<XFile?> takePicture() async => null;
  Future<void> startVideoRecording() async {}
  Future<XFile?> stopVideoRecording() async => null;
  Future<void> pauseVideoRecording() async {}
  Future<void> resumeVideoRecording() async {}

  Future<void> dispose() async {
    onFrame = null;
    _ready = false;
    _viewType = null;
    try {
      if (_stream != null) {
        final tracks = js_util.callMethod(_stream, 'getTracks', []) as List;
        for (final t in tracks) {
          js_util.callMethod(t, 'stop', []);
        }
      }
    } catch (_) {}
    _stream = null;
    _video?.remove();
    _video = null;
  }
}
