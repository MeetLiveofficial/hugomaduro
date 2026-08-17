import 'dart:ui' as ui show Gradient;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krimson/utilities/color_res.dart';
import 'package:krimson/utilities/theme_res.dart';

class StyleRes {
  /// Logo Meet&Live: Coral → Magenta → Purple.
  static Gradient themeGradient = const LinearGradient(
    colors: [
      ColorRes.themeGradient1,
      ColorRes.themeGradientMid,
      ColorRes.themeGradient2,
    ],
    stops: [0.0, 0.48, 1.0],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static Gradient themeGradientVertical = const LinearGradient(
    colors: [
      ColorRes.themeGradient1,
      ColorRes.themeGradientMid,
      ColorRes.themeGradient2,
    ],
    stops: [0.0, 0.48, 1.0],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  /// Dusk: Magenta → Purple → Deep violet.
  static Gradient duskGradient = const LinearGradient(
    colors: [
      ColorRes.mauve,
      ColorRes.mediumPurple,
      ColorRes.darkPurple,
    ],
    stops: [0.0, 0.5, 1.0],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static Gradient textDarkGreyGradient({double opacity = 1}) {
    final ctx = Get.context;
    final base = ctx != null ? textDarkGrey(ctx) : ColorRes.textDarkGrey;
    return LinearGradient(
      colors: [
        base.withValues(alpha: opacity),
        base.withValues(alpha: opacity),
      ],
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
    );
  }

  static Gradient disabledGreyGradient({double opacity = 1}) => LinearGradient(
        colors: [
          ColorRes.disabledGrey.withValues(alpha: opacity),
          ColorRes.disabledGrey.withValues(alpha: opacity)
        ],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      );

  static Gradient textLightGreyGradient({double opacity = 1}) {
    final ctx = Get.context;
    final base = ctx != null ? textLightGrey(ctx) : ColorRes.textLightGrey;
    return LinearGradient(
      colors: [
        base.withValues(alpha: opacity),
        base.withValues(alpha: opacity),
      ],
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
    );
  }

  static Shader get wavesGradient {
    final width = Get.context != null ? Get.width : 400.0;
    return ui.Gradient.linear(
      const Offset(70, 50),
      Offset(width / 2, 0),
      [
        ColorRes.themeGradient1,
        ColorRes.themeGradientMid,
        ColorRes.themeGradient2,
      ],
      [0.0, 0.48, 1.0],
    );
  }
}
