import 'package:figma_squircle_updated/figma_squircle.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krimson/common/extensions/string_extension.dart';
import 'package:krimson/common/manager/session_manager.dart';
import 'package:krimson/common/manager/streamer_invite.dart';
import 'package:krimson/common/widget/custom_divider.dart';
import 'package:krimson/common/widget/custom_image.dart';
import 'package:krimson/common/widget/privacy_policy_text.dart';
import 'package:krimson/common/widget/text_button_custom.dart';
import 'package:krimson/common/widget/theme_blur_bg.dart';
import 'package:krimson/languages/languages_keys.dart';
import 'package:krimson/screen/auth_screen/auth_screen_controller.dart';
import 'package:krimson/screen/auth_screen/auth_input_field.dart';
export 'package:krimson/screen/auth_screen/auth_input_field.dart'
    show LoginSheetTextField, AuthTextField;
import 'package:krimson/screen/auth_screen/forget_password_sheet.dart';
import 'package:krimson/screen/auth_screen/login_language_dropdown.dart';
import 'package:krimson/screen/auth_screen/registration_screen.dart';
import 'package:krimson/utilities/app_platform.dart';
import 'package:krimson/utilities/asset_res.dart';
import 'package:krimson/utilities/color_res.dart';
import 'package:krimson/utilities/text_style_custom.dart';
import 'package:krimson/utilities/theme_res.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(AuthScreenController());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.refreshSavedGuest();
    });
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Container(
        height: Get.height,
        decoration: const ShapeDecoration(
            shape: SmoothRectangleBorder(
          borderRadius: SmoothBorderRadius.vertical(
              top: SmoothRadius(cornerRadius: 0, cornerSmoothing: 1)),
        )),
        child: Stack(
          children: [
            const ThemeBlurBg(),
            SingleChildScrollView(
              child: SafeArea(
                bottom: false,
                child: Column(
                  children: [
                    // Espacio para el select de idioma (Positioned arriba).
                    const SizedBox(height: 56),
                    Padding(
                      padding:
                          const EdgeInsets.only(left: 20, right: 20, top: 12),
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 18.0),
                            child: RichText(
                                textAlign: TextAlign.center,
                                text: TextSpan(
                                  text: LKey.signIn.tr.toUpperCase(),
                                  style: TextStyleCustom.unboundedBlack900(
                                    fontSize: 25,
                                    color: whitePure(context),
                                  ).copyWith(letterSpacing: -.2),
                                  children: [
                                    TextSpan(
                                        text: '\n${LKey.toContinue.tr}'
                                            .toUpperCase(),
                                        style:
                                            TextStyleCustom.unboundedBlack900(
                                                fontSize: 25,
                                                color: ColorRes.softSalmon))
                                  ],
                                )),
                          ),
                          const SizedBox(height: 50 * 1.5),
                          LoginSheetTextField(
                            hintText: LKey.enterYourEmail.tr,
                            controller: controller.emailController,
                            keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: 14),
                          LoginSheetTextField(
                            isPasswordField: true,
                            hintText: LKey.enterPassword.tr,
                            controller: controller.passwordController,
                          ),
                          Align(
                            alignment: AlignmentDirectional.centerEnd,
                            child: InkWell(
                              onTap: () {
                                Get.bottomSheet(const ForgetPasswordSheet(),
                                        isScrollControlled: true)
                                    .then((value) => controller
                                        .forgetEmailController
                                        .clear());
                              },
                              child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 14.0),
                                  child: Text(LKey.forgetPassword.tr,
                                      style: TextStyleCustom.outFitMedium500(
                                          fontSize: 15,
                                          color: ColorRes.brandSoft))),
                            ),
                          ),
                          TextButtonCustom(
                              onTap: controller.onLogin,
                              title: LKey.logIn.tr,
                              btnHeight: 50,
                              horizontalMargin: 0,
                              gradient: true,
                              forceStreamerPalette: true,
                              titleColor: ColorRes.whitePure,
                              radius: 25)
                        ],
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        controller.fullNameController.clear();
                        controller.emailController.clear();
                        controller.passwordController.clear();
                        controller.confirmPassController.clear();
                        Get.to(() => const RegistrationScreen());
                      },
                      child: Container(
                        height: 48,
                        margin: const EdgeInsets.only(top: 25),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: ColorRes.menuSurface.withValues(alpha: 0.75),
                          border: Border.symmetric(
                            horizontal: BorderSide(color: ColorRes.menuBorder),
                          ),
                        ),
                        child: Text(
                          LKey.createAccountHere.tr,
                          style: TextStyleCustom.outFitMedium500(
                              color: ColorRes.whitePure, fontSize: 16),
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        StreamerInvite.registerUrl().lunchUrlWithHttps;
                      },
                      child: Padding(
                        padding: const EdgeInsets.only(top: 14, bottom: 18),
                        child: Text(
                          LKey.iAmStreamer.tr,
                          style: TextStyleCustom.outFitMedium500(
                            fontSize: 15,
                            color: ColorRes.brandSoft,
                          ),
                        ),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CustomDivider(
                          color: whitePure(context),
                          height: .5,
                          width: 100,
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 15.0),
                          child: Text(
                            LKey.continueWith.tr,
                            style: TextStyleCustom.outFitRegular400(
                                fontSize: 16, color: whitePure(context)),
                          ),
                        ),
                        CustomDivider(
                          color: whitePure(context),
                          height: .5,
                          width: 100,
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 25.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (AppPlatform.isIOS)
                            SocialBtn(
                              onTap: controller.onAppleTap,
                              icon: AssetRes.icApple,
                            ),
                          if (AppPlatform.isIOS) const SizedBox(width: 10),
                          SocialBtn(
                              onTap: controller.onGoogleTap,
                              icon: AssetRes.icGoogle),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                      child: Obx(() {
                        final saved = controller.savedGuest.value;
                        return Column(
                          children: [
                            if (saved != null) ...[
                              _SavedGuestSuggestion(
                                guest: saved,
                                onTap: controller.resumeSavedGuest,
                              ),
                              const SizedBox(height: 12),
                            ],
                            InkWell(
                              onTap: controller.onAnonymousTap,
                              borderRadius: BorderRadius.circular(25),
                              child: Container(
                                height: 48,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(25),
                                  border: Border.all(
                                    color: ColorRes.whitePure
                                        .withValues(alpha: 0.55),
                                  ),
                                  color: ColorRes.menuSurface
                                      .withValues(alpha: 0.12),
                                ),
                                child: Text(
                                  LKey.continueAsGuest.tr,
                                  style: TextStyleCustom.outFitMedium500(
                                    color: ColorRes.whitePure,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      }),
                    ),
                    PrivacyPolicyText(
                      boldTextColor: ColorRes.whitePure,
                      regularTextColor:
                          ColorRes.brandSoft.withValues(alpha: .9),
                    )
                  ],
                ),
              ),
            ),
            // Select de idioma fijo en esquina superior derecha.
            const SafeArea(
              child: Align(
                alignment: AlignmentDirectional.topEnd,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(12, 8, 12, 0),
                  child: LoginLanguageDropdown(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SocialBtn extends StatelessWidget {
  final String icon;
  final VoidCallback onTap;

  const SocialBtn({super.key, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 57,
        width: 57,
        decoration:
            BoxDecoration(shape: BoxShape.circle, color: whitePure(context)),
        alignment: Alignment.center,
        child: Image.asset(icon, height: 32, width: 32),
      ),
    );
  }
}

class _SavedGuestSuggestion extends StatelessWidget {
  final LastGuest guest;
  final VoidCallback onTap;

  const _SavedGuestSuggestion({required this.guest, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(25),
      child: Container(
        height: 56,
        padding: const EdgeInsets.fromLTRB(8, 6, 16, 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          gradient: const LinearGradient(
            colors: [ColorRes.crimson, ColorRes.softSalmon],
          ),
        ),
        child: Row(
          children: [
            CustomImage(
              size: const Size(44, 44),
              image: guest.profilePhoto?.addBaseURL(),
              fullName: guest.displayName,
              radius: 44,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    LKey.continueAsSavedGuest.trParams(
                      {'name': guest.displayName},
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyleCustom.outFitMedium500(
                      color: ColorRes.whitePure,
                      fontSize: 15,
                    ),
                  ),
                  Text(
                    LKey.savedGuestHint.tr,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyleCustom.outFitRegular400(
                      color: ColorRes.whitePure.withValues(alpha: 0.82),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: ColorRes.whitePure.withValues(alpha: 0.9),
            ),
          ],
        ),
      ),
    );
  }
}
