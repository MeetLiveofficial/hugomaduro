import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:krimson/common/widget/loader_widget.dart';
import 'package:krimson/screen/face_filters/models/face_filter_effect.dart';
import 'package:krimson/screen/face_filters/models/face_mesh_frame.dart';
import 'package:krimson/screen/face_filters/widgets/face_filter_overlay.dart';

/// Full-bleed preview. Overlay shares the same FittedBox space as CameraPreview
/// (critical for correct mesh alignment).
class FaceCameraPreviewStack extends StatelessWidget {
  const FaceCameraPreviewStack({
    super.key,
    required this.boundaryKey,
    required this.controller,
    required this.isReady,
    required this.nativeAspectRatio,
    required this.frameListenable,
    required this.effectId,
  });

  final GlobalKey boundaryKey;
  final CameraController? controller;
  final bool isReady;
  final double nativeAspectRatio;
  final ValueNotifier<FaceMeshFrame?> frameListenable;
  final FaceFilterId effectId;

  @override
  Widget build(BuildContext context) {
    if (!isReady || controller == null || !controller!.value.isInitialized) {
      return const ColoredBox(color: Colors.black, child: LoaderWidget());
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final displayW = constraints.maxWidth;
        // Keep native sensor ratio inside FittedBox.cover (package example).
        final nativeH = displayW / nativeAspectRatio;

        return RepaintBoundary(
          key: boundaryKey,
          child: ClipRect(
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: displayW,
                height: nativeH,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CameraPreview(controller!),
                    FaceFilterOverlay(
                      frameListenable: frameListenable,
                      effectId: effectId,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
