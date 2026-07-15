import 'package:get/get.dart';
import 'package:krimson/common/controller/firebase_firestore_controller.dart';
import 'package:krimson/common/extensions/user_extension.dart';
import 'package:krimson/common/service/api/user_service.dart';
import 'package:krimson/model/livestream/app_user.dart';
import 'package:krimson/model/user_model/user_model.dart';

class ChatThread {
  int? userId;
  String? id;
  int? msgCount;
  ChatType? chatType;
  String? requestType;
  String? lastMsg;
  String? conversationId;
  int? deletedId;
  bool? isDeleted;
  bool? iAmBlocked;
  bool? iBlocked;

  ChatThread({
    this.userId,
    this.id,
    this.msgCount,
    this.chatType,
    this.requestType,
    this.lastMsg,
    this.conversationId,
    this.deletedId,
    this.isDeleted,
    this.iAmBlocked,
    this.iBlocked,
  });

  ChatThread.fromJson(Map<String, dynamic> json) {
    userId = json['user_id'];
    id = json['id']?.toString();
    msgCount = json['msg_count'];
    chatType = ChatType.fromString(json['chat_type']?.toString());
    requestType = json['request_type']?.toString();
    lastMsg = json['last_msg']?.toString();
    conversationId = json['conversation_id']?.toString();
    deletedId = json['deleted_id'];
    isDeleted = json['is_deleted'] == true || json['is_deleted'] == 1;
    iAmBlocked = json['i_am_blocked'] == true || json['i_am_blocked'] == 1;
    iBlocked = json['i_blocked'] == true || json['i_blocked'] == 1;
    if (json['chat_user'] is Map) {
      _chatUser.value =
          AppUser.fromJson(Map<String, dynamic>.from(json['chat_user']));
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};

    data['user_id'] = userId;
    data['id'] = id;
    data['msg_count'] = msgCount ?? 0;
    data['chat_type'] = (chatType ?? ChatType.approved).value;
    data['request_type'] = requestType ?? '';
    data['last_msg'] = lastMsg ?? '';
    data['conversation_id'] = conversationId;
    data['deleted_id'] = deletedId ?? 0;
    data['is_deleted'] = isDeleted ?? false;
    data['i_am_blocked'] = iAmBlocked ?? false;
    data['i_blocked'] = iBlocked ?? false;
    return data;
  }

  /// Id del otro usuario en el hilo (Firestore `users_list` doc id).
  int get peerUserId => userId ?? chatUser?.userId ?? -1;

  // Reactive variable for chat user
  final Rx<AppUser?> _chatUser = Rx<AppUser?>(null);

  /// ✅ Plain getter and setter (same type = AppUser?)
  AppUser? get chatUser => _chatUser.value;

  set chatUser(AppUser? user) {
    if (user == null) return;
    _chatUser.value = user; // update reactive value

    if (!Get.isRegistered<FirebaseFirestoreController>()) return;
    final controller = Get.find<FirebaseFirestoreController>();
    final index = controller.users.indexWhere((element) => element.userId == user.userId);

    if (index != -1) {
      controller.users[index] = user;
    } else {
      controller.users.add(user);
    }
  }

  /// ✅ Expose Rx version for reactive UI (`Obx`)
  Rx<AppUser?> get chatUserRx => _chatUser;

  /// ✅ Initialize and auto-sync with controller / Laravel user API
  bool _boundChatUser = false;

  void bindChatUser() {
    if (_boundChatUser) return;
    _boundChatUser = true;

    // Ya viene de la API Laravel (chat_user).
    if (_chatUser.value != null) return;

    final uid = userId;
    if (uid == null) return;

    void applyFromUser(User? value) {
      if (value == null) return;
      _chatUser.value = value.appUser;
    }

    if (Get.isRegistered<FirebaseFirestoreController>()) {
      final controller = Get.find<FirebaseFirestoreController>();

      void updateUser() {
        final appUser =
            controller.users.firstWhereOrNull((element) => element.userId == uid);
        if (appUser != null) {
          _chatUser.value = appUser;
          return;
        }
        UserService.instance
            .fetchUserDetails(
              userId: uid,
              onError: () {},
            )
            .then((value) {
          if (value != null) {
            controller.cacheUser(value);
            applyFromUser(value);
          }
        });
      }

      ever(controller.users, (_) => updateUser());
      updateUser();
      return;
    }

    UserService.instance.fetchUserDetails(userId: uid).then(applyFromUser);
  }
}

enum ChatType {
  request('request'),
  approved('approved');

  final String value;

  const ChatType(this.value);

  static ChatType fromString(String? value) {
    if (value == null || value.isEmpty) return ChatType.approved;
    return ChatType.values.firstWhereOrNull((e) => e.value == value) ??
        ChatType.approved;
  }
}
