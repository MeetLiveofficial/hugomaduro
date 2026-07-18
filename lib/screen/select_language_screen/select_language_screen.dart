import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krimson/common/manager/session_manager.dart';
import 'package:krimson/common/widget/theme_blur_bg.dart';
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
    final languages =
        SessionManager.instance.getSettings()?.languages ?? [];
    final active = languages.where((e) => e.status == 1).toList();

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
                    'Idioma',
                    style: TextStyle(
                      color: whitePure(context),
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Elige el idioma de la app',
                    style: TextStyle(color: whitePure(context).withValues(alpha: 0.8)),
                  ),
                  const SizedBox(height: 24),
                  Expanded(
                    child: active.isEmpty
                        ? ListView(
                            children: [
                              _LangTile(
                                label: 'English',
                                code: 'en',
                                onTap: () => _select('en'),
                              ),
                              _LangTile(
                                label: 'Español',
                                code: 'es',
                                onTap: () => _select('es'),
                              ),
                            ],
                          )
                        : ListView.builder(
                            itemCount: active.length,
                            itemBuilder: (_, i) {
                              final lang = active[i];
                              return _LangTile(
                                label: lang.localizedTitle ??
                                    lang.title ??
                                    lang.code ??
                                    'Lang',
                                code: lang.code ?? 'en',
                                onTap: () => _select(lang.code ?? 'en'),
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

  void _select(String code) {
    SessionManager.instance.setBool(SessionKeys.isLanguageScreenSelect, true);
    // Aplica locale GetX de inmediato (sin esto el login sigue en inglés).
    SessionManager.instance.setLang(code);

    if (languageNavigationType == LanguageNavigationType.fromSetting) {
      Get.back();
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
  final VoidCallback onTap;

  const _LangTile({
    required this.label,
    required this.code,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white.withValues(alpha: 0.12),
      child: ListTile(
        title: Text(label, style: TextStyle(color: whitePure(context))),
        subtitle: Text(code, style: TextStyle(color: whitePure(context).withValues(alpha: 0.7))),
        trailing: Icon(Icons.chevron_right, color: whitePure(context)),
        onTap: onTap,
      ),
    );
  }
}
