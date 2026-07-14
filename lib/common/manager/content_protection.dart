import 'package:krimson/common/controller/base_controller.dart';
import 'package:krimson/utilities/const_res.dart';

/// Gate único para compartir / descargar contenido o perfil.
class ContentProtection {
  ContentProtection._();

  static bool get canShare => allowContentSharing;
  static bool get canDownload => allowContentDownload;

  /// true = permitido; false = bloqueado (y snackbar opcional).
  static bool ensureShareAllowed({bool notify = true}) {
    if (canShare) return true;
    if (notify) {
      BaseController.share.showSnackBar(
        'Sharing is disabled for this app.',
      );
    }
    return false;
  }

  static bool ensureDownloadAllowed({bool notify = true}) {
    if (canDownload) return true;
    if (notify) {
      BaseController.share.showSnackBar(
        'Downloads are disabled for this app.',
      );
    }
    return false;
  }
}
