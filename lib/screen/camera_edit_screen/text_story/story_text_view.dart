import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krimson/screen/camera_edit_screen/camera_edit_screen_controller.dart';
import 'package:krimson/screen/camera_edit_screen/text_story/story_text_view_controller.dart';

class CameraEditImageView extends StatelessWidget {
  final CameraEditScreenController cameraEditController;

  const CameraEditImageView({super.key, required this.cameraEditController});

  @override
  Widget build(BuildContext context) {
    Get.put(StoryTextViewController());
    return Container(
      key: Get.find<StoryTextViewController>().previewContainer,
      color: Colors.black12,
      child: const Center(child: Text('CameraEditImageView')),
    );
  }
}

class StoryTextView extends StatelessWidget {
  const StoryTextView({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
