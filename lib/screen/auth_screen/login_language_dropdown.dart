import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krimson/common/manager/session_manager.dart';
import 'package:krimson/model/general/settings_model.dart';
import 'package:krimson/utilities/color_res.dart';
import 'package:krimson/utilities/text_style_custom.dart';

/// Desplegable de idioma — menú blanco con texto oscuro.
class LoginLanguageDropdown extends StatelessWidget {
  const LoginLanguageDropdown({super.key});

  List<({String label, String code})> get _options {
    final active = SessionManager.instance.getActiveLanguages();
    if (active.isNotEmpty) {
      return active
          .map(
            (Language lang) => (
              label: lang.localizedTitle ?? lang.title ?? lang.code ?? 'EN',
              code: (lang.code ?? 'en').toLowerCase(),
            ),
          )
          .toList();
    }
    return const [
      (label: 'English', code: 'en'),
      (label: 'Español', code: 'es'),
      (label: 'Português', code: 'pt'),
      (label: 'العربية', code: 'ar'),
      (label: 'Русский', code: 'ru'),
      (label: 'Українська', code: 'uk'),
      (label: '中文', code: 'zh'),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final options = _options;
    final current = SessionManager.instance.getLang().toLowerCase();
    final selected = options.any((e) => e.code == current)
        ? current
        : (options.isNotEmpty ? options.first.code : 'en');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: ColorRes.whitePure,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: ColorRes.menuBorder, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selected,
          dropdownColor: ColorRes.whitePure,
          borderRadius: BorderRadius.circular(14),
          menuMaxHeight: 320,
          iconEnabledColor: ColorRes.crimson,
          style: TextStyleCustom.outFitMedium500(
            color: ColorRes.textDarkGrey,
            fontSize: 14,
          ),
          selectedItemBuilder: (context) {
            return options
                .map(
                  (e) => Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Text(
                      '${e.label} (${e.code.toUpperCase()})',
                      style: TextStyleCustom.outFitMedium500(
                        color: ColorRes.textDarkGrey,
                        fontSize: 14,
                      ),
                    ),
                  ),
                )
                .toList();
          },
          items: options
              .map(
                (e) => DropdownMenuItem<String>(
                  value: e.code,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: e.code == selected
                          ? ColorRes.menuSelected
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${e.label} (${e.code.toUpperCase()})',
                      style: TextStyleCustom.outFitRegular400(
                        color: e.code == selected
                            ? ColorRes.crimson
                            : ColorRes.textDarkGrey,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
          onChanged: (code) async {
            if (code == null || code == selected) return;
            SessionManager.instance
                .setBool(SessionKeys.isLanguageScreenSelect, true);
            await SessionManager.instance.setLang(code, syncRemote: false);
            Get.forceAppUpdate();
          },
        ),
      ),
    );
  }
}
