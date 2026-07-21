import 'package:get/get.dart';

class DynamicTranslations extends Translations {
  final Map<String, Map<String, String>> _keys = {};

  @override
  Map<String, Map<String, String>> get keys => _keys;

  /// Carga/mezcla CSV de idiomas y los registra en GetX.
  ///
  /// GetMaterialApp solo hace `Get.addTranslations(translations.keys)` una vez
  /// al montar (cuando el mapa aún está vacío). Sin `Get.appendTranslations`,
  /// `.tr` sigue devolviendo la clave en inglés aunque el locale sea ru/es/pt.
  void addTranslations(Map<String, Map<String, String>> map) {
    map.forEach((lang, translations) {
      if (_keys.containsKey(lang)) {
        _keys[lang]?.addAll(translations);
      } else {
        _keys[lang] = Map<String, String>.from(translations);
      }
    });
    Get.appendTranslations(map);
  }
}
