import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krimson/common/manager/app_role.dart';
import 'package:krimson/common/widget/gift_media.dart';
import 'package:krimson/languages/languages_keys.dart';
import 'package:krimson/model/livestream/live_chat_message.dart';
import 'package:krimson/screen/call_screen/video_call_screen.dart';
import 'package:krimson/utilities/color_res.dart';
import 'package:krimson/utilities/text_style_custom.dart';

/// Chat overlay de llamada/Match: mismas burbujas y traducción lado a lado que LIVE.
class CallChatOverlay extends StatelessWidget {
  const CallChatOverlay({super.key, required this.controller});

  final VideoCallController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final items = controller.chatMessages.toList();
      if (items.isEmpty) return const SizedBox.shrink();
      final visible = items.length > VideoCallController.maxVisibleComments
          ? items.sublist(items.length - VideoCallController.maxVisibleComments)
          : items;
      return Align(
        alignment: Alignment.bottomLeft,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.28,
            maxWidth: MediaQuery.sizeOf(context).width * 0.72,
          ),
          child: ListView.builder(
            reverse: true,
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            itemCount: visible.length,
            itemBuilder: (context, index) {
              final msg = visible[visible.length - 1 - index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: _CallChatBubble(controller: controller, message: msg),
              );
            },
          ),
        ),
      );
    });
  }
}

class _CallChatBubble extends StatelessWidget {
  const _CallChatBubble({required this.controller, required this.message});

  final VideoCallController controller;
  final LiveChatMessage message;

  @override
  Widget build(BuildContext context) {
    final isGiftBoost = message.type == 'gift_boost';
    final canTapBoost = isGiftBoost && AppRole.canSendGifts();
    return Align(
      alignment: Alignment.centerLeft,
      child: Material(
        color: Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: canTapBoost ? () => controller.promptGiftBoost(message) : null,
          child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                message.userName,
                style: TextStyleCustom.outFitMedium500(
                  color: ColorRes.themeAccentSolid,
                  fontSize: 11,
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
              if (isGiftBoost)
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
                      path: message.giftImage,
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
              else if (message.type == 'gif' && (message.gifUrl ?? '').isNotEmpty)
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

class CallChatComposer extends StatelessWidget {
  const CallChatComposer({super.key, required this.controller});

  final VideoCallController controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Obx(() {
        final expanded = controller.chatComposerExpanded.value;
        if (expanded) {
          return Row(
            children: [
              Expanded(child: _CallChatField(controller: controller)),
              const SizedBox(width: 6),
              Material(
                color: Colors.black.withValues(alpha: 0.45),
                shape: const CircleBorder(),
                child: IconButton(
                  onPressed: controller.collapseChatComposer,
                  icon: const Icon(Icons.keyboard_hide_rounded,
                      color: Colors.white, size: 20),
                ),
              ),
            ],
          );
        }
        return Align(
          alignment: Alignment.centerLeft,
          child: Material(
            color: Colors.black.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(24),
            child: InkWell(
              borderRadius: BorderRadius.circular(24),
              onTap: controller.expandChatComposer,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Text(
                  LKey.sayHello.tr,
                  style: TextStyleCustom.outFitRegular400(
                    color: Colors.white,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _CallChatField extends StatelessWidget {
  const _CallChatField({required this.controller});

  final VideoCallController controller;

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
            child: TextField(
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
                hintText: LKey.sayHello.tr,
                hintStyle: TextStyleCustom.outFitRegular400(
                  color: Colors.white54,
                  fontSize: 14,
                ),
              ),
            ),
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
