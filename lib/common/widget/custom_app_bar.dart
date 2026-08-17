import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:krimson/common/widget/custom_back_button.dart';
import 'package:krimson/utilities/color_res.dart';
import 'package:krimson/utilities/style_res.dart';
import 'package:krimson/utilities/text_style_custom.dart';
import 'package:krimson/utilities/theme_res.dart';

class CustomAppBar extends StatelessWidget {
  final String title;
  final Widget? widget;
  final Widget? rowWidget;
  final String? subTitle;
  final TextStyle? titleStyle;
  final Color? bgColor;
  final Color? iconColor;
  final bool isLoading;
  final bool showBack;

  const CustomAppBar(
      {super.key,
      required this.title,
      this.widget,
      this.subTitle,
      this.titleStyle,
      this.bgColor,
      this.iconColor,
      this.rowWidget,
      this.isLoading = false,
      this.showBack = true});

  @override
  Widget build(BuildContext context) {
    final branded = bgColor == null;
    final onBrand = branded ? ColorRes.whitePure : textDarkGrey(context);
    final onBrandMuted =
        branded ? ColorRes.whitePure.withValues(alpha: 0.82) : textLightGrey(context);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: bgColor,
        gradient: branded ? StyleRes.themeGradient : null,
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          spacing: widget != null ? 10 : 0,
          children: [
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (showBack)
                  CustomBackButton(
                    color: iconColor ?? onBrand,
                    width: 18,
                    height: 18,
                    padding: const EdgeInsets.all(15),
                  )
                else
                  const SizedBox(width: 48),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        title,
                        style: titleStyle ??
                            TextStyleCustom.unboundedMedium500(color: onBrand),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (isLoading)
                        CupertinoActivityIndicator(
                          color: onBrandMuted,
                          radius: 8,
                        )
                      else if (subTitle != null)
                        Text(
                          subTitle ?? '',
                          style: TextStyleCustom.outFitLight300(
                            color: onBrandMuted,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                rowWidget ?? const SizedBox(width: 48)
              ],
            ),
            widget ?? const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}
