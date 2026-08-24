import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krimson/utilities/color_res.dart';
import 'package:krimson/utilities/text_style_custom.dart';
import 'package:krimson/utilities/theme_res.dart';

class SettingIconTextWithArrow extends StatelessWidget {
  final String icon;
  final String title;
  final VoidCallback? onTap;
  final Widget? widget;
  final Color? iconColor;

  const SettingIconTextWithArrow({
    super.key,
    required this.icon,
    required this.title,
    this.onTap,
    this.widget,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final accent = iconColor ?? ColorRes.crimson;
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Image.asset(
                icon,
                width: 20,
                height: 20,
                color: accent,
                errorBuilder: (_, __, ___) => Icon(
                  Icons.settings,
                  size: 20,
                  color: accent,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title.tr,
                style: TextStyleCustom.outFitRegular400(
                  fontSize: 16,
                  color: textDarkGrey(context),
                ),
              ),
            ),
            widget ??
                Icon(
                  Icons.chevron_right,
                  color: accent.withValues(alpha: 0.7),
                ),
          ],
        ),
      ),
    );
  }
}
