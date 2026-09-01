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

  /// Dashboard y chrome del **usuario cliente** (cian + texto oscuro legible).
  ///
  /// Importante: `textDarkGrey` / `textLightGrey` / `whitePure` se usan en
  /// pantallas con fondo blanco (chat, sheets). No mapear texto a client-50/100.
  static ThemeData clientTheme(BuildContext context) {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: ClientColors.bg,
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: ClientColors.surface),
      appBarTheme: const AppBarTheme(backgroundColor: ClientColors.bg),
      fontFamily: FontRes.outFitRegular400,
      bottomSheetTheme:
          const BottomSheetThemeData(backgroundColor: ClientColors.surface),
      sliderTheme: const SliderThemeData(
          trackHeight: 2.5,
          trackShape: RectangularSliderTrackShape(),
          overlayShape: RoundSliderOverlayShape(overlayRadius: 0),
          overlayColor: Colors.transparent),
      textTheme: const TextTheme(
        // whitePure(): blanco real (overlays / texto sobre oscuro)
        titleLarge: TextStyle(color: ColorRes.whitePure),
        // textDarkGrey(): texto principal sobre fondos claros
        titleMedium: TextStyle(color: ClientColors.text),
        // textLightGrey(): secundario legible (no cyan pálido)
        titleSmall: TextStyle(color: ClientColors.textMuted),
        // themeAccentSolid(): azul de contraste en textos
        labelSmall: TextStyle(color: ClientColors.accentBlue),
        labelLarge: TextStyle(color: ClientColors.client600),
      ),
      textSelectionTheme: const TextSelectionThemeData(
          selectionColor: ClientColors.client200,
          cursorColor: ClientColors.primaryActive),
      cardTheme: const CardThemeData(color: ClientColors.primaryActive),
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      primaryColor: ClientColors.primary,
      // bgGrey()
      dividerColor: ClientColors.client100,
      // bgMediumGrey()
      cardColor: ClientColors.client50,
      // blackPure()
      primaryColorDark: ClientColors.text,
      // themeColor()
      canvasColor: ClientColors.surfaceDark,
      iconTheme: const IconThemeData(color: ClientColors.text),
      listTileTheme: const ListTileThemeData(
        iconColor: ClientColors.text,
        textColor: ClientColors.text,
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: ClientColors.surfaceDark,
        titleTextStyle: TextStyle(
          color: ClientColors.textOnDark,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          fontFamily: FontRes.outFitRegular400,
        ),
        contentTextStyle: TextStyle(
          color: ClientColors.textOnDarkMuted,
          fontSize: 15,
          fontFamily: FontRes.outFitRegular400,
        ),
      ),
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
