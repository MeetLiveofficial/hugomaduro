import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krimson/model/livestream/livestream.dart';
import 'package:krimson/screen/live_stream/livestream_screen/livestream_screen_controller.dart';
import 'package:krimson/screen/live_stream/livestream_screen/widget/live_host_panel.dart';
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
    // Solo aplicar prefs iniciales una vez (antes de que Zego aplique beauty).
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
                if (c.zegoView != null) return c.zegoView!;
                return Center(
                  child: Obx(() => Text(
                        c.statusMessage.value.isEmpty
                            ? 'You are live'
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
                child: Column(
                  children: [
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => controller.confirmExit(context),
                          icon: const Icon(Icons.close, color: Colors.white),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
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
                              const SizedBox(height: 4),
                              Text(
                                livestream.description ?? '',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyleCustom.outFitMedium500(
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Obx(() => Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.black45,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.wifi,
                                      color: Colors.amber, size: 16),
                                  const SizedBox(width: 4),
                                  Text(
                                    controller.networkLabel.value,
                                    style: TextStyleCustom.outFitRegular400(
                                      color: Colors.white,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            )),
                        TextButton(
                          onPressed: () => controller.confirmExit(context),
                          child: Text(
                            'End',
                            style: TextStyleCustom.outFitMedium500(
                              color: Colors.redAccent,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    LiveHostActionBar(
                      onBeauty: controller.openBeauty,
                      onInvite: controller.openInvite,
                      networkLabel: controller.networkLabel,
                    ),
                    const SizedBox(height: 8),
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
