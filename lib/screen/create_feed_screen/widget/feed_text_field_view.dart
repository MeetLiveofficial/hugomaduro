import 'package:detectable_text_field/widgets/detectable_text_field.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krimson/languages/languages_keys.dart';
import 'package:krimson/screen/create_feed_screen/create_feed_screen_controller.dart';
import 'package:krimson/utilities/text_style_custom.dart';
import 'package:krimson/utilities/theme_res.dart';

class FeedTextFieldView extends StatelessWidget {
  const FeedTextFieldView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<CreateFeedScreenController>();
    final helper = controller.commentHelper;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: whitePure(context),
      child: DetectableTextField(
        controller: helper.detectableTextController,
        focusNode: helper.detectableTextFocusNode,
        minLines: 3,
        maxLines: 8,
        onChanged: helper.onChanged,
        style: TextStyleCustom.outFitRegular400(
          color: textDarkGrey(context),
          fontSize: 16,
        ),
        decoration: InputDecoration(
          hintText: LKey.writeSomethingHere.tr,
          hintStyle: TextStyleCustom.outFitRegular400(
            color: textLightGrey(context),
            fontSize: 16,
          ),
          border: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.zero,
        ),
      ),
    );
  }
}
