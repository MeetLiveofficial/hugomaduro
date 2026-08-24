import 'dart:ui' show ImageFilter;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krimson/common/manager/app_role.dart';
import 'package:krimson/common/manager/livekit_room_controller.dart';
import 'package:krimson/common/widget/brand_wash_bg.dart';
import 'package:krimson/common/widget/livekit/livekit_video_view.dart';
import 'package:krimson/languages/languages_keys.dart';
import 'package:krimson/screen/match_screen/match_screen_controller.dart';
import 'package:krimson/screen/match_screen/match_web_video.dart';
import 'package:krimson/utilities/asset_res.dart';
import 'package:krimson/utilities/client_colors.dart';
import 'package:krimson/utilities/color_res.dart';
import 'package:krimson/utilities/style_res.dart';
import 'package:krimson/utilities/text_style_custom.dart';

/// Vista Match: radar de búsqueda + modos Random / Goddess.
/// [asTab]: embebido en la barra del cliente. Sin tab, muestra atrás (Ajustes streamer).
class MatchScreen extends StatelessWidget {
  final bool asTab;

  const MatchScreen({super.key, this.asTab = false});

  @override
  Widget build(BuildContext context) {
    final c = Get.put(MatchScreenController());
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        fit: StackFit.expand,
        children: [
          _MatchBackdrop(),
          SafeArea(
            child: Padding(
              padding: EdgeInsets.only(bottom: asTab ? 12 : 16),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final radar = (constraints.maxHeight * 0.36)
                      .clamp(150.0, 240.0);
                  return Column(
                    children: [
                      _TopBar(controller: c, showBack: !asTab),
                      Expanded(
                        child: AppRole.isStreamer()
                            ? Padding(
                                padding: const EdgeInsets.fromLTRB(
                                    16, 8, 16, 12),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(22),
                                  child: _StreamerWaitCamera(controller: c),
                                ),
                              )
                            : Align(
                                alignment: const Alignment(0, 0.42),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _RadarButton(controller: c, size: radar),
                                    SizedBox(height: radar < 180 ? 10 : 14),
                                    Obx(() {
                                      final busy = c.isMatching.value;
                                      final text = busy
                                          ? LKey.searchingMatch.tr
                                          : LKey.clickToMatch.tr;
                                      return Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 24),
                                        child: Text(
                                          text,
                                          textAlign: TextAlign.center,
                                          style:
                                              TextStyleCustom.outFitMedium500(
                                            color: AppRole.isClient()
                                                ? ClientColors.text
                                                : Colors.white,
                                            fontSize: 15,
                                          ),
                                        ),
                                      );
                                    }),
                                  ],
                                ),
                              ),
                      ),
                      if (AppRole.isStreamer())
                        _StreamerMatchRadio(controller: c)
                      else
                        _ModeRow(controller: c),
                      const SizedBox(height: 10),
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
    final client = AppRole.isClient();
    final base = client ? ClientColors.bg : ColorRes.obsidianDeep;
    final mid = client
        ? ClientColors.primary.withValues(alpha: 0.28)
        : ColorRes.mlPurple.withValues(alpha: 0.28);
    final bottom = client
        ? ClientColors.surface.withValues(alpha: 0.82)
        : ColorRes.obsidianDeep.withValues(alpha: 0.78);
    final halo = client ? ClientColors.primary : ColorRes.themeAccentSolid;
    final vignetteMid = client
        ? ClientColors.primaryActive.withValues(alpha: 0.45)
        : ColorRes.mlPurple.withValues(alpha: 0.45);
    final vignetteEnd = client
        ? ClientColors.bg.withValues(alpha: 0.88)
        : ColorRes.darkPurple.withValues(alpha: 0.78);

    return Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(color: base),
        ImageFiltered(
          imageFilter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Transform.scale(
            scale: 1.12,
            child: Image.asset(
              AssetRes.matchWomanBg,
              fit: BoxFit.cover,
              alignment: const Alignment(0, -0.08),
              errorBuilder: (_, __, ___) => const BrandWashBg(),
            ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                base.withValues(alpha: 0.38),
                mid,
                bottom,
              ],
            ),
          ),
        ),
        // Halo suave detrás del radar.
        Align(
          alignment: const Alignment(0, 0.2),
          child: Container(
            width: 320,
            height: 320,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  halo.withValues(alpha: 0.28),
                  halo.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ),
        // Viñeta inferior para los controles.
        Align(
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
                    colors: [
                      Colors.transparent,
                      vignetteMid,
                      vignetteEnd,
                    ],
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

class _StreamerWaitCamera extends StatelessWidget {
  const _StreamerWaitCamera({required this.controller});

  final MatchScreenController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      controller.waitCameraOn.value;
      if (!Get.isRegistered<LiveKitRoomController>(
          tag: MatchScreenController.waitLkTag)) {
        return const _CameraPlaceholder();
      }
      final lk =
          Get.find<LiveKitRoomController>(tag: MatchScreenController.waitLkTag);
      lk.mediaRevision.value;
      final local = lk.localParticipant.value;
      if (firstVideoTrackOf(local) == null) {
        return const _CameraPlaceholder();
      }
      if (kIsWeb) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          passThroughMatchVideoClicks();
        });
      }
      return LiveKitParticipantVideo(
        participant: local,
        mirror: true,
        forcePortraitUpright: false,
      );
    });
  }
}

class _CameraPlaceholder extends StatelessWidget {
  const _CameraPlaceholder();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFF140E18),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.videocam_rounded, color: Colors.white54, size: 42),
            const SizedBox(height: 10),
            Text(
              LKey.enablingCamera.tr,
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final MatchScreenController controller;
  final bool showBack;

  const _TopBar({required this.controller, this.showBack = false});

  @override
  Widget build(BuildContext context) {
    if (AppRole.isStreamer()) {
      if (!showBack) return const SizedBox(height: 8);
      return Padding(
        padding: const EdgeInsets.fromLTRB(6, 4, 14, 0),
        child: Align(
          alignment: Alignment.centerLeft,
          child: IconButton(
            onPressed: Get.back,
            icon: const Icon(Icons.arrow_back_ios_new,
                color: Colors.white, size: 18),
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
      child: Row(
        children: [
          if (showBack) ...[
            IconButton(
              onPressed: Get.back,
              icon: const Icon(Icons.arrow_back_ios_new,
                  color: Colors.white, size: 18),
            ),
            const SizedBox(width: 4),
          ],
          _ChipButton(
            onTap: controller.openWallet,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(AssetRes.icStar, width: 16, height: 16),
                const SizedBox(width: 6),
                Obx(() => Text(
                      '${controller.coins.value}',
                      style: TextStyleCustom.outFitSemiBold600(
                        color: ClientColors.text,
                        fontSize: 13,
                      ),
                    )),
              ],
            ),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Obx(() {
              final used = controller.freeMatchesUsed.value;
              final quota = controller.freeMatchesQuota.value;
              return Text(
                LKey.freeMatchesCount.trParams({
                  'used': '$used',
                  'quota': '$quota',
                }),
                style: TextStyleCustom.outFitMedium500(
                  color: ClientColors.textMuted,
                  fontSize: 12,
                ),
              );
            }),
          ),
          _ChipButton(
            onTap: controller.openMembership,
            borderColor: const Color(0xFFD4AF37),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(AssetRes.icPro, width: 16, height: 16),
                const SizedBox(width: 6),
                Text(
                  LKey.membership.tr,
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
      color: ClientColors.surfaceAlt.withValues(alpha: 0.72),
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: borderColor ?? ClientColors.secondarySoft,
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
                    gradient: StyleRes.clientGradient,
                    border: Border.all(
                      color: ClientColors.secondarySoft,
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
                          color: ClientColors.text,
                          size: iconSize,
                        ),
                );
              }),
            ),
            builder: (context, child) {
              return CustomPaint(
                painter: _RadarPainter(
                  progress: controller.pulseController.value,
                  accent: ClientColors.primary,
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

class _StreamerMatchRadio extends StatelessWidget {
  const _StreamerMatchRadio({required this.controller});

  final MatchScreenController controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Obx(() {
        final on = controller.inMatchPool.value;
        final camera = controller.waitCameraOn.value;
        final title = LKey.matchLabel.tr;
        final subtitle = on
            ? (camera ? LKey.waitingForClient.tr : LKey.enablingCamera.tr)
            : LKey.tapToReceiveClients.tr;
        return Material(
          color: on
              ? ColorRes.crimson.withValues(alpha: 0.42)
              : Colors.white.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: controller.toggleStreamerMatch,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: on
                      ? ColorRes.themeAccentSolid.withValues(alpha: 0.85)
                      : Colors.white24,
                  width: on ? 1.4 : 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    on
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_off_rounded,
                    color: on ? Colors.white : Colors.white54,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
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
                        Text(
                          subtitle,
                          style: TextStyleCustom.outFitRegular400(
                            color: const Color(0xFFE8D48B),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
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
        final seekingClients = AppRole.isStreamer();
        return Row(
          children: [
            Expanded(
              child: _ModeCard(
                title: LKey.matchModeRandom.tr,
                subtitle: seekingClients
                    ? LKey.matchAnyClient.tr
                    : LKey.matchAnyStreamer.tr,
                coins: seekingClients ? null : controller.randomHintCost,
                selected: selected == MatchSearchMode.random,
                premium: false,
                onTap: () => controller.selectMode(MatchSearchMode.random),
              ),
            ),
            if (!seekingClients) ...[
              const SizedBox(width: 10),
              Expanded(
                child: _ModeCard(
                  title: LKey.matchModeGoddess.tr,
                  subtitle: LKey.matchTopRated.tr,
                  coins: controller.goddessHintCost,
                  selected: selected == MatchSearchMode.goddess,
                  premium: true,
                  onTap: () => controller.selectMode(MatchSearchMode.goddess),
                ),
              ),
            ],
          ],
        );
      }),
    );
  }
}

class _ModeCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final int? coins;
  final bool selected;
  final bool premium;
  final VoidCallback onTap;

  const _ModeCard({
    required this.title,
    required this.subtitle,
    this.coins,
    required this.selected,
    required this.premium,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final client = AppRole.isClient();
    final fill = selected
        ? (client
            ? ClientColors.primary.withValues(alpha: 0.42)
            : ColorRes.crimson.withValues(alpha: 0.42))
        : (client
            ? ClientColors.surfaceAlt.withValues(alpha: 0.72)
            : Colors.white.withValues(alpha: 0.16));
    final edge = selected
        ? (client ? ClientColors.secondary : ColorRes.themeAccentSolid.withValues(alpha: 0.85))
        : (client ? ClientColors.border : Colors.white24);
    final radio = selected
        ? (client ? ClientColors.secondary : ColorRes.themeAccentSolid)
        : Colors.white54;
    final titleColor = client ? ClientColors.text : Colors.white;
    final subtitleColor =
        client ? ClientColors.textMuted : const Color(0xFFE8D48B);

    return Material(
      color: fill,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: edge,
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
                    color: radio,
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
                            color: titleColor,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: TextStyleCustom.outFitRegular400(
                            color: subtitleColor,
                            fontSize: 11,
                          ),
                        ),
                        if (coins != null && coins! > 0) ...[
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Image.asset(
                                AssetRes.icCoin,
                                width: 12,
                                height: 12,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                LKey.coinsCount.trParams({'count': '$coins'}),
                                style: TextStyleCustom.outFitSemiBold600(
                                  color: titleColor,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ],
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
                    color: client
                        ? ClientColors.secondarySoft
                        : ColorRes.accentPeach.withValues(alpha: 0.9),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
