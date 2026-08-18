import 'package:figma_squircle_updated/figma_squircle.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krimson/utilities/color_res.dart';
import 'package:krimson/utilities/style_res.dart';
import 'package:krimson/utilities/text_style_custom.dart';
import 'package:krimson/utilities/theme_res.dart';

class TextButtonCustom extends StatelessWidget {
  final String title;
  final Color? titleColor;
  final Color? backgroundColor;
  final VoidCallback onTap;
  final double? horizontalMargin;
  final double? btnHeight;
  final double? btnWidth;
  final double? fontSize;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final double? radius;
  final BorderSide? borderSide;
  final Widget? child;
  final bool gradient;

  const TextButtonCustom(
      {super.key,
      required this.onTap,
      required this.title,
      this.titleColor,
      this.backgroundColor,
      this.horizontalMargin,
      this.btnHeight,
      this.padding,
      this.fontSize,
      this.radius,
      this.borderSide,
      this.btnWidth,
      this.margin,
      this.child,
      this.gradient = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin:
          margin ?? EdgeInsets.symmetric(horizontal: horizontalMargin ?? 15),
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: btnHeight ?? 57,
          width: btnWidth,
          padding: padding,
          alignment: Alignment.center,
          decoration: ShapeDecoration(
              shape: SmoothRectangleBorder(
                  borderRadius: SmoothBorderRadius(
                      cornerRadius: radius ?? 14, cornerSmoothing: 1),
                  side: borderSide ?? BorderSide.none),
              gradient: gradient ? StyleRes.themeGradient : null,
              color: gradient ? null : (backgroundColor ?? whitePure(context)),
              shadows: [
                BoxShadow(
                  color: ColorRes.crimson.withValues(alpha: gradient ? 0.32 : 0.1),
                  blurRadius: gradient ? 12 : 8,
                  offset: const Offset(0, 4),
                ),
              ]),
          child: child ??
              Text(
                title.capitalize ?? '',
                style: TextStyleCustom.outFitRegular400(
                    color: titleColor ?? textDarkGrey(context),
                    fontSize: fontSize ?? 17),
              ),
        ),
      ),
    );
  }
}
