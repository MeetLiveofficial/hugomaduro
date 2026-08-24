import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krimson/common/manager/app_role.dart';
import 'package:krimson/common/widget/shine_sweep.dart';
import 'package:krimson/languages/languages_keys.dart';
import 'package:krimson/screen/dashboard_screen/dashboard_screen_controller.dart';
import 'package:krimson/utilities/client_colors.dart';
import 'package:krimson/utilities/streamer_colors.dart';
import 'package:krimson/utilities/style_res.dart';
import 'package:krimson/utilities/text_style_custom.dart';

/// LIVE | REELS | POSTS dentro del tab Home.
class HomeModeSwitcher extends StatelessWidget {
  const HomeModeSwitcher({super.key});

  @override
  Widget build(BuildContext context) {
    final dash = Get.find<DashboardScreenController>();
    const active = Colors.white;
    final inactive = Colors.white.withValues(alpha: 0.72);
    final firstLabel = LKey.liveTab.tr;

    return Obx(() {
      final mode = dash.homeTabMode.value;
      final onHome =
          dash.selectedPageIndex.value == DashboardScreenController.tabHome;
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: StyleRes.brandAccent.withValues(alpha: 0.42),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: (AppRole.isClient()
                      ? ClientColors.primaryActive
                      : StreamerColors.primaryActive)
                  .withValues(alpha: 0.28),
              blurRadius: 20,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                gradient: StyleRes.themeGradient,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _Chip(
                    label: firstLabel,
                    selected: onHome && mode == HomeTabMode.live,
                    selectedColor: active,
                    unselectedColor: inactive,
                    onTap: () {
                      dash.setHomeTabMode(HomeTabMode.live);
                      dash.onChanged(DashboardScreenController.tabHome);
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Text(
                      '|',
                      style: TextStyleCustom.outFitRegular400(
                        color: inactive,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  _Chip(
                    label: LKey.reels.tr,
                    selected: onHome && mode == HomeTabMode.reels,
                    selectedColor: active,
                    unselectedColor: inactive,
                    onTap: () {
                      dash.setHomeTabMode(HomeTabMode.reels);
                      dash.onChanged(DashboardScreenController.tabHome);
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Text(
                      '|',
                      style: TextStyleCustom.outFitRegular400(
                        color: inactive,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  _Chip(
                    label: LKey.posts.tr,
                    selected: onHome && mode == HomeTabMode.feed,
                    selectedColor: active,
                    unselectedColor: inactive,
                    onTap: () {
                      dash.setHomeTabMode(HomeTabMode.feed);
                      dash.onChanged(DashboardScreenController.tabHome);
                    },
                  ),
                ],
              ),
            ),
            const Positioned.fill(
              child: IgnorePointer(child: ShineSweep()),
            ),
          ],
        ),
        ),
      );
    });
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color selectedColor;
  final Color unselectedColor;
  final VoidCallback onTap;

  const _Chip({
    required this.label,
    required this.selected,
    required this.selectedColor,
    required this.unselectedColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Text(
        label.toUpperCase(),
        style: selected
            ? TextStyleCustom.unboundedBold700(
                color: selectedColor,
                fontSize: 14,
              )
            : TextStyleCustom.outFitMedium500(
                color: unselectedColor,
                fontSize: 13,
              ),
      ),
    );
  }
}
