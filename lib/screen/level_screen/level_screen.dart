import 'package:figma_squircle_updated/figma_squircle.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krimson/common/extensions/common_extension.dart';
import 'package:krimson/common/manager/app_role.dart';
import 'package:krimson/common/widget/brand_wash_bg.dart';
import 'package:krimson/common/widget/gradient_text.dart';
import 'package:krimson/common/manager/session_manager.dart';
import 'package:krimson/languages/languages_keys.dart';
import 'package:krimson/model/general/settings_model.dart';
import 'package:krimson/utilities/asset_res.dart';
import 'package:krimson/utilities/client_colors.dart';
import 'package:krimson/utilities/text_style_custom.dart';
import 'package:krimson/utilities/theme_res.dart';

/// Pantalla de niveles con contraste y jerarquía más legibles.
class LevelScreen extends StatelessWidget {
  final UserLevel? userLevels;

  const LevelScreen({super.key, this.userLevels});

  @override
  Widget build(BuildContext context) {
    final List<UserLevel> levels = [
      ...(SessionManager.instance.getSettings()?.userLevels ?? <UserLevel>[])
    ]
      ..sort((a, b) => a.coinsCollection.compareTo(b.coinsCollection));
    final current = userLevels ?? SessionManager.instance.getUser()?.getLevel;
    final client = AppRole.isClient();
    final accent = client ? ClientColors.primary : themeAccentSolid(context);
    final bg = client ? ClientColors.bg : scaffoldBackgroundColor(context);
    // Clientes solo ven progreso (nivel + monedas); sin textos de beneficios.
    final showBenefits = AppRole.isStreamer();

    if (client) {
      return ThemeRes.applyIfClient(
        context,
        Scaffold(
          backgroundColor: ClientColors.bg,
          body: Stack(
            children: [
              const BrandWashBg(vivid: true),
              _ClientLevelBody(levels: levels, current: current),
            ],
          ),
        ),
      );
    }

    return ThemeRes.applyIfClient(
      context,
      Scaffold(
      backgroundColor: bg,
      body: Column(
        children: [
          _Header(
            current: current,
            accent: accent,
            showBenefits: showBenefits,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
            child: Row(
              children: [
                Text(
                  LKey.level.tr,
                  style: TextStyleCustom.outFitSemiBold600(
                    color: AppRole.isClient()
                        ? ClientColors.text
                        : textDarkGrey(context),
                    fontSize: 14,
                  ),
                ),
                const Spacer(),
                Text(
                  LKey.collection.tr,
                  style: TextStyleCustom.outFitMedium500(
                    color: textLightGrey(context),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: levels.length,
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
              itemBuilder: (context, index) {
                final level = levels[index];
                final isCurrent = level.level == current?.level;
                return _LevelCard(
                  level: level,
                  isCurrent: isCurrent,
                  accent: accent,
                  showBenefits: showBenefits,
                );
              },
            ),
          ),
        ],
      ),
    ),
    );
  }
}

class _Header extends StatelessWidget {
  final UserLevel? current;
  final Color accent;
  final bool showBenefits;

  const _Header({
    required this.current,
    required this.accent,
    required this.showBenefits,
  });

  @override
  Widget build(BuildContext context) {
    final benefits =
        showBenefits ? (current?.benefits ?? const <String>[]) : const <String>[];

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppRole.isClient() ? Colors.transparent : const Color(0xFF141418),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                onPressed: Get.back,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: Colors.white, size: 20),
              ),
              const SizedBox(height: 4),
              Text(
                LKey.myLevel.tr,
                style: TextStyleCustom.unboundedBold700(
                  fontSize: 26,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: accent,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${LKey.level.tr} ${current?.level ?? 1}',
                      style: TextStyleCustom.outFitSemiBold600(
                        fontSize: 13,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  if (benefits.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    InkWell(
                      onTap: () => _showBenefitsSheet(
                        context,
                        benefits: benefits,
                        accent: accent,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        width: 28,
                        height: 28,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.55),
                          ),
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                        child: const Text(
                          '?',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            height: 1,
                          ),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      LKey.gatherMoreCoins.tr,
                      style: TextStyleCustom.outFitRegular400(
                        fontSize: 13,
                        color: Colors.white70,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showBenefitsSheet(
    BuildContext context, {
    required List<String> benefits,
    required Color accent,
  }) {
    Get.bottomSheet(
      SafeArea(
        child: Container(
          width: double.infinity,
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E24),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: accent.withValues(alpha: 0.45)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              Row(
                children: [
                  Text(
                    LKey.benefits.tr,
                    style: TextStyleCustom.outFitSemiBold600(
                      color: accent,
                      fontSize: 16,
                    ),
                  ),
                  const Spacer(),
                  InkWell(
                    onTap: Get.back,
                    borderRadius: BorderRadius.circular(16),
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(Icons.close_rounded,
                          color: Colors.white70, size: 20),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...benefits.map(
                (b) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Container(
                          width: 5,
                          height: 5,
                          decoration: BoxDecoration(
                            color: accent,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          b,
                          style: TextStyleCustom.outFitRegular400(
                            color: Colors.white.withValues(alpha: 0.92),
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
    );
  }
}

class _LevelCard extends StatelessWidget {
  final UserLevel level;
  final bool isCurrent;
  final Color accent;
  final bool showBenefits;

  const _LevelCard({
    required this.level,
    required this.isCurrent,
    required this.accent,
    required this.showBenefits,
  });

  @override
  Widget build(BuildContext context) {
    final client = AppRole.isClient();
    final borderColor = isCurrent
        ? accent
        : (client
            ? ClientColors.border
            : textLightGrey(context).withValues(alpha: 0.25));
    final fill = isCurrent
        ? accent.withValues(alpha: client ? 0.14 : 0.06)
        : (client ? ClientColors.surface : bgLightGrey(context));

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: ShapeDecoration(
        color: fill,
        shape: SmoothRectangleBorder(
          borderRadius: SmoothBorderRadius(cornerRadius: 14, cornerSmoothing: 1),
          side: BorderSide(color: borderColor, width: isCurrent ? 1.8 : 1),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${LKey.level.tr} ${level.level}',
                  style: TextStyleCustom.outFitSemiBold600(
                    color: isCurrent
                        ? accent
                        : (AppRole.isClient()
                            ? ClientColors.text
                            : textDarkGrey(context)),
                    fontSize: 15,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (isCurrent)
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    LKey.you.tr,
                    style: TextStyleCustom.outFitSemiBold600(
                      color: Colors.white,
                      fontSize: 11,
                    ),
                  ),
                ),
              Image.asset(AssetRes.icCoin, width: 16, height: 16),
              const SizedBox(width: 4),
              Text(
                level.coinsCollection.numberFormat,
                style: TextStyleCustom.outFitMedium500(
                  fontSize: 14,
                  color: AppRole.isClient()
                      ? ClientColors.gold
                      : textDarkGrey(context),
                ),
              ),
            ],
          ),
          if (showBenefits) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _MetaChip(
                  label:
                      '${LKey.callPrice.tr}: ${level.callRequestCoins} ${LKey.coins.tr}',
                  emphasized: isCurrent,
                ),
                _MetaChip(
                  label:
                      '${LKey.receiveCalls.tr}: ${level.canReceiveCalls == 1 ? LKey.yes.tr : LKey.no.tr}',
                  emphasized: isCurrent && level.canReceiveCalls == 1,
                ),
                _MetaChip(
                  label:
                      '${LKey.canGoLive.tr}: ${level.canGoLive == 1 ? LKey.yes.tr : LKey.no.tr}',
                  emphasized: isCurrent && level.canGoLive == 1,
                ),
              ],
            ),
            if (level.benefits.isNotEmpty) ...[
              const SizedBox(height: 10),
              ...level.benefits.take(3).map(
                    (b) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        '• $b',
                        style: TextStyleCustom.outFitRegular400(
                          fontSize: 12,
                          color: textDarkGrey(context).withValues(alpha: 0.75),
                        ),
                      ),
                    ),
                  ),
            ],
          ],
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final String label;
  final bool emphasized;

  const _MetaChip({required this.label, this.emphasized = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: emphasized
            ? themeAccentSolid(context).withValues(alpha: 0.1)
            : bgMediumGrey(context),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyleCustom.outFitMedium500(
          fontSize: 11,
          color: emphasized
              ? themeAccentSolid(context)
              : textDarkGrey(context).withValues(alpha: 0.8),
        ),
      ),
    );
  }
}

const _kLevelBadges = <String>[
  'assets/images/levels/level_badge_gold.png',
  'assets/images/levels/level_badge_silver.png',
  'assets/images/levels/level_badge_bronze.png',
  'assets/images/levels/level_badge_violet.png',
  'assets/images/levels/level_badge_magenta.png',
];

/// El PNG trae fondo negro; la luminancia pasa a alfa para que se vea el navy.
const ColorFilter _kBadgeKnockout = ColorFilter.matrix(<double>[
  1, 0, 0, 0, 0,
  0, 1, 0, 0, 0,
  0, 0, 1, 0, 0,
  0.35, 0.5, 0.15, 0, 0,
]);

class _BadgeArt extends StatelessWidget {
  final String asset;
  final double size;

  const _BadgeArt({required this.asset, required this.size});

  @override
  Widget build(BuildContext context) {
    return ColorFiltered(
      colorFilter: _kBadgeKnockout,
      child: Image.asset(
        asset,
        width: size,
        height: size,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.medium,
      ),
    );
  }
}

class _ClientLevelBody extends StatelessWidget {
  final List<UserLevel> levels;
  final UserLevel? current;

  const _ClientLevelBody({required this.levels, required this.current});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const _ClientLevelHeader(),
        Expanded(
          child: ListView.builder(
            itemCount: levels.length,
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 28),
            itemBuilder: (context, index) {
              final level = levels[index];
              return _ClientLevelRow(
                level: level,
                isCurrent: level.level == current?.level,
                badge: _kLevelBadges[index % _kLevelBadges.length],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ClientLevelHeader extends StatelessWidget {
  const _ClientLevelHeader();

  @override
  Widget build(BuildContext context) {
    final raw = LKey.myLevel.tr.trim();
    final split = raw.indexOf(' ');
    final head = split == -1 ? raw : raw.substring(0, split);
    final tail = split == -1 ? '' : raw.substring(split + 1);

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 4, 12, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            IconButton(
              onPressed: Get.back,
              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white, size: 20),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('👑', style: TextStyle(fontSize: 22)),
                        const SizedBox(height: 2),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              head,
                              style: TextStyleCustom.unboundedBold700(
                                fontSize: 32,
                                color: Colors.white,
                              ),
                            ),
                            if (tail.isNotEmpty) ...[
                              const SizedBox(width: 8),
                              Flexible(
                                child: GradientText(
                                  tail,
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF5CE1FF),
                                      Color(0xFF3A83F3),
                                    ],
                                  ),
                                  style: TextStyleCustom.unboundedBold700(
                                    fontSize: 32,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          LKey.gatherMoreCoins.tr,
                          style: TextStyleCustom.outFitRegular400(
                            fontSize: 13,
                            color: ClientColors.textMuted,
                          ),
                          maxLines: 3,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const _BadgeArt(
                    asset: 'assets/images/levels/level_badge_hero.png',
                    size: 118,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: ClientColors.surfaceAlt,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: ClientColors.primary.withValues(alpha: 0.7),
                      ),
                    ),
                    child: const Text('👑', style: TextStyle(fontSize: 14)),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    LKey.level.tr,
                    style: TextStyleCustom.outFitSemiBold600(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    LKey.collection.tr,
                    style: TextStyleCustom.outFitMedium500(
                      color: ClientColors.primary,
                      fontSize: 14,
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded,
                      color: ClientColors.primary, size: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ClientLevelRow extends StatelessWidget {
  final UserLevel level;
  final bool isCurrent;
  final String badge;

  const _ClientLevelRow({
    required this.level,
    required this.isCurrent,
    required this.badge,
  });

  @override
  Widget build(BuildContext context) {
    final edge = isCurrent
        ? const Color(0xFF5CE1FF)
        : ClientColors.accentBlue.withValues(alpha: 0.38);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(8, 6, 14, 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isCurrent
              ? const [Color(0xFF123A62), Color(0xFF16325A)]
              : const [Color(0xFF101C34), Color(0xFF0C1830)],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: edge, width: isCurrent ? 1.6 : 1),
        boxShadow: isCurrent
            ? ClientColors.neonGlow(
                color: const Color(0xFF3EC6FF),
                alpha: 0.4,
                blur: 16,
              )
            : null,
      ),
      child: Row(
        children: [
          _BadgeArt(asset: badge, size: 58),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${LKey.level.tr} ${level.level}',
              style: TextStyleCustom.outFitSemiBold600(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          ),
          if (isCurrent)
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF2EC8FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                LKey.you.tr,
                style: TextStyleCustom.outFitSemiBold600(
                  color: Colors.white,
                  fontSize: 12,
                ),
              ),
            ),
          Image.asset(AssetRes.icCoin, width: 18, height: 18),
          const SizedBox(width: 4),
          Text(
            level.coinsCollection.numberFormat,
            style: TextStyleCustom.outFitSemiBold600(
              fontSize: 15,
              color: ClientColors.gold,
            ),
          ),
        ],
      ),
    );
  }
}

