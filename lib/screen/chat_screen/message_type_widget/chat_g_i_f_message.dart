import 'package:flutter/material.dart';
import 'package:krimson/model/chat/message_data.dart';
import 'package:krimson/screen/chat_screen/widget/chat_media_helpers.dart';

class ChatGIFMessage extends StatelessWidget {
  final MessageData message;

  const ChatGIFMessage({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return ChatBubble(
      isMe: false,
      padding: const EdgeInsets.all(4),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: ChatNetworkMedia(
          path: message.imageMessage,
          width: 180,
          height: 180,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
