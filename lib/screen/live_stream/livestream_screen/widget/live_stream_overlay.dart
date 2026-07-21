import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krimson/common/service/livekit/livekit_room_service.dart';
import 'package:krimson/common/widget/custom_image.dart';
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
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (controller.liveKit?.qualityProfile.value ==
                          LiveKitQualityProfile.low)
                        const Padding(
                          padding: EdgeInsets.only(right: 6),
                          child: _Pill(label: 'LOW'),
                        ),
                      _Pill(
                        label:
                            '${controller.pingMs.value} ms · ${controller.fps.value} fps',
                      ),
                    ],
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
            Expanded(
              child: Stack(
                children: [
                  Align(
                    alignment: Alignment.bottomLeft,
                    child: _ChatList(controller: controller),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
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
            _LiveActionRow(controller: controller),
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

/// Pause / mute / regalos — controles visibles del LIVE.
class _LiveActionRow extends StatelessWidget {
  final LivestreamScreenController controller;

  const _LiveActionRow({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final paused = controller.isStreamPaused.value;
      final muted = controller.isLiveAudioMuted.value;
      final gifts = controller.giftSenders.length;
      return Row(
        children: [
          _ActionChip(
            icon: paused ? Icons.play_arrow_rounded : Icons.pause_rounded,
            label: paused ? 'Reanudar' : 'Pausar',
            onTap: controller.togglePauseLive,
          ),
          const SizedBox(width: 6),
          _ActionChip(
            icon: muted ? Icons.mic_off_rounded : Icons.mic_rounded,
            label: muted ? 'Unmute' : 'Mute',
            onTap: controller.toggleLiveAudioMute,
          ),
          const SizedBox(width: 6),
          _ActionChip(
            icon: Icons.card_giftcard_rounded,
            label: gifts > 0 ? 'Regalos ($gifts)' : 'Regalos',
            onTap: controller.openGiftSendersSheet,
          ),
        ],
      );
    });
  }
}

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.5),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
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
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: ColorRes.themeAccentSolid,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'LIVE',
                      style: TextStyleCustom.outFitMedium500(
                        color: Colors.white,
                        fontSize: 10,
                      ),
                    ),
                  ),
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
                          '${message.giftCoins != null ? ' · ${message.giftCoins}' : ''}',
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
      final n = controller.floatingLikes.value.clamp(0, 6);
      if (n == 0) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < n; i++)
              Padding(
                padding: EdgeInsets.only(bottom: 4.0 + i),
                child: Icon(
                  Icons.favorite,
                  color: ColorRes.themeAccentSolid.withValues(alpha: 0.85),
                  size: 22 + (i % 3) * 2,
                ),
              ),
          ],
        ),
      );
    });
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
                child: Row(
                  children: [
                    const Spacer(),
                    LiveHostActionBar(
                      onBeauty: controller.openBeauty,
                      onInvite: controller.openInvite,
                      networkLabel: controller.networkLabel,
                    ),
                  ],
                ),
              );
            }
            return Obx(() {
              final micOn = lk.microphoneEnabled.value;
              final camOn = lk.cameraEnabled.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () async {
                        await lk.toggleMicrophone();
                        controller.isLiveAudioMuted.value =
                            !lk.microphoneEnabled.value;
                      },
                      icon: Icon(
                        micOn ? Icons.mic : Icons.mic_off,
                        color: Colors.white,
                      ),
                    ),
                    IconButton(
                      onPressed: lk.toggleCamera,
                      icon: Icon(
                        camOn ? Icons.videocam : Icons.videocam_off,
                        color: Colors.white,
                      ),
                    ),
                    const Spacer(),
                    LiveHostActionBar(
                      onBeauty: controller.openBeauty,
                      onInvite: controller.openInvite,
                      networkLabel: controller.networkLabel,
                    ),
                  ],
                ),
              );
            });
          }),
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
