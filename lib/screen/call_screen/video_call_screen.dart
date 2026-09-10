import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krimson/common/controller/base_controller.dart';
import 'package:krimson/common/extensions/string_extension.dart';
import 'package:krimson/common/manager/app_role.dart';
import 'package:krimson/common/manager/coin_gate.dart';
import 'package:krimson/common/manager/guest_gate.dart';
import 'package:krimson/common/manager/livekit_room_controller.dart';
import 'package:krimson/common/manager/logger.dart';
import 'package:krimson/common/manager/session_manager.dart';
import 'package:krimson/common/service/api/call_service.dart';
import 'package:krimson/common/service/api/gift_wallet_service.dart';
import 'package:krimson/common/service/translation/chat_translator_service.dart';
import 'package:krimson/common/widget/livekit/livekit_video_view.dart';
import 'package:krimson/common/widget/match_connecting_view.dart';
import 'package:krimson/languages/languages_keys.dart';
import 'package:krimson/model/call/call_request_model.dart';
import 'package:krimson/model/general/settings_model.dart';
import 'package:krimson/model/livestream/app_user.dart';
import 'package:krimson/model/livestream/live_chat_message.dart';
import 'package:krimson/screen/call_screen/live_incoming_call_overlay.dart';
import 'package:krimson/screen/call_screen/match_recharge_dialog.dart';
import 'package:krimson/screen/call_screen/widget/call_chat_overlay.dart';
import 'package:krimson/screen/profile_screen/widget/impression_rate_sheet.dart';
import 'package:krimson/screen/gift_sheet/gift_request_prompt.dart';
import 'package:krimson/screen/gift_sheet/send_gift_sheet.dart';
import 'package:krimson/screen/gift_sheet/send_gift_sheet_controller.dart';
import 'package:krimson/screen/live_stream/livestream_screen/livestream_screen_controller.dart';
import 'package:krimson/screen/live_stream/livestream_screen/widget/live_gift_boost_sheet.dart';
import 'package:krimson/screen/match_screen/match_screen.dart';
import 'package:krimson/screen/match_screen/match_screen_controller.dart';
import 'package:krimson/screen/match_screen/match_web_video.dart';
import 'package:krimson/utilities/client_colors.dart';
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
    this.matchFreeSeconds = 20,
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
    final client = AppRole.isClient();
    return Scaffold(
      backgroundColor: client ? ClientColors.surfaceDark : const Color(0xFF140E18),
      resizeToAvoidBottomInset: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          SafeArea(
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
                            match ? LKey.matchLabel.tr : LKey.videoCall.tr,
                            style: TextStyleCustom.outFitMedium500(
                                color: client
                                    ? ClientColors.textOnDark
                                    : Colors.white,
                                fontSize: 16),
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
                                  ? (client
                                      ? ClientColors.primary
                                      : ColorRes.themeAccentSolid)
                                  : (client
                                      ? ClientColors.textOnDarkMuted
                                      : Colors.white70),
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
              if (!controller.matchUi.value) {
                return const SizedBox.shrink();
              }
              final total = controller.matchDurationSeconds;
              final left = controller.matchSecondsLeft.value;
              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: total > 0 ? (left / total).clamp(0.0, 1.0) : 0,
                    minHeight: 6,
                    backgroundColor: client
                        ? ClientColors.secondarySoft.withValues(alpha: 0.28)
                        : Colors.white24,
                    color: client
                        ? ClientColors.secondary
                        : ColorRes.themeAccentSolid,
                  ),
                ),
              );
            }),
            Obx(() {
              if (!controller.matchUi.value) return const SizedBox.shrink();
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
                    color: client ? ClientColors.textOnDark : Colors.white,
                    fontSize: 12,
                  ),
                ),
              );
            }),
            Expanded(
              child: Obx(() {
                controller.liveKit.mediaRevision.value;
                controller.matchUi.value;
                if (kIsWeb) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    passThroughMatchVideoClicks();
                  });
                }
                final stage = Stack(
                  fit: StackFit.expand,
                  children: [
                    LiveKitCallLayout(
                      local: controller.liveKit.localParticipant.value,
                      remotes: controller.liveKit.remoteParticipants.toList(),
                      statusText: controller.status.value,
                      remotePhotoUrl: controller.peerPhotoUrl,
                      remoteName: controller.peerName,
                      localPhotoUrl: controller.localPhotoUrl,
                      localName: controller.localName,
                      localInPip: client,
                    ),
                    Positioned(
                      left: 10,
                      right: 72,
                      bottom: 8,
                      child: CallChatOverlay(controller: controller),
                    ),
                  ],
                );
                // ClipRect en Web oculta el <video> de LiveKit.
                if (kIsWeb) return stage;
                return ClipRect(child: stage);
              }),
            ),
            // Barra fuera del Expanded del video para que el HtmlElementView
            // de LiveKit (Web) no tape mic / colgar / cámara / gift.
            Material(
              color: client ? ClientColors.surfaceDark : const Color(0xFF1C1424),
              elevation: 8,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Obx(() {
                      final req = controller.pendingGiftRequest.value;
                      if (req == null || !AppRole.canSendGifts()) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: GiftRequestBar(
                          message: req,
                          onSend: () {
                            unawaited(controller.sendRequestedGift(req));
                          },
                          onDismiss: controller.dismissGiftRequest,
                        ),
                      );
                    }),
                    CallChatComposer(controller: controller),
                    Obx(() {
                      controller.matchUi.value;
                      controller.liveKit.microphoneEnabled.value;
                      controller.liveKit.cameraEnabled.value;
                      if (kIsWeb) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          passThroughMatchVideoClicks();
                        });
                      }
                      final hideHangup = controller.matchUi.value &&
                          !controller.isMatchCaller;
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _RoundBtn(
                            icon: controller.liveKit.microphoneEnabled.value
                                ? Icons.mic
                                : Icons.mic_off,
                            color: client
                                ? ClientColors.surfaceDarkAlt
                                : const Color(0xFF3A3144),
                            onTap: () {
                              if (kIsWeb) passThroughMatchVideoClicks();
                              unawaited(controller.toggleMic());
                            },
                          ),
                          if (hideHangup)
                            const SizedBox(width: 56, height: 56)
                          else
                            _RoundBtn(
                              icon: Icons.call_end,
                              color: Colors.red,
                              onTap: () {
                                if (kIsWeb) passThroughMatchVideoClicks();
                                unawaited(controller.hangUp());
                              },
                            ),
                          if (!AppRole.isStreamer())
                            _RoundBtn(
                              icon: Icons.cameraswitch_rounded,
                              color: client
                                  ? ClientColors.surfaceDarkAlt
                                  : const Color(0xFF3A3144),
                              onTap: () {
                                if (kIsWeb) passThroughMatchVideoClicks();
                                unawaited(controller.flipCamera());
                              },
                            ),
                          // Streamer: no mostrar apagar cámara (solo reactivar si está off).
                          if (!AppRole.isStreamer() ||
                              !controller.liveKit.cameraEnabled.value)
                            _RoundBtn(
                              icon: controller.liveKit.cameraEnabled.value
                                  ? Icons.videocam
                                  : Icons.videocam_off,
                              color: client
                                  ? ClientColors.surfaceDarkAlt
                                  : const Color(0xFF3A3144),
                              onTap: () {
                                if (kIsWeb) passThroughMatchVideoClicks();
                                unawaited(controller.toggleCamera());
                              },
                            ),
                          _RoundBtn(
                            icon: Icons.card_giftcard_rounded,
                            color: client
                                ? ClientColors.primary
                                : ColorRes.themeAccentSolid
                                    .withValues(alpha: 0.9),
                            onTap: () {
                              if (kIsWeb) passThroughMatchVideoClicks();
                              unawaited(controller.openGiftSheet());
                            },
                          ),
                        ],
                      );
                    }),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
          Obx(() {
            controller.liveKit.mediaRevision.value;
            controller.matchUi.value;
            controller.liveKit.isConnecting.value;
            controller.liveKit.isConnected.value;
            controller.status.value;
            final connecting = controller.showMatchConnectingOverlay;
            if (kIsWeb) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                setMatchConnectingOverlay(connecting);
              });
            }
            if (!connecting) return const SizedBox.shrink();
            final hideHangup = !controller.isMatchCaller;
            return Positioned.fill(
              child: MatchConnectingView(
                left: MatchConnectingParty.callerOf(controller.call),
                right: MatchConnectingParty.calleeOf(controller.call),
                subtitle: controller.status.value,
                bottom: hideHangup
                    ? null
                    : _RoundBtn(
                        icon: Icons.call_end,
                        color: Colors.red,
                        onTap: () {
                          if (kIsWeb) passThroughMatchVideoClicks();
                          unawaited(controller.hangUp());
                        },
                      ),
              ),
            );
          }),
        ],
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
    final iconColor =
        AppRole.isClient() ? ClientColors.textOnDark : Colors.white;
    // GestureDetector + hitTest opaque: InkWell solo fallaba bajo platform-views.
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Ink(
          width: 56,
          height: 56,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          child: Icon(icon, color: iconColor, size: 28),
        ),
      ),
    );
  }
}

class VideoCallController extends BaseController {
  static VideoCallController? activeInstance;

  VideoCallController(
    this.call, {
    this.resumeLiveOnHangup = false,
    this.isMatchPreview = false,
    this.matchFreeSeconds = 20,
  });

  final CallRequestModel call;
  final bool resumeLiveOnHangup;
  final bool isMatchPreview;
  final int matchFreeSeconds;
  final RxString status = 'Conectando...'.obs;
  final RxString elapsedLabel = '00:00'.obs;
  final RxString matchCountdownLabel = '00:00'.obs;
  final RxInt matchSecondsLeft = 20.obs;
  final RxBool matchUi = false.obs;
  final RxList<LiveChatMessage> chatMessages = <LiveChatMessage>[].obs;
  final Rxn<LiveChatMessage> pendingGiftRequest = Rxn<LiveChatMessage>();
  final RxBool chatComposerExpanded = false.obs;
  final RxBool isSendingComment = false.obs;
  final TextEditingController commentController = TextEditingController();
  final FocusNode commentFocusNode = FocusNode();
  static const int maxVisibleComments = 8;

  late final LiveKitRoomController liveKit;
  Timer? _elapsedTimer;
  Timer? _statusPoll;
  Timer? _peerGoneTimer;
  Timer? _commentPoll;
  /// Web: LiveKit recrea &lt;video&gt; y vuelve a tapar la barra de controles.
  Timer? _webPointerPassTimer;
  StreamSubscription? _dataSub;
  /// Ancla compartida: `phase_ends_at` del servidor (fallback `responded_at`).
  DateTime? _syncAnchor;
  DateTime? _phaseEndsAt;
  int? _matchDurationOverride;
  bool _forceMatch = false;
  bool _convertedToPrivate = false;
  String? _respondedAtRaw;
  bool _timerStarted = false;
  bool _ending = false;
  bool _insufficientNotified = false;
  bool _cleaned = false;
  bool _kickInsufficient = false;
  bool _waitingServerMatchDecision = false;
  bool _hadRemote = false;
  DateTime? _callConnectedAt;
  int _lastCommentServerId = 0;
  bool _commentPollBusy = false;
  bool _callRoutePopped = false;
  final Set<String> _seenGiftBoostIds = {};
  final RxBool cameraFlipUnlocked = false.obs;
  final RxBool cameraOffUnlocked = false.obs;
  bool _cameraFeatureBusy = false;

  String get roomId => call.roomId ?? 'call_${call.id}';
  String get _tag => 'lk_call_${call.id}';

  /// Solo el caller (Cliente) paga flip / apagar cámara.
  bool get _mustPayCameraFeatures =>
      call.callerId == SessionManager.instance.getUserID();

  /// Match para caller y callee (cronómetro de 20s). Tras convertir a privada, false.
  bool get isMatchCall {
    if (_convertedToPrivate) return false;
    if (isMatchPreview || _forceMatch || call.isMatchSession) return true;
    return false;
  }

  bool get _originatedFromMatch =>
      isMatchPreview || _forceMatch || call.isMatchSession;

  bool get isMatchCaller {
    if (!isMatchCall) return false;
    return call.callerId == SessionManager.instance.getUserID();
  }

  bool get isMatchClient => isMatchCaller;

  /// GIF a pantalla completa hasta que el otro entra a LiveKit.
  /// El layout de video se mantiene montado debajo (si se desmonta, el
  /// servidor ve occupancy 0 y cierra el Match).
  bool get showMatchConnectingOverlay {
    if (!matchUi.value) return false;
    if (liveKit.isConnecting.value || !liveKit.isConnected.value) return true;
    return liveKit.remoteParticipants.isEmpty;
  }

  int get matchDurationSeconds => _matchDuration;

  CallParty? get peerParty {
    final myId = SessionManager.instance.getUserID();
    return call.caller?.id == myId ? call.callee : call.caller;
  }

  String? get peerPhotoUrl => peerParty?.profilePhoto?.addBaseURL();

  String? get peerName =>
      peerParty?.fullname ?? peerParty?.username;

  String? get localPhotoUrl =>
      SessionManager.instance.getUser()?.profilePhoto?.addBaseURL();

  String? get localName {
    final me = SessionManager.instance.getUser();
    return me?.fullname ?? me?.username;
  }

  /// El otro lado colgó (FCM `call_ended`).
  static void handleRemoteEnded(int? callRequestId, {String? endedReason}) {
    if (callRequestId == null) return;
    final tag = 'call_$callRequestId';
    if (!Get.isRegistered<VideoCallController>(tag: tag)) return;
    final c = Get.find<VideoCallController>(tag: tag);
    if ((endedReason ?? '').toLowerCase().trim() == 'insufficient_coins') {
      c._notifyInsufficientIfNeeded(c.call.copyWith(endedReason: endedReason));
    }
    unawaited(c.hangUp(forcedByPeer: true));
  }

  void _syncWallet(CallRequestModel fresh) {
    SessionManager.instance.applyCoinWallet(fresh.myCoinWallet);
  }

  void _notifyInsufficientIfNeeded(CallRequestModel fresh) {
    if (_insufficientNotified) return;
    final endedInsufficient = fresh.endedForInsufficientCoins || _kickInsufficient;
    if (!endedInsufficient) return;
    _insufficientNotified = true;
    _kickInsufficient = true;
    if (_originatedFromMatch) {
      return;
    }
    final iAmCaller = call.callerId == SessionManager.instance.getUserID();
    final msg = iAmCaller
        ? LKey.callEndedInsufficientCoins.tr
        : LKey.callEndedClientNoCoins.tr;
    Future.delayed(const Duration(milliseconds: 600), () {
      BaseController.share.showSnackBar(msg);
    });
  }

  /// Push legado `match_extension_modal`: el servidor ya no abre gracia.
  static void handleExtensionModal(int? callRequestId) {
    if (callRequestId == null) return;
    final tag = 'call_$callRequestId';
    if (!Get.isRegistered<VideoCallController>(tag: tag)) return;
    final c = Get.find<VideoCallController>(tag: tag);
    unawaited(c._pollCallStatus());
  }

  static void handleConvertedToPrivate(int? callRequestId) {
    if (callRequestId == null) return;
    final tag = 'call_$callRequestId';
    if (!Get.isRegistered<VideoCallController>(tag: tag)) return;
    final c = Get.find<VideoCallController>(tag: tag);
    c._applyConvertedToPrivate();
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
    return 20;
  }

  @override
  void onInit() {
    super.onInit();
    activeInstance = this;
    matchSecondsLeft.value = _matchDuration;
    matchCountdownLabel.value = _formatMmSs(_matchDuration);
    matchUi.value = isMatchCall;
    cameraFlipUnlocked.value = call.cameraFlipUnlocked;
    cameraOffUnlocked.value = call.cameraOffUnlocked;
    liveKit = LiveKitRoomController.putFresh(_tag);
    _startStatusPoll();
    if (kIsWeb) {
      passThroughMatchVideoClicks();
      _webPointerPassTimer?.cancel();
      _webPointerPassTimer =
          Timer.periodic(const Duration(milliseconds: 400), (_) {
        passThroughMatchVideoClicks();
      });
    }
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
    _commentPoll?.cancel();
    _commentPoll = null;
    _webPointerPassTimer?.cancel();
    _webPointerPassTimer = null;
    unawaited(_dataSub?.cancel());
    _dataSub = null;
    commentController.dispose();
    commentFocusNode.dispose();
    if (identical(activeInstance, this)) {
      activeInstance = null;
    }
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
    if (_ending || isClosed) return;
    final now = DateTime.now();

    if (isMatchCall) {
      // No contar los 20s mientras sincroniza / espera al otro.
      if (!_hadRemote &&
          liveKit.remoteParticipants.isEmpty &&
          _phaseEndsAt == null) {
        matchSecondsLeft.value = _matchDuration;
        matchCountdownLabel.value = _formatMmSs(_matchDuration);
        elapsedLabel.value = matchCountdownLabel.value;
        return;
      }
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
      if (safeLeft <= 0 && !_waitingServerMatchDecision && !_convertedToPrivate) {
        unawaited(_onMatchFreeWindowEnded());
      }
    } else {
      final anchor = _syncAnchor;
      if (anchor == null) return;
      final elapsed = now.difference(anchor).inSeconds;
      elapsedLabel.value = _formatMmSs(elapsed < 0 ? 0 : elapsed);
    }
  }

  void _enableMatchUi() {
    if (_convertedToPrivate) return;
    _forceMatch = true;
    matchUi.value = true;
  }

  /// El countdown de 20s es de un solo uso: nunca se alarga si el API reenvía un deadline nuevo.
  void _adoptPhaseEndsAt(DateTime? phaseEnd) {
    if (_convertedToPrivate || _waitingServerMatchDecision || phaseEnd == null) {
      return;
    }
    final current = _phaseEndsAt;
    if (current == null || phaseEnd.isBefore(current)) {
      _phaseEndsAt = phaseEnd;
    }
  }

  void _enterPrivateFromMatch(CallRequestModel fresh) {
    _syncWallet(fresh);
    _applyConvertedToPrivate(startedAt: _parseIso(fresh.startedAt));
  }

  void _applyConvertedToPrivate({DateTime? startedAt}) {
    if (_convertedToPrivate) return;
    _convertedToPrivate = true;
    _waitingServerMatchDecision = false;
    matchUi.value = false;
    _phaseEndsAt = null;
    _syncAnchor = startedAt ?? DateTime.now();
    _timerStarted = false;
    _startSyncedTimer();
    status.value = '';
  }

  Future<void> _onMatchFreeWindowEnded() async {
    if (_ending || _convertedToPrivate || _waitingServerMatchDecision) return;
    _waitingServerMatchDecision = true;
    matchSecondsLeft.value = 0;
    matchCountdownLabel.value = _formatMmSs(0);
    elapsedLabel.value = matchCountdownLabel.value;

    final id = call.id;
    if (id == null) return;

    Future<bool> applyOrHang(CallRequestModel fresh) async {
      if (_ending) return true;
      _syncWallet(fresh);
      if (fresh.isConvertedPrivate) {
        _enterPrivateFromMatch(fresh);
        return true;
      }
      if (fresh.isEnded) {
        _notifyInsufficientIfNeeded(fresh);
        await hangUp(forcedByPeer: true);
        return true;
      }
      return false;
    }

    if (isMatchCaller) {
      try {
        final fresh = await CallService.instance.continuePrivate(callRequestId: id);
        if (await applyOrHang(fresh)) return;
      } catch (e) {
        final msg = e.toString().toLowerCase();
        if (msg.contains('insufficient')) {
          _kickInsufficient = true;
          _notifyInsufficientIfNeeded(
            call.copyWith(endedReason: 'insufficient_coins'),
          );
          await hangUp(forcedByPeer: true);
          return;
        }
        if (msg.contains('peer disconnected') || msg.contains('not active')) {
          await hangUp(forcedByPeer: true);
          return;
        }
        // Ventana aún no cerrada en el server, o red: seguir con status.
      }
    }

    for (var i = 0; i < 8 && !_ending && !_convertedToPrivate; i++) {
      try {
        if (isMatchCaller && i > 0) {
          try {
            final cont = await CallService.instance.continuePrivate(callRequestId: id);
            if (await applyOrHang(cont)) return;
          } catch (e) {
            final msg = e.toString().toLowerCase();
            if (msg.contains('insufficient')) {
              _kickInsufficient = true;
              _notifyInsufficientIfNeeded(
                call.copyWith(endedReason: 'insufficient_coins'),
              );
              await hangUp(forcedByPeer: true);
              return;
            }
            if (msg.contains('peer disconnected') || msg.contains('not active')) {
              await hangUp(forcedByPeer: true);
              return;
            }
          }
        }
        final fresh = await CallService.instance.status(id);
        if (await applyOrHang(fresh)) return;
      } catch (_) {}
      await Future<void>.delayed(const Duration(seconds: 1));
    }
    // Sin rearmar los 20s. El poll de status convierte o cuelga.
  }

  void _onMatchData(List<int> bytes) {
    try {
      final map = jsonDecode(utf8.decode(bytes));
      if (map is! Map) return;
      final type = '${map['type']}';
      if (type == 'MATCH_CONVERTED_TO_PRIVATE' ||
          type == 'match_converted_private') {
        unawaited(_pollCallStatus());
        return;
      }
      if (type == 'SHOW_EXTENSION_MODAL' || type == 'match_extension_modal') {
        unawaited(_pollCallStatus());
        return;
      }
      if (type == 'KICK_OUT') {
        final reason =
            '${map['reason'] ?? map['ended_reason'] ?? ''}'.toLowerCase();
        if (reason.contains('insufficient') || reason.contains('grace')) {
          _kickInsufficient = true;
          _notifyInsufficientIfNeeded(
            call.copyWith(endedReason: 'insufficient_coins'),
          );
        }
        unawaited(hangUp(forcedByPeer: true));
        return;
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
      final pe = _parseIso(fresh.phaseEndsAt);
      if (pe != null) {
        final wasNull = _phaseEndsAt == null;
        _adoptPhaseEndsAt(pe);
        if (wasNull && isMatchCall && !_timerStarted) {
          unawaited(_resolveAnchorAndStart());
        }
      }
      if (fresh.isConvertedPrivate) {
        _enterPrivateFromMatch(fresh);
        return;
      }
      if (fresh.isEnded) {
        _notifyInsufficientIfNeeded(fresh);
        unawaited(hangUp(forcedByPeer: true));
        return;
      }
      final roomMs = CallRequestModel.matchSecondsFromRoomId(fresh.roomId);
      if (fresh.isMatch || fresh.matchSeconds > 0 || (roomMs ?? 0) > 0) {
        _enableMatchUi();
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
    final incomingPhase = _parseIso(call.phaseEndsAt);
    if (incomingPhase != null) {
      _adoptPhaseEndsAt(incomingPhase);
    }
    if (isMatchPreview || call.isMatch || call.matchSeconds > 0) {
      _enableMatchUi();
    }
    final roomMs = CallRequestModel.matchSecondsFromRoomId(call.roomId);
    if ((roomMs ?? 0) > 0) {
      _enableMatchUi();
      _matchDurationOverride ??= roomMs;
    }

    if (_syncAnchor == null) {
      await _hydrateCallMeta();
    }
    for (var i = 0; i < 4 && _syncAnchor == null; i++) {
      await Future.delayed(const Duration(milliseconds: 200));
      await _hydrateCallMeta();
      _syncAnchor ??= _parseRespondedAt();
      final pe = _parseIso(call.phaseEndsAt);
      if (pe != null) _adoptPhaseEndsAt(pe);
    }

    if (_syncAnchor == null) {
      await _hydrateCallMeta();
      _syncAnchor ??= _parseRespondedAt();
    }

    // Match: no arrancar countdown hasta que el otro esté en sala o el
    // servidor arme phase_ends_at (ambos conectados).
    if (isMatchCall &&
        _phaseEndsAt == null &&
        !_hadRemote &&
        liveKit.remoteParticipants.isEmpty) {
      matchSecondsLeft.value = _matchDuration;
      matchCountdownLabel.value = _formatMmSs(_matchDuration);
      elapsedLabel.value = matchCountdownLabel.value;
      if (status.value.trim().isEmpty ||
          status.value == 'Conectando...' ||
          status.value == 'Conectando…') {
        status.value = LKey.waitingForOtherUser.tr;
      }
      return;
    }

    if (isMatchCall && _phaseEndsAt == null && _hadRemote) {
      // Fallback local si el API aún no armó el reloj.
      _phaseEndsAt = DateTime.now().add(Duration(seconds: _matchDuration));
      _syncAnchor = DateTime.now();
    }

    if (_syncAnchor == null && _phaseEndsAt == null) {
      status.value =
          status.value.isEmpty ? 'Sincronizando reloj...' : status.value;
      return;
    }
    _syncAnchor ??= DateTime.now();
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
      Object? connectError;
      for (var attempt = 0; attempt < 2; attempt++) {
        try {
          if (attempt > 0) {
            liveKit = LiveKitRoomController.putFresh(_tag);
          }
          await liveKit.connect(
            roomName: roomId,
            identity: '${me!.id}',
            name: me.fullname ?? me.username ?? 'user',
            publishCamera: true,
            publishMicrophone: true,
            wsUrl: liveKitWsUrl,
            allowRearCamera: !AppRole.isStreamer(),
            // Streamer en llamada: cámara siempre on.
            allowCameraDisable: !AppRole.isStreamer(),
          );
          connectError = null;
          break;
        } catch (e) {
          connectError = e;
          if (!LiveKitRoomController.isDisposedStreamError(e) || attempt > 0) {
            rethrow;
          }
        }
      }
      if (connectError != null) {
        throw connectError;
      }
      if (isClosed || _ending) return;

      ever(liveKit.statusMessage, (msg) {
        if (isClosed || _ending) return;
        status.value = msg;
      });
      ever(liveKit.remoteParticipants, (_) {
        if (isClosed || _ending) return;
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
          _peerGoneTimer = Timer(const Duration(seconds: 12), () {
            if (_ending || isClosed) return;
            if (liveKit.remoteParticipants.isNotEmpty) return;
            unawaited(hangUp(forcedByPeer: true));
          });
        } else if (liveKit.isConnected.value) {
          status.value = LKey.waitingForOtherUser.tr;
        }
      });

      _callConnectedAt = DateTime.now();
      _dataSub?.cancel();
      _dataSub = liveKit.onDataReceived.listen((event) {
        if (isClosed || _ending) return;
        final topic = event.topic ?? '';
        if (topic == 'call_chat') {
          _onCallChatBytes(event.data);
          return;
        }
        final chat = LiveChatMessage.tryParseBytes(event.data);
        if (chat != null &&
            chat.userId > 0 &&
            (chat.type == 'text' ||
                chat.type == 'gif' ||
                chat.type == 'gift' ||
                chat.type == 'gift_boost')) {
          _appendCallChat(chat);
          return;
        }
        _onMatchData(event.data);
      });
      status.value = LKey.waitingForOtherUser.tr;
      _startCommentPolling();
      unawaited(ChatTranslatorService.instance.preloadForUserLanguage());
      await _resolveAnchorAndStart();
    } catch (e) {
      if (isClosed || _ending) return;
      Loggers.error('VideoCall start: $e');
      if (LiveKitRoomController.isDisposedStreamError(e)) {
        status.value = LKey.waitingForOtherUser.tr;
        return;
      }
      status.value = e.toString();
      showSnackBar(e.toString());
    }
  }

  Future<void> toggleMic() => liveKit.toggleMicrophone();

  Future<void> flipCamera() async {
    if (AppRole.isStreamer()) {
      showSnackBar('Solo cámara frontal');
      return;
    }
    if (!liveKit.cameraEnabled.value) {
      showSnackBar('Enciende la cámara primero');
      return;
    }
    if (_mustPayCameraFeatures && !cameraFlipUnlocked.value) {
      final ok = await _purchaseCameraFeature('flip');
      if (!ok) return;
    }
    await liveKit.switchCamera();
  }

  Future<void> toggleCamera() async {
    final turningOff = liveKit.cameraEnabled.value;
    // Streamer en llamada: cámara siempre on (sí puede reactivar si se cayó).
    if (turningOff && AppRole.isStreamer()) {
      showSnackBar('La cámara debe permanecer activa');
      return;
    }
    if (turningOff &&
        _mustPayCameraFeatures &&
        !cameraOffUnlocked.value) {
      final ok = await _purchaseCameraFeature('camera_off');
      if (!ok) return;
    }
    await liveKit.toggleCamera();
  }

  Future<bool> _purchaseCameraFeature(String feature) async {
    if (_cameraFeatureBusy) return false;
    final id = call.id;
    if (id == null) return false;

    final settings = SessionManager.instance.getSettings();
    final cost = feature == 'flip'
        ? (settings?.callCameraFlipCoins ?? 100)
        : (settings?.callCameraOffCoins ?? 100);

    if (cost > 0) {
      final label = feature == 'flip'
          ? 'Cámara trasera ($cost coins)'
          : 'Apagar cámara ($cost coins)';
      final confirmed = await Get.dialog<bool>(
            AlertDialog(
              backgroundColor: ClientColors.surfaceDark,
              title: Text(
                feature == 'flip' ? 'Cámara trasera' : 'Apagar cámara',
                style: TextStyleCustom.outFitSemiBold600(
                  color: ClientColors.textOnDark,
                  fontSize: 18,
                ),
              ),
              content: Text(
                'Cuesta $cost coins. Van a la aplicación, no a la streamer. ¿Continuar?',
                style: TextStyleCustom.outFitRegular400(
                  color: ClientColors.textOnDarkMuted,
                  fontSize: 15,
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Get.back(result: false),
                  child: Text(
                    LKey.cancel.tr,
                    style: TextStyleCustom.outFitMedium500(
                      color: ClientColors.secondary,
                      fontSize: 14,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => Get.back(result: true),
                  child: Text(
                    LKey.confirm.tr,
                    style: TextStyleCustom.outFitSemiBold600(
                      color: ClientColors.primary,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ) ??
          false;
      if (!confirmed) return false;
      if (!CoinGate.ensureEnough(cost, message: label)) return false;
    }

    _cameraFeatureBusy = true;
    try {
      final updated = await CallService.instance.purchaseCameraFeature(
        callRequestId: id,
        feature: feature,
      );
      _syncWallet(updated);
      cameraFlipUnlocked.value = updated.cameraFlipUnlocked;
      cameraOffUnlocked.value = updated.cameraOffUnlocked;
      if (feature == 'flip') cameraFlipUnlocked.value = true;
      if (feature == 'camera_off') cameraOffUnlocked.value = true;
      return true;
    } catch (e) {
      showSnackBar(e.toString());
      return false;
    } finally {
      _cameraFeatureBusy = false;
    }
  }

  Future<void> openGiftSheet() async {
    if (AppRole.isStreamer()) {
      await openGiftRequestSheet();
      return;
    }
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
      giftSource: 'call',
      streamUsers: [streamUser],
      onCompletion: (gm) {
        GiftManager.showAnimationDialog(gm.gift);
        unawaited(_broadcastCallGift(gm.gift));
      },
    );
  }

  /// Streamer: elige un regalo para pedírselo al cliente.
  Future<void> openGiftRequestSheet() async {
    final gifts = SessionManager.instance.getSettings()?.gifts ?? [];
    if (gifts.isEmpty) {
      showSnackBar(LKey.noActiveGifts.tr);
      return;
    }
    await Get.bottomSheet(
      LiveGiftBoostSheet(
        gifts: gifts,
        onBoost: (gift) {
          unawaited(broadcastCallGiftBoost(gift));
        },
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  Future<void> broadcastCallGiftBoost(Gift? gift) async {
    final me = SessionManager.instance.getUser();
    if (me?.id == null) return;
    final clientId =
        '${me!.id}_giftboost_${DateTime.now().millisecondsSinceEpoch}';
    final coins = gift?.coinPrice ?? 0;
    final text = gift == null
        ? LKey.sendMeGifts.tr
        : '${LKey.giftMe.tr} ($coins ${LKey.coins.tr})';
    final msg = LiveChatMessage(
      id: clientId,
      userId: me.id!,
      userName: (me.fullname ?? me.username ?? 'user').trim(),
      type: 'gift_boost',
      text: text,
      giftId: gift?.id,
      giftImage: gift?.image,
      giftCoins: coins > 0 ? coins : gift?.coinPrice,
    );
    _appendCallChat(msg);
    try {
      final callId = call.id;
      if (callId != null) {
        await CallService.instance.sendComment(
          callRequestId: callId,
          clientId: clientId,
          type: 'text',
          text: '🎁BOOST|${gift?.id ?? 0}|$text',
        );
      }
    } catch (_) {}
    try {
      await liveKit.publishData(msg.toBytes(), topic: 'call_chat');
    } catch (e) {
      Loggers.error('broadcastCallGiftBoost: $e');
    }
    if (Get.isBottomSheetOpen == true) Get.back();
    showSnackBar('Invitación de regalos enviada');
  }

  void dismissGiftRequest() {
    pendingGiftRequest.value = null;
  }

  Future<void> promptGiftBoost(LiveChatMessage msg) async {
    if (!AppRole.canSendGifts()) return;
    if (msg.userId == SessionManager.instance.getUserID()) return;
    await GiftRequestPrompt.showDialog(
      msg: msg,
      onSend: () {
        unawaited(sendRequestedGift(msg));
      },
    );
  }

  Future<void> sendRequestedGift(LiveChatMessage msg) async {
    pendingGiftRequest.value = null;
    await sendGiftDirectly(
      giftId: msg.giftId,
      giftImage: msg.giftImage,
      coinPrice: msg.giftCoins,
    );
  }

  int? get _peerUserId {
    final me = SessionManager.instance.getUserID();
    if (call.caller?.id == me) return call.callee?.id;
    return call.caller?.id;
  }

  String? _callGiftImage(int? giftId) {
    if (giftId == null) return null;
    final gifts = SessionManager.instance.getSettings()?.gifts ?? [];
    for (final g in gifts) {
      if (g.id == giftId && (g.image ?? '').isNotEmpty) return g.image;
    }
    return null;
  }

  int _callGiftCoins(LiveChatMessage msg) {
    if ((msg.giftCoins ?? 0) > 0) return msg.giftCoins!;
    final fromText = RegExp(r'\((\d+)').firstMatch(msg.text ?? '');
    final parsed = int.tryParse(fromText?.group(1) ?? '') ?? 0;
    if (parsed > 0) return parsed;
    final gifts = SessionManager.instance.getSettings()?.gifts ?? [];
    for (final g in gifts) {
      if (g.id == msg.giftId && (g.coinPrice ?? 0) > 0) return g.coinPrice!;
    }
    return 0;
  }

  LiveChatMessage _normalizeCallChat(LiveChatMessage raw) {
    final boost = LiveChatMessage.tryParseGiftBoost(raw);
    if (boost == null) return raw;
    final coins = _callGiftCoins(boost);
    final image = (boost.giftImage ?? '').trim().isNotEmpty
        ? boost.giftImage
        : _callGiftImage(boost.giftId);
    return LiveChatMessage(
      id: boost.id,
      userId: boost.userId,
      userName: boost.userName,
      type: 'gift_boost',
      text: (boost.text ?? LKey.sendMeGifts.tr).trim(),
      giftId: boost.giftId,
      giftImage: image,
      giftCoins: coins > 0 ? coins : boost.giftCoins,
      createdAt: boost.createdAt,
    );
  }

  void _handleCallGiftBoost(LiveChatMessage msg) {
    if (!AppRole.canSendGifts()) return;
    if (msg.userId == SessionManager.instance.getUserID()) return;
    if (!_seenGiftBoostIds.add(msg.id)) return;
    pendingGiftRequest.value = msg;
    unawaited(promptGiftBoost(msg));
  }

  bool _sendingDirectGift = false;

  Future<void> sendGiftDirectly({
    int? giftId,
    String? giftImage,
    int? coinPrice,
  }) async {
    if (GuestGate.block()) return;
    if (!AppRole.canSendGifts()) return;
    if (_sendingDirectGift) return;
    final peerId = _peerUserId;
    if (peerId == null) return;
    if (giftId == null || giftId <= 0) {
      await openGiftSheet();
      return;
    }

    Gift? gift;
    final catalog = SessionManager.instance.getSettings()?.gifts ?? [];
    for (final g in catalog) {
      if (g.id == giftId) {
        gift = Gift(
          id: g.id,
          categoryId: g.categoryId,
          coinPrice: g.coinPrice,
          title: g.title,
          image: g.image,
          isFullscreen: g.isFullscreen,
        );
        break;
      }
    }
    gift ??= Gift(
      id: giftId,
      image: giftImage ?? _callGiftImage(giftId),
      coinPrice: coinPrice,
    );
    if ((gift.image ?? '').isEmpty && (giftImage ?? '').isNotEmpty) {
      gift.image = giftImage;
    }
    var price = gift.coinPrice ?? 0;
    if (price <= 0) {
      for (final g in catalog) {
        if (g.id == giftId && (g.coinPrice ?? 0) > 0) {
          price = g.coinPrice!;
          gift.coinPrice = price;
          break;
        }
      }
    }
    if (price <= 0 && (coinPrice ?? 0) > 0) {
      price = coinPrice!;
      gift.coinPrice = price;
    }
    if (price <= 0) {
      showSnackBar(LKey.giftNotAvailable.tr);
      return;
    }
    if (!CoinGate.ensureEnough(
      price,
      message: LKey.insufficientCoins.tr,
      peerName: peerName,
      peerPhotoUrl: peerPhotoUrl,
    )) {
      return;
    }

    _sendingDirectGift = true;
    try {
      final detailed = await GiftWalletService.instance.sendGiftDetailed(
        giftId: giftId,
        userId: peerId,
        source: 'call',
      );
      if (!detailed.ok) {
        showSnackBar(detailed.message ?? LKey.giftNotAvailable.tr);
        return;
      }
      if (detailed.coinPrice > 0) gift.coinPrice = detailed.coinPrice;
      if ((detailed.image ?? '').isNotEmpty) gift.image = detailed.image;

      final me = SessionManager.instance.getUser();
      me?.removeCoinFromWallet(gift.coinPrice ?? price);
      SessionManager.instance.setUser(me);

      GiftManager.showAnimationDialog(gift);
      await _broadcastCallGift(gift);
    } finally {
      _sendingDirectGift = false;
    }
  }

  Future<void> _broadcastCallGift(Gift gift) async {
    final me = SessionManager.instance.getUser();
    if (me?.id == null) return;
    final clientId = '${me!.id}_gift_${DateTime.now().millisecondsSinceEpoch}';
    var coins = gift.coinPrice ?? 0;
    if (coins <= 0 && gift.id != null) {
      final catalog = SessionManager.instance.getSettings()?.gifts ?? [];
      for (final g in catalog) {
        if (g.id == gift.id && (g.coinPrice ?? 0) > 0) {
          coins = g.coinPrice!;
          break;
        }
      }
    }
    final msg = LiveChatMessage(
      id: clientId,
      userId: me.id!,
      userName: me.fullname ?? me.username ?? 'user',
      type: 'gift',
      text: LKey.sentAGift.tr,
      giftId: gift.id,
      giftImage: gift.image,
      giftCoins: coins,
    );
    _appendCallChat(msg);
    try {
      await liveKit.publishData(msg.toBytes(), topic: 'call_chat');
    } catch (e) {
      Loggers.error('broadcastCallGift: $e');
    }
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
      _syncWallet(fresh);
      cameraFlipUnlocked.value =
          cameraFlipUnlocked.value || fresh.cameraFlipUnlocked;
      cameraOffUnlocked.value =
          cameraOffUnlocked.value || fresh.cameraOffUnlocked;
      if (fresh.isEnded) {
        _notifyInsufficientIfNeeded(fresh);
        await hangUp(forcedByPeer: true);
        return;
      }
      if (fresh.isConvertedPrivate && !_convertedToPrivate) {
        _enterPrivateFromMatch(fresh);
        return;
      }
      _adoptPhaseEndsAt(_parseIso(fresh.phaseEndsAt));
      if (isMatchCall &&
          _phaseEndsAt != null &&
          !_timerStarted &&
          (_hadRemote || liveKit.remoteParticipants.isNotEmpty)) {
        unawaited(_resolveAnchorAndStart());
      }
    } catch (_) {}
  }

  void expandChatComposer() {
    chatComposerExpanded.value = true;
    commentFocusNode.requestFocus();
  }

  void collapseChatComposer() {
    chatComposerExpanded.value = false;
    commentFocusNode.unfocus();
  }

  void _onCallChatBytes(List<int> bytes) {
    final msg = LiveChatMessage.tryParseBytes(bytes);
    if (msg == null) return;
    if (msg.type != 'text' &&
        msg.type != 'gif' &&
        msg.type != 'gift' &&
        msg.type != 'gift_boost') {
      return;
    }
    _appendCallChat(msg);
  }

  void _appendCallChat(LiveChatMessage raw) {
    final msg = _normalizeCallChat(raw);
    if (chatMessages.any((m) => m.id == msg.id)) return;
    chatMessages.add(msg);
    while (chatMessages.length > maxVisibleComments) {
      chatMessages.removeAt(0);
    }
    if (msg.type == 'gift_boost') {
      _handleCallGiftBoost(msg);
    }
    if (msg.type == 'gift') {
      final me = SessionManager.instance.getUserID();
      if (msg.userId != me) {
        final gift = Gift(
          id: msg.giftId,
          image: msg.giftImage,
          coinPrice: msg.giftCoins,
        );
        GiftManager.showAnimationDialog(gift);
      }
    }
    if (msg.type == 'gift_boost' && AppRole.isClient()) {
      final me = SessionManager.instance.getUserID();
      if (msg.userId != me) {
        _promptGiftRequest(msg);
      }
    }
    if (msg.type == 'text' &&
        !msg.isTranslated &&
        (msg.text ?? '').trim().isNotEmpty) {
      final me = SessionManager.instance.getUserID();
      if (msg.userId != me) {
        unawaited(_translateCallChat(msg));
      }
    }
  }

  void _promptGiftRequest(LiveChatMessage msg) {
    final coins = msg.giftCoins ?? 0;
    final title = msg.text ?? LKey.sendMeGifts.tr;
    Get.snackbar(
      'Regalos',
      coins > 0 ? '$title 🎁' : title,
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.black87,
      colorText: Colors.white,
      margin: const EdgeInsets.all(12),
      borderRadius: 16,
      duration: const Duration(seconds: 5),
      onTap: (_) {
        Get.closeCurrentSnackbar();
        unawaited(sendRequestedGift(msg));
      },
      mainButton: TextButton(
        onPressed: () {
          Get.closeCurrentSnackbar();
          unawaited(sendRequestedGift(msg));
        },
        child: const Text(
          'Regalar',
          style: TextStyle(color: ColorRes.themeAccentSolid),
        ),
      ),
    );
  }

  Future<void> _translateCallChat(LiveChatMessage msg) async {
    final original = (msg.text ?? '').trim();
    if (original.isEmpty) return;
    try {
      await ChatTranslatorService.instance.ensureReady(
        targetLangCode: SessionManager.instance.getLang(),
      );
      final translated = await ChatTranslatorService.instance.translateText(
        original,
        targetLangCode: SessionManager.instance.getLang(),
      );
      final out = translated.trim();
      if (out.isEmpty || out == original) return;
      final idx = chatMessages.indexWhere((m) => m.id == msg.id);
      if (idx < 0) return;
      if (chatMessages[idx].isTranslated) return;
      chatMessages[idx] = msg.copyWithTranslation(
        original: original,
        translated: out,
      );
      chatMessages.refresh();
    } catch (e) {
      Loggers.error('call chat translate: $e');
    }
  }

  void _startCommentPolling() {
    _commentPoll?.cancel();
    unawaited(_pollComments(initial: true));
    _commentPoll = Timer.periodic(const Duration(seconds: 3), (_) {
      unawaited(_pollComments());
    });
  }

  Future<void> _pollComments({bool initial = false}) async {
    if (_ending || _commentPollBusy) return;
    final id = call.id;
    if (id == null) return;
    _commentPollBusy = true;
    try {
      final payload = await CallService.instance.fetchComments(
        callRequestId: id,
        afterId: initial
            ? null
            : (_lastCommentServerId > 0 ? _lastCommentServerId : null),
        limit: initial ? maxVisibleComments : 20,
      );
      for (final msg in payload.comments) {
        _appendCallChat(msg);
      }
      if (payload.lastServerId > _lastCommentServerId) {
        _lastCommentServerId = payload.lastServerId;
      }
    } catch (e) {
      Loggers.error('call comments poll: $e');
    } finally {
      _commentPollBusy = false;
    }
  }

  Future<void> sendComment(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || isSendingComment.value) return;
    final me = SessionManager.instance.getUser();
    final callId = call.id;
    if (me?.id == null || callId == null) return;
    isSendingComment.value = true;
    try {
      final clientId = '${me!.id}_${DateTime.now().millisecondsSinceEpoch}';
      final msg = LiveChatMessage(
        id: clientId,
        userId: me.id!,
        userName: (me.fullname ?? me.username ?? 'User').trim(),
        type: 'text',
        text: trimmed,
      );
      _appendCallChat(msg);
      commentController.clear();
      collapseChatComposer();
      try {
        final saved = await CallService.instance.sendComment(
          callRequestId: callId,
          clientId: clientId,
          type: 'text',
          text: trimmed,
        );
        if (saved != null) {
          _appendCallChat(saved);
        }
      } catch (e) {
        Loggers.error('call sendComment api: $e');
      }
      try {
        await liveKit.publishData(msg.toBytes(), topic: 'call_chat');
      } catch (_) {}
    } catch (e) {
      showSnackBar(e.toString());
    } finally {
      isSendingComment.value = false;
    }
  }

  Future<void> hangUp({
    bool showMatchRecharge = false,
    bool forcedByPeer = false,
  }) async {
    if (isMatchCall && !isMatchCaller && !forcedByPeer) {
      return;
    }
    // Si el primer colgar solo cerró un dialog, reintentar sacar la UI de la llamada.
    if (_ending) {
      _popCallUi();
      return;
    }
    _ending = true;
    _elapsedTimer?.cancel();
    _elapsedTimer = null;
    _statusPoll?.cancel();
    _statusPoll = null;
    _peerGoneTimer?.cancel();
    _peerGoneTimer = null;
    _commentPoll?.cancel();
    _commentPoll = null;
    _webPointerPassTimer?.cancel();
    _webPointerPassTimer = null;

    final peer = call.caller?.id == SessionManager.instance.getUserID()
        ? call.callee
        : call.caller;
    final iAmCaller = call.callerId == SessionManager.instance.getUserID();
    final shouldRecharge = _originatedFromMatch &&
        iAmCaller &&
        (_insufficientNotified || _kickInsufficient || showMatchRecharge);
    final notifyApi = !isMatchCall || isMatchCaller;
    final live = LivestreamScreenController.activeInstance;
    final shouldResume =
        resumeLiveOnHangup || (live?.pausedForCall.value == true);
    final ctrlTag = 'call_${call.id}';
    final lkTag = _tag;
    final stayOnMatch = _originatedFromMatch && AppRole.isStreamer();

    // Cerrar la UI YA (no esperar a LiveKit/API: ahí se quedaba colgado Match).
    _popCallUi();
    if (stayOnMatch && !Get.isRegistered<MatchScreenController>()) {
      Get.to(() => const MatchScreen());
    }

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
      if (_originatedFromMatch) {
        if (Get.isRegistered<MatchScreenController>()) {
          unawaited(Get.find<MatchScreenController>().resumeAfterCall());
        } else if (stayOnMatch) {
          Get.to(() => const MatchScreen());
        }
      }
      try {
        if (Get.isRegistered<VideoCallController>(tag: ctrlTag)) {
          Get.delete<VideoCallController>(tag: ctrlTag, force: true);
        }
      } catch (_) {}
      if (shouldRecharge) {
        Future.microtask(() {
          unawaited(MatchRechargeDialog.showOutOfCoins(party: peer));
        });
      } else {
        _promptImpressionAfterCall(peer);
      }
    }());
  }

  void _promptImpressionAfterCall(CallParty? peer) {
    if (!AppRole.isClient() || GuestGate.isAnonymous) return;
    final streamerId = peer?.id;
    if (streamerId == null || streamerId <= 0) return;
    if (streamerId == SessionManager.instance.getUserID()) return;
    Future.delayed(const Duration(milliseconds: 450), () {
      unawaited(ImpressionRateSheet.show(streamerId: streamerId));
    });
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
    // En Match streamer no usar Get.back de overlays: un falso
    // isDialogOpen sacaba la pantalla de espera.
    if (!(isMatchCall && AppRole.isStreamer())) {
      try {
        if (Get.isDialogOpen == true) {
          Get.back();
        }
      } catch (_) {}
      try {
        if (Get.isBottomSheetOpen == true) {
          Get.back();
        }
      } catch (_) {}
    }
    if (_callRoutePopped) return;
    _callRoutePopped = true;
    try {
      final nav = Get.key.currentState;
      if (nav != null && nav.canPop()) {
        nav.pop();
        return;
      }
      if (Get.currentRoute.contains('VideoCall') ||
          Get.currentRoute.contains('OutgoingCall')) {
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
