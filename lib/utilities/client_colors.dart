import 'package:flutter/material.dart';

/// Paleta corporativa del **Usuario Cliente** (`client-50` … `client-950`).
///
/// Equivale a `--color-*` / `--client-*` (Tailwind-scale). No usar en streamers.
///
/// | Token | Hex | Uso |
/// |---|---|---|
/// | 400 | `#27D3F5` | Primario (CTA, marca) |
/// | 500 / 600 | `#0BCDF4` / `#09A8C8` | Hover / active |
/// | 300 / 200 | `#63DFF8` / `#8FE8FA` | Acentos, badges, bordes |
/// | 950 / 900 / 800 | `#011418` / `#033944` / `#055E70` | Texto fuerte, modales oscuros, cards |
/// | 700 | `#07839C` | Texto secundario legible sobre claro |
/// | 50 / 100 | `#E7FAFE` / `#BBF1FC` | Fondos claros / chips (NO texto sobre blanco) |
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

  /// Azul de contraste para textos e iconos de nav (`#3a83f3`).
  static const Color accentBlue = Color(0xFF3A83F3);

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

  /// Fondo de pantalla (antes blanco/cian claro).
  static const Color bg = Color(0xFF2A2A32);

  /// Cards / modales claros.
  static const Color surface = Color(0xFFFFFFFF);

  /// Superficie elevada / chips claros.
  static const Color surfaceAlt = client100;

  /// Bordes y divisores.
  static const Color border = client200;

  /// Texto principal sobre el fondo de pantalla `#2a2a32`.
  static const Color text = Color(0xFFFFFFFF);

  /// Texto sobre cards / sheets blancos.
  static const Color textOnSurface = client950;

  /// Subtítulos / timestamps (azul de contraste).
  static const Color textMuted = accentBlue;

  /// Texto sobre fondos oscuros (LIVE, chips teal, media).
  static const Color textOnDark = client50;

  /// Subtítulo sobre fondos oscuros.
  static const Color textOnDarkMuted = client100;

  /// Superficie oscura (header Match, badges).
  static const Color surfaceDark = client900;

  /// Chip / pill oscuro.
  static const Color surfaceDarkAlt = client800;

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [client400, client500, client600],
    stops: [0.0, 0.48, 1.0],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient surfaceGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF2A2A32), Color(0xFF2A2A32), Color(0xFF2A2A32)],
  );
}
