import 'dart:math';

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
    if (token == null) {
      storage.remove(SessionKeys.authToken);
      return;
    }
    storage.write(SessionKeys.authToken, token.toJson());
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

      storage.write(SessionKeys.user, newUser.toJson());
      userRx.value = newUser;
      _syncLastGuest(newUser);
    }
  }

  void _syncLastGuest(User user) {
    if ((user.isAnonymous ?? 0) == 1) {
      saveLastGuest(user);
      return;
    }
    final last = getLastGuest();
    if (last != null && last.id == (user.id ?? 0).toInt()) {
      clearLastGuest();
    }
  }

  String getOrCreateDeviceUuid() {
    final stored = storage.read(SessionKeys.deviceUuid);
    if (stored is String && stored.length >= 8) {
      return stored;
    }
    final uuid = _newUuidV4();
    storage.write(SessionKeys.deviceUuid, uuid);
    return uuid;
  }

  LastGuest? getLastGuest() {
    final raw = storage.read(SessionKeys.lastGuest);
    if (raw is LastGuest) return raw;
    if (raw is Map) {
      try {
        return LastGuest.fromJson(Map<String, dynamic>.from(raw));
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  void saveLastGuest(User user) {
    final snapshot = LastGuest.fromUser(user);
    if (snapshot.id <= 0) return;
    storage.write(SessionKeys.lastGuest, snapshot.toJson());
  }

  void clearLastGuest() {
    storage.remove(SessionKeys.lastGuest);
  }

  String _newUuidV4() {
    final r = Random.secure();
    final bytes = List<int>.generate(16, (_) => r.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    String h(int i) => bytes[i].toRadixString(16).padLeft(2, '0');
    return '${h(0)}${h(1)}${h(2)}${h(3)}-${h(4)}${h(5)}-'
        '${h(6)}${h(7)}-${h(8)}${h(9)}-'
        '${h(10)}${h(11)}${h(12)}${h(13)}${h(14)}${h(15)}';
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
  static const deviceUuid = "device_uuid";
  static const lastGuest = "last_guest";
}

class LastGuest {
  final int id;
  final String fullname;
  final String username;
  final String? profilePhoto;

  const LastGuest({
    required this.id,
    required this.fullname,
    required this.username,
    this.profilePhoto,
  });

  factory LastGuest.fromUser(User user) {
    return LastGuest(
      id: (user.id ?? 0).toInt(),
      fullname: (user.fullname ?? '').trim(),
      username: (user.username ?? '').trim(),
      profilePhoto: user.profilePhoto,
    );
  }

  factory LastGuest.fromJson(Map<String, dynamic> json) {
    return LastGuest(
      id: int.tryParse('${json['id']}') ?? 0,
      fullname: (json['fullname'] ?? '').toString().trim(),
      username: (json['username'] ?? '').toString().trim(),
      profilePhoto: json['profile_photo']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'fullname': fullname,
        'username': username,
        'profile_photo': profilePhoto,
      };

  String get displayName {
    if (fullname.isNotEmpty) return fullname;
    if (username.isNotEmpty) return username;
    return 'Guest';
  }
}
