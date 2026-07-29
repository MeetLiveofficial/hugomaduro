import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:krimson/common/manager/logger.dart';
import 'package:krimson/screen/face_filters/services/face_mesh_camera_image_adapter_io.dart';
import 'package:mediapipe_face_mesh/mediapipe_face_mesh.dart';

typedef FaceCameraFrameCallback = void Function({
  FaceMeshNv21Image? nv21,
  FaceMeshImage? bgra,
  required int rotationDegrees,
  required bool mirrorHorizontal,
});

/// Owns the device camera for the MediaPipe face-filter pipeline.
class FaceCameraService {
  FaceCameraService();

  static const Map<DeviceOrientation, int> _deviceOrientationDegrees = {
    DeviceOrientation.portraitUp: 0,
    DeviceOrientation.landscapeLeft: 90,
    DeviceOrientation.portraitDown: 180,
    DeviceOrientation.landscapeRight: 270,
  };

  CameraController? _controller;
  List<CameraDescription> _cameras = const [];
  int _cameraIndex = 0;
  bool _isBusyFrame = false;
  FaceCameraFrameCallback? onFrame;

  CameraController? get controller => _controller;
  bool get isReady => _controller?.value.isInitialized == true;

  bool get isFrontCamera {
    if (_cameras.isEmpty) return true;
    return _cameras[_cameraIndex].lensDirection == CameraLensDirection.front;
  }

  /// Matches mediapipe_face_mesh example: mirror front cam on Android only.
  bool get mirrorHorizontal => !Platform.isIOS && isFrontCamera;

  /// Rotation compensation for MediaPipe inference (package example formula).
  ///
  /// Prefer locked/preview orientation over raw [deviceOrientation] — emulators
  /// (BlueStacks) often report landscape while the UI is portrait-locked, which
  /// zeroes out front-camera rotation and leaves the mesh on its side.
  int get rotationDegrees {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return 0;
    final camera = _cameras[_cameraIndex];
    if (Platform.isAndroid) {
      final deviceRotation = _deviceOrientationDegrees[_previewOrientation()] ??
          0;
      if (camera.lensDirection == CameraLensDirection.front) {
        return (camera.sensorOrientation + deviceRotation) % 360;
      }
      return (camera.sensorOrientation - deviceRotation + 360) % 360;
    }
    if (Platform.isIOS) {
      return _deviceOrientationDegrees[_previewOrientation()] ?? 0;
    }
    return 0;
  }

  DeviceOrientation _previewOrientation() {
    final controller = _controller;
    if (controller == null) return DeviceOrientation.portraitUp;
    return controller.value.lockedCaptureOrientation ??
        controller.value.previewPauseOrientation ??
        controller.value.deviceOrientation;
  }

  /// Native sensor aspect (height/width of previewSize) for upright layout.
  double get nativeAspectRatio {
    final size = _controller?.value.previewSize;
    if (size == null || size.width == 0) return 3 / 4;
    return size.height / size.width;
  }

  Future<bool> requestPermissions() async {
    if (kIsWeb) return false;
    final camera = await Permission.camera.request();
    final mic = await Permission.microphone.request();
    return camera.isGranted && mic.isGranted;
  }

  Future<bool> initialize({
    CameraLensDirection preferred = CameraLensDirection.front,
  }) async {
    if (kIsWeb) return false;
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        Loggers.error('FaceCameraService: no cameras');
        return false;
      }
      _cameraIndex = _preferredIndex(preferred) ?? 0;
      return _openCamera(_cameras[_cameraIndex]);
    } catch (e, st) {
      Loggers.error('FaceCameraService init error: $e\n$st');
      return false;
    }
  }

  int? _preferredIndex(CameraLensDirection direction) {
    for (var i = 0; i < _cameras.length; i++) {
      if (_cameras[i].lensDirection == direction) return i;
    }
    return null;
  }

  Future<bool> _openCamera(CameraDescription description) async {
    await stopImageStream();
    final previous = _controller;
    _controller = null;
    if (previous != null) {
      await previous.dispose();
    }

    final controller = CameraController(
      description,
      ResolutionPreset.high,
      enableAudio: true,
      imageFormatGroup: Platform.isIOS
          ? ImageFormatGroup.bgra8888
          : ImageFormatGroup.nv21,
    );
    _controller = controller;

    try {
      await controller.initialize();
      // Portrait-lock keeps sensor rotation stable (critical on BlueStacks).
      await controller.lockCaptureOrientation(DeviceOrientation.portraitUp);
      await startImageStream();
      return true;
    } catch (e, st) {
      Loggers.error('FaceCameraService open error: $e\n$st');
      await controller.dispose();
      _controller = null;
      return false;
    }
  }

  Future<void> startImageStream() async {
    final controller = _controller;
    if (controller == null ||
        !controller.value.isInitialized ||
        controller.value.isStreamingImages) {
      return;
    }
    await controller.startImageStream(_onCameraImage);
  }

  Future<void> stopImageStream() async {
    final controller = _controller;
    if (controller == null || !controller.value.isStreamingImages) return;
    try {
      await controller.stopImageStream();
    } catch (e) {
      Loggers.error('stopImageStream: $e');
    }
  }

  void _onCameraImage(CameraImage image) {
    final callback = onFrame;
    if (callback == null || _isBusyFrame) return;
    _isBusyFrame = true;
    try {
      if (Platform.isAndroid) {
        final nv21 = FaceMeshCameraImageAdapter.toNv21(image);
        if (nv21 != null) {
          callback(
            nv21: nv21,
            rotationDegrees: rotationDegrees,
            mirrorHorizontal: mirrorHorizontal,
          );
        }
      } else if (Platform.isIOS) {
        final bgra = FaceMeshCameraImageAdapter.toBgra(image);
        if (bgra != null) {
          callback(
            bgra: bgra,
            rotationDegrees: rotationDegrees,
            mirrorHorizontal: mirrorHorizontal,
          );
        }
      }
    } finally {
      scheduleMicrotask(() => _isBusyFrame = false);
    }
  }

  Future<void> switchCamera() async {
    if (_cameras.length < 2) return;
    final current = _cameras[_cameraIndex].lensDirection;
    final nextDirection = current == CameraLensDirection.front
        ? CameraLensDirection.back
        : CameraLensDirection.front;
    final next = _preferredIndex(nextDirection);
    if (next == null) return;
    _cameraIndex = next;
    await _openCamera(_cameras[_cameraIndex]);
  }

  Future<void> setFlash(bool on) async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    try {
      await controller.setFlashMode(on ? FlashMode.torch : FlashMode.off);
    } catch (e) {
      Loggers.error('setFlash: $e');
    }
  }

  Future<XFile?> takePicture() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return null;
    final wasStreaming = controller.value.isStreamingImages;
    if (wasStreaming) await stopImageStream();
    try {
      return await controller.takePicture();
    } finally {
      if (wasStreaming) await startImageStream();
    }
  }

  Future<void> startVideoRecording() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    if (controller.value.isRecordingVideo) return;
    if (controller.value.isStreamingImages) await stopImageStream();
    await controller.startVideoRecording();
  }

  Future<XFile?> stopVideoRecording() async {
    final controller = _controller;
    if (controller == null || !controller.value.isRecordingVideo) return null;
    final file = await controller.stopVideoRecording();
    await startImageStream();
    return file;
  }

  Future<void> pauseVideoRecording() async {
    final controller = _controller;
    if (controller == null || !controller.value.isRecordingVideo) return;
    try {
      await controller.pauseVideoRecording();
    } catch (e) {
      Loggers.error('pauseVideoRecording: $e');
    }
  }

  Future<void> resumeVideoRecording() async {
    final controller = _controller;
    if (controller == null) return;
    try {
      await controller.resumeVideoRecording();
    } catch (e) {
      Loggers.error('resumeVideoRecording: $e');
    }
  }

  Future<void> dispose() async {
    onFrame = null;
    final controller = _controller;
    _controller = null;
    if (controller == null) return;
    try {
      if (controller.value.isStreamingImages) {
        await controller.stopImageStream();
      }
      if (controller.value.isRecordingVideo) {
        await controller.stopVideoRecording();
      }
      await controller.dispose();
    } catch (e) {
      Loggers.error('FaceCameraService dispose: $e');
    }
  }
}
