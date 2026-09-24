import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krimson/common/manager/app_role.dart';
import 'package:krimson/languages/languages_keys.dart';
import 'package:krimson/screen/dashboard_screen/dashboard_screen_controller.dart';
import 'package:krimson/utilities/client_colors.dart';
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
      if (AppRole.isClient()) {
        Widget pill(String label, bool selected, VoidCallback onTap) {
          return GestureDetector(
            onTap: onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: selected ? const Color(0xFF27D3F5) : Colors.transparent,
                boxShadow: selected
                    ? ClientColors.neonGlow(
                        color: const Color(0xFF27D3F5),
                        alpha: 0.5,
                        blur: 12,
                        offset: Offset.zero,
                      )
                    : null,
              ),
              child: Text(
                label.toUpperCase(),
                style: selected
                    ? TextStyleCustom.unboundedBold700(
                        color: Colors.white,
                        fontSize: 13,
                      )
                    : TextStyleCustom.outFitMedium500(
                        color: Colors.white.withValues(alpha: 0.55),
                        fontSize: 13,
                      ),
              ),
            ),
          );
        }

        return Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: ClientColors.surfaceDarkAlt.withValues(alpha: 0.82),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: ClientColors.primary.withValues(alpha: 0.28),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              pill(firstLabel, onHome && mode == HomeTabMode.live, () {
                dash.setHomeTabMode(HomeTabMode.live);
                dash.onChanged(DashboardScreenController.tabHome);
              }),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  '|',
                  style: TextStyleCustom.outFitRegular400(
                    color: Colors.white24,
                    fontSize: 13,
                  ),
                ),
              ),
              pill(LKey.reels.tr, onHome && mode == HomeTabMode.reels, () {
                dash.setHomeTabMode(HomeTabMode.reels);
                dash.onChanged(DashboardScreenController.tabHome);
              }),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  '|',
                  style: TextStyleCustom.outFitRegular400(
                    color: Colors.white24,
                    fontSize: 13,
                  ),
                ),
              ),
              pill(LKey.posts.tr, onHome && mode == HomeTabMode.feed, () {
                dash.setHomeTabMode(HomeTabMode.feed);
                dash.onChanged(DashboardScreenController.tabHome);
              }),
            ],
          ),
        );
      }
      const magenta = Color(0xFFE879F9);
      return Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: const Color(0xCC140818),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: magenta.withValues(alpha: 0.55)),
          boxShadow: [
            BoxShadow(
              color: magenta.withValues(alpha: 0.35),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
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
              child: IgnorePointer(child: SizedBox.shrink()),
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
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: selected
            ? BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF4D9A), Color(0xFFB140D8)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFE879F9).withValues(alpha: 0.45),
                    blurRadius: 10,
                  ),
                ],
              )
            : null,
        child: Text(
          label.toUpperCase(),
          style: selected
              ? TextStyleCustom.unboundedBold700(
                  color: selectedColor,
                  fontSize: 13,
                )
              : TextStyleCustom.outFitMedium500(
                  color: unselectedColor,
                  fontSize: 13,
                ),
        ),
      ),
    );
  }
}
