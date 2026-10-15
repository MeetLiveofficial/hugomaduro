import 'package:get/get.dart';
import 'package:krimson/languages/app_fallbacks.dart';
import 'package:krimson/languages/languages_keys.dart';

/// Traduce nombres de catálogo (paquetes / marcos) que vienen del admin
/// en un solo idioma.
class CatalogI18n {
  CatalogI18n._();

  static String packageName(String? raw) {
    switch ((raw ?? '').trim().toLowerCase()) {
      case 'inicial':
      case 'starter':
        return LKey.planInicial.tr;
      case 'básico':
      case 'basico':
      case 'basic':
        return LKey.planBasico.tr;
      case 'popular':
        return LKey.planPopular.tr;
      case 'premium':
        return LKey.planPremium.tr;
      case 'vip':
        return LKey.planVip.tr;
      case 'grande':
      case 'large':
      case 'big':
        return LKey.planGrande.tr;
      default:
        return raw ?? '';
    }
  }

  static String dressingTitle(String? raw) {
    switch ((raw ?? '').trim().toLowerCase()) {
      case 'marco plata':
      case 'silver frame':
        return LKey.frameSilver.tr;
      case 'marco oro':
      case 'gold frame':
        return LKey.frameGold.tr;
      case 'marco diamante':
      case 'diamond frame':
        return LKey.frameDiamond.tr;
      default:
        return raw ?? '';
    }
  }

  /// Título o subtítulo de un método de recarga.
  /// Vacío, o igual al texto que ya traduce la app, usa el idioma del usuario.
  /// Un nombre distinto se muestra tal cual.
  static String paymentText(String? custom, String key, {String amount = ''}) {
    final value = (custom ?? '').trim();
    if (value.isEmpty || isKnownPaymentCopy(value, key)) {
      return _applyAmount(key.tr, amount);
    }
    final found = _translationKey(value);
    if (found != null) {
      return _applyAmount(found.tr, amount);
    }
    return _applyAmount(value, amount);
  }

  /// El texto del admin coincide con una frase de Idiomas: se muestra
  /// en el idioma activo. Una frase que no está en Idiomas se deja igual.
  static String? _translationKey(String raw) {
    final normalized = _norm(raw);
    if (normalized.isEmpty) return null;
    final maps = <Map<String, String>>[
      appFallbackEn,
      appFallbackEs,
      appFallbackPt,
      appFallbackAr,
      appFallbackRu,
      appFallbackUk,
      appFallbackZh,
      ...Get.translations.values,
    ];
    for (final map in maps) {
      for (final entry in map.entries) {
        if (_norm(entry.key) == normalized || _norm(entry.value) == normalized) {
          return entry.key;
        }
      }
    }
    return null;
  }

  static bool isKnownPaymentCopy(String raw, String key) {
    final normalized = _norm(raw);
    if (normalized.isEmpty || normalized == _norm(key)) return true;
    for (final map in const [
      appFallbackEn,
      appFallbackEs,
      appFallbackPt,
      appFallbackAr,
      appFallbackRu,
      appFallbackUk,
      appFallbackZh,
    ]) {
      final translated = map[key];
      if (translated != null && _norm(translated) == normalized) return true;
    }
    for (final alias in _paymentAliases[key] ?? const <String>[]) {
      if (_norm(alias) == normalized) return true;
    }
    return false;
  }

  static const _paymentAliases = <String, List<String>>{
    LKey.wompiLocalChargeHint: [
      'Cobro en COP equivalente a \$@amount USD',
    ],
  };

  static String _applyAmount(String text, String amount) {
    if (!text.contains('@amount')) return text;
    if (amount.isEmpty) {
      return text.replaceAll('@amount', '').replaceAll(RegExp(r'\s{2,}'), ' ').trim();
    }
    return text.replaceAll('@amount', amount);
  }

  static String _norm(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll('@amount', '')
        .replaceAll(RegExp(r'\d+(?:[.,]\d+)?'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}
