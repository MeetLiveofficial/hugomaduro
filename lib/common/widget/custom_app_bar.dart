import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:krimson/common/manager/app_role.dart';
import 'package:krimson/common/widget/custom_back_button.dart';
import 'package:krimson/common/widget/gradient_text.dart';
import 'package:krimson/utilities/client_colors.dart';
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
    final client = AppRole.isClient();
    final branded = bgColor == null;
    final onBrand = branded || client
        ? ColorRes.whitePure
        : textDarkGrey(context);
    final onBrandMuted = branded || client
        ? ColorRes.whitePure.withValues(alpha: 0.82)
        : textLightGrey(context);

    Widget titleWidget;
    if (titleStyle != null) {
      titleWidget = Text(
        title,
        style: titleStyle,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
      );
    } else if (client) {
      titleWidget = GradientText(
        title,
        gradient: ClientColors.titleGradient,
        style: TextStyleCustom.unboundedMedium500(
          color: ColorRes.whitePure,
          fontSize: 18,
        ),
      );
    } else {
      titleWidget = Text(
        title,
        style: TextStyleCustom.unboundedMedium500(color: onBrand),
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
      );
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: client && branded ? Colors.transparent : bgColor,
        gradient: (!client && branded) ? StyleRes.themeGradient : null,
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
                      titleWidget,
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
