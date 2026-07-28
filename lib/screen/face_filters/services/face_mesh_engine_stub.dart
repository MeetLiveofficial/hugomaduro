import 'package:flutter/foundation.dart';
import 'package:krimson/screen/face_filters/models/face_mesh_frame.dart';

class FaceMeshEngine {
  FaceMeshEngine();

  final ValueNotifier<FaceMeshFrame?> frameNotifier =
      ValueNotifier<FaceMeshFrame?>(null);

  bool get isInitialized => false;

  Future<void> initialize() async {
    if (kDebugMode) {
      debugPrint('FaceMeshEngine stub: unavailable on this platform');
    }
  }

  void pushNv21(
    dynamic frame, {
    required int rotationDegrees,
    required bool mirrorHorizontal,
  }) {}

  void pushBgra(
    dynamic frame, {
    required int rotationDegrees,
    required bool mirrorHorizontal,
  }) {}

  Future<void> dispose() async {
    frameNotifier.value = null;
  }
}
