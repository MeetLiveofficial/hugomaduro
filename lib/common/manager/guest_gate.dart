import 'package:get/get.dart';
import 'package:krimson/common/manager/session_manager.dart';
import 'package:krimson/common/widget/guest_join_sheet.dart';
import 'package:krimson/model/user_model/user_model.dart';
import 'package:krimson/screen/auth_screen/auth_screen_controller.dart';
import 'package:krimson/screen/auth_screen/registration_screen.dart';

/// Cliente Guest (incógnito): mismos privilegios que un cliente normal.
/// El sheet de unirse es opcional para vincular email, no un bloqueo.
class GuestGate {
  GuestGate._();

  static bool _sheetOpen = false;

  static User? get _user => SessionManager.instance.getUser();

  static bool get isAnonymous => (_user?.isAnonymous ?? 0) == 1;

  /// Ya no bloquea acciones: el Guest opera como cliente.
  static bool block() => false;

  static void showJoinSheet() {
    if (_sheetOpen) return;
    _sheetOpen = true;
    Get.bottomSheet(
      const GuestJoinSheet(),
      isScrollControlled: true,
    ).whenComplete(() => _sheetOpen = false);
  }

  /// Abre el registro para vincular email sin expulsar la pantalla actual.
  /// No restaura la sesión Guest (eso sacaba del formulario).
  static void openRegistration() {
    if (Get.isBottomSheetOpen == true) {
      Get.back();
    }
    if (!Get.isRegistered<AuthScreenController>()) {
      Get.put(AuthScreenController());
    }
    Get.to(() => const RegistrationScreen());
  }
}
