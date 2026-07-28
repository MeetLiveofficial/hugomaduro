import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krimson/common/extensions/common_extension.dart';
import 'package:krimson/common/extensions/string_extension.dart';
import 'package:krimson/common/service/api/privilege_service.dart';
import 'package:krimson/common/widget/custom_image.dart';
import 'package:krimson/common/widget/loader_widget.dart';
import 'package:krimson/common/widget/no_data_widget.dart';
import 'package:krimson/languages/languages_keys.dart';
import 'package:krimson/screen/leaderboard_screen/leaderboard_screen_controller.dart';
import 'package:krimson/utilities/asset_res.dart';
import 'package:krimson/utilities/color_res.dart';
import 'package:krimson/utilities/text_style_custom.dart';

/// Ranking Clientes (givers) | Streamers (receivers) con podio TOP 3.
class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(LeaderboardController());

    return Obx(() {
      final isClients = controller.tab.value == LeaderboardTab.clients;
      final theme = isClients ? _LbTheme.clients : _LbTheme.streamers;

      return Scaffold(
        backgroundColor: theme.bg,
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: theme.bgGradient,
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Column(
              children: [
                _Header(theme: theme),
                const SizedBox(height: 10),
                _TypeTabs(controller: controller),
                const SizedBox(height: 10),
                Obx(() => Text(
                      '${LKey.endsIn.tr} ${controller.countdown.value}',
                      style: TextStyleCustom.outFitMedium500(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    )),
                const SizedBox(height: 12),
                _PeriodFilters(controller: controller, theme: theme),
                const SizedBox(height: 8),
                Expanded(
                  child: Obx(() {
                    if (controller.isLoading.value &&
                        controller.users.isEmpty) {
                      return const LoaderWidget();
                    }
                    return NoDataView(
                      showShow: controller.users.isEmpty,
                      title: LKey.leaderboard.tr,
                      description: LKey.noData.tr,
                      child: CustomScrollView(
                        physics: const BouncingScrollPhysics(),
                        slivers: [
                          SliverToBoxAdapter(
                            child: _Podium(
                              users: controller.users,
                              theme: theme,
                            ),
                          ),
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(12, 8, 12, 100),
                            sliver: SliverList.separated(
                              itemCount: controller.users.length > 3
                                  ? controller.users.length - 3
                                  : 0,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 4),
                              itemBuilder: (context, index) {
                                final entry = controller.users[index + 3];
                                return _RankRow(entry: entry);
                              },
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: Obx(() {
          final me = controller.me.value;
          if (me == null) return const SizedBox.shrink();
          return _MyRankBar(me: me, theme: theme);
        }),
      );
    });
  }
}

class _LbTheme {
  const _LbTheme({
    required this.bg,
    required this.bgGradient,
    required this.accent,
    required this.tabActive,
    this.tabActiveGradient,
    required this.tabInactive,
    required this.periodActive,
    required this.periodInactive,
    required this.rowBg,
    required this.podium1,
    required this.podium2,
    required this.podium3,
  });

  final Color bg;
  final List<Color> bgGradient;
  final Color accent;
  final Color tabActive;
  final List<Color>? tabActiveGradient;
  final Color tabInactive;
  final Color periodActive;
  final Color periodInactive;
  final Color rowBg;
  final List<Color> podium1;
  final List<Color> podium2;
  final List<Color> podium3;

  /// Clientes: neon rosa→violeta (logo).
  static const clients = _LbTheme(
    bg: Color(0xFF0F0F12),
    bgGradient: [Color(0xFFE24AB7), Color(0xFFB140D8), Color(0xFF0F0F12)],
    accent: Color(0xFFF456AA),
    tabActive: Color(0xFFE24AB7),
    tabActiveGradient: [Color(0xFFFE5A59), Color(0xFFE24AB7)],
    tabInactive: Color(0xFF2A2A32),
    periodActive: Color(0xFFB140D8),
    periodInactive: Color(0xFF1A1A1F),
    rowBg: Color(0xCC1A1A1F),
    podium1: [Color(0xFFFE5A59), Color(0xFFE24AB7)],
    podium2: [Color(0xFFF456AA), Color(0xFFB140D8)],
    podium3: [Color(0xFFC084FC), Color(0xFF7C3AED)],
  );

  /// Streamers: coral→magenta→violeta.
  static const streamers = _LbTheme(
    bg: Color(0xFF0F0F12),
    bgGradient: [Color(0xFFFE5A59), Color(0xFFF456AA), Color(0xFFB140D8)],
    accent: Color(0xFFFFE4EC),
    tabActive: Color(0xFFFE5A59),
    tabActiveGradient: [Color(0xFFFE5A59), Color(0xFFE24AB7)],
    tabInactive: Color(0xFF2A2A32),
    periodActive: Color(0xFFE24AB7),
    periodInactive: Color(0xFF1A1A1F),
    rowBg: Color(0xCC222228),
    podium1: [Color(0xFFFE5A59), Color(0xFFE24AB7)],
    podium2: [Color(0xFFF456AA), Color(0xFFB140D8)],
    podium3: [Color(0xFFFFB4A2), Color(0xFF9333EA)],
  );
}

class _Header extends StatelessWidget {
  const _Header({required this.theme});

  final _LbTheme theme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
      child: Row(
        children: [
          IconButton(
            onPressed: Get.back,
            icon: const Icon(Icons.arrow_back_ios_new,
                color: Colors.white, size: 20),
          ),
          Expanded(
            child: Text(
              LKey.leaderboard.tr,
              textAlign: TextAlign.center,
              style: TextStyleCustom.unboundedBold700(
                color: Colors.white,
                fontSize: 18,
              ),
            ),
          ),
          IconButton(
            onPressed: () {
              Get.dialog(
                AlertDialog(
                  backgroundColor: theme.bg,
                  title: Text(
                    LKey.leaderboard.tr,
                    style: TextStyleCustom.outFitMedium500(
                        color: Colors.white, fontSize: 16),
                  ),
                  content: Text(
                    '${LKey.clientsRanking.tr}: regalos enviados.\n'
                    '${LKey.streamersRanking.tr}: regalos recibidos.',
                    style: TextStyleCustom.outFitRegular400(
                        color: Colors.white70, fontSize: 14),
                  ),
                  actions: [
                    TextButton(
                      onPressed: Get.back,
                      child: Text(LKey.continueText.tr,
                          style: TextStyleCustom.outFitMedium500(
                              color: theme.accent, fontSize: 14)),
                    ),
                  ],
                ),
              );
            },
            icon: Icon(Icons.help_outline, color: theme.accent, size: 22),
          ),
        ],
      ),
    );
  }
}

class _TypeTabs extends StatelessWidget {
  const _TypeTabs({required this.controller});

  final LeaderboardController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final tab = controller.tab.value;
      final activeColor = ColorRes.themeAccentSolid;
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 48),
        child: Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: const Color(0xFF0A0A0C),
            borderRadius: BorderRadius.circular(26),
          ),
          child: Row(
            children: [
              Expanded(
                child: _TypeTabChip(
                  label: LKey.clientsRanking.tr,
                  selected: tab == LeaderboardTab.clients,
                  activeColor: activeColor,
                  onTap: () => controller.setTab(LeaderboardTab.clients),
                ),
              ),
              Expanded(
                child: _TypeTabChip(
                  label: LKey.streamersRanking.tr,
                  selected: tab == LeaderboardTab.streamers,
                  activeColor: activeColor,
                  onTap: () => controller.setTab(LeaderboardTab.streamers),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}

class _TypeTabChip extends StatelessWidget {
  const _TypeTabChip({
    required this.label,
    required this.selected,
    required this.activeColor,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color activeColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? activeColor : Colors.transparent,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: selected ? Colors.white : Colors.transparent,
            width: selected ? 1.5 : 0,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: activeColor.withValues(alpha: 0.55),
                    blurRadius: 12,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              textAlign: TextAlign.center,
              style: selected
                  ? TextStyleCustom.outFitBold700(
                      color: Colors.white,
                      fontSize: 13,
                    )
                  : TextStyleCustom.outFitMedium500(
                      color: Colors.white54,
                      fontSize: 13,
                    ),
            ),
            if (selected)
              const Icon(Icons.arrow_drop_down, color: Colors.white, size: 16),
          ],
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.label,
    required this.selected,
    required this.active,
    this.activeGradient,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color active;
  final List<Color>? activeGradient;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final useGradient =
        selected && activeGradient != null && activeGradient!.length >= 2;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected && !useGradient ? active : Colors.transparent,
          gradient: useGradient ? LinearGradient(colors: activeGradient!) : null,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: selected
              ? TextStyleCustom.outFitBold700(
                  color: Colors.white,
                  fontSize: 13)
              : TextStyleCustom.outFitMedium500(
                  color: Colors.white60, fontSize: 13),
        ),
      ),
    );
  }
}

class _PeriodFilters extends StatelessWidget {
  const _PeriodFilters({required this.controller, required this.theme});

  final LeaderboardController controller;
  final _LbTheme theme;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final p = controller.period.value;
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            Expanded(
              child: _PeriodChip(
                label: LKey.today.tr,
                selected: p == LeaderboardPeriod.today,
                theme: theme,
                onTap: () => controller.setPeriod(LeaderboardPeriod.today),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _PeriodChip(
                label: LKey.thisWeek.tr,
                selected: p == LeaderboardPeriod.week,
                theme: theme,
                onTap: () => controller.setPeriod(LeaderboardPeriod.week),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _PeriodChip(
                label: LKey.thisMonth.tr,
                selected: p == LeaderboardPeriod.month,
                theme: theme,
                onTap: () => controller.setPeriod(LeaderboardPeriod.month),
              ),
            ),
          ],
        ),
      );
    });
  }
}

class _PeriodChip extends StatelessWidget {
  const _PeriodChip({
    required this.label,
    required this.selected,
    required this.theme,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final _LbTheme theme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          gradient: selected
              ? LinearGradient(
                  colors: [theme.periodActive, theme.periodActive.withValues(alpha: 0.75)],
                )
              : null,
          color: selected ? null : theme.periodInactive.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? theme.accent.withValues(alpha: 0.6) : Colors.white12,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: theme.periodActive.withValues(alpha: 0.45),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyleCustom.outFitMedium500(
                color: Colors.white,
                fontSize: 12,
              ),
            ),
            if (selected)
              const Icon(Icons.arrow_drop_down, color: Colors.white, size: 16),
          ],
        ),
      ),
    );
  }
}

class _Podium extends StatelessWidget {
  const _Podium({required this.users, required this.theme});

  final List<LeaderboardEntry> users;
  final _LbTheme theme;

  LeaderboardEntry? _at(int rank) {
    for (final u in users) {
      if ((u.rank ?? 0) == rank) return u;
    }
    if (users.length >= rank) return users[rank - 1];
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final first = _at(1);
    final second = _at(2);
    final third = _at(3);
    if (first == null && second == null && third == null) {
      return const SizedBox(height: 12);
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 16, 8, 4),
      child: SizedBox(
        height: 320,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: _PodiumSlot(
                entry: second,
                place: 2,
                height: 230,
                colors: theme.podium2,
                theme: theme,
              ),
            ),
            Expanded(
              child: _PodiumSlot(
                entry: first,
                place: 1,
                height: 280,
                colors: theme.podium1,
                theme: theme,
              ),
            ),
            Expanded(
              child: _PodiumSlot(
                entry: third,
                place: 3,
                height: 210,
                colors: theme.podium3,
                theme: theme,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PodiumSlot extends StatelessWidget {
  const _PodiumSlot({
    required this.entry,
    required this.place,
    required this.height,
    required this.colors,
    required this.theme,
  });

  final LeaderboardEntry? entry;
  final int place;
  final double height;
  final List<Color> colors;
  final _LbTheme theme;

  @override
  Widget build(BuildContext context) {
    if (entry == null) return SizedBox(height: height);

    return SizedBox(
      height: height,
      child: Column(
        children: [
          _RankFigure(
            entry: entry!,
            place: place,
            size: place == 1 ? 110.0 : 92.0,
            showTopBadge: true,
          ),
          const SizedBox(height: 6),
          Expanded(
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.fromLTRB(6, 8, 6, 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: colors,
                ),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(18)),
                border: Border.all(color: Colors.white24),
                boxShadow: [
                  BoxShadow(
                    color: colors.last.withValues(alpha: 0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        entry!.displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: TextStyleCustom.outFitMedium500(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (entry!.isSvip == 1) ...[
                            Text(
                              'SVIP',
                              style: TextStyleCustom.outFitBold700(
                                color: theme.accent,
                                fontSize: 9,
                              ),
                            ),
                            const SizedBox(width: 4),
                          ],
                          Text(
                            'Lv.${entry!.levelNumber}',
                            style: TextStyleCustom.outFitRegular400(
                              color: Colors.white70,
                              fontSize: 10,
                            ),
                          ),
                          if ((entry!.countryCode ?? '').isNotEmpty) ...[
                            const SizedBox(width: 4),
                            Text(
                              _flagEmoji(entry!.countryCode!),
                              style: const TextStyle(fontSize: 11),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.local_fire_department,
                          color: Color(0xFFFFB347), size: 14),
                      const SizedBox(width: 2),
                      Flexible(
                        child: Text(
                          entry!.score.numberFormat,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyleCustom.outFitBold700(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Avatar centrado en el hueco circular de cada figura/badge.
class _RankFigure extends StatelessWidget {
  const _RankFigure({
    required this.entry,
    required this.place,
    required this.size,
    this.showTopBadge = false,
    this.showFrame = true,
  });

  final LeaderboardEntry entry;
  final int place;
  final double size;
  final bool showTopBadge;
  /// Marcos ornamentados solo para TOP 1–3.
  final bool showFrame;

  static String frameFor(int place) {
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

  /// Ratio del círculo de foto respecto al asset.
  /// El hueco del PNG es ~0.64–0.72 del lado; la foto debe llenarlo.
  static double _avatarRatio(int place) {
    switch (place) {
      case 1:
        return 0.66; // marco dorado
      case 2:
        return 0.70; // marco coral
      case 3:
        return 0.62; // anillo plateado más fino
      default:
        return 0.68;
    }
  }

  /// Ajuste fino: el hueco no siempre coincide con el centro geométrico del PNG.
  static Offset _avatarOffset(int place, double size) {
    switch (place) {
      case 1:
        // Corona arriba → el círculo queda un poco más abajo
        return Offset(0, size * 0.04);
      case 2:
        return Offset(0, size * 0.02);
      case 3:
        // Máscara / laurel abajo → subir un poco la foto
        return Offset(0, size * -0.04);
      default:
        return Offset.zero;
    }
  }

  static Color _ringColor(int place) {
    switch (place) {
      case 1:
        return const Color(0xFFFFD56B);
      case 2:
        return const Color(0xFFFF8A5C);
      case 3:
        return const Color(0xFFC5D4E8);
      default:
        return Colors.white54;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Lista (4º+): solo avatar circular, sin marco.
    if (!showFrame || place > 3) {
      final avatarSize = size * 0.72;
      return SizedBox(
        width: size,
        height: size,
        child: Center(
          child: ClipOval(
            child: CustomImage(
              size: Size(avatarSize, avatarSize),
              image: entry.profilePhoto?.addBaseURL(),
              fullName: entry.displayName,
              strokeWidth: 0,
              fit: BoxFit.cover,
            ),
          ),
        ),
      );
    }

    final ratio = _avatarRatio(place);
    final avatarSize = size * ratio;
    final offset = _avatarOffset(place, size);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              Transform.translate(
                offset: offset,
                child: Container(
                  width: avatarSize,
                  height: avatarSize,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _ringColor(place),
                      width: place == 1 ? 2.5 : 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _ringColor(place).withValues(alpha: 0.45),
                        blurRadius: 10,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: CustomImage(
                      size: Size(avatarSize - 4, avatarSize - 4),
                      image: entry.profilePhoto?.addBaseURL(),
                      fullName: entry.displayName,
                      strokeWidth: 0,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              IgnorePointer(
                child: Image.asset(
                  frameFor(place),
                  width: size,
                  height: size,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                  gaplessPlayback: true,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
            ],
          ),
        ),
        if (showTopBadge && place <= 3) ...[
          const SizedBox(height: 2),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.75),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFFFD56B), width: 1),
            ),
            child: Text(
              '${LKey.top.tr} $place',
              style: TextStyleCustom.outFitBold700(
                color: Colors.white,
                fontSize: 10,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _RankRow extends StatelessWidget {
  const _RankRow({required this.entry});

  final LeaderboardEntry entry;

  @override
  Widget build(BuildContext context) {
    final place = entry.rank ?? 4;
    // Del 4º en adelante: sin caja/borde, solo fila sobre el fondo.
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text(
              '$place',
              style: TextStyleCustom.unboundedBold700(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
          ),
          _RankFigure(
            entry: entry,
            place: place,
            size: 48,
            showFrame: false,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        entry.displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyleCustom.outFitMedium500(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    if ((entry.countryCode ?? '').isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Text(
                        _flagEmoji(entry.countryCode!),
                        style: const TextStyle(fontSize: 13),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${LKey.level.tr} ${entry.levelNumber}'
                  '${entry.isSvip == 1 ? ' · ${LKey.svip.tr}' : ''}',
                  style: TextStyleCustom.outFitRegular400(
                    color: Colors.white60,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.local_fire_department,
              color: Color(0xFFFFB347), size: 16),
          const SizedBox(width: 4),
          Text(
            entry.score.numberFormat,
            style: TextStyleCustom.outFitMedium500(
              color: Colors.white,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _MyRankBar extends StatelessWidget {
  const _MyRankBar({required this.me, required this.theme});

  final LeaderboardEntry me;
  final _LbTheme theme;

  @override
  Widget build(BuildContext context) {
    final ranked = me.rank != null && me.rank! > 0;
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        10,
        16,
        10 + MediaQuery.paddingOf(context).bottom,
      ),
      decoration: BoxDecoration(
        color: theme.bg.withValues(alpha: 0.95),
        border: Border(top: BorderSide(color: theme.accent.withValues(alpha: 0.35))),
      ),
      child: Row(
        children: [
          _RankFigure(
            entry: me,
            place: me.rank ?? 4,
            size: 48,
            showFrame: (me.rank ?? 99) <= 3,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    me.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyleCustom.outFitMedium500(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ),
                if ((me.countryCode ?? '').isNotEmpty) ...[
                  const SizedBox(width: 6),
                  Text(
                    _flagEmoji(me.countryCode!),
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ],
            ),
          ),
          Text(
            ranked ? '#${me.rank}' : LKey.notRanked.tr,
            style: TextStyleCustom.outFitBold700(
              color: theme.accent,
              fontSize: 13,
            ),
          ),
          if (ranked) ...[
            const SizedBox(width: 8),
            const Icon(Icons.local_fire_department,
                color: Color(0xFFFFB347), size: 14),
            const SizedBox(width: 2),
            Text(
              me.score.numberFormat,
              style: TextStyleCustom.outFitMedium500(
                color: Colors.white,
                fontSize: 13,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

String _flagEmoji(String code) {
  final c = code.trim().toUpperCase();
  if (c.length != 2) return '';
  final a = c.codeUnitAt(0);
  final b = c.codeUnitAt(1);
  if (a < 65 || a > 90 || b < 65 || b > 90) return '';
  return String.fromCharCodes([0x1F1E6 + (a - 65), 0x1F1E6 + (b - 65)]);
}
