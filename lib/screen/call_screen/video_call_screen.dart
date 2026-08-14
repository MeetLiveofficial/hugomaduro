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
import 'package:krimson/model/general/settings_model.dart';
import 'package:krimson/model/livestream/app_user.dart';
import 'package:krimson/screen/call_screen/live_incoming_call_overlay.dart';
import 'package:krimson/screen/call_screen/match_recharge_dialog.dart';
import 'package:krimson/screen/gift_sheet/send_gift_sheet.dart';
import 'package:krimson/screen/gift_sheet/send_gift_sheet_controller.dart';
import 'package:krimson/screen/live_stream/livestream_screen/livestream_screen_controller.dart';
import 'package:krimson/utilities/color_res.dart';
import 'package:krimson/utilities/const_res.dart';
import 'package:krimson/utilities/text_style_custom.dart';

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
                    if (controller.matchUi.value) {
                      return const SizedBox.shrink();
                    }
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
                  controller.awaitingExtension.value;
                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      LiveKitCallLayout(
                        local: controller.liveKit.localParticipant.value,
                        remotes:
                            controller.liveKit.remoteParticipants.toList(),
                        statusText: controller.status.value,
                      ),
                      if (controller.awaitingExtension.value)
                        ColoredBox(
                          color: Colors.black.withValues(alpha: 0.72),
                          child: Center(
                            child: Text(
                              controller.isMatchCaller
                                  ? 'Video pausado\nElige más tiempo'
                                  : 'Video pausado\nEsperando al cliente…',
                              textAlign: TextAlign.center,
                              style: TextStyleCustom.outFitMedium500(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                }),
              ),
            ),
            Container(
              width: double.infinity,
              color: const Color(0xFF1C1424),
              padding: const EdgeInsets.fromLTRB(12, 14, 12, 16),
              child: Obx(() {
                controller.matchUi.value;
                final hideHangup =
                    controller.matchUi.value && !controller.isMatchCaller;
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
                    if (hideHangup)
                      const SizedBox(width: 56, height: 56)
                    else
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
  final RxString status = 'Conectando...'.obs;
  final RxString elapsedLabel = '00:00'.obs;
  final RxString matchCountdownLabel = '00:00'.obs;
  final RxInt matchSecondsLeft = 30.obs;
  final RxBool matchUi = false.obs;
  final RxBool awaitingExtension = false.obs;

  late final LiveKitRoomController liveKit;
  Timer? _elapsedTimer;
  Timer? _statusPoll;
  Timer? _peerGoneTimer;
  StreamSubscription? _dataSub;
  /// Ancla compartida: `phase_ends_at` del servidor (fallback `responded_at`).
  DateTime? _syncAnchor;
  DateTime? _phaseEndsAt;
  DateTime? _graceEndsAt;
  int? _matchDurationOverride;
  bool _forceMatch = false;
  String? _respondedAtRaw;
  bool _timerStarted = false;
  bool _ending = false;
  bool _cleaned = false;
  bool _extensionPromptOpen = false;
  bool _hadRemote = false;
  DateTime? _callConnectedAt;

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

  /// El otro lado colgó (FCM `call_ended`).
  static void handleRemoteEnded(int? callRequestId) {
    if (callRequestId == null) return;
    final tag = 'call_$callRequestId';
    if (!Get.isRegistered<VideoCallController>(tag: tag)) return;
    final c = Get.find<VideoCallController>(tag: tag);
    unawaited(c.hangUp(forcedByPeer: true));
  }

  /// Servidor abrió la ventana de gracia (FCM `match_extension_modal`).
  static void handleExtensionModal(int? callRequestId) {
    if (callRequestId == null) return;
    final tag = 'call_$callRequestId';
    if (!Get.isRegistered<VideoCallController>(tag: tag)) return;
    final c = Get.find<VideoCallController>(tag: tag);
    unawaited(c.openExtensionFromServer());
  }

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
    _startStatusPoll();
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
    _statusPoll?.cancel();
    _statusPoll = null;
    _peerGoneTimer?.cancel();
    _peerGoneTimer = null;
    unawaited(_dataSub?.cancel());
    _dataSub = null;
    // hangUp ya limpia; no lanzar un disconnect paralelo que pisa al LIVE.
    if (!_cleaned && !_ending) {
      unawaited(_cleanup(notifyApi: false));
    }
    super.onClose();
  }

  DateTime? _parseIso(String? raw) {
    final v = (raw ?? '').trim();
    if (v.isEmpty) return null;
    try {
      return DateTime.parse(v).toLocal();
    } catch (_) {
      return null;
    }
  }

  DateTime? _parseRespondedAt() {
    return _parseIso(_respondedAtRaw ?? call.respondedAt);
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
    final now = DateTime.now();

    if (isMatchCall && awaitingExtension.value) {
      final graceEnd = _graceEndsAt;
      if (graceEnd != null) {
        final left = graceEnd.difference(now).inSeconds;
        final safeLeft = left < 0 ? 0 : left;
        matchSecondsLeft.value = safeLeft;
        matchCountdownLabel.value = _formatMmSs(safeLeft);
        elapsedLabel.value = matchCountdownLabel.value;
      }
      return;
    }

    if (isMatchCall) {
      int safeLeft;
      final phaseEnd = _phaseEndsAt;
      if (phaseEnd != null) {
        final left = phaseEnd.difference(now).inSeconds;
        safeLeft = left < 0 ? 0 : left;
      } else {
        final anchor = _syncAnchor;
        if (anchor == null) return;
        final elapsed = now.difference(anchor).inSeconds;
        final safeElapsed = elapsed < 0 ? 0 : elapsed;
        final left = _matchDuration - safeElapsed;
        safeLeft = left < 0 ? 0 : left;
      }
      matchSecondsLeft.value = safeLeft;
      matchCountdownLabel.value = _formatMmSs(safeLeft);
      elapsedLabel.value = matchCountdownLabel.value;
      if (safeLeft <= 0 && !awaitingExtension.value) {
        unawaited(_onMatchTimeUp());
      }
    } else {
      final anchor = _syncAnchor;
      if (anchor == null) return;
      final elapsed = now.difference(anchor).inSeconds;
      elapsedLabel.value = _formatMmSs(elapsed < 0 ? 0 : elapsed);
    }
  }

  Future<void> _setMatchPaused(bool paused) async {
    try {
      await liveKit.setStreamPaused(paused: paused, asHost: true);
    } catch (_) {}
  }

  Future<void> openExtensionFromServer() => _onMatchTimeUp();

  Future<void> _onMatchTimeUp() async {
    if (_ending || awaitingExtension.value) return;
    awaitingExtension.value = true;
    matchSecondsLeft.value = 0;
    matchCountdownLabel.value = _formatMmSs(0);
    elapsedLabel.value = matchCountdownLabel.value;
    _graceEndsAt ??= DateTime.now().add(Duration(
      seconds: SessionManager.instance.getSettings()?.matchGraceSeconds ?? 40,
    ));
    await _setMatchPaused(true);

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
    final settings = SessionManager.instance.getSettings();
    try {
      final paid = await MatchRechargeDialog.show(
        peer: peer,
        callCost: call.coinsCost,
        tiers: settings?.matchTiers,
        graceSeconds: settings?.matchGraceSeconds ?? 40,
        graceEndsAt: _graceEndsAt,
        onExtend: _payAndExtend,
      );
      if (_ending) return;
      if (paid) return;
      await hangUp();
    } finally {
      _extensionPromptOpen = false;
    }
  }

  Future<bool> _payAndExtend(MatchTier tier) async {
    final id = call.id;
    if (id == null) return false;
    try {
      final updated = await CallService.instance.extendMatch(
        callRequestId: id,
        tier: tier.tier,
        extraSeconds: tier.seconds,
        coinsCost: tier.coins,
      );
      final me = SessionManager.instance.getUser();
      if (me != null && tier.coins > 0) {
        me.removeCoinFromWallet(tier.coins);
        SessionManager.instance.setUser(me);
      }
      _applyServerExtension(updated);
      try {
        await liveKit.publishData(
          utf8.encode(jsonEncode({
            'type': 'MATCH_EXTENDED',
            'match_seconds': updated.matchSeconds,
            'phase_ends_at': updated.phaseEndsAt,
          })),
          topic: 'match',
        );
      } catch (_) {}
      return true;
    } catch (e) {
      showSnackBar(e.toString().replaceFirst('Exception: ', ''));
      return false;
    }
  }

  Future<void> _waitForPeerExtension() async {
    for (var i = 0; i < 50 && !_ending && awaitingExtension.value; i++) {
      await Future<void>.delayed(const Duration(seconds: 1));
      if (_ending || !awaitingExtension.value) return;
      try {
        final id = call.id;
        if (id == null) continue;
        final fresh = await CallService.instance.status(id);
        if (fresh.isEnded) {
          await hangUp(forcedByPeer: true);
          return;
        }
        if (!fresh.isExtensionWindow && fresh.matchSeconds > 0) {
          _applyServerExtension(fresh);
          return;
        }
      } catch (_) {}
    }
    if (!_ending && awaitingExtension.value) {
      await hangUp(forcedByPeer: true);
    }
  }

  void _applyServerExtension(CallRequestModel updated) {
    if (updated.matchSeconds > 0) {
      _matchDurationOverride = updated.matchSeconds;
    }
    _phaseEndsAt = _parseIso(updated.phaseEndsAt);
    _graceEndsAt = null;
    awaitingExtension.value = false;
    _extensionPromptOpen = false;
    unawaited(_setMatchPaused(false));
    _timerStarted = true;
    _tickSynced();
    _elapsedTimer?.cancel();
    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _tickSynced();
    });
  }

  void _applyMatchExtension(int totalSeconds) {
    if (totalSeconds <= 0) return;
    _matchDurationOverride = totalSeconds;
    _phaseEndsAt = DateTime.now().add(Duration(
      seconds: totalSeconds > 0
          ? (totalSeconds - DateTime.now().difference(_syncAnchor ?? DateTime.now()).inSeconds)
              .clamp(1, totalSeconds)
          : 30,
    ));
    _graceEndsAt = null;
    awaitingExtension.value = false;
    _extensionPromptOpen = false;
    unawaited(_setMatchPaused(false));
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
      final type = '${map['type']}';
      if (type == 'SHOW_EXTENSION_MODAL' || type == 'match_extension_modal') {
        final graceAt = _parseIso(map['grace_ends_at']?.toString());
        if (graceAt != null) _graceEndsAt = graceAt;
        unawaited(_onMatchTimeUp());
        return;
      }
      if (type == 'KICK_OUT') {
        unawaited(hangUp(forcedByPeer: true));
        return;
      }
      if (type != 'MATCH_EXTENDED' && type != 'match_extend') return;
      final total = map['match_seconds'] is num
          ? (map['match_seconds'] as num).toInt()
          : int.tryParse('${map['match_seconds'] ?? 0}') ?? 0;
      final phaseEnd = _parseIso(map['phase_ends_at']?.toString());
      if (phaseEnd != null) {
        _phaseEndsAt = phaseEnd;
      }
      if (total > 0) {
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
        _syncAnchor ??= _parseIso(fresh.respondedAt);
      }
      _phaseEndsAt ??= _parseIso(fresh.phaseEndsAt);
      if (fresh.isExtensionWindow) {
        _graceEndsAt = _parseIso(fresh.graceEndsAt) ?? _graceEndsAt;
        unawaited(_onMatchTimeUp());
      }
      if (fresh.isEnded) {
        unawaited(hangUp(forcedByPeer: true));
        return;
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
    _phaseEndsAt ??= _parseIso(call.phaseEndsAt);
    _graceEndsAt ??= _parseIso(call.graceEndsAt);
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
      status.value = status.value.isEmpty ? 'Sincronizando reloj...' : status.value;
      return;
    }
    _startSyncedTimer();
  }

  Future<void> _start() async {
    final me = SessionManager.instance.getUser();
    if (me?.id == null || call.roomId == null || call.roomId!.isEmpty) {
      status.value = 'Sala de llamada inválida';
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
          _hadRemote = true;
          _peerGoneTimer?.cancel();
          _peerGoneTimer = null;
          status.value = '';
          unawaited(_resolveAnchorAndStart());
        } else if (liveKit.isConnected.value && _hadRemote) {
          status.value = 'El otro usuario se desconectó...';
          _peerGoneTimer?.cancel();
          final connectedFor = _callConnectedAt == null
              ? Duration.zero
              : DateTime.now().difference(_callConnectedAt!);
          if (connectedFor < const Duration(seconds: 8)) {
            return;
          }
          // ICE/LiveKit parpadea al salir del LIVE; no colgar a los 3s.
          _peerGoneTimer = Timer(const Duration(seconds: 12), () {
            if (_ending) return;
            if (liveKit.remoteParticipants.isNotEmpty) return;
            unawaited(hangUp(forcedByPeer: true));
          });
        } else if (liveKit.isConnected.value) {
          status.value = 'Esperando al otro usuario...';
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
      _callConnectedAt = DateTime.now();
      _dataSub?.cancel();
      _dataSub = liveKit.onDataReceived.listen((event) {
        _onMatchData(event.data);
      });
      status.value = 'Esperando al otro usuario...';
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

  void _startStatusPoll() {
    _statusPoll?.cancel();
    _statusPoll = Timer.periodic(const Duration(seconds: 3), (_) {
      unawaited(_pollCallStatus());
    });
  }

  Future<void> _pollCallStatus() async {
    if (_ending) return;
    final id = call.id;
    if (id == null) return;
    try {
      final fresh = await CallService.instance.status(id);
      if (_ending) return;
      if (fresh.isEnded) {
        await hangUp(forcedByPeer: true);
        return;
      }
      if (fresh.isExtensionWindow && !awaitingExtension.value) {
        _graceEndsAt = _parseIso(fresh.graceEndsAt) ?? _graceEndsAt;
        unawaited(_onMatchTimeUp());
        return;
      }
      if (!fresh.isExtensionWindow && awaitingExtension.value) {
        _applyServerExtension(fresh);
        return;
      }
      final phaseEnd = _parseIso(fresh.phaseEndsAt);
      if (phaseEnd != null) {
        _phaseEndsAt = phaseEnd;
      }
    } catch (_) {}
  }

  Future<void> hangUp({
    bool showMatchRecharge = false,
    bool forcedByPeer = false,
  }) async {
    if (isMatchCall && !isMatchCaller && !forcedByPeer) {
      return;
    }
    // Si el primer colgar solo cerró un dialog, reintentar sacar la UI.
    if (_ending) {
      _popCallUi();
      return;
    }
    _ending = true;
    awaitingExtension.value = false;
    _elapsedTimer?.cancel();
    _elapsedTimer = null;
    _statusPoll?.cancel();
    _statusPoll = null;
    _peerGoneTimer?.cancel();
    _peerGoneTimer = null;

    final peer = call.caller?.id == SessionManager.instance.getUserID()
        ? call.callee
        : call.caller;
    final cost = call.coinsCost;
    final shouldRecharge = showMatchRecharge && isMatchCaller;
    final notifyApi = !isMatchCall || isMatchCaller;
    final live = LivestreamScreenController.activeInstance;
    final shouldResume =
        resumeLiveOnHangup || (live?.pausedForCall.value == true);
    final ctrlTag = 'call_${call.id}';
    final lkTag = _tag;

    // Cerrar la UI YA (no esperar a LiveKit/API: ahí se quedaba colgado Match).
    _popCallUi();

    unawaited(() async {
      try {
        await _cleanup(notifyApi: notifyApi, liveKitTag: lkTag)
            .timeout(const Duration(seconds: 4));
      } catch (_) {}
      if (shouldResume) {
        try {
          // Liberar WebRTC de la llamada antes de reentrar al LIVE.
          await Future<void>.delayed(const Duration(milliseconds: 700));
          await (live ?? LivestreamScreenController.activeInstance)
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
      stopLoader();
    } catch (_) {}
    LiveIncomingCallOverlay.dismiss(callId: call.id);
    try {
      if (Get.isSnackbarOpen) {
        Get.closeAllSnackbars();
      }
    } catch (_) {}
    try {
      for (var i = 0; i < 4; i++) {
        if (Get.isDialogOpen == true || Get.isBottomSheetOpen == true) {
          Get.back();
          continue;
        }
        break;
      }
      if (Get.currentRoute.contains('VideoCall') ||
          Get.currentRoute.contains('OutgoingCall') ||
          Get.key.currentState?.canPop() == true) {
        Get.back();
      }
    } catch (_) {}
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
