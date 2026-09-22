import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krimson/common/manager/app_role.dart';
import 'package:krimson/common/manager/session_manager.dart';
import 'package:krimson/common/widget/brand_wash_bg.dart';
import 'package:krimson/common/widget/custom_app_bar.dart';
import 'package:krimson/common/widget/custom_back_button.dart';
import 'package:krimson/common/widget/restart_widget.dart';
import 'package:krimson/common/widget/theme_blur_bg.dart';
import 'package:krimson/languages/languages_keys.dart';
import 'package:krimson/screen/auth_screen/login_screen.dart';
import 'package:krimson/screen/on_boarding_screen/on_boarding_screen.dart';
import 'package:krimson/utilities/client_colors.dart';
import 'package:krimson/utilities/text_style_custom.dart';
import 'package:krimson/utilities/theme_res.dart';

enum LanguageNavigationType { fromStart, fromSetting }

class SelectLanguageScreen extends StatelessWidget {
  final LanguageNavigationType languageNavigationType;

  const SelectLanguageScreen({
    super.key,
    required this.languageNavigationType,
  });

  @override
  Widget build(BuildContext context) {
    // Solo idiomas activos del panel admin (APP LANGUAGES → ES/EN/PT…).
    final active = SessionManager.instance.getActiveLanguages();
    final current = SessionManager.instance.getLang();

    // Fallback alineado al seeder del backend si aún no hay settings.
    final tiles = active.isNotEmpty
        ? active
            .map(
              (lang) => (
                label: lang.localizedTitle ?? lang.title ?? lang.code ?? 'Lang',
                code: lang.code ?? 'en',
              ),
            )
            .toList()
        : const [
            (label: 'English', code: 'en'),
            (label: 'Español', code: 'es'),
            (label: 'Português', code: 'pt'),
            (label: 'العربية', code: 'ar'),
            (label: 'Русский', code: 'ru'),
            (label: 'Українська', code: 'uk'),
            (label: '中文', code: 'zh'),
          ];

    final fromSetting =
        languageNavigationType == LanguageNavigationType.fromSetting;
    final showBack = fromSetting ||
        (ModalRoute.of(context)?.canPop ?? false);

    return Scaffold(
      backgroundColor: fromSetting && AppRole.isClient() ? ClientColors.bg : null,
      body: Stack(
        children: [
          if (fromSetting && AppRole.isClient())
            const BrandWashBg(vivid: false)
          else
            const ThemeBlurBg(),
          if (fromSetting && AppRole.isClient())
            Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  CustomAppBar(
                    title: LKey.language.tr,
                    showBack: showBack,
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                    child: Text(
                      LKey.languages.tr.toUpperCase(),
                      style: TextStyleCustom.outFitMedium500(
                        color: ClientColors.primary,
                        fontSize: 12,
                      ).copyWith(letterSpacing: 1.6),
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(4, 0, 4, 24),
                      itemCount: tiles.length,
                      itemBuilder: (_, i) {
                        final tile = tiles[i];
                        return _LangTile(
                          label: tile.label,
                          code: tile.code,
                          selected: tile.code == current,
                          onTap: () => _select(context, tile.code),
                        );
                      },
                    ),
                  ),
                ],
              )
          else
            SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      if (showBack)
                        CustomBackButton(
                          color: whitePure(context),
                          width: 18,
                          height: 18,
                          padding: const EdgeInsets.all(12),
                        )
                      else
                        const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          LKey.language.tr,
                          style: TextStyle(
                            color: whitePure(context),
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 12, top: 4),
                    child: Text(
                      LKey.languages.tr,
                      style: TextStyle(
                        color: whitePure(context).withValues(alpha: 0.8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 12),
                      child: ListView.builder(
                        itemCount: tiles.length,
                        itemBuilder: (_, i) {
                          final tile = tiles[i];
                          return _LangTile(
                            label: tile.label,
                            code: tile.code,
                            selected: tile.code == current,
                            onTap: () => _select(context, tile.code),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _select(BuildContext context, String code) async {
    SessionManager.instance.setBool(SessionKeys.isLanguageScreenSelect, true);
    // Esperar sync a app_language en el server antes de reiniciar;
    // si no, el perfil vuelve a mostrar el idioma anterior.
    await SessionManager.instance.setLang(code);

    if (languageNavigationType == LanguageNavigationType.fromSetting) {
      final ctx = Get.context ?? context;
      RestartWidget.restartApp(ctx);
      return;
    }

    final onBoarding =
        SessionManager.instance.getSettings()?.onBoarding ?? [];
    final onBoardingShow =
        SessionManager.instance.getBool(SessionKeys.isOnBoardingScreenSelect);
    if (!onBoardingShow && onBoarding.isNotEmpty) {
      Get.off(() => const OnBoardingScreen());
    } else {
      Get.off(() => const LoginScreen(), routeName: '/login');
    }
  }
}

class _LangTile extends StatelessWidget {
  final String label;
  final String code;
  final bool selected;
  final VoidCallback onTap;

  const _LangTile({
    required this.label,
    required this.code,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final client = AppRole.isClient();
    final flag = _langFlag(code);
    if (client) {
      return Container(
        margin: const EdgeInsets.fromLTRB(12, 6, 12, 6),
        decoration: selected
            ? BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: const LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [Color(0xFF1A4A78), Color(0xFF5B2A8A)],
                ),
                border: Border.all(color: const Color(0xFF5CE1FF), width: 1.5),
                boxShadow: ClientColors.neonGlow(
                  color: const Color(0xFF5CE1FF),
                  alpha: 0.45,
                  blur: 18,
                ),
              )
            : ClientColors.glass(),
        child: ListTile(
          leading: Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: ClientColors.surfaceAlt,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: ClientColors.primary.withValues(alpha: 0.4),
              ),
            ),
            child: Text(flag, style: const TextStyle(fontSize: 22)),
          ),
          title: Text(
            label,
            style: TextStyleCustom.outFitMedium500(
              color: ClientColors.text,
              fontSize: 16,
            ),
          ),
          subtitle: Text(
            code.toUpperCase(),
            style: TextStyleCustom.outFitRegular400(
              color: ClientColors.textMuted,
              fontSize: 12,
            ),
          ),
          trailing: Icon(
            selected ? Icons.check_circle_rounded : Icons.chevron_right,
            color: selected
                ? const Color(0xFF5CE1FF)
                : ClientColors.primary.withValues(alpha: 0.7),
          ),
          onTap: onTap,
        ),
      );
    }
    return Card(
      color: Colors.white.withValues(alpha: selected ? 0.22 : 0.12),
      child: ListTile(
        title: Text(label, style: TextStyle(color: whitePure(context))),
        subtitle: Text(
          code.toUpperCase(),
          style: TextStyle(color: whitePure(context).withValues(alpha: 0.7)),
        ),
        trailing: Icon(
          selected ? Icons.check_circle : Icons.chevron_right,
          color: whitePure(context),
        ),
        onTap: onTap,
      ),
    );
  }
}

String _langFlag(String code) {
  switch (code.toLowerCase()) {
    case 'ar':
      return '🇦🇪';
    case 'zh':
      return '🇨🇳';
    case 'en':
      return '🇬🇧';
    case 'pt':
      return '🇵🇹';
    case 'ru':
      return '🇷🇺';
    case 'es':
      return '🇪🇸';
    case 'uk':
      return '🇺🇦';
    default:
      return '🌐';
  }
}
