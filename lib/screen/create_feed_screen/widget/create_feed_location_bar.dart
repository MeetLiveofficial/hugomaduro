import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krimson/languages/languages_keys.dart';
import 'package:krimson/screen/create_feed_screen/create_feed_screen_controller.dart';
import 'package:krimson/utilities/asset_res.dart';
import 'package:krimson/utilities/text_style_custom.dart';
import 'package:krimson/utilities/theme_res.dart';

class CreateFeedLocationBar extends StatelessWidget {
  final CreateFeedScreenController controller;

  const CreateFeedLocationBar({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final place = controller.selectedLocation.value;
      return InkWell(
        onTap: () {
          // Location sheet is still a stub; keep selection UI state clear.
          Get.snackbar(
            LKey.location.tr,
            LKey.locationServicesDisabledDescription.tr,
            snackPosition: SnackPosition.BOTTOM,
            duration: const Duration(seconds: 2),
          );
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: bgGrey(context)),
            ),
          ),
          child: Row(
            children: [
              Image.asset(
                AssetRes.icLocation,
                height: 20,
                width: 20,
                color: textDarkGrey(context),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  place?.name ?? LKey.location.tr,
                  style: TextStyleCustom.outFitRegular400(
                    color: place == null
                        ? textLightGrey(context)
                        : textDarkGrey(context),
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (place != null)
                InkWell(
                  onTap: () => controller.selectedLocation.value = null,
                  child: Icon(Icons.close, size: 18, color: textLightGrey(context)),
                ),
            ],
          ),
        ),
      );
    });
  }
}
