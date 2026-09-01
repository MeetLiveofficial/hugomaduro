import 'package:flutter/material.dart';
import 'package:krimson/common/manager/app_role.dart';
import 'package:krimson/model/chat/message_data.dart';
import 'package:krimson/screen/chat_screen/widget/chat_media_helpers.dart';
import 'package:krimson/utilities/client_colors.dart';
import 'package:krimson/utilities/text_style_custom.dart';
import 'package:krimson/utilities/theme_res.dart';

class ChatTextMessage extends StatelessWidget {
  final bool isMe;
  final MessageData message;

  const ChatTextMessage({
    super.key,
    required this.isMe,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return ChatBubble(
      isMe: isMe,
      child: Text(
        message.displayText,
        style: TextStyleCustom.outFitRegular400(
          color: AppRole.isClient()
              ? ClientColors.textOnSurface
              : textDarkGrey(context),
          fontSize: 15,
        ),
      ),
    );
  }
}
