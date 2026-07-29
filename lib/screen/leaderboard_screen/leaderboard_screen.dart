import 'dart:math' as math;
import 'dart:ui' as ui;

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
import 'package:krimson/utilities/text_style_custom.dart';

/// Ranking Giver / Receiver — podio épico estilo arena real.
class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(LeaderboardController());

    return Scaffold(
      backgroundColor: _Epic.voidBg,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const Positioned.fill(child: _ArenaBackdrop()),
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                const _Header(),
                const SizedBox(height: 6),
                _TypeTabs(controller: controller),
                const SizedBox(height: 8),
                Obx(() => Text(
                      '${LKey.endsIn.tr} ${controller.countdown.value}',
                      style: TextStyleCustom.outFitMedium500(
                        color: _Epic.gold.withValues(alpha: 0.9),
                        fontSize: 12,
                      ),
                    )),
                const SizedBox(height: 8),
                _PeriodFilters(controller: controller),
                const SizedBox(height: 8),
                Expanded(
                  child: Obx(() {
                    if (controller.isLoading.value &&
                        controller.users.isEmpty) {
                      return const LoaderWidget();
                    }
                    if (controller.users.isEmpty) {
                      return NoDataView(
                        showShow: true,
                        title: LKey.leaderboard.tr,
                        description: LKey.noData.tr,
                      );
                    }
                    final restCount = controller.users.length > 3
                        ? controller.users.length - 3
                        : 0;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Podio fijo, altura natural, sin overflow
                        Material(
                          type: MaterialType.transparency,
                          child: _PodiumStage(users: controller.users),
                        ),
                        const SizedBox(height: 10),
                        // Lista opaca: nada del podio se ve a través
                        Expanded(
                          child: ColoredBox(
                            color: const Color(0xFF0A040C),
                            child: ListView.separated(
                              physics: const BouncingScrollPhysics(),
                              padding:
                                  const EdgeInsets.fromLTRB(14, 4, 14, 16),
                              itemCount: restCount,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 10),
                              itemBuilder: (context, index) {
                                return _RankRow(
                                  entry: controller.users[index + 3],
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    );
                  }),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: Obx(() {
        final me = controller.me.value;
        if (me == null) return const SizedBox.shrink();
        return _MyRankBar(me: me);
      }),
    );
  }
}

abstract final class _Epic {
  static const voidBg = Color(0xFF07030A);
  static const gold = Color(0xFFFFD56B);
  static const crimson = Color(0xFFE53935);
  static const crimsonDeep = Color(0xFF8B0000);
  static const tabDark = Color(0xFF241428);
  static const tabText = Color(0xFFB71C1C);
  static const periodOff = Color(0xFF2A1630);

  static const place1 = [Color(0xFFFF3B3B), Color(0xFF8B0000)];
  static const place2 = [Color(0xFF4FA3FF), Color(0xFF153A8C)];
  static const place3 = [Color(0xFFB06BFF), Color(0xFF4A1878)];
}

// ───────────────────────────────────────────── Header / tabs / periods

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 2, 4, 0),
      child: Row(
        children: [
          IconButton(
            onPressed: Get.back,
            icon: const Icon(Icons.arrow_back_ios_new,
                color: Colors.white, size: 20),
          ),
          Expanded(
            child: ShaderMask(
              shaderCallback: (b) => const LinearGradient(
                colors: [Color(0xFFFFF1C1), Color(0xFFFFD56B), Color(0xFFFFB020)],
              ).createShader(b),
              child: Text(
                LKey.leaderboard.tr,
                textAlign: TextAlign.center,
                style: TextStyleCustom.unboundedBold700(
                  color: Colors.white,
                  fontSize: 19,
                ),
              ),
            ),
          ),
          IconButton(
            onPressed: () {
              Get.dialog(
                AlertDialog(
                  backgroundColor: _Epic.voidBg,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: _Epic.gold.withValues(alpha: 0.5)),
                  ),
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
                      child: Text(
                        LKey.continueText.tr,
                        style: TextStyleCustom.outFitMedium500(
                            color: _Epic.gold, fontSize: 14),
                      ),
                    ),
                  ],
                ),
              );
            },
            icon: const Icon(Icons.help_outline, color: _Epic.gold, size: 22),
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
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: const Color(0xFF120814),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: _Epic.gold.withValues(alpha: 0.4)),
            boxShadow: [
              BoxShadow(
                color: _Epic.gold.withValues(alpha: 0.2),
                blurRadius: 16,
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: _TypeChip(
                  label: LKey.clientsRanking.tr,
                  selected: tab == LeaderboardTab.clients,
                  onTap: () => controller.setTab(LeaderboardTab.clients),
                ),
              ),
              Expanded(
                child: _TypeChip(
                  label: LKey.streamersRanking.tr,
                  selected: tab == LeaderboardTab.streamers,
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

class _TypeChip extends StatelessWidget {
  const _TypeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 4),
        decoration: BoxDecoration(
          gradient: selected
              ? const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFFFF9FF), Color(0xFFE9D4F8)],
                )
              : null,
          color: selected ? null : _Epic.tabDark,
          borderRadius: BorderRadius.circular(24),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: _Epic.crimson.withValues(alpha: 0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: selected
              ? TextStyleCustom.outFitBold700(
                  color: _Epic.tabText, fontSize: 12)
              : TextStyleCustom.outFitMedium500(
                  color: Colors.white, fontSize: 12),
        ),
      ),
    );
  }
}

class _PeriodFilters extends StatelessWidget {
  const _PeriodFilters({required this.controller});

  final LeaderboardController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final p = controller.period.value;
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Expanded(
              child: _PeriodChip(
                label: LKey.today.tr,
                selected: p == LeaderboardPeriod.today,
                onTap: () => controller.setPeriod(LeaderboardPeriod.today),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _PeriodChip(
                label: LKey.thisWeek.tr,
                selected: p == LeaderboardPeriod.week,
                onTap: () => controller.setPeriod(LeaderboardPeriod.week),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _PeriodChip(
                label: LKey.thisMonth.tr,
                selected: p == LeaderboardPeriod.month,
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
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.fromLTRB(4, 8, 4, 4),
        decoration: BoxDecoration(
          gradient: selected
              ? const LinearGradient(
                  colors: [_Epic.crimson, _Epic.crimsonDeep],
                )
              : null,
          color: selected ? null : _Epic.periodOff,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected
                ? _Epic.gold.withValues(alpha: 0.75)
                : Colors.white.withValues(alpha: 0.08),
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: _Epic.crimson.withValues(alpha: 0.55),
                    blurRadius: 14,
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
            Icon(
              Icons.arrow_drop_down,
              color: selected ? _Epic.gold : _Epic.crimson,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}

// ───────────────────────────────────────────── Epic arena background

class _ArenaBackdrop extends StatelessWidget {
  const _ArenaBackdrop();

  @override
  Widget build(BuildContext context) {
    return const CustomPaint(
      painter: _ArenaPainter(),
      child: SizedBox.expand(),
    );
  }
}

class _ArenaPainter extends CustomPainter {
  const _ArenaPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Base void → royal crimson
    final base = Paint()
      ..shader = ui.Gradient.linear(
        Offset(w * 0.5, 0),
        Offset(w * 0.5, h),
        const [
          Color(0xFF3A0A28),
          Color(0xFF1A0618),
          Color(0xFF0A040C),
          Color(0xFF050208),
        ],
        const [0, 0.28, 0.62, 1],
      );
    canvas.drawRect(Offset.zero & size, base);

    // Ceiling vignette glow
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h * 0.45),
      Paint()
        ..shader = ui.Gradient.radial(
          Offset(w * 0.5, h * 0.08),
          w * 0.75,
          [
            _Epic.gold.withValues(alpha: 0.22),
            const Color(0x66C62828),
            const Color(0x00000000),
          ],
          const [0, 0.35, 1],
        ),
    );

    // Heavy curtains (left / right)
    _drawCurtain(canvas, size, left: true);
    _drawCurtain(canvas, size, left: false);

    // Golden pillars
    _drawPillar(canvas, size, x: w * 0.06);
    _drawPillar(canvas, size, x: w * 0.94);

    // Triple golden arches
    for (final t in [0.0, 0.08, 0.16]) {
      final path = Path()
        ..moveTo(w * (0.05 + t * 0.3), h * (0.42 + t * 0.4))
        ..quadraticBezierTo(
          w * 0.5,
          h * (-0.02 + t * 0.15),
          w * (0.95 - t * 0.3),
          h * (0.42 + t * 0.4),
        );
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.4 - t * 6
          ..color = _Epic.gold.withValues(alpha: 0.5 - t)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5),
      );
    }

    // Ornate filigree bar under arches
    final barY = h * 0.18;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
            center: Offset(w * 0.5, barY), width: w * 0.55, height: 4),
        const Radius.circular(2),
      ),
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(w * 0.22, barY),
          Offset(w * 0.78, barY),
          [
            _Epic.gold.withValues(alpha: 0),
            _Epic.gold.withValues(alpha: 0.75),
            _Epic.gold.withValues(alpha: 0),
          ],
        ),
    );

    // Central spotlight beam
    final beam = Path()
      ..moveTo(w * 0.44, 0)
      ..lineTo(w * 0.56, 0)
      ..lineTo(w * 0.78, h * 0.55)
      ..lineTo(w * 0.22, h * 0.55)
      ..close();
    canvas.drawPath(
      beam,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(w * 0.5, 0),
          Offset(w * 0.5, h * 0.55),
          [
            _Epic.gold.withValues(alpha: 0.28),
            _Epic.gold.withValues(alpha: 0.08),
            _Epic.gold.withValues(alpha: 0),
          ],
        ),
    );

    // Side soft beams
    for (final cx in [0.28, 0.72]) {
      final p = Path()
        ..moveTo(w * (cx - 0.03), 0)
        ..lineTo(w * (cx + 0.03), 0)
        ..lineTo(w * (cx + 0.12), h * 0.5)
        ..lineTo(w * (cx - 0.12), h * 0.5)
        ..close();
      canvas.drawPath(
        p,
        Paint()
          ..shader = ui.Gradient.linear(
            Offset(w * cx, 0),
            Offset(w * cx, h * 0.5),
            [
              Colors.white.withValues(alpha: 0.08),
              Colors.transparent,
            ],
          ),
      );
    }

    // Embers / floating sparks
    final rng = math.Random(42);
    for (var i = 0; i < 48; i++) {
      final px = rng.nextDouble() * w;
      final py = rng.nextDouble() * h * 0.7;
      final r = 0.6 + rng.nextDouble() * 1.8;
      final a = 0.15 + rng.nextDouble() * 0.55;
      canvas.drawCircle(
        Offset(px, py),
        r,
        Paint()
          ..color = (i.isEven ? _Epic.gold : const Color(0xFFFF8A50))
              .withValues(alpha: a)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
      );
    }

    // Stage floor glow
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.5, h * 0.52),
        width: w * 1.1,
        height: h * 0.18,
      ),
      Paint()
        ..shader = ui.Gradient.radial(
          Offset(w * 0.5, h * 0.52),
          w * 0.55,
          [
            _Epic.gold.withValues(alpha: 0.2),
            _Epic.crimson.withValues(alpha: 0.08),
            Colors.transparent,
          ],
        ),
    );
  }

  void _drawCurtain(Canvas canvas, Size size, {required bool left}) {
    final w = size.width;
    final h = size.height;
    final folds = 5;
    for (var i = 0; i < folds; i++) {
      final t = i / folds;
      final x0 = left ? w * (0.0 + t * 0.18) : w * (1.0 - t * 0.18);
      final x1 = left ? w * (0.04 + t * 0.18) : w * (0.96 - t * 0.18);
      final path = Path()
        ..moveTo(x0, 0)
        ..quadraticBezierTo(
          (x0 + x1) / 2 + (left ? 8 : -8),
          h * 0.25,
          x0,
          h * 0.55,
        )
        ..lineTo(x1, h * 0.58)
        ..quadraticBezierTo(
          (x0 + x1) / 2 + (left ? 10 : -10),
          h * 0.25,
          x1,
          0,
        )
        ..close();
      canvas.drawPath(
        path,
        Paint()
          ..shader = ui.Gradient.linear(
            Offset(x0, 0),
            Offset(x1, h * 0.5),
            [
              Color.lerp(
                const Color(0xFF8B1018),
                const Color(0xFF4A0810),
                t,
              )!
                  .withValues(alpha: 0.75 - t * 0.35),
              const Color(0x004A0810),
            ],
          ),
      );
    }
  }

  void _drawPillar(Canvas canvas, Size size, {required double x}) {
    final h = size.height;
    final rect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(x, h * 0.28), width: 8, height: h * 0.5),
      const Radius.circular(4),
    );
    canvas.drawRRect(
      rect,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(x, 0),
          Offset(x, h * 0.55),
          [
            _Epic.gold.withValues(alpha: 0.85),
            _Epic.gold.withValues(alpha: 0.35),
            _Epic.gold.withValues(alpha: 0.05),
          ],
        ),
    );
    // Capital
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(x, h * 0.06), width: 18, height: 10),
        const Radius.circular(3),
      ),
      Paint()..color = _Epic.gold.withValues(alpha: 0.7),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ───────────────────────────────────────────── Podium (compacto, sin overflow)

class _PodiumStage extends StatelessWidget {
  const _PodiumStage({required this.users});

  final List<LeaderboardEntry> users;

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
      return const SizedBox.shrink();
    }

    // Altura NATURAL — sin SizedBox fijo ni CrossAxisAlignment.end
    // (eso causaba el hueco vacío + solape con la lista).
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: _ChampionCard(
              entry: second,
              place: 2,
              colors: _Epic.place2,
              accent: const Color(0xFFFF8A5C),
              figureSize: 78,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _ChampionCard(
              entry: first,
              place: 1,
              colors: _Epic.place1,
              accent: _Epic.gold,
              figureSize: 96,
              elevated: true,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _ChampionCard(
              entry: third,
              place: 3,
              colors: _Epic.place3,
              accent: const Color(0xFF7EB6FF),
              figureSize: 78,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChampionCard extends StatelessWidget {
  const _ChampionCard({
    required this.entry,
    required this.place,
    required this.colors,
    required this.accent,
    required this.figureSize,
    this.elevated = false,
  });

  final LeaderboardEntry? entry;
  final int place;
  final List<Color> colors;
  final Color accent;
  final double figureSize;
  final bool elevated;

  @override
  Widget build(BuildContext context) {
    if (entry == null) return const SizedBox.shrink();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Extra top only for #1 crown spacing
        if (elevated) const SizedBox(height: 14),
        Center(
          child: SizedBox(
            width: figureSize,
            height: figureSize,
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.hardEdge,
              children: [
                _RankFigure(
                  entry: entry!,
                  place: place,
                  size: figureSize,
                ),
                if (place == 1)
                  const Positioned(
                    top: 0,
                    child: Icon(
                      Icons.workspace_premium,
                      color: _Epic.gold,
                      size: 18,
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 4),
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: accent, width: 1),
            ),
            child: Text(
              '${LKey.top.tr} $place',
              style: TextStyleCustom.outFitBold700(
                color: Colors.white,
                fontSize: 9,
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [colors.first, colors.last],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: place == 1 ? _Epic.gold : accent.withValues(alpha: 0.85),
              width: place == 1 ? 1.6 : 1.2,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                entry!.displayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyleCustom.outFitBold700(
                  color: Colors.white,
                  fontSize: elevated ? 12 : 11,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                entry!.isSvip == 1
                    ? 'SVIP Lv.${entry!.levelNumber}'
                    : 'Lv.${entry!.levelNumber}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyleCustom.outFitMedium500(
                  color: entry!.isSvip == 1 ? _Epic.gold : Colors.white70,
                  fontSize: 10,
                ),
              ),
              const SizedBox(height: 3),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.local_fire_department,
                    color: place == 1 ? _Epic.gold : const Color(0xFFFFB347),
                    size: 13,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    entry!.score.numberFormat,
                    style: TextStyleCustom.outFitBold700(
                      color: Colors.white,
                      fontSize: elevated ? 12 : 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ───────────────────────────────────────────── Avatar figure

class _RankFigure extends StatelessWidget {
  const _RankFigure({
    required this.entry,
    required this.place,
    required this.size,
    this.showFrame = true,
  });

  final LeaderboardEntry entry;
  final int place;
  final double size;
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

  /// Ratio del hueco central del PNG (centrado, sin offset).
  static double _avatarRatio(int place) {
    switch (place) {
      case 1:
        return 0.56;
      case 2:
        return 0.58;
      case 3:
        return 0.56;
      default:
        return 0.72;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!showFrame || place > 3) {
      return SizedBox(
        width: size,
        height: size,
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: _Epic.gold.withValues(alpha: 0.7),
              width: 1.5,
            ),
          ),
          child: ClipOval(
            child: CustomImage(
              size: Size(size, size),
              image: entry.profilePhoto?.addBaseURL(),
              fullName: entry.displayName,
              strokeWidth: 0,
              fit: BoxFit.cover,
            ),
          ),
        ),
      );
    }

    final avatarSize = size * _avatarRatio(place);

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          ClipOval(
            child: CustomImage(
              size: Size(avatarSize, avatarSize),
              image: entry.profilePhoto?.addBaseURL(),
              fullName: entry.displayName,
              strokeWidth: 0,
              fit: BoxFit.cover,
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
    );
  }
}

// ───────────────────────────────────────────── List rows (arena cards)

class _RankRow extends StatelessWidget {
  const _RankRow({required this.entry});

  final LeaderboardEntry entry;

  @override
  Widget build(BuildContext context) {
    final place = entry.rank ?? 4;
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Color(0xFF3A1A14),
            Color(0xFF5A2A18),
            Color(0xFF3A1A14),
          ],
        ),
        border: Border.all(
          color: _Epic.gold.withValues(alpha: 0.5),
          width: 1.2,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 26,
            child: Text(
              '$place',
              textAlign: TextAlign.center,
              style: TextStyleCustom.unboundedBold700(
                color: _Epic.gold,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 8),
          _RankFigure(
            entry: entry,
            place: place,
            size: 42,
            showFrame: false,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyleCustom.outFitMedium500(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${LKey.level.tr} ${entry.levelNumber}'
                  '${entry.isSvip == 1 ? ' · ${LKey.svip.tr}' : ''}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyleCustom.outFitRegular400(
                    color: Colors.white60,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          const Icon(Icons.local_fire_department,
              color: Color(0xFFFFB347), size: 15),
          const SizedBox(width: 3),
          Text(
            entry.score.numberFormat,
            style: TextStyleCustom.outFitBold700(
              color: Colors.white,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

// ───────────────────────────────────────────── My rank bar

class _MyRankBar extends StatelessWidget {
  const _MyRankBar({required this.me});

  final LeaderboardEntry me;

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
        gradient: const LinearGradient(
          colors: [Color(0xFF3A2210), Color(0xFF1A1008)],
        ),
        border: Border(
          top: BorderSide(color: _Epic.gold.withValues(alpha: 0.55), width: 1.4),
        ),
        boxShadow: [
          BoxShadow(
            color: _Epic.gold.withValues(alpha: 0.2),
            blurRadius: 18,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          _RankFigure(
            entry: me,
            place: me.rank ?? 4,
            size: 46,
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
                const SizedBox(width: 6),
                Text(
                  'Lv.${me.levelNumber}',
                  style: TextStyleCustom.outFitRegular400(
                    color: Colors.white60,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Text(
            ranked ? '#${me.rank}' : LKey.notRanked.tr,
            style: TextStyleCustom.outFitBold700(
              color: _Epic.gold,
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
