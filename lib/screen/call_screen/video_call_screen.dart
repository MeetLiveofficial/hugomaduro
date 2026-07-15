import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krimson/common/controller/base_controller.dart';
import 'package:krimson/common/manager/session_manager.dart';
import 'package:krimson/common/service/api/call_service.dart';
import 'package:krimson/languages/languages_keys.dart';
import 'package:krimson/model/call/call_request_model.dart';
import 'package:krimson/utilities/text_style_custom.dart';
import 'package:krimson/utilities/theme_res.dart';
import 'package:zego_express_engine/zego_express_engine.dart';

class VideoCallScreen extends StatelessWidget {
  final CallRequestModel call;

  const VideoCallScreen({super.key, required this.call});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(VideoCallController(call), tag: 'call_${call.id}');
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: Obx(() {
                final remote = controller.remoteView.value;
                if (remote != null) return remote;
                return Center(
                  child: Text(
                    controller.status.value,
                    style: TextStyleCustom.outFitRegular400(
                        color: whitePure(context), fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                );
              }),
            ),
            Positioned(
              right: 16,
              top: 16,
              width: 110,
              height: 160,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Obx(() => controller.localView.value ??
                    Container(color: Colors.black54)),
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 24,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _RoundBtn(
                    icon: Icons.call_end,
                    color: Colors.red,
                    onTap: controller.hangUp,
                  ),
                ],
              ),
            ),
            Positioned(
              left: 16,
              top: 16,
              child: Text(
                LKey.videoCall.tr,
                style: TextStyleCustom.outFitMedium500(
                    color: whitePure(context), fontSize: 16),
              ),
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
  VideoCallController(this.call);

  final CallRequestModel call;
  final Rxn<Widget> localView = Rxn<Widget>();
  final Rxn<Widget> remoteView = Rxn<Widget>();
  final RxString status = 'Connecting...'.obs;

  int? localViewId;
  int? remoteViewId;
  String? localStreamId;
  String? remoteStreamId;
  String get roomId => call.roomId ?? 'call_${call.id}';

  @override
  void onReady() {
    super.onReady();
    _start();
  }

  @override
  void onClose() {
    _cleanup(notifyApi: false);
    super.onClose();
  }

  Future<void> _start() async {
    final me = SessionManager.instance.getUser();
    if (me?.id == null || call.roomId == null) {
      status.value = 'Invalid call room';
      return;
    }

    localStreamId = '${roomId}_${me!.id}';

    ZegoExpressEngine.onRoomStreamUpdate = (roomID, updateType, streamList, _) async {
      if (roomID != roomId) return;
      if (updateType == ZegoUpdateType.Add) {
        for (final stream in streamList) {
          if (stream.streamID == localStreamId) continue;
          await _playRemote(stream.streamID);
        }
      } else if (updateType == ZegoUpdateType.Delete) {
        for (final stream in streamList) {
          if (stream.streamID == remoteStreamId) {
            await _stopRemote();
            status.value = 'Peer left';
          }
        }
      }
    };

    try {
      final zegoUser = ZegoUser('${me.id}', me.fullname ?? me.username ?? 'user');
      await ZegoExpressEngine.instance.loginRoom(
        roomId,
        zegoUser,
        config: ZegoRoomConfig.defaultConfig()..isUserStatusNotify = true,
      );

      localView.value =
          await ZegoExpressEngine.instance.createCanvasView((id) async {
        localViewId = id;
        await ZegoExpressEngine.instance.startPreview(
          canvas: ZegoCanvas(id, viewMode: ZegoViewMode.AspectFill),
        );
        await ZegoExpressEngine.instance
            .startPublishingStream(localStreamId!);
      });
      status.value = 'Waiting for peer...';
    } catch (e) {
      status.value = e.toString();
      if (!kIsWeb) {
        showSnackBar(e.toString());
      }
    }
  }

  Future<void> _playRemote(String streamId) async {
    remoteStreamId = streamId;
    remoteView.value =
        await ZegoExpressEngine.instance.createCanvasView((id) async {
      remoteViewId = id;
      await ZegoExpressEngine.instance.startPlayingStream(
        streamId,
        canvas: ZegoCanvas(id, viewMode: ZegoViewMode.AspectFill),
      );
    });
    status.value = '';
  }

  Future<void> _stopRemote() async {
    if (remoteStreamId != null) {
      try {
        await ZegoExpressEngine.instance.stopPlayingStream(remoteStreamId!);
      } catch (_) {}
    }
    if (remoteViewId != null) {
      try {
        await ZegoExpressEngine.instance.destroyCanvasView(remoteViewId!);
      } catch (_) {}
    }
    remoteView.value = null;
    remoteViewId = null;
    remoteStreamId = null;
  }

  Future<void> hangUp() async {
    await _cleanup(notifyApi: true);
    Get.back();
  }

  Future<void> _cleanup({required bool notifyApi}) async {
    try {
      await ZegoExpressEngine.instance.stopPublishingStream();
      await ZegoExpressEngine.instance.stopPreview();
    } catch (_) {}
    await _stopRemote();
    if (localViewId != null) {
      try {
        await ZegoExpressEngine.instance.destroyCanvasView(localViewId!);
      } catch (_) {}
      localViewId = null;
    }
    try {
      await ZegoExpressEngine.instance.logoutRoom(roomId);
    } catch (_) {}
    ZegoExpressEngine.onRoomStreamUpdate = null;
    if (notifyApi && call.id != null && call.isAccepted) {
      try {
        await CallService.instance.end(call.id!);
      } catch (_) {}
    }
  }
}
