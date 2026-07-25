import 'package:krimson/common/manager/session_manager.dart';
import 'package:krimson/model/user_model/user_model.dart';

/// Roles de la APP (aparte del admin del panel).
class AppRole {
  static const String streamer = 'streamer';
  static const String client = 'client';

  /// Solo `client` explícito; vacío/desconocido = streamer (UI legacy).
  static String of(User? user) {
    final raw = (user?.appRole ?? '').trim().toLowerCase();
    if (raw == client) return client;
    return streamer;
  }

  static bool isStreamer([User? user]) =>
      of(user ?? SessionManager.instance.getUser()) == streamer;

  static bool isClient([User? user]) =>
      of(user ?? SessionManager.instance.getUser()) == client;

  /// Cliente no puede crear LIVE, posts, reels ni stories.
  static bool canPublish([User? user]) => isStreamer(user);

  /// Solo streamers reciben videollamadas de pago.
  static bool canReceivePaidCalls([User? user]) {
    final u = user ?? SessionManager.instance.getUser();
    if (!isStreamer(u)) return false;
    return (u?.canReceiveCalls == 1) || (u?.getLevel.canReceiveCalls == 1);
  }

  /// Solo clientes recargan coins; streamers ganan y retiran.
  static bool canRecharge([User? user]) => isClient(user);

  /// Solo streamer puede iniciar LIVE (además de canGoLive del nivel).
  static bool canStartLive([User? user]) {
    final u = user ?? SessionManager.instance.getUser();
    if (!isStreamer(u)) return false;
    return (u?.canGoLive == 1) || (u?.getLevel.canGoLive == 1);
  }

  /// Streamer puede abrir el feed Home (LIVE | REELS | POSTS).
  static bool canAccessHomeFeed([User? user]) => isStreamer(user);
}
