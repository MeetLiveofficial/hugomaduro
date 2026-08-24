import 'dart:ui' as ui show Gradient;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krimson/common/manager/app_role.dart';
import 'package:krimson/utilities/client_colors.dart';
import 'package:krimson/utilities/color_res.dart';
import 'package:krimson/utilities/theme_res.dart';

class StyleRes {
  static const Gradient _streamerGradient = LinearGradient(
    colors: [
      ColorRes.themeGradient1,
      ColorRes.themeGradientMid,
      ColorRes.themeGradient2,
    ],
    stops: [0.0, 0.48, 1.0],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const Gradient _streamerGradientVertical = LinearGradient(
    colors: [
      ColorRes.themeGradient1,
      ColorRes.themeGradientMid,
      ColorRes.themeGradient2,
    ],
    stops: [0.0, 0.48, 1.0],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  /// Marca coral → magenta (login, splash, streamer). Nunca paleta cliente.
  static const Gradient streamerGradient = _streamerGradient;

  /// Marca sólida: cliente `--color-400`; streamer magenta.
  /// Solo si el usuario logueado es **cliente**.
  static Color get brandAccent =>
      AppRole.isClient() ? ClientColors.primary : ColorRes.crimson;

  /// Streamer: coral → magenta. Cliente (logueado): `client-400` → `client-600`.
  static Gradient get themeGradient =>
      AppRole.isClient() ? ClientColors.primaryGradient : _streamerGradient;

  static Gradient get themeGradientVertical => AppRole.isClient()
      ? ClientColors.primaryGradient
      : _streamerGradientVertical;

  /// Cliente: `--client-400` → `--client-600`.
  static const Gradient clientGradient = ClientColors.primaryGradient;

  static const Gradient clientSurfaceGradient = ClientColors.surfaceGradient;

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
    final colors = AppRole.isClient()
        ? const [
            ClientColors.client400,
            ClientColors.client500,
            ClientColors.client600,
          ]
        : const [
            ColorRes.themeGradient1,
            ColorRes.themeGradientMid,
            ColorRes.themeGradient2,
          ];
    return ui.Gradient.linear(
      const Offset(70, 50),
      Offset(width / 2, 0),
      colors,
      [0.0, 0.48, 1.0],
    );
  }
}
