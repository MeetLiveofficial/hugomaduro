import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krimson/common/widget/custom_back_button.dart';
import 'package:krimson/common/widget/gradient_text.dart';
import 'package:krimson/common/widget/privacy_policy_text.dart';
import 'package:krimson/common/widget/text_button_custom.dart';
import 'package:krimson/common/widget/text_field_custom.dart';
import 'package:krimson/languages/languages_keys.dart';
import 'package:krimson/model/general/countries_model.dart';
import 'package:krimson/model/general/settings_model.dart';
import 'package:krimson/screen/auth_screen/auth_screen_controller.dart';
import 'package:krimson/utilities/color_res.dart';
import 'package:krimson/utilities/style_res.dart';
import 'package:krimson/utilities/text_style_custom.dart';
import 'package:krimson/utilities/theme_res.dart';

class RegistrationScreen extends StatelessWidget {
  const RegistrationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AuthScreenController>();
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            const CustomBackButton(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 5)),
            Expanded(
                child: SingleChildScrollView(
              dragStartBehavior: DragStartBehavior.down,
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(LKey.signUp.tr.toUpperCase(),
                            style: TextStyleCustom.unboundedBlack900(
                              fontSize: 25,
                              color: textDarkGrey(context),
                            ).copyWith(letterSpacing: -.2)),
                        GradientText(LKey.startJourney.tr.toUpperCase(),
                            gradient: StyleRes.themeGradient,
                            style: TextStyleCustom.unboundedBlack900(
                              fontSize: 25,
                              color: textDarkGrey(context),
                            ).copyWith(letterSpacing: -.2)),
                      ],
                    ),
                  ),
                  TextFieldCustom(
                    controller: controller.fullNameController,
                    title: LKey.fullName.tr,
                    hintText: LKey.enterFullName.tr,
                  ),
                  TextFieldCustom(
                    controller: controller.emailController,
                    title: LKey.email.tr,
                    hintText: LKey.enterYourEmail.tr,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  Obx(() => _AuthPickerField(
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
                    final label =
                        selectedLang.localizedTitle ??
                        selectedLang.title ??
                        selected.toUpperCase();
                    return _AuthPickerField(
                      title: LKey.language.tr,
                      value: label,
                      isPlaceholder: false,
                      icon: Icons.language,
                      onTap: () => _openLanguageSheet(
                        context,
                        controller,
                        options,
                        selected,
                      ),
                    );
                  }),
                  Obx(() => _AuthPickerField(
                        title: LKey.country.tr,
                        value: controller.selectedCountry.value?.countryName ??
                            LKey.selectCountry.tr,
                        isPlaceholder:
                            controller.selectedCountry.value == null,
                        icon: Icons.public,
                        onTap: () =>
                            _openCountrySheet(context, controller),
                      )),
                  TextFieldCustom(
                    controller: controller.passwordController,
                    title: LKey.password.tr,
                    hintText: LKey.enterPassword.tr,
                    isPasswordField: true,
                  ),
                  TextFieldCustom(
                    controller: controller.confirmPassController,
                    title: LKey.reTypePassword.tr,
                    hintText: LKey.enterPassword.tr,
                    isPasswordField: true,
                  ),
                  const SizedBox(height: 20),
                  TextButtonCustom(
                      onTap: controller.onCreateAccount,
                      title: LKey.createAccount.tr,
                      gradient: true,
                      horizontalMargin: 20,
                      titleColor: whitePure(context),
                      radius: 25),
                  const SizedBox(height: 16),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: PrivacyPolicyText(),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  void _openLanguageSheet(
    BuildContext context,
    AuthScreenController controller,
    List<Language> options,
    String selected,
  ) {
    Get.bottomSheet(
      Container(
        constraints: BoxConstraints(maxHeight: Get.height * 0.55),
        decoration: const BoxDecoration(
          color: ColorRes.whitePure,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: ColorRes.bgGrey,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                LKey.selectLanguage.tr,
                style: TextStyleCustom.outFitMedium500(
                  color: ColorRes.textDarkGrey,
                  fontSize: 17,
                ),
              ),
            ),
            Expanded(
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
                        color: isSelected
                            ? ColorRes.coralRed
                            : ColorRes.textDarkGrey,
                        fontSize: 16,
                      ),
                    ),
                    trailing: isSelected
                        ? const Icon(Icons.check, color: ColorRes.coralRed)
                        : null,
                    onTap: () {
                      controller.selectLanguageCode(code);
                      Get.back();
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  void _openCountrySheet(
    BuildContext context,
    AuthScreenController controller,
  ) {
    final query = ''.obs;
    Get.bottomSheet(
      Container(
        height: Get.height * 0.75,
        decoration: const BoxDecoration(
          color: ColorRes.whitePure,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: ColorRes.bgGrey,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                LKey.selectCountry.tr,
                style: TextStyleCustom.outFitMedium500(
                  color: ColorRes.textDarkGrey,
                  fontSize: 17,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: TextField(
                onChanged: (v) => query.value = v.trim().toLowerCase(),
                decoration: InputDecoration(
                  hintText: LKey.searchCountry.tr,
                  hintStyle: TextStyleCustom.outFitRegular400(
                    color: ColorRes.textLightGrey,
                    fontSize: 15,
                  ),
                  filled: true,
                  fillColor: ColorRes.bgLightGrey,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  prefixIcon: const Icon(Icons.search,
                      color: ColorRes.textLightGrey),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
            ),
            Expanded(
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
                        color: ColorRes.textLightGrey,
                      ),
                    ),
                  );
                }
                return ListView.builder(
                  itemCount: list.length,
                  itemBuilder: (_, i) {
                    final Country country = list[i];
                    final selected =
                        controller.selectedCountry.value?.countryCode ==
                            country.countryCode;
                    return ListTile(
                      title: Text(
                        country.countryName,
                        style: TextStyleCustom.outFitRegular400(
                          color: selected
                              ? ColorRes.coralRed
                              : ColorRes.textDarkGrey,
                          fontSize: 16,
                        ),
                      ),
                      trailing: Text(
                        country.countryCode,
                        style: TextStyleCustom.outFitRegular400(
                          color: ColorRes.textLightGrey,
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
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }
}

class _AuthPickerField extends StatelessWidget {
  final String title;
  final String value;
  final bool isPlaceholder;
  final IconData icon;
  final VoidCallback onTap;

  const _AuthPickerField({
    required this.title,
    required this.value,
    required this.isPlaceholder,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Text(title,
              style: TextStyleCustom.outFitRegular400(
                  color: textDarkGrey(context), fontSize: 17)),
        ),
        Container(
          height: 52,
          margin: const EdgeInsets.only(top: 8, bottom: 12, left: 16, right: 16),
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: ColorRes.whitePure.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: ColorRes.roseBorder.withValues(alpha: 0.35),
            ),
            boxShadow: [
              BoxShadow(
                color: ColorRes.crimson.withValues(alpha: 0.07),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              child: SizedBox.expand(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          value,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyleCustom.outFitRegular400(
                            color: isPlaceholder
                                ? textLightGrey(context)
                                : textDarkGrey(context),
                            fontSize: 16,
                          ),
                        ),
                      ),
                      Icon(icon, size: 20, color: textLightGrey(context)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
