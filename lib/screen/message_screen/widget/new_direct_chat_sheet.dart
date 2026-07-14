import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krimson/common/extensions/string_extension.dart';
import 'package:krimson/common/functions/debounce_action.dart';
import 'package:krimson/common/manager/session_manager.dart';
import 'package:krimson/common/service/api/user_service.dart';
import 'package:krimson/common/widget/custom_image.dart';
import 'package:krimson/common/widget/custom_search_text_field.dart';
import 'package:krimson/common/widget/loader_widget.dart';
import 'package:krimson/languages/languages_keys.dart';
import 'package:krimson/model/user_model/user_model.dart';
import 'package:krimson/screen/message_screen/widget/chat_conversation_user_card.dart';
import 'package:krimson/utilities/app_res.dart';
import 'package:krimson/utilities/text_style_custom.dart';
import 'package:krimson/utilities/theme_res.dart';

/// Sheet para buscar un usuario e iniciar un chat directo.
Future<void> openNewDirectChatSheet() {
  return Get.bottomSheet(
    const _NewDirectChatSheet(),
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
  );
}

class _NewDirectChatSheet extends StatefulWidget {
  const _NewDirectChatSheet();

  @override
  State<_NewDirectChatSheet> createState() => _NewDirectChatSheetState();
}

class _NewDirectChatSheetState extends State<_NewDirectChatSheet> {
  final TextEditingController _search = TextEditingController();
  final RxList<User> _users = <User>[].obs;
  final RxBool _loading = false.obs;
  final RxBool _searched = false.obs;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _onQuery(String value) {
    DebounceAction.shared.call(() {
      _searchUsers(value.trim());
    });
  }

  Future<void> _searchUsers(String q) async {
    if (q.isEmpty) {
      _users.clear();
      _searched.value = false;
      return;
    }
    _loading.value = true;
    _searched.value = true;
    try {
      final list = await UserService.instance.searchUsers(
        keyWord: q,
        limit: AppRes.paginationLimit,
      );
      final meId = SessionManager.instance.getUserID();
      _users.assignAll(list.where((u) => u.id != meId));
    } catch (_) {
      _users.clear();
    } finally {
      _loading.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height * 0.72;
    return SafeArea(
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: whitePure(context),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 10),
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: bgGrey(context),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 8, 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      LKey.newChat.tr,
                      style: TextStyleCustom.unboundedSemiBold600(
                        color: textDarkGrey(context),
                        fontSize: 16,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: Get.back,
                    icon: Icon(Icons.close, color: textDarkGrey(context)),
                  ),
                ],
              ),
            ),
            CustomSearchTextField(
              controller: _search,
              onChanged: _onQuery,
              hintText: LKey.searchUsers.tr,
            ),
            Expanded(
              child: Obx(() {
                if (_loading.value) return const LoaderWidget();
                if (!_searched.value) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        LKey.newChatHint.tr,
                        textAlign: TextAlign.center,
                        style: TextStyleCustom.outFitRegular400(
                          color: textLightGrey(context),
                          fontSize: 14,
                        ),
                      ),
                    ),
                  );
                }
                if (_users.isEmpty) {
                  return Center(
                    child: Text(
                      LKey.userListEmptyTitle.tr,
                      style: TextStyleCustom.outFitRegular400(
                        color: textLightGrey(context),
                      ),
                    ),
                  );
                }
                return ListView.separated(
                  itemCount: _users.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final user = _users[index];
                    return ListTile(
                      leading: CustomImage(
                        size: const Size(44, 44),
                        strokeWidth: 0,
                        image: user.profilePhoto?.addBaseURL(),
                        fullName: user.fullname,
                      ),
                      title: Text(user.fullname ?? user.username ?? ''),
                      subtitle: Text('@${user.username ?? ''}'),
                      onTap: () {
                        Get.back();
                        openDirectChatWith(user);
                      },
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
