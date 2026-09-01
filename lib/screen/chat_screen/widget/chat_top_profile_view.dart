import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krimson/common/extensions/string_extension.dart';
import 'package:krimson/common/service/navigation/navigate_with_controller.dart';
import 'package:krimson/common/widget/custom_image.dart';
import 'package:krimson/common/widget/custom_popup_menu_button.dart';
import 'package:krimson/common/widget/full_name_with_blue_tick.dart';
import 'package:krimson/languages/languages_keys.dart';
import 'package:krimson/model/chat/chat_thread.dart';
import 'package:krimson/model/livestream/app_user.dart';
import 'package:krimson/model/user_model/user_model.dart';
import 'package:krimson/common/manager/app_role.dart';
import 'package:krimson/screen/chat_screen/chat_screen_controller.dart';
import 'package:krimson/utilities/client_colors.dart';
import 'package:krimson/utilities/color_res.dart';
import 'package:krimson/utilities/text_style_custom.dart';
import 'package:krimson/utilities/theme_res.dart';

class ChatTopProfileView extends StatelessWidget {
  final ChatScreenController controller;

  const ChatTopProfileView({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final client = AppRole.isClient();
    final chrome = client ? ClientColors.bg : ColorRes.whitePure;
    final onChrome = client ? ClientColors.text : ColorRes.textDarkGrey;
    final muted = client ? ClientColors.accentBlue : ColorRes.textDarkGrey;
    return Container(
      color: chrome,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      child: SafeArea(
        bottom: false,
        child: Builder(builder: (context) {
          ChatThread chatThread = controller.conversationUser.value;
          // bind una sola vez (no dentro del rebuild reactivo)
          chatThread.bindChatUser();
          return Obx(() {
          // Observa el hilo + el usuario reactivo
          final _ = controller.conversationUser.value;
          final chatUser = chatThread.chatUserRx.value;
          bool iBlocked = chatThread.iBlocked ?? false;
          return Row(
            spacing: 10,
            children: [
              IconButton(
                onPressed: () => Get.back(),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                icon: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 20,
                  color: onChrome,
                ),
              ),
              Expanded(
                child: InkWell(
                  onTap: () {
                    User user = User(
                      id: chatUser?.userId,
                      fullname: chatUser?.fullname,
                      username: chatUser?.username,
                      profilePhoto: chatUser?.profile,
                      isVerify: chatUser?.isVerify,
                    );
                    NavigationService.shared.openProfileScreen(
                      user,
                      onUserUpdate: (user) {
                        if (controller.otherUser?.id == user?.id) {
                          controller.otherUser = user;
                        }
                      },
                    );
                  },
                  child: Row(
                    spacing: 10,
                    children: [
                      // Chat: foto circular sin insignia/marco.
                      CustomImage(
                          size: const Size(48, 48),
                          image: chatUser?.profile?.addBaseURL(),
                          fullName: chatUser?.fullname),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            FullNameWithBlueTick(
                                username: chatUser?.username ?? '',
                                fontSize: 13,
                                iconSize: 18,
                                fontColor: onChrome,
                                isVerify: chatUser?.isVerify),
                            Text(chatUser?.fullname ?? '',
                                style: TextStyleCustom.outFitLight300(
                                    color: muted, fontSize: 15))
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              CustomPopupMenuButton(
                  items: [
                    MenuItem(
                      iBlocked ? LKey.unBlock.tr : LKey.block.tr,
                      () {
                        controller.toggleBlockUnblock(chatThread);
                      },
                    ),
                    MenuItem(
                      LKey.report.tr,
                      () {
                        controller.onReportUser(chatThread);
                      },
                    ),
                  ],
                  child: Container(
                      height: 36,
                      width: 36,
                      decoration: BoxDecoration(
                        color: chrome,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: client
                              ? ClientColors.accentBlue.withValues(alpha: 0.55)
                              : ColorRes.crimson.withValues(alpha: 0.45),
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.more_horiz_rounded,
                        size: 22,
                        color: onChrome,
                      )))
            ],
          );
          });
        }),
      ),
    );
  }
}
