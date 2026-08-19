import 'package:get/get.dart';
import 'package:krimson/common/manager/session_manager.dart';
import 'package:krimson/common/widget/guest_join_sheet.dart';
import 'package:krimson/model/user_model/user_model.dart';

/// Perfil invitado: ve contenido, no puede match / chat / llamadas / comentarios / regalos.
class GuestGate {
  GuestGate._();

  static bool _sheetOpen = false;

  static User? get _user => SessionManager.instance.getUser();

  static bool get isAnonymous => (_user?.isAnonymous ?? 0) == 1;

  /// true = acción bloqueada (el caller debe hacer return).
  static bool block() {
    if (!isAnonymous) return false;
    showJoinSheet();
    return true;
  }

  static void showJoinSheet() {
    if (_sheetOpen) return;
    _sheetOpen = true;
    Get.bottomSheet(
      const GuestJoinSheet(),
      isScrollControlled: true,
    ).whenComplete(() => _sheetOpen = false);
  }
}
