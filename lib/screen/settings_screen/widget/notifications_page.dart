import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krimson/common/manager/app_role.dart';
import 'package:krimson/common/widget/brand_controls.dart';
import 'package:krimson/common/widget/custom_app_bar.dart';
import 'package:krimson/common/widget/custom_toggle.dart';
import 'package:krimson/languages/languages_keys.dart';
import 'package:krimson/screen/notification_screen/notification_screen.dart';
import 'package:krimson/screen/settings_screen/settings_screen.dart';
import 'package:krimson/screen/settings_screen/settings_screen_controller.dart';
import 'package:krimson/screen/settings_screen/widget/setting_icon_text_with_arrow.dart';
import 'package:krimson/utilities/asset_res.dart';
import 'package:krimson/utilities/color_res.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.isRegistered<SettingsScreenController>()
        ? Get.find<SettingsScreenController>()
        : Get.put(SettingsScreenController());
    final isAgency = AppRole.isAgency();
    return Scaffold(
      body: Column(
        children: [
          CustomAppBar(title: LKey.notifications.tr),
          Expanded(
            child: Obx(() {
              final user = controller.myUser.value;
              return ListView(
                padding: const EdgeInsets.only(bottom: 32),
                children: [
                  SettingLabel(title: LKey.activity),
                  BrandPanel(
                    child: SettingIconTextWithArrow(
                      icon: AssetRes.icNotification_1,
                      iconColor: settingRowIcon(ColorRes.crimson),
                      title: LKey.notifications,
                      onTap: () {
                        Get.to(() => const NotificationScreen());
                      },
                    ),
                  ),
                  SettingLabel(title: LKey.notifications),
                  BrandPanel(
                    child: Column(
                      children: [
                        if (!isAgency) ...[
                          _toggle(
                            controller,
                            icon: AssetRes.icHeart,
                            color: settingRowIcon(ColorRes.crimson),
                            title: LKey.postLikes,
                            isOn: (user?.notifyPostLike ?? 1) == 1,
                            type: SettingToggle.notifyPostLike,
                          ),
                          _toggle(
                            controller,
                            icon: AssetRes.icPostComment,
                            color: settingRowIcon(ColorRes.mlPurple),
                            title: LKey.commentsOnPost,
                            isOn: (user?.notifyPostComment ?? 1) == 1,
                            type: SettingToggle.notifyPostComment,
                          ),
                          _toggle(
                            controller,
                            icon: AssetRes.icFollow,
                            color: settingRowIcon(ColorRes.roseBorder),
                            title: LKey.newFollowers,
                            isOn: (user?.notifyFollow ?? 1) == 1,
                            type: SettingToggle.notifyFollow,
                          ),
                          _toggle(
                            controller,
                            icon: AssetRes.icComment,
                            color: settingRowIcon(ColorRes.darkPurple),
                            title: LKey.mentions,
                            isOn: (user?.notifyMention ?? 1) == 1,
                            type: SettingToggle.notifyMention,
                          ),
                        ],
                        _toggle(
                          controller,
                          icon: AssetRes.icGift,
                          color: settingRowIcon(ColorRes.crimsonAlt),
                          title: LKey.giftsReceived,
                          isOn: (user?.notifyGiftReceived ?? 1) == 1,
                          type: SettingToggle.notifyGiftReceived,
                        ),
                        _toggle(
                          controller,
                          icon: AssetRes.icChat,
                          color: settingRowIcon(ColorRes.crimson),
                          title: LKey.chatMessage,
                          isOn: (user?.notifyChat ?? 1) == 1,
                          type: SettingToggle.notifyChat,
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _toggle(
    SettingsScreenController controller, {
    required String icon,
    required Color color,
    required String title,
    required bool isOn,
    required SettingToggle type,
  }) {
    return SettingIconTextWithArrow(
      icon: icon,
      iconColor: color,
      title: title,
      widget: CustomToggle(
        isOn: isOn.obs,
        onChanged: (value) {
          controller.onChangedToggle(value, type);
        },
      ),
    );
  }
}
