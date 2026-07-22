import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krimson/common/service/livekit/livekit_room_service.dart';
import 'package:krimson/common/widget/custom_image.dart';
import 'package:krimson/common/widget/double_tap_detector.dart';
import 'package:krimson/model/livestream/live_chat_message.dart';
import 'package:krimson/screen/live_stream/livestream_screen/livestream_screen_controller.dart';
import 'package:krimson/screen/live_stream/livestream_screen/widget/live_host_panel.dart';
import 'package:krimson/utilities/color_res.dart';
import 'package:krimson/utilities/text_style_custom.dart';
import 'package:krimson/common/extensions/string_extension.dart';

/// Overlay LIVE: host/viewers arriba; título + chat/Private/Like/Gift abajo.
class LiveStreamOverlay extends StatelessWidget {
  final LivestreamScreenController controller;
  final bool showHostControls;
  final VoidCallback onClose;

  const LiveStreamOverlay({
    super.key,
    required this.controller,
    required this.onClose,
    this.showHostControls = false,
  });

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(10, 8, 10, 8 + bottomInset),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _TopBar(controller: controller, onClose: onClose),
            const SizedBox(height: 6),
            Obx(() => Align(
                  alignment: Alignment.centerRight,
                  child: _Pill(
                    label:
                        '${controller.pingMs.value} ms · ${controller.fps.value} fps',
                  ),
                )),
            Obx(() {
              final banner = controller.followBanner.value;
              if (banner == null) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(top: 8),
                child: _FollowBanner(message: banner),
              );
            }),
            Obx(() {
              if (controller.isBattleWaiting.value) {
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: _BattleWaitingBanner(controller: controller),
                );
              }
              if (!controller.isBattleRunning.value) {
                return const SizedBox.shrink();
              }
              return Padding(
                padding: const EdgeInsets.only(top: 8),
                child: _BattleScoreBar(controller: controller),
              );
            }),
            Expanded(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Doble tap en el video → like (solo audiencia).
                  // En batalla: modal de apoyo (lado = preferencia).
                  Positioned.fill(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return DoubleTapDetector(
                          onDoubleTap: (details) {
                            if (controller.isHost) return;
                            final box = context.findRenderObject() as RenderBox?;
                            final local = box?.globalToLocal(
                                  details.globalPosition,
                                ) ??
                                details.localPosition;
                            controller.onBattleDoubleTap(
                              local,
                              Size(constraints.maxWidth, constraints.maxHeight),
                            );
                          },
                          child: const ColoredBox(color: Colors.transparent),
                        );
                      },
                    ),
                  ),
                  Align(
                    alignment: Alignment.bottomLeft,
                    child: _ChatList(controller: controller),
                  ),
                  // Corazones flotantes (abajo-derecha, sobre el chat/controles).
                  Positioned(
                    right: 4,
                    bottom: 8,
                    child: _FloatingLikes(controller: controller),
                  ),
                  Obx(() {
                    if (!controller.isStreamPaused.value) {
                      return const SizedBox.shrink();
                    }
                    return const Center(child: _PausedBadge());
                  }),
                ],
              ),
            ),
            _TitleDescription(controller: controller),
            const SizedBox(height: 8),
            _ComposerRow(
              controller: controller,
              showHostControls: showHostControls,
            ),
          ],
        ),
      ),
    );
  }
}

class _FollowBanner extends StatelessWidget {
  final LiveChatMessage message;

  const _FollowBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: ColorRes.themeAccentSolid.withValues(alpha: 0.92),
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            const Icon(Icons.person_add_alt_1_rounded,
                color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '${message.userName} te sigue',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyleCustom.outFitMedium500(
                  color: Colors.white,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BattleWaitingBanner extends StatelessWidget {
  final LivestreamScreenController controller;

  const _BattleWaitingBanner({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final name = controller.battleOpponentName.value;
      final label = name.isEmpty
          ? 'Esperando respuesta a la batalla…'
          : 'Esperando a $name…';
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.65),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: ColorRes.themeAccentSolid.withValues(alpha: 0.7),
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.hourglass_top_rounded,
                color: ColorRes.themeAccentSolid, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: TextStyleCustom.outFitMedium500(
                  color: Colors.white,
                  fontSize: 13,
                ),
              ),
            ),
            Text(
              'BATALLA',
              style: TextStyleCustom.outFitSemiBold600(
                color: ColorRes.themeAccentSolid,
                fontSize: 11,
              ),
            ),
          ],
        ),
      );
    });
  }
}

class _BattleScoreBar extends StatelessWidget {
  final LivestreamScreenController controller;

  const _BattleScoreBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final hostCoins = controller.battleHostCoins.value;
      final oppCoins = controller.battleOpponentCoins.value;
      final total = hostCoins + oppCoins;
      // Empieza 50/50; luego se mueve con likes/regalos.
      final hostPct = total <= 0 ? 0.5 : hostCoins / total;
      final secs = controller.battleRemainingSeconds.value;
      final mm = (secs ~/ 60).toString().padLeft(2, '0');
      final ss = (secs % 60).toString().padLeft(2, '0');
      final hostName =
          controller.livestream.hostUser?.fullname ??
              controller.livestream.hostUser?.username ??
              'Host';
      final oppName = controller.battleOpponentName.value.isEmpty
          ? 'Rival'
          : controller.battleOpponentName.value;

      return Material(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Icon(Icons.sports_kabaddi_rounded,
                      color: ColorRes.themeAccentSolid, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    'BATALLA',
                    style: TextStyleCustom.outFitMedium500(
                      color: Colors.white,
                      fontSize: 11,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '$mm:$ss',
                    style: TextStyleCustom.outFitMedium500(
                      color: Colors.white70,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              SizedBox(
                height: 28,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final barW = constraints.maxWidth;
                    final junctionX = (hostPct * barW).clamp(0.0, barW);
                    return Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.center,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: SizedBox(
                            height: 8,
                            width: barW,
                            child: Row(
                              children: [
                                Expanded(
                                  flex: total <= 0
                                      ? 500
                                      : (hostPct * 1000).round().clamp(1, 999),
                                  child: Container(
                                      color: ColorRes.themeAccentSolid),
                                ),
                                Expanded(
                                  flex: total <= 0
                                      ? 500
                                      : ((1 - hostPct) * 1000)
                                          .round()
                                          .clamp(1, 999),
                                  child: Container(
                                      color: const Color(0xFF3B82F6)),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          left: junctionX - 16,
                          top: -2,
                          child: const _BattleJunctionFire(
                            width: 32,
                            height: 32,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '$hostName · $hostCoins',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyleCustom.outFitRegular400(
                        color: Colors.white,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  Text(
                    'VS',
                    style: TextStyleCustom.outFitMedium500(
                      color: Colors.white70,
                      fontSize: 10,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      '$oppCoins · $oppName',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                      style: TextStyleCustom.outFitRegular400(
                        color: Colors.white,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    });
  }
}

/// Llama animada en la unión rojo/azul del marcador de batalla.
class _BattleJunctionFire extends StatefulWidget {
  final double width;
  final double height;

  const _BattleJunctionFire({
    required this.width,
    required this.height,
  });

  @override
  State<_BattleJunctionFire> createState() => _BattleJunctionFireState();
}

class _BattleJunctionFireState extends State<_BattleJunctionFire>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, __) => CustomPaint(
          painter: _BattleFirePainter(t: _c.value),
          size: Size(widget.width, widget.height),
        ),
      ),
    );
  }
}

class _BattleFirePainter extends CustomPainter {
  final double t;

  _BattleFirePainter({required this.t});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final baseY = size.height * 0.78;
    final glow = Paint()
      ..color = const Color(0xFFFF6A00).withValues(alpha: 0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawCircle(Offset(cx, baseY - 4), size.width * 0.42, glow);

    // Capas: exterior (rojo), media (naranja), núcleo (amarillo/blanco).
    _drawTongue(
      canvas,
      cx: cx,
      baseY: baseY,
      w: size.width * 0.55,
      h: size.height * 0.78,
      phase: t,
      wobble: 0.9,
      color: const Color(0xFFE11D48),
    );
    _drawTongue(
      canvas,
      cx: cx - size.width * 0.08,
      baseY: baseY,
      w: size.width * 0.38,
      h: size.height * 0.62,
      phase: t + 0.33,
      wobble: 1.2,
      color: const Color(0xFFFF6A00),
    );
    _drawTongue(
      canvas,
      cx: cx + size.width * 0.06,
      baseY: baseY,
      w: size.width * 0.32,
      h: size.height * 0.55,
      phase: t + 0.66,
      wobble: 1.4,
      color: const Color(0xFFFFB020),
    );
    _drawTongue(
      canvas,
      cx: cx,
      baseY: baseY,
      w: size.width * 0.18,
      h: size.height * 0.38,
      phase: t + 0.15,
      wobble: 1.6,
      color: const Color(0xFFFFF3C4),
    );

    // Chispas
    final spark = Paint()..color = const Color(0xFFFFE08A);
    for (var i = 0; i < 5; i++) {
      final p = (t + i * 0.17) % 1.0;
      final sx = cx +
          (i.isEven ? -1 : 1) *
              size.width *
              (0.08 + 0.12 * (i % 3)) *
              (0.4 + 0.6 * (1 - p));
      final sy = baseY - size.height * (0.15 + p * 0.75);
      final r = (1.2 + (1 - p) * 1.6) * (i.isOdd ? 0.85 : 1);
      spark.color = Color.lerp(
            const Color(0xFFFFB020),
            const Color(0xFFFFF8E7),
            p,
          )!
          .withValues(alpha: (1 - p) * 0.9);
      canvas.drawCircle(Offset(sx, sy), r, spark);
    }
  }

  void _drawTongue(
    Canvas canvas, {
    required double cx,
    required double baseY,
    required double w,
    required double h,
    required double phase,
    required double wobble,
    required Color color,
  }) {
    final sway = math.sin(phase * math.pi * 2) * w * 0.18 * wobble;
    final stretch = 1 + 0.12 * math.sin((phase + 0.25) * math.pi * 2);
    final tipY = baseY - h * stretch;
    final tipX = cx + sway;
    final left = cx - w / 2;
    final right = cx + w / 2;

    final path = Path()
      ..moveTo(left, baseY)
      ..cubicTo(
        left - w * 0.05,
        baseY - h * 0.35,
        tipX - w * 0.25,
        tipY + h * 0.2,
        tipX,
        tipY,
      )
      ..cubicTo(
        tipX + w * 0.25,
        tipY + h * 0.2,
        right + w * 0.05,
        baseY - h * 0.35,
        right,
        baseY,
      )
      ..close();

    final paint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0, 0.55),
        radius: 0.95,
        colors: [
          color.withValues(alpha: 0.95),
          color.withValues(alpha: 0.55),
          color.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(Rect.fromLTRB(left - 4, tipY - 4, right + 4, baseY + 2));

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _BattleFirePainter oldDelegate) =>
      oldDelegate.t != t;
}

class _PausedBadge extends StatelessWidget {
  const _PausedBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.pause_circle_filled, color: Colors.white, size: 22),
          const SizedBox(width: 8),
          Text(
            'PAUSADO',
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

/// Controles LIVE: host = Batalla/Pausar/Mute/Regalos/Calidad/Options; audiencia = solo Calidad.
class _LiveControlsBar extends StatelessWidget {
  final LivestreamScreenController controller;
  final bool showHostControls;

  const _LiveControlsBar({
    required this.controller,
    required this.showHostControls,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final paused = controller.isStreamPaused.value;
      final muted = showHostControls
          ? !(controller.liveKit?.microphoneEnabled.value ?? true)
          : controller.isLiveAudioMuted.value;
      final gifts = controller.giftSenders.length;
      final battleOn = controller.isBattleRunning.value ||
          controller.isBattleWaiting.value;
      final quality = controller.liveKit?.qualityProfile.value ??
          LiveKitQualityProfile.low;
      final qualityText = switch (quality) {
        LiveKitQualityProfile.low => 'Baja',
        LiveKitQualityProfile.medium => 'Media',
        LiveKitQualityProfile.high => 'Alta',
      };

      // Audiencia: solo calidad de video (sin Pausar/Mute/Regalos).
      if (!showHostControls) {
        return SizedBox(
          height: 40,
          child: Align(
            alignment: Alignment.centerLeft,
            child: _ActionChip(
              icon: Icons.high_quality_rounded,
              label: qualityText,
              onTap: controller.openQualitySheet,
            ),
          ),
        );
      }

      return SizedBox(
        height: 40,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Flexible(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _ActionChip(
                      icon: Icons.sports_kabaddi_rounded,
                      label: battleOn ? 'Fin batalla' : 'Batalla',
                      accent: true,
                      onTap: controller.openBattle,
                    ),
                    const SizedBox(width: 6),
                    _ActionChip(
                      icon: paused
                          ? Icons.play_arrow_rounded
                          : Icons.pause_rounded,
                      label: paused ? 'Reanudar' : 'Pausar',
                      onTap: controller.togglePauseLive,
                    ),
                    const SizedBox(width: 6),
                    _ActionChip(
                      // Estado real del mic: Mute = silenciado; Abierto = puede hablar.
                      icon: muted ? Icons.mic_off_rounded : Icons.mic_rounded,
                      label: muted ? 'Mute' : 'Abierto',
                      onTap: controller.toggleLiveAudioMute,
                    ),
                    const SizedBox(width: 6),
                    _ActionChip(
                      icon: Icons.card_giftcard_rounded,
                      label: gifts > 0 ? 'Regalos ($gifts)' : 'Regalos',
                      onTap: controller.openGiftSendersSheet,
                    ),
                    const SizedBox(width: 6),
                    _ActionChip(
                      icon: Icons.high_quality_rounded,
                      label: qualityText,
                      onTap: controller.openQualitySheet,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 6),
            LiveHostActionBar(
              onBeauty: controller.openBeauty,
              onInvite: controller.openInvite,
              onBattle: controller.openBattle,
              onQuality: controller.openQualitySheet,
              networkLabel: controller.networkLabel,
              qualityLabel: qualityText,
              battleRunning: battleOn,
            ),
          ],
        ),
      );
    });
  }
}

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool accent;

  const _ActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
    this.accent = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: accent
          ? ColorRes.themeAccentSolid.withValues(alpha: 0.92)
          : Colors.black.withValues(alpha: 0.5),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 16),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyleCustom.outFitMedium500(
                  color: Colors.white,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final LivestreamScreenController controller;
  final VoidCallback onClose;

  const _TopBar({required this.controller, required this.onClose});

  @override
  Widget build(BuildContext context) {
    final host = controller.livestream.hostUser;
    final name = host?.fullname ?? host?.username ?? controller.liveTitle;
    final photo = host?.profile;

    return Row(
      children: [
        Expanded(
          child: Material(
            color: Colors.black.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(28),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(4, 4, 8, 4),
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(24),
                      onTap: controller.openHostProfile,
                      child: Row(
                        children: [
                          CustomImage(
                            size: const Size(36, 36),
                            image: photo?.addBaseURL(),
                            fullName: name,
                            strokeWidth: 0,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyleCustom.outFitMedium500(
                                    color: Colors.white,
                                    fontSize: 13,
                                  ),
                                ),
                                Text(
                                  'ID: ${controller.livestream.hostId ?? ''}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyleCustom.outFitRegular400(
                                    color: Colors.white70,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (!controller.isHost)
                    Obx(() {
                      if (controller.isFollowingHost.value) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: Material(
                          color: ColorRes.themeAccentSolid,
                          borderRadius: BorderRadius.circular(14),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: controller.isFollowBusy.value
                                ? null
                                : controller.followHost,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              child: Text(
                                controller.isFollowBusy.value ? '…' : 'Follow',
                                style: TextStyleCustom.outFitMedium500(
                                  color: Colors.white,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  Obx(() {
                    final battle = controller.isBattleRunning.value;
                    return Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: ColorRes.themeAccentSolid,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        battle ? 'BATALLA' : 'LIVE',
                        style: TextStyleCustom.outFitMedium500(
                          color: Colors.white,
                          fontSize: 10,
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Obx(() => _Pill(
              icon: Icons.visibility_rounded,
              label: '${controller.watchingCount.value}',
            )),
        const SizedBox(width: 6),
        Obx(() => _Pill(
              icon: Icons.favorite_rounded,
              label: '${controller.likeCount.value}',
            )),
        IconButton(
          onPressed: onClose,
          icon: const Icon(Icons.close, color: Colors.white),
        ),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  final IconData? icon;
  final String label;

  const _Pill({required this.label, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, color: Colors.white, size: 14),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyleCustom.outFitRegular400(
              color: Colors.white,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatList extends StatelessWidget {
  final LivestreamScreenController controller;

  const _ChatList({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final items = controller.chatMessages
          .where((m) => m.type != 'like')
          .toList();
      if (items.isEmpty) return const SizedBox.shrink();
      final visible = items.length > LivestreamScreenController.maxVisibleComments
          ? items.sublist(items.length - LivestreamScreenController.maxVisibleComments)
          : items;
      return SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.28,
        width: MediaQuery.sizeOf(context).width * 0.72,
        child: ListView.builder(
          reverse: true,
          padding: EdgeInsets.zero,
          itemCount: visible.length,
          itemBuilder: (context, index) {
            final msg = visible[visible.length - 1 - index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: _ChatBubble(controller: controller, message: msg),
            );
          },
        ),
      );
    });
  }
}

class _ChatBubble extends StatelessWidget {
  final LivestreamScreenController controller;
  final LiveChatMessage message;

  const _ChatBubble({required this.controller, required this.message});

  @override
  Widget build(BuildContext context) {
    final canReply =
        message.type == 'text' || message.type == 'gif' || message.type == 'gift';

    return Align(
      alignment: Alignment.centerLeft,
      child: Material(
        color: Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: canReply ? () => controller.setReplyTo(message) : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => controller.openChatUserProfile(message),
                  child: Text(
                    message.userName,
                    style: TextStyleCustom.outFitMedium500(
                      color: ColorRes.themeAccentSolid,
                      fontSize: 11,
                    ),
                  ),
                ),
                if (message.isReply) ...[
                  const SizedBox(height: 2),
                  Text(
                    '↳ ${message.replyToUserName ?? ''}'
                    '${(message.replyToText ?? '').isNotEmpty ? ': ${message.replyToText}' : ''}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyleCustom.outFitRegular400(
                      color: Colors.white60,
                      fontSize: 10,
                    ),
                  ),
                ],
                const SizedBox(height: 2),
                if (message.type == 'follow')
                  Text(
                    message.text ?? 'te sigue',
                    style: TextStyleCustom.outFitMedium500(
                      color: Colors.white,
                      fontSize: 13,
                    ),
                  )
                else if (message.type == 'gif' &&
                    (message.gifUrl ?? '').isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      message.gifUrl!,
                      height: 72,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Text(
                        'GIF',
                        style: TextStyleCustom.outFitRegular400(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  )
                else if (message.type == 'gift')
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if ((message.giftImage ?? '').isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: Image.network(
                            message.giftImage!.addBaseURL(),
                            width: 36,
                            height: 36,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.card_giftcard,
                              color: Colors.white70,
                              size: 28,
                            ),
                          ),
                        )
                      else
                        const Icon(Icons.card_giftcard,
                            color: Colors.white70, size: 28),
                      Flexible(
                        child: Text(
                          'sent a gift'
                          '${message.giftCoins != null && message.giftCoins! > 0 ? ' · ${message.giftCoins} coins' : ''}',
                          style: TextStyleCustom.outFitRegular400(
                            color: Colors.white,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  )
                else
                  Text(
                    message.text ?? '',
                    style: TextStyleCustom.outFitRegular400(
                      color: Colors.white,
                      fontSize: 13,
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

class _FloatingLikes extends StatelessWidget {
  final LivestreamScreenController controller;

  const _FloatingLikes({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final n = controller.floatingLikes.value.clamp(0, 8);
      if (n == 0) return const SizedBox.shrink();
      return SizedBox(
        width: 56,
        height: 180,
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            for (var i = 0; i < n; i++)
              _FloatingHeart(
                key: ValueKey('like_$i}_${controller.floatingLikes.value}'),
                index: i,
              ),
          ],
        ),
      );
    });
  }
}

class _FloatingHeart extends StatefulWidget {
  final int index;

  const _FloatingHeart({super.key, required this.index});

  @override
  State<_FloatingHeart> createState() => _FloatingHeartState();
}

class _FloatingHeartState extends State<_FloatingHeart>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _rise;
  late final Animation<double> _fade;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..forward();
    _rise = Tween<double>(begin: 0, end: -150 - (widget.index % 3) * 12.0)
        .animate(CurvedAnimation(parent: _c, curve: Curves.easeOutCubic));
    _fade = Tween<double>(begin: 1, end: 0).animate(
      CurvedAnimation(parent: _c, curve: const Interval(0.35, 1)),
    );
    _scale = Tween<double>(begin: 0.6, end: 1.25).animate(
      CurvedAnimation(parent: _c, curve: Curves.easeOutBack),
    );
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dx = ((widget.index % 3) - 1) * 10.0;
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) => Opacity(
        opacity: _fade.value.clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(dx, _rise.value),
          child: Transform.scale(
            scale: _scale.value,
            child: Icon(
              Icons.favorite,
              color: ColorRes.themeAccentSolid.withValues(alpha: 0.95),
              size: 28 + (widget.index % 3) * 4,
              shadows: const [
                Shadow(color: Colors.black54, blurRadius: 6),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TitleDescription extends StatelessWidget {
  final LivestreamScreenController controller;

  const _TitleDescription({required this.controller});

  @override
  Widget build(BuildContext context) {
    final title = controller.liveTitle;
    final desc = controller.liveDescription;
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyleCustom.outFitMedium500(
                color: Colors.white,
                fontSize: 15,
              ),
            ),
            if (desc.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                desc,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyleCustom.outFitRegular400(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ComposerRow extends StatelessWidget {
  final LivestreamScreenController controller;
  final bool showHostControls;

  const _ComposerRow({
    required this.controller,
    required this.showHostControls,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Obx(() {
          final reply = controller.replyingTo.value;
          if (reply == null) return const SizedBox.shrink();
          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Material(
              color: Colors.black.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 6, 4, 6),
                child: Row(
                  children: [
                    const Icon(Icons.reply_rounded,
                        color: Colors.white70, size: 16),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Respondiendo a ${reply.userName}'
                        '${(reply.text ?? '').isNotEmpty ? ': ${reply.text}' : ''}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyleCustom.outFitRegular400(
                          color: Colors.white70,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      onPressed: controller.clearReply,
                      icon: const Icon(Icons.close,
                          color: Colors.white70, size: 16),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
        if (showHostControls) ...[
          Builder(builder: (context) {
            final lk = controller.liveKit;
            if (lk == null) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _LiveControlsBar(
                  controller: controller,
                  showHostControls: true,
                ),
              );
            }
            return Obx(() {
              final micOn = lk.microphoneEnabled.value;
              final camOn = lk.cameraEnabled.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _LiveControlsBar(
                      controller: controller,
                      showHostControls: true,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 36,
                            minHeight: 36,
                          ),
                          onPressed: () async {
                            await lk.toggleMicrophone();
                            controller.isLiveAudioMuted.value =
                                !lk.microphoneEnabled.value;
                          },
                          icon: Icon(
                            micOn ? Icons.mic : Icons.mic_off,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 36,
                            minHeight: 36,
                          ),
                          onPressed: lk.toggleCamera,
                          icon: Icon(
                            camOn ? Icons.videocam : Icons.videocam_off,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            });
          }),
        ] else ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _LiveControlsBar(
              controller: controller,
              showHostControls: false,
            ),
          ),
        ],
        Row(
          children: [
            Expanded(
              child: Container(
                height: 44,
                padding: const EdgeInsets.only(left: 14, right: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Obx(() {
                        final reply = controller.replyingTo.value;
                        return TextField(
                          controller: controller.commentController,
                          style: TextStyleCustom.outFitRegular400(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                          cursorColor: ColorRes.themeAccentSolid,
                          textInputAction: TextInputAction.send,
                          onSubmitted: controller.sendComment,
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            isDense: true,
                            hintText: reply != null
                                ? 'Responder a ${reply.userName}…'
                                : 'Di Hola',
                            hintStyle: TextStyleCustom.outFitRegular400(
                              color: Colors.white54,
                              fontSize: 14,
                            ),
                          ),
                        );
                      }),
                    ),
                    IconButton(
                      onPressed: () => controller
                          .sendComment(controller.commentController.text),
                      icon: const Icon(Icons.send_rounded,
                          color: ColorRes.themeAccentSolid, size: 22),
                    ),
                  ],
                ),
              ),
            ),
            if (!controller.isHost) ...[
              const SizedBox(width: 6),
              Material(
                color: ColorRes.themeAccentSolid,
                borderRadius: BorderRadius.circular(22),
                child: InkWell(
                  borderRadius: BorderRadius.circular(22),
                  onTap: controller.openPrivateCall,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 11),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.call, color: Colors.white, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          'Private',
                          style: TextStyleCustom.outFitMedium500(
                            color: Colors.white,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Obx(() => _CircleBtn(
                    icon: Icons.favorite,
                    onTap: controller.isLiking.value
                        ? null
                        : controller.sendLike,
                  )),
              const SizedBox(width: 6),
              _CircleBtn(
                icon: Icons.card_giftcard_rounded,
                onTap: controller.openGiftSheet,
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _CircleBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _CircleBtn({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.45),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(11),
          child: Icon(icon, color: ColorRes.themeAccentSolid, size: 22),
        ),
      ),
    );
  }
}
