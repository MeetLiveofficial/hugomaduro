import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krimson/common/manager/session_manager.dart';
import 'package:krimson/common/widget/custom_popup_menu_button.dart';
import 'package:krimson/languages/languages_keys.dart';
import 'package:krimson/screen/feed_screen/feed_screen_controller.dart';
import 'package:krimson/screen/home_screen/widget/home_mode_switcher.dart';
import 'package:krimson/screen/notification_screen/notification_screen.dart';
import 'package:krimson/utilities/asset_res.dart';
import 'package:krimson/utilities/color_res.dart';
import 'package:krimson/utilities/text_style_custom.dart';
import 'package:krimson/utilities/theme_res.dart';

class FeedTopView extends StatelessWidget {
  final FeedScreenController controller;

  const FeedTopView({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 6, 8, 8),
        child: SizedBox(
          height: 44,
          child: Row(
            children: [
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: CustomPopupMenuButton(
                    items: [
                      MenuItem(
                          LKey.discover.tr,
                          () => controller
                              .onChangeCategory(PostCategory.discover)),
                      MenuItem(
                          LKey.nearby.tr,
                          () =>
                              controller.onChangeCategory(PostCategory.nearby)),
                      MenuItem(
                          LKey.following.tr,
                          () => controller
                              .onChangeCategory(PostCategory.following)),
                    ],
                    child: Obx(
                      () => Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                                controller.selectedPostCategory.value.title
                                    .toUpperCase(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyleCustom.unboundedBold700(
                                    color: ColorRes.whitePure, fontSize: 13)),
                          ),
                          const SizedBox(width: 5),
                          Image.asset(AssetRes.icDownArrow,
                              color: ColorRes.whitePure, height: 8, width: 8),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const HomeModeSwitcher(),
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: InkWell(
                    onTap: () {
                      Get.to(() => const NotificationScreen());
                      int count = SessionManager.instance.notifyCount.value;
                      SessionManager.instance.setNotifyCount(-count);
                      SessionManager.instance.notifyCount.value = 0;
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: SizedBox(
                      width: 40,
                      height: 40,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Image.asset(AssetRes.icNotification,
                              width: 22,
                              height: 22,
                              color: ColorRes.whitePure),
                          Obx(() {
                            int notifyCount =
                                SessionManager.instance.notifyCount.value;
                            if (notifyCount <= 0) {
                              return const SizedBox();
                            }
                            return Align(
                              alignment: Alignment.topRight,
                              child: Container(
                                height: 16,
                                width: 16,
                                margin: const EdgeInsets.only(top: 2, right: 2),
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                    color: themeAccentSolid(context),
                                    shape: BoxShape.circle),
                                child: Text(
                                  '$notifyCount',
                                  style: TextStyleCustom.outFitRegular400(
                                      color: whitePure(context), fontSize: 10),
                                ),
                              ),
                            );
                          })
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
