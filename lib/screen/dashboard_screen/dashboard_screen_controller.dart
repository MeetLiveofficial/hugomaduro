import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:krimson/common/controller/ads_controller.dart';
import 'package:krimson/common/controller/base_controller.dart';
import 'package:krimson/common/controller/firebase_firestore_controller.dart';
import 'package:krimson/common/manager/app_role.dart';
import 'package:krimson/common/manager/firebase_app_helper.dart';
import 'package:krimson/common/manager/firebase_notification_manager.dart';
import 'package:krimson/common/manager/logger.dart';
import 'package:krimson/common/manager/session_manager.dart';
import 'package:krimson/common/service/api/call_service.dart';
import 'package:krimson/common/service/api/live_session_service.dart';
import 'package:krimson/common/service/api/user_service.dart';
import 'package:krimson/common/service/subscription/subscription_manager.dart';
import 'package:krimson/common/widget/restart_widget.dart';
import 'package:krimson/languages/languages_keys.dart';
import 'package:krimson/model/chat/chat_thread.dart';
import 'package:krimson/model/general/settings_model.dart';
import 'package:krimson/model/user_model/user_model.dart';
import 'package:krimson/screen/call_screen/live_incoming_call_overlay.dart';
import 'package:krimson/screen/call_screen/outgoing_call_screen.dart';
import 'package:krimson/screen/camera_screen/camera_screen.dart';
import 'package:krimson/screen/feed_screen/feed_screen_controller.dart';
import 'package:krimson/screen/gif_sheet/gif_sheet_controller.dart';
import 'package:krimson/screen/live_stream/livestream_screen/livestream_screen_controller.dart';
import 'package:krimson/screen/live_stream/livestream_screen/widget/live_invite_dialog.dart';
import 'package:krimson/screen/live_stream/livestream_screen/widget/live_battle_invite_dialog.dart';
import 'package:krimson/model/livestream/livestream.dart';
import 'package:krimson/utilities/asset_res.dart';
import 'package:krimson/utilities/const_res.dart';
import 'package:krimson/utilities/firebase_const.dart';

class DashboardScreenController extends BaseController with GetSingleTickerProviderStateMixin {
  /// Orden bottom nav: Home · Explore · Live/Match (centro) · Chat · Profile
  static const int tabHome = 0;
  static const int tabExplore = 1;
  static const int tabLive = 2;
  static const int tabChat = 3;
  static const int tabProfile = 4;

  List<String> bottomIconList = [
    AssetRes.icReel,
    AssetRes.icSearch,
    AssetRes.icLiveStream,
    AssetRes.icChat,
    AssetRes.icProfile
  ];
  /// Home por defecto (descubrimiento LIVE). El tab centro es el estudio (cámara).
  RxInt selectedPageIndex = tabHome.obs;
  /// Dentro del tab Home: LIVE (activos) por defecto, Reels o Feed.
  final Rx<HomeTabMode> homeTabMode = HomeTabMode.live.obs;
  RxDouble scaleValue = 1.0.obs;
  Function(int index)? onBottomIndexChanged;
  Rx<PostUploadingProgress> postProgress = Rx(PostUploadingProgress());
  Function(PostUploadingProgress progress) onProgress = (_) {};

  late AnimationController animationController;

  /// Lazy: no tocar Firestore en el constructor (evita [core/no-app]).
  FirebaseFirestore get db => FirebaseFirestore.instance;
  RxInt unReadCount = 0.obs;
  RxInt chatUnReadCount = 0.obs;
  RxInt requestUnReadCount = 0.obs;
  RxInt callsUnReadCount = 0.obs;

  StreamSubscription? _unReadCountSubscription;
  late Animation<double> scaleAnimation;
  User? user = SessionManager.instance.getUser();

  @override
  void onInit() {
    super.onInit();
    user = SessionManager.instance.getUser() ?? user;
    // Streamer no usa el feed Home: arrancar en Perfil (seguro, sin cámara).
    if (AppRole.isStreamer(user)) {
      selectedPageIndex.value = tabProfile;
    }
    SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(statusBarBrightness: Brightness.light));
    Get.put(GifSheetController());
    Get.put(AdsController());
    animationController = AnimationController(duration: const Duration(milliseconds: 200), vsync: this);
    scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: animationController, curve: Curves.easeInOut),
    )..addListener(() {
        scaleValue.value = scaleAnimation.value; // Update reactive scale value
      });
    onProgress = (progress) {
      postProgress.value = progress;
    };
  }

  @override
  void onReady() async {
    super.onReady();
    SubscriptionManager.shared.subscriptionListener();

    if (useFirebase) {
      await FirebaseAppHelper.ensureInitialized();
    }
    // Cache local de usuarios de chat/live (funciona sin Firestore).
    if (!Get.isRegistered<FirebaseFirestoreController>()) {
      Get.put(FirebaseFirestoreController());
    }

    // Asegura Auth anónimo si hace falta para Firestore.
    if (useFirebase && Firebase.apps.isNotEmpty) {
      try {
        if (firebase_auth.FirebaseAuth.instance.currentUser == null) {
          await firebase_auth.FirebaseAuth.instance.signInAnonymously();
        }
      } catch (e) {
        Loggers.error('Firebase anonymous auth on dashboard failed: $e');
      }
    }

    // Run below in parallel
    _fetchLanguageFromUser();
    _fetchUnReadCount();
    startCacheCleanupScheduler();
    _startLiveInvitePoll();
    _startIncomingCallPoll();
    _subscribeFollowUserIds();
    updateDummyUsers();
  }

  Timer? _liveInvitePollTimer;
  Timer? _incomingCallPollTimer;
  Timer? _heartbeatTimer;
  final Set<int> _seenIncomingCallIds = {};
  bool _incomingCallPollPrimed = false;
  bool _incomingCallPollBusy = false;

  /// Poll de invitaciones LIVE (cubre Web/sin FCM real).
  void _startLiveInvitePoll() {
    _liveInvitePollTimer?.cancel();
    Future.microtask(_pollLiveInvites);
    _liveInvitePollTimer =
        Timer.periodic(const Duration(seconds: 8), (_) => _pollLiveInvites());
  }

  /// Poll global de llamadas entrantes (badge + overlay; cubre sin FCM / BlueStacks).
  void _startIncomingCallPoll() {
    _incomingCallPollTimer?.cancel();
    Future.microtask(_pollIncomingCalls);
    _incomingCallPollTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _pollIncomingCalls(),
    );
  }

  Future<void> _pollIncomingCalls() async {
    if (_incomingCallPollBusy) return;
    if (!SessionManager.instance.isLogin() ||
        !SessionManager.instance.hasAuthToken) {
      return;
    }
    // LIVE ya tiene su propio poll de llamadas.
    if (LivestreamScreenController.activeInstance != null) return;
    if (OutgoingCallController.activeInstance != null) return;
    if (Get.currentRoute.contains('VideoCall') ||
        Get.currentRoute.contains('OutgoingCall') ||
        Get.currentRoute.contains('IncomingCall')) {
      return;
    }

    _incomingCallPollBusy = true;
    try {
      final inbox = await CallService.instance.inbox();
      final pending =
          inbox.received.where((e) => e.isPending && e.id != null).toList();

      callsUnReadCount.value = pending.length;
      unReadCount.value = chatUnReadCount.value +
          requestUnReadCount.value +
          callsUnReadCount.value;

      if (!_incomingCallPollPrimed) {
        _seenIncomingCallIds.addAll(pending.map((e) => e.id!));
        _incomingCallPollPrimed = true;
        if (pending.isNotEmpty) {
          await LiveIncomingCallOverlay.show(pending.first);
        }
        return;
      }

      for (final item in pending) {
        if (_seenIncomingCallIds.add(item.id!)) {
          await LiveIncomingCallOverlay.show(item);
          break;
        }
      }
    } catch (e) {
      Loggers.error('dashboard incoming call poll: $e');
    } finally {
      _incomingCallPollBusy = false;
    }
  }

  Future<void> _pollLiveInvites() async {
    if (!SessionManager.instance.isLogin() ||
        !SessionManager.instance.hasAuthToken) {
      return;
    }
    try {
      final invites = await LiveSessionService.instance.pendingInvites();
      for (final stream in invites) {
        if (stream.type == LivestreamType.battle &&
            stream.battleType == BattleType.waiting) {
          await LiveBattleInviteDialog.showIfNeeded(stream);
        } else {
          await LiveInviteDialog.showIfNeeded(stream);
        }
      }
    } catch (e) {
      Loggers.error('pending live invites poll: $e');
    }
  }

  void startCacheCleanupScheduler() {
    _heartbeatTimer?.cancel();
    if (!SessionManager.instance.isLogin()) return;
    UserService.instance.updateLastUsedAt();
    // Heartbeat frecuente para que ACTIVE/INACTIVE no parpadee.
    _heartbeatTimer = Timer.periodic(const Duration(minutes: 2), (_) {
      if (!SessionManager.instance.isLogin() ||
          !SessionManager.instance.hasAuthToken) {
        return;
      }
      UserService.instance.updateLastUsedAt();
    });
  }

  /// Detiene polls/timers (llamar en logout aunque GetX tarde en onClose).
  void stopBackgroundWork() {
    _liveInvitePollTimer?.cancel();
    _liveInvitePollTimer = null;
    _incomingCallPollTimer?.cancel();
    _incomingCallPollTimer = null;
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    _unReadCountSubscription?.cancel();
    _unReadCountSubscription = null;
  }

  @override
  void onClose() {
    stopBackgroundWork();
    animationController.dispose();
    super.onClose();
  }

  onChanged(int index) {
    // Streamer: tabLive = estudio Go Live. Cliente: tabLive = Match.
    final isDarkChrome = index == tabHome &&
        (homeTabMode.value == HomeTabMode.reels ||
            homeTabMode.value == HomeTabMode.live);
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
        statusBarBrightness:
            isDarkChrome || (index == tabLive && AppRole.isClient(user))
                ? Brightness.dark
                : Brightness.light));
    if (index == tabHome && homeTabMode.value == HomeTabMode.feed) {
      onFeedPostScrollDown(index);
    }
    if (selectedPageIndex.value == index) return;
    HapticFeedback.lightImpact();
    onBottomIndexChanged?.call(index);
    selectedPageIndex.value = index;
    animationController
      ..reset()
      ..forward();
  }

  void setHomeTabMode(HomeTabMode mode) {
    homeTabMode.value = mode;
    final dark = (mode == HomeTabMode.reels || mode == HomeTabMode.live) &&
        selectedPageIndex.value == tabHome;
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
        statusBarBrightness: dark ? Brightness.dark : Brightness.light));
    if (mode == HomeTabMode.feed) {
      onFeedPostScrollDown(tabHome);
    }
  }

  onFeedPostScrollDown(int index) {
    if (selectedPageIndex.value != index) return;
    if (Get.isRegistered<FeedScreenController>()) {
      final controller = Get.find<FeedScreenController>();
      if (controller.posts.isNotEmpty && !controller.isLoading.value) {
        controller.postScrollController
            .animateTo(0.0, duration: const Duration(milliseconds: 150), curve: Curves.linear);
        controller.refreshKey.currentState?.show();
      }
    }
  }

  void _fetchUnReadCount() {
    if (!useFirebase) {
      unReadCount.value = 0;
      requestUnReadCount.value = 0;
      return;
    }
    _unReadCountSubscription = db
        .collection(FirebaseConst.users)
        .doc(user?.id.toString())
        .collection(FirebaseConst.usersList)
        .where(FirebaseConst.isDeleted, isEqualTo: false)
        .withConverter(
          fromFirestore: (snapshot, _) => ChatThread.fromJson(snapshot.data()!),
          toFirestore: (value, _) => value.toJson(),
        )
        .snapshots()
        .listen((event) {
      // Calculate unread counts once per snapshot (not per docChange)
      final docs = event.docs.map((e) => e.data()).toList();

      final totalUnread = docs.where((e) => (e.msgCount ?? 0) > 0).length;

      final requestUnread = docs.where((e) => (e.msgCount ?? 0) > 0 && e.chatType == ChatType.request).length;

      unReadCount.value = totalUnread;
      requestUnReadCount.value = requestUnread;
    });
  }

  Future<void> _fetchLanguageFromUser() async {
    final savedLanguage = SessionManager.instance.getLang();
    // Perfil fresco de sesión (tras login ya sincronizado con el idioma elegido).
    final profileLang =
        SessionManager.instance.getUser()?.appLanguage ?? user?.appLanguage;

    // Si el perfil no trae idioma, conservar el de sesión (p. ej. elegido pre-login).
    if (profileLang == null || profileLang.trim().isEmpty) {
      final resolved = SessionManager.instance.ensureActiveLang(savedLanguage);
      if (resolved != savedLanguage) {
        SessionManager.instance.setLang(resolved);
      }
      return;
    }

    // Solo aplica app_language si está entre los idiomas activos del panel.
    final resolved = SessionManager.instance.ensureActiveLang(profileLang);
    if (resolved != savedLanguage) {
      SessionManager.instance.setLang(resolved);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final ctx = Get.context;
        if (ctx != null) RestartWidget.restartApp(ctx);
      });
    }
  }

  void _subscribeFollowUserIds() async {
    if (!useFirebase) return;
    Future.wait([addUserInFirebase()]);
    for (int id in (user?.followingIds ?? [])) {
      // Delay slightly to avoid overloading FCM
      await Future.delayed(const Duration(milliseconds: 100));
      Future.wait([FirebaseNotificationManager.instance.subscribeToTopic(topic: '$id')]);
    }
  }

  Future addUserInFirebase() async {
    if (!useFirebase) return;
    if (Get.isRegistered<FirebaseFirestoreController>()) {
      Get.find<FirebaseFirestoreController>().addUser(user);
    } else {
      Get.put(FirebaseFirestoreController()).addUser(user);
    }
  }

  void updateDummyUsers() {
    if (!useFirebase) return;
    List<DummyLive> dummyLives = SessionManager.instance.getSettings()?.dummyLives ?? [];
    if (dummyLives.isNotEmpty) {
      final controller = Get.find<FirebaseFirestoreController>();
      for (var element in dummyLives) {
        controller.updateUser(element.user);
      }
    }
  }
}

enum HomeTabMode { live, reels, feed }

class PostUploadingProgress {
  final CameraScreenType type;
  final UploadType uploadType;
  final double progress;

  PostUploadingProgress({this.type = CameraScreenType.post, this.progress = 0, this.uploadType = UploadType.none});
}

enum UploadType {
  none,
  finish,
  error,
  uploading;

  String title(CameraScreenType type) {
    switch (this) {
      case UploadType.none:
        return '';
      case UploadType.finish:
        return type == CameraScreenType.post ? LKey.postUploadSuccessfully.tr : LKey.storyUploadSuccess.tr;
      case UploadType.error:
        return LKey.uploadingFailed.tr;
      case UploadType.uploading:
        return type == CameraScreenType.post ? LKey.postIsBeginUploading.tr : LKey.storyIsBeginUploading.tr;
    }
  }
}
