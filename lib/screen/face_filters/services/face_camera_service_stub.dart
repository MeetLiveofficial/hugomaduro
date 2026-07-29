import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';

typedef FaceCameraFrameCallback = void Function({
  dynamic nv21,
  dynamic bgra,
  required int rotationDegrees,
  required bool mirrorHorizontal,
});

class FaceCameraService {
  FaceCameraService();

  FaceCameraFrameCallback? onFrame;
  CameraController? get controller => null;
  bool get isReady => false;
  bool get isFrontCamera => true;
  bool get mirrorHorizontal => true;
  int get rotationDegrees => 0;
  double get nativeAspectRatio => 3 / 4;

  Future<bool> requestPermissions() async => false;

  Future<bool> initialize({
    CameraLensDirection preferred = CameraLensDirection.front,
  }) async {
    if (kDebugMode) {
      debugPrint('FaceCameraService stub: unavailable on this platform');
    }
    return false;
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
  }
}
