import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krimson/utilities/asset_res.dart';

/// Estilo visual por paquete (overlay de recarga + tienda cliente).
class CoinPackVisual {
  const CoinPackVisual({
    required this.accent,
    required this.button,
    this.badgeEn,
    this.badgeEs,
    this.badgeIcon,
    this.hasGift = false,
    this.stackCount = 1,
  });

  final Color accent;
  final Color button;
  final String? badgeEn;
  final String? badgeEs;
  final IconData? badgeIcon;
  final bool hasGift;
  final int stackCount;

  String? get badge {
    if (badgeEn == null) return null;
    return Get.locale?.languageCode == 'es' ? (badgeEs ?? badgeEn) : badgeEn;
  }

  static CoinPackVisual of(int index) => _all[index % _all.length];

  static const _all = <CoinPackVisual>[
    CoinPackVisual(
      accent: Color(0xFFF5C542),
      button: Color(0xFFF5B400),
      badgeEn: 'Most popular',
      badgeEs: 'Más popular',
      badgeIcon: Icons.local_fire_department_rounded,
      stackCount: 1,
    ),
    CoinPackVisual(
      accent: Color(0xFF3B9BFF),
      button: Color(0xFF2F7BFF),
      stackCount: 2,
    ),
    CoinPackVisual(
      accent: Color(0xFFC084FC),
      button: Color(0xFFA855F7),
      badgeEn: 'Great value',
      badgeEs: 'Gran valor',
      badgeIcon: Icons.workspace_premium_rounded,
      hasGift: true,
      stackCount: 3,
    ),
    CoinPackVisual(
      accent: Color(0xFF4ADE80),
      button: Color(0xFF22C55E),
      hasGift: true,
      stackCount: 3,
    ),
    CoinPackVisual(
      accent: Color(0xFFF472B6),
      button: Color(0xFFEC4899),
      stackCount: 3,
    ),
    CoinPackVisual(
      accent: Color(0xFFA78BFA),
      button: Color(0xFF8B5CF6),
      badgeEn: 'Best choice',
      badgeEs: 'Mejor opción',
      badgeIcon: Icons.workspace_premium_rounded,
      hasGift: true,
      stackCount: 3,
    ),
  ];
}

class CoinPackLeading extends StatelessWidget {
  const CoinPackLeading({
    super.key,
    required this.accent,
    required this.stackCount,
    this.hasGift = false,
    this.size = 42,
  });

  final Color accent;
  final int stackCount;
  final bool hasGift;
  final double size;

  @override
  Widget build(BuildContext context) {
    final count = stackCount.clamp(1, 3);
    return SizedBox(
      width: hasGift ? 58 : 52,
      height: 50,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          if (count >= 3)
            Positioned(
              left: 0,
              top: 10,
              child: Opacity(
                opacity: 0.45,
                child: Image.asset(
                  AssetRes.icCoin,
                  width: size - 12,
                  height: size - 12,
                ),
              ),
            ),
          if (count >= 2)
            Positioned(
              left: count >= 3 ? 10 : 2,
              top: 6,
              child: Opacity(
                opacity: 0.7,
                child: Image.asset(
                  AssetRes.icCoin,
                  width: size - 6,
                  height: size - 6,
                ),
              ),
            ),
          Positioned(
            right: hasGift ? 10 : 2,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.55),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Image.asset(AssetRes.icCoin, width: size, height: size),
            ),
          ),
          if (hasGift)
            Positioned(
              right: -2,
              bottom: -2,
              child: Image.asset(
                AssetRes.icGift,
                width: 22,
                height: 22,
                errorBuilder: (_, __, ___) => Icon(
                  Icons.card_giftcard_rounded,
                  color: accent,
                  size: 20,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
