import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krimson/common/widget/custom_tab_switcher.dart';
import 'package:krimson/common/widget/loader_widget.dart';
import 'package:krimson/common/widget/no_data_widget.dart';
import 'package:krimson/languages/languages_keys.dart';
import 'package:krimson/model/chat/chat_thread.dart';
import 'package:krimson/screen/message_screen/message_screen_controller.dart';
import 'package:krimson/screen/message_screen/widget/calls_list_view.dart';
import 'package:krimson/screen/message_screen/widget/chat_conversation_user_card.dart';
import 'package:krimson/screen/message_screen/widget/message_search_sheet.dart';
import 'package:krimson/screen/message_screen/widget/new_direct_chat_sheet.dart';
import 'package:krimson/screen/message_screen/widget/support_chat_card.dart';
import 'package:krimson/utilities/color_res.dart';
import 'package:krimson/utilities/style_res.dart';
import 'package:krimson/utilities/text_style_custom.dart';
import 'package:krimson/utilities/theme_res.dart';

class MessageScreen extends StatelessWidget {
  const MessageScreen({super.key});

  static const Color _pageBg = Color(0xFFFFF4F8);

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(MessageScreenController());

    return ColoredBox(
      color: _pageBg,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: StyleRes.themeGradient,
              boxShadow: [
                BoxShadow(
                  color: ColorRes.crimson.withValues(alpha: 0.28),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 8, 12),
                child: Column(
                  children: [
                    SizedBox(
                      height: 48,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Text(
                            LKey.messages.tr,
                            textAlign: TextAlign.center,
                            style: TextStyleCustom.unboundedMedium500(
                              fontSize: 18,
                              color: ColorRes.whitePure,
                            ),
                          ),
                          Row(
                            children: [
                              IconButton(
                                tooltip: LKey.searchHere.tr,
                                onPressed: openMessageSearchSheet,
                                icon: const Icon(
                                  Icons.search_rounded,
                                  color: ColorRes.whitePure,
                                  size: 24,
                                ),
                              ),
                              const Spacer(),
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
                        ],
                      ),
                    ),
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
                            count:
                                controller.dashboardController.chatUnReadCount),
                        1: _MessageTabBadge(
                            count: controller
                                .dashboardController.requestUnReadCount),
                        2: _MessageTabBadge(
                            count: controller
                                .dashboardController.callsUnReadCount),
                      },
                      margin: const EdgeInsets.only(top: 10),
                      backgroundColor: ColorRes.whitePure,
                      unselectedFontColor: ColorRes.textDarkGrey,
                    ),
                  ],
                ),
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
    );
  }
}

class ChatsListView extends StatelessWidget {
  const ChatsListView({super.key});

  @override
  Widget build(BuildContext context) {
    final MessageScreenController controller = Get.find();
    return Obx(() {
      final list = controller.chatsUsers;
      final itemCount = list.length + 1;
      return NoDataView(
        showShow: list.isEmpty,
        title: LKey.chatListEmptyTitle.tr,
        description: LKey.chatListEmptyDescription.tr,
        child: ListView.separated(
          itemCount: itemCount,
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 96),
          separatorBuilder: (_, __) => const Divider(
            height: 1,
            indent: 76,
            color: Color(0x22E24AB7),
          ),
          itemBuilder: (context, index) {
            if (index == 0) {
              return const SupportChatCard();
            }
            ChatThread chatConversation = list[index - 1];
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
        final list = controller.requestsUsers;
        return NoDataView(
          showShow: list.isEmpty,
          title: LKey.chatRequestEmptyTitle.tr,
          description: LKey.chatRequestEmptyDescription.tr,
          child: ListView.separated(
            itemCount: list.length,
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 96),
            separatorBuilder: (_, __) => const Divider(
              height: 1,
              indent: 76,
              color: Color(0x22E24AB7),
            ),
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
