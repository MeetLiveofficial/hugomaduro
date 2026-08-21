import 'package:figma_squircle_updated/figma_squircle.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krimson/common/manager/app_role.dart';
import 'package:krimson/common/manager/content_protection.dart';
import 'package:krimson/common/widget/brand_controls.dart';
import 'package:krimson/common/widget/custom_app_bar.dart';
import 'package:krimson/common/widget/custom_drop_down.dart';
import 'package:krimson/common/widget/custom_toggle.dart';
import 'package:krimson/common/widget/text_button_custom.dart';
import 'package:krimson/languages/languages_keys.dart';
import 'package:krimson/model/user_model/user_model.dart';
import 'package:krimson/screen/blocked_user_screen/blocked_user_screen.dart';
import 'package:krimson/screen/call_price_screen/call_price_screen.dart';
import 'package:krimson/screen/match_screen/match_screen.dart';
import 'package:krimson/screen/coin_wallet_screen/coin_wallet_screen.dart';
import 'package:krimson/screen/withdrawals_screen/withdrawals_screen.dart';
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
import 'package:krimson/utilities/asset_res.dart';
import 'package:krimson/utilities/color_res.dart';
import 'package:krimson/utilities/style_res.dart';
import 'package:krimson/utilities/text_style_custom.dart';
import 'package:krimson/utilities/theme_res.dart';

class SettingsScreen extends StatelessWidget {
  final Function(User? user)? onUpdateUser;
  final bool showBack;

  const SettingsScreen({
    super.key,
    this.onUpdateUser,
    this.showBack = true,
  });

  @override
  Widget build(BuildContext context) {
    if (showBack && Get.isRegistered<SettingsScreenController>()) {
      Get.delete<SettingsScreenController>(force: true);
    }
    final controller = Get.put(SettingsScreenController());
    final isAgency = AppRole.isAgency();
    return Scaffold(
        body: Column(
      children: [
        CustomAppBar(title: LKey.settings.tr, showBack: showBack),
        Expanded(
            child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isAgency)
                SubscriptionCard(
                    controller: controller, onUpdateUser: onUpdateUser),
              SettingLabel(title: LKey.personal),
              BrandPanel(
                child: Column(
                  children: [
              SettingIconTextWithArrow(
                icon: AssetRes.icEdit,
                iconColor: ColorRes.crimson,
                title: LKey.editProfile,
                onTap: () {
                  Get.to(() => EditProfileScreen(onUpdateUser: onUpdateUser));
                },
              ),
              SettingIconTextWithArrow(
                icon: AssetRes.icLanguage_1,
                iconColor: ColorRes.mlPurple,
                title: LKey.languages,
                onTap: () {
                  Get.to(() => const SelectLanguageScreen(
                      languageNavigationType:
                          LanguageNavigationType.fromSetting));
                },
              ),
              if (!isAgency)
                SettingIconTextWithArrow(
                  icon: AssetRes.icBlock,
                  iconColor: ColorRes.crimsonAlt,
                  title: LKey.blockedUsers,
                  onTap: () {
                    Get.to(() => const BlockedUserScreen());
                  },
                ),
              if (!isAgency && ContentProtection.canShare)
                SettingIconTextWithArrow(
                  icon: AssetRes.icQrCode_1,
                  iconColor: ColorRes.roseBorder,
                  title: LKey.myQrCode,
                  onTap: () {
                    Get.to(() => const QrCodeScreen());
                  },
                ),
              SettingIconTextWithArrow(
                icon: AssetRes.icWallet,
                iconColor: ColorRes.mlPurple,
                title: LKey.coinWallet,
                onTap: () async {
                  await Get.to(() => const CoinWalletScreen());
                },
              ),
              if (AppRole.canWithdraw())
                SettingIconTextWithArrow(
                  icon: AssetRes.icWallet,
                  iconColor: ColorRes.crimson,
                  title: LKey.withdrawals,
                  onTap: () {
                    Get.to(() => const WithdrawalsScreen());
                  },
                ),
              if (AppRole.isStreamer())
                SettingIconTextWithArrow(
                  icon: AssetRes.icHeart,
                  iconColor: ColorRes.crimsonAlt,
                  title: 'Match',
                  onTap: () {
                    Get.to(() => const MatchScreen());
                  },
                ),
              if (AppRole.isStreamer())
                SettingIconTextWithArrow(
                  icon: AssetRes.icVideoCamera,
                  iconColor: ColorRes.mlPurple,
                  title: LKey.editCalls,
                  onTap: () {
                    Get.to(() => const CallPriceScreen());
                  },
                ),
              if (AppRole.canAccessTasks())
                SettingIconTextWithArrow(
                  icon: AssetRes.icVideoRequest,
                  iconColor: ColorRes.crimson,
                  title: LKey.tasks,
                  onTap: () {
                    Get.to(() => const TasksScreen());
                  },
                ),
              if (!isAgency)
                SettingIconTextWithArrow(
                  icon: AssetRes.icVideoRequest,
                  iconColor: ColorRes.darkPurple,
                  title: LKey.privilegeHub,
                  onTap: () {
                    Get.to(() => const PrivilegeHubScreen());
                  },
                ),
                  ],
                ),
              ),
              SettingLabel(
                  title: isAgency ? LKey.notifications : LKey.privacy),
              BrandPanel(
                child: Column(
                  children: [
              if (!isAgency)
                Obx(
                  () => SettingIconTextWithArrow(
                    icon: AssetRes.icEye_1,
                    iconColor: ColorRes.crimson,
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
              if (!isAgency)
                Obx(
                  () {
                    return SettingIconTextWithArrow(
                      icon: AssetRes.icEye_1,
                      iconColor: ColorRes.mlPurple,
                      title: LKey.showMyFollowings,
                      widget: CustomToggle(
                        isOn:
                            (controller.myUser.value?.showMyFollowing == 1).obs,
                        onChanged: (value) {
                          controller.onChangedToggle(
                              value, SettingToggle.showMyFollowings);
                        },
                      ),
                    );
                  },
                ),
              if (!isAgency)
                Obx(
                  () {
                    return SettingIconTextWithArrow(
                      icon: AssetRes.icMessage,
                      iconColor: ColorRes.roseBorder,
                      title: LKey.showChatBtn,
                      widget: CustomToggle(
                        isOn:
                            (controller.myUser.value?.receiveMessage == 1).obs,
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
                      iconColor: ColorRes.crimsonAlt,
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
                iconColor: ColorRes.crimson,
                title: LKey.notifications,
                onTap: () {
                  Get.to(() => const NotificationsPage());
                },
              ),
                  ],
                ),
              ),
              SettingLabel(title: LKey.general),
              BrandPanel(
                child: Column(
                  children: [
              SettingIconTextWithArrow(
                icon: AssetRes.icReport,
                iconColor: ColorRes.mlPurple,
                title: LKey.termsOfUse,
                onTap: () {
                  Get.to(() => const TermAndPrivacyScreen(
                      type: TermAndPrivacyType.termAndCondition));
                },
              ),
              SettingIconTextWithArrow(
                icon: AssetRes.icReport,
                iconColor: ColorRes.darkPurple,
                title: LKey.privacyPolicy,
                onTap: () {
                  Get.to(() => const TermAndPrivacyScreen(
                      type: TermAndPrivacyType.privacyPolicy));
                },
              ),
              if (isAgency)
                SettingIconTextWithArrow(
                  icon: AssetRes.icBlock,
                  iconColor: ColorRes.crimsonAlt,
                  title: LKey.deleteAccount,
                  onTap: controller.onDeleteAccount,
                ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: TextButtonCustom(
                  title: LKey.logOut.tr,
                  onTap: controller.onLogout,
                  backgroundColor: ColorRes.crimsonAlt.withValues(alpha: 0.12),
                  titleColor: ColorRes.crimsonAlt,
                  borderSide: BorderSide(
                    color: ColorRes.crimsonAlt.withValues(alpha: 0.45),
                  ),
                  btnHeight: 48,
                  horizontalMargin: 0,
                ),
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 6),
      child: Text(
        title.tr.toUpperCase(),
        style: TextStyleCustom.outFitMedium500(
                fontSize: 12, color: ColorRes.crimson)
            .copyWith(letterSpacing: 1.6),
      ),
    );
  }
}
