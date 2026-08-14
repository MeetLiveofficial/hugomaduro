import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krimson/common/manager/livekit_room_controller.dart';
import 'package:krimson/common/widget/livekit/livekit_video_view.dart';
import 'package:krimson/model/livestream/livestream.dart';
import 'package:krimson/screen/face_filters/models/face_filter_effect.dart';
import 'package:krimson/screen/face_filters/widgets/beauty_camera_preview.dart';
import 'package:krimson/screen/deepar/deepar_runtime.dart';
import 'package:krimson/model/general/settings_model.dart';
import 'package:krimson/screen/live_stream/livestream_screen/livestream_screen_controller.dart';
import 'package:krimson/screen/live_stream/livestream_screen/widget/live_battle_split_view.dart';
import 'package:krimson/screen/live_stream/livestream_screen/widget/live_stream_overlay.dart';
import 'package:krimson/utilities/color_res.dart';
import 'package:krimson/utilities/text_style_custom.dart';
import 'package:video_player/video_player.dart';

class LivestreamHostScreen extends StatelessWidget {
  final bool isHost;
  final Livestream livestream;
  final bool initialBeautyOn;
  final double initialWhiten;
  final double initialRosy;
  final double initialSmooth;
  final double initialSharpen;
  final double initialSlimFace;
  final double initialBigEye;
  final FaceFilterId initialBeautyFilterId;
  final int? initialDeepArFilterId;

  const LivestreamHostScreen({
    super.key,
    required this.isHost,
    required this.livestream,
    this.initialBeautyOn = false,
    this.initialWhiten = 50,
    this.initialRosy = 40,
    this.initialSmooth = 55,
    this.initialSharpen = 35,
    this.initialSlimFace = 0,
    this.initialBigEye = 0,
    this.initialBeautyFilterId = FaceFilterId.none,
    this.initialDeepArFilterId,
  });

  @override
  Widget build(BuildContext context) {
    final tag = 'live_${livestream.roomID}';
    final controller = Get.put(
      LivestreamScreenController(isHost: true, livestream: livestream),
      tag: tag,
    );
    if (!controller.beautyPrefsApplied) {
      controller.beautyOn.value = initialBeautyOn;
      controller.whiten.value = initialWhiten;
      controller.rosy.value = initialRosy;
      controller.smooth.value = initialSmooth;
      controller.sharpen.value = initialSharpen;
      controller.slimFace.value = initialSlimFace;
      controller.bigEye.value = initialBigEye;
      controller.selectedBeautyFilterId.value = initialBeautyFilterId;
      controller.selectedDeepArFilterId.value = initialDeepArFilterId;
      controller.beautyPrefsApplied = true;
      // Rehidratar filtro DeepAR del pre-live (carrusel + approx beauty).
      if (initialDeepArFilterId != null) {
        DeepARFilters? match;
        for (final f in DeepArRuntime.filters()) {
          if (f.id == initialDeepArFilterId) {
            match = f;
            break;
          }
        }
        controller.onLiveDeepArFilterSelected(match);
      } else {
        controller.applyBeauty();
      }
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) controller.confirmExit(context);
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        resizeToAvoidBottomInset: true,
        body: Stack(
          fit: StackFit.expand,
          children: [
            GetBuilder<LivestreamScreenController>(
              tag: tag,
              builder: (c) {
                if (c.dummyPlayer != null &&
                    c.dummyPlayer!.value.isInitialized) {
                  return FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(
                      width: c.dummyPlayer!.value.size.width,
                      height: c.dummyPlayer!.value.size.height,
                      child: VideoPlayer(c.dummyPlayer!),
                    ),
                  );
                }
                final lk = c.liveKit;
                return Obx(() {
                  final connected = lk?.isConnected.value == true;
                  final connecting = lk?.isConnecting.value == true;
                  lk?.mediaRevision.value;
                  c.pausedForCall.value;
                  if (connected && lk != null) {
                    if (c.isBattleRunning.value) {
                      return LiveBattleSplitView(controller: c);
                    }
                    final local = lk.localParticipant.value;
                    final hasVideo = firstVideoTrackOf(local) != null;
                    if (hasVideo) {
                      return BeautyFiltered(
                        controller: c.beautyShader,
                        child: LiveKitParticipantVideo(
                          participant: local,
                          mirror: true,
                          forcePortraitUpright: false,
                        ),
                      );
                    }
                    // Cámara activándose: loading en lugar de pantalla negra.
                    if (lk.cameraEnabled.value) {
                      return const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 44,
                              height: 44,
                              child: CircularProgressIndicator(
                                color: Colors.white70,
                                strokeWidth: 2.5,
                              ),
                            ),
                            SizedBox(height: 14),
                            Text(
                              'Cargando cámara…',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    // Conectado pero sin track: permiso denegado o cámara ocupada.
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 28),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              c.statusMessage.value.isEmpty
                                  ? 'Permite la cámara en el navegador y reintenta.'
                                  : c.statusMessage.value,
                              textAlign: TextAlign.center,
                              style: TextStyleCustom.outFitRegular400(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextButton.icon(
                              onPressed: () async {
                                await c.liveKit?.setCameraEnabled(true);
                                c.update();
                              },
                              style: TextButton.styleFrom(
                                backgroundColor: ColorRes.themeAccentSolid,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 18,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(22),
                                ),
                              ),
                              icon: const Icon(Icons.videocam_rounded, size: 18),
                              label: const Text('Activar cámara'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  if (c.pausedForCall.value) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      c.ensureLiveKitAfterCallIfNeeded();
                    });
                  }
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 28),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (connecting || c.pausedForCall.value)
                            const Padding(
                              padding: EdgeInsets.only(bottom: 16),
                              child: CircularProgressIndicator(
                                color: Colors.white70,
                                strokeWidth: 2.5,
                              ),
                            ),
                          Text(
                            c.statusMessage.value.isEmpty
                                ? (c.pausedForCall.value
                                    ? 'Reconectando LIVE…'
                                    : 'You are live')
                                : c.statusMessage.value,
                            textAlign: TextAlign.center,
                            style: TextStyleCustom.outFitRegular400(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                          if (!connecting && !c.pausedForCall.value) ...[
                            const SizedBox(height: 16),
                            TextButton.icon(
                              onPressed: c.retryLiveConnection,
                              style: TextButton.styleFrom(
                                backgroundColor: ColorRes.themeAccentSolid,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 18,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(22),
                                ),
                              ),
                              icon: const Icon(Icons.refresh_rounded, size: 18),
                              label: const Text('Reintentar'),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                });
              },
            ),
            LiveStreamOverlay(
              controller: controller,
              showHostControls: true,
              onClose: () => controller.confirmExit(context),
            ),
          ],
        ),
      ),
    );
  }
}
