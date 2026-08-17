import 'package:flutter/material.dart';
import 'package:krimson/model/general/settings_model.dart';
import 'package:krimson/model/user_model/user_model.dart';
import 'package:krimson/utilities/color_res.dart';

/// Contorno del avatar según nivel (Warm Sunrise → Dusk Violet).
class LevelAvatarStyle {
  LevelAvatarStyle._();

  static int levelOf(User? user) {
    if (user == null) return 1;
    return user.levelNumber ??
        user.getLevel.level ??
        1;
  }

  static bool isSvip(User? user) {
    if (user == null) return false;
    final lvl = user.getLevel;
    return lvl.isSvipLevel == 1;
  }

  static bool isVip(User? user) => user?.isVipActive == true;

  /// Gradiente del anillo por nivel.
  static LinearGradient ringGradient(int level, {bool svip = false, bool vip = false}) {
    if (vip) {
      return const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFFFFE082),
          Color(0xFFFFC107),
          Color(0xFFFF8F00),
        ],
      );
    }
    if (svip || level >= 10) {
      return const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          ColorRes.accentPeach,
          ColorRes.coralRed,
          ColorRes.mauve,
        ],
      );
    }
    if (level >= 8) {
      return const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [ColorRes.mauve, ColorRes.darkPurple],
      );
    }
    if (level >= 6) {
      return const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [ColorRes.accentRose, ColorRes.mauve],
      );
    }
    if (level >= 4) {
      return const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [ColorRes.softSalmon, ColorRes.coralRed],
      );
    }
    if (level >= 2) {
      return const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [ColorRes.accentPeach, ColorRes.softSalmon],
      );
    }
    return const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFD4CBD0), Color(0xFFB8AFA8)],
    );
  }

  static LinearGradient forUser(User? user) {
    return ringGradient(levelOf(user), svip: isSvip(user), vip: isVip(user));
  }

  static LinearGradient forUserLevel(UserLevel? level) {
    final n = level?.level ?? 1;
    return ringGradient(n, svip: level?.isSvipLevel == 1);
  }
}

/// Avatar circular con anillo de nivel.
class LevelAvatarRing extends StatelessWidget {
  final User? user;
  final Widget child;
  final double padding;
  final double? size;

  const LevelAvatarRing({
    super.key,
    required this.user,
    required this.child,
    this.padding = 3,
    this.size,
  });

  @override
  Widget build(BuildContext context) {
    final ring = Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LevelAvatarStyle.forUser(user),
        boxShadow: [
          BoxShadow(
            color: LevelAvatarStyle.forUser(user)
                .colors
                .last
                .withValues(alpha: 0.35),
            blurRadius: 10,
            spreadRadius: 0.5,
          ),
        ],
      ),
      child: child,
    );
    if (size == null) return ring;
    return SizedBox(width: size, height: size, child: ring);
  }
}
