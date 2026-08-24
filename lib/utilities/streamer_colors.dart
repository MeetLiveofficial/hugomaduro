import 'package:flutter/material.dart';

/// Paleta corporativa del **Usuario Streamer** (`streamer-50` … `streamer-950`).
///
/// Equivale a `--streamer-50` … `--streamer-950` y `--color-*` en CSS.
class StreamerColors {
  StreamerColors._();

  static const Color streamer50 = Color(0xFFE7FAFE);
  static const Color streamer100 = Color(0xFFBBF1FC);
  static const Color streamer200 = Color(0xFF8FE8FA);
  static const Color streamer300 = Color(0xFF63DFF8);
  static const Color streamer400 = Color(0xFF27D3F5);
  static const Color streamer500 = Color(0xFF0BCDF4);
  static const Color streamer600 = Color(0xFF09A8C8);
  static const Color streamer700 = Color(0xFF07839C);
  static const Color streamer800 = Color(0xFF055E70);
  static const Color streamer900 = Color(0xFF033944);
  static const Color streamer950 = Color(0xFF011418);

  /// Acción principal / marca (`--color-400`).
  static const Color primary = streamer400;

  /// Hover (`--color-500`).
  static const Color primaryHover = streamer500;

  /// Active (`--color-600`).
  static const Color primaryActive = streamer600;

  /// Acentos, badges, progreso (`--color-300`).
  static const Color secondary = streamer300;

  /// Bordes suaves (`--color-200`).
  static const Color secondarySoft = streamer200;

  /// Fondo de pantalla (`--color-950`).
  static const Color bg = streamer950;

  /// Cards / modales (`--color-900`).
  static const Color surface = streamer900;

  /// Superficie elevada (`--color-800`).
  static const Color surfaceAlt = streamer800;

  /// Bordes y divisores (`--color-700`).
  static const Color border = streamer700;

  /// Texto sobre fondo oscuro (`--color-50`).
  static const Color text = streamer50;

  /// Subtítulos (`--color-100`).
  static const Color textMuted = streamer100;

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [streamer400, streamer500, streamer600],
    stops: [0.0, 0.48, 1.0],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient surfaceGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [streamer800, streamer900, streamer950],
  );
}
