import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krimson/screen/camera_screen/camera_screen.dart';
import 'package:krimson/screen/camera_screen/camera_screen_controller.dart';
import 'package:krimson/utilities/asset_res.dart';
import 'package:krimson/utilities/text_style_custom.dart';
import 'package:krimson/utilities/theme_res.dart';

class CameraBottomView extends StatelessWidget {
  final CameraScreenType cameraType;

  const CameraBottomView({super.key, required this.cameraType});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<CameraScreenController>();
    final isStory = cameraType == CameraScreenType.story;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 20, right: 20, top: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!isStory) _DurationSelector(controller: controller),
          if (isStory)
            Text(
              'Tap foto · Hold video',
              style: TextStyleCustom.outFitRegular400(
                color: whitePure(context).withValues(alpha: 0.75),
                fontSize: 12,
              ),
            ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _GalleryButton(onTap: controller.onMediaTap),
              _ShutterButton(controller: controller, isStory: isStory),
              const SizedBox(width: 52, height: 52),
            ],
          ),
        ],
      ),
    );
  }
}

class _DurationSelector extends StatelessWidget {
  final CameraScreenController controller;

  const _DurationSelector({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (!controller.isSecondListShow.value) {
        return Text(
          '${controller.selectedSecond.value}s',
          style: TextStyleCustom.outFitMedium500(
            color: whitePure(context),
            fontSize: 14,
          ),
        );
      }
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: controller.secondsList.map((second) {
          final selected = controller.selectedSecond.value == second;
          return GestureDetector(
            onTap: () => controller.selectedSecond.value = second,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: const EdgeInsets.symmetric(horizontal: 6),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: selected
                    ? whitePure(context)
                    : whitePure(context).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${second}s',
                style: TextStyleCustom.outFitMedium500(
                  color: selected ? blackPure(context) : whitePure(context),
                  fontSize: 13,
                ),
              ),
            ),
          );
        }).toList(),
      );
    });
  }
}

class _GalleryButton extends StatelessWidget {
  final VoidCallback onTap;

  const _GalleryButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: whitePure(context), width: 1.5),
        ),
        clipBehavior: Clip.antiAlias,
        child: Image.asset(
          AssetRes.icUploadGallery,
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}

class _ShutterButton extends StatefulWidget {
  final CameraScreenController controller;
  final bool isStory;

  const _ShutterButton({
    required this.controller,
    required this.isStory,
  });

  @override
  State<_ShutterButton> createState() => _ShutterButtonState();
}

class _ShutterButtonState extends State<_ShutterButton> {
  DateTime? _pressStartedAt;
  bool _recordingFromHold = false;

  void _onPointerDown(_) {
    _pressStartedAt = DateTime.now();
    _recordingFromHold = false;
    if (!widget.isStory) return;
    // Hold > 220ms → video (sin retrasar el tap de foto).
    Future.delayed(const Duration(milliseconds: 220), () {
      if (!mounted || _pressStartedAt == null || _recordingFromHold) return;
      if (widget.controller.isStartingRecording.value) return;
      _recordingFromHold = true;
      widget.controller.onPlayPauseToggle(type: 1);
    });
  }

  void _onPointerUp(_) {
    final started = _pressStartedAt;
    _pressStartedAt = null;
    if (started == null) return;

    if (widget.isStory) {
      if (_recordingFromHold || widget.controller.isStartingRecording.value) {
        widget.controller.onPlayPauseToggle(type: 2);
      } else {
        // Tap corto → foto inmediata.
        widget.controller.onPlayPauseToggle();
      }
      _recordingFromHold = false;
      return;
    }

    widget.controller.onPlayPauseToggle();
  }

  void _onPointerCancel(_) {
    _pressStartedAt = null;
    if (_recordingFromHold || widget.controller.isStartingRecording.value) {
      widget.controller.onPlayPauseToggle(type: 2);
    }
    _recordingFromHold = false;
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    return Obx(() {
      final progress = controller.progress.value;
      final maxSeconds = controller.selectedSecond.value.toDouble();
      final isRecording = controller.isStartingRecording.value;
      final ringProgress =
          maxSeconds <= 0 ? 0.0 : (progress / maxSeconds).clamp(0.0, 1.0);
      final ready = controller.isCaptureReady;

      return Listener(
        onPointerDown: ready ? _onPointerDown : null,
        onPointerUp: ready ? _onPointerUp : null,
        onPointerCancel: ready ? _onPointerCancel : null,
        child: Opacity(
          opacity: ready ? 1 : 0.45,
          child: SizedBox(
            width: 84,
            height: 84,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 84,
                  height: 84,
                  child: CircularProgressIndicator(
                    value: isRecording ? ringProgress : (ready ? 0 : null),
                    strokeWidth: 4,
                    backgroundColor: whitePure(context).withValues(alpha: 0.25),
                    valueColor:
                        AlwaysStoppedAnimation(themeAccentSolid(context)),
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: isRecording ? 34 : 68,
                  height: isRecording ? 34 : 68,
                  decoration: BoxDecoration(
                    color: isRecording
                        ? themeAccentSolid(context)
                        : whitePure(context),
                    shape: isRecording ? BoxShape.rectangle : BoxShape.circle,
                    borderRadius:
                        isRecording ? BorderRadius.circular(8) : null,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}
