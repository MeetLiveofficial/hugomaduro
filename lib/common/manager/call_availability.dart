import 'package:krimson/common/manager/app_role.dart';
import 'package:krimson/languages/languages_keys.dart';
import 'package:krimson/model/user_model/user_model.dart';
import 'package:get/get.dart';

/// Disponibilidad de videollamada de pago hacia una streamer.
class CallAvailability {
  CallAvailability._();

  /// Host del LIVE que el cliente está viendo ahora. Null si no está dentro.
  static int? watchingLiveHostId;

  static bool isLive(User? user) => (user?.isLive ?? 0) == 1;

  static bool isWatchingThisLive(User? host) {
    final hostId = host?.id;
    if (hostId == null || watchingLiveHostId == null) return false;
    return watchingLiveHostId == hostId;
  }

  static bool isOnline(User? user) =>
      user != null && (user.isActive == 1 || user.isLive == 1);

  static bool isInCall(User? user) => (user?.inCall ?? 0) == 1;

  static bool isOffline(User? user) => user != null && !isOnline(user);

  /// Mostrar el botón de llamada (aunque esté disabled).
  static bool shouldShowCallButton(User? user) {
    if (!AppRole.isClient()) return false;
    if (user == null || user.isFreez == 1) return false;
    if (isLive(user) && !isWatchingThisLive(user)) return false;
    return AppRole.canReceivePaidCalls(user);
  }

  static bool canPlaceCall(User? user) {
    if (!shouldShowCallButton(user)) return false;
    if (isLive(user) && !isWatchingThisLive(user)) return false;
    if (!isOnline(user)) return false;
    if (isInCall(user)) return false;
    return true;
  }

  static String? blockMessage(User? user) {
    if (user == null) return null;
    if (isLive(user) && !isWatchingThisLive(user)) {
      return LKey.callOnlyFromLive.tr;
    }
    if (isInCall(user)) return LKey.callStreamerInCall.tr;
    if (!isOnline(user)) return LKey.callStreamerOffline.tr;
    if (!AppRole.canReceivePaidCalls(user)) return LKey.callCannotReceive.tr;
    return null;
  }

  static int callCost(User? user) {
    if (user == null) return 0;
    if (user.callRequestCoins > 0) return user.callRequestCoins;
    return user.getLevel.callRequestCoins;
  }
}
