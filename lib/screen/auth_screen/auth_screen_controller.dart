import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:image_picker/image_picker.dart';
import 'package:krimson/common/controller/base_controller.dart';
import 'package:krimson/common/manager/firebase_app_helper.dart';
import 'package:krimson/common/manager/firebase_notification_manager.dart';
import 'package:krimson/common/manager/app_role.dart';
import 'package:krimson/common/manager/guest_gate.dart';
import 'package:krimson/common/manager/logger.dart';
import 'package:krimson/common/manager/session_manager.dart';
import 'package:krimson/common/manager/session_restore.dart';
import 'package:krimson/common/service/api/common_service.dart';
import 'package:krimson/common/service/api/notification_service.dart';
import 'package:krimson/common/service/api/user_service.dart';
import 'package:krimson/common/service/subscription/subscription_manager.dart';
import 'package:krimson/languages/dynamic_translations.dart';
import 'package:krimson/languages/languages_keys.dart';
import 'package:krimson/model/general/countries_model.dart';
import 'package:krimson/model/general/settings_model.dart';
import 'package:krimson/model/user_model/user_model.dart' as user;
import 'package:krimson/screen/auth_screen/guest_setup_screen.dart';
import 'package:krimson/screen/dashboard_screen/dashboard_screen.dart';
import 'package:krimson/utilities/asset_res.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

/// Auth de Krimson:
/// - Email/password → SIEMPRE Laravel (valida password). Firebase es opcional (chat).
/// - Google/Apple → Firebase social + Laravel logInUser (sin password).
class AuthScreenController extends BaseController {
  TextEditingController fullNameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController forgetEmailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController confirmPassController = TextEditingController();

  final Rxn<DateTime> birthDate = Rxn<DateTime>();
  final Rxn<Country> selectedCountry = Rxn<Country>();
  final RxString selectedLanguage = ''.obs;
  final RxList<Country> countries = <Country>[].obs;
  final RxList<Language> languages = <Language>[].obs;

  bool get _firebaseReady => FirebaseAppHelper.isReady;

  @override
  void onInit() {
    CommonService.instance.fetchGlobalSettings();
    _loadRegistrationOptions();
    // Solo FCM si Firebase ya está listo (evita [core/no-app] en Auth).
    if (_firebaseReady) {
      FirebaseNotificationManager.instance;
    } else {
      FirebaseAppHelper.ensureInitialized().then((ok) {
        if (ok) FirebaseNotificationManager.instance;
      });
    }
    super.onInit();
    try {
      Get.find<DynamicTranslations>().ensureAgencyFallbacks();
    } catch (_) {}
    unawaited(_tryAutoRestoreSession());
  }

  /// Si hay sesión guardada (Guest u otro), entrar sin pedir login de nuevo.
  Future<void> _tryAutoRestoreSession() async {
    if (!hasStoredSession()) return;
    try {
      final user = await refreshSessionUser(
        timeout: const Duration(seconds: 12),
      );
      if (user != null) {
        await _navigateScreen(user);
      }
    } catch (e) {
      if (isSessionAuthFailure(e)) {
        SessionManager.instance.clearSomeKey();
      }
    }
  }

  Future<void> _loadRegistrationOptions() async {
    try {
      final list = await parseCountries(filePath: AssetRes.countriesCSV);
      countries.assignAll(list);
    } catch (_) {}
    final active = SessionManager.instance.getActiveLanguages();
    languages.assignAll(active);
    final current = SessionManager.instance.getLang();
    if (current.isNotEmpty) {
      selectedLanguage.value = current;
    } else if (active.isNotEmpty) {
      selectedLanguage.value = (active.first.code ?? 'en').toLowerCase();
    } else {
      selectedLanguage.value = 'en';
    }
  }

  String get birthDateLabel {
    final d = birthDate.value;
    if (d == null) return LKey.selectDateOfBirth.tr;
    final mm = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    return '$dd/$mm/${d.year}';
  }

  String get birthDateApi {
    final d = birthDate.value;
    if (d == null) return '';
    final mm = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    return '${d.year}-$mm-$dd';
  }

  Future<void> pickBirthDate(BuildContext context) async {
    final today = _dateOnly(DateTime.now());
    // Último día válido = exactamente hace 18 años (cumpleaños de 18 inclusive).
    final maxDob = DateTime(today.year - 18, today.month, today.day);
    final minDob = DateTime(today.year - 100, today.month, today.day);
    final initial = birthDate.value != null
        ? _dateOnly(birthDate.value!)
        : maxDob;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isAfter(maxDob) ? maxDob : initial,
      firstDate: minDob,
      lastDate: maxDob,
      helpText: LKey.dateOfBirth.tr,
    );
    if (picked != null) {
      birthDate.value = _dateOnly(picked);
    }
  }

  void selectLanguageCode(String code) {
    selectedLanguage.value = code.toLowerCase();
  }

  void selectCountry(Country country) {
    selectedCountry.value = country;
  }

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  /// true si ya cumplió 18 años (el día del cumpleaños cuenta).
  bool _isAtLeast18(DateTime dob) {
    final today = _dateOnly(DateTime.now());
    final eighteenthBirthday =
        DateTime(dob.year + 18, dob.month, dob.day);
    return !today.isBefore(eighteenthBirthday);
  }

  Future<void> onLogin() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty) {
      return showSnackBar(LKey.enterEmail.tr);
    }
    if (password.isEmpty) {
      return showSnackBar(LKey.enterAPassword.tr);
    }

    showLoader(barrierDismissible: true);
    try {
      // Login = Laravel. Firebase NO bloquea (chat se conecta después).
      final deviceToken =
          'krimson_android_${DateTime.now().millisecondsSinceEpoch}';

      final data = await UserService.instance
          .logInFakeUser(
        identity: email,
        password: password,
        fullName: email.contains('@') ? email.split('@').first : email,
        deviceToken: deviceToken,
        loginMethod: LoginMethod.email,
      )
          .timeout(const Duration(seconds: 20), onTimeout: () {
        throw TimeoutException('El servidor tardó demasiado en responder');
      });

      // Cerrar loader ANTES del snackbar: si no, Get.back() del loader
      // se come el mensaje y parece que se queda “pensando”.
      stopLoader();

      if (data == null) {
        showSnackBar('Credenciales inválidas. Revisa email y contraseña.');
        return;
      }

      if (data.token?.authToken == null || data.token!.authToken!.isEmpty) {
        showSnackBar('Login OK pero sin token. Revisa el backend.');
        return;
      }

      SessionManager.instance.setPassword(password);
      SessionManager.instance.setUser(data);
      SessionManager.instance.setAuthToken(data.token);
      SessionManager.instance.setLogin(true);
      // No aplicar app_language del server aquí: pisa el idioma elegido
      // en SelectLanguageScreen (p. ej. ru → en). _navigateScreen lo sincroniza.

      _notifyRegistrationBonusIfNeeded(data);
      // ignore: unawaited_futures
      SubscriptionManager.shared.login('${data.id}');

      await _navigateScreen(data);

      // Firebase / chat en background (nunca bloquea el login).
      // ignore: unawaited_futures
      Future<void>(() async {
        final ok = await FirebaseAppHelper.ensureInitialized();
        if (ok) {
          await _ensureFirebaseAuthForChat(email, password);
        }
      });
    } catch (e, st) {
      Loggers.error('onLogin: $e\n$st');
      stopLoader();
      showSnackBar('No se pudo iniciar sesión. Revisa tus datos e inténtalo de nuevo.');
    } finally {
      stopLoader();
    }
  }

  Future<void> onCreateAccount() async {
    final fullName = fullNameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final confirm = confirmPassController.text.trim();

    if (fullName.isEmpty) {
      return showSnackBar(LKey.fullNameEmpty.tr);
    }
    if (email.isEmpty) {
      return showSnackBar(LKey.enterEmail.tr);
    }
    if (password.isEmpty) {
      return showSnackBar(LKey.enterAPassword.tr);
    }
    if (confirm.isEmpty) {
      return showSnackBar(LKey.confirmPasswordEmpty.tr);
    }
    if (!GetUtils.isEmail(email)) {
      return showSnackBar(LKey.invalidEmail.tr);
    }
    if (password != confirm) {
      return showSnackBar(LKey.passwordMismatch.tr);
    }
    if (password.length < 6) {
      return showSnackBar(LKey.weakPassword.tr);
    }
    if (birthDate.value == null) {
      return showSnackBar(LKey.dobRequired.tr);
    }
    if (!_isAtLeast18(birthDate.value!)) {
      return showSnackBar(LKey.mustBe18.tr);
    }
    if (selectedCountry.value == null) {
      return showSnackBar(LKey.countryRequired.tr);
    }
    if (selectedLanguage.value.trim().isEmpty) {
      return showSnackBar(LKey.languageRequired.tr);
    }

    showLoader(barrierDismissible: true);
    try {
      // Registro = Laravel. Sin esperar Firebase/FCM.
      final deviceToken =
          'krimson_android_${DateTime.now().millisecondsSinceEpoch}';

      final lang = selectedLanguage.value.trim().toLowerCase();
      await SessionManager.instance.setLang(lang, syncRemote: false);

      final data = await UserService.instance
          .registerUser(
        identity: email,
        password: password,
        fullName: fullName,
        deviceToken: deviceToken,
        loginMethod: LoginMethod.email,
        dob: birthDateApi,
        country: selectedCountry.value?.countryName,
        countryCode: selectedCountry.value?.countryCode,
        appLanguage: lang,
        keepAuthToken: GuestGate.isAnonymous,
      )
          .timeout(const Duration(seconds: 25), onTimeout: () {
        throw TimeoutException('El servidor tardó demasiado en responder');
      });

      if (data == null) {
        return;
      }

      data.appLanguage = lang;
      data.country = selectedCountry.value?.countryName;
      data.countryCode = selectedCountry.value?.countryCode;
      data.dob = birthDateApi;

      SessionManager.instance.setPassword(password);
      SessionManager.instance.setUser(data);
      SessionManager.instance.setAuthToken(data.token);

      _notifyRegistrationBonusIfNeeded(data);
      SubscriptionManager.shared.login('${data.id}');

      stopLoader();
      Get.back();
      Get.back();
      _navigateScreen(data);

      // Firebase Auth opcional en background (chat).
      // ignore: unawaited_futures
      Future<void>(() async {
        final ok = await FirebaseAppHelper.ensureInitialized();
        if (ok) {
          await _createOrSignInFirebase(email, password, displayName: fullName);
        }
      });
    } catch (e) {
      Loggers.error('onCreateAccount: $e');
      showSnackBar('No se pudo registrar: $e');
    } finally {
      stopLoader();
    }
  }

  Future<void> onAnonymousTap() async {
    Get.to(() => const GuestSetupScreen());
  }

  Future<void> completeGuestSetup({
    required String fullName,
    required int avatarIndex,
  }) async {
    final name = fullName.trim();
    if (name.length < 2) {
      showSnackBar(LKey.fullNameEmpty.tr);
      return;
    }
    final avatar = avatarIndex < 1
        ? 1
        : (avatarIndex > AssetRes.guestAvatars.length
            ? AssetRes.guestAvatars.length
            : avatarIndex);

    showLoader(barrierDismissible: true);
    try {
      final deviceToken =
          'krimson_android_${DateTime.now().millisecondsSinceEpoch}';
      final lang = SessionManager.instance.getLang();

      if (hasStoredSession() &&
          (SessionManager.instance.getUser()?.isAnonymous ?? 0) == 1) {
        try {
          final existing = await refreshSessionUser(
            timeout: const Duration(seconds: 15),
          );
          if (existing != null) {
            final photo = await _guestAvatarFile(avatar);
            final updated = await UserService.instance.updateUserDetails(
              fullname: name,
              profilePhoto: photo,
            );
            final data = updated ?? existing;
            SessionManager.instance.setUser(data);
            SessionManager.instance.setLogin(true);
            stopLoader();
            await _navigateScreen(data);
            return;
          }
        } catch (e) {
          if (isSessionAuthFailure(e)) {
            SessionManager.instance.clearSomeKey();
          }
        }
      }

      var data = await UserService.instance
          .logInAnonymousUser(
        deviceToken: deviceToken,
        appLanguage: lang.isNotEmpty ? lang : 'en',
        fullName: name,
        avatar: avatar,
      )
          .timeout(const Duration(seconds: 20), onTimeout: () {
        throw TimeoutException('El servidor tardó demasiado en responder');
      });

      if (data == null) return;
      if (data.token?.authToken == null || data.token!.authToken!.isEmpty) {
        showSnackBar('Login OK pero sin token. Revisa el backend.');
        return;
      }

      SessionManager.instance.setUser(data);
      SessionManager.instance.setAuthToken(data.token);
      SessionManager.instance.setLogin(true);

      final needsName = (data.fullname ?? '').trim().isEmpty ||
          (data.fullname ?? '').trim().toLowerCase() == 'guest';
      final needsPhoto = (data.profilePhoto ?? '').trim().isEmpty;
      if (needsName || needsPhoto) {
        try {
          final photo = needsPhoto ? await _guestAvatarFile(avatar) : null;
          final updated = await UserService.instance.updateUserDetails(
            fullname: needsName ? name : null,
            profilePhoto: photo,
          );
          if (updated != null) {
            data = updated;
            SessionManager.instance.setUser(data);
          }
        } catch (e) {
          Loggers.error('Guest profile photo: $e');
        }
      }

      stopLoader();
      await _navigateScreen(data);

      Future<void>(() async {
        final ok = await FirebaseAppHelper.ensureInitialized();
        if (ok) {
          try {
            await FirebaseAuth.instance.signInAnonymously();
          } catch (_) {}
        }
      });
    } catch (e, st) {
      Loggers.error('completeGuestSetup: $e\n$st');
      stopLoader();
      showSnackBar(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      stopLoader();
    }
  }

  Future<XFile> _guestAvatarFile(int index) async {
    final asset = AssetRes.guestAvatars[index - 1];
    final data = await rootBundle.load(asset);
    return XFile.fromData(
      data.buffer.asUint8List(),
      mimeType: 'image/jpeg',
      name: 'guest_$index.jpg',
    );
  }

  void onGoogleTap() async {
    showLoader(barrierDismissible: true);
    try {
      final ready = await FirebaseAppHelper.ensureInitialized(
        timeout: const Duration(seconds: 15),
      );
      if (!ready) {
        showSnackBar(
          'Firebase no listo. Usa email/contraseña, o espera a que '
          'google-services.json tenga oauth_client (SHA-1 en Firebase). '
          '${FirebaseAppHelper.lastError ?? ''}',
        );
        return;
      }
      final credential = await signInWithGoogle();
      if (credential.user == null) return;

      final data = await _socialLaravelLogin(
        identity: credential.user?.email ?? '',
        fullname: credential.user?.displayName ??
            credential.user?.email?.split('@').first,
        loginMethod: LoginMethod.google,
      );
      if (data != null) {
        _navigateScreen(data);
      }
    } catch (e) {
      Loggers.error(e);
      showSnackBar('$e');
    } finally {
      stopLoader();
    }
  }

  void onAppleTap() async {
    showLoader(barrierDismissible: true);
    try {
      final ready = await FirebaseAppHelper.ensureInitialized(
        timeout: const Duration(seconds: 15),
      );
      if (!ready) {
        showSnackBar(
          'Apple Sign-In requiere Firebase. Usa email/contraseña por ahora. '
          '${FirebaseAppHelper.lastError ?? ''}',
        );
        return;
      }
      final credential = await signInWithApple();
      if (credential.user == null) return;

      final data = await _socialLaravelLogin(
        identity: credential.user?.email ?? '',
        fullname: credential.user?.displayName ??
            credential.user?.email?.split('@').first,
        loginMethod: LoginMethod.apple,
      );
      if (data != null) {
        _navigateScreen(data);
      }
    } catch (e) {
      Loggers.error(e);
      showSnackBar('$e');
    } finally {
      stopLoader();
    }
  }

  Future<user.User?> _socialLaravelLogin({
    required String identity,
    String? fullname,
    required LoginMethod loginMethod,
  }) async {
    if (identity.isEmpty) {
      showSnackBar(LKey.somethingWentWrong.tr);
      return null;
    }
    String deviceToken =
        (await FirebaseNotificationManager.instance.getNotificationToken()) ??
            '';
    if (deviceToken.isEmpty) {
      deviceToken =
          'krimson_android_${DateTime.now().millisecondsSinceEpoch}';
    }

    final data = await UserService.instance.logInUser(
      identity: identity,
      loginMethod: loginMethod,
      deviceToken: deviceToken,
      fullName: fullname,
    );
    if (data == null) {
      showSnackBar(LKey.somethingWentWrong.tr);
      return null;
    }
    SessionManager.instance.setUser(data);
    SessionManager.instance.setAuthToken(data.token);
    _notifyRegistrationBonusIfNeeded(data);
    SubscriptionManager.shared.login('${data.id}');
    return data;
  }

  void _notifyRegistrationBonusIfNeeded(user.User data) {
    if (AppRole.isClient(data)) return;
    final setting = SessionManager.instance.getSettings();
    if (data.isDummy == 0 &&
        data.newRegister == true &&
        setting?.registrationBonusStatus == 1) {
      final translations = Get.find<DynamicTranslations>();
      final languageData =
          translations.keys[SessionManager.instance.getLang()] ?? {};
      NotificationService.instance.pushNotification(
          title: languageData[LKey.registrationBonusTitle] ??
              LKey.registrationBonusTitle.tr,
          body: languageData[LKey.registrationBonusDescription] ??
              LKey.registrationBonusDescription.tr,
          type: NotificationType.other,
          deviceType: data.device,
          token: data.deviceToken,
          authorizationToken: data.token?.authToken);
    }
  }

  Future<void> _createOrSignInFirebase(
    String email,
    String password, {
    String? displayName,
  }) async {
    try {
      try {
        final cred = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(email: email, password: password);
        if (displayName != null && displayName.isNotEmpty) {
          await cred.user?.updateDisplayName(displayName);
        }
      } on FirebaseAuthException catch (e) {
        if (e.code == 'email-already-in-use') {
          await FirebaseAuth.instance
              .signInWithEmailAndPassword(email: email, password: password);
        } else {
          Loggers.error('Firebase register: ${e.code} ${e.message}');
        }
      }
    } catch (e) {
      Loggers.error('_createOrSignInFirebase: $e');
    }
  }

  Future<UserCredential> signInWithGoogle() async {
    final GoogleSignIn googleSignIn = GoogleSignIn.instance;
    await googleSignIn.initialize();
    final GoogleSignInAccount account = await googleSignIn.authenticate();
    final credential =
        GoogleAuthProvider.credential(idToken: account.authentication.idToken);
    return await FirebaseAuth.instance.signInWithCredential(credential);
  }

  Future<UserCredential> signInWithApple() async {
    final appleCredential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName
      ],
    );
    final oauthCredential = OAuthProvider('apple.com').credential(
      idToken: appleCredential.identityToken,
      accessToken: appleCredential.authorizationCode,
    );
    return await FirebaseAuth.instance.signInWithCredential(oauthCredential);
  }

  void forgetPassword() async {
    final email = forgetEmailController.text.trim();
    if (email.isEmpty) {
      showSnackBar(LKey.enterEmail.tr);
      return;
    }
    if (!GetUtils.isEmail(email)) {
      showSnackBar(LKey.invalidEmail.tr);
      return;
    }
    // Reset de password depende de Firebase; si no hay, aviso claro.
    if (!_firebaseReady) {
      showSnackBar(
          'Contacta al administrador para restablecer tu contraseña en Meet&Live.');
      Get.back();
      return;
    }
    showLoader(barrierDismissible: true);
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      Get.back();
      showSnackBar(LKey.resetPasswordLinkSent.tr);
    } on FirebaseAuthException catch (e) {
      showSnackBar(e.message ?? 'An error occurred. Please try again.');
    } finally {
      stopLoader();
    }
  }

  /// Tras login Laravel OK: abre sesión Firebase para Firestore/chat.
  /// Nunca crea usuario Firebase si el password no sirve — solo anónimo como fallback.
  Future<void> _ensureFirebaseAuthForChat(String email, String password) async {
    try {
      final ready = await FirebaseAppHelper.ensureInitialized();
      if (!ready) {
        Loggers.error('Firebase Auth for chat: app not initialized');
        return;
      }
      if (FirebaseAuth.instance.currentUser != null) return;
      try {
        await FirebaseAuth.instance
            .signInWithEmailAndPassword(email: email, password: password)
            .timeout(const Duration(seconds: 8));
      } on FirebaseAuthException catch (e) {
        if (e.code == 'user-not-found') {
          try {
            await FirebaseAuth.instance
                .createUserWithEmailAndPassword(email: email, password: password)
                .timeout(const Duration(seconds: 8));
          } catch (_) {
            await FirebaseAuth.instance
                .signInAnonymously()
                .timeout(const Duration(seconds: 5));
          }
        } else if (e.code == 'wrong-password' ||
            e.code == 'invalid-credential') {
          // Password Laravel ≠ Firebase: no forzar create; chat anónimo.
          await FirebaseAuth.instance
              .signInAnonymously()
              .timeout(const Duration(seconds: 5));
        } else {
          await FirebaseAuth.instance
              .signInAnonymously()
              .timeout(const Duration(seconds: 5));
        }
      }
      Loggers.success(
          'Firebase Auth ready for chat: ${FirebaseAuth.instance.currentUser?.uid}');
    } catch (e) {
      Loggers.error('Firebase Auth for chat failed: $e');
      try {
        await FirebaseAuth.instance
            .signInAnonymously()
            .timeout(const Duration(seconds: 5));
      } catch (_) {}
    }
  }

  Future<void> _navigateScreen(user.User? data) async {
    // NO usar DebounceAction.shared: se cancela con otros debounce de la app
    // y dejaba el login "pegado" mucho tiempo antes de entrar.
    // Conservar el idioma elegido antes del login (SelectLanguage / Settings)
    // y sincronizarlo al perfil; no pisar con app_language del server (suele ser en).
    final selectedLang = SessionManager.instance.getLang();
    if (data != null) {
      data.appLanguage = selectedLang;
    }
    SessionManager.instance.setLogin(true);
    SessionManager.instance.setUser(data);
    await SessionManager.instance.setLang(selectedLang);
    Get.offAll(
      () => DashboardScreen(myUser: SessionManager.instance.getUser() ?? data),
      routeName: '/dashboard',
    );
  }
}
