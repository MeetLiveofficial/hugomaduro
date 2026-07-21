import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krimson/common/widget/livekit/livekit_video_view.dart';
import 'package:krimson/model/livestream/livestream.dart';
import 'package:krimson/screen/live_stream/livestream_screen/livestream_screen_controller.dart';
import 'package:krimson/screen/live_stream/livestream_screen/widget/live_stream_overlay.dart';
import 'package:krimson/utilities/color_res.dart';
import 'package:krimson/utilities/text_style_custom.dart';
import 'package:video_player/video_player.dart';

class LiveStreamAudienceScreen extends StatelessWidget {
  final bool isHost;
  final Livestream livestream;

  const LiveStreamAudienceScreen({
    super.key,
    required this.isHost,
    required this.livestream,
  });

  @override
  Widget build(BuildContext context) {
    final tag = 'live_audience_${livestream.roomID}';
    final controller = Get.put(
      LivestreamScreenController(isHost: false, livestream: livestream),
      tag: tag,
    );

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) controller.endOrLeave();
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
                    final remotes = lk.remoteParticipants.toList();
                    if (remotes.isEmpty) {
                      return Center(
                        child: Text(
                          c.statusMessage.value.isEmpty
                              ? 'Waiting for host…'
                              : c.statusMessage.value,
                          textAlign: TextAlign.center,
                          style: TextStyleCustom.outFitRegular400(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      );
                    }
                    return LiveKitParticipantVideo(
                      participant: remotes.first,
                    );
                  });
                }
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Obx(() {
                      final busy = lk?.isConnecting.value == true;
                      final msg = c.statusMessage.value.isEmpty
                          ? 'Conectando al LIVE…'
                          : c.statusMessage.value;
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (busy)
                            const Padding(
                              padding: EdgeInsets.only(bottom: 16),
                              child: CircularProgressIndicator(
                                color: ColorRes.themeAccentSolid,
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
                          const SizedBox(height: 16),
                          if (!busy)
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
                              label: Text(
                                'Reintentar',
                                style: TextStyleCustom.outFitMedium500(
                                  color: Colors.white,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                        ],
                      );
                    }),
                  ),
                );
              },
            ),
            LiveStreamOverlay(
              controller: controller,
              showHostControls: false,
              onClose: controller.endOrLeave,
            ),
          ],
        ),
      ),
    );
  }
}
