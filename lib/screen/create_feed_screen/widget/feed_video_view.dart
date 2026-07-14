import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krimson/screen/create_feed_screen/create_feed_screen_controller.dart';
import 'package:krimson/utilities/asset_res.dart';
import 'package:krimson/utilities/theme_res.dart';
import 'package:video_player/video_player.dart';

class FeedVideoView extends StatelessWidget {
  final CreateFeedScreenController controller;

  const FeedVideoView({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final video = controller.video.value;
      if (video == null) return const SizedBox.shrink();

      final player = controller.videoPlayerController.value;

      return SizedBox(
        height: 280,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (player != null && player.value.isInitialized)
              FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: player.value.size.width,
                  height: player.value.size.height,
                  child: VideoPlayer(player),
                ),
              )
            else
              FutureBuilder<Uint8List>(
                future: video.thumbnail.readAsBytes(),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    return Image.memory(snapshot.data!, fit: BoxFit.cover);
                  }
                  return Container(color: bgGrey(context));
                },
              ),
            Positioned(
              top: 10,
              right: 10,
              child: InkWell(
                onTap: () {
                  controller.videoPlayerController.value?.dispose();
                  controller.videoPlayerController.value = null;
                  controller.video.value = null;
                  controller.feedPostType.value = FeedPostType.text;
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: blackPure(context).withValues(alpha: 0.55),
                    shape: BoxShape.circle,
                  ),
                  child: Image.asset(
                    AssetRes.icDelete,
                    height: 18,
                    width: 18,
                    color: whitePure(context),
                  ),
                ),
              ),
            ),
            if (player != null && player.value.isInitialized)
              Center(
                child: IconButton(
                  onPressed: () {
                    if (player.value.isPlaying) {
                      player.pause();
                    } else {
                      player.play();
                    }
                    controller.videoPlayerController.refresh();
                  },
                  icon: Icon(
                    player.value.isPlaying
                        ? Icons.pause_circle_filled
                        : Icons.play_circle_filled,
                    color: whitePure(context),
                    size: 48,
                  ),
                ),
              ),
            if (kIsWeb && (player == null || !player.value.isInitialized))
              const Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Text(
                    'Video selected — preview may be limited on web',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ),
              ),
          ],
        ),
      );
    });
  }
}
