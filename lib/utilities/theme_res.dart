import 'package:flutter/material.dart';
import 'package:krimson/common/manager/app_role.dart';
import 'package:krimson/utilities/client_colors.dart';
import 'package:krimson/utilities/color_res.dart';
import 'package:krimson/utilities/font_res.dart';
import 'package:krimson/utilities/streamer_colors.dart';

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

  /// Dashboard y chrome del **usuario cliente** (`client-50` … `client-950`).
  static ThemeData clientTheme(BuildContext context) {
    return ThemeData(
      brightness: Brightness.dark,
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

  /// Dashboard y chrome del **usuario streamer** (`streamer-50` … `streamer-950`).
  static ThemeData streamerTheme(BuildContext context) {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: StreamerColors.bg,
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: StreamerColors.surface),
      appBarTheme: const AppBarTheme(backgroundColor: StreamerColors.surface),
      fontFamily: FontRes.outFitRegular400,
      bottomSheetTheme:
          const BottomSheetThemeData(backgroundColor: StreamerColors.surface),
      sliderTheme: const SliderThemeData(
          trackHeight: 2.5,
          trackShape: RectangularSliderTrackShape(),
          overlayShape: RoundSliderOverlayShape(overlayRadius: 0),
          overlayColor: Colors.transparent),
      textTheme: const TextTheme(
        titleLarge: TextStyle(color: StreamerColors.text),
        titleMedium: TextStyle(color: StreamerColors.text),
        titleSmall: TextStyle(color: StreamerColors.textMuted),
        labelSmall: TextStyle(color: StreamerColors.primary),
        labelLarge: TextStyle(color: ColorRes.disabledGrey),
      ),
      textSelectionTheme:
          const TextSelectionThemeData(selectionColor: StreamerColors.border),
      cardTheme: const CardThemeData(color: StreamerColors.surfaceAlt),
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      primaryColor: StreamerColors.primary,
      dividerColor: StreamerColors.border,
      cardColor: StreamerColors.surfaceAlt,
      primaryColorDark: StreamerColors.text,
      canvasColor: StreamerColors.bg,
      useMaterial3: false,
    );
  }

  static ThemeData roleTheme(BuildContext context) {
    return AppRole.isClient() ? clientTheme(context) : streamerTheme(context);
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
