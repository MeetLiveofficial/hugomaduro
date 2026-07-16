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

  const VideoCallScreen({
    super.key,
    required this.call,
    this.resumeLiveOnHangup = false,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(
      VideoCallController(call, resumeLiveOnHangup: resumeLiveOnHangup),
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
                    LKey.videoCall.tr,
                    style: TextStyleCustom.outFitMedium500(
                        color: whitePure(context), fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Obx(() => Text(
                        controller.elapsedLabel.value,
                        style: TextStyleCustom.outFitRegular400(
                          color: whitePure(context).withValues(alpha: 0.8),
                          fontSize: 13,
                        ),
                      )),
                ],
              ),
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
  VideoCallController(this.call, {this.resumeLiveOnHangup = false});

  final CallRequestModel call;
  final bool resumeLiveOnHangup;
  final RxString status = 'Connecting...'.obs;
  final RxString elapsedLabel = '00:00'.obs;

  late final LiveKitRoomController liveKit;
  Timer? _elapsedTimer;
  DateTime? _startedAt;

  String get roomId => call.roomId ?? 'call_${call.id}';
  String get _tag => 'lk_call_${call.id}';

  @override
  void onInit() {
    super.onInit();
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
      _startElapsedTimer();
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

  Future<void> hangUp() async {
    await _cleanup(notifyApi: true);
    if (resumeLiveOnHangup) {
      final live = LivestreamScreenController.activeInstance;
      try {
        await live?.resumeLiveKitAfterCall();
      } catch (_) {}
    }
    Get.back();
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
