import 'package:flutter/material.dart';
import 'package:krimson/model/chat/message_data.dart';
import 'package:krimson/screen/chat_screen/chat_screen_controller.dart';
import 'package:krimson/screen/chat_screen/widget/chat_media_helpers.dart';
import 'package:krimson/utilities/text_style_custom.dart';
import 'package:krimson/utilities/theme_res.dart';

class ChatPostMessage extends StatelessWidget {
  final MessageData message;
  final ChatScreenController controller;

  const ChatPostMessage({
    super.key,
    required this.message,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final thumb = decodePostThumb(message.postMessage);
    final title = decodePostTitle(message.postMessage);
    return ChatBubble(
      isMe: message.userId == controller.myUser?.id,
      padding: const EdgeInsets.all(6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: ChatNetworkMedia(
              path: thumb,
              width: 56,
              height: 56,
            ),
          ),
          const SizedBox(width: 10),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 150),
            child: Text(
              title,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyleCustom.outFitRegular400(
                color: textDarkGrey(context),
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
