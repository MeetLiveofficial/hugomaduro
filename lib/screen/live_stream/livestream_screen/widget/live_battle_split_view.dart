import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krimson/common/extensions/string_extension.dart';
import 'package:krimson/common/widget/custom_image.dart';
import 'package:krimson/common/widget/livekit/livekit_video_view.dart';
import 'package:krimson/screen/live_stream/livestream_screen/livestream_screen_controller.dart';
import 'package:krimson/utilities/color_res.dart';
import 'package:krimson/utilities/text_style_custom.dart';
import 'package:livekit_client/livekit_client.dart';

/// Vista PK: dos LIVE lado a lado (host = rojo / rival = azul).
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

      // Rojo = invitador (sala primaria); azul = rival.
      // Nunca usar hostId+opponentId de la sala local: en la del invitado
      // ambos apuntaban a él y duplicaban su cámara.
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
      final oppPct = total <= 0 ? 50 : (100 - hostPct);

      final teamAName = controller.isBattlePrimaryHost
          ? (controller.livestream.hostUser?.fullname ??
              controller.livestream.hostUser?.username ??
              'Host')
          : 'Invitador';
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

      return Stack(
        fit: StackFit.expand,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _BattlePane(
                  teamLabel: 'TEAM A',
                  teamColor: ColorRes.themeAccentSolid,
                  name: teamAName,
                  photo: teamAPhoto,
                  percent: hostPct,
                  coins: hostCoins,
                  participant: red,
                  mirrorLocal: red is LocalParticipant,
                ),
              ),
              Expanded(
                child: _BattlePane(
                  teamLabel: 'TEAM B',
                  teamColor: const Color(0xFF3B82F6),
                  name: teamBName,
                  photo: teamBPhoto,
                  percent: oppPct,
                  coins: oppCoins,
                  participant: blue,
                  mirrorLocal: blue is LocalParticipant,
                  alignEnd: true,
                ),
              ),
            ],
          ),
          // Barra de dominio arriba
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 5,
            child: Row(
              children: [
                Expanded(
                  flex: hostPct.clamp(1, 99),
                  child: const ColoredBox(color: ColorRes.themeAccentSolid),
                ),
                Expanded(
                  flex: oppPct.clamp(1, 99),
                  child: const ColoredBox(color: Color(0xFF3B82F6)),
                ),
              ],
            ),
          ),
          // VS central
          const Center(
            child: _VsBadge(),
          ),
        ],
      );
    });
  }
}

class _VsBadge extends StatelessWidget {
  const _VsBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.85),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white24, width: 2),
      ),
      child: Text(
        'VS',
        style: TextStyleCustom.outFitSemiBold600(
          color: Colors.white,
          fontSize: 14,
        ),
      ),
    );
  }
}

class _BattlePane extends StatelessWidget {
  final String teamLabel;
  final Color teamColor;
  final String name;
  final String? photo;
  final int percent;
  final int coins;
  final Participant? participant;
  final bool mirrorLocal;
  final bool alignEnd;

  const _BattlePane({
    required this.teamLabel,
    required this.teamColor,
    required this.name,
    required this.photo,
    required this.percent,
    required this.coins,
    required this.participant,
    this.mirrorLocal = false,
    this.alignEnd = false,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(
          color: Colors.black,
          child: LiveKitParticipantVideo(
            participant: participant,
            mirror: mirrorLocal && participant is LocalParticipant,
            placeholder: _Placeholder(
              name: name,
              photo: photo,
              accent: teamColor,
            ),
          ),
        ),
        // Gradiente inferior
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: 120,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.75),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          top: 14,
          left: alignEnd ? null : 10,
          right: alignEnd ? 10 : null,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: teamColor,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              teamLabel,
              style: TextStyleCustom.outFitSemiBold600(
                color: Colors.white,
                fontSize: 11,
              ),
            ),
          ),
        ),
        if (coins > 0)
          Positioned(
            top: 52,
            left: alignEnd ? 8 : null,
            right: alignEnd ? null : 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '+$coins',
                    style: TextStyleCustom.outFitMedium500(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.monetization_on, color: Colors.amber.shade400, size: 14),
                ],
              ),
            ),
          ),
        Positioned(
          left: 8,
          right: 8,
          bottom: 16,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyleCustom.outFitMedium500(
                  color: Colors.white,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '$percent%',
                style: TextStyleCustom.unboundedSemiBold600(
                  color: Colors.white,
                  fontSize: 22,
                ),
              ),
            ],
          ),
        ),
      ],
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomImage(
              size: const Size(72, 72),
              strokeWidth: 2,
              strokeColor: accent,
              image: photo?.addBaseURL(),
              fullName: name,
            ),
            const SizedBox(height: 10),
            Text(
              name,
              style: TextStyleCustom.outFitMedium500(
                color: Colors.white70,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Esperando cámara…',
              style: TextStyleCustom.outFitRegular400(
                color: Colors.white38,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
