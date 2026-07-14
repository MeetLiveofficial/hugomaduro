import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krimson/common/widget/custom_image.dart';
import 'package:krimson/screen/comment_sheet/helper/comment_helper.dart';
import 'package:krimson/screen/create_feed_screen/create_feed_screen_controller.dart';
import 'package:krimson/utilities/text_style_custom.dart';
import 'package:krimson/utilities/theme_res.dart';

class UrlMetaDataCard extends StatelessWidget {
  final CreateFeedScreenController controller;

  const UrlMetaDataCard({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final CommentHelper helper = controller.commentHelper;
    return Obx(() {
      final meta = helper.metaData.value;
      if (meta == null) return const SizedBox.shrink();

      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: bgLightGrey(context),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            if ((meta.image ?? '').isNotEmpty)
              CustomImage(
                size: const Size(56, 56),
                radius: 8,
                image: meta.image,
                isShowPlaceHolder: true,
              ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    meta.title ?? meta.url ?? '',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyleCustom.outFitMedium500(
                      color: textDarkGrey(context),
                      fontSize: 13,
                    ),
                  ),
                  if ((meta.description ?? '').isNotEmpty)
                    Text(
                      meta.description!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyleCustom.outFitRegular400(
                        color: textLightGrey(context),
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),
            IconButton(
              onPressed: () {
                helper.closedUrls.add(meta.url ?? '');
                helper.metaData.value = null;
              },
              icon: Icon(Icons.close, color: textLightGrey(context)),
            ),
          ],
        ),
      );
    });
  }
}
