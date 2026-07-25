import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krimson/common/manager/session_manager.dart';
import 'package:krimson/common/widget/restart_widget.dart';
import 'package:krimson/common/widget/theme_blur_bg.dart';
import 'package:krimson/languages/languages_keys.dart';
import 'package:krimson/screen/auth_screen/login_screen.dart';
import 'package:krimson/screen/on_boarding_screen/on_boarding_screen.dart';
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

    return Scaffold(
      body: Stack(
        children: [
          const ThemeBlurBg(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    LKey.language.tr,
                    style: TextStyle(
                      color: whitePure(context),
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    LKey.languages.tr,
                    style: TextStyle(
                      color: whitePure(context).withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Expanded(
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
