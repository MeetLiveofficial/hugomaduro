import 'package:flutter/material.dart';
import 'package:krimson/model/chat/message_data.dart';
import 'package:krimson/screen/chat_screen/chat_screen_controller.dart';
import 'package:krimson/screen/chat_screen/widget/chat_media_helpers.dart';
import 'package:krimson/utilities/text_style_custom.dart';
import 'package:krimson/utilities/theme_res.dart';

/// Used by chat_screen_controller for waveform sample width.
const double wavesWidth = 200;

class ChatAudioMessage extends StatelessWidget {
  final MessageData message;
  final ChatScreenController controller;

  const ChatAudioMessage({
    super.key,
    required this.message,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return ChatBubble(
      isMe: message.userId == controller.myUser?.id,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.graphic_eq, color: themeAccentSolid(context)),
          const SizedBox(width: 8),
          SizedBox(
            width: wavesWidth * 0.6,
            child: Text(
              'Voice message',
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
