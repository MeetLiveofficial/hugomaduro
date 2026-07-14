import 'package:flutter/material.dart';
import 'package:krimson/utilities/color_res.dart';
import 'package:krimson/utilities/theme_res.dart';

enum UserRequestAction {
  block,
  reject,
  accept;

  static const Map<UserRequestAction, String> titles = {
    UserRequestAction.block: 'block',
    UserRequestAction.reject: 'reject',
    UserRequestAction.accept: 'accept',
  };

  static Map<UserRequestAction, Color> colors(BuildContext context) => {
        UserRequestAction.block: bgGrey(context),
        UserRequestAction.reject: ColorRes.likeRed.withValues(alpha: .15),
        UserRequestAction.accept: ColorRes.green.withValues(alpha: .15),
      };

  static Map<UserRequestAction, Color> titleColors(BuildContext context) => {
        UserRequestAction.block: textDarkGrey(context),
        UserRequestAction.reject: ColorRes.likeRed,
        UserRequestAction.accept: ColorRes.green,
      };

  String get title => titles[this]!;

  Color color(BuildContext context) => colors(context)[this]!;

  Color titleColor(BuildContext context) => titleColors(context)[this]!;
}

enum ChatAction {
  gift,
  audio,
  media;

  /// Iconos Material ligeros (sin PNG pesados).
  IconData get icon {
    switch (this) {
      case ChatAction.gift:
        return Icons.card_giftcard_outlined;
      case ChatAction.audio:
        return Icons.mic_none_outlined;
      case ChatAction.media:
        return Icons.image_outlined;
    }
  }

  static List<ChatAction> getChatActions({required bool isGiphyEnabled}) {
    // Stickers/emojis removed from chat input by product request.
    return const [ChatAction.gift, ChatAction.audio, ChatAction.media];
  }
}
