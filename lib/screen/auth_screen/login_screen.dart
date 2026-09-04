import 'package:figma_squircle_updated/figma_squircle.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krimson/common/extensions/string_extension.dart';
import 'package:krimson/common/manager/streamer_invite.dart';
import 'package:krimson/common/widget/custom_divider.dart';
import 'package:krimson/common/widget/privacy_policy_text.dart';
import 'package:krimson/common/widget/text_button_custom.dart';
import 'package:krimson/common/widget/theme_blur_bg.dart';
import 'package:krimson/languages/languages_keys.dart';
import 'package:krimson/screen/auth_screen/auth_screen_controller.dart';
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
                      child: InkWell(
                        onTap: controller.onAnonymousTap,
                        borderRadius: BorderRadius.circular(25),
                        child: Container(
                          height: 48,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(25),
                            border: Border.all(
                              color: ColorRes.whitePure.withValues(alpha: 0.55),
                            ),
                            color: ColorRes.menuSurface.withValues(alpha: 0.12),
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

class LoginSheetTextField extends StatefulWidget {
  final bool isPasswordField;
  final String hintText;
  final TextEditingController controller;
  final TextInputType? keyboardType;

  const LoginSheetTextField(
      {super.key,
      this.isPasswordField = false,
      required this.hintText,
      required this.controller,
      this.keyboardType});

  @override
  State<LoginSheetTextField> createState() => _LoginSheetTextFieldState();
}

class _LoginSheetTextFieldState extends State<LoginSheetTextField> {
  bool isHide = true;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: ShapeDecoration(
          shape: SmoothRectangleBorder(
            borderRadius:
                SmoothBorderRadius(cornerRadius: 14, cornerSmoothing: 1),
            side: BorderSide(color: ColorRes.menuBorder),
            borderAlign: BorderAlign.inside,
          ),
          color: ColorRes.bgElevated.withValues(alpha: 0.95),
          shadows: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ]),
      child: TextField(
        controller: widget.controller,
        style: TextStyleCustom.outFitRegular400(
            color: ColorRes.whitePure, fontSize: 16),
        onTapOutside: (event) => FocusManager.instance.primaryFocus?.unfocus(),
        obscureText: widget.isPasswordField && isHide,
        keyboardType: widget.keyboardType ?? TextInputType.text,
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: widget.hintText,
          hintStyle: TextStyleCustom.outFitRegular400(
              color: ColorRes.whitePure.withValues(alpha: 0.45), fontSize: 16),
          contentPadding: EdgeInsets.only(
              left: 14, right: 10, top: widget.isPasswordField ? 2 : 0),
          suffixIconConstraints: const BoxConstraints(),
          suffixIcon: widget.isPasswordField
              ? InkWell(
                  onTap: () {
                    isHide = !isHide;
                    setState(() {});
                  },
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: Image.asset(
                        isHide ? AssetRes.icEye : AssetRes.icHideEye,
                        height: 24,
                        width: 35,
                        color: ColorRes.whitePure.withValues(alpha: 0.7),
                        key: UniqueKey()),
                  ),
                )
              : null,
        ),
        cursorColor: ColorRes.mauve,
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
