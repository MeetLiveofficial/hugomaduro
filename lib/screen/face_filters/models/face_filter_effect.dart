import 'package:flutter/material.dart';

/// Built-in interactive face effects / styles (TikTok-style carousel).
enum FaceFilterId {
  none,
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

class FaceFilterEffect {
  const FaceFilterEffect({
    required this.id,
    required this.title,
    required this.icon,
    required this.accent,
  });

  final FaceFilterId id;
  final String title;
  final IconData icon;
  final Color accent;

  static const List<FaceFilterEffect> catalog = [
    FaceFilterEffect(
      id: FaceFilterId.none,
      title: 'None',
      icon: Icons.block,
      accent: Color(0xFF9E9E9E),
    ),
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
