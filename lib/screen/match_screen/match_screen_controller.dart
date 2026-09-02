import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krimson/common/controller/base_controller.dart';
import 'package:krimson/common/manager/app_role.dart';
import 'package:krimson/common/manager/coin_gate.dart';
import 'package:krimson/common/manager/guest_gate.dart';
import 'package:krimson/common/manager/livekit_room_controller.dart';
import 'package:krimson/common/manager/logger.dart';
import 'package:krimson/common/manager/session_manager.dart';
import 'package:krimson/common/manager/streamer_camera_lock.dart';
import 'package:krimson/common/service/api/call_service.dart';
import 'package:krimson/common/service/api/user_service.dart';
import 'package:krimson/languages/languages_keys.dart';
import 'package:krimson/model/call/call_request_model.dart';
import 'package:krimson/screen/call_screen/live_incoming_call_overlay.dart';
import 'package:krimson/screen/call_screen/outgoing_call_screen.dart';
import 'package:krimson/screen/call_screen/video_call_screen.dart';
import 'package:krimson/screen/coin_wallet_screen/coin_wallet_screen.dart';
import 'package:krimson/screen/dashboard_screen/dashboard_screen_controller.dart';
import 'package:krimson/screen/live_stream/live_stream_search_screen/live_stream_search_screen_controller.dart';
import 'package:krimson/screen/match_screen/match_preview_screen.dart';
import 'package:krimson/screen/subscription_screen/subscription_screen.dart';
import 'package:krimson/utilities/const_res.dart';

enum MatchSearchMode { random, goddess }

class MatchScreenController extends BaseController
    with GetTickerProviderStateMixin {
  static const waitLkTag = 'match_wait';

  final Rx<MatchSearchMode> mode = MatchSearchMode.random.obs;
  final RxBool isMatching = false.obs;
  final RxBool inMatchPool = false.obs;
  /// Streamer: Match ON por defecto; solo se apaga si desmarca el radio.
  final RxBool streamerMatchEnabled = true.obs;
  final RxBool waitCameraOn = false.obs;
  final RxInt coins = 0.obs;
  final RxInt freeMatchesUsed = 0.obs;
  final RxInt freeMatchesQuota = 2.obs;

  late final AnimationController pulseController;
  Worker? _tabWorker;
  AppLifecycleListener? _lifecycle;
  Timer? _heartbeat;
  Timer? _inboxPoll;
  StreamSubscription? _waitDataSub;
  bool _joining = false;
  final Set<int> _joinedCallIds = {};

  int get walletCoins => coins.value;

  void refreshCoins() {
    final u = SessionManager.instance.getUser();
    coins.value = u?.coinWallet?.toInt() ?? 0;
    freeMatchesUsed.value = u?.dailyFreeMatchesUsed ?? 0;
    freeMatchesQuota.value = u?.dailyFreeMatchesQuota ??
        SessionManager.instance.getSettings()?.matchDailyFreeQuota ??
        2;
  }

  bool get isPlusMember =>
      (SessionManager.instance.getUser()?.isVerify ?? 0) == 1;

  /// Precio Random (coins van al monedero de la APP).
  int get randomHintCost =>
      SessionManager.instance.getSettings()?.matchRandomCoins ?? 50;

  /// Precio Goddess (coins van al monedero de la APP).
  int get goddessHintCost =>
      SessionManager.instance.getSettings()?.matchGoddessCoins ?? 150;

  int get membershipHintCost {
    final mid = ((randomHintCost + goddessHintCost) / 2).round();
    return mid.clamp(1, 9999);
  }

  bool get _matchUiVisible {
    if (AppRole.isStreamer()) return true;
    if (!Get.isRegistered<DashboardScreenController>()) return true;
    return Get.find<DashboardScreenController>().selectedPageIndex.value ==
        DashboardScreenController.tabLive;
  }

  @override
  void onInit() {
    super.onInit();
    pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    );
    refreshCoins();
    if (AppRole.isStreamer()) {
      mode.value = MatchSearchMode.random;
    }
    _syncPulse();
    if (Get.isRegistered<DashboardScreenController>()) {
      _tabWorker = ever(
        Get.find<DashboardScreenController>().selectedPageIndex,
        (_) {
          _syncPulse();
          unawaited(_syncPresence());
        },
      );
    }
    StreamerCameraLock.releaseMatchWait = leavePool;
    _lifecycle = AppLifecycleListener(
      onResume: () => unawaited(_syncPresence()),
      onHide: () {
        if (_stayInPool) return;
        unawaited(leavePool());
      },
      onPause: () {
        if (_stayInPool) return;
        unawaited(leavePool());
      },
    );
    unawaited(_syncPresence());
  }

  /// Match a pantalla completa (streamer): toma la cámara y entra al pool.
  Future<void> onWaitScreenOpened() async {
    StreamerCameraLock.matchWaitVisible = true;
    if (!AppRole.isStreamer()) return;
    if (streamerMatchEnabled.value) {
      await joinPool();
    }
  }

  /// Al salir de Match: suelta la cámara para que LIVE la encienda al instante.
  Future<void> onWaitScreenClosed() async {
    StreamerCameraLock.matchWaitVisible = false;
    if (!AppRole.isStreamer()) return;
    await leavePool();
    await _resumeLiveStudioCamera();
  }

  void _syncPulse() {
    final shouldRun = _matchUiVisible;
    if (shouldRun) {
      if (!pulseController.isAnimating) pulseController.repeat();
    } else if (pulseController.isAnimating) {
      pulseController.stop();
    }
  }

  bool get _stayInPool {
    final route = Get.currentRoute;
    if (route.contains('VideoCall') || route.contains('MatchPreview')) {
      return true;
    }
    // Streamer en espera: no salir del pool al perder el foco (BlueStacks,
    // app en segundo plano). Si no, el cliente web no lo encuentra.
    return AppRole.isStreamer() &&
        streamerMatchEnabled.value &&
        StreamerCameraLock.matchWaitVisible;
  }

  Future<void> _syncPresence() async {
    if (Get.currentRoute.contains('VideoCall')) {
      await leavePool();
      return;
    }
    if (Get.currentRoute.contains('MatchPreview')) {
      return;
    }
    if (AppRole.isStreamer()) {
      if (streamerMatchEnabled.value && StreamerCameraLock.matchWaitVisible) {
        await joinPool();
      } else if (!StreamerCameraLock.matchWaitVisible) {
        await leavePool();
      }
      return;
    }
    if (_matchUiVisible) {
      await joinPool();
    } else {
      await leavePool();
    }
  }

  Future<void> toggleStreamerMatch() async {
    if (!AppRole.isStreamer()) return;
    if (inMatchPool.value) {
      streamerMatchEnabled.value = false;
      await leavePool();
      return;
    }
    streamerMatchEnabled.value = true;
    await joinPool();
  }

  Future<void> joinPool() async {
    if (_joining) return;
    if (Get.currentRoute.contains('VideoCall')) return;
    if (inMatchPool.value) {
      if (AppRole.isStreamer() && !_hasLocalWaitVideo()) {
        _joining = true;
        try {
          await _pauseLiveStudioCamera();
          await _connectWaitCamera(null);
        } catch (e) {
          Loggers.error('Match wait camera retry: $e');
        } finally {
          _joining = false;
        }
      }
      return;
    }
    _joining = true;
    try {
      if (AppRole.isStreamer()) {
        await _pauseLiveStudioCamera();
      }
      // Cámara en paralelo con el API: si el permiso ya está, el feed sale ya.
      final camFuture = AppRole.isStreamer()
          ? _connectWaitCamera(null)
          : Future<void>.value();
      final waitRoom = await CallService.instance.joinMatch();
      if (AppRole.isStreamer() && !streamerMatchEnabled.value) {
        inMatchPool.value = false;
        await CallService.instance.leaveMatch();
        await _disconnectWaitCamera();
        return;
      }
      inMatchPool.value = true;
      _heartbeat?.cancel();
      _heartbeat = Timer.periodic(const Duration(seconds: 10), (_) {
        unawaited(CallService.instance.matchHeartbeat());
      });
      _inboxPoll?.cancel();
      _inboxPoll = Timer.periodic(const Duration(seconds: 2), (_) {
        unawaited(_pollMatchInbox());
      });
      unawaited(_pollMatchInbox());
      await camFuture;
      if (AppRole.isStreamer() &&
          (waitRoom ?? '').trim().isNotEmpty &&
          !_hasLocalWaitVideo()) {
        await _connectWaitCamera(waitRoom);
      }
    } catch (e) {
      inMatchPool.value = false;
      Loggers.error('Match joinPool: $e');
    } finally {
      _joining = false;
    }
  }

  /// Sale del pool en local sin cortar la cámara de espera (el API ya limpió).
  void markLeftPoolLocally() {
    _heartbeat?.cancel();
    _heartbeat = null;
    _inboxPoll?.cancel();
    _inboxPoll = null;
    inMatchPool.value = false;
  }

  Future<void> leavePool() async {
    markLeftPoolLocally();
    await _disconnectWaitCamera();
    await CallService.instance.leaveMatch();
  }

  bool _hasLocalWaitVideo() {
    if (!Get.isRegistered<LiveKitRoomController>(tag: waitLkTag)) return false;
    final lk = Get.find<LiveKitRoomController>(tag: waitLkTag);
    return firstVideoTrackOf(lk.localParticipant.value) != null;
  }

  Future<void> _connectWaitCamera(String? waitRoom) async {
    final me = SessionManager.instance.getUser();
    final id = me?.id;
    if (id == null) return;
    if (_hasLocalWaitVideo()) {
      waitCameraOn.value = true;
      if (Get.isRegistered<LiveKitRoomController>(tag: waitLkTag)) {
        _listenWaitRoomData(Get.find<LiveKitRoomController>(tag: waitLkTag));
      }
      return;
    }
    final room = (waitRoom ?? '').trim().isNotEmpty
        ? waitRoom!.trim()
        : 'matchwait_$id';
    try {
      if (!Get.isRegistered<LiveKitRoomController>(tag: waitLkTag)) {
        Get.put(LiveKitRoomController(), tag: waitLkTag);
      }
      final lk = Get.find<LiveKitRoomController>(tag: waitLkTag);
      await lk.connect(
        roomName: room,
        identity: '$id',
        name: me?.fullname ?? me?.username ?? 'streamer',
        publishCamera: true,
        publishMicrophone: false,
        wsUrl: liveKitWsUrl,
        forceReconnect: lk.isConnected.value &&
            firstVideoTrackOf(lk.localParticipant.value) == null,
        adaptiveStream: false,
        dynacast: false,
      );
      _listenWaitRoomData(lk);
      var hasTrack = firstVideoTrackOf(lk.localParticipant.value) != null;
      waitCameraOn.value = hasTrack || lk.cameraEnabled.value;
      lk.mediaRevision.value++;
      for (var i = 0; i < 10 && !hasTrack; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 120));
        hasTrack = firstVideoTrackOf(lk.localParticipant.value) != null;
        waitCameraOn.value = hasTrack || lk.cameraEnabled.value;
        lk.mediaRevision.value++;
      }
      waitCameraOn.value = hasTrack || lk.isConnected.value;
    } catch (e) {
      waitCameraOn.value = false;
      Loggers.error('Match wait camera: $e');
    }
  }

  Future<void> _pauseLiveStudioCamera() async {
    if (!Get.isRegistered<LiveStreamSearchScreenController>()) return;
    try {
      await Get.find<LiveStreamSearchScreenController>().pauseStudioCamera();
    } catch (e) {
      Loggers.error('pauseStudioCamera: $e');
    }
  }

  Future<void> _resumeLiveStudioCamera() async {
    if (StreamerCameraLock.matchWaitVisible) return;
    if (!Get.isRegistered<DashboardScreenController>()) return;
    if (Get.find<DashboardScreenController>().selectedPageIndex.value !=
        DashboardScreenController.tabLive) {
      return;
    }
    if (!Get.isRegistered<LiveStreamSearchScreenController>()) return;
    try {
      await Get.find<LiveStreamSearchScreenController>().resumeStudioCamera();
    } catch (e) {
      Loggers.error('resumeStudioCamera: $e');
    }
  }

  void _listenWaitRoomData(LiveKitRoomController lk) {
    _waitDataSub?.cancel();
    _waitDataSub = lk.onDataReceived.listen((event) {
      try {
        final map = jsonDecode(utf8.decode(event.data));
        if (map is! Map) return;
        final type = '${map['type']}';
        if (type != 'MATCH_READY' && type != 'call_accepted') return;
        unawaited(_pollMatchInbox());
      } catch (_) {}
    });
  }

  Future<void> _disconnectWaitCamera() async {
    waitCameraOn.value = false;
    _waitDataSub?.cancel();
    _waitDataSub = null;
    if (!Get.isRegistered<LiveKitRoomController>(tag: waitLkTag)) return;
    try {
      await Get.find<LiveKitRoomController>(tag: waitLkTag).disconnect();
    } catch (_) {}
    Get.delete<LiveKitRoomController>(tag: waitLkTag, force: true);
  }

  bool _isFreshMatch(CallRequestModel e) {
    final raw = (e.respondedAt ?? e.createdAt ?? '').trim();
    if (raw.isEmpty) return true;
    final t = DateTime.tryParse(raw);
    if (t == null) return true;
    return DateTime.now().toUtc().difference(t.toUtc()).inSeconds.abs() < 75;
  }

  Future<void> _pollMatchInbox() async {
    if (!inMatchPool.value) return;
    if (OutgoingCallController.activeInstance != null) return;
    try {
      final inbox = await CallService.instance.inbox();
      final me = SessionManager.instance.getUserID();
      final all = [...inbox.received, ...inbox.sent];
      for (final e in all) {
        if (!e.isMatchSession || e.id == null) continue;
        if (_joinedCallIds.contains(e.id)) continue;
        if (e.isAccepted &&
            (e.roomId ?? '').trim().isNotEmpty &&
            (e.endedAt ?? '').isEmpty &&
            _isFreshMatch(e)) {
          await _joinReadyMatch(e);
          return;
        }
        if (e.isPending && e.calleeId == me && _isFreshMatch(e)) {
          await LiveIncomingCallOverlay.show(e);
          return;
        }
      }
    } catch (e) {
      Loggers.error('Match inbox poll: $e');
    }
  }

  Future<void> _joinReadyMatch(CallRequestModel call) async {
    final id = call.id;
    if (id == null) return;
    if (_joinedCallIds.contains(id)) return;
    if (Get.isRegistered<VideoCallController>(tag: 'call_$id')) return;
    if (Get.currentRoute.contains('VideoCall')) return;
    _joinedCallIds.add(id);
    LiveIncomingCallOverlay.dismiss(callId: id);
    final outgoing = OutgoingCallController.activeInstance;
    if (outgoing != null) {
      OutgoingCallController.handleRemoteAccepted(
        callRequestId: id,
        roomId: call.roomId,
        call: call,
      );
      return;
    }
    await leavePool();
    Get.to(() => VideoCallScreen(
          call: call,
          isMatchPreview: false,
          matchFreeSeconds:
              call.matchSeconds > 0 ? call.matchSeconds : 40,
        ));
  }

  @override
  void onClose() {
    if (StreamerCameraLock.releaseMatchWait == leavePool) {
      StreamerCameraLock.releaseMatchWait = null;
    }
    StreamerCameraLock.matchWaitVisible = false;
    _tabWorker?.dispose();
    _lifecycle?.dispose();
    _heartbeat?.cancel();
    _inboxPoll?.cancel();
    _waitDataSub?.cancel();
    unawaited(_disconnectWaitCamera());
    unawaited(CallService.instance.leaveMatch());
    pulseController.dispose();
    super.onClose();
  }

  void selectMode(MatchSearchMode value) {
    mode.value = value;
  }

  /// Tras colgar un Match: la streamer vuelve a esperar si el radio sigue activo.
  Future<void> resumeAfterCall() async {
    if (AppRole.isStreamer()) {
      if (streamerMatchEnabled.value && StreamerCameraLock.matchWaitVisible) {
        await joinPool();
      }
      return;
    }
    await _syncPresence();
  }

  Future<void> startMatch() async {
    if (GuestGate.block()) return;
    if (AppRole.isStreamer()) {
      await toggleStreamerMatch();
      return;
    }
    if (isMatching.value) return;
    final meNow = SessionManager.instance.getUser();
    final remaining = meNow?.dailyFreeMatchesRemaining ?? 2;
    final matchMode =
        mode.value == MatchSearchMode.goddess ? 'goddess' : 'random';
    final cost =
        matchMode == 'goddess' ? goddessHintCost : randomHintCost;
    if (remaining <= 0 &&
        cost > 0 &&
        !CoinGate.ensureEnough(
          cost,
          message: LKey.needCoinsToSearchMatch.trParams({'coins': '$cost'}),
        )) {
      return;
    }
    isMatching.value = true;
    try {
      await joinPool();
      final remaining =
          SessionManager.instance.getUser()?.dailyFreeMatchesRemaining ?? 2;
      if (remaining <= 0 &&
          cost > 0 &&
          !CoinGate.ensureEnough(
            cost,
            message: LKey.needCoinsToSearchMatch.trParams({'coins': '$cost'}),
          )) {
        return;
      }
      final unlock = await CallService.instance.unlockMatch(mode: matchMode);
      final me = SessionManager.instance.getUser();
      if (me != null) {
        me.coinWallet = unlock.coinWallet;
        SessionManager.instance.setUser(me);
        refreshCoins();
      }
      if (unlock.charged > 0) {
        showSnackBar(LKey.coinsUsedToViewMatch.trParams({'count': '${unlock.charged}'}));
      }
      final match = await CallService.instance.findMatch(
        mode: matchMode,
      );
      await Get.to(() => MatchPreviewScreen(
            initial: match,
            mode: matchMode,
          ));
      try {
        final fresh = await UserService.instance
            .fetchUserDetails(userId: SessionManager.instance.getUserID());
        if (fresh != null) {
          SessionManager.instance.setUser(fresh);
        }
      } catch (_) {}
      refreshCoins();
      final after = SessionManager.instance.getUser();
      if ((after?.dailyFreeMatchesRemaining ?? 0) <= 0 &&
          (after?.coinWallet ?? 0).toInt() <= 0) {
        CoinGate.openCoinShopSheet(headline: LKey.freeMatchesUsed.tr);
      }
    } catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '');
      if (msg.toLowerCase().contains('insufficient')) {
        CoinGate.ensureEnough(999999, message: LKey.insufficientCoins.tr);
      } else if (msg.toLowerCase().contains('no match')) {
        showSnackBar(mode.value == MatchSearchMode.goddess
            ? LKey.noGoddessInMatch.tr
            : LKey.noStreamersInMatch.tr);
      } else {
        showSnackBar(msg);
      }
      Loggers.error('MatchScreen.startMatch: $e');
    } finally {
      isMatching.value = false;
    }
  }

  void openWallet() {
    Get.to(() => const CoinWalletScreen());
  }

  void openMembership() {
    Get.to(() => const SubscriptionScreen());
  }
}
