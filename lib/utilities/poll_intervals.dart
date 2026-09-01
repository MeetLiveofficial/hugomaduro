/// Intervalos de polling HTTP. Subidos a 10–15s para recortar ~80% de tráfico.
/// El camino feliz sigue cubierto por FCM / LiveKit; esto es red de seguridad.
class PollIntervals {
  PollIntervals._();

  /// Match pool: `call/inbox`
  static const inboxMatch = Duration(seconds: 10);

  /// Dashboard llamadas entrantes: `call/inbox`
  static const inboxDashboard = Duration(seconds: 12);

  /// LIVE abierto: `call/inbox`
  static const inboxLive = Duration(seconds: 12);

  /// Pestaña CALL: `call/inbox`
  static const inboxCallsList = Duration(seconds: 15);

  /// Dashboard invitaciones LIVE: `live/pendingInvites`
  static const liveInvites = Duration(seconds: 15);

  /// Discovery: `live/listActive`
  static const listActive = Duration(seconds: 15);

  /// Messages + `support/summary`
  static const chatAndSupport = Duration(seconds: 15);
}
