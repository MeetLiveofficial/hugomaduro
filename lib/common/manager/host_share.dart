import 'package:krimson/common/manager/app_role.dart';
import 'package:krimson/common/manager/session_manager.dart';

/// Galería: un solo `coin_price` real. El cliente ve 100%;
/// la streamer ve su % (A/S = LIVE, resto = B/C).
class HostShare {
  static double streamerPercent() {
    final settings = SessionManager.instance.getSettings();
    final user = SessionManager.instance.getUser();
    final live = settings?.hostSharePercentLive ?? 35;
    final standard = settings?.hostSharePercentStandard ?? 30;
    var grade = (user?.weeklyCallGrade ?? user?.effectiveStreamerGrade ?? '')
        .trim()
        .toUpperCase();
    if (grade == 'SS') grade = 'S';
    if (grade == 'D') grade = 'NEW';
    if (grade == 'A' || grade == 'S') return live;
    return standard;
  }

  /// Precio visible. El cobro al cliente sigue siendo el 100%.
  static int displayCoins(int fullPrice) {
    if (fullPrice <= 0) return 0;
    if (!AppRole.isStreamer()) return fullPrice;
    return (fullPrice * streamerPercent() / 100).floor();
  }
}
