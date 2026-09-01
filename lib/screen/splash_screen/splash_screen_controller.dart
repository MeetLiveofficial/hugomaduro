import 'dart:async';
import 'dart:convert';

import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:krimson/common/controller/base_controller.dart';
import 'package:krimson/common/extensions/string_extension.dart';
import 'package:krimson/common/manager/firebase_app_helper.dart';
import 'package:krimson/common/manager/gift_media_cache.dart';
import 'package:krimson/common/manager/logger.dart';
import 'package:krimson/common/manager/session_manager.dart';
import 'package:krimson/common/manager/session_restore.dart';
import 'package:krimson/common/service/api/app_update_service.dart';
import 'package:krimson/common/service/api/common_service.dart';
import 'package:krimson/common/service/network_helper/network_helper.dart';
import 'package:krimson/common/service/translation/chat_translator_service.dart';
import 'package:krimson/common/widget/no_internet_sheet.dart';
import 'package:krimson/languages/dynamic_translations.dart';
import 'package:krimson/model/general/settings_model.dart';
import 'package:krimson/screen/auth_screen/login_screen.dart';
import 'package:krimson/screen/dashboard_screen/dashboard_screen.dart';
import 'package:krimson/utilities/app_res.dart';

class SplashScreenController extends BaseController {
  late StreamSubscription _subscription;
  bool isOnline = true;
  bool _noInternetSheetOpen = false;

  @override
  void onReady() {
    super.onReady();

    Future.wait([
      FirebaseAppHelper.ensureInitialized(),
      fetchSettings(),
    ]);

    _subscription = NetworkHelper().onConnectionChange.listen((status) {
      isOnline = status;
      if (isOnline) {
        // Solo cerrar el sheet de sin internet; NUNCA Get.back() a ciegas
        // (en BlueStacks/emuladores el evento online dispara al arrancar y
        // Get.back() sacaba el Splash dejando pantalla blanca).
        if (_noInternetSheetOpen) {
          _noInternetSheetOpen = false;
          if (Get.isDialogOpen == true ||
              (Get.key.currentState?.canPop() ?? false)) {
            Get.back();
          }
        }
      } else if (!_noInternetSheetOpen) {
        _noInternetSheetOpen = true;
        Get.to(() => const NoInternetSheet(), transition: Transition.downToUp);
      }
    });
  }

  @override
  void onClose() {
    super.onClose();
    _subscription.cancel();
  }

  Future<void> fetchSettings() async {
    try {
      await Future.delayed(const Duration(milliseconds: 800));
      bool showNavigate = false;
      try {
        showNavigate = await CommonService.instance
            .fetchGlobalSettings()
            .timeout(const Duration(seconds: 15));
      } catch (e) {
        Loggers.error('fetchGlobalSettings timeout/error: $e');
        // Si hay settings en caché, seguir (p. ej. para descargar idiomas).
        if (SessionManager.instance.getSettings() == null) {
          if (await _tryRestoreSession()) return;
          showSnackBar('Sin conexión al servidor. Revisa tu red.', second: 5);
          Get.offAll(() => const LoginScreen(), routeName: '/login');
          return;
        }
        showNavigate = true;
      }
      if (!showNavigate) {
        if (SessionManager.instance.getSettings() == null) {
          if (await _tryRestoreSession()) return;
          showSnackBar('No se pudo cargar la configuración del servidor.',
              second: 5);
          Get.offAll(() => const LoginScreen(), routeName: '/login');
          return;
        }
      }

      final translations = Get.find<DynamicTranslations>();
      var setting = SessionManager.instance.getSettings();
      // Prefetch gift GIFs into disk cache (non-blocking).
      GiftMediaCache.precacheGifts(setting?.gifts);
      var languages = setting?.languages ?? [];
      List<Language> downloadLanguages =
          languages.where((element) => element.status == 1).toList();
      if (downloadLanguages.isEmpty) {
        if (await _tryRestoreSession()) return;
        showSnackBar(AppRes.languageAdd, second: 5);
        translations.ensureAllFallbacks();
        Get.offAll(() => const LoginScreen(), routeName: '/login');
        return;
      }

      var downloadedFiles = await downloadAndParseLanguages(downloadLanguages);
      translations.addTranslations(downloadedFiles);

      var defaultLang =
          languages.firstWhereOrNull((element) => element.isDefault == 1);
      if (defaultLang != null) {
        SessionManager.instance.setFallbackLang(defaultLang.code ?? 'en');
      }

      // NUNCA abrir SelectLanguage al arrancar: Login primero.
      // El idioma se cambia desde el desplegable del Login.
      SessionManager.instance
          .setBool(SessionKeys.isLanguageScreenSelect, true);
      if (SessionManager.instance.getLang().trim().isEmpty) {
        await SessionManager.instance.setLang('en', syncRemote: false);
      }

      // Solo idiomas activos del panel (ES/EN/PT, etc.) impulsan la UI.
      final activeLang = SessionManager.instance.ensureActiveLang();
      // Forzar locale tras registrar CSV en Get.translations (ver DynamicTranslations).
      Get.updateLocale(Locale(activeLang));

      // Precarga silenciosa de modelos ML Kit (EN + idioma del usuario).
      // No bloquea la navegación; la primera traducción en chat será instantánea.
      unawaited(
        ChatTranslatorService.instance.preloadForUserLanguage(
          langCode: activeLang,
        ),
      );

      // No reiniciar toda la app aquí: RestartWidget + Get.off dejaba
      // navigator vacío (pantalla blanca) en emuladores.

      if (await _tryRestoreSession()) return;

      Get.offAll(() => const LoginScreen(), routeName: '/login');
      unawaited(AppUpdateService.instance.maybeShowUpdateDialog());
    } catch (e, st) {
      Loggers.error('Splash fetchSettings error: $e\n$st');
      if (isSessionAuthFailure(e)) {
        SessionManager.instance.clearSomeKey();
        Get.offAll(() => const LoginScreen(), routeName: '/login');
        return;
      }
      if (await _tryRestoreSession()) return;
      showSnackBar('Error de inicio: $e', second: 8);
      Get.offAll(() => const LoginScreen(), routeName: '/login');
    }
  }

  /// Restaura sesión (Guest o usuario normal) desde almacenamiento local.
  /// Solo cierra sesión si el token es inválido; fallos de red usan caché.
  Future<bool> _tryRestoreSession() async {
    if (!SessionManager.instance.isLogin()) {
      return false;
    }
    if (!SessionManager.instance.hasAuthToken) {
      SessionManager.instance.clearSomeKey();
      return false;
    }

    final cachedUser = SessionManager.instance.getUser();
    if (cachedUser == null || (cachedUser.id ?? 0) <= 0) {
      SessionManager.instance.clearSomeKey();
      return false;
    }

    try {
      final user = await refreshSessionUser();
      if (user == null) {
        Get.offAll(() => DashboardScreen(myUser: cachedUser),
            routeName: '/dashboard');
      } else {
        Get.offAll(() => DashboardScreen(myUser: user),
            routeName: '/dashboard');
      }
      unawaited(AppUpdateService.instance.maybeShowUpdateDialog());
      return true;
    } catch (e) {
      Loggers.error('Splash session restore failed: $e');
      SessionManager.instance.clearSomeKey();
      return false;
    }
  }

  Future<Map<String, Map<String, String>>> downloadAndParseLanguages(List<Language> languages) async {
    final languageData = <String, Map<String, String>>{};
    final pending = <Future<void>>[];

    for (var language in languages) {
      if (language.code != null && language.csvFile != null) {
        pending.add(downloadAndProcessLanguage(language, languageData));
        // Máx. 3 descargas en paralelo.
        if (pending.length >= 3) {
          await Future.wait(pending);
          pending.clear();
        }
      }
    }
    if (pending.isNotEmpty) {
      await Future.wait(pending);
    }

    return languageData;
  }

  Future<void> downloadAndProcessLanguage(Language language, Map<String, Map<String, String>> languageData) async {
    final url = language.csvFile?.addBaseURL() ?? '';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final csvContent = utf8.decode(response.bodyBytes);
        final parsedMap = _parseCsvToMap(csvContent);
        languageData[language.code!] = parsedMap;
        Loggers.info(
            'Downloaded and parsed: ${language.code} (${parsedMap.length} keys)');
      } else {
        Loggers.error(
            'Failed to download ${language.code}: ${response.statusCode} url=$url');
      }
    } catch (e) {
      Loggers.error('Error downloading ${language.code}: $e url=$url');
    }
  }

  Map<String, String> _parseCsvToMap(String csvContent) {
    // Los CSV del server usan LF (\n). El default del paquete `csv` es CRLF,
    // y entonces todo el archivo queda como 1 sola fila → 1 sola clave → UI en inglés.
    final normalized =
        csvContent.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    final rows = const CsvToListConverter(
      eol: '\n',
      shouldParseNumbers: false,
    ).convert(normalized);
    final map = <String, String>{};

    for (var row in rows) {
      if (row.length >= 2) {
        final key = row[0].toString();
        final value = row[1].toString();
        if (key.isNotEmpty) {
          map[key] = value;
        }
      }
    }
    return map;
  }
}
