import 'package:flutter/material.dart';
import 'package:facebetter_flutter/facebetter_flutter.dart';
import 'package:krimson/screen/face_filters/models/face_filter_effect.dart';

/// Looks mapeados a FaceBetter Basic + Reshape.
/// Docs: https://www.facebetter.net/docs/intro/overview
class FaceBetterLooks {
  FaceBetterLooks._();

  static const List<FaceFilterEffect> catalog = [
    FaceFilterEffect(
      id: FaceFilterId.none,
      title: 'None',
      icon: Icons.block,
      accent: Color(0xFF9E9E9E),
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
      id: FaceFilterId.beauty,
      title: 'Beauty',
      icon: Icons.face_retouching_natural,
      accent: Color(0xFFFFAB91),
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
  ];

  static FaceBetterBeautyParams paramsFor(FaceFilterId id) {
    switch (id) {
      case FaceFilterId.none:
        return const FaceBetterBeautyParams(enabled: false);
      case FaceFilterId.beautySoft:
        return const FaceBetterBeautyParams(
          smooth: 0.55,
          whiten: 0.20,
          rosy: 0.10,
          sharpen: 0.12,
          slimFace: 0.0,
          bigEye: 0.0,
        );
      case FaceFilterId.beautyNatural:
        return const FaceBetterBeautyParams(
          smooth: 0.28,
          whiten: 0.08,
          rosy: 0.05,
          sharpen: 0.22,
          slimFace: 0.05,
          bigEye: 0.0,
        );
      case FaceFilterId.beauty:
        return const FaceBetterBeautyParams(
          smooth: 0.78,
          whiten: 0.35,
          rosy: 0.12,
          sharpen: 0.35,
          slimFace: 0.35,
          bigEye: 0.25,
        );
      case FaceFilterId.beautyPorcelain:
        return const FaceBetterBeautyParams(
          smooth: 0.82,
          whiten: 0.70,
          rosy: 0.05,
          sharpen: 0.18,
          slimFace: 0.20,
          bigEye: 0.15,
        );
      case FaceFilterId.beautyFresh:
        return const FaceBetterBeautyParams(
          smooth: 0.55,
          whiten: 0.25,
          rosy: 0.12,
          sharpen: 0.30,
          slimFace: 0.15,
          bigEye: 0.28,
        );
      case FaceFilterId.beautyWarm:
        return const FaceBetterBeautyParams(
          smooth: 0.60,
          whiten: 0.18,
          rosy: 0.30,
          sharpen: 0.20,
          slimFace: 0.20,
          bigEye: 0.10,
        );
      case FaceFilterId.beautyRose:
        return const FaceBetterBeautyParams(
          smooth: 0.65,
          whiten: 0.30,
          rosy: 0.65,
          sharpen: 0.18,
          slimFace: 0.25,
          bigEye: 0.22,
        );
      case FaceFilterId.beautyDewy:
        return const FaceBetterBeautyParams(
          smooth: 0.60,
          whiten: 0.35,
          rosy: 0.55,
          sharpen: 0.10,
          slimFace: 0.15,
          bigEye: 0.18,
        );
      case FaceFilterId.beautyMatte:
        return const FaceBetterBeautyParams(
          smooth: 0.90,
          whiten: 0.30,
          rosy: 0.02,
          sharpen: 0.45,
          slimFace: 0.30,
          bigEye: 0.10,
        );
      case FaceFilterId.beautyRadiant:
        return const FaceBetterBeautyParams(
          smooth: 0.70,
          whiten: 0.40,
          rosy: 0.30,
          sharpen: 0.50,
          slimFace: 0.22,
          bigEye: 0.22,
        );
      case FaceFilterId.beautyClear:
        return const FaceBetterBeautyParams(
          smooth: 0.72,
          whiten: 0.80,
          rosy: 0.05,
          sharpen: 0.25,
          slimFace: 0.18,
          bigEye: 0.12,
        );
      case FaceFilterId.beautyVFace:
        return const FaceBetterBeautyParams(
          smooth: 0.65,
          whiten: 0.25,
          rosy: 0.15,
          sharpen: 0.30,
          slimFace: 0.70,
          bigEye: 0.18,
        );
      case FaceFilterId.beautyDoll:
        return const FaceBetterBeautyParams(
          smooth: 0.78,
          whiten: 0.50,
          rosy: 0.55,
          sharpen: 0.18,
          slimFace: 0.35,
          bigEye: 0.70,
        );
      case FaceFilterId.beautyPeach:
        return const FaceBetterBeautyParams(
          smooth: 0.62,
          whiten: 0.20,
          rosy: 0.65,
          sharpen: 0.15,
          slimFace: 0.20,
          bigEye: 0.15,
        );
      case FaceFilterId.beautySilk:
        return const FaceBetterBeautyParams(
          smooth: 0.95,
          whiten: 0.45,
          rosy: 0.12,
          sharpen: 0.05,
          slimFace: 0.25,
          bigEye: 0.12,
        );
      case FaceFilterId.beautyCrystal:
        return const FaceBetterBeautyParams(
          smooth: 0.68,
          whiten: 0.55,
          rosy: 0.08,
          sharpen: 0.65,
          slimFace: 0.22,
          bigEye: 0.20,
        );
      case FaceFilterId.beautyNight:
        return const FaceBetterBeautyParams(
          smooth: 0.48,
          whiten: 0.12,
          rosy: 0.18,
          sharpen: 0.60,
          slimFace: 0.18,
          bigEye: 0.12,
        );
      case FaceFilterId.beautySnatch:
        return const FaceBetterBeautyParams(
          smooth: 0.85,
          whiten: 0.40,
          rosy: 0.28,
          sharpen: 0.55,
          slimFace: 0.55,
          bigEye: 0.35,
        );
      case FaceFilterId.beautyGlass:
        return const FaceBetterBeautyParams(
          smooth: 0.65,
          whiten: 0.75,
          rosy: 0.15,
          sharpen: 0.50,
          slimFace: 0.20,
          bigEye: 0.28,
        );
      default:
        return const FaceBetterBeautyParams(
          smooth: 0.42,
          whiten: 0.28,
          rosy: 0.15,
          sharpen: 0.20,
        );
    }
  }

  static void applyToSliders(
    FaceFilterId id, {
    required void Function(bool on) setBeautyOn,
    required void Function(double) setWhiten,
    required void Function(double) setSmooth,
    required void Function(double) setRosy,
    required void Function(double) setSharpen,
    required void Function(double) setSlimFace,
    required void Function(double) setBigEye,
  }) {
    final p = paramsFor(id);
    setBeautyOn(p.enabled && id != FaceFilterId.none);
    setWhiten(p.whiten * 100);
    setSmooth(p.smooth * 100);
    setRosy(p.rosy * 100);
    setSharpen(p.sharpen * 100);
    setSlimFace(p.slimFace * 100);
    setBigEye(p.bigEye * 100);
  }
}
