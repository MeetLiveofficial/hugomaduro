import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krimson/common/widget/livekit/livekit_video_view.dart';
import 'package:krimson/model/livestream/livestream.dart';
import 'package:krimson/screen/live_stream/livestream_screen/livestream_screen_controller.dart';
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
                    // Audiencia: video del host (primer remoto con track).
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
                  child: Obx(() => Text(
                        c.statusMessage.value.isEmpty
                            ? 'Connecting…'
                            : c.statusMessage.value,
                        textAlign: TextAlign.center,
                        style: TextStyleCustom.outFitRegular400(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      )),
                );
              },
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: controller.endOrLeave,
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                    ),
                    Expanded(
                      child: Text(
                        livestream.description ?? 'Live',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyleCustom.outFitMedium500(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.redAccent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'LIVE',
                        style: TextStyleCustom.outFitMedium500(
                          color: Colors.white,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
