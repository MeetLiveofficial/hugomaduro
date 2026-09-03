import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krimson/common/widget/custom_back_button.dart';
import 'package:krimson/common/widget/text_button_custom.dart';
import 'package:krimson/common/widget/theme_blur_bg.dart';
import 'package:krimson/languages/languages_keys.dart';
import 'package:krimson/screen/auth_screen/auth_screen_controller.dart';
import 'package:krimson/screen/auth_screen/login_screen.dart';
import 'package:krimson/utilities/asset_res.dart';
import 'package:krimson/utilities/color_res.dart';
import 'package:krimson/utilities/text_style_custom.dart';

class GuestSetupScreen extends StatefulWidget {
  const GuestSetupScreen({super.key});

  @override
  State<GuestSetupScreen> createState() => _GuestSetupScreenState();
}

class _GuestSetupScreenState extends State<GuestSetupScreen> {
  final _name = TextEditingController();
  int _avatar = 1;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    final name = _name.text.trim();
    if (name.length < 2) {
      Get.find<AuthScreenController>().showSnackBar(LKey.fullNameEmpty.tr);
      return;
    }
    await Get.find<AuthScreenController>().completeGuestSetup(
      fullName: name,
      avatarIndex: _avatar,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<AuthScreenController>()) {
      Get.put(AuthScreenController());
    }
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          const ThemeBlurBg(),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 4, 20, 0),
                  child: Row(
                    children: [
                      CustomBackButton(
                        color: ColorRes.whitePure,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 8),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                    child: Column(
                      children: [
                        Text(
                          LKey.guestSetupTitle.tr.toUpperCase(),
                          textAlign: TextAlign.center,
                          style: TextStyleCustom.unboundedBlack900(
                            fontSize: 22,
                            color: ColorRes.whitePure,
                          ).copyWith(letterSpacing: -.2),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          LKey.guestSetupSubtitle.tr,
                          textAlign: TextAlign.center,
                          style: TextStyleCustom.outFitRegular400(
                            fontSize: 15,
                            color: ColorRes.whitePure.withValues(alpha: 0.72),
                          ),
                        ),
                        const SizedBox(height: 28),
                        CircleAvatar(
                          radius: 52,
                          backgroundColor: ColorRes.menuBorder,
                          backgroundImage: AssetImage(
                            AssetRes.guestAvatars[_avatar - 1],
                          ),
                        ),
                        const SizedBox(height: 28),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            LKey.enterYourName.tr,
                            style: TextStyleCustom.outFitMedium500(
                              fontSize: 14,
                              color: ColorRes.whitePure.withValues(alpha: 0.8),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        LoginSheetTextField(
                          hintText: LKey.enterFullName.tr,
                          controller: _name,
                        ),
                        const SizedBox(height: 24),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            LKey.chooseAvatar.tr,
                            style: TextStyleCustom.outFitMedium500(
                              fontSize: 14,
                              color: ColorRes.whitePure.withValues(alpha: 0.8),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          alignment: WrapAlignment.center,
                          children: List.generate(AssetRes.guestAvatars.length,
                              (i) {
                            final n = i + 1;
                            final selected = _avatar == n;
                            return GestureDetector(
                              onTap: () => setState(() => _avatar = n),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                padding: const EdgeInsets.all(3),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: selected
                                        ? ColorRes.softSalmon
                                        : Colors.transparent,
                                    width: 3,
                                  ),
                                ),
                                child: CircleAvatar(
                                  radius: 36,
                                  backgroundImage: AssetImage(
                                    AssetRes.guestAvatars[i],
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                        const SizedBox(height: 36),
                        TextButtonCustom(
                          onTap: _continue,
                          title: LKey.continueText.tr,
                          btnHeight: 50,
                          horizontalMargin: 0,
                          gradient: true,
                          forceStreamerPalette: true,
                          titleColor: ColorRes.whitePure,
                          radius: 25,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
