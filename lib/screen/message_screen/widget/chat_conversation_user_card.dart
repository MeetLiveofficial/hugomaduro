import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krimson/common/extensions/list_extension.dart';
import 'package:krimson/common/extensions/string_extension.dart';
import 'package:krimson/common/extensions/user_extension.dart';
import 'package:krimson/common/widget/brand_controls.dart';
import 'package:krimson/common/widget/custom_image.dart';
import 'package:krimson/common/enum/chat_enum.dart';
import 'package:krimson/common/manager/app_role.dart';
import 'package:krimson/common/manager/session_manager.dart';
import 'package:krimson/languages/languages_keys.dart';
import 'package:krimson/model/chat/chat_thread.dart';
import 'package:krimson/model/user_model/user_model.dart';
import 'package:krimson/screen/chat_screen/chat_screen.dart';
import 'package:krimson/screen/message_screen/message_screen_controller.dart';
import 'package:krimson/utilities/client_colors.dart';
import 'package:krimson/utilities/color_res.dart';
import 'package:krimson/utilities/text_style_custom.dart';
import 'package:krimson/utilities/theme_res.dart';

class ChatConversationUserCard extends StatelessWidget {
  final ChatThread chatConversation;

  const ChatConversationUserCard({
    super.key,
    required this.chatConversation,
  });

  void _openChat() {
    Get.to(
      () => ChatScreen(conversationUser: chatConversation),
      preventDuplicates: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<MessageScreenController>();
    final unread = chatConversation.msgCount ?? 0;

    return InkWell(
      onTap: _openChat,
      onLongPress: () => controller.onLongPress(chatConversation),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Obx(() {
              final user = chatConversation.chatUserRx.value;
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  CustomImage(
                    size: const Size(52, 52),
                    image: user?.profile?.addBaseURL(),
                    fullName: user?.fullname ?? user?.username,
                    strokeWidth: 0,
                  ),
                  if (user?.isPresent == true)
                    Positioned(
                      right: 1,
                      bottom: 1,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: const Color(0xFF22C55E),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppRole.isClient()
                                ? ClientColors.bg
                                : whitePure(context),
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            }),
            const SizedBox(width: 12),
            Expanded(
              child: Obx(() {
                final user = chatConversation.chatUserRx.value;
                final active = user?.isPresent == true;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            user?.fullname ?? user?.username ?? LKey.user.tr,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyleCustom.outFitMedium500(
                              fontSize: 15,
                              color: AppRole.isClient()
                                  ? ClientColors.text
                                  : ColorRes.textDarkGrey,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        BrandStatusPill(
                          label: active ? LKey.statusActive.tr : LKey.statusInactive.tr,
                          color: active
                              ? const Color(0xFF22C55E)
                              : const Color(0xFFBFA8B8),
                          solid: active,
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      (chatConversation.lastMsg ?? '').trim().isEmpty
                          ? LKey.message.tr
                          : chatConversation.lastMsg!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyleCustom.outFitRegular400(
                        fontSize: 13,
                        color: AppRole.isClient()
                            ? ClientColors.textMuted
                            : ColorRes.textLightGrey,
                      ),
                    ),
                  ],
                );
              }),
            ),
            if (unread > 0)
              Container(
                margin: const EdgeInsets.only(left: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: const BoxDecoration(
                  color: ColorRes.likeRed,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  unread > 99 ? '99+' : '$unread',
                  style: TextStyleCustom.outFitMedium500(
                    fontSize: 11,
                    color: whitePure(context),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Abre un chat 1:1 (nuevo o existente) con el usuario seleccionado.
void openDirectChatWith(User user) {
  final meId = SessionManager.instance.getUserID();
  final thread = ChatThread(
    id: DateTime.now().millisecondsSinceEpoch.toString(),
    lastMsg: '',
    msgCount: 0,
    isDeleted: false,
    deletedId: 0,
    iAmBlocked: false,
    iBlocked: user.isBlock ?? false,
    requestType: UserRequestAction.accept.title,
    chatType: ChatType.approved,
    conversationId: [meId, user.id].conversationId,
    userId: user.id,
  );
  thread.chatUser = user.appUser;
  Get.to(
    () => ChatScreen(conversationUser: thread, user: user),
    preventDuplicates: false,
  );
}
