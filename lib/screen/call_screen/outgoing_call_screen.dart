import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
import 'package:krimson/common/controller/base_controller.dart';
import 'package:krimson/common/extensions/string_extension.dart';
import 'package:krimson/common/manager/coin_gate.dart';
import 'package:krimson/common/manager/logger.dart';
import 'package:krimson/common/manager/session_manager.dart';
import 'package:krimson/common/service/api/call_service.dart';
import 'package:krimson/common/widget/custom_image.dart';
import 'package:krimson/languages/languages_keys.dart';
import 'package:krimson/model/call/call_request_model.dart';
import 'package:krimson/model/user_model/user_model.dart';
import 'package:krimson/screen/call_screen/video_call_screen.dart';
import 'package:krimson/utilities/asset_res.dart';
import 'package:krimson/utilities/color_res.dart';
import 'package:krimson/utilities/text_style_custom.dart';
import 'package:krimson/utilities/theme_res.dart';

/// Pantalla saliente estilo WhatsApp: avanza al aceptar.
class OutgoingCallScreen extends StatelessWidget {
  final User callee;
  final int cost;

  const OutgoingCallScreen({
    super.key,
    required this.callee,
    required this.cost,
  });

  @override
  Widget build(BuildContext context) {
    final tag = 'outgoing_${callee.id}_${DateTime.now().millisecondsSinceEpoch}';
    final controller = Get.put(
      OutgoingCallController(callee: callee, cost: cost),
      tag: tag,
    );

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        await controller.cancelAndClose();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0B0F14),
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
  OutgoingCallController({required this.callee, required this.cost});

  /// Instancia activa para cerrar desde FCM `call_rejected`.
  static OutgoingCallController? activeInstance;

  final User callee;
  final int cost;

  final RxString subtitle = LKey.calling.tr.obs;
  final RxnString errorText = RxnString();

  CallRequestModel? call;
  Timer? _poll;
  Timer? _timeout;
  bool _closing = false;
  bool _joined = false;
  final AudioPlayer _ringback = AudioPlayer();

  @override
  void onInit() {
    super.onInit();
    activeInstance = this;
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

  /// El receptor aceptó: una sola navegación a VideoCall (evita doble pantalla / kick LiveKit).
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
      return;
    }
    unawaited(c._enterAcceptedCall(updated: call, roomId: roomId));
  }

  Future<void> _enterAcceptedCall({
    CallRequestModel? updated,
    String? roomId,
  }) async {
    if (_joined || _closing) return;
    _joined = true;
    _poll?.cancel();
    _timeout?.cancel();
    await _stopRingback();
    subtitle.value = LKey.connecting.tr;

    CallRequestModel? current = updated ?? call;
    final rid = (roomId ?? current?.roomId ?? '').trim();

    if (current == null ||
        !current.isAccepted ||
        (current.roomId ?? '').isEmpty) {
      // Completar desde inbox o con room_id del push.
      try {
        final inbox = await CallService.instance.inbox();
        for (final e in [...inbox.sent, ...inbox.received]) {
          if (e.id == call?.id) {
            current = e;
            break;
          }
        }
      } catch (_) {}
    }

    current ??= call;
    if (current == null) {
      _joined = false;
      return;
    }

    if (rid.isNotEmpty && (current.roomId ?? '').isEmpty) {
      current = CallRequestModel(
        id: current.id,
        callerId: current.callerId,
        calleeId: current.calleeId,
        coinsCost: current.coinsCost,
        userLevel: current.userLevel,
        status: 'accepted',
        roomId: rid,
        respondedAt: current.respondedAt,
        endedAt: current.endedAt,
        createdAt: current.createdAt,
        caller: current.caller,
        callee: current.callee,
      );
    } else if (current.status != 'accepted' && rid.isNotEmpty) {
      current = CallRequestModel(
        id: current.id,
        callerId: current.callerId,
        calleeId: current.calleeId,
        coinsCost: current.coinsCost,
        userLevel: current.userLevel,
        status: 'accepted',
        roomId: rid.isNotEmpty ? rid : current.roomId,
        respondedAt: current.respondedAt,
        endedAt: current.endedAt,
        createdAt: current.createdAt,
        caller: current.caller,
        callee: current.callee,
      );
    }

    if ((current.roomId ?? '').isEmpty) {
      _joined = false;
      subtitle.value = LKey.callFailed.tr;
      return;
    }

    call = current;
    Get.off(() => VideoCallScreen(call: current!));
  }

  Future<void> _startRingback() async {
    try {
      await _ringback.setAsset(AssetRes.callSoft);
      await _ringback.setLoopMode(LoopMode.one);
      await _ringback.setVolume(0.4);
      await _ringback.play();
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
    final userId = callee.id;
    if (userId == null) {
      errorText.value = 'user not found';
      return;
    }

    subtitle.value = LKey.calling.tr;
    try {
      call = await CallService.instance.create(userId: userId);
      final me = SessionManager.instance.getUser();
      if (me != null && cost > 0) {
        me.removeCoinFromWallet(cost);
        SessionManager.instance.setUser(me);
      }
      subtitle.value = LKey.ringing.tr;
      await _startRingback();
      _poll = Timer.periodic(const Duration(seconds: 1), (_) => _checkStatus());
      _timeout = Timer(const Duration(seconds: 45), () async {
        if (_joined || _closing) return;
        await _stopRingback();
        subtitle.value = LKey.callNoAnswer.tr;
        await _cancelRemote();
        await Future.delayed(const Duration(milliseconds: 900));
        await cancelAndClose(skipCancelApi: true);
      });
    } catch (e) {
      await _stopRingback();
      final msg = e.toString().replaceFirst('Exception: ', '');
      errorText.value = msg;
      subtitle.value = LKey.callFailed.tr;
      if (msg.toLowerCase().contains('insufficient') ||
          msg.toLowerCase().contains('coin')) {
        CoinGate.ensureEnough(cost, message: 'Moneda insuficiente');
      }
      await Future.delayed(const Duration(milliseconds: 1200));
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
    subtitle.value = LKey.callRejected.tr;
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
    if (id == null || _joined || _closing) return;
    try {
      final inbox = await CallService.instance.inbox();
      CallRequestModel? updated;
      for (final e in [...inbox.sent, ...inbox.received]) {
        if (e.id == id) {
          updated = e;
          break;
        }
      }
      if (updated == null) return;
      final current = updated;
      call = current;
      final status = (current.status ?? '').toLowerCase().trim();

      if (current.isAccepted && (current.roomId ?? '').isNotEmpty) {
        await _enterAcceptedCall(updated: current);
        return;
      }

      if (status == 'rejected' || current.isRejected) {
        await _onRejected();
        return;
      }

      if (status == 'cancelled' ||
          status == 'expired' ||
          status == 'ended') {
        _poll?.cancel();
        _timeout?.cancel();
        await _stopRingback();
        subtitle.value = LKey.callCancelled.tr;
        await Future.delayed(const Duration(milliseconds: 800));
        await cancelAndClose(skipCancelApi: true);
      }
    } catch (_) {
      // silencioso; el próximo tick reintenta
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
    if (Get.key.currentState?.canPop() == true) {
      Get.back();
    }
  }
}
