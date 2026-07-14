import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krimson/common/controller/base_controller.dart';
import 'package:krimson/common/controller/firebase_firestore_controller.dart';
import 'package:krimson/common/manager/logger.dart';
import 'package:krimson/common/manager/session_manager.dart';
import 'package:krimson/common/widget/confirmation_dialog.dart';
import 'package:krimson/languages/languages_keys.dart';
import 'package:krimson/model/chat/chat_thread.dart';
import 'package:krimson/model/user_model/user_model.dart';
import 'package:krimson/screen/dashboard_screen/dashboard_screen_controller.dart';
import 'package:krimson/utilities/firebase_const.dart';

class MessageScreenController extends BaseController {
  List<String> chatCategories = [LKey.chats.tr, LKey.requests.tr];
  RxInt selectedChatCategory = 0.obs;
  FirebaseFirestore db = FirebaseFirestore.instance;
  PageController pageController = PageController();
  User? myUser = SessionManager.instance.getUser();
  RxList<ChatThread> chatsUsers = <ChatThread>[].obs;
  RxList<ChatThread> requestsUsers = <ChatThread>[].obs;
  final dashboardController = Get.find<DashboardScreenController>();
  late final FirebaseFirestoreController firebaseFirestoreController;
  RxnString chatError = RxnString();
  StreamSubscription? _chatSubscription;
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
    if (Get.isRegistered<FirebaseFirestoreController>()) {
      firebaseFirestoreController = Get.find<FirebaseFirestoreController>();
    } else {
      firebaseFirestoreController = Get.put(FirebaseFirestoreController());
    }
    _bootstrapChat();
  }

  @override
  void onClose() {
    _chatSubscription?.cancel();
    pageController.dispose();
    searchController.dispose();
    super.onClose();
  }

  void onPageChanged(int index) {
    selectedChatCategory.value = index;
  }

  Future<void> _bootstrapChat() async {
    isLoading.value = true;
    chatError.value = null;
    try {
      if (Firebase.apps.isEmpty) {
        chatError.value =
            'Firebase is not configured. Chat requires Firebase.';
        isLoading.value = false;
        return;
      }
      if (firebase_auth.FirebaseAuth.instance.currentUser == null) {
        if (kIsWeb) {
          await firebase_auth.FirebaseAuth.instance.signInAnonymously();
        }
      }
      await _listenToUserChatsAndRequests();
    } catch (e) {
      Loggers.error('Chat bootstrap failed: $e');
      chatError.value =
          'Unable to connect to chat. Check Firebase Auth / Firestore rules.';
      isLoading.value = false;
    }
  }

  Future<void> _listenToUserChatsAndRequests() async {
    isLoading.value = true;
    _chatSubscription?.cancel();
    _chatSubscription = db
        .collection(FirebaseConst.users)
        .doc(myUser?.id.toString())
        .collection(FirebaseConst.usersList)
        .withConverter(
            fromFirestore: (snapshot, options) =>
                ChatThread.fromJson(snapshot.data()!),
            toFirestore: (ChatThread value, options) => value.toJson())
        .where(FirebaseConst.isDeleted, isEqualTo: false)
        .orderBy(FirebaseConst.id, descending: true)
        .snapshots()
        .listen((event) {
      isLoading.value = false;
      chatError.value = null;
      for (var change in event.docChanges) {
        final ChatThread? chatUser = change.doc.data();
        if (chatUser == null) continue;

        switch (change.type) {
          case DocumentChangeType.added:
            if (chatUser.userId != -1) {
              firebaseFirestoreController
                  .fetchUserIfNeeded(chatUser.userId ?? -1);
            }
            if (chatUser.chatType == ChatType.approved) {
              if (chatsUsers.every((e) => e.userId != chatUser.userId)) {
                chatsUsers.add(chatUser);
              }
            } else {
              if (requestsUsers.every((e) => e.userId != chatUser.userId)) {
                requestsUsers.add(chatUser);
              }
            }
            break;
          case DocumentChangeType.modified:
            final userId = chatUser.userId;
            chatsUsers.removeWhere((user) => user.userId == userId);
            requestsUsers.removeWhere((user) => user.userId == userId);
            (chatUser.chatType == ChatType.approved
                    ? chatsUsers
                    : requestsUsers)
                .add(chatUser);
            break;
          case DocumentChangeType.removed:
            final userId = chatUser.userId;
            chatsUsers.removeWhere((user) => user.userId == userId);
            requestsUsers.removeWhere((user) => user.userId == userId);
            break;
        }
      }

      chatsUsers.sort((a, b) => (b.id ?? '0').compareTo(a.id ?? '0'));
      requestsUsers.sort((a, b) => (b.id ?? '0').compareTo(a.id ?? '0'));
    }, onError: (error) {
      isLoading.value = false;
      Loggers.error('CHAT LISTEN ERROR: $error');
      chatError.value =
          'Chat permission or connection error. Firestore needs Firebase Auth.';
    });
  }

  void onLongPress(ChatThread chatConversation) {
    Get.bottomSheet(ConfirmationSheet(
      title: LKey.deleteChatUserTitle.trParams(
          {'user_name': chatConversation.chatUser?.username ?? ''}),
      description: LKey.deleteChatUserDescription.tr,
      onTap: () async {
        int time = DateTime.now().millisecondsSinceEpoch;
        showLoader();
        await db
            .collection(FirebaseConst.users)
            .doc(myUser?.id.toString())
            .collection(FirebaseConst.usersList)
            .doc(chatConversation.userId.toString())
            .update({
          FirebaseConst.deletedId: time,
          FirebaseConst.isDeleted: true,
        }).catchError((error) {
          Loggers.error('USER NOT DELETE : $error');
        });
        stopLoader();
      },
    ));
  }
}
