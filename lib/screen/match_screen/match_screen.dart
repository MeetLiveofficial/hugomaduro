import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krimson/screen/match_screen/match_screen_controller.dart';
import 'package:krimson/utilities/asset_res.dart';
import 'package:krimson/utilities/color_res.dart';
import 'package:krimson/utilities/text_style_custom.dart';

/// Vista Match (Cliente): radar de búsqueda + modos Random / Goddess.
class MatchScreen extends StatelessWidget {
  const MatchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.put(MatchScreenController());
    return Scaffold(
      backgroundColor: const Color(0xFF1A1220),
      body: Stack(
        fit: StackFit.expand,
        children: [
          const _MatchBackdrop(),
          SafeArea(
            child: Padding(
              // Espacio para la bottom nav flotante.
              padding: const EdgeInsets.only(bottom: 72),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final radar = (constraints.maxHeight * 0.36)
                      .clamp(150.0, 240.0);
                  return Column(
                    children: [
                      _TopBar(controller: c),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _RadarButton(controller: c, size: radar),
                            SizedBox(height: radar < 180 ? 10 : 14),
                            Obx(() {
                              final busy = c.isMatching.value;
                              return Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 24),
                                child: Text(
                                  busy
                                      ? 'Buscando coincidencia…'
                                      : 'Haga clic para hacer coincidir',
                                  textAlign: TextAlign.center,
                                  style: TextStyleCustom.outFitMedium500(
                                    color: Colors.white,
                                    fontSize: 15,
                                  ),
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                      _MembershipBanner(controller: c),
                      const SizedBox(height: 10),
                      _ModeRow(controller: c),
                      const SizedBox(height: 4),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MatchBackdrop extends StatelessWidget {
  const _MatchBackdrop();

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF2A1A28),
                Color(0xFF1A1220),
                Color(0xFF120E18),
              ],
            ),
          ),
        ),
        // Halo suave detrás del radar.
        Align(
          alignment: const Alignment(0, -0.15),
          child: Container(
            width: 320,
            height: 320,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  ColorRes.themeAccentSolid.withValues(alpha: 0.28),
                  ColorRes.themeAccentSolid.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ),
        // Viñeta inferior para los controles.
        const Align(
          alignment: Alignment.bottomCenter,
          child: IgnorePointer(
            child: SizedBox(
              height: 280,
              width: double.infinity,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Color(0xCC0A0610)],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _TopBar extends StatelessWidget {
  final MatchScreenController controller;

  const _TopBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
      child: Row(
        children: [
          _ChipButton(
            onTap: controller.openWallet,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(AssetRes.icStar, width: 16, height: 16),
                const SizedBox(width: 6),
                Text(
                  '${controller.walletCoins}',
                  style: TextStyleCustom.outFitSemiBold600(
                    color: Colors.white,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          _ChipButton(
            onTap: controller.openMembership,
            borderColor: const Color(0xFFD4AF37),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(AssetRes.icPro, width: 16, height: 16),
                const SizedBox(width: 6),
                Text(
                  'Membership',
                  style: TextStyleCustom.outFitMedium500(
                    color: const Color(0xFFE8D48B),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChipButton extends StatelessWidget {
  final Widget child;
  final VoidCallback onTap;
  final Color? borderColor;

  const _ChipButton({
    required this.child,
    required this.onTap,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.45),
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: borderColor ?? Colors.white24,
              width: 1,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _RadarButton extends StatelessWidget {
  final MatchScreenController controller;
  final double size;

  const _RadarButton({
    required this.controller,
    this.size = 240,
  });

  @override
  Widget build(BuildContext context) {
    final core = (size * 0.30).clamp(56.0, 78.0);
    final iconSize = (core * 0.44).clamp(24.0, 34.0);
    return GestureDetector(
      onTap: controller.startMatch,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: size,
        height: size,
        child: RepaintBoundary(
          child: AnimatedBuilder(
            animation: controller.pulseController,
            child: Center(
              child: Obx(() {
                final busy = controller.isMatching.value;
                return Container(
                  width: core,
                  height: core,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black.withValues(alpha: 0.35),
                    border: Border.all(
                      color: ColorRes.themeAccentSolid.withValues(alpha: 0.9),
                      width: 2,
                    ),
                  ),
                  child: busy
                      ? Padding(
                          padding: EdgeInsets.all(core * 0.28),
                          child: const CircularProgressIndicator(
                            strokeWidth: 2.4,
                            color: Colors.white,
                          ),
                        )
                      : Icon(
                          Icons.touch_app_rounded,
                          color: Colors.white,
                          size: iconSize,
                        ),
                );
              }),
            ),
            builder: (context, child) {
              return CustomPaint(
                painter: _RadarPainter(
                  progress: controller.pulseController.value,
                  accent: ColorRes.themeAccentSolid,
                ),
                child: child,
              );
            },
          ),
        ),
      ),
    );
  }
}

class _RadarPainter extends CustomPainter {
  final double progress;
  final Color accent;

  _RadarPainter({required this.progress, required this.accent});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxR = size.shortestSide / 2;

    for (var i = 0; i < 2; i++) {
      final phase = (progress + i / 2) % 1.0;
      final radius = maxR * (0.30 + phase * 0.68);
      final opacity = (1.0 - phase).clamp(0.0, 1.0);
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..color = accent.withValues(alpha: 0.12 + opacity * 0.42);
      canvas.drawCircle(center, radius, paint);
    }

    // Anillo fijo interno.
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = accent.withValues(alpha: 0.35);
    canvas.drawCircle(center, maxR * 0.32, ring);
  }

  @override
  bool shouldRepaint(covariant _RadarPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.accent != accent;
}

class _MembershipBanner extends StatelessWidget {
  final MatchScreenController controller;

  const _MembershipBanner({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Material(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: controller.openMembership,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0x66D4AF37)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(AssetRes.icPro, width: 18, height: 18),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    controller.isPlusMember
                        ? 'Membership activa'
                        : 'Membership  ★  ${controller.membershipHintCost}/match',
                    textAlign: TextAlign.center,
                    style: TextStyleCustom.outFitMedium500(
                      color: const Color(0xFFE8D48B),
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ModeRow extends StatelessWidget {
  final MatchScreenController controller;

  const _ModeRow({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Obx(() {
        final selected = controller.mode.value;
        return Row(
          children: [
            Expanded(
              child: _ModeCard(
                title: 'Random',
                cost: controller.randomHintCost,
                selected: selected == MatchSearchMode.random,
                premium: false,
                onTap: () => controller.selectMode(MatchSearchMode.random),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _ModeCard(
                title: 'Goddess',
                cost: controller.goddessHintCost,
                selected: selected == MatchSearchMode.goddess,
                premium: true,
                onTap: () => controller.selectMode(MatchSearchMode.goddess),
              ),
            ),
          ],
        );
      }),
    );
  }
}

class _ModeCard extends StatelessWidget {
  final String title;
  final int cost;
  final bool selected;
  final bool premium;
  final VoidCallback onTap;

  const _ModeCard({
    required this.title,
    required this.cost,
    required this.selected,
    required this.premium,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: selected ? 0.62 : 0.42),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected
                  ? ColorRes.themeAccentSolid.withValues(alpha: 0.85)
                  : Colors.white24,
              width: selected ? 1.4 : 1,
            ),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Row(
                children: [
                  Icon(
                    selected
                        ? Icons.radio_button_checked_rounded
                        : Icons.radio_button_off_rounded,
                    color: selected
                        ? ColorRes.themeAccentSolid
                        : Colors.white54,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyleCustom.outFitSemiBold600(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Image.asset(AssetRes.icStar,
                                width: 12, height: 12),
                            const SizedBox(width: 4),
                            Text(
                              '$cost/match',
                              style: TextStyleCustom.outFitRegular400(
                                color: const Color(0xFFE8D48B),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (premium)
                Positioned(
                  right: -2,
                  top: -6,
                  child: Icon(
                    Icons.auto_awesome,
                    size: 14,
                    color: ColorRes.accentPeach.withValues(alpha: 0.9),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
