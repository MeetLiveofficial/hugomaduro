import 'package:flutter/material.dart';
import 'package:krimson/common/extensions/string_extension.dart';
import 'package:krimson/common/widget/custom_image.dart';
import 'package:krimson/common/widget/gift_media.dart';
import 'package:krimson/common/widget/shine_sweep.dart';
import 'package:krimson/model/user_model/user_model.dart';
import 'package:krimson/utilities/asset_res.dart';
import 'package:krimson/utilities/color_res.dart';
import 'package:krimson/utilities/style_res.dart';
import 'package:krimson/utilities/text_style_custom.dart';

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
    this.gradeLabel,
    this.compact = false,
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
    String? gradeLabel,
    bool compact = false,
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
      gradeLabel: gradeLabel,
      compact: compact,
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
    bool compact = false,
  }) {
    final dressing = (user.equippedFrameImage ?? '').trim();
    final badge = (user.equippedBadgeImage ?? '').trim();
    final isStreamer = (user.appRole ?? '').toLowerCase() == 'streamer';
    final isClient = (user.appRole ?? '').toLowerCase() == 'client';
    final localFrame = dressing.isEmpty
        ? (isStreamer
            ? AssetRes.streamerBadgeForGrade(user.effectiveStreamerGrade)
            : isClient
                ? AssetRes.clientFrameForLevel(user.levelNumber ?? 1)
                : null)
        : null;
    final surround = dressing.isNotEmpty ? dressing : '';
    final cornerBadge = dressing.isNotEmpty ? badge : '';
    if (surround.isNotEmpty || (localFrame ?? '').isNotEmpty) {
      final gradeKey = (user.equippedFrame?['unlock_grade'] ??
              user.effectiveStreamerGrade)
          ?.toString();
      final slug = user.equippedFrame?['slug']?.toString() ?? '';
      final isGradeFrame = isStreamer &&
          (localFrame != null ||
              (user.equippedFrame?['unlock_grade']
                      ?.toString()
                      .trim()
                      .isNotEmpty ??
                  false) ||
              slug.startsWith('streamer_'));
      final isClientFrame = isClient &&
          (slug.startsWith('client_frame_') || localFrame != null);
      final ratio = isGradeFrame
          ? AssetRes.streamerBadgePhotoRatio(gradeKey)
          : isClientFrame
              ? (user.equippedFrame?['photo_ratio'] is num
                  ? (user.equippedFrame!['photo_ratio'] as num).toDouble()
                  : AssetRes.clientFramePhotoRatio(user.levelNumber ?? 1))
              : user.framePhotoRatio;
      final totalSize = compact ? 96.0 : size.clamp(80.0, 128.0);
      return FramedAvatar.fitted(
        key: key,
        size: totalSize,
        image: user.profilePhoto,
        fullName: user.fullname ?? user.username,
        frameImage: surround.isEmpty ? null : surround,
        localFrame: localFrame,
        badgeImage: (isGradeFrame || isClientFrame)
            ? null
            : (cornerBadge.isEmpty ? null : cornerBadge),
        onTap: onTap,
        glowColor: glowColor,
        photoRatio: ratio,
        photoOffset: isGradeFrame
            ? AssetRes.streamerBadgePhotoOffset(gradeKey, outer: totalSize)
            : Offset.zero,
        photoOnTop: false,
        compact: compact,
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
  final String? gradeLabel;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final networkFrame = (frameImage ?? '').trim();
    final assetFrame = (localFrame ?? '').trim();
    final badge = (badgeImage ?? '').trim();
    final hasChrome = networkFrame.isNotEmpty || assetFrame.isNotEmpty;
    final extra = hasChrome ? size * frameExtra : 0.0;
    final outer = size + extra * 2;

    Widget photo = _fillPhoto(
      size: size,
      imageUrl: (image ?? '').addBaseURL(),
      fullName: fullName,
      framed: hasChrome,
      strokeWidth: hasChrome ? 0 : strokeWidth,
      strokeColor: strokeColor,
    );

    if (!hasChrome && ring != null) {
      photo = ring!(photo);
    }

    if (hasChrome) {
      photo = Transform.scale(scale: 1.12, child: photo);
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

    final grade = (gradeLabel ?? '').trim();

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
          children: [
            ...stackChildren,
            if (grade.isNotEmpty)
              Positioned(
                bottom: extra * 0.35,
                child: IgnorePointer(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
                    decoration: BoxDecoration(
                      gradient: StyleRes.themeGradient,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white, width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: ColorRes.crimson.withValues(alpha: 0.4),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      grade,
                      style: TextStyleCustom.outFitSemiBold600(
                        color: ColorRes.whitePure,
                        fontSize: 9,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _fillPhoto({
    required double size,
    required String imageUrl,
    String? fullName,
    required bool framed,
    required double strokeWidth,
    Color? strokeColor,
  }) {
    if (imageUrl.trim().isEmpty) {
      return CustomImage(
        size: Size(size, size),
        image: imageUrl,
        fullName: fullName,
        radius: size / 2,
        strokeWidth: framed ? 0 : strokeWidth,
        strokeColor: strokeColor,
        fit: BoxFit.cover,
      );
    }

    return ClipOval(
      clipBehavior: Clip.hardEdge,
      child: SizedBox(
        width: size,
        height: size,
        child: Image.network(
          imageUrl,
          width: size,
          height: size,
          fit: BoxFit.cover,
          alignment: Alignment.center,
          gaplessPlayback: true,
          filterQuality: FilterQuality.medium,
          webHtmlElementStrategy: WebHtmlElementStrategy.never,
          errorBuilder: (_, __, ___) => CustomImage(
            size: Size(size, size),
            image: imageUrl,
            fullName: fullName,
            radius: size / 2,
            strokeWidth: 0,
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}
