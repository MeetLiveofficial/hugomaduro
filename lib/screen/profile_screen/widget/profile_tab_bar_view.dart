import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krimson/languages/languages_keys.dart';
import 'package:krimson/screen/profile_screen/profile_screen_controller.dart';
import 'package:krimson/utilities/asset_res.dart';
import 'package:krimson/utilities/color_res.dart';
import 'package:krimson/utilities/style_res.dart';
import 'package:krimson/utilities/text_style_custom.dart';
import 'package:krimson/utilities/theme_res.dart';

class ProfileTabs extends StatelessWidget {
  final ProfileScreenController controller;

  const ProfileTabs({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final selected = controller.selectedTabIndex.value;
      return Container(
        height: 44,
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: bgGrey(context), width: 1),
          ),
        ),
        child: Row(
          children: [
            _TabItem(
              label: LKey.posts.tr,
              icon: AssetRes.icPost,
              isSelected: selected == 0,
              onTap: () {
                controller.onTabChanged(0);
                if (controller.pageController.hasClients) {
                  controller.pageController.animateToPage(
                    0,
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                  );
                }
              },
            ),
            _TabItem(
              label: LKey.reels.tr,
              icon: AssetRes.icReel,
              isSelected: selected == 1,
              onTap: () {
                controller.onTabChanged(1);
                if (controller.pageController.hasClients) {
                  controller.pageController.animateToPage(
                    1,
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                  );
                }
              },
            ),
          ],
        ),
      );
    });
  }
}

class _TabItem extends StatelessWidget {
  final String label;
  final String icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _TabItem({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color =
        isSelected ? ColorRes.crimson : textLightGrey(context);
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(icon, height: 18, width: 18, color: color),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: TextStyleCustom.outFitMedium500(
                      color: color,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              height: 2,
              margin: const EdgeInsets.symmetric(horizontal: 24),
              decoration: BoxDecoration(
                gradient: isSelected ? StyleRes.themeGradient : null,
                color: isSelected ? null : Colors.transparent,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
