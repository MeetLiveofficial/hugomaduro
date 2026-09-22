import 'package:flutter/material.dart';

/// Paleta del **Usuario Cliente** — navy neón (mockups Meet&Live).
///
/// No usar en streamers. Escala `client-50` … `client-950` se mantiene
/// para acentos cian; fondos y superficies son navy oscuro.
class ClientColors {
  ClientColors._();

  static const Color client50 = Color(0xFFE7FAFE);
  static const Color client100 = Color(0xFFBBF1FC);
  static const Color client200 = Color(0xFF8FE8FA);
  static const Color client300 = Color(0xFF63DFF8);
  static const Color client400 = Color(0xFF27D3F5);
  static const Color client500 = Color(0xFF0BCDF4);
  static const Color client600 = Color(0xFF09A8C8);
  static const Color client700 = Color(0xFF07839C);
  static const Color client800 = Color(0xFF055E70);
  static const Color client900 = Color(0xFF033944);
  static const Color client950 = Color(0xFF011418);

  /// Azul de contraste (`#3a83f3`).
  static const Color accentBlue = Color(0xFF3A83F3);

  /// Magenta de títulos / Goddess / PLUS.
  static const Color magenta = Color(0xFFC084FC);
  static const Color magentaHot = Color(0xFFE879F9);
  static const Color violet = Color(0xFF7C3AED);

  /// Oro de monedas / podio.
  static const Color gold = Color(0xFFFBBF24);

  /// Toggle ON (notificaciones).
  static const Color toggleOn = Color(0xFF2DD4BF);

  /// Acción principal / marca (`--color-400`).
  static const Color primary = client400;

  /// Hover (`--color-500`).
  static const Color primaryHover = client500;

  /// Active (`--color-600`).
  static const Color primaryActive = client600;

  /// Acentos, badges, progreso (`--color-300`).
  static const Color secondary = client300;

  /// Bordes suaves (`--color-200`).
  static const Color secondarySoft = client200;

  /// Fondo de pantalla navy (mockups).
  static const Color bg = Color(0xFF07101C);

  /// Fondo intermedio / wash.
  static const Color bgMid = Color(0xFF0A1630);

  /// Cards / sheets oscuros.
  static const Color surface = Color(0xFF0C1A32);

  /// Superficie elevada / chips.
  static const Color surfaceAlt = Color(0xFF0E2240);

  /// Bordes glow.
  static const Color border = Color(0x6627D3F5);

  /// Texto principal sobre navy.
  static const Color text = Color(0xFFFFFFFF);

  /// Texto sobre cards (mismo navy oscuro).
  static const Color textOnSurface = Color(0xFFFFFFFF);

  /// Subtítulos / timestamps.
  static const Color textMuted = Color(0xB3FFFFFF);

  /// Texto sobre fondos oscuros (LIVE, chips, media).
  static const Color textOnDark = Color(0xFFF5FDFF);

  /// Subtítulo sobre fondos oscuros.
  static const Color textOnDarkMuted = Color(0xB3BBF1FC);

  /// Superficie oscura (header Match, badges).
  static const Color surfaceDark = Color(0xFF050B18);

  /// Chip / pill oscuro.
  static const Color surfaceDarkAlt = Color(0xFF102038);

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [client400, client500, client600],
    stops: [0.0, 0.48, 1.0],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Títulos de AppBar: cian → magenta.
  static const LinearGradient titleGradient = LinearGradient(
    colors: [Color(0xFF5CE1FF), Color(0xFFC084FC)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  /// CTA Save / Link Now: cian → violeta.
  static const LinearGradient ctaGradient = LinearGradient(
    colors: [Color(0xFF27D3F5), Color(0xFF7C3AED)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient surfaceGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF0A1630), Color(0xFF07101C), Color(0xFF050B18)],
  );

  static List<BoxShadow> neonGlow({
    Color? color,
    double alpha = 0.38,
    double blur = 16,
    Offset offset = const Offset(0, 4),
  }) {
    return [
      BoxShadow(
        color: (color ?? primary).withValues(alpha: alpha),
        blurRadius: blur,
        offset: offset,
      ),
    ];
  }

  static BoxDecoration glass({
    bool highlighted = false,
    Color? glowColor,
    double radius = 16,
  }) {
    final glow = glowColor ?? (highlighted ? magenta : primary);
    return BoxDecoration(
      color: highlighted ? null : surface.withValues(alpha: 0.92),
      gradient: highlighted
          ? const LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [Color(0xFF143A68), Color(0xFF4C2A7A)],
            )
          : null,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: glow.withValues(alpha: highlighted ? 0.95 : 0.55),
        width: highlighted ? 1.5 : 1.15,
      ),
      boxShadow: neonGlow(
        color: glow,
        alpha: highlighted ? 0.5 : 0.28,
        blur: highlighted ? 20 : 14,
      ),
    );
  }
}
