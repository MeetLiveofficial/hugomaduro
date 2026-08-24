import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krimson/common/widget/livekit/livekit_video_view.dart';
import 'package:krimson/languages/languages_keys.dart';
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
                return Obx(() {
                  c.pausedForCall.value;
                  c.hostInCall.value;
                  if (c.pausedForCall.value) {
                    return LivePausedForCallPane(controller: c);
                  }
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
                  final connected = lk?.isConnected.value == true;
                  lk?.mediaRevision.value;
                  if (connected && lk != null) {
                    if (c.isBattleRunning.value) {
                      return LiveBattleSplitView(controller: c);
                    }
                    final remotes = lk.remoteParticipants.toList();
                    if (remotes.isEmpty) {
                      if (c.isBattleOpponentPublisher &&
                          lk.localParticipant.value != null) {
                        return LiveKitParticipantVideo(
                          participant: lk.localParticipant.value,
                          mirror: true,
                        );
                      }
                      final absent = c.hostAbsent.value;
                      final left = c.hostAbsentSecondsLeft.value;
                      final hostBusy = c.hostInCall.value;
                      final msg = hostBusy
                          ? LKey.livePausedHostInCall.tr
                          : (absent
                              ? (left > 0
                                  ? LKey.hostDisconnectedSeeking.trParams(
                                      {'sec': '$left'},
                                    )
                                  : LKey.searchingAnotherLive.tr)
                              : (c.statusMessage.value.isEmpty
                                  ? LKey.waitingForHost.tr
                                  : c.statusMessage.value));
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 28),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (absent && !hostBusy)
                                const Padding(
                                  padding: EdgeInsets.only(bottom: 14),
                                  child: CircularProgressIndicator(
                                    color: ColorRes.themeAccentSolid,
                                    strokeWidth: 2.5,
                                  ),
                                ),
                              if (hostBusy)
                                const Padding(
                                  padding: EdgeInsets.only(bottom: 14),
                                  child: Icon(
                                    Icons.pause_circle_filled_rounded,
                                    color: Colors.white70,
                                    size: 56,
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
                              if (absent && !hostBusy) ...[
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
                    if (c.hostInCall.value) {
                      return ColoredBox(
                        color: const Color(0xFF140E18),
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 28),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.pause_circle_filled_rounded,
                                  color: Colors.white70,
                                  size: 56,
                                ),
                                const SizedBox(height: 14),
                                Text(
                                  LKey.livePausedHostInCall.tr,
                                  textAlign: TextAlign.center,
                                  style: TextStyleCustom.outFitRegular400(
                                    color: Colors.white70,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }
                    return LiveKitParticipantVideo(
                      participant: remotes.first,
                    );
                  }
                  final busy = lk?.isConnecting.value == true;
                  final failed =
                      c.statusMessage.value.contains('Reintentar') ||
                          c.statusMessage.value.contains('No se pudo');
                  final msg = c.statusMessage.value.isEmpty
                      ? (c.hostInCall.value
                          ? LKey.livePausedHostInCall.tr
                          : (busy
                              ? 'Reconectando al LIVE…'
                              : 'Conectando al LIVE…'))
                      : c.statusMessage.value;
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 28),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (c.hostInCall.value)
                            const Padding(
                              padding: EdgeInsets.only(bottom: 16),
                              child: Icon(
                                Icons.pause_circle_filled_rounded,
                                color: Colors.white70,
                                size: 56,
                              ),
                            )
                          else if (busy || !failed)
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
                          if (failed && !busy && !c.hostInCall.value) ...[
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
