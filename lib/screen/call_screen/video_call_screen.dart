import 'dart:async';

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
import 'package:krimson/utilities/theme_res.dart';

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
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: Obx(() {
                controller.liveKit.mediaRevision.value;
                return LiveKitCallLayout(
                  local: controller.liveKit.localParticipant.value,
                  remotes: controller.liveKit.remoteParticipants.toList(),
                  statusText: controller.status.value,
                );
              }),
            ),
            Positioned(
              left: 16,
              top: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    controller.isMatchClient
                        ? 'Match'
                        : LKey.videoCall.tr,
                    style: TextStyleCustom.outFitMedium500(
                        color: whitePure(context), fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Obx(() {
                    final match = controller.isMatchClient;
                    final left = controller.matchSecondsLeft.value;
                    final label = match
                        ? '00:${left.toString().padLeft(2, '0')}'
                        : controller.elapsedLabel.value;
                    return Text(
                      label,
                      style: TextStyleCustom.outFitRegular400(
                        color: match && left <= 5
                            ? ColorRes.themeAccentSolid
                            : whitePure(context).withValues(alpha: 0.8),
                        fontSize: match ? 18 : 13,
                      ),
                    );
                  }),
                ],
              ),
            ),
            if (controller.isMatchClient)
              Positioned(
                top: 52,
                left: 0,
                right: 0,
                child: Obx(() {
                  final left = controller.matchSecondsLeft.value;
                  if (left > 10) return const SizedBox.shrink();
                  return Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        left <= 0
                            ? 'Tiempo agotado'
                            : 'Match termina en $left s',
                        style: TextStyleCustom.outFitMedium500(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  );
                }),
              ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 24,
              child: Obx(() {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _RoundBtn(
                      icon: controller.liveKit.microphoneEnabled.value
                          ? Icons.mic
                          : Icons.mic_off,
                      color: Colors.white24,
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
                      color: Colors.white24,
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
  final RxInt matchSecondsLeft = 30.obs;

  late final LiveKitRoomController liveKit;
  Timer? _elapsedTimer;
  DateTime? _startedAt;
  bool _matchCountdownStarted = false;
  bool _ending = false;

  String get roomId => call.roomId ?? 'call_${call.id}';
  String get _tag => 'lk_call_${call.id}';

  bool get isMatchClient {
    if (!isMatchPreview) return false;
    final me = SessionManager.instance.getUserID();
    return call.callerId == me;
  }

  int get _matchDuration {
    final fromSettings =
        SessionManager.instance.getSettings()?.matchFreeSeconds ?? 0;
    if (matchFreeSeconds > 0) return matchFreeSeconds;
    if (fromSettings > 0) return fromSettings;
    return 30;
  }

  @override
  void onInit() {
    super.onInit();
    matchSecondsLeft.value = _matchDuration;
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
    _cleanup(notifyApi: false);
    super.onClose();
  }

  void _startElapsedTimer() {
    if (isMatchClient) {
      _startMatchCountdown();
      return;
    }
    _startedAt ??= DateTime.now();
    _elapsedTimer?.cancel();
    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final start = _startedAt;
      if (start == null) return;
      final s = DateTime.now().difference(start).inSeconds;
      final mm = (s ~/ 60).toString().padLeft(2, '0');
      final ss = (s % 60).toString().padLeft(2, '0');
      elapsedLabel.value = '$mm:$ss';
    });
  }

  void _startMatchCountdown() {
    if (!isMatchClient || _matchCountdownStarted || _ending) return;
    _matchCountdownStarted = true;
    matchSecondsLeft.value = _matchDuration;
    _elapsedTimer?.cancel();
    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_ending) return;
      final next = matchSecondsLeft.value - 1;
      matchSecondsLeft.value = next < 0 ? 0 : next;
      if (next <= 0) {
        unawaited(hangUp(showMatchRecharge: true));
      }
    });
  }

  Future<void> _start() async {
    final me = SessionManager.instance.getUser();
    if (me?.id == null || call.roomId == null || call.roomId!.isEmpty) {
      status.value = 'Invalid call room';
      return;
    }

    if (kIsWeb) {
      status.value =
          'Video call is limited on Web. Use Android/iOS for full A/V.';
      _startElapsedTimer();
      return;
    }

    try {
      ever(liveKit.statusMessage, (msg) {
        if (msg.isNotEmpty) status.value = msg;
      });
      ever(liveKit.remoteParticipants, (_) {
        if (liveKit.remoteParticipants.isNotEmpty) {
          status.value = '';
          _startElapsedTimer();
        } else if (liveKit.isConnected.value) {
          status.value = 'Waiting for peer...';
        }
      });

      await liveKit.connect(
        roomName: roomId,
        identity: '${me!.id}',
        name: me.fullname ?? me.username ?? 'user',
        publishCamera: true,
        publishMicrophone: true,
        wsUrl: liveKitWsUrl,
      );
      status.value = 'Waiting for peer...';
      // Match: el cronómetro empieza al conectar (preview cliente).
      if (isMatchClient) {
        _startMatchCountdown();
      } else {
        _startElapsedTimer();
      }
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
    final peer = call.caller?.id == SessionManager.instance.getUserID()
        ? call.callee
        : call.caller;
    final cost = call.coinsCost;
    await _cleanup(notifyApi: true);
    if (resumeLiveOnHangup) {
      final live = LivestreamScreenController.activeInstance;
      try {
        await live?.resumeLiveKitAfterCall();
      } catch (_) {}
    }
    Get.back();
    if (showMatchRecharge && isMatchClient) {
      Future.microtask(() {
        MatchRechargeDialog.show(peer: peer, callCost: cost);
      });
    }
  }

  Future<void> _cleanup({required bool notifyApi}) async {
    _elapsedTimer?.cancel();
    try {
      await liveKit.disconnect();
    } catch (_) {}
    if (Get.isRegistered<LiveKitRoomController>(tag: _tag)) {
      Get.delete<LiveKitRoomController>(tag: _tag);
    }
    if (notifyApi && call.id != null && call.isAccepted) {
      try {
        await CallService.instance.end(call.id!);
      } catch (_) {}
    }
  }
}
