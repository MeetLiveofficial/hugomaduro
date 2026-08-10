import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:krimson/common/manager/logger.dart';
import 'package:krimson/common/service/livekit/livekit_room_service.dart';
import 'package:krimson/screen/face_filters/models/face_filter_effect.dart';
import 'package:krimson/screen/face_filters/models/face_mesh_frame.dart';
import 'package:krimson/screen/face_filters/services/face_filter_pipeline.dart';
import 'package:krimson/screen/face_filters/widgets/face_camera_preview_stack.dart';
import 'package:livekit_client/livekit_client.dart';

/// Puente LiveKit ↔ pipeline MediaPipe / GPUPixel.
///
/// Estrategia de rendimiento (móvil):
/// 1. LiveKit publica la cámara nativa (encoder H.264 estable, simulcast).
/// 2. En paralelo, [FaceFilterPipeline] analiza frames a ≤ [maxInferenceFps]
///    para landmarks (sin bloquear publicación) — o GPUPixel en pre-live.
/// 3. El host ve overlay local via [buildHostPreview] / BeautyShader.
/// 4. Cuando el filtro es `none`, se puede omitir MediaPipe por completo.
///
/// Nota: inyectar píxeles compuestos (GPUPixel Sink) en el track RTC de
/// LiveKit Flutter requiere un capturer custom. Ver
/// `packages/gpupixel_flutter/README.md`. El track publicado sigue
/// siendo la cámara LiveKit.
class LiveKitFaceFilterBridge {
  LiveKitFaceFilterBridge({
    FaceFilterPipeline? pipeline,
    this.maxInferenceFps = 15,
  }) : pipeline = pipeline ??
            FaceFilterPipeline(maxInferenceFps: maxInferenceFps);

  final FaceFilterPipeline pipeline;
  final int maxInferenceFps;

  FaceFilterId _effectId = FaceFilterId.none;
  bool _analysisEnabled = false;
  LiveKitRoomService? _roomService;

  FaceFilterId get effectId => _effectId;
  ValueListenable<FaceMeshFrame?> get frameListenable =>
      pipeline.frameListenable;

  /// Adjunta a un [LiveKitRoomService] ya conectado (o a punto de publicar).
  Future<void> attach(LiveKitRoomService roomService) async {
    _roomService = roomService;
  }

  /// Activa/desactiva análisis MediaPipe según el filtro.
  Future<void> setEffect(FaceFilterId id) async {
    _effectId = id;
    final look = id.beautyLook;
    if (look != null) {
      pipeline.beauty.setLook(look);
    }
    final needMesh = id.needsFaceMesh;
    if (needMesh && !_analysisEnabled) {
      await _startAnalysis();
    } else if (!needMesh && _analysisEnabled) {
      await _stopAnalysis();
    }
  }

  Future<void> _startAnalysis() async {
    if (kIsWeb) return;
    try {
      // LiveKit ya tiene la cámara; abrimos pipeline solo para mesh en
      // sesiones donde el host usa FaceCamera dedicada (stories / filtered live UI).
      // Si la cámara está ocupada por LiveKit, start() fallará — se loguea y
      // el preview LiveKit sigue sin overlay.
      final ok = await pipeline.start();
      _analysisEnabled = ok;
      if (!ok) {
        Loggers.error(
            'LiveKitFaceFilterBridge: camera busy — overlay local omitido');
      }
    } catch (e, st) {
      Loggers.error('LiveKitFaceFilterBridge start: $e\n$st');
      _analysisEnabled = false;
    }
  }

  Future<void> _stopAnalysis() async {
    _analysisEnabled = false;
    await pipeline.stop();
  }

  /// Opciones de captura LiveKit recomendadas cuando hay filtros activos
  /// (prioridad a FPS estable frente a resolución).
  CameraCaptureOptions captureOptionsForFilters({
    required LiveKitQualityProfile profile,
  }) {
    final params = switch (profile) {
      LiveKitQualityProfile.high => VideoParametersPresets.h720_169,
      LiveKitQualityProfile.medium => VideoParametersPresets.h360_169,
      LiveKitQualityProfile.low => VideoParametersPresets.h180_169,
    };
    return CameraCaptureOptions(
      params: params,
      maxFrameRate: profile == LiveKitQualityProfile.high ? 24.0 : 20.0,
    );
  }

  /// Preview del host con overlay de filtro (usar en UI de live cuando
  /// el bridge posee la cámara vía [FaceFilterPipeline]).
  Widget buildHostPreview({
    required GlobalKey boundaryKey,
    required FaceFilterId effectId,
  }) {
    return FaceCameraPreviewStack(
      boundaryKey: boundaryKey,
      controller: pipeline.camera.controller,
      isReady: pipeline.isReady,
      nativeAspectRatio: pipeline.camera.nativeAspectRatio,
      frameListenable: pipeline.frameListenable,
      effectId: effectId,
      beauty: pipeline.beauty,
    );
  }

  /// Modo recomendado para lives con filtros: el host usa FaceCamera + mesh
  /// y LiveKit publica sin cámara (solo audio), o con cámara nativa sin mesh.
  /// Aquí configuramos audio-only publish hint.
  bool get prefersNativeLiveKitCamera =>
      !_effectId.needsFaceMesh || !_analysisEnabled;

  LiveKitRoomService? get roomService => _roomService;

  Future<void> dispose() async {
    await _stopAnalysis();
    _roomService = null;
  }
}
