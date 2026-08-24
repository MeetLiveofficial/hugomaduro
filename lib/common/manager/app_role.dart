import 'package:krimson/common/manager/session_manager.dart';
import 'package:krimson/model/user_model/user_model.dart';

/// Roles de la APP (aparte del admin del panel).
class AppRole {
  static const String streamer = 'streamer';
  static const String client = 'client';
  static const String agency = 'agency';

  /// `client` y `agency` son explícitos; vacío/desconocido = streamer.
  static String of(User? user) {
    final raw = (user?.appRole ?? '').trim().toLowerCase();
    if (raw == client) return client;
    if (raw == agency) return agency;
    return streamer;
  }

  static bool isStreamer([User? user]) =>
      of(user ?? SessionManager.instance.getUser()) == streamer;

  static bool isClient([User? user]) =>
      of(user ?? SessionManager.instance.getUser()) == client;

  static bool isAgency([User? user]) =>
      of(user ?? SessionManager.instance.getUser()) == agency;

  /// Cliente no puede crear LIVE, posts, reels ni stories.
  static bool canPublish([User? user]) => isStreamer(user);

  /// Solo streamers reciben videollamadas de pago.
  static bool canReceivePaidCalls([User? user]) {
    final u = user ?? SessionManager.instance.getUser();
    if (!isStreamer(u)) return false;
    return (u?.canReceiveCalls == 1) || (u?.getLevel.canReceiveCalls == 1);
  }

  /// Precio/min de llamada: solo rangos semanales A y S (SS cuenta como S).
  static bool canEditCallPrice([User? user]) {
    if (!isStreamer(user)) return false;
    var grade = (user ?? SessionManager.instance.getUser())
            ?.effectiveStreamerGrade
            ?.toUpperCase()
            .trim() ??
        '';
    if (grade == 'SS') grade = 'S';
    return grade == 'A' || grade == 'S';
  }

  /// Solo clientes envían regalos (chats, LIVE, llamadas).
  static bool canSendGifts([User? user]) {
    final u = user ?? SessionManager.instance.getUser();
    return isClient(u);
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

  /// Streamers y agencias ganan coins (no recargan).
  static bool canEarn([User? user]) => isStreamer(user) || isAgency(user);

  /// Solo streamers ven y completan tareas (retiros).
  static bool canAccessTasks([User? user]) => isStreamer(user);

  /// Streamers y agencias pueden solicitar retiros en la APP.
  static bool canWithdraw([User? user]) => canEarn(user);

  /// KYC obligatorio una sola vez al solicitar un retiro (streamers y agencias).
  static bool needsKycForWithdrawal([User? user]) {
    final u = user ?? SessionManager.instance.getUser();
    if (u == null || !canWithdraw(u)) return false;
    return !u.isKycApproved;
  }
}
