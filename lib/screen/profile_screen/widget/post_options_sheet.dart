import 'package:figma_squircle_updated/figma_squircle.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krimson/common/controller/base_controller.dart';
import 'package:krimson/common/manager/session_manager.dart';
import 'package:krimson/languages/languages_keys.dart';
import 'package:krimson/screen/camera_screen/camera_screen.dart';
import 'package:krimson/screen/create_feed_screen/create_feed_screen.dart';
import 'package:krimson/screen/profile_screen/profile_screen_controller.dart';
import 'package:krimson/utilities/asset_res.dart';
import 'package:krimson/utilities/text_style_custom.dart';
import 'package:krimson/utilities/theme_res.dart';

enum PublishType { goLive, createPost, createReel, createStory }

class PostOptionsSheet extends StatelessWidget {
  final ProfileScreenController controller;
  final void Function(PublishType type)? onChanged;

  const PostOptionsSheet({
    super.key,
    required this.controller,
    this.onChanged,
  });

  bool get _canGoLive {
    final user = SessionManager.instance.getUser();
    if (user == null) return false;
    return user.canGoLive == 1 || user.getLevel.canGoLive == 1;
  }

  @override
  Widget build(BuildContext context) {
    final options = [
      _PublishOption(
        type: PublishType.createStory,
        title: LKey.story.tr,
        icon: AssetRes.icStory,
      ),
      _PublishOption(
        type: PublishType.createReel,
        title: LKey.reels.tr,
        icon: AssetRes.icReel,
      ),
      _PublishOption(
        type: PublishType.createPost,
        title: LKey.createFeed.tr,
        icon: AssetRes.icPost,
      ),
      _PublishOption(
        type: PublishType.goLive,
        title: LKey.goLive.tr,
        icon: AssetRes.icLive,
      ),
    ];

    return Container(
      decoration: ShapeDecoration(
        color: whitePure(context),
        shape: const SmoothRectangleBorder(
          borderRadius: SmoothBorderRadius.vertical(
            top: SmoothRadius(cornerRadius: 24, cornerSmoothing: 1),
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 4,
                width: 48,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: bgGrey(context),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              Text(
                LKey.publish.tr,
                style: TextStyleCustom.unboundedSemiBold600(
                  color: textDarkGrey(context),
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 16),
              ...options.map((option) => _OptionTile(
                    option: option,
                    onTap: () => _onSelect(option.type),
                  )),
            ],
          ),
        ),
      ),
    );
  }

  void _onSelect(PublishType type) {
    if (type == PublishType.goLive && !_canGoLive) {
      Get.back();
      BaseController.share.showSnackBar(LKey.liveLockedUntilLevel.tr);
      return;
    }

    Get.back();
    onChanged?.call(type);

    switch (type) {
      case PublishType.goLive:
        // Caller (reels/dashboard) switches to live tab via onChanged.
        break;
      case PublishType.createPost:
        if (kIsWeb) {
          Get.to(() => const CreateFeedScreen(createType: CreateFeedType.feed));
        } else {
          Get.to(() => const CameraScreen(cameraType: CameraScreenType.post));
        }
        break;
      case PublishType.createReel:
        if (kIsWeb) {
          BaseController.share.showSnackBar(
            'Camera is not available on web. Use the Android/iOS app.',
          );
        } else {
          Get.to(() => const CameraScreen(cameraType: CameraScreenType.post));
        }
        break;
      case PublishType.createStory:
        if (kIsWeb) {
          BaseController.share.showSnackBar(
            'Camera is not available on web. Use the Android/iOS app.',
          );
        } else {
          Get.to(() => const CameraScreen(cameraType: CameraScreenType.story));
        }
        break;
    }
  }
}

class _PublishOption {
  final PublishType type;
  final String title;
  final String icon;

  const _PublishOption({
    required this.type,
    required this.title,
    required this.icon,
  });
}

class _OptionTile extends StatelessWidget {
  final _PublishOption option;
  final VoidCallback onTap;

  const _OptionTile({required this.option, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: bgLightGrey(context),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                height: 42,
                width: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: whitePure(context),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Image.asset(
                  option.icon,
                  height: 22,
                  width: 22,
                  color: textDarkGrey(context),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  option.title,
                  style: TextStyleCustom.outFitMedium500(
                    color: textDarkGrey(context),
                    fontSize: 15,
                  ),
                ),
              ),
              Image.asset(
                AssetRes.icRightArrow,
                height: 18,
                width: 18,
                color: textLightGrey(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
