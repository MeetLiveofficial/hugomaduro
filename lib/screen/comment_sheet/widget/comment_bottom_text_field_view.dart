import 'package:detectable_text_field/widgets/detectable_text_field.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krimson/common/extensions/string_extension.dart';
import 'package:krimson/common/manager/session_manager.dart';
import 'package:krimson/common/widget/custom_image.dart';
import 'package:krimson/languages/languages_keys.dart';
import 'package:krimson/screen/comment_sheet/comment_sheet_controller.dart';
import 'package:krimson/screen/comment_sheet/helper/comment_helper.dart';
import 'package:krimson/utilities/asset_res.dart';
import 'package:krimson/utilities/text_style_custom.dart';
import 'package:krimson/utilities/theme_res.dart';

class CommentBottomTextFieldView extends StatelessWidget {
  final CommentHelper helper;
  final bool isFromBottomSheet;

  const CommentBottomTextFieldView({
    super.key,
    required this.helper,
    this.isFromBottomSheet = true,
  });

  @override
  Widget build(BuildContext context) {
    final me = SessionManager.instance.getUser();
    final gifOn = SessionManager.instance.getSettings()?.gifSupport == 1;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Obx(() {
              if (!helper.isReplyUser.value) {
                return const SizedBox.shrink();
              }
              final reply = helper.replyComment.value;
              final username = reply?.user?.username ?? '';
              return Container(
                width: double.infinity,
                color: bgLightGrey(context),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${LKey.replyingTo.tr} @$username',
                        style: TextStyleCustom.outFitRegular400(
                          color: textDarkGrey(context),
                          fontSize: 13,
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: helper.onCloseReply,
                      child: Image.asset(
                        AssetRes.icClose,
                        width: 18,
                        height: 18,
                        color: textLightGrey(context),
                      ),
                    ),
                  ],
                ),
              );
            }),
            Container(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
              decoration: BoxDecoration(
                color: whitePure(context),
                border: Border(
                  top: BorderSide(color: bgGrey(context)),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  CustomImage(
                    size: const Size(36, 36),
                    strokeWidth: 0,
                    image: me?.profilePhoto?.addBaseURL(),
                    fullName: me?.fullname,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      constraints: const BoxConstraints(minHeight: 40),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: bgLightGrey(context),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: DetectableTextField(
                        controller: helper.detectableTextController,
                        focusNode: helper.detectableTextFocusNode,
                        minLines: 1,
                        maxLines: 4,
                        onChanged: helper.onChanged,
                        style: TextStyleCustom.outFitRegular400(
                          color: textDarkGrey(context),
                          fontSize: 15,
                        ),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 10),
                          hintText: '${LKey.writeHere.tr}..',
                          hintStyle: TextStyleCustom.outFitRegular400(
                            color: textLightGrey(context),
                            fontSize: 15,
                          ),
                        ),
                        cursorColor: themeAccentSolid(context),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Obx(() {
                    final hasText = !helper.isDetectableTextEmpty.value;
                    if (hasText) {
                      return InkWell(
                        onTap: _send,
                        borderRadius: BorderRadius.circular(20),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 8),
                          child: Text(
                            LKey.post.tr,
                            style: TextStyleCustom.unboundedMedium500(
                              fontSize: 13,
                              color: themeAccentSolid(context),
                            ),
                          ),
                        ),
                      );
                    }
                    if (gifOn) {
                      return InkWell(
                        onTap: _send,
                        borderRadius: BorderRadius.circular(20),
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Image.asset(
                            AssetRes.icSticker,
                            width: 24,
                            height: 24,
                            color: textDarkGrey(context),
                          ),
                        ),
                      );
                    }
                    return InkWell(
                      onTap: _send,
                      borderRadius: BorderRadius.circular(20),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 8),
                        child: Text(
                          LKey.post.tr,
                          style: TextStyleCustom.unboundedMedium500(
                            fontSize: 13,
                            color: textLightGrey(context),
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _send() {
    if (!Get.isRegistered<CommentSheetController>()) return;
    Get.find<CommentSheetController>().onSendComment();
  }
}
