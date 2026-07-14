import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krimson/screen/create_feed_screen/create_feed_screen.dart';
import 'package:krimson/screen/create_feed_screen/create_feed_screen_controller.dart';
import 'package:krimson/utilities/theme_res.dart';

class ReelPreviewCard extends StatelessWidget {
  final CreateFeedScreenController controller;

  const ReelPreviewCard({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    if (controller.createType != CreateFeedType.reel) {
      return const SizedBox.shrink();
    }

    return Obx(() {
      final video = controller.video.value;
      final content = controller.content.value;

      Widget preview;
      if (video != null) {
        preview = FutureBuilder<Uint8List>(
          future: video.thumbnail.readAsBytes(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return Container(color: bgGrey(context), height: 220);
            }
            return Image.memory(
              snapshot.data!,
              height: 220,
              width: double.infinity,
              fit: BoxFit.cover,
            );
          },
        );
      } else if (content?.thumbnailBytes != null) {
        preview = Image.memory(
          content!.thumbnailBytes!,
          height: 220,
          width: double.infinity,
          fit: BoxFit.cover,
        );
      } else {
        preview = Container(
          height: 220,
          width: double.infinity,
          color: bgGrey(context),
          alignment: Alignment.center,
          child: Icon(Icons.videocam_outlined,
              size: 48, color: textLightGrey(context)),
        );
      }

      return preview;
    });
  }
}
