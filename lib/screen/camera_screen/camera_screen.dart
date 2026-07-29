import 'package:deepar_flutter_plus/deepar_flutter_plus.dart';
import 'package:figma_squircle_updated/figma_squircle.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:retrytech_plugin/retrytech_plugin.dart';
import 'package:krimson/common/widget/black_gradient_shadow.dart';
import 'package:krimson/common/widget/custom_back_button.dart';
import 'package:krimson/common/widget/custom_border_round_icon.dart';
import 'package:krimson/common/widget/loader_widget.dart';
import 'package:krimson/screen/camera_screen/camera_screen_controller.dart';
import 'package:krimson/screen/camera_screen/widget/camera_bottom_view.dart';
import 'package:krimson/screen/camera_screen/widget/camera_top_view.dart';
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
                      Icon(
                        Icons.videocam_off_outlined,
                        size: 72,
                        color: textLightGrey(context),
                      ),
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
          alignment: Alignment.center,
          children: [
            _buildCameraPreview(controller),
            const Align(
              alignment: Alignment.bottomCenter,
              child: BlackGradientShadow(
                height: 150,
              ),
            ),
            _buildCameraUI(context, controller),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraPreview(CameraScreenController controller) {
    return AspectRatio(
      aspectRatio: 0.52,
      child: ClipSmoothRect(
        radius: SmoothBorderRadius(cornerRadius: 20, cornerSmoothing: 1),
        child: controller.isDeepAr
            ? Obx(
                () {
                  DeepArControllerPlus deepArControllerPlus =
                      controller.deepArControllerPlus.value;
                  return controller.isDeepARInitialized.value
                      ? Transform.scale(
                          scale: deepArControllerPlus.aspectRatio *
                              0.62, //change value as needed
                          child: DeepArPreviewPlus(deepArControllerPlus),
                        )
                      : const LoaderWidget();
                },
              )
            : RetrytechPlugin.shared.cameraView,
      ),
    );
  }

  Widget _buildCameraUI(
      BuildContext context, CameraScreenController controller) {
    return SafeArea(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          CameraTopView(cameraType: cameraType),
          if (cameraType == CameraScreenType.story)
            _buildTextStoryButton(controller),
          CameraBottomView(cameraType: cameraType),
        ],
      ),
    );
  }

  Widget _buildTextStoryButton(CameraScreenController controller) {
    return Align(
      alignment: AlignmentDirectional.centerEnd,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 17),
        child: CustomBorderRoundIcon(
          image: AssetRes.icText,
          onTap: controller.onNavigateTextStory,
        ),
      ),
    );
  }
}
