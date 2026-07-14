import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krimson/utilities/text_style_custom.dart';
import 'package:krimson/utilities/theme_res.dart';

class SettingIconTextWithArrow extends StatelessWidget {
  final String icon;
  final String title;
  final VoidCallback? onTap;
  final Widget? widget;

  const SettingIconTextWithArrow({
    super.key,
    required this.icon,
    required this.title,
    this.onTap,
    this.widget,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Image.asset(
              icon,
              width: 22,
              height: 22,
              color: textDarkGrey(context),
              errorBuilder: (_, __, ___) => Icon(
                Icons.settings,
                size: 22,
                color: textDarkGrey(context),
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
                  color: textLightGrey(context),
                ),
          ],
        ),
      ),
    );
  }
}
