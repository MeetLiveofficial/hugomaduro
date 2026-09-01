/// Un solo dueño de la cámara del streamer (estudio LIVE vs espera Match).
///
/// Evita Camera2/LiveKit a la vez, que en móvil tira errores y deja el
/// placeholder «Turning camera on…».
class StreamerCameraLock {
  StreamerCameraLock._();

  /// Match wait screen está visible (Get.to Match).
  static bool matchWaitVisible = false;

  /// Libera pool + cámara de espera Match. Lo registra MatchScreenController.
  static Future<void> Function()? releaseMatchWait;

  static Future<void> releaseMatchWaitIfAny() async {
    final fn = releaseMatchWait;
    if (fn == null) return;
    try {
      await fn();
    } catch (_) {}
  }
}
