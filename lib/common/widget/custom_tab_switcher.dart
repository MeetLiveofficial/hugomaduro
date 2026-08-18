import 'package:figma_squircle_updated/figma_squircle.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krimson/utilities/color_res.dart';
import 'package:krimson/utilities/style_res.dart';
import 'package:krimson/utilities/text_style_custom.dart';
import 'package:krimson/utilities/theme_res.dart';

class CustomTabSwitcher extends StatelessWidget {
  final List<String> items;
  final Function(int index) onTap;
  final RxInt selectedIndex;
  final Widget? widget;
  final int widgetTabIndex;
  /// Badges opcionales por índice de tab (p. ej. Chats/Requests/Calls).
  final Map<int, Widget>? badges;
  final EdgeInsets? margin;
  final Color? selectedFontColor;
  final Color? unselectedFontColor;
  final Color? backgroundColor;

  const CustomTabSwitcher(
      {super.key,
      required this.items,
      required this.onTap,
      required this.selectedIndex,
      this.widget,
      this.widgetTabIndex = -1,
      this.badges,
      this.margin,
      this.selectedFontColor,
      this.unselectedFontColor,
      this.backgroundColor});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Container(
        height: 48,
        width: double.infinity,
        margin: margin ?? const EdgeInsets.symmetric(vertical: 10),
        decoration: ShapeDecoration(
          color: backgroundColor ?? bgMediumGrey(context),
          shape: SmoothRectangleBorder(
            borderRadius:
                SmoothBorderRadius(cornerRadius: 10, cornerSmoothing: 1),
            side: const BorderSide(color: ColorRes.menuBorder),
          ),
        ),
        padding: const EdgeInsets.all(4),
        child: Stack(
          alignment: AlignmentDirectional.center,
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                return AnimatedAlign(
                  alignment: Alignment(
                    items.length <= 1
                        ? 0
                        : (selectedIndex.value * 2 / (items.length - 1)) - 1,
                    0,
                  ),
                  duration: const Duration(milliseconds: 300),
                  child: Container(
                    width: constraints.maxWidth / items.length,
                    decoration: ShapeDecoration(
                      shape: SmoothRectangleBorder(
                        borderRadius: SmoothBorderRadius(
                            cornerRadius: 10 - 2, cornerSmoothing: 1),
                      ),
                      gradient: StyleRes.themeGradient,
                    ),
                  ),
                );
              },
            ),
            Row(
              children: List.generate(
                items.length,
                (index) {
                  bool isSelected = selectedIndex.value == index;
                  final badge = badges?[index] ??
                      (widget != null && widgetTabIndex == index
                          ? widget
                          : null);
                  return Expanded(
                    child: InkWell(
                      onTap: () => onTap(index),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Text(
                              items[index].tr,
                              style: TextStyleCustom.outFitRegular400(
                                  color: !isSelected
                                      ? (unselectedFontColor ??
                                          textLightGrey(context))
                                      : (selectedFontColor ??
                                          ColorRes.whitePure),
                                  fontSize: 15),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                            ),
                          ),
                          if (badge != null) badge,
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
