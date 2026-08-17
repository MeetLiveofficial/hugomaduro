import 'package:flutter/material.dart';

/// Meet&Live — paleta oficial ([meetlive.online](https://meetlive.online/) + logo).
///
/// Coral `#FE5A59` · Magenta `#E24AB7` · Purple `#B140D8` · Rose `#F9A8D4`
/// Fondos: Obsidian `#0F0F12` · Carbon `#1A1A1F`
class ColorRes {
  static const Color blackPure = Color(0xFF000000);
  static const Color whitePure = Color(0xFFFFFFFF);

  // ── Tokens web ─────────────────────────────────────────────────
  static const Color crimson = Color(0xFFE24AB7);
  static const Color crimsonAlt = Color(0xFFFE5A59);
  static const Color mlPurple = Color(0xFFB140D8);
  static const Color roseMuted = Color(0xFFF9A8D4);
  static const Color roseBorder = Color(0xFFF456AA);
  static const Color obsidian = Color(0xFF0F0F12);
  static const Color obsidianDeep = Color(0xFF09090B);
  static const Color carbon = Color(0xFF1A1A1F);
  static const Color dtText = Color(0xFFF5E9F2);

  // ── Board (nombres legacy → tokens vivos) ──────────────────────
  static const Color softSalmon = Color(0xFFFF7A9C);
  static const Color coralRed = crimsonAlt;
  static const Color mauve = crimson;
  static const Color accentRose = roseMuted;
  static const Color accentPeach = Color(0xFFFFC2D4);
  static const Color mediumPurple = mlPurple;
  static const Color darkPurple = Color(0xFF7A22A8);

  static const Color brandCoral = coralRed;
  static const Color brandPink = crimson;
  static const Color brandMagenta = crimson;
  static const Color brandViolet = mediumPurple;
  static const Color brandDeep = darkPurple;
  static const Color brandSoft = accentRose;

  /// Fondos dusk con tinte magenta (sin gris apagado).
  static const Color bgVoid = Color(0xFF160E18);
  static const Color bgElevated = Color(0xFF1E1422);
  static const Color bgCard = Color(0xFF261A2C);
  static const Color bgSoft = Color(0xFF322038);

  /// Menús / selects: superficie clara (texto oscuro).
  static const Color menuSurface = Color(0xFFFFFFFF);
  static const Color menuSurfaceElevated = Color(0xFFFFFFFF);
  static const Color menuBorder = Color(0x33E24AB7);
  static const Color menuSelected = Color(0xFFFFE8F5);

  static const Color streamerSalmon = softSalmon;
  static const Color streamerCoral = coralRed;
  static const Color streamerMauve = mauve;
  static const Color streamerPink = accentRose;
  static const Color streamerPeach = accentPeach;
  static const Color streamerLavender = mediumPurple;
  static const Color streamerPurple = darkPurple;

  static const Color clientMagenta = mauve;
  static const Color clientIndigo = darkPurple;
  static const Color clientTeal = accentRose;
  static const Color clientRoyal = mediumPurple;
  static const Color clientFuchsia = accentRose;

  static const Color baseCoral = coralRed;
  static const Color baseLavender = mediumPurple;
  static const Color baseRaspberry = accentRose;
  static const Color basePeach = accentPeach;
  static const Color baseCream = Color(0xFFFFE4F0);

  static const Color accentIndigo = darkPurple;
  static const Color accentPurple = mauve;
  static const Color accentBurntRed = coralRed;
  static const Color accentOrange = softSalmon;
  static const Color accentGold = accentPeach;

  /// Logo: Coral → Magenta → Purple.
  static const Color themeGradient1 = crimsonAlt;
  static const Color themeGradientMid = crimson;
  static const Color themeGradient2 = mlPurple;

  static const Color clientGradient1 = crimson;
  static const Color clientGradientMid = mlPurple;
  static const Color clientGradient2 = darkPurple;

  static const Color themeAccentSolid = crimson;

  static const Color themeColor = bgVoid;
  static const Color obsidianNavy = bgVoid;
  static const Color surfaceDeep = bgElevated;

  static const Color textDarkGrey = Color(0xFF1C1218);
  static const Color textLightGrey = Color(0xFF6B5360);
  static const Color orange = softSalmon;
  static const Color green = Color(0xFF34D399);
  static const Color green1 = Color(0xFF34D948);
  static const Color likeRed = Color(0xFFFE5A59);
  static const Color textStoryBgGradient2 = accentRose;
  static const Color blueFollow = mauve;
  static const Color battleProgressColor = mauve;

  static const Color bgLightGrey = Color(0xFFFFD6EC);
  static const Color bgGrey = Color(0xFFF5C6E4);
  static const Color bgMediumGrey = Color(0xFFFFEAF5);
  static const Color disabledGrey = Color(0xFFC4B0BC);

  /// Iconos de la barra inferior (uno por tab).
  static const Color navHome = crimson;
  static const Color navExplore = mlPurple;
  static const Color navLive = crimsonAlt;
  static const Color navChat = roseBorder;
  static const Color navProfile = darkPurple;

  static const List<Color> navIconColors = [
    navHome,
    navExplore,
    navLive,
    navChat,
    navProfile,
  ];
}
