import 'package:flutter/material.dart';
import 'package:krimson/common/widget/gift_media.dart';
import 'package:krimson/model/chat/message_data.dart';
import 'package:krimson/screen/chat_screen/widget/chat_media_helpers.dart';
import 'package:krimson/utilities/text_style_custom.dart';
import 'package:krimson/utilities/theme_res.dart';

class ChatGiftMessage extends StatelessWidget {
  final MessageData message;
  final bool isMe;

  const ChatGiftMessage({
    super.key,
    required this.message,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    final coins = message.textMessage ?? '0';
    return ChatBubble(
      isMe: isMe,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GiftMedia(
            path: message.imageMessage,
            width: 48,
            height: 48,
            fit: BoxFit.contain,
            muted: true,
            looping: true,
            placeholder: Icon(
              Icons.card_giftcard,
              size: 36,
              color: textLightGrey(context),
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Gift',
                style: TextStyleCustom.outFitMedium500(
                  color: textDarkGrey(context),
                  fontSize: 13,
                ),
              ),
              Text(
                '$coins coins',
                style: TextStyleCustom.outFitRegular400(
                  color: textLightGrey(context),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
