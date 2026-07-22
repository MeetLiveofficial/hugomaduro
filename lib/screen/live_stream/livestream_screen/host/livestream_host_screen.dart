import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krimson/common/widget/livekit/livekit_video_view.dart';
import 'package:krimson/model/livestream/livestream.dart';
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

  const LivestreamHostScreen({
    super.key,
    required this.isHost,
    required this.livestream,
    this.initialBeautyOn = false,
    this.initialWhiten = 50,
    this.initialRosy = 40,
    this.initialSmooth = 55,
    this.initialSharpen = 35,
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
      controller.beautyPrefsApplied = true;
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
                if (lk != null && lk.isConnected.value) {
                  return Obx(() {
                    lk.mediaRevision.value;
                    if (c.isBattleRunning.value) {
                      return LiveBattleSplitView(controller: c);
                    }
                    return LiveKitParticipantVideo(
                      participant: lk.localParticipant.value,
                      mirror: true,
                    );
                  });
                }
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Obx(() {
                      final busy = lk?.isConnecting.value == true;
                      final msg = c.statusMessage.value.isEmpty
                          ? 'You are live'
                          : c.statusMessage.value;
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (busy)
                            const Padding(
                              padding: EdgeInsets.only(bottom: 16),
                              child: CircularProgressIndicator(
                                color: Colors.white70,
                                strokeWidth: 2.5,
                              ),
                            ),
                          Text(
                            msg,
                            textAlign: TextAlign.center,
                            style: TextStyleCustom.outFitRegular400(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                          if (!busy &&
                              (lk == null || lk.isConnected.value != true)) ...[
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
                      );
                    }),
                  ),
                );
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
