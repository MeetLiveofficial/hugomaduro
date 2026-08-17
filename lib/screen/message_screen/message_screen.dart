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
import 'package:krimson/screen/message_screen/widget/support_chat_card.dart';
import 'package:krimson/utilities/color_res.dart';
import 'package:krimson/utilities/style_res.dart';
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
          decoration: BoxDecoration(gradient: StyleRes.themeGradient),
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
                            color: ColorRes.whitePure,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: LKey.newChat.tr,
                        onPressed: openNewDirectChatSheet,
                        icon: const Icon(
                          Icons.edit_square,
                          color: ColorRes.whitePure,
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
                  badges: {
                    0: _MessageTabBadge(
                        count: controller.dashboardController.chatUnReadCount),
                    1: _MessageTabBadge(
                        count:
                            controller.dashboardController.requestUnReadCount),
                    2: _MessageTabBadge(
                        count: controller.dashboardController.callsUnReadCount),
                  },
                  margin: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                  backgroundColor: ColorRes.whitePure.withValues(alpha: 0.92),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: ColorRes.whitePure.withValues(alpha: 0.96),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(22)),
              boxShadow: [
                BoxShadow(
                  color: ColorRes.crimson.withValues(alpha: 0.12),
                  blurRadius: 18,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Column(
              children: [
                CustomSearchTextField(
                  controller: controller.searchController,
                  onChanged: controller.onSearchChanged,
                  suffixIcon: IconButton(
                    padding: EdgeInsets.zero,
                    constraints:
                        const BoxConstraints(minWidth: 36, minHeight: 36),
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
                ),
              ],
            ),
          ),
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
      final showSupport = controller.showSupportInSearch;
      // El chat de soporte siempre va primero (aunque no haya otros chats).
      final itemCount = list.length + (showSupport ? 1 : 0);
      return NoDataView(
        showShow: itemCount == 0,
        title: LKey.chatListEmptyTitle.tr,
        description: LKey.chatListEmptyDescription.tr,
        child: ListView.builder(
          itemCount: itemCount,
          padding: const EdgeInsets.only(bottom: 12),
          itemBuilder: (context, index) {
            if (showSupport && index == 0) {
              return const SupportChatCard();
            }
            final chatIndex = showSupport ? index - 1 : index;
            ChatThread chatConversation = list[chatIndex];
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

class _MessageTabBadge extends StatelessWidget {
  final RxInt count;

  const _MessageTabBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final length = count.value;
      if (length <= 0) return const SizedBox.shrink();
      return Container(
        height: 20,
        constraints: const BoxConstraints(minWidth: 20),
        margin: const EdgeInsets.only(left: 4),
        padding: const EdgeInsets.symmetric(horizontal: 5),
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: ColorRes.likeRed,
        ),
        alignment: Alignment.center,
        child: Text(
          length > 99 ? '99+' : '$length',
          style: TextStyleCustom.outFitRegular400(
            fontSize: 10,
            color: whitePure(context),
          ),
        ),
      );
    });
  }
}

