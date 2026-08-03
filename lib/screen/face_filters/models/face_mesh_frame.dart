import 'package:flutter/material.dart';
import 'package:krimson/screen/face_filters/models/face_filter_effect.dart';

/// One inference frame ready for overlay painting.
///
/// [normalizedLandmarks] are already rotation/mirror-mapped into 0..1 space
/// (same transform as mediapipe FaceMeshPainter).
class FaceMeshFrame {
  const FaceMeshFrame({
    required this.normalizedLandmarks,
    this.triangles = const [],
    this.blendshapes = const {},
  });

  final List<Offset> normalizedLandmarks;
  final List<List<int>> triangles;
  final Map<String, double> blendshapes;

  Offset? landmark(int index, Size canvasSize) {
    if (index < 0 || index >= normalizedLandmarks.length) return null;
    final n = normalizedLandmarks[index];
    return Offset(n.dx * canvasSize.width, n.dy * canvasSize.height);
  }

  List<Offset> allLandmarks(Size canvasSize) {
    return [
      for (final n in normalizedLandmarks)
        Offset(n.dx * canvasSize.width, n.dy * canvasSize.height),
    ];
  }

  double blend(String key, [double fallback = 0]) =>
      blendshapes[key] ?? fallback;

  double get smileIntensity {
    final left = blend('mouthSmileLeft');
    final right = blend('mouthSmileRight');
    return ((left + right) / 2).clamp(0.0, 1.0);
  }

  double get eyeOpenIntensity {
    final blinkL = blend('eyeBlinkLeft');
    final blinkR = blend('eyeBlinkRight');
    return (1 - ((blinkL + blinkR) / 2)).clamp(0.0, 1.0);
  }

  Offset? noseTip(Size s) => landmark(FaceMeshLandmarkIndex.noseTip, s);
  Offset? forehead(Size s) => landmark(FaceMeshLandmarkIndex.forehead, s);
  Offset? chin(Size s) => landmark(FaceMeshLandmarkIndex.chin, s);
  Offset? leftEyeOuter(Size s) =>
      landmark(FaceMeshLandmarkIndex.leftEyeOuter, s);
  Offset? rightEyeOuter(Size s) =>
      landmark(FaceMeshLandmarkIndex.rightEyeOuter, s);
  Offset? leftCheek(Size s) => landmark(FaceMeshLandmarkIndex.leftCheek, s);
  Offset? rightCheek(Size s) => landmark(FaceMeshLandmarkIndex.rightCheek, s);
  Offset? upperLip(Size s) => landmark(FaceMeshLandmarkIndex.upperLip, s);
  Offset? leftIris(Size s) => landmark(FaceMeshLandmarkIndex.leftIris, s);
  Offset? rightIris(Size s) => landmark(FaceMeshLandmarkIndex.rightIris, s);
}
