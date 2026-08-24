import 'package:get/get.dart';
import 'package:krimson/common/manager/session_manager.dart';

/// Nombre visible de un código de idioma (`es` → Español).
class LanguageDisplay {
  LanguageDisplay._();

  static const _names = {
    'es': 'Español',
    'en': 'English',
    'pt': 'Português',
    'fr': 'Français',
    'de': 'Deutsch',
    'it': 'Italiano',
    'ar': 'العربية',
    'hi': 'हिन्दी',
    'zh': '中文',
    'ja': '日本語',
    'ko': '한국어',
    'ru': 'Русский',
    'uk': 'Українська',
  };

  static String name(String? code) {
    if (code == null || code.trim().isEmpty) return '';
    final c = code.trim().toLowerCase().split(RegExp(r'[_-]')).first;
    final fromSettings = SessionManager.instance
        .getActiveLanguages()
        .firstWhereOrNull((l) => (l.code ?? '').toLowerCase() == c);
    if (fromSettings != null) {
      final title =
          (fromSettings.localizedTitle ?? fromSettings.title ?? '').trim();
      if (title.isNotEmpty) return title;
    }
    return _names[c] ?? c.toUpperCase();
  }
}
