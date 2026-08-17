import 'package:flutter/material.dart';
import 'package:krimson/common/extensions/string_extension.dart';
import 'package:krimson/common/widget/custom_image.dart';
import 'package:krimson/common/widget/gift_media.dart';
import 'package:krimson/common/widget/shine_sweep.dart';
import 'package:krimson/model/user_model/user_model.dart';
import 'package:krimson/utilities/asset_res.dart';

/// Foto circular + marco/insignia del Dressing Center alrededor.
///
/// El PNG del admin (Bronce, Plata, Oro, SVIP…) se pinta alrededor; la foto
/// queda en el hueco. Si el PNG trae el centro opaco, la foto va encima.
class FramedAvatar extends StatelessWidget {
  const FramedAvatar({
    super.key,
    required this.size,
    this.image,
    this.fullName,
    this.frameImage,
    this.localFrame,
    this.badgeImage,
    this.onTap,
    this.strokeWidth = 0,
    this.strokeColor,
    this.ring,
    this.glowColor,
    this.frameExtra = 0.22,
    this.photoOffset = Offset.zero,
    this.photoOnTop = true,
  });

  /// [size] = diámetro total (marco incluido).
  factory FramedAvatar.fitted({
    Key? key,
    required double size,
    String? image,
    String? fullName,
    String? frameImage,
    String? localFrame,
    String? badgeImage,
    VoidCallback? onTap,
    Color? glowColor,
    double photoRatio = 0.62,
    Offset photoOffset = Offset.zero,
    bool photoOnTop = true,
  }) {
    final photoSize = size * photoRatio;
    final extra = (size - photoSize) / 2;
    final frameExtra = photoSize > 0 ? extra / photoSize : 0.22;
    return FramedAvatar(
      key: key,
      size: photoSize,
      image: image,
      fullName: fullName,
      frameImage: frameImage,
      localFrame: localFrame,
      badgeImage: badgeImage,
      onTap: onTap,
      glowColor: glowColor,
      frameExtra: frameExtra,
      photoOffset: photoOffset,
      photoOnTop: photoOnTop,
    );
  }

  factory FramedAvatar.fromUser(
    User user, {
    Key? key,
    required double size,
    VoidCallback? onTap,
    double strokeWidth = 0,
    Color? strokeColor,
    Widget Function(Widget child)? ring,
    Color? glowColor,
  }) {
    final dressing = (user.equippedFrameImage ?? '').trim();
    final badge = (user.equippedBadgeImage ?? '').trim();
    final localGrade = dressing.isEmpty
        ? AssetRes.streamerBadgeForGrade(user.effectiveStreamerGrade)
        : null;
    final surround = dressing.isNotEmpty ? dressing : '';
    final cornerBadge = dressing.isNotEmpty ? badge : '';
    if (surround.isNotEmpty || (localGrade ?? '').isNotEmpty) {
      final gradeKey = (user.equippedFrame?['unlock_grade'] ??
              user.effectiveStreamerGrade)
          ?.toString();
      final isGradeFrame = localGrade != null ||
          (user.equippedFrame?['unlock_grade']
                  ?.toString()
                  .trim()
                  .isNotEmpty ??
              false) ||
          (user.equippedFrame?['slug']?.toString().startsWith('streamer_') ??
              false);
      final ratio = isGradeFrame
          ? AssetRes.streamerBadgePhotoRatio(gradeKey)
          : user.framePhotoRatio;
      // size = diámetro total del widget (alas incluidas). No inflar.
      final totalSize = size > 96 ? 88.0 : size;
      return FramedAvatar.fitted(
        key: key,
        size: totalSize,
        image: user.profilePhoto,
        fullName: user.fullname ?? user.username,
        frameImage: surround.isEmpty ? null : surround,
        localFrame: localGrade,
        badgeImage: cornerBadge.isEmpty ? null : cornerBadge,
        onTap: onTap,
        glowColor: glowColor,
        photoRatio: ratio,
        photoOnTop: false,
      );
    }
    return FramedAvatar(
      key: key,
      size: size > 90 ? 72 : size,
      image: user.profilePhoto,
      fullName: user.fullname ?? user.username,
      onTap: onTap,
      strokeWidth: strokeWidth,
      strokeColor: strokeColor,
      ring: ring,
    );
  }

  static String rankAssetForPlace(int place) {
    switch (place) {
      case 1:
        return AssetRes.icRankFrame1;
      case 2:
        return AssetRes.icRankFrame2;
      case 3:
        return AssetRes.icRankFrame3;
      default:
        return AssetRes.icRankFrame2;
    }
  }

  /// Diámetro de la foto (el marco crece [frameExtra] a cada lado).
  final double size;
  final String? image;
  final String? fullName;
  final String? frameImage;
  final String? localFrame;
  final String? badgeImage;
  final VoidCallback? onTap;
  final double strokeWidth;
  final Color? strokeColor;
  final Widget Function(Widget child)? ring;
  final Color? glowColor;
  final double frameExtra;
  final Offset photoOffset;
  final bool photoOnTop;

  @override
  Widget build(BuildContext context) {
    final networkFrame = (frameImage ?? '').trim();
    final assetFrame = (localFrame ?? '').trim();
    final badge = (badgeImage ?? '').trim();
    final hasChrome = networkFrame.isNotEmpty || assetFrame.isNotEmpty;
    final extra = hasChrome ? size * frameExtra : 0.0;
    final outer = size + extra * 2;

    Widget photo = CustomImage(
      size: Size(size, size),
      image: (image ?? '').addBaseURL(),
      fullName: fullName,
      radius: size / 2,
      strokeWidth: hasChrome ? 0 : strokeWidth,
      strokeColor: strokeColor,
      fit: BoxFit.cover,
    );

    if (hasChrome) {
      photo = ClipOval(child: photo);
    }

    if (!hasChrome && ring != null) {
      photo = ring!(photo);
    }

    if (photoOffset != Offset.zero) {
      photo = Transform.translate(offset: photoOffset, child: photo);
    }

    Widget? chrome;
    if (networkFrame.isNotEmpty) {
      chrome = IgnorePointer(
        child: ShineSweep.masked(
          child: GiftMedia(
            path: networkFrame,
            width: outer,
            height: outer,
            fit: BoxFit.contain,
            placeholder: const SizedBox.shrink(),
          ),
        ),
      );
    } else if (assetFrame.isNotEmpty) {
      chrome = IgnorePointer(
        child: ShineSweep.masked(
          child: Image.asset(
            assetFrame,
            width: outer,
            height: outer,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
            gaplessPlayback: true,
            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
          ),
        ),
      );
    }

    final stackChildren = <Widget>[
      if (hasChrome && glowColor != null)
        IgnorePointer(
          child: Container(
            width: outer * 1.2,
            height: outer * 0.4,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(outer),
              boxShadow: [
                BoxShadow(
                  color: glowColor!.withValues(alpha: 0.45),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
        ),
    ];

    if (chrome != null && photoOnTop) {
      stackChildren.add(chrome);
      stackChildren.add(photo);
    } else {
      stackChildren.add(photo);
      if (chrome != null) stackChildren.add(chrome);
    }

    if (badge.isNotEmpty) {
      stackChildren.add(
        Positioned(
          right: outer * 0.02,
          bottom: outer * 0.08,
          child: IgnorePointer(
            child: GiftMedia(
              path: badge,
              width: outer * 0.22,
              height: outer * 0.22,
              fit: BoxFit.contain,
              placeholder: const SizedBox.shrink(),
            ),
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: outer,
        height: outer,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: stackChildren,
        ),
      ),
    );
  }
}
