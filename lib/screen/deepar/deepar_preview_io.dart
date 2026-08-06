import 'package:deepar_flutter_plus/deepar_flutter_plus.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krimson/screen/deepar/deepar_camera_controller.dart';
import 'package:krimson/utilities/color_res.dart';

/// Preview DeepAR a pantalla completa con estados loading/error.
class DeepArPreview extends StatelessWidget {
  const DeepArPreview({
    super.key,
    required this.controller,
    this.fit = BoxFit.cover,
  });

  final DeepArCameraController controller;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final ready = controller.isReady.value;
      final native = controller.native;
      if (!ready || native == null) {
        return ColoredBox(
          color: ColorRes.bgVoid,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(color: ColorRes.accentRose),
                const SizedBox(height: 12),
                Text(
                  controller.statusMessage.value.isEmpty
                      ? 'Starting DeepAR…'
                      : controller.statusMessage.value,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: ColorRes.whitePure.withValues(alpha: 0.75),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        );
      }

      final preview = DeepArPreviewPlus(native);
      if (fit == BoxFit.cover) {
        return SizedBox.expand(
          child: FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: MediaQuery.sizeOf(context).width,
              height: MediaQuery.sizeOf(context).height,
              child: preview,
            ),
          ),
        );
      }
      return preview;
    });
  }
}
