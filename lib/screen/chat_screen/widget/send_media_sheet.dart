import 'package:figma_squircle_updated/figma_squircle.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:krimson/common/widget/bottom_sheet_top_view.dart';
import 'package:krimson/languages/languages_keys.dart';
import 'package:krimson/screen/chat_screen/chat_screen_controller.dart';
import 'package:krimson/screen/chat_screen/widget/chat_bottom_action_view.dart';
import 'package:krimson/screen/chat_screen/widget/chat_media_helpers.dart';
import 'package:krimson/utilities/theme_res.dart';

class SendMediaSheet extends StatelessWidget {
  final String image;
  final XFile? imageFile;
  final VoidCallback onSendBtnClick;
  final ChatScreenController controller;

  const SendMediaSheet({
    super.key,
    required this.image,
    required this.onSendBtnClick,
    required this.controller,
    this.imageFile,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(top: AppBar().preferredSize.height * 2.5),
      decoration: ShapeDecoration(
          shape: const SmoothRectangleBorder(
              borderRadius: SmoothBorderRadius.vertical(
                  top: SmoothRadius(cornerRadius: 40, cornerSmoothing: 1))),
          color: scaffoldBackgroundColor(context)),
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.only(bottom: 20),
        child: Column(
          children: [
            BottomSheetTopView(title: LKey.sendMedia.tr),
            Flexible(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: ClipSmoothRect(
                  radius: SmoothBorderRadius(
                      cornerRadius: 15, cornerSmoothing: 1),
                  child: SafePickedImage(
                    path: image,
                    xFile: imageFile ?? XFile(image),
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            ChatTextField(
              controller: controller.mediaTextController,
              isTextEmpty: false.obs,
              onSendTextMessage: onSendBtnClick,
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}
