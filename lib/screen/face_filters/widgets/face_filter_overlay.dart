import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:krimson/screen/face_filters/models/face_filter_effect.dart';
import 'package:krimson/screen/face_filters/models/face_mesh_frame.dart';
import 'package:krimson/screen/face_filters/widgets/face_filter_painter.dart';

class FaceFilterOverlay extends StatelessWidget {
  const FaceFilterOverlay({
    super.key,
    required this.frameListenable,
    required this.effectId,
  });

  final ValueListenable<FaceMeshFrame?> frameListenable;
  final FaceFilterId effectId;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<FaceMeshFrame?>(
      valueListenable: frameListenable,
      builder: (context, frame, _) {
        return CustomPaint(
          painter: FaceFilterPainter(frame: frame, effectId: effectId),
          child: const SizedBox.expand(),
        );
      },
    );
  }
}
