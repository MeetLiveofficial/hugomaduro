import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krimson/common/controller/base_controller.dart';
import 'package:krimson/common/extensions/string_extension.dart';
import 'package:krimson/common/manager/livekit_room_controller.dart';
import 'package:krimson/common/manager/session_manager.dart';
import 'package:krimson/common/service/api/call_service.dart';
import 'package:krimson/common/widget/livekit/livekit_video_view.dart';
import 'package:krimson/languages/languages_keys.dart';
import 'package:krimson/model/call/call_request_model.dart';
import 'package:krimson/model/livestream/app_user.dart';
import 'package:krimson/screen/call_screen/match_recharge_dialog.dart';
import 'package:krimson/screen/gift_sheet/send_gift_sheet.dart';
import 'package:krimson/screen/gift_sheet/send_gift_sheet_controller.dart';
import 'package:krimson/screen/live_stream/livestream_screen/livestream_screen_controller.dart';
import 'package:krimson/utilities/color_res.dart';
import 'package:krimson/utilities/const_res.dart';
import 'package:krimson/utilities/text_style_custom.dart';
import 'package:livekit_client/livekit_client.dart';

class VideoCallScreen extends StatelessWidget {
  final CallRequestModel call;
  final bool resumeLiveOnHangup;
  final bool isMatchPreview;
  final int matchFreeSeconds;

  const VideoCallScreen({
    super.key,
    required this.call,
    this.resumeLiveOnHangup = false,
    this.isMatchPreview = false,
    this.matchFreeSeconds = 30,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(
      VideoCallController(
        call,
        resumeLiveOnHangup: resumeLiveOnHangup,
        isMatchPreview: isMatchPreview,
        matchFreeSeconds: matchFreeSeconds,
      ),
      tag: 'call_${call.id}',
    );
    return Scaffold(
      backgroundColor: const Color(0xFF140E18),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Obx(() {
                          final match = controller.matchUi.value;
                          return Text(
                            match ? 'Match' : LKey.videoCall.tr,
                            style: TextStyleCustom.outFitMedium500(
                                color: Colors.white, fontSize: 16),
                          );
                        }),
                        const SizedBox(height: 4),
                        Obx(() {
                          final match = controller.matchUi.value;
                          final left = controller.matchSecondsLeft.value;
                          final label = match
                              ? controller.matchCountdownLabel.value
                              : controller.elapsedLabel.value;
                          return Text(
                            label,
                            style: TextStyleCustom.outFitRegular400(
                              color: match && left <= 5
                                  ? ColorRes.themeAccentSolid
                                  : Colors.white70,
                              fontSize: match ? 18 : 13,
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                  Obx(() {
                    final msg = controller.status.value.trim();
                    if (msg.isEmpty) return const SizedBox.shrink();
                    return Flexible(
                      child: Text(
                        msg,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.end,
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 11,
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
            Obx(() {
              if (!controller.matchUi.value) return const SizedBox.shrink();
              if (controller.awaitingExtension.value) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Text(
                    controller.isMatchCaller
                        ? 'Elige más tiempo para continuar'
                        : 'El cliente puede continuar el Match…',
                    textAlign: TextAlign.center,
                    style: TextStyleCustom.outFitMedium500(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                );
              }
              final left = controller.matchSecondsLeft.value;
              if (left > 10) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Text(
                  left <= 0
                      ? 'Tiempo agotado'
                      : 'Match termina en $left s',
                  textAlign: TextAlign.center,
                  style: TextStyleCustom.outFitMedium500(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
              );
            }),
            Expanded(
              child: ClipRect(
                child: Obx(() {
                  controller.liveKit.mediaRevision.value;
                  return LiveKitCallLayout(
                    local: controller.liveKit.localParticipant.value,
                    remotes: controller.liveKit.remoteParticipants.toList(),
                    statusText: controller.status.value,
                  );
                }),
              ),
            ),
            Container(
              width: double.infinity,
              color: const Color(0xFF1C1424),
              padding: const EdgeInsets.fromLTRB(12, 14, 12, 16),
              child: Obx(() {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _RoundBtn(
                      icon: controller.liveKit.microphoneEnabled.value
                          ? Icons.mic
                          : Icons.mic_off,
                      color: const Color(0xFF3A3144),
                      onTap: controller.toggleMic,
                    ),
                    _RoundBtn(
                      icon: Icons.call_end,
                      color: Colors.red,
                      onTap: controller.hangUp,
                    ),
                    _RoundBtn(
                      icon: controller.liveKit.cameraEnabled.value
                          ? Icons.videocam
                          : Icons.videocam_off,
                      color: const Color(0xFF3A3144),
                      onTap: controller.toggleCamera,
                    ),
                    _RoundBtn(
                      icon: Icons.card_giftcard_rounded,
                      color: ColorRes.themeAccentSolid.withValues(alpha: 0.9),
                      onTap: controller.openGiftSheet,
                    ),
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

class _RoundBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _RoundBtn(
      {required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: CircleAvatar(
        radius: 28,
        backgroundColor: color,
        child: Icon(icon, color: Colors.white, size: 28),
      ),
    );
  }
}

class VideoCallController extends BaseController {
  VideoCallController(
    this.call, {
    this.resumeLiveOnHangup = false,
    this.isMatchPreview = false,
    this.matchFreeSeconds = 30,
  });

  final CallRequestModel call;
  final bool resumeLiveOnHangup;
  final bool isMatchPreview;
  final int matchFreeSeconds;
  final RxString status = 'Connecting...'.obs;
  final RxString elapsedLabel = '00:00'.obs;
  final RxString matchCountdownLabel = '00:00'.obs;
  final RxInt matchSecondsLeft = 30.obs;
  final RxBool matchUi = false.obs;
  final RxBool awaitingExtension = false.obs;

  late final LiveKitRoomController liveKit;
  Timer? _elapsedTimer;
  StreamSubscription? _dataSub;
  /// Ancla compartida: SOLO `responded_at` del servidor.
  DateTime? _syncAnchor;
  int? _matchDurationOverride;
  bool _forceMatch = false;
  String? _respondedAtRaw;
  bool _timerStarted = false;
  bool _ending = false;
  bool _cleaned = false;
  bool _extensionPromptOpen = false;

  String get roomId => call.roomId ?? 'call_${call.id}';
  String get _tag => 'lk_call_${call.id}';

  /// Match para caller y callee (mismo modo de UI / cronómetro).
  bool get isMatchCall {
    if (isMatchPreview || _forceMatch || call.isMatchSession) return true;
    return false;
  }

  bool get isMatchCaller {
    if (!isMatchCall) return false;
    return call.callerId == SessionManager.instance.getUserID();
  }

  bool get isMatchClient => isMatchCaller;

  int get _matchDuration {
    if (_matchDurationOverride != null && _matchDurationOverride! > 0) {
      return _matchDurationOverride!;
    }
    final fromRoom = CallRequestModel.matchSecondsFromRoomId(call.roomId);
    if (fromRoom != null && fromRoom > 0) return fromRoom;
    if (call.matchSeconds > 0) return call.matchSeconds;
    final fromSettings =
        SessionManager.instance.getSettings()?.matchFreeSeconds ?? 0;
    if (isMatchCall && matchFreeSeconds > 0) return matchFreeSeconds;
    if (isMatchCall && fromSettings > 0) return fromSettings;
    if (matchFreeSeconds > 0 && isMatchPreview) return matchFreeSeconds;
    return 30;
  }

  @override
  void onInit() {
    super.onInit();
    matchSecondsLeft.value = _matchDuration;
    matchCountdownLabel.value = _formatMmSs(_matchDuration);
    matchUi.value = isMatchCall;
    liveKit = Get.put(LiveKitRoomController(), tag: _tag);
  }

  @override
  void onReady() {
    super.onReady();
    _start();
  }

  @override
  void onClose() {
    _elapsedTimer?.cancel();
    _elapsedTimer = null;
    unawaited(_dataSub?.cancel());
    _dataSub = null;
    if (!_cleaned) {
      unawaited(_cleanup(notifyApi: false));
    }
    super.onClose();
  }

  DateTime? _parseRespondedAt() {
    final raw = (_respondedAtRaw ?? call.respondedAt ?? '').trim();
    if (raw.isEmpty) return null;
    try {
      return DateTime.parse(raw).toLocal();
    } catch (_) {
      return null;
    }
  }

  String _formatMmSs(int totalSeconds) {
    final s = totalSeconds < 0 ? 0 : totalSeconds;
    final mm = (s ~/ 60).toString().padLeft(2, '0');
    final ss = (s % 60).toString().padLeft(2, '0');
    return '$mm:$ss';
  }

  /// Cronómetro SOLO con `responded_at` (misma ancla en ambos lados).
  void _startSyncedTimer() {
    if (_ending) return;
    _syncAnchor ??= _parseRespondedAt();
    if (_syncAnchor == null) return;

    final now = DateTime.now();
    if (_syncAnchor!.isAfter(now.add(const Duration(seconds: 2)))) {
      _syncAnchor = now;
    }

    if (_timerStarted) {
      _tickSynced();
      return;
    }
    _timerStarted = true;
    _elapsedTimer?.cancel();
    _tickSynced();
    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _tickSynced();
    });
  }

  void _tickSynced() {
    if (_ending) return;
    final anchor = _syncAnchor;
    if (anchor == null) return;
    final elapsed = DateTime.now().difference(anchor).inSeconds;
    final safeElapsed = elapsed < 0 ? 0 : elapsed;

    if (isMatchCall) {
      final duration = _matchDuration;
      final left = duration - safeElapsed;
      final safeLeft = left < 0 ? 0 : left;
      matchSecondsLeft.value = safeLeft;
      matchCountdownLabel.value = _formatMmSs(safeLeft);
      // Mismo string en ambos lados (cuenta atrás).
      elapsedLabel.value = matchCountdownLabel.value;
      if (safeLeft <= 0 && !awaitingExtension.value) {
        unawaited(_onMatchTimeUp());
      }
    } else {
      elapsedLabel.value = _formatMmSs(safeElapsed);
    }
  }

  Future<void> _onMatchTimeUp() async {
    if (_ending || awaitingExtension.value) return;
    awaitingExtension.value = true;
    matchSecondsLeft.value = 0;
    matchCountdownLabel.value = _formatMmSs(0);
    elapsedLabel.value = matchCountdownLabel.value;

    if (isMatchCaller) {
      await _promptClientExtension();
    } else {
      await _waitForPeerExtension();
    }
  }

  Future<void> _promptClientExtension() async {
    if (_extensionPromptOpen || _ending) return;
    _extensionPromptOpen = true;
    final peer = call.caller?.id == SessionManager.instance.getUserID()
        ? call.callee
        : call.caller;
    try {
      final paid = await MatchRechargeDialog.show(
        peer: peer,
        callCost: call.coinsCost,
        onExtend: _payAndExtend,
      );
      if (_ending) return;
      if (paid) return;
      await hangUp();
    } finally {
      _extensionPromptOpen = false;
    }
  }

  Future<bool> _payAndExtend(int minutes, int coins) async {
    final id = call.id;
    if (id == null) return false;
    try {
      final extra = minutes * 60;
      final updated = await CallService.instance.extendMatch(
        callRequestId: id,
        extraSeconds: extra,
        coinsCost: coins,
      );
      final me = SessionManager.instance.getUser();
      if (me != null && coins > 0) {
        me.removeCoinFromWallet(coins);
        SessionManager.instance.setUser(me);
      }
      var total = updated.matchSeconds;
      if (total <= _matchDuration) {
        total = _matchDuration + extra;
      }
      _applyMatchExtension(total);
      try {
        await liveKit.publishData(
          utf8.encode(jsonEncode({
            'type': 'match_extend',
            'match_seconds': updated.matchSeconds,
          })),
          topic: 'match_extend',
        );
      } catch (_) {}
      return true;
    } catch (e) {
      showSnackBar(e.toString().replaceFirst('Exception: ', ''));
      return false;
    }
  }

  Future<void> _waitForPeerExtension() async {
    // El cliente puede tardar en elegir oferta; no cortar la room.
    for (var i = 0; i < 45 && !_ending && awaitingExtension.value; i++) {
      await Future<void>.delayed(const Duration(seconds: 2));
      if (_ending || !awaitingExtension.value) return;
      try {
        final id = call.id;
        if (id == null) continue;
        final fresh = await CallService.instance.status(id);
        final st = (fresh.status ?? '').toLowerCase();
        if (st == 'ended' || st == 'cancelled' || st == 'expired') {
          await hangUp();
          return;
        }
        if (fresh.matchSeconds > _matchDuration) {
          _applyMatchExtension(fresh.matchSeconds);
          return;
        }
      } catch (_) {}
    }
    if (!_ending && awaitingExtension.value) {
      await hangUp();
    }
  }

  void _applyMatchExtension(int totalSeconds) {
    if (totalSeconds <= 0) return;
    _matchDurationOverride = totalSeconds;
    awaitingExtension.value = false;
    _extensionPromptOpen = false;
    _timerStarted = true;
    _tickSynced();
    _elapsedTimer?.cancel();
    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _tickSynced();
    });
  }

  void _onMatchData(List<int> bytes) {
    try {
      final map = jsonDecode(utf8.decode(bytes));
      if (map is! Map) return;
      if ('${map['type']}' != 'match_extend') return;
      final total = map['match_seconds'] is num
          ? (map['match_seconds'] as num).toInt()
          : int.tryParse('${map['match_seconds'] ?? 0}') ?? 0;
      if (total > _matchDuration) {
        _applyMatchExtension(total);
      }
    } catch (_) {}
  }

  Future<void> _hydrateCallMeta() async {
    final id = call.id;
    if (id == null) return;
    try {
      final fresh = await CallService.instance.status(id);
      if ((fresh.respondedAt ?? '').trim().isNotEmpty) {
        _respondedAtRaw = fresh.respondedAt;
        _syncAnchor ??= () {
          try {
            return DateTime.parse(fresh.respondedAt!).toLocal();
          } catch (_) {
            return null;
          }
        }();
      }
      final roomMs = CallRequestModel.matchSecondsFromRoomId(fresh.roomId);
      if (fresh.isMatch || fresh.matchSeconds > 0 || (roomMs ?? 0) > 0) {
        _forceMatch = true;
        matchUi.value = true;
        final next = fresh.matchSeconds > 0
            ? fresh.matchSeconds
            : (roomMs ?? _matchDuration);
        if (next > _matchDuration) {
          _matchDurationOverride = next;
        } else {
          _matchDurationOverride ??= next;
        }
      }
    } catch (_) {}
  }

  /// Espera `responded_at` del server antes de arrancar el reloj.
  Future<void> _resolveAnchorAndStart() async {
    _respondedAtRaw ??= call.respondedAt;
    _syncAnchor ??= _parseRespondedAt();
    if (isMatchPreview || call.isMatch || call.matchSeconds > 0) {
      _forceMatch = true;
      matchUi.value = true;
    }
    final roomMs = CallRequestModel.matchSecondsFromRoomId(call.roomId);
    if ((roomMs ?? 0) > 0) {
      _forceMatch = true;
      matchUi.value = true;
      _matchDurationOverride ??= roomMs;
    }

    if (_syncAnchor == null) {
      await _hydrateCallMeta();
    }
    for (var i = 0; i < 4 && _syncAnchor == null; i++) {
      await Future.delayed(const Duration(milliseconds: 200));
      await _hydrateCallMeta();
      _syncAnchor ??= _parseRespondedAt();
    }

    // Último recurso: ambos ya aceptaron; si falta timestamp, no inventar
    // clocks distintos — reintentar un status final.
    if (_syncAnchor == null) {
      await _hydrateCallMeta();
      _syncAnchor ??= _parseRespondedAt();
    }
    if (_syncAnchor == null) {
      // Sin ancla de servidor no se puede sincronizar; diferir arranque.
      status.value = status.value.isEmpty ? 'Syncing clock…' : status.value;
      return;
    }
    _startSyncedTimer();
  }

  Future<void> _start() async {
    final me = SessionManager.instance.getUser();
    if (me?.id == null || call.roomId == null || call.roomId!.isEmpty) {
      status.value = 'Invalid call room';
      return;
    }

    // Reloj anclado a responded_at (misma ancla en ambos lados).
    await _resolveAnchorAndStart();

    try {
      ever(liveKit.statusMessage, (msg) {
        status.value = msg;
      });
      ever(liveKit.remoteParticipants, (_) {
        if (liveKit.remoteParticipants.isNotEmpty) {
          status.value = '';
          unawaited(_resolveAnchorAndStart());
        } else if (liveKit.isConnected.value) {
          status.value = 'Waiting for peer...';
        }
      });

      await liveKit.connect(
        roomName: roomId,
        identity: '${me!.id}',
        name: me.fullname ?? me.username ?? 'user',
        // Web: el HtmlElementView de la cámara tapa toda la UI.
        publishCamera: !kIsWeb,
        publishMicrophone: true,
        wsUrl: liveKitWsUrl,
      );
      _dataSub?.cancel();
      _dataSub = liveKit.onDataReceived.listen((event) {
        _onMatchData(event.data);
      });
      status.value = 'Waiting for peer...';
      await _resolveAnchorAndStart();
    } catch (e) {
      status.value = e.toString();
      showSnackBar(e.toString());
    }
  }

  Future<void> toggleMic() => liveKit.toggleMicrophone();

  Future<void> toggleCamera() => liveKit.toggleCamera();

  Future<void> openGiftSheet() async {
    final peer = call.caller?.id == SessionManager.instance.getUserID()
        ? call.callee
        : call.caller;
    final peerId = peer?.id;
    if (peerId == null) {
      showSnackBar('Peer not found');
      return;
    }
    final streamUser = AppUser(
      userId: peerId,
      fullname: peer?.fullname,
      username: peer?.username,
      profile: peer?.profilePhoto?.addBaseURL(),
    );
    await GiftManager.openGiftSheet(
      userId: peerId,
      giftType: GiftType.none,
      streamUsers: [streamUser],
      onCompletion: (gm) {
        GiftManager.showAnimationDialog(gm.gift);
      },
    );
  }

  Future<void> hangUp({bool showMatchRecharge = false}) async {
    if (_ending) return;
    _ending = true;
    awaitingExtension.value = false;
    _elapsedTimer?.cancel();
    _elapsedTimer = null;

    final peer = call.caller?.id == SessionManager.instance.getUserID()
        ? call.callee
        : call.caller;
    final cost = call.coinsCost;
    final shouldResume = resumeLiveOnHangup;
    final shouldRecharge = showMatchRecharge && isMatchCaller;
    final ctrlTag = 'call_${call.id}';
    final lkTag = _tag;

    // Cerrar la UI YA (no esperar a LiveKit/API: ahí se quedaba colgado Match).
    _popCallUi();

    unawaited(() async {
      try {
        await _cleanup(notifyApi: true, liveKitTag: lkTag)
            .timeout(const Duration(seconds: 4));
      } catch (_) {}
      if (shouldResume) {
        try {
          await LivestreamScreenController.activeInstance
              ?.resumeLiveKitAfterCall();
        } catch (_) {}
      }
      try {
        if (Get.isRegistered<VideoCallController>(tag: ctrlTag)) {
          Get.delete<VideoCallController>(tag: ctrlTag, force: true);
        }
      } catch (_) {}
      if (shouldRecharge) {
        Future.microtask(() {
          MatchRechargeDialog.show(peer: peer, callCost: cost);
        });
      }
    }());
  }

  void _popCallUi() {
    try {
      if (Get.isDialogOpen == true) Get.back();
    } catch (_) {}
    try {
      if (Get.key.currentState?.canPop() == true) {
        Get.back();
        return;
      }
    } catch (_) {}
    final ctx = Get.context;
    if (ctx != null) {
      try {
        final nav = Navigator.of(ctx, rootNavigator: true);
        if (nav.canPop()) nav.pop();
      } catch (_) {}
    }
  }

  Future<void> _cleanup({
    required bool notifyApi,
    String? liveKitTag,
  }) async {
    if (_cleaned) return;
    _cleaned = true;
    _elapsedTimer?.cancel();
    _elapsedTimer = null;
    final tag = liveKitTag ?? _tag;
    try {
      await liveKit.disconnect(silent: true).timeout(
            const Duration(seconds: 3),
          );
    } catch (_) {}
    try {
      if (Get.isRegistered<LiveKitRoomController>(tag: tag)) {
        Get.delete<LiveKitRoomController>(tag: tag, force: true);
      }
    } catch (_) {}
    if (notifyApi && call.id != null) {
      try {
        await CallService.instance.end(call.id!).timeout(
              const Duration(seconds: 3),
            );
      } catch (_) {}
    }
  }
}
