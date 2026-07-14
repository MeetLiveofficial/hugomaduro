import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krimson/languages/languages_keys.dart';
import 'package:krimson/screen/create_feed_screen/create_feed_screen_controller.dart';
import 'package:krimson/utilities/text_style_custom.dart';
import 'package:krimson/utilities/theme_res.dart';

class FeedCommentToggle extends StatelessWidget {
  const FeedCommentToggle({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<CreateFeedScreenController>();
    return Obx(
      () => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: Text(
                LKey.allowComments.tr,
                style: TextStyleCustom.outFitMedium500(
                  color: textDarkGrey(context),
                  fontSize: 15,
                ),
              ),
            ),
            Switch(
              value: controller.canComment.value,
              activeColor: themeAccentSolid(context),
              onChanged: (value) => controller.canComment.value = value,
            ),
          ],
        ),
      ),
    );
  }
}
