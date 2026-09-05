import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krimson/common/widget/gift_media.dart';
import 'package:krimson/languages/languages_keys.dart';
import 'package:krimson/model/livestream/live_chat_message.dart';
import 'package:krimson/utilities/color_res.dart';
import 'package:krimson/utilities/text_style_custom.dart';

/// Aviso al cliente cuando la streamer pide un regalo (LIVE o llamada).
class GiftRequestPrompt {
  GiftRequestPrompt._();

  static Future<void> showDialog({
    required LiveChatMessage msg,
    required VoidCallback onSend,
  }) async {
    final coins = msg.giftCoins ?? 0;
    final title = (msg.text ?? '').trim().isEmpty
        ? LKey.sendMeGifts.tr
        : msg.text!.trim();
    await Get.dialog<void>(
      AlertDialog(
        backgroundColor: const Color(0xFF1A1224),
        title: Text(
          LKey.giftMe.tr,
          style: TextStyleCustom.outFitMedium500(
            color: Colors.white,
            fontSize: 16,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if ((msg.giftImage ?? '').isNotEmpty || msg.giftId != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: GiftMedia(
                  path: msg.giftImage,
                  width: 72,
                  height: 72,
                  fit: BoxFit.contain,
                  muted: true,
                  looping: true,
                  placeholder: const Icon(
                    Icons.card_giftcard,
                    color: ColorRes.accentPeach,
                    size: 48,
                  ),
                ),
              ),
            Text(
              coins > 0
                  ? '$title\n${msg.userName} · $coins ${LKey.coins.tr}'
                  : '$title\n${msg.userName}',
              textAlign: TextAlign.center,
              style: TextStyleCustom.outFitRegular400(
                color: Colors.white70,
                fontSize: 13,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: Get.back,
            child: Text(
              LKey.notNow.tr,
              style: TextStyleCustom.outFitMedium500(color: Colors.white54),
            ),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              onSend();
            },
            child: Text(
              LKey.sendGifts.tr,
              style: TextStyleCustom.outFitMedium500(
                color: ColorRes.themeAccentSolid,
              ),
            ),
          ),
        ],
      ),
      barrierDismissible: true,
    );
  }
}

/// Barra compacta (fuera del video en Web) para enviar el regalo pedido.
class GiftRequestBar extends StatelessWidget {
  const GiftRequestBar({
    super.key,
    required this.message,
    required this.onSend,
    this.onDismiss,
  });

  final LiveChatMessage message;
  final VoidCallback onSend;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    final coins = message.giftCoins ?? 0;
    final title = (message.text ?? '').trim().isEmpty
        ? LKey.sendMeGifts.tr
        : message.text!.trim();
    return Material(
      color: ColorRes.themeAccentSolid.withValues(alpha: 0.95),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onSend,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 8, 6, 8),
          child: Row(
            children: [
              GiftMedia(
                path: message.giftImage,
                width: 36,
                height: 36,
                fit: BoxFit.contain,
                muted: true,
                looping: true,
                placeholder: const Icon(
                  Icons.card_giftcard,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
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
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      coins > 0
                          ? '${message.userName} · $coins ${LKey.coins.tr}'
                          : message.userName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyleCustom.outFitRegular400(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                LKey.sendGifts.tr,
                style: TextStyleCustom.outFitMedium500(
                  color: Colors.white,
                  fontSize: 12,
                ),
              ),
              if (onDismiss != null)
                IconButton(
                  onPressed: onDismiss,
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.close, color: Colors.white70, size: 18),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
