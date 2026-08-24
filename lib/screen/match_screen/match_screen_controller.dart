import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krimson/common/controller/base_controller.dart';
import 'package:krimson/common/manager/app_role.dart';
import 'package:krimson/common/manager/coin_gate.dart';
import 'package:krimson/common/manager/livekit_room_controller.dart';
import 'package:krimson/common/manager/logger.dart';
import 'package:krimson/common/manager/session_manager.dart';
import 'package:krimson/common/service/api/call_service.dart';
import 'package:krimson/common/service/api/user_service.dart';
import 'package:krimson/languages/languages_keys.dart';
import 'package:krimson/model/call/call_request_model.dart';
import 'package:krimson/screen/call_screen/live_incoming_call_overlay.dart';
import 'package:krimson/screen/call_screen/outgoing_call_screen.dart';
import 'package:krimson/screen/call_screen/video_call_screen.dart';
import 'package:krimson/screen/coin_wallet_screen/coin_wallet_screen.dart';
import 'package:krimson/screen/dashboard_screen/dashboard_screen_controller.dart';
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
  final RxBool waitCameraOn = false.obs;
  final RxInt coins = 0.obs;
  final RxInt freeMatchesUsed = 0.obs;
  final RxInt freeMatchesQuota = 2.obs;

  late final AnimationController pulseController;
  Worker? _tabWorker;
  AppLifecycleListener? _lifecycle;
  Timer? _heartbeat;
  Timer? _inboxPoll;
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

  /// Hint de costo Random (mínimo de niveles activos).
  int get randomHintCost {
    final levels = SessionManager.instance.getSettings()?.userLevels ?? [];
    final prices = levels
        .map((e) => e.callRequestCoins)
        .where((c) => c > 0)
        .toList();
    if (prices.isEmpty) return 9;
    prices.sort();
    return prices.first;
  }

  /// Hint Goddess: streamers grado A/S (más alto).
  int get goddessHintCost {
    final base = randomHintCost;
    return base < 30 ? 30 : (base * 3).clamp(30, 9999);
  }

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
    return route.contains('VideoCall') || route.contains('MatchPreview');
  }

  Future<void> _syncPresence() async {
    if (Get.currentRoute.contains('VideoCall')) {
      await leavePool();
      return;
    }
    if (Get.currentRoute.contains('MatchPreview')) {
      return;
    }
    if (_matchUiVisible) {
      await joinPool();
    } else {
      await leavePool();
    }
  }

  Future<void> joinPool() async {
    if (_joining) return;
    if (Get.currentRoute.contains('VideoCall')) return;
    if (inMatchPool.value) {
      if (AppRole.isStreamer() && !waitCameraOn.value) {
        _joining = true;
        try {
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
      final waitRoom = await CallService.instance.joinMatch();
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
      if (AppRole.isStreamer()) {
        await _connectWaitCamera(waitRoom);
      }
    } catch (e) {
      Loggers.error('Match joinPool: $e');
    } finally {
      _joining = false;
    }
  }

  Future<void> leavePool() async {
    _heartbeat?.cancel();
    _heartbeat = null;
    _inboxPoll?.cancel();
    _inboxPoll = null;
    await _disconnectWaitCamera();
    if (!inMatchPool.value) return;
    inMatchPool.value = false;
    await CallService.instance.leaveMatch();
  }

  Future<void> _connectWaitCamera(String? waitRoom) async {
    final me = SessionManager.instance.getUser();
    final id = me?.id;
    if (id == null) return;
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
        publishCamera: !kIsWeb,
        publishMicrophone: false,
        wsUrl: liveKitWsUrl,
      );
      waitCameraOn.value = true;
    } catch (e) {
      waitCameraOn.value = false;
      Loggers.error('Match wait camera: $e');
    }
  }

  Future<void> _disconnectWaitCamera() async {
    waitCameraOn.value = false;
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
          isMatchPreview: true,
          matchFreeSeconds:
              call.matchSeconds > 0 ? call.matchSeconds : 30,
        ));
  }

  @override
  void onClose() {
    _tabWorker?.dispose();
    _lifecycle?.dispose();
    _heartbeat?.cancel();
    _inboxPoll?.cancel();
    unawaited(_disconnectWaitCamera());
    unawaited(CallService.instance.leaveMatch());
    pulseController.dispose();
    super.onClose();
  }

  void selectMode(MatchSearchMode value) {
    mode.value = value;
  }

  Future<void> startMatch() async {
    if (AppRole.isStreamer()) {
      await joinPool();
      showSnackBar('Cámara lista. Esperando un cliente…');
      return;
    }
    if (isMatching.value) return;
    final meNow = SessionManager.instance.getUser();
    final remaining = meNow?.dailyFreeMatchesRemaining ?? 2;
    final wallet = (meNow?.coinWallet ?? 0).toInt();
    if (remaining <= 0 && wallet <= 0) {
      CoinGate.openCoinShopSheet(headline: LKey.freeMatchesUsed.tr);
      return;
    }
    isMatching.value = true;
    try {
      await joinPool();
      final remaining =
          SessionManager.instance.getUser()?.dailyFreeMatchesRemaining ?? 2;
      final cost =
          SessionManager.instance.getSettings()?.matchInitialCoins ?? 0;
      if (remaining <= 0 &&
          cost > 0 &&
          !CoinGate.ensureEnough(
            cost,
            message: 'Necesitas $cost coins para ver streamers en Match',
          )) {
        return;
      }
      final unlock = await CallService.instance.unlockMatch();
      final me = SessionManager.instance.getUser();
      if (me != null) {
        me.coinWallet = unlock.coinWallet;
        SessionManager.instance.setUser(me);
        refreshCoins();
      }
      if (unlock.charged > 0) {
        showSnackBar('Se usaron ${unlock.charged} coins para ver Match');
      }
      final lang = (me?.appLanguage ?? '').trim().toLowerCase();
      final matchMode =
          mode.value == MatchSearchMode.goddess ? 'goddess' : 'random';
      final match = await CallService.instance.findMatch(
        appLanguage: lang.isEmpty ? null : lang,
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
        CoinGate.ensureEnough(999999, message: 'Monedas insuficientes');
      } else if (msg.toLowerCase().contains('no match')) {
        showSnackBar(mode.value == MatchSearchMode.goddess
            ? 'No hay Goddess en Match ahora. Prueba Random.'
            : 'No hay streamers en Match ahora');
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
