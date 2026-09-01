import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
import 'package:krimson/common/controller/base_controller.dart';
import 'package:krimson/common/extensions/string_extension.dart';
import 'package:krimson/common/manager/coin_gate.dart';
import 'package:krimson/common/manager/guest_gate.dart';
import 'package:krimson/common/manager/logger.dart';
import 'package:krimson/common/manager/session_manager.dart';
import 'package:krimson/common/service/api/call_service.dart';
import 'package:krimson/common/widget/custom_image.dart';
import 'package:krimson/languages/languages_keys.dart';
import 'package:krimson/model/call/call_request_model.dart';
import 'package:krimson/model/user_model/user_model.dart';
import 'package:krimson/screen/call_screen/video_call_screen.dart';
import 'package:krimson/screen/live_stream/livestream_screen/livestream_screen_controller.dart';
import 'package:krimson/utilities/asset_res.dart';
import 'package:krimson/utilities/color_res.dart';
import 'package:krimson/utilities/role_colors.dart';
import 'package:krimson/utilities/text_style_custom.dart';
import 'package:krimson/utilities/theme_res.dart';

/// Pantalla saliente estilo WhatsApp: avanza al aceptar.
class OutgoingCallScreen extends StatefulWidget {
  final User callee;
  final int cost;
  final bool isMatch;
  final int matchFreeSeconds;
  /// Si create falla por "already in a call" y venimos del LIVE, redirigir.
  final bool onBusyRedirectToNextLive;

  const OutgoingCallScreen({
    super.key,
    required this.callee,
    required this.cost,
    this.isMatch = false,
    this.matchFreeSeconds = 40,
    this.onBusyRedirectToNextLive = false,
  });

  @override
  State<OutgoingCallScreen> createState() => _OutgoingCallScreenState();
}

class _OutgoingCallScreenState extends State<OutgoingCallScreen> {
  late final String _tag;
  late final OutgoingCallController controller;

  @override
  void initState() {
    super.initState();
    // Tag estable: un solo controller (antes DateTime.now() recreaba uno por rebuild).
    _tag = 'outgoing_${widget.callee.id}';
    if (Get.isRegistered<OutgoingCallController>(tag: _tag)) {
      Get.delete<OutgoingCallController>(tag: _tag, force: true);
    }
    controller = Get.put(
      OutgoingCallController(
        callee: widget.callee,
        cost: widget.cost,
        isMatch: widget.isMatch,
        matchFreeSeconds: widget.matchFreeSeconds,
        onBusyRedirectToNextLive: widget.onBusyRedirectToNextLive,
      ),
      tag: _tag,
    );
  }

  @override
  void dispose() {
    if (Get.isRegistered<OutgoingCallController>(tag: _tag)) {
      Get.delete<OutgoingCallController>(tag: _tag, force: true);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final callee = widget.callee;
    final cost = widget.cost;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        await controller.cancelAndClose();
      },
      child: Scaffold(
        backgroundColor: RolePalette.bg,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 24),
                Obx(() => Text(
                      controller.subtitle.value,
                      textAlign: TextAlign.center,
                      style: TextStyleCustom.outFitRegular400(
                        color: whitePure(context).withValues(alpha: 0.75),
                        fontSize: 15,
                      ),
                    )),
                const SizedBox(height: 36),
                Center(
                  child: CustomImage(
                    size: const Size(120, 120),
                    image: callee.profilePhoto?.addBaseURL(),
                    fullName: callee.fullname ?? callee.username,
                    strokeWidth: 0,
                  ),
                ),
                const SizedBox(height: 22),
                Text(
                  callee.fullname ?? callee.username ?? '-',
                  textAlign: TextAlign.center,
                  style: TextStyleCustom.unboundedSemiBold600(
                    color: whitePure(context),
                    fontSize: 24,
                  ),
                ),
                if ((callee.username ?? '').isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    '@${callee.username}',
                    textAlign: TextAlign.center,
                    style: TextStyleCustom.outFitRegular400(
                      color: whitePure(context).withValues(alpha: 0.55),
                      fontSize: 14,
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                if (cost > 0)
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.asset(AssetRes.icCoin, height: 16, width: 16),
                          const SizedBox(width: 6),
                          Text(
                            LKey.callCostPerMin.trParams({'coins': '$cost'}),
                            style: TextStyleCustom.outFitMedium500(
                              color: whitePure(context),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                const Spacer(),
                Obx(() {
                  final err = controller.errorText.value;
                  if (err == null || err.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      err,
                      textAlign: TextAlign.center,
                      style: TextStyleCustom.outFitRegular400(
                        color: ColorRes.likeRed,
                        fontSize: 14,
                      ),
                    ),
                  );
                }),
                Center(
                  child: InkWell(
                    onTap: controller.cancelAndClose,
                    borderRadius: BorderRadius.circular(40),
                    child: const CircleAvatar(
                      radius: 34,
                      backgroundColor: ColorRes.likeRed,
                      child: Icon(Icons.call_end,
                          color: Colors.white, size: 32),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  LKey.cancelCall.tr,
                  textAlign: TextAlign.center,
                  style: TextStyleCustom.outFitMedium500(
                    color: whitePure(context).withValues(alpha: 0.8),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 28),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class OutgoingCallController extends BaseController {
  OutgoingCallController({
    required this.callee,
    required this.cost,
    this.isMatch = false,
    this.matchFreeSeconds = 40,
    this.onBusyRedirectToNextLive = false,
  }) : subtitle = (isMatch ? 'Match…' : LKey.calling.tr).obs;

  /// Instancia activa para cerrar desde FCM `call_rejected` / `call_accepted`.
  static OutgoingCallController? activeInstance;

  final User callee;
  final int cost;
  final bool isMatch;
  final int matchFreeSeconds;
  final bool onBusyRedirectToNextLive;

  final RxString subtitle;
  final RxnString errorText = RxnString();

  CallRequestModel? call;
  Timer? _poll;
  Timer? _timeout;
  bool _closing = false;
  bool _joined = false;
  bool _checkBusy = false;
  final AudioPlayer _ringback = AudioPlayer();

  @override
  void onInit() {
    super.onInit();
    activeInstance = this;
    if (!isMatch) {
      unawaited(
        LivestreamScreenController.activeInstance?.pauseLiveKitForCall(),
      );
    }
  }

  @override
  void onReady() {
    super.onReady();
    _startCall();
  }

  @override
  void onClose() {
    if (identical(activeInstance, this)) {
      activeInstance = null;
    }
    _poll?.cancel();
    _timeout?.cancel();
    unawaited(_stopRingback(disposePlayer: true));
    super.onClose();
  }

  /// Cierre inmediato cuando el callee rechaza (push FCM).
  static void handleRemoteRejected(int? callRequestId) {
    final c = activeInstance;
    if (c == null || c._closing || c._joined) return;
    if (callRequestId != null &&
        c.call?.id != null &&
        c.call!.id != callRequestId) {
      return;
    }
    unawaited(c._onRejected());
  }

  /// El receptor aceptó: una sola navegación a VideoCall.
  static void handleRemoteAccepted({
    int? callRequestId,
    String? roomId,
    CallRequestModel? call,
  }) {
    final c = activeInstance;
    if (c == null || c._closing || c._joined) return;
    if (callRequestId != null &&
        c.call?.id != null &&
        c.call!.id != callRequestId) {
      // Match cruzado: el id aceptado es el del otro pending.
      if (!c.isMatch) return;
    }
    unawaited(c._enterAcceptedCall(
      updated: call,
      roomId: roomId,
      callRequestId: callRequestId,
    ));
  }

  /// El otro también pulsó Llamar (pending cruzado).
  static void handleCrossedMatch(CallRequestModel incoming) {
    final c = activeInstance;
    if (c == null || c._closing || c._joined || !c.isMatch) return;
    final peerId = c.callee.id;
    if (incoming.callerId != peerId && incoming.calleeId != peerId) return;
    unawaited(c._onCrossedMatch(incoming));
  }

  Future<void> _onCrossedMatch(CallRequestModel incoming) async {
    if (_joined || _closing) return;
    if (incoming.isAccepted && (incoming.roomId ?? '').trim().isNotEmpty) {
      await _enterAcceptedCall(updated: incoming);
      return;
    }
    if (!incoming.isPending || incoming.id == null) return;
    try {
      final accepted = await CallService.instance.accept(incoming.id!);
      final mine = call?.id;
      if (mine != null && mine != incoming.id) {
        try {
          await CallService.instance.cancel(mine);
        } catch (_) {}
      }
      await _enterAcceptedCall(updated: accepted);
    } catch (e) {
      Loggers.error('crossed match accept: $e');
    }
  }

  Future<void> _enterAcceptedCall({
    CallRequestModel? updated,
    String? roomId,
    int? callRequestId,
  }) async {
    if (_joined || _closing) return;
    _joined = true;
    _poll?.cancel();
    _timeout?.cancel();
    await _stopRingback();
    subtitle.value = isMatch ? 'Conectando Match…' : LKey.connecting.tr;

    final targetId = callRequestId ?? updated?.id ?? call?.id;
    CallRequestModel? current = updated ?? call;
    var rid = (roomId ?? current?.roomId ?? '').trim();

    Future<CallRequestModel?> fetchFresh() async {
      if (targetId != null) {
        try {
          return await CallService.instance.status(targetId);
        } catch (e) {
          Loggers.error('call status: $e');
        }
      }
      try {
        final inbox = await CallService.instance.inbox();
        for (final e in [...inbox.sent, ...inbox.received]) {
          if (targetId != null && e.id == targetId) return e;
          if (call?.id != null && e.id == call!.id) return e;
        }
      } catch (e) {
        Loggers.error('call inbox poll: $e');
      }
      return null;
    }

    if (current == null ||
        !current.isAccepted ||
        (current.roomId ?? '').trim().isEmpty) {
      final fresh = await fetchFresh();
      if (fresh != null) current = fresh;
    }

    rid = (roomId ?? current?.roomId ?? rid).trim();

    // Sintetizar si el push trae room_id aunque no haya modelo local.
    if (current == null && rid.isNotEmpty && targetId != null) {
      current = CallRequestModel(
        id: targetId,
        callerId: SessionManager.instance.getUserID(),
        calleeId: callee.id,
        coinsCost: cost,
        status: 'accepted',
        roomId: rid,
        matchSeconds: isMatch ? matchFreeSeconds : 0,
        isMatch: isMatch,
        callee: CallParty(
          id: callee.id,
          username: callee.username,
          fullname: callee.fullname,
          profilePhoto: callee.profilePhoto,
        ),
      );
    }

    // Asegurar responded_at (ancla del cronómetro sync).
    if (current != null &&
        ((current.respondedAt ?? '').trim().isEmpty ||
            (isMatch && current.matchSeconds <= 0))) {
      final fresh = await fetchFresh();
      if (fresh != null) {
        current = current.copyWith(
          status: fresh.status ?? current.status,
          roomId: (fresh.roomId ?? '').trim().isNotEmpty
              ? fresh.roomId
              : current.roomId,
          respondedAt: fresh.respondedAt ?? current.respondedAt,
          matchSeconds: fresh.matchSeconds > 0
              ? fresh.matchSeconds
              : (isMatch ? matchFreeSeconds : current.matchSeconds),
        );
      } else if (isMatch && current.matchSeconds <= 0) {
        current = current.copyWith(matchSeconds: matchFreeSeconds);
      }
    }

    if (current == null) {
      Loggers.error('enterAcceptedCall: no call model (id=$targetId rid=$rid)');
      _joined = false;
      subtitle.value = LKey.ringing.tr;
      _poll = Timer.periodic(const Duration(seconds: 2), (_) => _checkStatus());
      return;
    }

    if (rid.isNotEmpty && (current.roomId ?? '').trim().isEmpty) {
      current = current.copyWith(status: 'accepted', roomId: rid);
    } else if (!current.isAccepted && rid.isNotEmpty) {
      current = current.copyWith(status: 'accepted', roomId: rid);
    } else if (!current.isAccepted &&
        (current.roomId ?? '').trim().isNotEmpty) {
      current = current.copyWith(status: 'accepted');
    }

    if ((current.roomId ?? '').trim().isEmpty) {
      Loggers.error('enterAcceptedCall: empty room_id for ${current.id}');
      _joined = false;
      subtitle.value = isMatch ? 'Match fallido' : LKey.callFailed.tr;
      return;
    }

    call = current;
    final live = LivestreamScreenController.activeInstance;
    if (live != null) {
      try {
        await live.pauseLiveKitForCall();
      } catch (_) {}
      await Future<void>.delayed(const Duration(milliseconds: 600));
      Get.off(() => VideoCallScreen(
            call: current!,
            resumeLiveOnHangup: true,
            isMatchPreview: isMatch,
            matchFreeSeconds: matchFreeSeconds,
          ));
    } else {
      Get.off(() => VideoCallScreen(
            call: current!,
            isMatchPreview: isMatch,
            matchFreeSeconds: matchFreeSeconds,
          ));
    }
  }

  Future<void> _startRingback() async {
    try {
      await _ringback.setAsset(AssetRes.callSoft);
      await _ringback.setLoopMode(LoopMode.one);
      await _ringback.setVolume(0.4);
      // LoopMode.one: play() no completa; no await para no bloquear el poll.
      unawaited(_ringback.play());
    } catch (e) {
      Loggers.error('outgoing ringback: $e');
    }
  }

  Future<void> _stopRingback({bool disposePlayer = false}) async {
    try {
      await _ringback.stop();
    } catch (_) {}
    if (disposePlayer) {
      try {
        await _ringback.dispose();
      } catch (_) {}
    }
  }

  Future<void> _startCall() async {
    if (GuestGate.block()) return;
    final userId = callee.id;
    if (userId == null) {
      errorText.value = 'user not found';
      return;
    }

    subtitle.value = isMatch ? 'Match…' : LKey.calling.tr;
    try {
      call = await CallService.instance.create(
        userId: userId,
        isMatch: isMatch,
        matchSeconds: isMatch ? matchFreeSeconds : null,
        coinsCost: cost > 0 ? cost : null,
      );
      final me = SessionManager.instance.getUser();
      if (me != null && cost > 0) {
        me.removeCoinFromWallet(cost);
        SessionManager.instance.setUser(me);
      }
      if (call != null &&
          call!.isAccepted &&
          (call!.roomId ?? '').trim().isNotEmpty) {
        await _enterAcceptedCall(updated: call);
        return;
      }
      subtitle.value = LKey.ringing.tr;
      unawaited(_startRingback());
      _poll?.cancel();
      _poll = Timer.periodic(const Duration(seconds: 2), (_) {
        unawaited(_checkStatus());
      });
      unawaited(_checkStatus());
      _timeout?.cancel();
      _timeout = Timer(const Duration(seconds: 45), () async {
        if (_joined || _closing) return;
        // Última chance: puede que ya esté accepted y el poll falló.
        try {
          final id = call?.id;
          if (id != null) {
            final fresh = await CallService.instance.status(id);
            if (fresh.isAccepted && (fresh.roomId ?? '').isNotEmpty) {
              await _enterAcceptedCall(updated: fresh);
              return;
            }
          }
        } catch (_) {}
        await _stopRingback();
        subtitle.value = isMatch ? 'Sin respuesta' : LKey.callNoAnswer.tr;
        await _cancelRemote();
        await Future.delayed(const Duration(milliseconds: 900));
        await cancelAndClose(skipCancelApi: true);
      });
    } catch (e) {
      await _stopRingback();
      final msg = e.toString().replaceFirst('Exception: ', '');
      errorText.value = msg;
      subtitle.value = isMatch ? 'Match fallido' : LKey.callFailed.tr;
      if (msg.toLowerCase().contains('peer left') ||
          msg.toLowerCase().contains('join match')) {
        errorText.value = 'El otro usuario ya no está en Match';
        subtitle.value = 'El otro usuario ya no está en Match';
      }
      if (msg.toLowerCase().contains('join the live')) {
        errorText.value = LKey.callOnlyFromLive.tr;
        subtitle.value = LKey.callOnlyFromLive.tr;
      }
      final busy = msg.toLowerCase().contains('already in a call');
      if (busy) {
        errorText.value = LKey.callStreamerInCall.tr;
        subtitle.value = LKey.callStreamerInCall.tr;
      }
      if (msg.toLowerCase().contains('insufficient') ||
          msg.toLowerCase().contains('coin')) {
        CoinGate.ensureEnough(cost, message: 'Moneda insuficiente');
      }
      await Future.delayed(const Duration(milliseconds: 900));
      if (busy && onBusyRedirectToNextLive) {
        if (!_closing && Get.key.currentState?.canPop() == true) {
          Get.back();
        }
        final live = LivestreamScreenController.activeInstance;
        if (live != null) {
          unawaited(live.leaveAndRedirectToNextLive());
        }
        return;
      }
      await Future.delayed(const Duration(milliseconds: 300));
      if (!_closing && Get.key.currentState?.canPop() == true) {
        Get.back();
      }
    }
  }

  Future<void> _onRejected() async {
    if (_joined || _closing) return;
    _poll?.cancel();
    _timeout?.cancel();
    await _stopRingback();
    subtitle.value = isMatch ? 'Match rechazado' : LKey.callRejected.tr;
    final me = SessionManager.instance.getUser();
    if (me != null && cost > 0) {
      me.coinWallet = (me.coinWallet ?? 0) + cost;
      SessionManager.instance.setUser(me);
    }
    await Future.delayed(const Duration(milliseconds: 900));
    await cancelAndClose(skipCancelApi: true);
  }

  Future<void> _checkStatus() async {
    final id = call?.id;
    if (id == null || _joined || _closing || _checkBusy) return;
    _checkBusy = true;
    try {
      CallRequestModel? updated;
      try {
        updated = await CallService.instance.status(id);
      } catch (_) {
        final inbox = await CallService.instance.inbox();
        for (final e in [...inbox.sent, ...inbox.received]) {
          if (e.id == id) {
            updated = e;
            break;
          }
        }
      }
      if (updated == null) return;
      call = updated;
      final status = (updated.status ?? '').toLowerCase().trim();

      if (updated.isAccepted && (updated.roomId ?? '').isNotEmpty) {
        await _enterAcceptedCall(updated: updated);
        return;
      }

      if (status == 'rejected' || updated.isRejected) {
        await _onRejected();
        return;
      }

      if (isMatch) {
        try {
          final inbox = await CallService.instance.inbox();
          final peerId = callee.id;
          for (final e in [...inbox.received, ...inbox.sent]) {
            if (!e.isMatchSession) continue;
            if (e.callerId != peerId && e.calleeId != peerId) continue;
            if (e.id != null && e.id == id) continue;
            if (e.isAccepted && (e.roomId ?? '').trim().isNotEmpty) {
              await _enterAcceptedCall(updated: e);
              return;
            }
            if (e.isPending && e.calleeId == SessionManager.instance.getUserID()) {
              await _onCrossedMatch(e);
              return;
            }
          }
        } catch (_) {}
      }

      if (status == 'cancelled' ||
          status == 'expired' ||
          status == 'ended') {
        _poll?.cancel();
        _timeout?.cancel();
        await _stopRingback();
        subtitle.value = isMatch ? 'Match cancelado' : LKey.callCancelled.tr;
        await Future.delayed(const Duration(milliseconds: 800));
        await cancelAndClose(skipCancelApi: true);
      }
    } catch (e) {
      Loggers.error('outgoing poll: $e');
    } finally {
      _checkBusy = false;
    }
  }

  Future<void> _cancelRemote() async {
    final id = call?.id;
    if (id == null) return;
    try {
      await CallService.instance.cancel(id);
      final me = SessionManager.instance.getUser();
      if (me != null && cost > 0) {
        me.coinWallet = (me.coinWallet ?? 0) + cost;
        SessionManager.instance.setUser(me);
      }
    } catch (_) {}
  }

  Future<void> cancelAndClose({
    bool skipCancelApi = false,
  }) async {
    if (_closing) return;
    _closing = true;
    _poll?.cancel();
    _timeout?.cancel();
    await _stopRingback();
    if (!skipCancelApi && call?.isPending == true) {
      await _cancelRemote();
    }
    if (!_joined) {
      unawaited(
        LivestreamScreenController.activeInstance?.resumeLiveKitAfterCall(),
      );
    }
    if (Get.key.currentState?.canPop() == true) {
      Get.back();
    }
  }
}
