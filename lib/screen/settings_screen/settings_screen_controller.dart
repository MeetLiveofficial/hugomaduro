import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:krimson/common/controller/base_controller.dart';
import 'package:krimson/common/controller/firebase_firestore_controller.dart';
import 'package:krimson/common/manager/logger.dart';
import 'package:krimson/common/manager/session_manager.dart';
import 'package:krimson/common/service/api/user_service.dart';
import 'package:krimson/common/widget/confirmation_dialog.dart';
import 'package:krimson/languages/languages_keys.dart';
import 'package:krimson/model/general/settings_model.dart';
import 'package:krimson/model/general/status_model.dart';
import 'package:krimson/model/user_model/user_model.dart';
import 'package:krimson/screen/auth_screen/login_screen.dart';
import 'package:krimson/screen/auth_screen/auth_screen_controller.dart';
import 'package:krimson/screen/dashboard_screen/dashboard_screen_controller.dart';

class SettingsScreenController extends BaseController {
  Rx<User?> myUser = Rx<User?>(null);
  Rx<Setting?> settings = Rx<Setting?>(null);
  Rx<WhoCanSeePost> selectedWhoCanSeePost = WhoCanSeePost.values.first.obs;
  RxBool isUpdateApiCalled = false.obs;

  @override
  void onInit() {
    super.onInit();
    initData();
  }

  void initData() {
    myUser.value = SessionManager.instance.getUser();
    settings.value = SessionManager.instance.getSettings();
    selectedWhoCanSeePost.value = (myUser.value?.whoCanViewPost == 1)
        ? WhoCanSeePost.followersOnly
        : WhoCanSeePost.everyone;

    // For refresh user data only
    UserService.instance.fetchUserDetails().then((value) {
      if (value != null) {
        myUser.value = value;
      }
    });
  }

  void onChangedWhoCanSeePost(WhoCanSeePost? value) async {
    isUpdateApiCalled.value = true;

    selectedWhoCanSeePost.value = value ?? WhoCanSeePost.values.first;
    await UserService.instance.updateUserDetails(whoCanSeePost: value?.value);
    isUpdateApiCalled.value = false;
  }

  onChangedToggle(bool value, SettingToggle settingToggle) async {
    isUpdateApiCalled.value = true;
    await UserService.instance.updateUserDetails(
        notifyPostLike:
            settingToggle == SettingToggle.notifyPostLike ? value : null,
        notifyPostComment:
            settingToggle == SettingToggle.notifyPostComment ? value : null,
        notifyFollow:
            settingToggle == SettingToggle.notifyFollow ? value : null,
        notifyMention:
            settingToggle == SettingToggle.notifyMention ? value : null,
        notifyGiftReceived:
            settingToggle == SettingToggle.notifyGiftReceived ? value : null,
        notifyChat: settingToggle == SettingToggle.notifyChat ? value : null,
        receiveMessage:
            settingToggle == SettingToggle.receiveMessage ? value : null,
        matchEnabled:
            settingToggle == SettingToggle.matchEnabled ? value : null,
        showMyFollowing:
            settingToggle == SettingToggle.showMyFollowings ? value : null);
    isUpdateApiCalled.value = false;
    // For update user value
    myUser.value = SessionManager.instance.getUser();
  }

  void onDeleteAccount() {
    Get.bottomSheet(ConfirmationSheet(
        onTap: () async {
          showLoader(barrierDismissible: true);
          _stopSessionBackgroundWork();
          StatusModel model = await UserService.instance.deleteMyAccount();
          stopLoader();
          if (model.status == true) {
            FirebaseFirestoreController.instance.deleteUser(myUser.value?.id);
            SessionManager.instance.clear();
            _deleteSessionControllers();
            deleteCurrentUser();
            Get.offAll(() => const LoginScreen(), routeName: '/login');
          } else {
            showSnackBar(model.message);
          }
        },
        description: LKey.deleteAccountMessage.tr,
        description2: LKey.proceedConfirmation.tr,
        title: LKey.deleteYourAccount.tr));
  }

  Future<void> deleteCurrentUser() async {
    try {
      auth.User? user = auth.FirebaseAuth.instance.currentUser;

      if (user != null) {
        await user.delete(); // Deletes the account
        Loggers.success("User account deleted successfully.");
      } else {
        Loggers.success("No user is signed in.");
      }
    } on auth.FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        Loggers.error(
            '⚠️ The user must re-authenticate before deleting their account.');
        reAuthenticateAndDelete(myUser.value?.identity ?? '');
        // Prompt for re-authentication here
      } else {
        Loggers.error('❌ Error: ${e.message}');
      }
    }
  }

  Future<void> reAuthenticateAndDelete(String email) async {
    try {
      auth.User? user = auth.FirebaseAuth.instance.currentUser;

      if (user != null) {
        String? password = SessionManager.instance.getPassword();
        if (password == null) return;
        auth.AuthCredential credential =
            auth.EmailAuthProvider.credential(email: email, password: password);

        await user.reauthenticateWithCredential(credential);
        await user.delete();

        print("User re-authenticated and deleted.");
      }
    } catch (e) {
      print("Error: $e");
    }
  }

  void onLogout() {
    Get.bottomSheet(ConfirmationSheet(
      onTap: () async {
        // Cerrar sheet primero para no apilar dialogs.
        if (Get.isBottomSheetOpen == true) {
          Get.back();
        }
        showLoader(barrierDismissible: true);
        try {
          // Cortar polls del dashboard ANTES de limpiar token (evita 401 en loop).
          _stopSessionBackgroundWork();

          try {
            await UserService.instance
                .logoutUser()
                .timeout(const Duration(seconds: 6));
          } catch (_) {
            // Seguimos con logout local aunque la API falle / cuelgue.
          }
          if (!kIsWeb) {
            try {
              await GoogleSignIn.instance
                  .signOut()
                  .timeout(const Duration(seconds: 2));
            } catch (_) {}
          }
          try {
            await auth.FirebaseAuth.instance
                .signOut()
                .timeout(const Duration(seconds: 2));
          } catch (_) {}

          SessionManager.instance.clearSomeKey();
          _deleteSessionControllers();
        } catch (e) {
          showSnackBar('$e');
        } finally {
          stopLoader();
          // Navegar siempre fuera, aunque el loader haya fallado.
          Get.offAll(() => const LoginScreen(), routeName: '/login');
        }
      },
      description: LKey.logoutConfirmation.tr,
      description2: LKey.proceedConfirmation.tr,
      title: LKey.logoutTitle.tr,
    ));
  }

  void _stopSessionBackgroundWork() {
    if (Get.isRegistered<DashboardScreenController>()) {
      try {
        Get.find<DashboardScreenController>().stopBackgroundWork();
      } catch (_) {}
    }
  }

  void _deleteSessionControllers() {
    try {
      if (Get.isRegistered<DashboardScreenController>()) {
        Get.delete<DashboardScreenController>(force: true);
      }
    } catch (_) {}
    try {
      if (Get.isRegistered<FirebaseFirestoreController>()) {
        Get.delete<FirebaseFirestoreController>(force: true);
      }
    } catch (_) {}
    try {
      if (Get.isRegistered<AuthScreenController>()) {
        Get.delete<AuthScreenController>(force: true);
      }
    } catch (_) {}
  }
}

enum WhoCanSeePost {
  everyone,
  followersOnly;

  String get title {
    switch (this) {
      case WhoCanSeePost.everyone:
        return LKey.everyone.tr;
      case WhoCanSeePost.followersOnly:
        return LKey.followersOnly.tr;
    }
  }

  String get value {
    switch (this) {
      case WhoCanSeePost.everyone:
        return '0';
      case WhoCanSeePost.followersOnly:
        return '1';
    }
  }
}

enum SettingToggle {
  showMyFollowings,
  receiveMessage,
  matchEnabled,
  notifyPostLike,
  notifyPostComment,
  notifyFollow,
  notifyMention,
  notifyGiftReceived,
  notifyChat;
}
