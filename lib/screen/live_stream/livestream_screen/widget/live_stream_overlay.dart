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
import 'package:krimson/utilities/text_style_custom.dart';

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
            _ComposerRow(
              controller: controller,
              showHostControls: showHostControls,
              onClose: onClose,
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
              result.isDraw ? 'EMPATE' : 'RESULTADO PK',
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
                'GANÓ',
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
                '${result.winnerCoins} monedas',
                style: TextStyleCustom.outFitRegular400(
                  color: const Color(0xFFFFD56B),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'PERDIÓ',
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
                '${result.loserCoins} monedas',
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

/// Regalos: icono limpio + punto rojo (sin número grande).
class _GiftIconBtn extends StatelessWidget {
  final bool hasGifts;
  final VoidCallback onTap;

  const _GiftIconBtn({required this.hasGifts, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Regalos',
      child: Material(
        color: Colors.black.withValues(alpha: 0.45),
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
                const Icon(Icons.card_giftcard_outlined,
                    color: Colors.white, size: 20),
                if (hasGifts)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: ColorRes.themeAccentSolid,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white24, width: 0.8),
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
                                        'Unirse',
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
      final elapsed = controller.liveElapsedSeconds.value;
      final mm = (elapsed ~/ 60).toString().padLeft(2, '0');
      final ss = (elapsed % 60).toString().padLeft(2, '0');
      final hh = elapsed ~/ 3600;
      final timeLabel = hh > 0
          ? '${hh.toString().padLeft(2, '0')}:$mm:$ss'
          : '$mm:$ss';
      return Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
            decoration: BoxDecoration(
              color: ColorRes.themeAccentSolid,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              battle ? 'PK' : 'LIVE',
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
                else if (message.type == 'join')
                  Text(
                    message.text ?? 'entró al LIVE',
                    style: TextStyleCustom.outFitMedium500(
                      color: Colors.white.withValues(alpha: 0.92),
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
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: GiftMedia(
                          path: (message.giftImage ?? '').isNotEmpty
                              ? message.giftImage
                              : controller.resolveGiftImage(message.giftId),
                          width: 36,
                          height: 36,
                          fit: BoxFit.contain,
                          placeholder: const Icon(
                            Icons.card_giftcard,
                            color: Colors.white70,
                            size: 28,
                          ),
                        ),
                      ),
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

class _ComposerRow extends StatelessWidget {
  final LivestreamScreenController controller;
  final bool showHostControls;
  final VoidCallback onClose;

  const _ComposerRow({
    required this.controller,
    required this.showHostControls,
    required this.onClose,
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
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Container(
                height: 40,
                padding: const EdgeInsets.only(left: 14, right: 2),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
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
                            contentPadding: const EdgeInsets.symmetric(
                                vertical: 10),
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
                    SizedBox(
                      width: 40,
                      height: 40,
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        onPressed: () => controller
                            .sendComment(controller.commentController.text),
                        icon: const Icon(Icons.send_rounded,
                            color: ColorRes.themeAccentSolid, size: 20),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Acciones fijas, misma altura/eje que el input (sin FittedBox).
            if (showHostControls) ...[
              const SizedBox(width: 6),
              Obx(() => _GiftIconBtn(
                    hasGifts: controller.giftSenders.isNotEmpty,
                    onTap: controller.openGiftSendersSheet,
                  )),
              const SizedBox(width: 6),
              _LiveIconBtn(
                icon: Icons.task_alt_rounded,
                tooltip: LKey.tasks.tr,
                onTap: controller.openLiveTasksSheet,
              ),
              const SizedBox(width: 6),
              Obx(() {
                final battleOn = controller.isBattleRunning.value ||
                    controller.isBattleWaiting.value;
                return _LiveIconBtn(
                  icon: battleOn
                      ? Icons.flag_rounded
                      : Icons.sports_kabaddi_rounded,
                  tooltip: battleOn ? 'Fin batalla' : 'Batalla',
                  accent: !battleOn,
                  danger: battleOn,
                  onTap: controller.openBattle,
                );
              }),
              const SizedBox(width: 6),
              Obx(() {
                final paused = controller.isStreamPaused.value;
                final muted = controller.liveKit == null
                    ? controller.isLiveAudioMuted.value
                    : !(controller.liveKit!.microphoneEnabled.value);
                final battleOn = controller.isBattleRunning.value ||
                    controller.isBattleWaiting.value;
                final qualityText = controller.liveKit == null
                    ? 'Baja'
                    : switch (controller.liveKit!.qualityProfile.value) {
                        LiveKitQualityProfile.low => 'Baja',
                        LiveKitQualityProfile.medium => 'Media',
                        LiveKitQualityProfile.high => 'Alta',
                      };
                return _LiveIconBtn(
                  icon: Icons.tune_rounded,
                  tooltip: 'Options',
                  onTap: () => openLiveHostOptionsMenu(
                    onBeauty: controller.openBeauty,
                    onInvite: controller.openInvite,
                    onBattle: controller.openBattle,
                    onQuality: controller.openQualitySheet,
                    onPause: controller.togglePauseLive,
                    onMic: controller.toggleLiveAudioMute,
                    onCamera: controller.liveKit?.toggleCamera,
                    networkLabel: controller.networkLabel,
                    qualityLabel: qualityText,
                    battleRunning: battleOn,
                    paused: paused,
                    muted: muted,
                    cameraOn: controller.liveKit?.cameraEnabled.value,
                  ),
                );
              }),
              const SizedBox(width: 6),
              _LiveIconBtn(
                icon: Icons.close_rounded,
                tooltip: LKey.exitLiveStream.tr,
                danger: true,
                onTap: onClose,
              ),
            ],
            if (!controller.isHost) ...[
              const SizedBox(width: 6),
              _CircleBtn(
                icon: Icons.high_quality_rounded,
                onTap: controller.openQualitySheet,
              ),
              const SizedBox(width: 6),
              Material(
                color: ColorRes.themeAccentSolid,
                borderRadius: BorderRadius.circular(20),
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: controller.openPrivateCall,
                  child: const SizedBox(
                    height: 40,
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.call, color: Colors.white, size: 16),
                          SizedBox(width: 4),
                          Text(
                            'Private',
                            style: TextStyle(
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
                    onTap: controller.isLiking.value
                        ? null
                        : controller.sendLike,
                  )),
              const SizedBox(width: 6),
              _CircleBtn(
                icon: Icons.card_giftcard_outlined,
                onTap: controller.openGiftSheet,
              ),
              // Sin X abajo: la audiencia ya tiene el de la barra superior.
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
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      ),
    );
  }
}
