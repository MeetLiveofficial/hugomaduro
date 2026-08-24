import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:krimson/common/service/api/user_service.dart';
import 'package:krimson/model/general/settings_model.dart';
import 'package:krimson/model/user_model/user_model.dart';
import 'package:krimson/utilities/app_res.dart';

class SessionManager {
  static var instance = SessionManager();
  var storage = GetStorage('krimson');
  var conversationId = '';
  RxInt notifyCount = 0.obs;
  RxInt isModerator = 0.obs;
  /// Usuario de sesión reactivo: el perfil y el wallet leen de aquí.
  final Rxn<User> userRx = Rxn<User>();

  SessionManager() {
    listenNotifyCount();
    listenModerator();
    listenSubscription();
    listenUser();
  }

  User? _asUser(dynamic value) {
    if (value == null) return null;
    if (value is User) return value;
    if (value is Map) {
      try {
        return User.fromJson(Map<String, dynamic>.from(value));
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  void listenUser() {
    userRx.value = getUser();
    storage.listenKey(SessionKeys.user, (value) {
      final user = _asUser(value);
      userRx.value = user;
      isModerator.value = user?.isModerator ?? 0;
    });
  }

  void setAuthToken(Token? token) {
    storage.write(SessionKeys.authToken, token);
  }

  String getAuthToken() {
    return getToken()?.authToken ?? '';
  }

  bool get hasAuthToken {
    final token = getAuthToken();
    return token.isNotEmpty && token != 'AUTH TOKEN EMPTY';
  }

  void setPassword(String? password) {
    storage.write(SessionKeys.password, password);
  }

  String? getPassword() {
    return storage.read(SessionKeys.password);
  }

  Token? getToken() {
    var token = storage.read(SessionKeys.authToken);
    if (token is Token?) {
      return token;
    } else {
      return Token.fromJson(token);
    }
  }

  void setNotifyCount(int count) {
    int oldCount = getNotifyCount;
    oldCount += count;
    storage.write(SessionKeys.notifyCount, oldCount);
  }

  int get getNotifyCount {
    return storage.read(SessionKeys.notifyCount) ?? 0;
  }

  void listenNotifyCount() {
    notifyCount.value = getNotifyCount;
    storage.listenKey(SessionKeys.notifyCount, (value) {
      notifyCount.value = value is int ? value : 0;
    });
  }

  void listenModerator() {
    isModerator.value = getUser()?.isModerator ?? 0;
    storage.listenKey(SessionKeys.user, (value) {
      User? user = value as User?;
      isModerator.value = user?.isModerator ?? 0;
    });
  }

  void listenSubscription() {
    isModerator.value = getUser()?.isVerify ?? 0;
    storage.listenKey(SessionKeys.user, (value) {
      User? user = value as User?;
      isModerator.value = user?.isModerator ?? 0;
    });
  }

  void setUser(User? user) {
    if (user != null) {
      // Convert the object to a JSON map and set 'stories' to null
      Map<String, dynamic> json = user.toJson();
      json['stories'] = null;

      // Re-create the User object from the modified JSON map
      User newUser = User.fromJson(json);

      storage.write(SessionKeys.user, newUser);
      userRx.value = newUser;
    }
  }

  User? getUser() {
    var user = storage.read(SessionKeys.user);

    if (user == null || user is User?) {
      return user;
    } else if (user is Map<String, dynamic>) {
      return User.fromJson(user);
    } else {
      return null;
    }
  }

  int getUserID() {
    return (getUser()?.id ?? 0).toInt();
  }

  String getCurrency() {
    return getSettings()?.currency ?? AppRes.currency;
  }

  void setSettings(Setting settings) {
    storage.write(SessionKeys.setting, settings.toJson());
    if (settings.appName != null && settings.appName!.trim().isNotEmpty) {
      final name = settings.appName!.trim();
      // Rebrand: ignorar nombre legacy cacheado/API hasta que el panel se actualice.
      AppRes.appName =
          (name.toLowerCase() == 'krimson') ? 'Meet&Live' : name;
    }
  }

  Setting? getSettings() {
    var data = storage.read(SessionKeys.setting);
    if (data is Setting) return data;
    if (data is Map) {
      try {
        return Setting.fromJson(Map<String, dynamic>.from(data));
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  /// Guarda el locale localmente y, si hay sesión, lo sincroniza al perfil
  /// (`app_language`) en el backend. Hay que **await** antes de RestartWidget
  /// para que el chip del perfil no vuelva a mostrar el idioma anterior.
  Future<void> setLang(String langCode, {bool syncRemote = true}) async {
    storage.write(SessionKeys.lang, langCode);
    // Sin esto GetX sigue mostrando el idioma anterior (claves en inglés).
    Get.updateLocale(Locale(langCode));
    final user = getUser();
    if (user != null) {
      user.appLanguage = langCode;
      setUser(user);
    }
    if (syncRemote && user != null && hasAuthToken) {
      try {
        await UserService.instance.updateUserDetails(appLanguage: langCode);
      } catch (e) {
        // Locale local ya aplicado; el perfil se reintentará en el próximo sync.
      }
    }
  }

  String getLang() {
    return storage.read(SessionKeys.lang) ?? getFallbackLang();
  }

  /// Idiomas activos del panel admin (APP LANGUAGES con status = 1).
  List<Language> getActiveLanguages() {
    return (getSettings()?.languages ?? [])
        .where((e) => e.status == 1 && (e.code?.isNotEmpty ?? false))
        .toList();
  }

  /// Garantiza que el locale sea uno de los idiomas activos (p. ej. es/en/pt).
  /// Si [preferred] no está activo, usa el default del admin o el primero disponible.
  String ensureActiveLang([String? preferred]) {
    final active = getActiveLanguages();
    final codes = active.map((e) => e.code!).toList();
    final candidate = (preferred ?? getLang()).trim().toLowerCase();

    // Fallback local si el admin aún no envió idiomas (mismo set del seeder).
    if (codes.isEmpty) {
      const seeded = ['en', 'es', 'pt', 'ar', 'ru', 'uk', 'zh'];
      final resolved = seeded.contains(candidate) ? candidate : 'en';
      if (resolved != getLang()) {
        storage.write(SessionKeys.lang, resolved);
        Get.updateLocale(Locale(resolved));
      }
      return resolved;
    }

    if (codes.contains(candidate)) {
      if (candidate != getLang()) {
        setLang(candidate);
      }
      return candidate;
    }

    final defaultLang =
        active.firstWhereOrNull((e) => e.isDefault == 1)?.code ?? codes.first;
    if (defaultLang != getLang()) {
      setLang(defaultLang);
    }
    return defaultLang;
  }

  /// Aplica el idioma del perfil (app_language) a la sesión / UI.
  void applyUserAppLanguage(String? code) {
    if (code == null || code.trim().isEmpty) return;
    ensureActiveLang(code.trim().toLowerCase());
  }

  void setFallbackLang(String langCode) {
    storage.write(SessionKeys.fallbackLang, langCode);
  }

  String getFallbackLang() {
    return storage.read(SessionKeys.fallbackLang) ?? 'en';
  }

  DateTime? getLastMessageReadDate({required String spaceId}) {
    var date = storage.read(spaceId);
    if (date is DateTime) {
      return date;
    } else {
      return null;
    }
  }

  void setLastMessageReadDate({required String spaceId}) {
    storage.write(spaceId, DateTime.now());
  }

  bool isLogin() {
    return storage.read(SessionKeys.isLogin) ?? false;
  }

  void setLogin(bool isLog) {
    storage.write(SessionKeys.isLogin, isLog);
  }

  bool get shouldOpenEULASheet {
    return storage.read(SessionKeys.shouldOpenEULA) ?? true;
  }

  Future<void> setOpenEulaSheet(bool isLog) async {
    await storage.write(SessionKeys.shouldOpenEULA, isLog);
  }

  Future<void> setBool(String key, bool value) async {
    await storage.write(key, value);
  }

  bool getBool(String key) {
    return storage.read(key) ?? false;
  }

  void clear() {
    storage.erase();
  }

  void clearSomeKey() {
    storage.remove(SessionKeys.isLogin);
    storage.remove(SessionKeys.user);
    storage.remove(SessionKeys.authToken);
    storage.remove(SessionKeys.password);
    storage.remove(SessionKeys.notifyCount);
    // Conservar lang / fallbackLang: borrarlos provoca Get.updateLocale
    // y reinicios que parecen “refresco infinito” tras logout.
  }
}

class SessionKeys {
  static const isLogin = "login";
  static const shouldOpenEULA = "should_open_eula";
  static const fallbackLang = "fallback_lang";
  static const lang = "lang";
  static const setting = "setting";
  static const user = "user";
  static const authToken = "authToken";
  static const password = "password";
  static const notifyCount = "notify_count";
  static const isLanguageScreenSelect = "is_language_screen_select";
  static const isOnBoardingScreenSelect = "is_on_boarding_screen_select";
}
