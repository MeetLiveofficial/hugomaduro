import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krimson/languages/languages_keys.dart';
import 'package:krimson/screen/create_feed_screen/create_feed_screen_controller.dart';
import 'package:krimson/utilities/asset_res.dart';
import 'package:krimson/utilities/theme_res.dart';

class FeedImageView extends StatelessWidget {
  final RxList<ImageWithFilter> files;
  final CreateFeedScreenController controller;

  const FeedImageView({
    super.key,
    required this.files,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (files.isEmpty) return const SizedBox.shrink();

      return Column(
        children: [
          SizedBox(
            height: 280,
            width: double.infinity,
            child: PageView.builder(
              itemCount: files.length,
              onPageChanged: (index) =>
                  controller.selectedImageIndex.value = index,
              itemBuilder: (context, index) {
                final item = files[index];
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    FutureBuilder<Uint8List>(
                      future: item.media.readAsBytes(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return Container(color: bgGrey(context));
                        }
                        return Image.memory(
                          snapshot.data!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                        );
                      },
                    ),
                    Positioned(
                      top: 10,
                      right: 10,
                      child: InkWell(
                        onTap: controller.onDeleteSelectedImages,
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
                    if (files.length > 1)
                      Positioned(
                        bottom: 10,
                        left: 0,
                        right: 0,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            files.length,
                            (i) => Container(
                              width: 6,
                              height: 6,
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: i == controller.selectedImageIndex.value
                                    ? whitePure(context)
                                    : whitePure(context).withValues(alpha: 0.4),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
          if (!kIsWeb)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: TextButton.icon(
                onPressed: () => controller.onMediaTap(FeedPostType.image),
                icon: const Icon(Icons.add_photo_alternate_outlined),
                label: Text(LKey.addMore.tr),
              ),
            ),
        ],
      );
    });
  }
}
