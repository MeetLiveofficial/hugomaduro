import 'package:flutter/material.dart';
import 'package:krimson/common/manager/app_role.dart';
import 'package:krimson/utilities/client_colors.dart';
import 'package:krimson/utilities/streamer_colors.dart';

/// Tokens del rol activo: cliente (`ClientColors`) o streamer (`StreamerColors`).
class RolePalette {
  RolePalette._();

  static bool get _client => AppRole.isClient();

  static Color get primary =>
      _client ? ClientColors.primary : StreamerColors.primary;

  static Color get primaryHover =>
      _client ? ClientColors.primaryHover : StreamerColors.primaryHover;

  static Color get primaryActive =>
      _client ? ClientColors.primaryActive : StreamerColors.primaryActive;

  static Color get secondary =>
      _client ? ClientColors.secondary : StreamerColors.secondary;

  static Color get secondarySoft =>
      _client ? ClientColors.secondarySoft : StreamerColors.secondarySoft;

  static Color get bg => _client ? ClientColors.bg : StreamerColors.bg;

  static Color get surface =>
      _client ? ClientColors.surface : StreamerColors.surface;

  static Color get surfaceAlt =>
      _client ? ClientColors.surfaceAlt : StreamerColors.surfaceAlt;

  static Color get border =>
      _client ? ClientColors.border : StreamerColors.border;

  static Color get text => _client ? ClientColors.text : StreamerColors.text;

  static Color get textMuted =>
      _client ? ClientColors.textMuted : StreamerColors.textMuted;

  static LinearGradient get primaryGradient => _client
      ? ClientColors.primaryGradient
      : StreamerColors.primaryGradient;
}
