import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:krimson/common/manager/logger.dart';
import 'package:krimson/screen/face_filters/models/face_mesh_frame.dart';
import 'package:mediapipe_face_mesh/mediapipe_face_mesh.dart';

class FaceMeshEngine {
  FaceMeshEngine();

  FaceDetectorProcessor? _detector;
  FaceMeshProcessor? _mesh;
  FaceMeshInferencePipeline? _pipeline;
  FaceMeshInferenceStreamProcessor? _streamProcessor;
  FaceBlendshapesProcessor? _blendshapes;

  StreamController<FaceMeshNv21Image>? _nv21Controller;
  StreamController<FaceMeshImage>? _bgraController;
  StreamSubscription? _subscription;
  int? _streamRotation;
  bool _pendingMirror = true;
  bool _isBusy = false;
  bool _initialized = false;

  final ValueNotifier<FaceMeshFrame?> frameNotifier =
      ValueNotifier<FaceMeshFrame?>(null);

  bool get isInitialized => _initialized;

  Future<void> initialize() async {
    if (kIsWeb || _initialized) return;
    try {
      _detector = await FaceDetectorProcessor.create(
        model: FaceDetectionModel.shortRange,
        delegate: FaceMeshDelegate.xnnpack,
        maxResults: 1,
        roiScaleY: 1.7,
        roiShiftY: -0.2,
      );

      final useAttention = !Platform.isWindows;
      _mesh = await FaceMeshProcessor.create(
        delegate: FaceMeshDelegate.xnnpack,
        enableSmoothing: true,
        enableRoiTracking: true,
        enableIris: !useAttention,
        enableAttentionMesh: useAttention,
      );

      _blendshapes = await FaceBlendshapesProcessor.create(
        delegate: FaceMeshDelegate.xnnpack,
      );

      _pipeline = FaceMeshInferencePipeline(
        detector: _detector!,
        mesh: _mesh!,
      );
      _streamProcessor = FaceMeshInferenceStreamProcessor(_pipeline!);
      _initialized = true;
      Loggers.success('FaceMeshEngine initialized');
    } catch (e, st) {
      Loggers.error('FaceMeshEngine init failed: $e\n$st');
      await dispose();
      rethrow;
    }
  }

  void pushNv21(
    FaceMeshNv21Image frame, {
    required int rotationDegrees,
    required bool mirrorHorizontal,
  }) {
    if (!_initialized || _isBusy) return;
    _ensureStream(rotationDegrees: rotationDegrees, nv21: true);
    _isBusy = true;
    _pendingMirror = mirrorHorizontal;
    _nv21Controller?.add(frame);
  }

  void pushBgra(
    FaceMeshImage frame, {
    required int rotationDegrees,
    required bool mirrorHorizontal,
  }) {
    if (!_initialized || _isBusy) return;
    _ensureStream(rotationDegrees: rotationDegrees, nv21: false);
    _isBusy = true;
    _pendingMirror = mirrorHorizontal;
    _bgraController?.add(frame);
  }

  void _ensureStream({required int rotationDegrees, required bool nv21}) {
    if (_subscription != null && _streamRotation == rotationDegrees) return;
    _stopStream();
    _pipeline?.resetTracking();
    _streamRotation = rotationDegrees;
    final processor = _streamProcessor;
    if (processor == null) return;

    if (nv21) {
      _nv21Controller = StreamController<FaceMeshNv21Image>();
      _subscription = processor
          .processNv21(
            _nv21Controller!.stream,
            runMeshResolver: (_) => true,
            rotationDegrees: rotationDegrees,
          )
          .listen(_onResult, onError: _onError);
    } else {
      _bgraController = StreamController<FaceMeshImage>();
      _subscription = processor
          .process(
            _bgraController!.stream,
            runMeshResolver: (_) => true,
            rotationDegrees: rotationDegrees,
          )
          .listen(_onResult, onError: _onError);
    }
  }

  void _onResult(FaceMeshInferenceResult result) {
    _isBusy = false;
    final mesh = result.meshResult;
    final rotation = _streamRotation ?? 0;
    if (mesh == null || mesh.landmarks.isEmpty) {
      frameNotifier.value = null;
      return;
    }

    Map<String, double> blends = const {};
    try {
      final raw = _blendshapes?.process(mesh);
      if (raw != null) {
        blends = {
          for (final entry in raw.entries) entry.key.name: entry.value,
        };
      }
    } catch (_) {}

    // Map into unit square with rotation/mirror — painter scales to canvas.
    final normalized = mesh.landmarksAsOffsets(
      targetSize: const Size(1, 1),
      rotationDegrees: rotation,
      mirrorHorizontal: _pendingMirror,
      clampToBounds: true,
    );
    final triangles = mesh.triangles
        .map((t) => List<int>.from(t.indices))
        .toList(growable: false);

    frameNotifier.value = FaceMeshFrame(
      normalizedLandmarks: normalized,
      triangles: triangles,
      blendshapes: blends,
    );
  }

  void _onError(Object error, StackTrace st) {
    _isBusy = false;
    Loggers.error('FaceMeshEngine stream error: $error');
  }

  void _stopStream() {
    _subscription?.cancel();
    _subscription = null;
    _nv21Controller?.close();
    _bgraController?.close();
    _nv21Controller = null;
    _bgraController = null;
    _streamRotation = null;
    _isBusy = false;
  }

  Future<void> dispose() async {
    _stopStream();
    frameNotifier.value = null;
    try {
      _blendshapes?.close();
      _mesh?.close();
      _detector?.close();
    } catch (_) {}
    _blendshapes = null;
    _mesh = null;
    _detector = null;
    _pipeline = null;
    _streamProcessor = null;
    _initialized = false;
  }
}
