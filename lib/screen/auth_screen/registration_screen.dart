import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krimson/common/widget/custom_back_button.dart';
import 'package:krimson/common/widget/gradient_text.dart';
import 'package:krimson/common/widget/privacy_policy_text.dart';
import 'package:krimson/common/widget/text_button_custom.dart';
import 'package:krimson/common/widget/theme_blur_bg.dart';
import 'package:krimson/languages/languages_keys.dart';
import 'package:krimson/model/general/countries_model.dart';
import 'package:krimson/model/general/settings_model.dart';
import 'package:krimson/screen/auth_screen/auth_input_field.dart';
import 'package:krimson/screen/auth_screen/auth_screen_controller.dart';
import 'package:krimson/utilities/color_res.dart';
import 'package:krimson/utilities/style_res.dart';
import 'package:krimson/utilities/text_style_custom.dart';

class RegistrationScreen extends StatelessWidget {
  const RegistrationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AuthScreenController>();
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          const ThemeBlurBg(),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 6),
                const CustomBackButton(
                  color: ColorRes.whitePure,
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    dragStartBehavior: DragStartBehavior.down,
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 22),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                LKey.signUp.tr.toUpperCase(),
                                style: TextStyleCustom.unboundedBlack900(
                                  fontSize: 25,
                                  color: ColorRes.whitePure,
                                ).copyWith(letterSpacing: -.2),
                              ),
                              GradientText(
                                LKey.startJourney.tr.toUpperCase(),
                                gradient: StyleRes.streamerGradient,
                                style: TextStyleCustom.unboundedBlack900(
                                  fontSize: 25,
                                  color: ColorRes.whitePure,
                                ).copyWith(letterSpacing: -.2),
                              ),
                            ],
                          ),
                        ),
                        AuthTextField(
                          controller: controller.fullNameController,
                          title: LKey.fullName.tr,
                          hintText: LKey.enterFullName.tr,
                        ),
                        AuthTextField(
                          controller: controller.emailController,
                          title: LKey.email.tr,
                          hintText: LKey.enterYourEmail.tr,
                          keyboardType: TextInputType.emailAddress,
                        ),
                        Obx(() => AuthPickerField(
                              title: LKey.dateOfBirth.tr,
                              value: controller.birthDate.value == null
                                  ? LKey.selectDateOfBirth.tr
                                  : controller.birthDateLabel,
                              isPlaceholder: controller.birthDate.value == null,
                              icon: Icons.calendar_today_outlined,
                              onTap: () => controller.pickBirthDate(context),
                            )),
                        Obx(() {
                          final langs = controller.languages;
                          final options = langs.isNotEmpty
                              ? langs
                              : [
                                  Language(
                                      code: 'en',
                                      title: 'English',
                                      localizedTitle: 'English'),
                                  Language(
                                      code: 'es',
                                      title: 'Español',
                                      localizedTitle: 'Español'),
                                ];
                          final codes = options
                              .map((e) => (e.code ?? 'en').toLowerCase())
                              .toList();
                          var selected = controller.selectedLanguage.value;
                          if (!codes.contains(selected) && codes.isNotEmpty) {
                            selected = codes.first;
                          }
                          final selectedLang = options.firstWhere(
                            (e) => (e.code ?? '').toLowerCase() == selected,
                            orElse: () => options.first,
                          );
                          final label = selectedLang.localizedTitle ??
                              selectedLang.title ??
                              selected.toUpperCase();
                          return AuthPickerField(
                            title: LKey.language.tr,
                            value: label,
                            isPlaceholder: false,
                            icon: Icons.language,
                            onTap: () => _openLanguageSheet(
                              controller,
                              options,
                              selected,
                            ),
                          );
                        }),
                        Obx(() => AuthPickerField(
                              title: LKey.country.tr,
                              value: controller.selectedCountry.value
                                      ?.countryName ??
                                  LKey.selectCountry.tr,
                              isPlaceholder:
                                  controller.selectedCountry.value == null,
                              icon: Icons.public,
                              onTap: () => _openCountrySheet(controller),
                            )),
                        AuthTextField(
                          controller: controller.passwordController,
                          title: LKey.password.tr,
                          hintText: LKey.enterPassword.tr,
                          isPasswordField: true,
                        ),
                        AuthTextField(
                          controller: controller.confirmPassController,
                          title: LKey.reTypePassword.tr,
                          hintText: LKey.enterPassword.tr,
                          isPasswordField: true,
                        ),
                        const SizedBox(height: 8),
                        TextButtonCustom(
                          onTap: controller.onCreateAccount,
                          title: LKey.createAccount.tr,
                          gradient: true,
                          forceStreamerPalette: true,
                          horizontalMargin: 0,
                          titleColor: ColorRes.whitePure,
                          radius: 25,
                        ),
                        const SizedBox(height: 16),
                        PrivacyPolicyText(
                          boldTextColor: ColorRes.whitePure,
                          regularTextColor:
                              ColorRes.brandSoft.withValues(alpha: .9),
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

  void _openLanguageSheet(
    AuthScreenController controller,
    List<Language> options,
    String selected,
  ) {
    AuthSelectSheet.show(
      title: LKey.selectLanguage.tr,
      child: ListView.builder(
        itemCount: options.length,
        itemBuilder: (_, i) {
          final lang = options[i];
          final code = (lang.code ?? 'en').toLowerCase();
          final isSelected = code == selected;
          final title =
              lang.localizedTitle ?? lang.title ?? code.toUpperCase();
          return ListTile(
            title: Text(
              title,
              style: TextStyleCustom.outFitRegular400(
                color: isSelected ? ColorRes.roseMuted : ColorRes.whitePure,
                fontSize: 16,
              ),
            ),
            trailing: isSelected
                ? const Icon(Icons.check, color: ColorRes.crimson)
                : null,
            onTap: () {
              controller.selectLanguageCode(code);
              Get.back();
            },
          );
        },
      ),
    );
  }

  void _openCountrySheet(AuthScreenController controller) {
    final query = ''.obs;
    AuthSelectSheet.show(
      title: LKey.selectCountry.tr,
      heightFactor: 0.75,
      header: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        child: AuthFieldShell(
          height: 46,
          child: TextField(
            onChanged: (v) => query.value = v.trim().toLowerCase(),
            style: TextStyleCustom.outFitRegular400(
              color: ColorRes.whitePure,
              fontSize: 15,
            ),
            cursorColor: ColorRes.mauve,
            decoration: InputDecoration(
              hintText: LKey.searchCountry.tr,
              hintStyle: TextStyleCustom.outFitRegular400(
                color: ColorRes.whitePure.withValues(alpha: 0.45),
                fontSize: 15,
              ),
              border: InputBorder.none,
              prefixIcon: Icon(
                Icons.search,
                color: ColorRes.whitePure.withValues(alpha: 0.55),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),
        ),
      ),
      child: Obx(() {
        final q = query.value;
        final list = controller.countries.where((c) {
          if (q.isEmpty) return true;
          return c.countryName.toLowerCase().contains(q) ||
              c.countryCode.toLowerCase().contains(q);
        }).toList();
        if (list.isEmpty) {
          return Center(
            child: Text(
              LKey.noData.tr,
              style: TextStyleCustom.outFitRegular400(
                color: ColorRes.whitePure.withValues(alpha: 0.55),
              ),
            ),
          );
        }
        return ListView.builder(
          itemCount: list.length,
          itemBuilder: (_, i) {
            final Country country = list[i];
            final selected = controller.selectedCountry.value?.countryCode ==
                country.countryCode;
            return ListTile(
              title: Text(
                country.countryName,
                style: TextStyleCustom.outFitRegular400(
                  color: selected ? ColorRes.roseMuted : ColorRes.whitePure,
                  fontSize: 16,
                ),
              ),
              trailing: Text(
                country.countryCode,
                style: TextStyleCustom.outFitRegular400(
                  color: ColorRes.whitePure.withValues(alpha: 0.45),
                  fontSize: 13,
                ),
              ),
              onTap: () {
                controller.selectCountry(country);
                Get.back();
              },
            );
          },
        );
      }),
    );
  }
}
