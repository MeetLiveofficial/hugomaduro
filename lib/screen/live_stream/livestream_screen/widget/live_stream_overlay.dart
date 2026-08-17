import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krimson/common/extensions/string_extension.dart';
import 'package:krimson/common/service/livekit/livekit_room_service.dart';
import 'package:krimson/common/widget/custom_image.dart';
import 'package:krimson/common/widget/double_tap_detector.dart';
import 'package:krimson/common/widget/gift_media.dart';
import 'package:krimson/languages/languages_keys.dart';
import 'package:krimson/model/livestream/live_chat_message.dart';
import 'package:krimson/screen/live_stream/livestream_screen/livestream_screen_controller.dart';
import 'package:krimson/screen/live_stream/livestream_screen/widget/live_host_panel.dart';
import 'package:krimson/utilities/color_res.dart';
import 'package:krimson/utilities/level_avatar_style.dart';
import 'package:krimson/utilities/text_style_custom.dart';

String _liveJoinLabel(LiveChatMessage message) {
  if (message.isSvip || (message.userLevel ?? 0) >= 8) {
    return LKey.arrivedInStyle.tr;
  }
  if ((message.userLevel ?? 0) >= 4) {
    return LKey.joinedShort.tr;
  }
  return LKey.joinedTheLive.tr;
}

String _liveGiftLabel(LiveChatMessage message) {
  final coins = message.giftCoins;
  final base = LKey.sentAGift.tr;
  if (coins != null && coins > 0) {
    return '$base · $coins ${LKey.coins.tr}';
  }
  return base;
}

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
    // top: notch; bottom: false — immersive oculta nav; padding manual abajo.
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          10,
          6,
          10,
          10 + bottomInset + MediaQuery.viewPaddingOf(context).bottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _TopBar(controller: controller, onClose: onClose),
            const SizedBox(height: 4),
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
                padding: const EdgeInsets.only(top: 6),
                child: _FollowBanner(message: banner),
              );
            }),
            Obx(() {
              final banner = controller.joinBanner.value;
              if (banner == null) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(top: 6),
                child: _JoinLevelBanner(message: banner),
              );
            }),
            Obx(() {
              if (controller.isBattleWaiting.value) {
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: _BattleWaitingBanner(controller: controller),
                );
              }
              // Marcador BATALLA/fuego/timer va DEBAJO del video (LiveBattleSplitView).
              return const SizedBox.shrink();
            }),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return Stack(
                    clipBehavior: Clip.hardEdge,
                    children: [
                      // Doble tap cubre toda el área (incl. video PK).
                      Positioned.fill(
                        child: DoubleTapDetector(
                          onDoubleTap: (details) {
                            if (controller.isHost) return;
                            final box =
                                context.findRenderObject() as RenderBox?;
                            final local = box?.globalToLocal(
                                  details.globalPosition,
                                ) ??
                                details.localPosition;
                            controller.onBattleDoubleTap(
                              local,
                              Size(
                                constraints.maxWidth,
                                constraints.maxHeight,
                              ),
                            );
                          },
                          child: const ColoredBox(color: Colors.transparent),
                        ),
                      ),
                      // Flex (no SizedBox fijo): el spacer PK nunca supera el
                      // alto disponible → evita BOTTOM OVERFLOWED en web.
                      Positioned.fill(
                        child: Obx(() {
                          final battle = controller.isBattleRunning.value;
                          return Column(
                            children: [
                              if (battle)
                                const Flexible(
                                  flex: 58,
                                  child: SizedBox.expand(),
                                ),
                              Flexible(
                                flex: battle ? 42 : 100,
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    _TitleDescription(
                                        controller: controller),
                                    const SizedBox(height: 4),
                                    Expanded(
                                      child: _ChatList(
                                          controller: controller),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        }),
                      ),
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
                      Obx(() {
                        final result = controller.battleResultBanner.value;
                        if (result == null) return const SizedBox.shrink();
                        return Center(
                          child: _BattleResultCard(result: result),
                        );
                      }),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            if (!controller.isHost)
              _GiftIncentiveSlider(controller: controller),
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

class _BattleResultCard extends StatelessWidget {
  final BattleResultBanner result;

  const _BattleResultCard({required this.result});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.82),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: () {
          final w = MediaQuery.sizeOf(context).width - 48;
          return w > 320 ? 320.0 : w;
        }(),
        padding: const EdgeInsets.fromLTRB(22, 20, 22, 18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: result.isDraw
                ? Colors.amber.withValues(alpha: 0.85)
                : ColorRes.themeAccentSolid.withValues(alpha: 0.9),
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              result.isDraw ? LKey.pkDraw.tr : LKey.pkResult.tr,
              style: TextStyleCustom.outFitBold700(
                color: result.isDraw
                    ? Colors.amber
                    : ColorRes.themeAccentSolid,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 12),
            if (result.isDraw) ...[
              Text(
                '${result.winnerName}  =  ${result.loserName}',
                textAlign: TextAlign.center,
                style: TextStyleCustom.outFitSemiBold600(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${result.winnerCoins} - ${result.loserCoins}',
                style: TextStyleCustom.outFitMedium500(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
            ] else ...[
              Text(
                LKey.pkWon.tr,
                style: TextStyleCustom.outFitMedium500(
                  color: Colors.white54,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                result.winnerName,
                textAlign: TextAlign.center,
                style: TextStyleCustom.outFitBold700(
                  color: Colors.white,
                  fontSize: 20,
                ),
              ),
              Text(
                '${result.winnerCoins} ${LKey.coins.tr}',
                style: TextStyleCustom.outFitRegular400(
                  color: const Color(0xFFFFD56B),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                LKey.pkLost.tr,
                style: TextStyleCustom.outFitMedium500(
                  color: Colors.white54,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                result.loserName,
                textAlign: TextAlign.center,
                style: TextStyleCustom.outFitSemiBold600(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),
              Text(
                '${result.loserCoins} ${LKey.coins.tr}',
                style: TextStyleCustom.outFitRegular400(
                  color: Colors.white54,
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
                '${message.userName} ${LKey.isFollowingYou.tr}',
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

class _JoinLevelBanner extends StatelessWidget {
  final LiveChatMessage message;

  const _JoinLevelBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    final level = message.userLevel ?? 1;
    final svip = message.isSvip;
    final vip = message.isVip;
    final gradient = LevelAvatarStyle.ringGradient(level, svip: svip, vip: vip);
    final badge = vip ? '👑 VIP' : (svip ? LKey.svip.tr : 'Lv. $level');
    final subtitle = _liveJoinLabel(message);

    return Material(
      borderRadius: BorderRadius.circular(14),
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              gradient.colors.first.withValues(alpha: 0.95),
              gradient.colors.last.withValues(alpha: 0.88),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: gradient.colors.last.withValues(alpha: 0.35),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.28),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.35),
                  ),
                ),
                child: Text(
                  badge,
                  style: TextStyleCustom.outFitMedium500(
                    color: Colors.white,
                    fontSize: 11,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      message.userName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyleCustom.outFitMedium500(
                        color: Colors.white,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyleCustom.outFitRegular400(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                svip || level >= 8
                    ? Icons.auto_awesome_rounded
                    : Icons.waving_hand_rounded,
                color: Colors.white,
                size: 18,
              ),
            ],
          ),
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
          ? LKey.waitingBattleResponse.tr
          : LKey.waitingForUser.trParams({'name': name});
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
              LKey.battle.tr.toUpperCase(),
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
            LKey.paused.tr,
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

/// Botón circular solo-icono (Batalla / Mic / Regalos / Tareas).
class _LiveIconBtn extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final bool accent;
  final bool danger;

  const _LiveIconBtn({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.accent = false,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    final bg = accent
        ? ColorRes.themeAccentSolid.withValues(alpha: 0.95)
        : danger
            ? const Color(0xFFE11D48).withValues(alpha: 0.9)
            : Colors.black.withValues(alpha: 0.45);

    return Tooltip(
      message: tooltip,
      child: Material(
        color: bg,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: 40,
            height: 40,
            child: Icon(icon, color: Colors.white, size: 20),
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

    return SizedBox(
      width: double.infinity,
      height: 44,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Host a la izquierda.
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Material(
                  color: Colors.black.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(28),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(4, 4, 8, 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        InkWell(
                          borderRadius: BorderRadius.circular(24),
                          onTap: controller.openHostProfile,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CustomImage(
                                size: const Size(32, 32),
                                image: photo?.addBaseURL(),
                                fullName: name,
                                strokeWidth: 0,
                              ),
                              const SizedBox(width: 6),
                              ConstrainedBox(
                                constraints:
                                    const BoxConstraints(maxWidth: 90),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style:
                                          TextStyleCustom.outFitSemiBold600(
                                        color: Colors.white,
                                        fontSize: 12,
                                      ),
                                    ),
                                    Obx(() => Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.favorite,
                                                size: 10,
                                                color: Colors.white
                                                    .withValues(alpha: 0.75)),
                                            const SizedBox(width: 2),
                                            Text(
                                              '${controller.likeCount.value}',
                                              style: TextStyleCustom
                                                  .outFitRegular400(
                                                color: Colors.white70,
                                                fontSize: 10,
                                              ),
                                            ),
                                          ],
                                        )),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        if (!controller.isHost)
                          Obx(() {
                            if (controller.isFollowingHost.value) {
                              return _LiveStatusChip(controller: controller);
                            }
                            return Material(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: controller.isFollowBusy.value
                                    ? null
                                    : controller.followHost,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 6),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.favorite,
                                          size: 12,
                                          color: ColorRes.themeAccentSolid),
                                      const SizedBox(width: 3),
                                      Text(
                                        LKey.follow.tr,
                                        style: TextStyleCustom
                                            .outFitSemiBold600(
                                          color: ColorRes.themeAccentSolid,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          })
                        else
                          _LiveStatusChip(controller: controller),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Bloque derecho: contribuidores + viewers + X (al borde).
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _TopContributors(controller: controller, compact: true),
              const SizedBox(width: 6),
              Obx(() => _Pill(
                    label: '${controller.watchingCount.value}',
                  )),
              const SizedBox(width: 4),
              _LiveIconBtn(
                icon: Icons.close_rounded,
                tooltip: LKey.exitLiveStream.tr,
                onTap: onClose,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LiveStatusChip extends StatelessWidget {
  final LivestreamScreenController controller;

  const _LiveStatusChip({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final battle = controller.isBattleRunning.value;
      final inCall = controller.hostInCall.value;
      final elapsed = controller.liveElapsedSeconds.value;
      final mm = (elapsed ~/ 60).toString().padLeft(2, '0');
      final ss = (elapsed % 60).toString().padLeft(2, '0');
      final hh = elapsed ~/ 3600;
      final timeLabel = hh > 0
          ? '${hh.toString().padLeft(2, '0')}:$mm:$ss'
          : '$mm:$ss';
      final statusLabel = inCall ? LKey.inCall.tr : (battle ? 'PK' : 'LIVE');
      final statusColor = inCall
          ? const Color(0xFFE67E22)
          : ColorRes.themeAccentSolid;
      return Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
            decoration: BoxDecoration(
              color: statusColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              statusLabel,
              style: TextStyleCustom.outFitSemiBold600(
                color: Colors.white,
                fontSize: 10,
              ),
            ),
          ),
          if (!battle) ...[
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                timeLabel,
                style: TextStyleCustom.outFitMedium500(
                  color: Colors.white,
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ],
      );
    });
  }
}

/// Avatares del top 3 por monedas; el #1 lleva marco destacado.
/// Visible para host y audiencia (misma pastilla del header).
class _TopContributors extends StatelessWidget {
  final LivestreamScreenController controller;
  final bool compact;

  const _TopContributors({
    required this.controller,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final items = controller.giftSenders.toList()
        ..sort((a, b) => b.totalCoins.compareTo(a.totalCoins));
      final top = items.take(3).toList();
      if (top.isEmpty) return const SizedBox.shrink();

      // Izquierda → derecha: 3º, 2º, 1º (el top queda junto a LIVE).
      final ordered = top.reversed.toList();
      final overlap = compact ? 13.0 : 16.0;
      final avatarBase = compact ? 20.0 : 22.0;

      return InkWell(
        onTap: controller.openGiftSendersSheet,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: EdgeInsets.only(
            left: compact ? 4 : 2,
            right: compact ? 2 : 2,
            top: 2,
            bottom: 2,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: avatarBase + (ordered.length - 1) * overlap + 4,
                height: compact ? 26 : 30,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    for (var i = 0; i < ordered.length; i++)
                      Positioned(
                        left: i * overlap,
                        child: _ContributorAvatar(
                          sender: ordered[i],
                          isTop: ordered[i].userId == top.first.userId,
                          rank: items.indexWhere(
                                  (e) => e.userId == ordered[i].userId) +
                              1,
                          compact: compact,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}

class _ContributorAvatar extends StatelessWidget {
  final LiveGiftSender sender;
  final bool isTop;
  final int rank;
  final bool compact;

  const _ContributorAvatar({
    required this.sender,
    required this.isTop,
    required this.rank,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final size = compact
        ? (isTop ? 22.0 : 20.0)
        : (isTop ? 28.0 : 24.0);
    final ring = isTop
        ? Colors.amber.shade400
        : rank == 2
            ? const Color(0xFFC0C0C0)
            : const Color(0xFFCD7F32);

    return SizedBox(
      width: size + (isTop ? 4 : 0),
      height: size + (isTop ? 6 : 0),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: ring, width: isTop ? 2 : 1.4),
              boxShadow: isTop
                  ? [
                      BoxShadow(
                        color: Colors.amber.withValues(alpha: 0.45),
                        blurRadius: 5,
                      ),
                    ]
                  : null,
            ),
            child: CustomImage(
              size: Size(size, size),
              fullName: sender.userName,
              strokeWidth: 0,
            ),
          ),
          if (isTop)
            Positioned(
              top: -4,
              child: Icon(
                Icons.workspace_premium_rounded,
                size: compact ? 10 : 12,
                color: Colors.amber.shade400,
              ),
            ),
        ],
      ),
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
      return LayoutBuilder(
        builder: (context, constraints) {
          final maxH = constraints.maxHeight.isFinite
              ? constraints.maxHeight
              : MediaQuery.sizeOf(context).height * 0.22;
          final w = constraints.maxWidth.isFinite
              ? constraints.maxWidth.clamp(120.0, MediaQuery.sizeOf(context).width * 0.72)
              : MediaQuery.sizeOf(context).width * 0.72;
          return Align(
            alignment: Alignment.bottomLeft,
            child: SizedBox(
              height: maxH,
              width: w,
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
            ),
          );
        },
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
    final isGiftBoost = message.type == 'gift_boost';

    return Align(
      alignment: Alignment.centerLeft,
      child: Material(
        color: Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: isGiftBoost && !controller.isHost
              ? () => controller.sendGiftDirectly(
                    giftId: message.giftId,
                    giftImage: message.giftImage,
                    coinPrice: message.giftCoins,
                  )
              : (canReply ? () => controller.setReplyTo(message) : null),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => controller.openChatUserProfile(message),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          message.userName,
                          style: TextStyleCustom.outFitMedium500(
                            color: ColorRes.themeAccentSolid,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      if (message.type == 'join' &&
                          (message.userLevel ?? 0) > 0) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            gradient: LevelAvatarStyle.ringGradient(
                              message.userLevel ?? 1,
                              svip: message.isSvip,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            message.isSvip
                                ? LKey.svip.tr
                                : 'Lv.${message.userLevel}',
                            style: TextStyleCustom.outFitMedium500(
                              color: Colors.white,
                              fontSize: 9,
                            ),
                          ),
                        ),
                      ],
                    ],
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
                    '${LKey.isFollowingYou.tr}',
                    style: TextStyleCustom.outFitMedium500(
                      color: Colors.white,
                      fontSize: 13,
                    ),
                  )
                else if (message.type == 'join')
                  Text(
                    _liveJoinLabel(message),
                    style: TextStyleCustom.outFitMedium500(
                      color: Colors.white.withValues(alpha: 0.92),
                      fontSize: 13,
                    ),
                  )
                else if (message.type == 'call_invite')
                  Text(
                    '📞 ${LKey.invitesToPrivateCall.tr}'
                    '${message.giftCoins != null && message.giftCoins! > 0 ? ' · ${message.giftCoins} ${LKey.coins.tr}' : ''}',
                    style: TextStyleCustom.outFitMedium500(
                      color: ColorRes.accentPeach,
                      fontSize: 13,
                    ),
                  )
                else if (message.type == 'gift_boost')
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          message.text ?? LKey.sendMeGifts.tr,
                          style: TextStyleCustom.outFitMedium500(
                            color: ColorRes.accentPeach,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      GiftMedia(
                        path: (message.giftImage ?? '').isNotEmpty
                            ? message.giftImage
                            : controller.resolveGiftImage(message.giftId),
                        width: 28,
                        height: 28,
                        fit: BoxFit.contain,
                        muted: true,
                        looping: true,
                        placeholder: const Icon(
                          Icons.card_giftcard,
                          color: ColorRes.accentPeach,
                          size: 22,
                        ),
                      ),
                    ],
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
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: GiftMedia(
                          path: (message.giftImage ?? '').isNotEmpty
                              ? message.giftImage
                              : controller.resolveGiftImage(message.giftId),
                          width: 36,
                          height: 36,
                          fit: BoxFit.contain,
                          muted: true,
                          looping: true,
                          placeholder: const Icon(
                            Icons.card_giftcard,
                            color: Colors.white70,
                            size: 28,
                          ),
                        ),
                      ),
                      Flexible(
                        child: Text(
                          _liveGiftLabel(message),
                          style: TextStyleCustom.outFitRegular400(
                            color: Colors.white,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  )
                else
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        message.displayText,
                        style: TextStyleCustom.outFitRegular400(
                          color: Colors.white,
                          fontSize: 13,
                        ),
                      ),
                      if (message.isTranslated) ...[
                        const SizedBox(height: 2),
                        Text(
                          message.originalText ?? '',
                          style: TextStyleCustom.outFitRegular400(
                            color: Colors.white54,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ],
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
              color: ColorRes.likeRed.withValues(alpha: 0.95),
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
    final title = controller.liveTitle.trim();
    final desc = controller.liveDescription.trim();
    if (title.isEmpty && desc.isEmpty) return const SizedBox.shrink();

    final maxW = MediaQuery.sizeOf(context).width * 0.68;
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxW),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (title.isNotEmpty)
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyleCustom.outFitSemiBold600(
                  color: Colors.white,
                  fontSize: 13,
                ),
              ),
            if (desc.isNotEmpty) ...[
              if (title.isNotEmpty) const SizedBox(height: 2),
              Text(
                desc,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyleCustom.outFitRegular400(
                  color: Colors.white70,
                  fontSize: 11,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _GiftIncentiveSlider extends StatelessWidget {
  final LivestreamScreenController controller;

  const _GiftIncentiveSlider({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final sendingId = controller.sendingGiftId.value;
      final count = controller.giftIncentives.length;
      if (count <= 0) return const SizedBox.shrink();
      final slots = controller.giftIncentives
          .where((e) => e.isConfigured)
          .toList(growable: false);
      if (slots.isEmpty) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: SizedBox(
          height: 56,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 2),
            itemCount: slots.length,
            separatorBuilder: (_, __) => const SizedBox(width: 6),
            itemBuilder: (context, index) {
              final slot = slots[index];
              final msg = slot.trimmedMessage;
              final sending = sendingId != null && sendingId == slot.giftId;
              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    if (controller.isHost) return;
                    if (controller.sendingGiftId.value != null) return;
                    controller.sendIncentiveGift(slot);
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 108,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: sending
                            ? ColorRes.themeAccentSolid
                            : Colors.white24,
                      ),
                    ),
                    child: Stack(
                      children: [
                        Row(
                          children: [
                            IgnorePointer(
                              child: GiftMedia(
                                path: slot.image,
                                width: 32,
                                height: 32,
                                fit: BoxFit.contain,
                                muted: true,
                                looping: true,
                                placeholder: const Icon(
                                  Icons.card_giftcard,
                                  color: ColorRes.accentPeach,
                                  size: 22,
                                ),
                              ),
                            ),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    msg.isEmpty ? LKey.giftMe.tr : msg,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyleCustom.outFitMedium500(
                                      color: Colors.white,
                                      fontSize: 11,
                                    ),
                                  ),
                                  Text(
                                    '(${slot.coinPrice ?? 0})',
                                    style: TextStyleCustom.outFitRegular400(
                                      color: ColorRes.accentPeach,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (sending)
                          Positioned.fill(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.45),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Center(
                                child: SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: ColorRes.themeAccentSolid,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      );
    });
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
                        '${LKey.replyingTo.tr} ${reply.userName}'
                        '${reply.displayText.isNotEmpty ? ': ${reply.displayText}' : ''}',
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
        Obx(() {
          final expanded = controller.chatComposerExpanded.value ||
              controller.replyingTo.value != null;
          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (expanded)
                Expanded(child: _ExpandedChatField(controller: controller))
              else
                _DiHolaChip(onTap: controller.expandChatComposer),
              if (!expanded) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (showHostControls) ..._hostActions(controller),
                          if (!controller.isHost)
                            ..._audienceActions(controller),
                        ],
                      ),
                    ),
                  ),
                ),
              ] else ...[
                const SizedBox(width: 6),
                _CircleBtn(
                  icon: Icons.keyboard_hide_rounded,
                  onTap: controller.collapseChatComposer,
                ),
              ],
            ],
          );
        }),
      ],
    );
  }

  List<Widget> _hostActions(LivestreamScreenController c) {
    return [
      _BadgeIconBtn(
        icon: Icons.card_giftcard_rounded,
        tooltip: LKey.boostGifts.tr,
        accent: true,
        onTap: c.openGiftBoostSheet,
      ),
      const SizedBox(width: 6),
      _BadgeIconBtn(
        icon: Icons.call_rounded,
        tooltip: LKey.inviteToCall.tr,
        accent: true,
        onTap: c.inviteAudienceToCall,
      ),
      const SizedBox(width: 6),
      Obx(() => _BadgeIconBtn(
            icon: Icons.chat_bubble_outline_rounded,
            tooltip: LKey.chats.tr,
            badge: c.unreadChatCount.value,
            onTap: c.openUnreadChatsSheet,
          )),
      const SizedBox(width: 6),
      _LiveIconBtn(
        icon: Icons.task_alt_rounded,
        tooltip: LKey.tasks.tr,
        onTap: c.openLiveTasksSheet,
      ),
      const SizedBox(width: 6),
      Obx(() {
        final battleOn =
            c.isBattleRunning.value || c.isBattleWaiting.value;
        return _LiveIconBtn(
          icon: battleOn
              ? Icons.flag_rounded
              : Icons.sports_kabaddi_rounded,
          tooltip: battleOn ? LKey.endBattle.tr : LKey.battle.tr,
          accent: !battleOn,
          danger: battleOn,
          onTap: c.openBattle,
        );
      }),
      const SizedBox(width: 6),
      Obx(() {
        final paused = c.isStreamPaused.value;
        final muted = c.liveKit == null
            ? c.isLiveAudioMuted.value
            : !(c.liveKit!.microphoneEnabled.value);
        final qualityText = c.liveKit == null
            ? LKey.qualityLow.tr
            : switch (c.liveKit!.qualityProfile.value) {
                LiveKitQualityProfile.low => LKey.qualityLow.tr,
                LiveKitQualityProfile.medium => LKey.qualityMedium.tr,
                LiveKitQualityProfile.high => LKey.qualityHigh.tr,
              };
        final hasReceivedGifts = c.giftSenders.isNotEmpty;
        return _LiveIconBtn(
          icon: Icons.tune_rounded,
          tooltip: LKey.options.tr,
          onTap: () => openLiveHostOptionsMenu(
            onInvite: c.openInvite,
            onQuality: c.openQualitySheet,
            onPause: c.togglePauseLive,
            onMic: c.toggleLiveAudioMute,
            onCamera: c.liveKit?.toggleCamera,
            onGiftSenders: c.openGiftSendersSheet,
            giftSendersSubtitle: hasReceivedGifts
                ? LKey.seeGiftSenders.tr
                : LKey.noGiftsYet.tr,
            qualityLabel: qualityText,
            paused: paused,
            muted: muted,
            cameraOn: c.liveKit?.cameraEnabled.value,
          ),
        );
      }),
    ];
  }

  List<Widget> _audienceActions(LivestreamScreenController c) {
    return [
      Obx(() => _BadgeIconBtn(
            icon: Icons.chat_bubble_outline_rounded,
            tooltip: LKey.chats.tr,
            badge: c.unreadChatCount.value,
            onTap: c.openUnreadChatsSheet,
          )),
      const SizedBox(width: 6),
      _CircleBtn(
        icon: Icons.high_quality_rounded,
        onTap: c.openQualitySheet,
      ),
      const SizedBox(width: 6),
      Material(
        color: ColorRes.themeAccentSolid,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: c.openPrivateCall,
          child: SizedBox(
            height: 40,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.call, color: Colors.white, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    LKey.privateCall.tr,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      const SizedBox(width: 6),
      Obx(() => _CircleBtn(
            icon: Icons.favorite,
            onTap: c.isLiking.value ? null : c.sendLike,
          )),
      const SizedBox(width: 6),
      _CircleBtn(
        icon: Icons.card_giftcard_outlined,
        onTap: c.openGiftSheet,
      ),
    ];
  }
}

class _DiHolaChip extends StatelessWidget {
  const _DiHolaChip({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.45),
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: SizedBox(
          height: 40,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.chat_bubble_outline_rounded,
                    color: Colors.white70, size: 16),
                const SizedBox(width: 6),
                Text(
                  LKey.sayHello.tr,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
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

class _ExpandedChatField extends StatelessWidget {
  const _ExpandedChatField({required this.controller});

  final LivestreamScreenController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      padding: const EdgeInsets.only(left: 14, right: 2),
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
                focusNode: controller.commentFocusNode,
                autofocus: true,
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
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  hintText: reply != null
                      ? '${LKey.reply.tr} ${reply.userName}…'
                      : LKey.sayHello.tr,
                  hintStyle: TextStyleCustom.outFitRegular400(
                    color: Colors.white54,
                    fontSize: 14,
                  ),
                ),
              );
            }),
          ),
          SizedBox(
            width: 40,
            height: 40,
            child: IconButton(
              padding: EdgeInsets.zero,
              onPressed: () =>
                  controller.sendComment(controller.commentController.text),
              icon: const Icon(Icons.send_rounded,
                  color: ColorRes.themeAccentSolid, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

class _BadgeIconBtn extends StatelessWidget {
  const _BadgeIconBtn({
    required this.icon,
    required this.onTap,
    this.tooltip,
    this.badge = 0,
    this.accent = false,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;
  final int badge;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    final btn = Material(
      color: accent
          ? ColorRes.themeAccentSolid.withValues(alpha: 0.9)
          : Colors.black.withValues(alpha: 0.45),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              Icon(icon, color: Colors.white, size: 20),
                  if (badge > 0)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    constraints: const BoxConstraints(minWidth: 14),
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    height: 14,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: ColorRes.themeAccentSolid,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.black54, width: 1),
                    ),
                    child: Text(
                      badge > 99 ? '99+' : '$badge',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
    if ((tooltip ?? '').isEmpty) return btn;
    return Tooltip(message: tooltip!, child: btn);
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
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      ),
    );
  }
}
