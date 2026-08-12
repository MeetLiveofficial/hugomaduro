import 'dart:async';
import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:krimson/common/manager/app_role.dart';
import 'package:krimson/common/manager/logger.dart';
import 'package:krimson/common/manager/session_manager.dart' show SessionManager;
import 'package:krimson/common/service/api/call_service.dart';
import 'package:krimson/common/service/api/live_session_service.dart';
import 'package:krimson/common/service/api/notification_service.dart';
import 'package:krimson/common/service/api/post_service.dart';
import 'package:krimson/common/service/api/user_service.dart';
import 'package:krimson/common/service/navigation/navigate_with_controller.dart';
import 'package:krimson/languages/dynamic_translations.dart';
import 'package:krimson/model/call/call_request_model.dart';
import 'package:krimson/model/chat/chat_thread.dart';
import 'package:krimson/model/livestream/livestream.dart';
import 'package:krimson/model/post_story/post_model.dart';
import 'package:krimson/screen/call_screen/incoming_call_screen.dart';
import 'package:krimson/screen/call_screen/live_incoming_call_overlay.dart';
import 'package:krimson/screen/call_screen/outgoing_call_screen.dart';
import 'package:krimson/screen/call_screen/video_call_screen.dart';
import 'package:krimson/screen/chat_screen/chat_screen.dart';
import 'package:krimson/screen/chat_screen/chat_screen_controller.dart';
import 'package:krimson/screen/dashboard_screen/dashboard_screen_controller.dart';
import 'package:krimson/screen/live_stream/livestream_screen/livestream_screen_controller.dart';
import 'package:krimson/screen/live_stream/livestream_screen/widget/live_invite_dialog.dart';
import 'package:krimson/screen/live_stream/livestream_screen/widget/live_battle_invite_dialog.dart';
import 'package:krimson/screen/message_screen/message_screen_controller.dart';
import 'package:krimson/screen/message_screen/widget/calls_list_view.dart';
import 'package:krimson/screen/post_screen/single_post_screen.dart';
import 'package:krimson/screen/reels_screen/reels_screen.dart';
import 'package:krimson/screen/reels_screen/widget/reel_page_type.dart';
import 'package:krimson/screen/tasks_screen/tasks_screen.dart';
import 'package:krimson/utilities/app_platform.dart';
import 'package:krimson/utilities/const_res.dart';

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse notificationResponse) {
  print('NOTIFICATION TAP ON BACKGROUND');
  notificationResponse.data;
  if (notificationResponse.payload != null) {
    FirebaseNotificationManager.instance.handleNotification(notificationResponse.payload!);
  }
}

class FirebaseNotificationManager {
  FirebaseNotificationManager._() {
    if (Firebase.apps.isEmpty) {
      Loggers.error(
          'FCM skipped: Firebase.initializeApp() no se ejecutó todavía');
      return;
    }
    init();
  }

  static final instance = FirebaseNotificationManager._();

  /// Lazy: no tocar Messaging si Firebase aún no existe (evita [core/no-app]).
  FirebaseMessaging? _firebaseMessaging;
  FirebaseMessaging get firebaseMessaging {
    _firebaseMessaging ??= FirebaseMessaging.instance;
    return _firebaseMessaging!;
  }
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  RxString notificationPayload = ''.obs;
  AndroidNotificationChannel channel = const AndroidNotificationChannel(
      'krimson', // id
      'Meet&Live', // title
      playSound: true,
      enableLights: true,
      enableVibration: true,
      showBadge: false,
      importance: Importance.max);

  AndroidNotificationChannel callChannel = const AndroidNotificationChannel(
      'krimson_calls',
      'Meet&Live Calls',
      playSound: true,
      enableLights: true,
      enableVibration: true,
      showBadge: true,
      importance: Importance.max);

  String? notificationId;

  void init() async {
    if (kIsWeb) {
      return;
    }
    if (Firebase.apps.isEmpty) {
      Loggers.error('FCM init abort: no Firebase app');
      return;
    }
    if (AppPlatform.isAndroid) {
      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    } else {
      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, sound: true);
      await firebaseMessaging.requestPermission(alert: true, badge: false, sound: true);
    }

    subscribeToTopic();

    var initializationSettingsAndroid = const AndroidInitializationSettings('@mipmap/ic_launcher');

    var initializationSettingsIOS = const DarwinInitializationSettings(
        defaultPresentAlert: true, defaultPresentSound: true, defaultPresentBadge: false);

    var initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid, iOS: initializationSettingsIOS);

    // Handling notification taps
    flutterLocalNotificationsPlugin.initialize(
        settings: initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          print('onDidReceiveNotificationResponse ${response.payload}');
          String? payload = response.payload;
          if (payload != null) {
            notificationPayload.value = payload;
          }
        },
        onDidReceiveBackgroundNotificationResponse: notificationTapBackground);

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      // If Notification has gone twice
      if (notificationId == message.messageId) return;
      notificationId = message.messageId;

      final type = message.data['type'];
      final data = message.data['notification_data'] ?? '';

      if (type == NotificationType.chat.type) {
        if (data.isNotEmpty) {
          try {
            final conversationUser = ChatThread.fromJson(jsonDecode(data));
            if (conversationUser.conversationId == ChatScreenController.chatId) {
              return;
            }
          } catch (e) {
            Loggers.error('chat push parse: $e');
          }
        }
      } else if (type == 'call_request') {
        showNotification(message, isCall: true);
        _refreshCallsBadge();
        // App en foreground: siempre mostrar UI de llamada entrante.
        _openIncomingCallFromPush(message.data);
        return;
      } else if (type == 'call_rejected') {
        showNotification(message, isCall: true);
        final id = int.tryParse('${message.data['call_request_id'] ?? ''}');
        OutgoingCallController.handleRemoteRejected(id);
        return;
      } else if (type == 'call_cancelled') {
        final id = int.tryParse('${message.data['call_request_id'] ?? ''}');
        IncomingCallController.handleRemoteCancelled(id);
        _refreshCallsBadge();
        return;
      } else if (type == 'call_accepted') {
        showNotification(message, isCall: true);
        _openAcceptedCallFromPush(message.data);
        return;
      } else if (type == NotificationType.liveStream.type) {
        showNotification(message);
        // App en foreground: diálogo Unirse / Más tarde (no auto-navegar).
        final data = message.data['notification_data'] ?? '';
        if (data.toString().isNotEmpty) {
          _showLiveInviteFromPayload(data.toString());
        }
        return;
      } else {
        SessionManager.instance.setNotifyCount(1);
      }
      showNotification(message,
          isCall: type == 'call_accepted' || type == 'call_rejected');
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      Loggers.info('User tapped the notification: ${message.data}');
      print('FirebaseMessaging.onMessageOpenedApp');
      if (message.data.isNotEmpty) {
        handleNotification(jsonEncode(message.toMap()));
      }
    });

    final androidPlugin = flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(channel);
    await androidPlugin?.createNotificationChannel(callChannel);
  }

  void unsubscribeToTopic({String? topic}) async {
    Loggers.success(
        '🔔 Topic UnSubscribe : ${topic ?? notificationTopic}_${AppPlatform.isAndroid ? 'android' : 'ios'}');
    await firebaseMessaging.unsubscribeFromTopic(
        '${topic ?? notificationTopic}_${AppPlatform.isAndroid ? 'android' : 'ios'}');
    if (kDebugMode) {
      await firebaseMessaging.unsubscribeFromTopic(
          'test_${topic ?? notificationTopic}_${AppPlatform.isAndroid ? 'android' : 'ios'}');
    }
  }

  Future<void> subscribeToTopic({String? topic}) async {
    Loggers.success(
        '🔔 Topic Subscribe : ${topic ?? notificationTopic}_${AppPlatform.isAndroid ? 'android' : 'ios'}');
    await firebaseMessaging.subscribeToTopic(
        '${topic ?? notificationTopic}_${AppPlatform.isAndroid ? 'android' : 'ios'}');

    if (kDebugMode) {
      await firebaseMessaging.subscribeToTopic(
          'test_${topic ?? notificationTopic}_${AppPlatform.isAndroid ? 'android' : 'ios'}');
    }
  }

  void showNotification(RemoteMessage message, {bool isCall = false}) {
    print('SHOW MESSAGE : ${message.toMap()}');
    int notificationId = DateTime.now().millisecondsSinceEpoch.remainder(100000);
    final activeChannel = isCall ? callChannel : channel;

    flutterLocalNotificationsPlugin.show(
        id: notificationId,
        title: (message.data['title']) ?? message.notification?.title,
        body: (message.data['body'] as String?) ?? message.notification?.body,
        notificationDetails: NotificationDetails(
            iOS: const DarwinNotificationDetails(
                presentSound: true, presentAlert: true, presentBadge: false),
            android: AndroidNotificationDetails(
              activeChannel.id,
              activeChannel.name,
              channelDescription: isCall ? 'Incoming video calls' : null,
              importance: Importance.max,
              priority: Priority.max,
              playSound: true,
              enableVibration: true,
            )),
        payload: jsonEncode(message.toMap()));
  }

  Future<void> handleNotification(String payload) async {
    final RemoteMessage message = RemoteMessage.fromMap(jsonDecode(payload));
    final dataType = message.data['type'];
    final dataString = message.data['notification_data'];
    print('DATA TYPE : $dataType');
    print('DATA STRING : $dataString');
    if (dataType == null) return;

    if (dataType == 'call_request') {
      // Tap en notificación: abrir UI de llamada (o ir a CALL).
      await _openIncomingCallFromPush(message.data, forceOpen: true);
      return;
    }
    if (dataType == 'call_rejected') {
      final id = int.tryParse('${message.data['call_request_id'] ?? ''}');
      OutgoingCallController.handleRemoteRejected(id);
      return;
    }
    if (dataType == 'call_cancelled') {
      final id = int.tryParse('${message.data['call_request_id'] ?? ''}');
      IncomingCallController.handleRemoteCancelled(id);
      return;
    }
    if (dataType == 'call_accepted') {
      await _openAcceptedCallFromPush(message.data);
      return;
    }

    if (dataType == 'task') {
      if (!AppRole.canAccessTasks()) return;
      Future.delayed(const Duration(milliseconds: 300), () {
        Get.to(() => const TasksScreen());
      });
      return;
    }

    if (dataString == null || dataString.isEmpty) return;
    final controller = Get.put(DashboardScreenController());
    switch (dataType) {
      case 'chat':
        Future.delayed(const Duration(milliseconds: 500), () async {
          controller.selectedPageIndex.value =
              DashboardScreenController.tabChat;
          await _handleChatNotification(dataString);
        });

        break;
      case 'post':
        await _handlePostNotification(dataString, controller);
        break;
      case 'user':
        controller.selectedPageIndex.value =
            DashboardScreenController.tabProfile;
        await _handleUserNotification(dataString);
        break;
      case 'live_stream':
        await _showLiveInviteFromPayload(dataString);
        break;
      case 'battle_invite':
        await _showBattleInviteFromPayload(dataString);
        break;
      default:
        Loggers.warning('Unknown notification type: $dataType');
    }
  }

  Future<void> _showBattleInviteFromPayload(String dataString) async {
    try {
      final incomingStream = Livestream.fromJson(jsonDecode(dataString));
      final roomId = incomingStream.roomID ?? '${incomingStream.hostId ?? ''}';
      if (roomId.isEmpty) return;

      Livestream stream = incomingStream;
      try {
        final payload =
            await LiveSessionService.instance.fetchSession(roomId: roomId);
        if (payload?.session != null) {
          stream = payload!.session;
        }
      } catch (_) {}

      await LiveBattleInviteDialog.showIfNeeded(stream);
    } catch (e) {
      Loggers.error('battle invite dialog: $e');
    }
  }

  Future<void> _showLiveInviteFromPayload(String dataString) async {
    try {
      final incomingStream = Livestream.fromJson(jsonDecode(dataString));
      final roomId = incomingStream.roomID ?? '${incomingStream.hostId ?? ''}';
      if (roomId.isEmpty) return;

      Livestream stream = incomingStream;
      try {
        final payload =
            await LiveSessionService.instance.fetchSession(roomId: roomId);
        if (payload?.session != null) {
          stream = payload!.session;
        }
      } catch (_) {}

      await LiveInviteDialog.showIfNeeded(stream);
    } catch (e) {
      Loggers.error('live invite dialog: $e');
    }
  }

  Future<void> _openIncomingCallFromPush(
    Map<String, dynamic> data, {
    bool forceOpen = false,
  }) async {
    final id = int.tryParse('${data['call_request_id'] ?? ''}');
    if (id == null) return;
    final tag = 'incoming_$id';
    if (Get.isRegistered<IncomingCallController>(tag: tag)) return;
    try {
      final inbox = await CallService.instance.inbox();
      final pending = inbox.received
          .where((e) => e.id == id && e.isPending)
          .toList();
      if (pending.isEmpty) return;
      final call = pending.first;
      final opened = await LiveIncomingCallOverlay.show(call);
      if (opened) return;

      // Fallback: half-sheet también vía Get.to (sin pantalla completa).
      if (!forceOpen) return;
      if (Get.isRegistered<DashboardScreenController>()) {
        final dash = Get.find<DashboardScreenController>();
        dash.selectedPageIndex.value = DashboardScreenController.tabChat;
      }
      if (Get.isRegistered<MessageScreenController>()) {
        Get.find<MessageScreenController>().openCallsTab();
      }
      Get.to(
        () => IncomingCallScreen(call: call, asDialog: true),
        opaque: false,
        fullscreenDialog: true,
        transition: Transition.downToUp,
      );
    } catch (e) {
      Loggers.error('open incoming call from push: $e');
    }
  }

  Future<void> _openAcceptedCallFromPush(Map<String, dynamic> data) async {
    final id = int.tryParse('${data['call_request_id'] ?? ''}');
    final roomId = '${data['room_id'] ?? ''}'.trim();
    if (id == null) return;

    // Emisor con Outgoing abierto: una sola transición (no apilar VideoCall).
    if (OutgoingCallController.activeInstance != null) {
      OutgoingCallController.handleRemoteAccepted(
        callRequestId: id,
        roomId: roomId.isEmpty ? null : roomId,
      );
      return;
    }

    final tag = 'call_$id';
    if (Get.isRegistered<VideoCallController>(tag: tag)) return;

    try {
      final inbox = await CallService.instance.inbox();
      final all = [...inbox.received, ...inbox.sent];
      CallRequestModel? match;
      for (final e in all) {
        if (e.id == id && e.isAccepted) {
          match = e;
          break;
        }
      }
      if (match == null && roomId.isNotEmpty) {
        match = CallRequestModel(
          id: id,
          status: 'accepted',
          roomId: roomId,
        );
      }
      if (match == null || (match.roomId ?? '').isEmpty) return;
      Get.to(() => VideoCallScreen(call: match!));
    } catch (e) {
      Loggers.error('open accepted call from push: $e');
    }
  }

  void _refreshCallsBadge() {
    try {
      if (Get.isRegistered<DashboardScreenController>()) {
        final dash = Get.find<DashboardScreenController>();
        dash.callsUnReadCount.value = dash.callsUnReadCount.value + 1;
        dash.unReadCount.value = dash.chatUnReadCount.value +
            dash.requestUnReadCount.value +
            dash.callsUnReadCount.value;
      }
      if (Get.isRegistered<CallsListController>()) {
        unawaited(
            Get.find<CallsListController>().refreshInbox(silent: true));
      }
    } catch (e) {
      Loggers.error('refresh calls badge: $e');
    }
  }

  Future<void> _handleChatNotification(String data) async {
    try {
      final conversationUser = ChatThread.fromJson(jsonDecode(data));
      Loggers.info('Navigating to chat: ${conversationUser.toJson()}');
      await Get.to(() => ChatScreen(conversationUser: conversationUser));
    } catch (e) {
      Loggers.error('Failed to handle chat notification: $e');
    }
  }

  Future<void> _handlePostNotification(String data, DashboardScreenController controller) async {
    try {
      NotificationInfo notificationInfo = NotificationInfo.fromJson(jsonDecode(data));
      final int postId = notificationInfo.id ?? -1;
      final int? commentId = notificationInfo.commentId;
      final int? replyId = notificationInfo.replyCommentId;
      final result = await PostService.instance
          .fetchPostById(postId: postId, commentId: commentId, replyId: replyId);

      if (result.status == true && result.data != null) {
        final Post? post = result.data?.post;
        if (post == null) return;

        if (post.postType == PostType.reel) {
          controller.selectedPageIndex.value =
              DashboardScreenController.tabProfile;
          Get.to(() => ReelsScreen(
                reels: [post].obs,
                position: 0,
                postByIdData: result.data,
                pageType: ReelPageType.notification,
              ));
        } else if ([PostType.text, PostType.image, PostType.video].contains(post.postType)) {
          controller.selectedPageIndex.value =
              DashboardScreenController.tabHome;
          controller.homeTabMode.value = HomeTabMode.feed;
          await Get.to(() =>
              SinglePostScreen(post: post, postByIdData: result.data, isFromNotification: true));
        }
      }
    } catch (e) {
      Loggers.error('Failed to handle post notification: $e');
    }
  }

  Future<void> _handleUserNotification(String data) async {
    try {
      final map = jsonDecode(data);
      final int id = map['id'];
      final user = await UserService.instance.fetchUserDetails(userId: id);

      if (user != null) {
        Loggers.success('Navigating to user: ${user.id}');
        NavigationService.shared.openProfileScreen(user);
      }
    } catch (e) {
      Loggers.error('Failed to handle user notification: $e');
    }
  }

  Future<String?> getNotificationToken() async {
    try {
      if (kIsWeb) {
        final storage = GetStorage('krimson');
        final stored = storage.read('device_token');
        if (stored is String && stored.isNotEmpty) return stored;
        final token =
            'krimson_web_${DateTime.now().millisecondsSinceEpoch}';
        await storage.write('device_token', token);
        return token;
      }
      if (Firebase.apps.isEmpty) {
        Loggers.error('getNotificationToken: Firebase not initialized');
      } else {
        String? token = await firebaseMessaging.getToken();
        Loggers.info('DeviceToken $token');
        if (token != null && token.isNotEmpty) return token;
      }
    } catch (e) {
      Loggers.error('DeviceToken Exception $e');
    }
    // Fallback si FCM no entrega token (emulador / permisos).
    final fallback =
        'krimson_${AppPlatform.isAndroid ? 'android' : 'ios'}_${DateTime.now().millisecondsSinceEpoch}';
    Loggers.warning('DeviceToken fallback: $fallback');
    return fallback;
  }

  Future<void> sendLocalisationNotification(
    String key, {
    Map<String, String> keyParams = const {},
    String? deviceToken = '',
    int? deviceType = 0,
    String? languageCode = 'en',
    required NotificationInfo body,
    required NotificationType type,
    Map<String, dynamic>? extraData,
  }) async {
    // Early return if no device token provided
    if ((deviceToken ?? '').isEmpty) {
      Loggers.error('Device Token Empty - Notification not sent for key: $key');
      return;
    }

    // Get user data once
    final user = SessionManager.instance.getUser();
    final title = user?.fullname ?? '';

    // Get translations efficiently
    final translations = Get.find<DynamicTranslations>();
    final languageData = translations.keys[languageCode] ?? {};

    // Get description with fallback
    var description = languageData[key] ?? key;

    keyParams.forEach((key, value) {
      description = description.replaceAll('@$key', value);
    });

    // Log relevant information
    Loggers.info('''
      [Notification Details]
      Language: $languageCode
      Key: $key
      Description: $description
      Recipient: ${user?.id ?? 'Unknown'}
      Device Type: $deviceType
      Device Token: $deviceToken
    ''');

    // Send notification
    await NotificationService.instance.pushNotification(
        title: title,
        body: description,
        data: extraData ?? body.toJson(),
        deviceType: deviceType,
        token: deviceToken,
        type: type);
  }
}

enum NotificationType {
  chat('chat'),
  post('post'),
  user('user'),
  liveStream('live_stream'),
  battleInvite('battle_invite'),
  task('task'),
  other('other');

  final String type;

  const NotificationType(this.type);
}

class NotificationInfo {
  int? id;
  int? commentId;
  int? replyCommentId;

  NotificationInfo({
    this.id,
    this.commentId,
    this.replyCommentId,
  });

  factory NotificationInfo.fromJson(Map<String, dynamic> json) => NotificationInfo(
        id: json["id"],
        commentId: json["comment_id"],
        replyCommentId: json["reply_comment_id"],
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "comment_id": commentId,
        "reply_comment_id": replyCommentId,
      };
}
