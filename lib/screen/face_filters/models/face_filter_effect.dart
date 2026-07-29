import 'package:flutter/material.dart';
import 'package:krimson/model/filter/face_filter_models.dart';
import 'package:krimson/screen/face_filters/widgets/beauty_camera_preview.dart';

/// Built-in interactive face effects / styles (TikTok-style carousel).
enum FaceFilterId {
  none,
  /// GPU beauty looks (fragment shader) — visibles en el carrusel.
  beautySoft,
  beautyNatural,
  beautyPorcelain,
  beautyFresh,
  beautyWarm,
  beautyRose,
  meshDebug,
  glasses,
  dogEars,
  blush,
  mustache,
  sparkleEyes,
  cyberNeon,
  freckles,
  heartEyes,
  catWhiskers,
  softGlow,
}

extension FaceFilterIdX on FaceFilterId {
  String get code => name;

  /// Filtros de belleza facial vía shader GPU (sin overlay MediaPipe).
  bool get isBeautyGpu =>
      this == FaceFilterId.beautySoft ||
      this == FaceFilterId.beautyNatural ||
      this == FaceFilterId.beautyPorcelain ||
      this == FaceFilterId.beautyFresh ||
      this == FaceFilterId.beautyWarm ||
      this == FaceFilterId.beautyRose;

  /// Necesita Face Mesh / CustomPainter AR.
  bool get needsFaceMesh =>
      this != FaceFilterId.none && !isBeautyGpu;

  /// Preset GPU asociado (null = apagar beauty o dejar base suave).
  BeautyLook? get beautyLook {
    switch (this) {
      case FaceFilterId.beautySoft:
        return const BeautyLook(intensity: 0.72, mode: 0);
      case FaceFilterId.beautyNatural:
        return const BeautyLook(intensity: 0.52, mode: 0);
      case FaceFilterId.beautyPorcelain:
        return const BeautyLook(intensity: 0.88, mode: 1);
      case FaceFilterId.beautyFresh:
        return const BeautyLook(intensity: 0.75, mode: 2);
      case FaceFilterId.beautyWarm:
        return const BeautyLook(intensity: 0.80, mode: 3);
      case FaceFilterId.beautyRose:
        return const BeautyLook(intensity: 0.78, mode: 4);
      case FaceFilterId.none:
        return const BeautyLook(intensity: 0, mode: 0);
      default:
        // Filtros AR: base beauty ligera debajo del overlay.
        return const BeautyLook(intensity: 0.35, mode: 0);
    }
  }

  static FaceFilterId? tryParse(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    for (final v in FaceFilterId.values) {
      if (v.name == raw) return v;
    }
    return null;
  }
}

extension RemoteFaceFilterMapping on RemoteFaceFilter {
  FaceFilterId? get localEffectId => FaceFilterIdX.tryParse(code);

  FaceFilterEffect toEffect() {
    final id = localEffectId ?? FaceFilterId.none;
    FaceFilterEffect? builtin;
    for (final e in FaceFilterEffect.catalog) {
      if (e.id == id) {
        builtin = e;
        break;
      }
    }
    return FaceFilterEffect(
      id: id,
      title: title.isNotEmpty ? title : (builtin?.title ?? code),
      icon: builtin?.icon ?? Icons.auto_fix_high,
      accent: accentColor != null
          ? parseAccent(fallback: builtin?.accent ?? const Color(0xFF9E9E9E))
          : (builtin?.accent ?? parseAccent()),
      assetIcon: builtin?.assetIcon,
      remote: this,
    );
  }
}

class FaceFilterEffect {
  const FaceFilterEffect({
    required this.id,
    required this.title,
    required this.icon,
    required this.accent,
    this.assetIcon,
    this.remote,
  });

  final FaceFilterId id;
  final String title;
  final IconData icon;
  final Color accent;
  /// Thumbnail local (p. ej. foto preview de belleza).
  final String? assetIcon;
  /// Datos remotos (premium, URLs, versión) cuando vienen del sync API.
  final RemoteFaceFilter? remote;

  bool get isPremium => remote?.isPremium ?? false;
  int get coinPrice => remote?.coinPrice ?? 0;
  String? get iconUrl => remote?.iconUrl;

  /// Preferir red si hay URL; si no, asset embebido.
  bool get hasPhotoThumb =>
      (iconUrl != null && iconUrl!.isNotEmpty) ||
      (assetIcon != null && assetIcon!.isNotEmpty);

  static const List<FaceFilterEffect> catalog = [
    FaceFilterEffect(
      id: FaceFilterId.none,
      title: 'None',
      icon: Icons.block,
      accent: Color(0xFF9E9E9E),
    ),
    // —— Belleza facial (GPU) ——
    FaceFilterEffect(
      id: FaceFilterId.beautySoft,
      title: 'Soft',
      icon: Icons.face_retouching_natural,
      accent: Color(0xFFFFCCBC),
      assetIcon: 'assets/filters/beauty/beauty_soft.jpg',
    ),
    FaceFilterEffect(
      id: FaceFilterId.beautyNatural,
      title: 'Natural',
      icon: Icons.spa_outlined,
      accent: Color(0xFFA5D6A7),
      assetIcon: 'assets/filters/beauty/beauty_natural.jpg',
    ),
    FaceFilterEffect(
      id: FaceFilterId.beautyPorcelain,
      title: 'Porcelain',
      icon: Icons.brightness_5,
      accent: Color(0xFFF8BBD0),
      assetIcon: 'assets/filters/beauty/beauty_porcelain.jpg',
    ),
    FaceFilterEffect(
      id: FaceFilterId.beautyFresh,
      title: 'Fresh',
      icon: Icons.water_drop_outlined,
      accent: Color(0xFF81D4FA),
      assetIcon: 'assets/filters/beauty/beauty_fresh.jpg',
    ),
    FaceFilterEffect(
      id: FaceFilterId.beautyWarm,
      title: 'Warm',
      icon: Icons.wb_sunny,
      accent: Color(0xFFFFB74D),
      assetIcon: 'assets/filters/beauty/beauty_warm.jpg',
    ),
    FaceFilterEffect(
      id: FaceFilterId.beautyRose,
      title: 'Rose',
      icon: Icons.favorite_border,
      accent: Color(0xFFF48FB1),
      assetIcon: 'assets/filters/beauty/beauty_rose.jpg',
    ),
    // —— AR / fun ——
    FaceFilterEffect(
      id: FaceFilterId.meshDebug,
      title: 'Mesh',
      icon: Icons.grid_on,
      accent: Color(0xFF69F0AE),
    ),
    FaceFilterEffect(
      id: FaceFilterId.glasses,
      title: 'Glasses',
      icon: Icons.visibility,
      accent: Color(0xFF40C4FF),
    ),
    FaceFilterEffect(
      id: FaceFilterId.dogEars,
      title: 'Ears',
      icon: Icons.pets,
      accent: Color(0xFFFFAB40),
    ),
    FaceFilterEffect(
      id: FaceFilterId.blush,
      title: 'Blush',
      icon: Icons.favorite,
      accent: Color(0xFFFF80AB),
    ),
    FaceFilterEffect(
      id: FaceFilterId.mustache,
      title: 'Mustache',
      icon: Icons.face,
      accent: Color(0xFF8D6E63),
    ),
    FaceFilterEffect(
      id: FaceFilterId.sparkleEyes,
      title: 'Sparkle',
      icon: Icons.auto_awesome,
      accent: Color(0xFFFFD740),
    ),
    FaceFilterEffect(
      id: FaceFilterId.cyberNeon,
      title: 'Neon',
      icon: Icons.bolt,
      accent: Color(0xFFE040FB),
    ),
    FaceFilterEffect(
      id: FaceFilterId.freckles,
      title: 'Freckles',
      icon: Icons.grain,
      accent: Color(0xFFD7A86E),
    ),
    FaceFilterEffect(
      id: FaceFilterId.heartEyes,
      title: 'Hearts',
      icon: Icons.favorite_rounded,
      accent: Color(0xFFFF1744),
    ),
    FaceFilterEffect(
      id: FaceFilterId.catWhiskers,
      title: 'Cat',
      icon: Icons.cruelty_free,
      accent: Color(0xFFFF6E40),
    ),
    FaceFilterEffect(
      id: FaceFilterId.softGlow,
      title: 'Glow',
      icon: Icons.wb_sunny_outlined,
      accent: Color(0xFFFFF59D),
    ),
  ];
}

/// Stable MediaPipe Face Mesh landmark indices.
class FaceMeshLandmarkIndex {
  static const int noseTip = 1;
  static const int forehead = 10;
  static const int chin = 152;
  static const int leftEyeOuter = 33;
  static const int leftEyeInner = 133;
  static const int rightEyeOuter = 263;
  static const int rightEyeInner = 362;
  static const int mouthLeft = 61;
  static const int mouthRight = 291;
  static const int upperLip = 13;
  static const int lowerLip = 14;
  static const int leftCheek = 234;
  static const int rightCheek = 454;
  static const int leftIris = 468;
  static const int rightIris = 473;
  static const int leftBrowOuter = 70;
  static const int rightBrowOuter = 300;
}
