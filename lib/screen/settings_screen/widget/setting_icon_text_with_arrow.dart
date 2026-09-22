import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krimson/common/manager/app_role.dart';
import 'package:krimson/common/widget/client_icon_box.dart';
import 'package:krimson/utilities/client_colors.dart';
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
    final client = AppRole.isClient();
    final accent = iconColor ??
        (client ? ClientColors.primary : themeAccentSolid(context));
    final row = InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(client ? 16 : 0),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: client ? 14 : 16,
          vertical: client ? 12 : 10,
        ),
        child: Row(
          children: [
            client
                ? ClientIconBox(asset: icon, accent: accent)
                : Container(
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
                  color: client ? ClientColors.text : textDarkGrey(context),
                ),
              ),
            ),
            widget ??
                Icon(
                  Icons.chevron_right,
                  color: client
                      ? ClientColors.primary.withValues(alpha: 0.85)
                      : accent.withValues(alpha: 0.7),
                ),
          ],
        ),
      ),
    );

    if (!client) return row;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 5, 12, 5),
      decoration: ClientColors.glass(),
      child: row,
    );
  }
}
