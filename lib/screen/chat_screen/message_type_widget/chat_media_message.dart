import 'package:flutter/material.dart';
import 'package:krimson/model/chat/message_data.dart';
import 'package:krimson/screen/chat_screen/chat_screen_controller.dart';
import 'package:krimson/screen/chat_screen/widget/chat_media_helpers.dart';
import 'package:krimson/utilities/text_style_custom.dart';
import 'package:krimson/utilities/theme_res.dart';

class ChatMediaMessage extends StatelessWidget {
  final bool isMe;
  final MessageData message;
  final ChatScreenController controller;

  const ChatMediaMessage({
    super.key,
    required this.isMe,
    required this.message,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final isVideo = message.messageType == MessageType.video;
    final preview = isVideo
        ? (message.imageMessage ?? message.videoMessage)
        : message.imageMessage;
    final caption = (message.textMessage ?? '').trim();

    return ChatBubble(
      isMe: isMe,
      padding: const EdgeInsets.all(4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              alignment: Alignment.center,
              children: [
                ChatNetworkMedia(path: preview),
                if (isVideo)
                  const Icon(Icons.play_circle_outline,
                      color: Colors.white, size: 42),
              ],
            ),
          ),
          if (caption.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 4),
              child: Text(
                caption,
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
