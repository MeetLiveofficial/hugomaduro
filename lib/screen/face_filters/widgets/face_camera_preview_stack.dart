import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:krimson/common/widget/loader_widget.dart';
import 'package:krimson/screen/face_filters/models/face_filter_effect.dart';
import 'package:krimson/screen/face_filters/models/face_mesh_frame.dart';
import 'package:krimson/screen/face_filters/widgets/beauty_camera_preview.dart';
import 'package:krimson/screen/face_filters/widgets/face_filter_overlay.dart';
import 'package:krimson/screen/face_filters/widgets/portrait_locked_camera_preview.dart';

/// Full-bleed preview. Overlay shares the camera coordinate space.
///
/// Usa [PortraitLockedCameraPreview] para evitar preview de lado en emuladores.
/// Si se pasa [beauty], aplica tono/suavizado sobre el preview.
class FaceCameraPreviewStack extends StatelessWidget {
  const FaceCameraPreviewStack({
    super.key,
    required this.boundaryKey,
    required this.controller,
    required this.isReady,
    required this.nativeAspectRatio,
    required this.frameListenable,
    required this.effectId,
    this.beauty,
    this.showBeautySlider = false,
  });

  final GlobalKey boundaryKey;
  final CameraController? controller;
  final bool isReady;
  final double nativeAspectRatio;
  final ValueListenable<FaceMeshFrame?> frameListenable;
  final FaceFilterId effectId;
  final BeautyShaderController? beauty;
  final bool showBeautySlider;

  @override
  Widget build(BuildContext context) {
    if (!isReady || controller == null || !controller!.value.isInitialized) {
      return const ColoredBox(color: Colors.black, child: LoaderWidget());
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final displayW = constraints.maxWidth;
        final displayH = constraints.maxHeight;
        final targetAspect =
            nativeAspectRatio <= 0 ? (3 / 4) : nativeAspectRatio;
        var boxW = displayW;
        var boxH = boxW / targetAspect;
        if (boxH < displayH) {
          boxH = displayH;
          boxW = boxH * targetAspect;
        }

        Widget preview = PortraitLockedCameraPreview(
          controller!,
          child: FaceFilterOverlay(
            frameListenable: frameListenable,
            effectId: effectId,
          ),
        );

        if (beauty != null) {
          preview = BeautyFiltered(controller: beauty!, child: preview);
        }

        return Stack(
          fit: StackFit.expand,
          children: [
            RepaintBoundary(
              key: boundaryKey,
              child: ClipRect(
                child: OverflowBox(
                  maxWidth: boxW,
                  maxHeight: boxH,
                  alignment: Alignment.center,
                  child: SizedBox(
                    width: boxW,
                    height: boxH,
                    child: preview,
                  ),
                ),
              ),
            ),
            if (showBeautySlider && beauty != null)
              Positioned(
                left: 16,
                right: 16,
                bottom: 8,
                child: BeautyIntensitySliderBar(controller: beauty!),
              ),
          ],
        );
      },
    );
  }
}
