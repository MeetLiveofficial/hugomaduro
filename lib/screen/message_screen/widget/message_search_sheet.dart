import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krimson/languages/languages_keys.dart';
import 'package:krimson/model/chat/chat_thread.dart';
import 'package:krimson/screen/message_screen/message_screen_controller.dart';
import 'package:krimson/screen/message_screen/widget/chat_conversation_user_card.dart';
import 'package:krimson/screen/message_screen/widget/new_direct_chat_sheet.dart';
import 'package:krimson/screen/message_screen/widget/support_chat_card.dart';
import 'package:krimson/utilities/color_res.dart';
import 'package:krimson/utilities/text_style_custom.dart';
import 'package:krimson/common/widget/custom_search_text_field.dart';

/// Menú de búsqueda de chats: se abre al tocar el input de Mensajes.
Future<void> openMessageSearchSheet() {
  return Get.bottomSheet(
    const _MessageSearchSheet(),
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
  );
}

class _MessageSearchSheet extends StatefulWidget {
  const _MessageSearchSheet();

  @override
  State<_MessageSearchSheet> createState() => _MessageSearchSheetState();
}

class _MessageSearchSheetState extends State<_MessageSearchSheet> {
  final TextEditingController _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Get.find<MessageScreenController>().onSearchChanged('');
    });
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = Get.find<MessageScreenController>();
    final height = MediaQuery.sizeOf(context).height * 0.88;
    return SafeArea(
      child: Container(
        height: height,
        decoration: const BoxDecoration(
          color: Color(0xFFFFF4F8),
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: ColorRes.crimson.withValues(alpha: 0.22),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 12, 4, 8),
              child: Row(
                children: [
                  Expanded(
                    child: CustomSearchTextField(
                      controller: _search,
                      hintText: LKey.searchHere.tr,
                      margin: EdgeInsets.zero,
                      autofocus: true,
                      onChanged: c.onSearchChanged,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      _search.clear();
                      c.onSearchChanged('');
                      Get.back();
                    },
                    child: Text(
                      LKey.cancel.tr,
                      style: TextStyleCustom.outFitMedium500(
                        color: ColorRes.roseMuted,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Obx(() {
                final q = c.searchQuery.value.trim();
                final chats = c.filteredChats;
                final requests = c.filteredRequests;
                final showSupport = c.showSupportInSearch;
                final empty = chats.isEmpty &&
                    requests.isEmpty &&
                    !showSupport;
                if (empty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            q.isEmpty
                                ? LKey.searchHere.tr
                                : LKey.noData.tr,
                            textAlign: TextAlign.center,
                            style: TextStyleCustom.outFitRegular400(
                              color: ColorRes.textLightGrey,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextButton.icon(
                            onPressed: () {
                              Get.back();
                              openNewDirectChatSheet();
                            },
                            icon: const Icon(Icons.person_add_alt_1_rounded,
                                color: ColorRes.crimson),
                            label: Text(
                              LKey.newChat.tr,
                              style: TextStyleCustom.outFitMedium500(
                                color: ColorRes.crimson,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return ListView(
                  padding: const EdgeInsets.only(bottom: 24),
                  children: [
                    if (showSupport) const SupportChatCard(),
                    ...chats.map((ChatThread t) {
                      t.bindChatUser();
                      return ChatConversationUserCard(chatConversation: t);
                    }),
                    if (requests.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                        child: Text(
                          LKey.requests.tr,
                          style: TextStyleCustom.outFitMedium500(
                        color: ColorRes.textLightGrey,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      ...requests.map((ChatThread t) {
                        t.bindChatUser();
                        return ChatConversationUserCard(chatConversation: t);
                      }),
                    ],
                  ],
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
