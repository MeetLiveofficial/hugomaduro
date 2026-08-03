import 'package:figma_squircle_updated/figma_squircle.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krimson/utilities/text_style_custom.dart';
import 'package:krimson/utilities/color_res.dart';

class CustomPopupMenuButton extends StatelessWidget {
  final List<MenuItem> items;
  final Color? color;
  final Widget child;
  final Offset? offset;
  final Function(String)? onSelect;
  final VoidCallback? onOpened;
  final VoidCallback? onCanceled;

  const CustomPopupMenuButton(
      {super.key,
      required this.items,
      this.color,
      this.onSelect,
      required this.child,
      this.offset,
      this.onOpened,
      this.onCanceled});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: (value) {
        if (onSelect != null) {
          onSelect?.call(value);
        }
      },
      constraints: const BoxConstraints(maxHeight: 150),
      onOpened: onOpened,
      onCanceled: onCanceled,
      surfaceTintColor: ColorRes.whitePure,
      offset: offset ?? Offset.zero,
      color: color ?? ColorRes.whitePure,
      shadowColor: ColorRes.coralRed.withValues(alpha: 0.2),
      position: PopupMenuPosition.under,
      popUpAnimationStyle: const AnimationStyle(curve: Curves.easeOutCubic),
      shape: SmoothRectangleBorder(
        side: const BorderSide(color: ColorRes.bgGrey),
        borderRadius: const SmoothBorderRadius.all(
            SmoothRadius(cornerRadius: 10, cornerSmoothing: 1)),
      ),
      menuPadding: EdgeInsets.zero,
      itemBuilder: (context) {
        return items.map((e) {
          return PopupMenuItem<String>(
              onTap: e.onTap,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Text(e.title.tr,
                  style: TextStyleCustom.outFitRegular400(
                      fontSize: 16, color: ColorRes.textDarkGrey)));
        }).toList();
      },
      child: child,
    );
  }
}

class MenuItem {
  final String title;
  final Function()? onTap;

  MenuItem(this.title, this.onTap);
}
