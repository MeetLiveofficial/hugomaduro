import 'package:figma_squircle_updated/figma_squircle.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krimson/common/widget/loader_widget.dart';
import 'package:krimson/languages/languages_keys.dart';
import 'package:krimson/model/support/support_ticket.dart';
import 'package:krimson/screen/support_chat/support_chat_controller.dart';
import 'package:krimson/utilities/color_res.dart';
import 'package:krimson/utilities/style_res.dart';
import 'package:krimson/utilities/text_style_custom.dart';
import 'package:krimson/utilities/theme_res.dart';

class SupportChatScreen extends StatelessWidget {
  const SupportChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(SupportChatController());
    return Scaffold(
      backgroundColor: scaffoldBackgroundColor(context),
      body: SafeArea(
        child: Column(
          children: [
            _SupportTopBar(controller: controller),
            Expanded(
              child: Obx(() {
                if (controller.isLoading.value && controller.messages.isEmpty) {
                  return const LoaderWidget();
                }
                if (controller.messages.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        LKey.supportChatEmpty.tr,
                        textAlign: TextAlign.center,
                        style: TextStyleCustom.outFitRegular400(
                          color: textLightGrey(context),
                          fontSize: 14,
                        ),
                      ),
                    ),
                  );
                }
                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  itemCount: controller.messages.length,
                  itemBuilder: (context, index) {
                    final msg = controller.messages[index];
                    return _SupportBubble(message: msg);
                  },
                );
              }),
            ),
            _SupportComposer(controller: controller),
          ],
        ),
      ),
    );
  }
}

class _SupportTopBar extends StatelessWidget {
  final SupportChatController controller;

  const _SupportTopBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 12, 8),
      child: Row(
        children: [
          IconButton(
            onPressed: Get.back,
            icon: Icon(Icons.arrow_back_ios_new_rounded,
                size: 20, color: textDarkGrey(context)),
          ),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: StyleRes.themeGradient,
            ),
            child: const Icon(Icons.support_agent_rounded,
                color: Colors.white, size: 22),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Obx(() {
              final t = controller.ticket.value;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    LKey.supportChat.tr,
                    style: TextStyleCustom.outFitMedium500(
                      fontSize: 16,
                      color: textDarkGrey(context),
                    ),
                  ),
                  Text(
                    t?.ticketNumber ?? LKey.supportChatSubtitle.tr,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyleCustom.outFitRegular400(
                      fontSize: 12,
                      color: textLightGrey(context),
                    ),
                  ),
                ],
              );
            }),
          ),
          Obx(() {
            final status = controller.ticket.value?.status ?? 'open';
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFF22C55E).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                status.toUpperCase(),
                style: TextStyleCustom.outFitMedium500(
                  fontSize: 10,
                  color: const Color(0xFF15803D),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _SupportBubble extends StatelessWidget {
  final SupportMessage message;

  const _SupportBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isMe = message.isMe == true;
    final isSystem = message.authorType == 'system';
    final align = isMe ? Alignment.centerRight : Alignment.centerLeft;
    final bg = isSystem
        ? const Color(0xFF9CA3AF).withValues(alpha: 0.18)
        : isMe
            ? ColorRes.coralRed.withValues(alpha: 0.92)
            : bgLightGrey(context);

    final fg = isMe ? Colors.white : textDarkGrey(context);

    return Align(
      alignment: align,
      child: Container(
        constraints: BoxConstraints(maxWidth: Get.width * 0.78),
        margin: const EdgeInsets.symmetric(vertical: 5),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: ShapeDecoration(
          color: bg,
          shape: SmoothRectangleBorder(
            borderRadius: SmoothBorderRadius(
              cornerRadius: 16,
              cornerSmoothing: 1,
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (!isMe)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  isSystem ? LKey.system.tr : LKey.supportChat.tr,
                  style: TextStyleCustom.outFitMedium500(
                    fontSize: 11,
                    color: textLightGrey(context),
                  ),
                ),
              ),
            Text(
              (message.textMessage ?? '').trim().isEmpty
                  ? (message.imageMessage != null ? '📷' : '')
                  : message.textMessage!,
              style: TextStyleCustom.outFitRegular400(
                fontSize: 14,
                color: fg,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SupportComposer extends StatelessWidget {
  final SupportChatController controller;

  const _SupportComposer({required this.controller});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller.textController,
                onChanged: controller.onTextChanged,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => controller.sendText(),
                decoration: InputDecoration(
                  hintText: LKey.supportChatHint.tr,
                  hintStyle: TextStyleCustom.outFitRegular400(
                    color: textLightGrey(context),
                    fontSize: 14,
                  ),
                  filled: true,
                  fillColor: bgLightGrey(context),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(22),
                    borderSide: BorderSide.none,
                  ),
                ),
                style: TextStyleCustom.outFitRegular400(
                  color: textDarkGrey(context),
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Obx(() {
              final enabled =
                  !controller.isTextEmpty.value && !controller.isSending.value;
              return InkWell(
                onTap: enabled ? controller.sendText : null,
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: enabled ? StyleRes.themeGradient : null,
                    color: enabled ? null : const Color(0xFF9CA3AF),
                  ),
                  child: const Icon(Icons.send_rounded,
                      color: Colors.white, size: 20),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
