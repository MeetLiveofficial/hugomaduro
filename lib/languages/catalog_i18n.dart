import 'package:get/get.dart';
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
}
