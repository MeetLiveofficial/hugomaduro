import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krimson/common/extensions/user_extension.dart';
import 'package:krimson/model/chat/chat_thread.dart';
import 'package:krimson/model/user_model/user_model.dart';
import 'package:krimson/screen/chat_screen/chat_screen_controller.dart';
import 'package:krimson/screen/chat_screen/widget/chat_bottom_action_view.dart';
import 'package:krimson/screen/chat_screen/widget/chat_center_message_view.dart';
import 'package:krimson/screen/chat_screen/widget/chat_top_profile_view.dart';
import 'package:krimson/common/manager/app_role.dart';
import 'package:krimson/utilities/client_colors.dart';
import 'package:krimson/utilities/color_res.dart';
import 'package:krimson/utilities/theme_res.dart';

class ChatScreen extends StatelessWidget {
  final ChatThread conversationUser;
  final User? user;

  const ChatScreen({super.key, required this.conversationUser, this.user});

  @override
  Widget build(BuildContext context) {
    // Asegurar peer id antes de que el controller arme las refs de Firestore.
    if (conversationUser.userId == null && user?.id != null) {
      conversationUser.userId = user!.id;
    }
    if (conversationUser.chatUser == null && user != null) {
      conversationUser.chatUser = user!.appUser;
    }
    final controller = Get.put(ChatScreenController(conversationUser.obs),
        tag: '${conversationUser.conversationId}');
    final page = Scaffold(
      backgroundColor:
          AppRole.isClient() ? ClientColors.bg : ColorRes.whitePure,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ChatTopProfileView(controller: controller),
          ChatMessageView(controller: controller),
          ChatBottomActionView(controller: controller)
        ],
      ),
    );
    return ThemeRes.applyIfClient(context, page);
  }
}
