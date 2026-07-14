import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:krimson/model/chat/message_data.dart';
import 'package:krimson/screen/chat_screen/chat_screen_controller.dart';
import 'package:krimson/screen/chat_screen/widget/chat_media_helpers.dart';
import 'package:krimson/utilities/text_style_custom.dart';
import 'package:krimson/utilities/theme_res.dart';

class ChatStoryReplyMessage extends StatelessWidget {
  final ChatScreenController controller;
  final MessageData message;
  final bool isMe;

  const ChatStoryReplyMessage({
    super.key,
    required this.controller,
    required this.message,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    String preview = '';
    String replyText = message.textMessage ?? '';
    try {
      final map = jsonDecode(message.storyReplyMessage ?? '{}');
      if (map is Map) {
        preview = '${map['content'] ?? map['thumbnail'] ?? ''}';
        if (replyText.isEmpty) {
          replyText = '${map['reply'] ?? map['text'] ?? 'Story reply'}';
        }
      }
    } catch (_) {}

    return ChatBubble(
      isMe: isMe,
      padding: const EdgeInsets.all(6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: ChatNetworkMedia(
              path: preview.isEmpty ? null : preview,
              width: 44,
              height: 70,
            ),
          ),
          const SizedBox(width: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 160),
            child: Text(
              replyText.isEmpty ? 'Replied to story' : replyText,
              style: TextStyleCustom.outFitRegular400(
                color: textDarkGrey(context),
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
