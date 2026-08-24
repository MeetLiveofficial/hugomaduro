import 'package:flutter/material.dart';

/// Paleta corporativa del **Usuario Cliente** (`client-50` … `client-950`).
///
/// Equivale a las variables CSS `--client-50` … `--client-950`.
class ClientColors {
  ClientColors._();

  static const Color client50 = Color(0xFFE7F7FE);
  static const Color client100 = Color(0xFFBBE8FC);
  static const Color client200 = Color(0xFF8FDAFA);
  static const Color client300 = Color(0xFF63CBF8);
  static const Color client400 = Color(0xFF27B7F5);
  static const Color client500 = Color(0xFF0BAEF4);
  static const Color client600 = Color(0xFF098FC8);
  static const Color client700 = Color(0xFF076F9C);
  static const Color client800 = Color(0xFF055070);
  static const Color client900 = Color(0xFF033144);
  static const Color client950 = Color(0xFF011118);

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

  /// Fondo de pantalla (`--color-950`).
  static const Color bg = client950;

  /// Cards / modales (`--color-900`).
  static const Color surface = client900;

  /// Superficie elevada (`--color-800`).
  static const Color surfaceAlt = client800;

  /// Bordes y divisores (`--color-700`).
  static const Color border = client700;

  /// Texto sobre fondo oscuro (`--color-50`).
  static const Color text = client50;

  /// Subtítulos (`--color-100`).
  static const Color textMuted = client100;

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [client400, client500, client600],
    stops: [0.0, 0.48, 1.0],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient surfaceGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [client800, client900, client950],
  );
}
