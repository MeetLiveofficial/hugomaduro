import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krimson/common/manager/app_role.dart';
import 'package:krimson/common/widget/brand_controls.dart';
import 'package:krimson/languages/languages_keys.dart';
import 'package:krimson/screen/message_screen/message_screen_controller.dart';
import 'package:krimson/screen/support_chat/support_chat_controller.dart';
import 'package:krimson/screen/support_chat/support_chat_screen.dart';
import 'package:krimson/utilities/client_colors.dart';
import 'package:krimson/utilities/color_res.dart';
import 'package:krimson/utilities/text_style_custom.dart';
import 'package:krimson/utilities/theme_res.dart';

/// Fila fija al inicio de Chats: abre el chat de tickets de soporte.
class SupportChatCard extends StatelessWidget {
  const SupportChatCard({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<MessageScreenController>();

    return InkWell(
      onTap: () async {
        await Get.to(() => const SupportChatScreen());
        if (Get.isRegistered<SupportChatController>()) {
          Get.delete<SupportChatController>();
        }
        controller.refreshSupportSummary();
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: AppRole.isClient()
            ? ClientColors.glass(radius: 16)
            : BoxDecoration(
                color: const Color(0xCC140818),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0x73E879F9)),
              ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppRole.isClient()
                    ? ClientColors.ctaGradient
                    : const LinearGradient(
                        colors: [Color(0xFFFF4D9A), Color(0xFFB140D8)],
                      ),
              ),
              child: const Icon(
                Icons.support_agent_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Obx(() {
                final summary = controller.supportSummary.value;
                final last = (summary?.lastMsg ?? '').trim().isEmpty
                    ? LKey.supportChatSubtitle.tr
                    : summary!.lastMsg;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            LKey.supportChat.tr,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyleCustom.outFitMedium500(
                              fontSize: 15,
                              color: AppRole.isClient()
                                  ? ClientColors.text
                                  : Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        BrandStatusPill(
                          label: LKey.supportBadge.tr,
                          color: AppRole.isClient()
                              ? ClientColors.magentaHot
                              : const Color(0xFFE879F9),
                          solid: true,
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      last,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyleCustom.outFitRegular400(
                        fontSize: 13,
                        color: AppRole.isClient()
                            ? ClientColors.textMuted
                            : Colors.white70,
                      ),
                    ),
                  ],
                );
              }),
            ),
            Obx(() {
              final unread = controller.supportSummary.value?.userUnread ?? 0;
              if (unread <= 0) return const SizedBox.shrink();
              return Container(
                margin: const EdgeInsets.only(left: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppRole.isClient()
                      ? ClientColors.magentaHot
                      : const Color(0xFFE879F9),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  unread > 99 ? '99+' : '$unread',
                  style: TextStyleCustom.outFitMedium500(
                    fontSize: 11,
                    color: whitePure(context),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
