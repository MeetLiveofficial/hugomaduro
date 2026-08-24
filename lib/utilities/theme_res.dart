import 'package:flutter/material.dart';
import 'package:krimson/common/manager/app_role.dart';
import 'package:krimson/utilities/client_colors.dart';
import 'package:krimson/utilities/color_res.dart';
import 'package:krimson/utilities/font_res.dart';

class ThemeRes {
  /// Theme light mode

  static ThemeData lightTheme(BuildContext context) {
    return ThemeData(
      scaffoldBackgroundColor: ColorRes.bgLightGrey,
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: ColorRes.whitePure),
      appBarTheme: const AppBarTheme(backgroundColor: ColorRes.bgLightGrey),
      fontFamily: FontRes.outFitRegular400,
      bottomSheetTheme:
          const BottomSheetThemeData(backgroundColor: ColorRes.whitePure),
      sliderTheme: const SliderThemeData(
          trackHeight: 2.5,
          trackShape: RectangularSliderTrackShape(),
          overlayShape: RoundSliderOverlayShape(overlayRadius: 0),
          overlayColor: Colors.transparent),
      textTheme: const TextTheme(
        titleLarge: TextStyle(color: ColorRes.whitePure),
        titleMedium: TextStyle(color: ColorRes.textDarkGrey),
        titleSmall: TextStyle(color: ColorRes.textLightGrey),
        labelSmall: TextStyle(color: ColorRes.themeAccentSolid),
        labelLarge: TextStyle(color: ColorRes.disabledGrey),
      ),
      textSelectionTheme:
          const TextSelectionThemeData(selectionColor: ColorRes.disabledGrey),
      cardTheme: const CardThemeData(color: ColorRes.blueFollow),
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      primaryColor: ColorRes.themeAccentSolid,
      dividerColor: ColorRes.bgGrey,
      cardColor: ColorRes.bgMediumGrey,
      primaryColorDark: ColorRes.blackPure,
      canvasColor: ColorRes.themeColor,
      useMaterial3: false,
    );
  }

  /// Theme dark mode

  static ThemeData darkTheme(BuildContext context) {
    return ThemeData();
  }

  /// Dashboard y chrome del **usuario cliente** (cian/turquesa `client-50` … `client-950`).
  static ThemeData clientTheme(BuildContext context) {
    return ThemeData(
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: ClientColors.primary,
        onPrimary: ClientColors.text,
        secondary: ClientColors.secondary,
        onSecondary: ClientColors.bg,
        surface: ClientColors.surface,
        onSurface: ClientColors.text,
      ),
      scaffoldBackgroundColor: ClientColors.bg,
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: ClientColors.surface),
      appBarTheme: const AppBarTheme(backgroundColor: ClientColors.surface),
      fontFamily: FontRes.outFitRegular400,
      bottomSheetTheme:
          const BottomSheetThemeData(backgroundColor: ClientColors.surface),
      sliderTheme: const SliderThemeData(
          trackHeight: 2.5,
          trackShape: RectangularSliderTrackShape(),
          overlayShape: RoundSliderOverlayShape(overlayRadius: 0),
          overlayColor: Colors.transparent),
      textTheme: const TextTheme(
        titleLarge: TextStyle(color: ClientColors.text),
        titleMedium: TextStyle(color: ClientColors.text),
        titleSmall: TextStyle(color: ClientColors.textMuted),
        labelSmall: TextStyle(color: ClientColors.primary),
        labelLarge: TextStyle(color: ColorRes.disabledGrey),
      ),
      textSelectionTheme:
          const TextSelectionThemeData(selectionColor: ClientColors.border),
      cardTheme: const CardThemeData(color: ClientColors.surfaceAlt),
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      primaryColor: ClientColors.primary,
      dividerColor: ClientColors.border,
      cardColor: ClientColors.surfaceAlt,
      primaryColorDark: ClientColors.text,
      canvasColor: ClientColors.bg,
      useMaterial3: false,
    );
  }

  /// Aplica [clientTheme] solo si el usuario es cliente.
  static Widget applyIfClient(BuildContext context, Widget child) {
    if (!AppRole.isClient()) return child;
    return Theme(data: clientTheme(context), child: child);
  }
}

Color whitePure(BuildContext context) {
  return Theme.of(context).textTheme.titleLarge?.color ?? ColorRes.whitePure;
}

Color textDarkGrey(BuildContext context) {
  return Theme.of(context).textTheme.titleMedium?.color ?? ColorRes.textDarkGrey;
}

Color textLightGrey(BuildContext context) {
  return Theme.of(context).textTheme.titleSmall?.color ??
      ColorRes.textLightGrey;
}

Color bgGrey(BuildContext context) {
  return Theme.of(context).dividerColor;
}

Color themeAccentSolid(BuildContext context) {
  return Theme.of(context).textTheme.labelSmall?.color ??
      ColorRes.themeAccentSolid;
}

Color disableGrey(BuildContext context) {
  return Theme.of(context).textTheme.labelLarge?.color ?? ColorRes.disabledGrey;
}

Color scaffoldBackgroundColor(BuildContext context) {
  return Theme.of(context).scaffoldBackgroundColor;
}

Color blueFollow(BuildContext context) {
  return Theme.of(context).cardTheme.color ?? ColorRes.blueFollow;
}

Color bgMediumGrey(BuildContext context) {
  return Theme.of(context).cardColor;
}

Color blackPure(BuildContext context) {
  return Theme.of(context).primaryColorDark;
}

Color bgLightGrey(BuildContext context) {
  return Theme.of(context).appBarTheme.backgroundColor ?? ColorRes.bgLightGrey;
}

Color themeColor(BuildContext context) {
  return Theme.of(context).canvasColor;
}
