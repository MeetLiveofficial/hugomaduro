import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krimson/common/controller/base_controller.dart';
import 'package:krimson/common/manager/logger.dart';
import 'package:krimson/common/manager/session_manager.dart';
import 'package:krimson/common/service/api/chat_service.dart';
import 'package:krimson/common/widget/confirmation_dialog.dart';
import 'package:krimson/languages/languages_keys.dart';
import 'package:krimson/model/chat/chat_thread.dart';
import 'package:krimson/model/user_model/user_model.dart';
import 'package:krimson/screen/dashboard_screen/dashboard_screen_controller.dart';
import 'package:krimson/screen/message_screen/widget/calls_list_view.dart';
import 'package:krimson/utilities/const_res.dart';

class MessageScreenController extends BaseController {
  List<String> chatCategories = [LKey.chats.tr, LKey.requests.tr, LKey.calls.tr];
  RxInt selectedChatCategory = 0.obs;
  PageController pageController = PageController();
  User? myUser = SessionManager.instance.getUser();
  RxList<ChatThread> chatsUsers = <ChatThread>[].obs;
  RxList<ChatThread> requestsUsers = <ChatThread>[].obs;
  final dashboardController = Get.find<DashboardScreenController>();
  RxnString chatError = RxnString();
  Timer? _pollTimer;
  final TextEditingController searchController = TextEditingController();
  final RxString searchQuery = ''.obs;

  List<ChatThread> get filteredChats {
    searchQuery.value;
    chatsUsers.length;
    return _filter(chatsUsers);
  }

  List<ChatThread> get filteredRequests {
    searchQuery.value;
    requestsUsers.length;
    return _filter(requestsUsers);
  }

  List<ChatThread> _filter(List<ChatThread> source) {
    final q = searchQuery.value.trim().toLowerCase();
    if (q.isEmpty) return source.toList();
    return source.where((c) {
      final u = c.chatUser;
      final name = (u?.fullname ?? '').toLowerCase();
      final username = (u?.username ?? '').toLowerCase();
      final last = (c.lastMsg ?? '').toLowerCase();
      return name.contains(q) || username.contains(q) || last.contains(q);
    }).toList();
  }

  void onSearchChanged(String value) {
    searchQuery.value = value;
  }

  @override
  void onInit() {
    super.onInit();
    pageController = PageController(initialPage: selectedChatCategory.value);
    // Poll de llamadas activo aunque el tab Calls no se haya abierto aún.
    if (!Get.isRegistered<CallsListController>()) {
      Get.put(CallsListController());
    }
    _bootstrapChat();
  }

  @override
  void onClose() {
    _pollTimer?.cancel();
    pageController.dispose();
    searchController.dispose();
    super.onClose();
  }

  void onPageChanged(int index) {
    selectedChatCategory.value = index;
  }

  void openCallsTab() {
    const callsIndex = 2;
    selectedChatCategory.value = callsIndex;
    if (pageController.hasClients) {
      pageController.animateToPage(
        callsIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _bootstrapChat() async {
    isLoading.value = true;
    chatError.value = null;
    try {
      if (useFirebase) {
        chatError.value =
            'Firebase chat desactivado. Usa Laravel (useFirebase=false).';
        isLoading.value = false;
        return;
      }
      await _refreshThreads();
      _pollTimer?.cancel();
      _pollTimer = Timer.periodic(const Duration(seconds: 4), (_) {
        _refreshThreads(silent: true);
      });
    } catch (e) {
      Loggers.error('Chat bootstrap failed: $e');
      chatError.value = 'No se pudo cargar el chat: $e';
      isLoading.value = false;
    }
  }

  Future<void> _refreshThreads({bool silent = false}) async {
    try {
      if (!silent) isLoading.value = true;
      final result = await ChatService.instance.fetchThreads();
      chatsUsers.assignAll(result.chats);
      requestsUsers.assignAll(result.requests);
      _syncUnreadBadges(result.chats, result.requests);
      chatError.value = null;
    } catch (e) {
      Loggers.error('fetchThreads: $e');
      if (!silent) {
        chatError.value = e.toString();
      }
    } finally {
      isLoading.value = false;
    }
  }

  void _syncUnreadBadges(List<ChatThread> chats, List<ChatThread> requests) {
    final chatUnread = chats.where((e) => (e.msgCount ?? 0) > 0).length;
    final requestUnread = requests.where((e) => (e.msgCount ?? 0) > 0).length;
    dashboardController.chatUnReadCount.value = chatUnread;
    dashboardController.requestUnReadCount.value = requestUnread;
    dashboardController.unReadCount.value = chatUnread +
        requestUnread +
        dashboardController.callsUnReadCount.value;
  }

  Future<void> onRefresh() => _refreshThreads();

  void onLongPress(ChatThread chatConversation) {
    Get.bottomSheet(ConfirmationSheet(
      title: LKey.deleteChatUserTitle.trParams(
          {'user_name': chatConversation.chatUser?.username ?? ''}),
      description: LKey.deleteChatUserDescription.tr,
      onTap: () async {
        final peerId = chatConversation.peerUserId;
        if (peerId == -1) return;
        showLoader();
        try {
          await ChatService.instance.updateThread(
            peerUserId: peerId,
            isDeleted: true,
          );
          chatsUsers.removeWhere((c) => c.peerUserId == peerId);
          requestsUsers.removeWhere((c) => c.peerUserId == peerId);
        } catch (e) {
          Loggers.error('delete chat: $e');
          showSnackBar(e.toString());
        } finally {
          stopLoader();
        }
      },
    ));
  }
}
