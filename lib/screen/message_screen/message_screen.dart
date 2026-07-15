import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krimson/common/manager/session_manager.dart';
import 'package:krimson/common/widget/custom_search_text_field.dart';
import 'package:krimson/common/widget/custom_tab_switcher.dart';
import 'package:krimson/common/widget/loader_widget.dart';
import 'package:krimson/common/widget/no_data_widget.dart';
import 'package:krimson/languages/languages_keys.dart';
import 'package:krimson/model/chat/chat_thread.dart';
import 'package:krimson/screen/feed_screen/feed_screen_controller.dart';
import 'package:krimson/screen/feed_screen/widget/story_view.dart';
import 'package:krimson/screen/message_screen/message_screen_controller.dart';
import 'package:krimson/screen/message_screen/widget/calls_list_view.dart';
import 'package:krimson/screen/message_screen/widget/chat_conversation_user_card.dart';
import 'package:krimson/screen/message_screen/widget/new_direct_chat_sheet.dart';
import 'package:krimson/utilities/color_res.dart';
import 'package:krimson/utilities/text_style_custom.dart';
import 'package:krimson/utilities/theme_res.dart';

class MessageScreen extends StatelessWidget {
  const MessageScreen({super.key});

  FeedScreenController _feedController() {
    if (Get.isRegistered<FeedScreenController>()) {
      return Get.find<FeedScreenController>();
    }
    return Get.put(
      FeedScreenController(SessionManager.instance.getUser().obs),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(MessageScreenController());
    final feedController = _feedController();

    return Column(
      children: [
        Container(
          color: scaffoldBackgroundColor(context),
          child: SafeArea(
            minimum: const EdgeInsets.only(top: 15),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    children: [
                      const SizedBox(width: 40),
                      Expanded(
                        child: Text(
                          LKey.messages.tr,
                          textAlign: TextAlign.center,
                          style: TextStyleCustom.unboundedMedium500(
                            fontSize: 15,
                            color: textDarkGrey(context),
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: LKey.newChat.tr,
                        onPressed: openNewDirectChatSheet,
                        icon: Icon(
                          Icons.edit_square,
                          color: textDarkGrey(context),
                          size: 22,
                        ),
                      ),
                    ],
                  ),
                ),
                StoryView(controller: feedController),
                CustomTabSwitcher(
                  items: controller.chatCategories,
                  onTap: (index) {
                    controller.onPageChanged(index);
                    controller.pageController.animateToPage(index,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.linear);
                  },
                  selectedIndex: controller.selectedChatCategory,
                  widget: Obx(() {
                    int length = controller
                        .dashboardController.requestUnReadCount.value;
                    if (length <= 0) {
                      return const SizedBox();
                    }
                    return Container(
                      height: 22,
                      width: 22,
                      margin: const EdgeInsets.symmetric(horizontal: 5),
                      decoration: const BoxDecoration(
                          shape: BoxShape.circle, color: ColorRes.likeRed),
                      alignment: Alignment.center,
                      child: Text(
                        '$length',
                        style: TextStyleCustom.outFitRegular400(
                            fontSize: 12, color: whitePure(context)),
                      ),
                    );
                  }),
                  widgetTabIndex: 1,
                  margin: const EdgeInsets.all(10),
                ),
              ],
            ),
          ),
        ),
        CustomSearchTextField(
          controller: controller.searchController,
          onChanged: controller.onSearchChanged,
          suffixIcon: IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            onPressed: openNewDirectChatSheet,
            icon: Icon(
              Icons.person_add_alt_1_rounded,
              size: 20,
              color: themeAccentSolid(context),
            ),
          ),
        ),
        Expanded(
          child: Obx(() {
            if (controller.chatError.value != null) {
              return Padding(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        controller.chatError.value!,
                        textAlign: TextAlign.center,
                        style: TextStyleCustom.outFitRegular400(
                          color: textLightGrey(context),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextButton.icon(
                        onPressed: openNewDirectChatSheet,
                        icon: const Icon(Icons.chat_bubble_outline),
                        label: Text(LKey.newChat.tr),
                      ),
                    ],
                  ),
                ),
              );
            }
            return controller.isLoading.value &&
                    (controller.selectedChatCategory.value == 0
                        ? controller.chatsUsers.isEmpty
                        : controller.selectedChatCategory.value == 1
                            ? controller.requestsUsers.isEmpty
                            : false)
                ? const LoaderWidget()
                : PageView(
                    controller: controller.pageController,
                    onPageChanged: controller.onPageChanged,
                    children: const [
                      ChatsListView(),
                      RequestsListView(),
                      CallsListView(),
                    ],
                  );
          }),
        )
      ],
    );
  }
}

class ChatsListView extends StatelessWidget {
  const ChatsListView({super.key});

  @override
  Widget build(BuildContext context) {
    final MessageScreenController controller = Get.find();
    return Obx(() {
      final list = controller.filteredChats;
      return NoDataView(
        showShow: list.isEmpty,
        title: LKey.chatListEmptyTitle.tr,
        description: LKey.chatListEmptyDescription.tr,
        child: ListView.builder(
          itemCount: list.length,
          padding: EdgeInsets.zero,
          itemBuilder: (context, index) {
            ChatThread chatConversation = list[index];
            chatConversation.bindChatUser();
            return ChatConversationUserCard(chatConversation: chatConversation);
          },
        ),
      );
    });
  }
}

class RequestsListView extends StatelessWidget {
  const RequestsListView({super.key});

  @override
  Widget build(BuildContext context) {
    final MessageScreenController controller = Get.find();

    return Obx(
      () {
        final list = controller.filteredRequests;
        return NoDataView(
          showShow: list.isEmpty,
          title: LKey.chatRequestEmptyTitle.tr,
          description: LKey.chatRequestEmptyDescription.tr,
          child: ListView.builder(
            itemCount: list.length,
            padding: EdgeInsets.zero,
            itemBuilder: (context, index) {
              ChatThread chatConversation = list[index];
              chatConversation.bindChatUser();
              return ChatConversationUserCard(
                  chatConversation: chatConversation);
            },
          ),
        );
      },
    );
  }
}

