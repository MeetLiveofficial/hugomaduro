import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krimson/common/widget/black_gradient_shadow.dart';
import 'package:krimson/common/widget/custom_back_button.dart';
import 'package:krimson/common/widget/custom_border_round_icon.dart';
import 'package:krimson/screen/camera_screen/camera_screen_controller.dart';
import 'package:krimson/screen/camera_screen/widget/camera_bottom_view.dart';
import 'package:krimson/screen/camera_screen/widget/camera_top_view.dart';
import 'package:krimson/screen/face_filters/widgets/deep_ar_preview_stack.dart';
import 'package:krimson/screen/face_filters/widgets/face_camera_preview_stack.dart';
import 'package:krimson/screen/face_filters/widgets/face_filter_carousel.dart';
import 'package:krimson/screen/selected_music_sheet/selected_music_sheet_controller.dart';
import 'package:krimson/utilities/asset_res.dart';
import 'package:krimson/utilities/text_style_custom.dart';
import 'package:krimson/utilities/theme_res.dart';

enum CameraScreenType { post, story }

class CameraScreen extends StatelessWidget {
  final CameraScreenType cameraType;
  final SelectedMusic? selectedMusic;

  const CameraScreen({super.key, required this.cameraType, this.selectedMusic});

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return Scaffold(
        backgroundColor: blackPure(context),
        body: SafeArea(
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: CustomBackButton(
                  padding: const EdgeInsets.all(15),
                  color: whitePure(context),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.videocam_off_outlined,
                          size: 72, color: textLightGrey(context)),
                      const SizedBox(height: 20),
                      Text(
                        'Camera Unavailable',
                        style: TextStyleCustom.unboundedSemiBold600(
                          color: whitePure(context),
                          fontSize: 18,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Camera capture is not available in the web browser. Use the Android or iOS app to record posts, reels, and stories.',
                        style: TextStyleCustom.outFitRegular400(
                          color: textLightGrey(context),
                          fontSize: 15,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final controller =
        Get.put(CameraScreenController(cameraType, selectedMusic.obs));

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: blackPure(context),
        resizeToAvoidBottomInset: false,
        body: Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(child: _buildCameraPreview(controller)),
            const Align(
              alignment: Alignment.bottomCenter,
              child: BlackGradientShadow(height: 180),
            ),
            _buildCameraUI(controller),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraPreview(CameraScreenController controller) {
    return Obx(() {
      if (controller.useDeepAr) {
        return const DeepArPreviewStack();
      }
      return FaceCameraPreviewStack(
        boundaryKey: controller.previewBoundaryKey,
        controller: controller.cameraController,
        isReady: controller.isCameraReady.value,
        nativeAspectRatio: controller.nativeAspectRatio,
        frameListenable: controller.meshEngine.frameNotifier,
        effectId: controller.selectedFilterId.value,
        beauty: controller.filterPipeline.beauty,
      );
    });
  }

  Widget _buildCameraUI(CameraScreenController controller) {
    return SafeArea(
      child: Column(
        children: [
          CameraTopView(cameraType: cameraType),
          const Spacer(),
          if (cameraType == CameraScreenType.story)
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: Padding(
                padding: const EdgeInsets.only(right: 17, bottom: 12),
                child: CustomBorderRoundIcon(
                  image: AssetRes.icText,
                  onTap: controller.onNavigateTextStory,
                ),
              ),
            ),
          Obx(() {
            if (!controller.isEffectShow.value) {
              return const SizedBox.shrink();
            }
            if (controller.useDeepAr) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: DeepArFilterCarousel(
                  filters: controller.deepAr.filters,
                  selectedId: controller.selectedDeepArFilterId.value,
                  onSelected: controller.onDeepArFilterSelected,
                ),
              );
            }
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: FaceFilterCarousel(
                selectedId: controller.selectedFilterId.value,
                effects: controller.filterCatalog.effects.toList(),
                onSelected: controller.onFilterSelected,
              ),
            );
          }),
          CameraBottomView(cameraType: cameraType),
        ],
      ),
    );
  }
}
