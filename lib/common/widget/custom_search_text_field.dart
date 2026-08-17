import 'package:figma_squircle_updated/figma_squircle.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krimson/languages/languages_keys.dart';
import 'package:krimson/utilities/color_res.dart';
import 'package:krimson/utilities/text_style_custom.dart';
import 'package:krimson/utilities/theme_res.dart';

class CustomSearchTextField extends StatelessWidget {
  final BorderSide? borderSide;
  final EdgeInsets? margin;
  final Function(String value)? onChanged;
  final bool? enable;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final TextEditingController? controller;
  final TapRegionCallback? onTapOutside;
  final String? hintText;
  final Widget? suffixIcon;

  const CustomSearchTextField(
      {super.key,
      this.borderSide,
      this.margin,
      this.onChanged,
      this.enable,
      this.onTap,
      this.backgroundColor,
      this.controller,
      this.onTapOutside,
      this.hintText,
      this.suffixIcon});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin ?? const EdgeInsets.symmetric(vertical: 7, horizontal: 10),
      decoration: ShapeDecoration(
        shape: SmoothRectangleBorder(
            borderRadius:
                SmoothBorderRadius(cornerRadius: 14, cornerSmoothing: 1),
            side: borderSide ??
                BorderSide(color: ColorRes.roseBorder.withValues(alpha: 0.32))),
        color: backgroundColor ?? ColorRes.whitePure.withValues(alpha: 0.94),
        shadows: [
          BoxShadow(
            color: ColorRes.crimson.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: TextField(
        onTap: onTap,
        controller: controller,
        decoration: InputDecoration(
            border: InputBorder.none,
            enabled: enable ?? true,
            constraints: const BoxConstraints(minHeight: 44, maxHeight: 46),
            contentPadding:
                const EdgeInsets.only(left: 16, right: 12, top: 12, bottom: 12),
            hintText: hintText ?? LKey.searchHere.tr,
            hintStyle: TextStyleCustom.outFitLight300(
                fontSize: 15, color: textLightGrey(context)),
            hintFadeDuration: const Duration(milliseconds: 200),
            prefixIcon: Icon(Icons.search_rounded,
                size: 20, color: ColorRes.crimson.withValues(alpha: 0.85)),
            prefixIconConstraints: const BoxConstraints(minWidth: 40),
            suffixIconConstraints: const BoxConstraints(),
            suffixIcon: suffixIcon),
        cursorHeight: 16,
        style: TextStyleCustom.outFitRegular400(
            fontSize: 15, color: textDarkGrey(context)),
        onTapOutside: (event) {
          onTapOutside?.call(event);
          FocusManager.instance.primaryFocus?.unfocus();
        },
        onChanged: onChanged,
      ),
    );
  }
}
