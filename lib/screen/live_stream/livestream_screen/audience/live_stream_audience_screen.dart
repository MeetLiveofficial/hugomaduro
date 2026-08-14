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
                return Obx(() {
                  final connected = lk?.isConnected.value == true;
                  lk?.mediaRevision.value;
                  c.pausedForCall.value;
                  if (connected && lk != null) {
                    if (c.isBattleRunning.value) {
                      return LiveBattleSplitView(controller: c);
                    }
                    final remotes = lk.remoteParticipants.toList();
                    if (remotes.isEmpty) {
                      // Rival de PK puede ser el único local publicando.
                      if (c.isBattleOpponentPublisher &&
                          lk.localParticipant.value != null) {
                        return LiveKitParticipantVideo(
                          participant: lk.localParticipant.value,
                          mirror: true,
                        );
                      }
                      final absent = c.hostAbsent.value;
                      final left = c.hostAbsentSecondsLeft.value;
                      final msg = absent
                          ? (left > 0
                              ? 'Host desconectado…\nBuscando otro LIVE en $left s'
                              : 'Buscando otro LIVE…')
                          : (c.statusMessage.value.isEmpty
                              ? 'Waiting for host…'
                              : c.statusMessage.value);
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 28),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (absent)
                                const Padding(
                                  padding: EdgeInsets.only(bottom: 14),
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
                              if (absent) ...[
                                const SizedBox(height: 16),
                                TextButton(
                                  onPressed: c.leaveAndRedirectToNextLive,
                                  style: TextButton.styleFrom(
                                    backgroundColor:
                                        ColorRes.themeAccentSolid,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 18,
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(22),
                                    ),
                                  ),
                                  child: Text(
                                    'Ver otro LIVE',
                                    style: TextStyleCustom.outFitMedium500(
                                      color: Colors.white,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    }
                    return LiveKitParticipantVideo(
                      participant: remotes.first,
                    );
                  }
                  if (c.pausedForCall.value) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      c.ensureLiveKitAfterCallIfNeeded();
                    });
                  }
                  final busy = lk?.isConnecting.value == true ||
                      c.pausedForCall.value;
                  final failed =
                      c.statusMessage.value.contains('Reintentar') ||
                          c.statusMessage.value.contains('No se pudo');
                  final msg = c.statusMessage.value.isEmpty
                      ? (busy
                          ? 'Reconectando al LIVE…'
                          : 'Conectando al LIVE…')
                      : c.statusMessage.value;
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 28),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (busy || !failed)
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
                          if (failed && !busy) ...[
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
                              label: Text(
                                'Reintentar',
                                style: TextStyleCustom.outFitMedium500(
                                  color: Colors.white,
                                  fontSize: 13,
                                ),
                              ),
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
              showHostControls: false,
              onClose: controller.endOrLeave,
            ),
          ],
        ),
      ),
    );
  }
}
