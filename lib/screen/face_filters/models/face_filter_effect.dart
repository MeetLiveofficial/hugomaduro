import 'package:flutter/material.dart';
import 'package:krimson/model/filter/face_filter_models.dart';
import 'package:krimson/screen/face_filters/widgets/beauty_camera_preview.dart';

/// Built-in interactive face effects / styles (TikTok-style carousel).
enum FaceFilterId {
  none,
  /// GPU beauty looks (fragment shader) — visibles en el carrusel.
  /// Beauty HD: suavizado fuerte + even skin (preset principal).
  beauty,
  beautySoft,
  beautyNatural,
  beautyPorcelain,
  beautyFresh,
  beautyWarm,
  beautyRose,
  /// Looks belleza personalizados (LIVE / FaceBetter params).
  beautyDewy,
  beautyMatte,
  beautyRadiant,
  beautyClear,
  beautyVFace,
  beautyDoll,
  beautyPeach,
  beautySilk,
  beautyCrystal,
  beautyNight,
  beautySnatch,
  beautyGlass,
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
      this == FaceFilterId.beauty ||
      this == FaceFilterId.beautySoft ||
      this == FaceFilterId.beautyNatural ||
      this == FaceFilterId.beautyPorcelain ||
      this == FaceFilterId.beautyFresh ||
      this == FaceFilterId.beautyWarm ||
      this == FaceFilterId.beautyRose ||
      this == FaceFilterId.beautyDewy ||
      this == FaceFilterId.beautyMatte ||
      this == FaceFilterId.beautyRadiant ||
      this == FaceFilterId.beautyClear ||
      this == FaceFilterId.beautyVFace ||
      this == FaceFilterId.beautyDoll ||
      this == FaceFilterId.beautyPeach ||
      this == FaceFilterId.beautySilk ||
      this == FaceFilterId.beautyCrystal ||
      this == FaceFilterId.beautyNight ||
      this == FaceFilterId.beautySnatch ||
      this == FaceFilterId.beautyGlass;

  /// Necesita Face Mesh / CustomPainter AR.
  bool get needsFaceMesh =>
      this != FaceFilterId.none && !isBeautyGpu;

  /// Preset GPU asociado (null = apagar beauty o dejar base suave).
  BeautyLook? get beautyLook {
    switch (this) {
      case FaceFilterId.beauty:
        return const BeautyLook(
          intensity: 0.88,
          mode: 5,
          whiten: 0.22,
          rosy: 0.08,
          sharpen: 0.28,
        );
      case FaceFilterId.beautySoft:
        return const BeautyLook(
          intensity: 0.72,
          mode: 0,
          whiten: 0.12,
          rosy: 0.06,
          sharpen: 0.10,
        );
      case FaceFilterId.beautyNatural:
        return const BeautyLook(
          intensity: 0.52,
          mode: 0,
          whiten: 0.05,
          rosy: 0.04,
          sharpen: 0.20,
        );
      case FaceFilterId.beautyPorcelain:
        return const BeautyLook(
          intensity: 0.90,
          mode: 1,
          whiten: 0.55,
          rosy: 0.04,
          sharpen: 0.12,
        );
      case FaceFilterId.beautyFresh:
        return const BeautyLook(
          intensity: 0.82,
          mode: 2,
          whiten: 0.18,
          rosy: 0.10,
          sharpen: 0.22,
        );
      case FaceFilterId.beautyWarm:
        return const BeautyLook(
          intensity: 0.85,
          mode: 3,
          whiten: 0.12,
          rosy: 0.18,
          sharpen: 0.15,
        );
      case FaceFilterId.beautyRose:
        return const BeautyLook(
          intensity: 0.86,
          mode: 4,
          whiten: 0.20,
          rosy: 0.55,
          sharpen: 0.14,
        );
      case FaceFilterId.beautyDewy:
        return const BeautyLook(
          intensity: 0.88,
          mode: 6,
          whiten: 0.25,
          rosy: 0.40,
          sharpen: 0.08,
        );
      case FaceFilterId.beautyMatte:
        return const BeautyLook(
          intensity: 0.90,
          mode: 7,
          whiten: 0.20,
          rosy: 0.02,
          sharpen: 0.35,
        );
      case FaceFilterId.beautyRadiant:
        return const BeautyLook(
          intensity: 0.88,
          mode: 5,
          whiten: 0.30,
          rosy: 0.22,
          sharpen: 0.40,
        );
      case FaceFilterId.beautyClear:
        return const BeautyLook(
          intensity: 0.86,
          mode: 1,
          whiten: 0.70,
          rosy: 0.05,
          sharpen: 0.18,
        );
      case FaceFilterId.beautyVFace:
        return const BeautyLook(
          intensity: 0.80,
          mode: 5,
          whiten: 0.18,
          rosy: 0.12,
          sharpen: 0.25,
        );
      case FaceFilterId.beautyDoll:
        return const BeautyLook(
          intensity: 0.90,
          mode: 4,
          whiten: 0.40,
          rosy: 0.45,
          sharpen: 0.15,
        );
      case FaceFilterId.beautyPeach:
        return const BeautyLook(
          intensity: 0.88,
          mode: 8,
          whiten: 0.15,
          rosy: 0.50,
          sharpen: 0.12,
        );
      case FaceFilterId.beautySilk:
        return const BeautyLook(
          intensity: 0.95,
          mode: 7,
          whiten: 0.35,
          rosy: 0.10,
          sharpen: 0.05,
        );
      case FaceFilterId.beautyCrystal:
        return const BeautyLook(
          intensity: 0.88,
          mode: 10,
          whiten: 0.45,
          rosy: 0.08,
          sharpen: 0.55,
        );
      case FaceFilterId.beautyNight:
        return const BeautyLook(
          intensity: 0.80,
          mode: 9,
          whiten: 0.10,
          rosy: 0.15,
          sharpen: 0.50,
        );
      case FaceFilterId.beautySnatch:
        return const BeautyLook(
          intensity: 0.92,
          mode: 5,
          whiten: 0.28,
          rosy: 0.20,
          sharpen: 0.45,
        );
      case FaceFilterId.beautyGlass:
        return const BeautyLook(
          intensity: 0.90,
          mode: 11,
          whiten: 0.60,
          rosy: 0.12,
          sharpen: 0.40,
        );
      case FaceFilterId.none:
        return const BeautyLook(intensity: 0, mode: 0);
      default:
        return const BeautyLook(intensity: 0.42, mode: 0);
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
      id: FaceFilterId.beauty,
      title: 'Beauty',
      icon: Icons.face_retouching_natural,
      accent: Color(0xFFFFAB91),
    ),
    FaceFilterEffect(
      id: FaceFilterId.beautySoft,
      title: 'Soft',
      icon: Icons.spa,
      accent: Color(0xFFFFCCBC),
    ),
    FaceFilterEffect(
      id: FaceFilterId.beautyNatural,
      title: 'Natural',
      icon: Icons.spa_outlined,
      accent: Color(0xFFA5D6A7),
    ),
    FaceFilterEffect(
      id: FaceFilterId.beautyPorcelain,
      title: 'Porcelain',
      icon: Icons.brightness_5,
      accent: Color(0xFFF8BBD0),
    ),
    FaceFilterEffect(
      id: FaceFilterId.beautyFresh,
      title: 'Fresh',
      icon: Icons.water_drop_outlined,
      accent: Color(0xFF81D4FA),
    ),
    FaceFilterEffect(
      id: FaceFilterId.beautyWarm,
      title: 'Warm',
      icon: Icons.wb_sunny,
      accent: Color(0xFFFFB74D),
    ),
    FaceFilterEffect(
      id: FaceFilterId.beautyRose,
      title: 'Rose',
      icon: Icons.favorite_border,
      accent: Color(0xFFF48FB1),
    ),
    FaceFilterEffect(
      id: FaceFilterId.beautyDewy,
      title: 'Dewy',
      icon: Icons.opacity,
      accent: Color(0xFFB2EBF2),
    ),
    FaceFilterEffect(
      id: FaceFilterId.beautyMatte,
      title: 'Matte',
      icon: Icons.blur_on,
      accent: Color(0xFFE0E0E0),
    ),
    FaceFilterEffect(
      id: FaceFilterId.beautyRadiant,
      title: 'Radiant',
      icon: Icons.wb_iridescent_outlined,
      accent: Color(0xFFFFE082),
    ),
    FaceFilterEffect(
      id: FaceFilterId.beautyClear,
      title: 'Clear',
      icon: Icons.auto_fix_high,
      accent: Color(0xFFE1F5FE),
    ),
    FaceFilterEffect(
      id: FaceFilterId.beautyVFace,
      title: 'V-Face',
      icon: Icons.face_3_outlined,
      accent: Color(0xFFCE93D8),
    ),
    FaceFilterEffect(
      id: FaceFilterId.beautyDoll,
      title: 'Doll',
      icon: Icons.visibility_outlined,
      accent: Color(0xFFF8BBD0),
    ),
    FaceFilterEffect(
      id: FaceFilterId.beautyPeach,
      title: 'Peach',
      icon: Icons.emoji_nature,
      accent: Color(0xFFFFAB91),
    ),
    FaceFilterEffect(
      id: FaceFilterId.beautySilk,
      title: 'Silk',
      icon: Icons.texture,
      accent: Color(0xFFF5F5F5),
    ),
    FaceFilterEffect(
      id: FaceFilterId.beautyCrystal,
      title: 'Crystal',
      icon: Icons.diamond_outlined,
      accent: Color(0xFFB3E5FC),
    ),
    FaceFilterEffect(
      id: FaceFilterId.beautyNight,
      title: 'Night',
      icon: Icons.nightlight_round,
      accent: Color(0xFF90A4AE),
    ),
    FaceFilterEffect(
      id: FaceFilterId.beautySnatch,
      title: 'Snatch',
      icon: Icons.auto_awesome,
      accent: Color(0xFFFF8A65),
    ),
    FaceFilterEffect(
      id: FaceFilterId.beautyGlass,
      title: 'Glass',
      icon: Icons.water,
      accent: Color(0xFF80DEEA),
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
