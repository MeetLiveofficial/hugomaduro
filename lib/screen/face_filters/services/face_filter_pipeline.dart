import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:krimson/screen/face_filters/models/face_mesh_frame.dart';
import 'package:krimson/screen/face_filters/services/face_camera_service.dart';
import 'package:krimson/screen/face_filters/services/face_mesh_engine.dart';
import 'package:krimson/screen/face_filters/widgets/beauty_camera_preview.dart';

/// Orquesta cámara → MediaPipe con presupuesto de FPS.
///
/// ```
/// CameraImageStream
///   → throttle (maxInferenceFps)
///   → FaceMeshEngine (drop si busy)
///   → frameNotifier (landmarks)
///   → CustomPainter / LiveKit bridge
/// ```
///
/// Beauty GPU (Impeller fragment shader) vive en [beauty] y se aplica en
/// [FaceCameraPreviewStack] vía [BeautyFiltered].
class FaceFilterPipeline {
  FaceFilterPipeline({
    FaceCameraService? camera,
    FaceMeshEngine? mesh,
    this.maxInferenceFps = 18,
    this.defaultBeautyIntensity = 0.0,
  })  : camera = camera ?? FaceCameraService(),
        mesh = mesh ?? FaceMeshEngine();

  final FaceCameraService camera;
  final FaceMeshEngine mesh;
  final BeautyShaderController beauty = BeautyShaderController();

  /// Intensidad inicial del beauty al arrancar (0–1).
  final double defaultBeautyIntensity;

  /// 15–20 FPS de inferencia: suficiente para AR fluido sin robar CPU al encoder.
  final int maxInferenceFps;

  DateTime? _lastPushAt;
  bool _running = false;

  ValueListenable<FaceMeshFrame?> get frameListenable => mesh.frameNotifier;

  bool get isReady => _running && camera.isReady && mesh.isInitialized;

  Future<bool> start({
    CameraLensDirection preferred = CameraLensDirection.front,
  }) async {
    if (kIsWeb) return false;
    await mesh.initialize();
    // Cargar shader en paralelo a la cámara (best-effort; Web/Skia → no-op).
    await beauty.load();
    beauty.setIntensity(defaultBeautyIntensity);
    camera.onFrame = _onFrame;
    final ok = await camera.initialize(preferred: preferred);
    _running = ok;
    return ok;
  }

  void _onFrame({
    dynamic nv21,
    dynamic bgra,
    required int rotationDegrees,
    required bool mirrorHorizontal,
  }) {
    if (!_shouldAcceptFrame()) return;
    if (nv21 != null) {
      mesh.pushNv21(
        nv21,
        rotationDegrees: rotationDegrees,
        mirrorHorizontal: mirrorHorizontal,
      );
    } else if (bgra != null) {
      mesh.pushBgra(
        bgra,
        rotationDegrees: rotationDegrees,
        mirrorHorizontal: mirrorHorizontal,
      );
    }
  }

  bool _shouldAcceptFrame() {
    final minGapMs = (1000 / maxInferenceFps).round();
    final now = DateTime.now();
    final last = _lastPushAt;
    if (last != null && now.difference(last).inMilliseconds < minGapMs) {
      return false;
    }
    _lastPushAt = now;
    return true;
  }

  Future<void> stop() async {
    _running = false;
    camera.onFrame = null;
    await camera.dispose();
    await mesh.dispose();
  }

  /// Libera cámara, mesh y el [FragmentShader] de belleza.
  Future<void> dispose() async {
    await stop();
    beauty.dispose();
  }
}
