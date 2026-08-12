import 'package:figma_squircle_updated/figma_squircle.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krimson/common/manager/app_role.dart';
import 'package:krimson/common/manager/content_protection.dart';
import 'package:krimson/common/widget/custom_app_bar.dart';
import 'package:krimson/common/widget/custom_drop_down.dart';
import 'package:krimson/common/widget/custom_toggle.dart';
import 'package:krimson/languages/languages_keys.dart';
import 'package:krimson/model/user_model/user_model.dart';
import 'package:krimson/screen/blocked_user_screen/blocked_user_screen.dart';
import 'package:krimson/screen/coin_wallet_screen/coin_wallet_screen.dart';
import 'package:krimson/screen/edit_profile_screen/edit_profile_screen.dart';
import 'package:krimson/screen/privilege_screen/privilege_hub_screen.dart';
import 'package:krimson/screen/qr_code_screen/qr_code_screen.dart';
import 'package:krimson/screen/select_language_screen/select_language_screen.dart';
import 'package:krimson/screen/settings_screen/settings_screen_controller.dart';
import 'package:krimson/screen/settings_screen/widget/notifications_page.dart';
import 'package:krimson/screen/settings_screen/widget/setting_icon_text_with_arrow.dart';
import 'package:krimson/screen/subscription_screen/subscription_screen.dart';
import 'package:krimson/screen/tasks_screen/tasks_screen.dart';
import 'package:krimson/screen/term_and_privacy_screen/term_and_privacy_screen.dart';
import 'package:krimson/screen/withdrawals_screen/withdrawals_screen.dart';
import 'package:krimson/utilities/asset_res.dart';
import 'package:krimson/utilities/style_res.dart';
import 'package:krimson/utilities/text_style_custom.dart';
import 'package:krimson/utilities/theme_res.dart';

class SettingsScreen extends StatelessWidget {
  final Function(User? user)? onUpdateUser;

  const SettingsScreen({super.key, this.onUpdateUser});

  @override
  Widget build(BuildContext context) {
    if (Get.isRegistered<SettingsScreenController>()) {
      Get.delete<SettingsScreenController>(force: true);
    }
    final controller = Get.put(SettingsScreenController());
    return Scaffold(
        body: Column(
      children: [
        CustomAppBar(title: LKey.settings.tr),
        Expanded(
            child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SubscriptionCard(
                  controller: controller, onUpdateUser: onUpdateUser),
              SettingLabel(title: LKey.personal),
              SettingIconTextWithArrow(
                icon: AssetRes.icEdit,
                title: LKey.editProfile,
                onTap: () {
                  Get.to(() => EditProfileScreen(onUpdateUser: onUpdateUser));
                },
              ),
              SettingIconTextWithArrow(
                icon: AssetRes.icLanguage_1,
                title: LKey.languages,
                onTap: () {
                  Get.to(() => const SelectLanguageScreen(
                      languageNavigationType:
                          LanguageNavigationType.fromSetting));
                },
              ),
              SettingIconTextWithArrow(
                icon: AssetRes.icBlock,
                title: LKey.blockedUsers,
                onTap: () {
                  Get.to(() => const BlockedUserScreen());
                },
              ),
              if (ContentProtection.canShare)
                SettingIconTextWithArrow(
                  icon: AssetRes.icQrCode_1,
                  title: LKey.myQrCode,
                  onTap: () {
                    Get.to(() => const QrCodeScreen());
                  },
                ),
              // Streamers no recargan: solo retiros. Clientes ven Coin Wallet.
              if (AppRole.isStreamer())
                SettingIconTextWithArrow(
                  icon: AssetRes.icWallet,
                  title: LKey.withdrawals,
                  onTap: () {
                    Get.to(() => const WithdrawalsScreen());
                  },
                )
              else
                SettingIconTextWithArrow(
                  icon: AssetRes.icWallet,
                  title: LKey.coinWallet,
                  onTap: () {
                    Get.to(() => const CoinWalletScreen());
                  },
                ),
              if (AppRole.canAccessTasks())
                SettingIconTextWithArrow(
                  icon: AssetRes.icVideoRequest,
                  title: LKey.tasks,
                  onTap: () {
                    Get.to(() => const TasksScreen());
                  },
                ),
              SettingIconTextWithArrow(
                icon: AssetRes.icVideoRequest,
                title: LKey.privilegeHub,
                onTap: () {
                  Get.to(() => const PrivilegeHubScreen());
                },
              ),
              SettingLabel(title: LKey.privacy),
              Obx(
                () => SettingIconTextWithArrow(
                  icon: AssetRes.icEye_1,
                  title: LKey.whoCanSeePosts,
                  widget: CustomDropDownBtn<WhoCanSeePost>(
                    items: WhoCanSeePost.values,
                    onChanged: controller.isUpdateApiCalled.value
                        ? null
                        : controller.onChangedWhoCanSeePost,
                    selectedValue: controller.selectedWhoCanSeePost.value,
                    style: TextStyleCustom.outFitRegular400(
                        fontSize: 15, color: textLightGrey(context)),
                    getTitle: (value) => value.title,
                  ),
                ),
              ),
              Obx(
                () {
                  return SettingIconTextWithArrow(
                    icon: AssetRes.icEye_1,
                    title: LKey.showMyFollowings,
                    widget: CustomToggle(
                      isOn: (controller.myUser.value?.showMyFollowing == 1).obs,
                      onChanged: (value) {
                        controller.onChangedToggle(
                            value, SettingToggle.showMyFollowings);
                      },
                    ),
                  );
                },
              ),
              Obx(
                () {
                  return SettingIconTextWithArrow(
                    icon: AssetRes.icMessage,
                    title: LKey.showChatBtn,
                    widget: CustomToggle(
                      isOn: (controller.myUser.value?.receiveMessage == 1).obs,
                      onChanged: (value) async {
                        controller.onChangedToggle(
                            value, SettingToggle.receiveMessage);
                      },
                    ),
                  );
                },
              ),
              if (AppRole.isStreamer(controller.myUser.value))
                Obx(
                  () {
                    final enabled =
                        (controller.myUser.value?.matchEnabled ?? 1) == 1;
                    return SettingIconTextWithArrow(
                      icon: AssetRes.icEye_1,
                      title: LKey.receiveMatch,
                      widget: CustomToggle(
                        isOn: enabled.obs,
                        onChanged: (value) async {
                          controller.onChangedToggle(
                              value, SettingToggle.matchEnabled);
                        },
                      ),
                    );
                  },
                ),
              SettingIconTextWithArrow(
                icon: AssetRes.icNotification_1,
                title: LKey.notifications,
                onTap: () {
                  Get.to(() => const NotificationsPage());
                },
              ),
              SettingLabel(title: LKey.general),
              SettingIconTextWithArrow(
                icon: AssetRes.icReport,
                title: LKey.termsOfUse,
                onTap: () {
                  Get.to(() => const TermAndPrivacyScreen(
                      type: TermAndPrivacyType.termAndCondition));
                },
              ),
              SettingIconTextWithArrow(
                icon: AssetRes.icReport,
                title: LKey.privacyPolicy,
                onTap: () {
                  Get.to(() => const TermAndPrivacyScreen(
                      type: TermAndPrivacyType.privacyPolicy));
                },
              ),
              SettingIconTextWithArrow(
                icon: AssetRes.icLogout,
                title: LKey.logOut,
                onTap: controller.onLogout,
                widget: const SizedBox(),
              ),
            ],
          ),
        ))
      ],
    ));
  }
}

class SubscriptionCard extends StatefulWidget {
  final SettingsScreenController controller;
  final Function(User? user)? onUpdateUser;

  const SubscriptionCard(
      {super.key, required this.controller, this.onUpdateUser});

  @override
  State<SubscriptionCard> createState() => _SubscriptionCardState();
}

class _SubscriptionCardState extends State<SubscriptionCard> {
  @override
  Widget build(BuildContext context) {
    return Obx(() {
      bool isVerify = widget.controller.myUser.value?.isVerify == 1;
      return InkWell(
        onTap: () {
          if (!isVerify) {
            Get.to<bool>(
                    () => SubscriptionScreen(onUpdateUser: widget.onUpdateUser))
                ?.then((value) {
              if (value == true) {
                widget.controller.myUser.update((val) => val?.isVerify = 1);
              }
            });
          }
        },
        child: Container(
          height: 47,
          padding: const EdgeInsets.symmetric(horizontal: 15),
          margin: const EdgeInsets.all(5),
          decoration: ShapeDecoration(
              shape: SmoothRectangleBorder(
                  borderRadius:
                      SmoothBorderRadius(cornerRadius: 7, cornerSmoothing: 1)),
              gradient: StyleRes.themeGradient),
          child: Row(
            spacing: 11,
            children: [
              Image.asset(AssetRes.icPro, width: 24, height: 24),
              Expanded(
                child: RichText(
                  text: TextSpan(
                      text: isVerify ? LKey.youAre.tr : LKey.become.tr,
                      style: TextStyleCustom.outFitRegular400(
                          color: whitePure(context), fontSize: 15),
                      children: [
                        TextSpan(
                            text: ' ${LKey.plus.tr} ',
                            style: TextStyleCustom.outFitExtraBold800(
                                color: whitePure(context), fontSize: 15)),
                        TextSpan(
                            text: isVerify ? LKey.member.tr : '',
                            style: TextStyleCustom.outFitRegular400(
                                color: whitePure(context), fontSize: 15)),
                      ]),
                ),
              ),
              if (!isVerify)
                Image.asset(AssetRes.icForwardArrow,
                    width: 24, height: 20, color: whitePure(context))
            ],
          ),
        ),
      );
    });
  }
}

class SettingLabel extends StatelessWidget {
  final String title;

  const SettingLabel({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 39,
      width: double.infinity,
      color: bgMediumGrey(context),
      alignment: AlignmentDirectional.centerStart,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      margin: const EdgeInsets.symmetric(vertical: 1),
      child: Text(
        title.tr.toUpperCase(),
        style: TextStyleCustom.outFitMedium500(
                fontSize: 13, color: textLightGrey(context))
            .copyWith(letterSpacing: 2),
      ),
    );
  }
}
