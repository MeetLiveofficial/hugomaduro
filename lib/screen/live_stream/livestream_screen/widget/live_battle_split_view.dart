import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krimson/common/extensions/string_extension.dart';
import 'package:krimson/common/widget/custom_image.dart';
import 'package:krimson/common/widget/livekit/livekit_video_view.dart';
import 'package:krimson/screen/live_stream/livestream_screen/livestream_screen_controller.dart';
import 'package:krimson/utilities/color_res.dart';
import 'package:krimson/utilities/text_style_custom.dart';
import 'package:livekit_client/livekit_client.dart';

/// Altura relativa del video PK (overlay reserva el mismo valor).
const double kPkVideoHeightFactor = 0.52;

/// Vista PK: videos grandes arriba + marcador (fuego + timer PK) DEBAJO.
class LiveBattleSplitView extends StatelessWidget {
  final LivestreamScreenController controller;

  const LiveBattleSplitView({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      controller.liveKit?.mediaRevision.value;
      controller.isBattleRunning.value;
      controller.battleOpponentId.value;
      controller.battleHostCoins.value;
      controller.battleOpponentCoins.value;
      controller.battleRemainingSeconds.value;

      final redId = controller.battleRedUserId;
      final blueId = controller.battleBlueUserId;
      final red = redId > 0 ? controller.participantForUserId(redId) : null;
      final blue =
          blueId > 0 && blueId != redId
              ? controller.participantForUserId(blueId)
              : null;

      final hostCoins = controller.battleHostCoins.value;
      final oppCoins = controller.battleOpponentCoins.value;
      final total = hostCoins + oppCoins;
      final hostPct =
          total <= 0 ? 50 : ((hostCoins / total) * 100).round().clamp(0, 100);

      final teamAName = controller.isBattlePrimaryHost
          ? (controller.livestream.hostUser?.fullname ??
              controller.livestream.hostUser?.username ??
              'Host')
          : (controller.battleOpponentName.value.isEmpty
              ? 'Invitador'
              : controller.battleOpponentName.value);
      final teamAPhoto = controller.isBattlePrimaryHost
          ? controller.livestream.hostUser?.profile
          : null;
      final teamBName = controller.isBattlePrimaryHost
          ? (controller.battleOpponentName.value.isEmpty
              ? 'Rival'
              : controller.battleOpponentName.value)
          : (controller.livestream.hostUser?.fullname ??
              controller.livestream.hostUser?.username ??
              'Rival');
      final teamBPhoto = controller.isBattlePrimaryHost
          ? null
          : controller.livestream.hostUser?.profile;

      final size = MediaQuery.sizeOf(context);
      final topInset = MediaQuery.viewPaddingOf(context).top;
      // Alineado con overlay flex 58/42: video+marcador caben arriba del chat.
      final videoH = size.width > 520
          ? (size.height * 0.36).clamp(200.0, size.height * 0.42)
          : (size.height * kPkVideoHeightFactor).clamp(260.0, size.height * 0.50);

      return ColoredBox(
        color: Colors.black,
        child: Align(
          alignment: Alignment.topCenter,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: topInset),
              SizedBox(
                height: videoH,
                width: size.width,
                child: Stack(
                  fit: StackFit.expand,
                  clipBehavior: Clip.hardEdge,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: _BattlePane(
                            teamColor: ColorRes.themeAccentSolid,
                            name: teamAName,
                            photo: teamAPhoto,
                            participant: red,
                            mirrorLocal: red is LocalParticipant,
                          ),
                        ),
                        Expanded(
                          child: _BattlePane(
                            teamColor: const Color(0xFF3B82F6),
                            name: teamBName,
                            photo: teamBPhoto,
                            participant: blue,
                            mirrorLocal: blue is LocalParticipant,
                          ),
                        ),
                      ],
                    ),
                    const Center(child: _VsBadge()),
                  ],
                ),
              ),
              // Marcador pegado al video (sin Expanded → sin hueco negro).
              SizedBox(
                width: size.width,
                child: _PkScoreBelow(
                  hostName: teamAName,
                  oppName: teamBName,
                  hostCoins: hostCoins,
                  oppCoins: oppCoins,
                  hostPct: hostPct / 100.0,
                  total: total,
                  remainingSeconds: controller.battleRemainingSeconds.value,
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}

/// Marcador debajo del video: fuego + timer en fila; barra roja/azul debajo.
class _PkScoreBelow extends StatelessWidget {
  final String hostName;
  final String oppName;
  final int hostCoins;
  final int oppCoins;
  final double hostPct;
  final int total;
  final int remainingSeconds;

  const _PkScoreBelow({
    required this.hostName,
    required this.oppName,
    required this.hostCoins,
    required this.oppCoins,
    required this.hostPct,
    required this.total,
    required this.remainingSeconds,
  });

  @override
  Widget build(BuildContext context) {
    final mm = (remainingSeconds ~/ 60).toString().padLeft(2, '0');
    final ss = (remainingSeconds % 60).toString().padLeft(2, '0');
    final hostPctInt = (hostPct * 100).round().clamp(0, 100);
    final oppPctInt = 100 - hostPctInt;
    final redFlex =
        total <= 0 ? 500 : (hostPct * 1000).round().clamp(1, 999);
    final blueFlex =
        total <= 0 ? 500 : ((1 - hostPct) * 1000).round().clamp(1, 999);

    return Container(
      margin: const EdgeInsets.fromLTRB(8, 0, 8, 4),
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: BoxDecoration(
        color: const Color(0xFF14161C),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: SizedBox(
              width: MediaQuery.sizeOf(context).width - 36,
              child: Row(
                children: [
                  _TeamChip(
                    label: 'TEAM A',
                    color: ColorRes.themeAccentSolid,
                  ),
                  const Spacer(),
                  // Fuego + timer en una sola fila (no apilados).
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1C1F28),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const _BattleJunctionFire(width: 18, height: 18),
                        const SizedBox(width: 4),
                        Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: 'P',
                                style: TextStyleCustom.outFitSemiBold600(
                                  color: ColorRes.themeAccentSolid,
                                  fontSize: 13,
                                ),
                              ),
                              TextSpan(
                                text: 'K',
                                style: TextStyleCustom.outFitSemiBold600(
                                  color: const Color(0xFF60A5FA),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 12,
                          margin: const EdgeInsets.symmetric(horizontal: 7),
                          color: Colors.white24,
                        ),
                        Icon(Icons.timer_outlined,
                            size: 12, color: Colors.white70),
                        const SizedBox(width: 3),
                        Text(
                          '$mm:$ss',
                          style: TextStyleCustom.outFitSemiBold600(
                            color: Colors.white,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  _TeamChip(
                    label: 'TEAM B',
                    color: const Color(0xFF3B82F6),
                    alignEnd: true,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _ScoreSide(
                  name: hostName,
                  coins: hostCoins,
                  percent: hostPctInt,
                  color: ColorRes.themeAccentSolid,
                  alignEnd: false,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  'VS',
                  style: TextStyleCustom.unboundedSemiBold600(
                    color: Colors.amber.shade300,
                    fontSize: 12,
                  ),
                ),
              ),
              Expanded(
                child: _ScoreSide(
                  name: oppName,
                  coins: oppCoins,
                  percent: oppPctInt,
                  color: const Color(0xFF3B82F6),
                  alignEnd: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Barra ROJA / AZUL bien visible debajo de los scores.
          _PkPushBar(hostPct: hostPct, redFlex: redFlex, blueFlex: blueFlex),
        ],
      ),
    );
  }
}

/// Barra de empujón PK: rojo (A) | azul (B) con fuego en la unión.
class _PkPushBar extends StatelessWidget {
  final double hostPct;
  final int redFlex;
  final int blueFlex;

  const _PkPushBar({
    required this.hostPct,
    required this.redFlex,
    required this.blueFlex,
  });

  @override
  Widget build(BuildContext context) {
    const red = Color(0xFFFF003F);
    const blue = Color(0xFF3B82F6);
    final ratio = hostPct.clamp(0.0, 1.0);

    return SizedBox(
      height: 22,
      width: double.infinity,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final junction = (w * ratio).clamp(12.0, w - 12.0);
          return ClipRect(
            child: Stack(
              clipBehavior: Clip.hardEdge,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(11),
                  child: Row(
                    children: [
                      Expanded(
                        flex: redFlex,
                        child: Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFFFF4D6D), red],
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: blueFlex,
                        child: Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [blue, Color(0xFF60A5FA)],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  left: (junction - 11).clamp(0.0, w - 22.0),
                  top: 0,
                  child: const _BattleJunctionFire(width: 22, height: 22),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _TeamChip extends StatelessWidget {
  final String label;
  final Color color;
  final bool alignEnd;

  const _TeamChip({
    required this.label,
    required this.color,
    this.alignEnd = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: TextStyleCustom.outFitSemiBold600(
          color: Colors.white,
          fontSize: 10,
        ),
      ),
    );
  }
}

class _ScoreSide extends StatelessWidget {
  final String name;
  final int coins;
  final int percent;
  final Color color;
  final bool alignEnd;

  const _ScoreSide({
    required this.name,
    required this.coins,
    required this.percent,
    required this.color,
    required this.alignEnd,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: double.infinity,
          child: Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: alignEnd ? TextAlign.right : TextAlign.left,
            style: TextStyleCustom.outFitMedium500(
              color: Colors.white,
              fontSize: 12,
            ),
          ),
        ),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: alignEnd ? Alignment.centerRight : Alignment.centerLeft,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: alignEnd
                ? [
                    Text(
                      '$percent%',
                      style: TextStyleCustom.outFitSemiBold600(
                        color: color,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(Icons.monetization_on,
                        size: 13, color: Colors.amber.shade400),
                    const SizedBox(width: 2),
                    Text(
                      '$coins',
                      style: TextStyleCustom.outFitMedium500(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ]
                : [
                    Icon(Icons.monetization_on,
                        size: 13, color: Colors.amber.shade400),
                    const SizedBox(width: 2),
                    Text(
                      '$coins',
                      style: TextStyleCustom.outFitMedium500(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '$percent%',
                      style: TextStyleCustom.outFitSemiBold600(
                        color: color,
                        fontSize: 13,
                      ),
                    ),
                  ],
          ),
        ),
      ],
    );
  }
}

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
          painter: _PkFirePainter(t: _c.value),
          size: Size(widget.width, widget.height),
        ),
      ),
    );
  }
}

class _PkFirePainter extends CustomPainter {
  final double t;

  _PkFirePainter({required this.t});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final baseY = size.height * 0.78;
    final glow = Paint()
      ..color = const Color(0xFFFF6A00).withValues(alpha: 0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawCircle(Offset(cx, baseY - 4), size.width * 0.42, glow);

    _tongue(canvas,
        cx: cx,
        baseY: baseY,
        w: size.width * 0.55,
        h: size.height * 0.78,
        phase: t,
        wobble: 0.9,
        color: const Color(0xFFE11D48));
    _tongue(canvas,
        cx: cx - size.width * 0.08,
        baseY: baseY,
        w: size.width * 0.38,
        h: size.height * 0.62,
        phase: t + 0.33,
        wobble: 1.2,
        color: const Color(0xFFFF6A00));
    _tongue(canvas,
        cx: cx + size.width * 0.06,
        baseY: baseY,
        w: size.width * 0.32,
        h: size.height * 0.55,
        phase: t + 0.66,
        wobble: 1.4,
        color: const Color(0xFFFFB020));
  }

  void _tongue(
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
      ..cubicTo(left - w * 0.05, baseY - h * 0.35, tipX - w * 0.25,
          tipY + h * 0.2, tipX, tipY)
      ..cubicTo(tipX + w * 0.25, tipY + h * 0.2, right + w * 0.05,
          baseY - h * 0.35, right, baseY)
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
  bool shouldRepaint(covariant _PkFirePainter oldDelegate) => oldDelegate.t != t;
}

class _VsBadge extends StatelessWidget {
  const _VsBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.8),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white24, width: 2),
      ),
      child: Text(
        'VS',
        style: TextStyleCustom.outFitSemiBold600(
          color: Colors.white,
          fontSize: 13,
        ),
      ),
    );
  }
}

class _BattlePane extends StatelessWidget {
  final Color teamColor;
  final String name;
  final String? photo;
  final Participant? participant;
  final bool mirrorLocal;

  const _BattlePane({
    required this.teamColor,
    required this.name,
    required this.photo,
    required this.participant,
    this.mirrorLocal = false,
  });

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFF0A0C10),
      child: LiveKitParticipantVideo(
        participant: participant,
        fit: VideoViewFit.contain,
        mirror: mirrorLocal && participant is LocalParticipant,
        placeholder: _Placeholder(
          name: name,
          photo: photo,
          accent: teamColor,
        ),
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  final String name;
  final String? photo;
  final Color accent;

  const _Placeholder({
    required this.name,
    required this.photo,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFF12151A),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomImage(
                size: const Size(64, 64),
                strokeWidth: 2,
                strokeColor: accent,
                image: photo?.addBaseURL(),
                fullName: name,
              ),
              const SizedBox(height: 8),
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyleCustom.outFitMedium500(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
