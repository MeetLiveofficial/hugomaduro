import 'package:figma_squircle_updated/figma_squircle.dart';
import 'package:flutter/material.dart';
import 'package:krimson/utilities/asset_res.dart';
import 'package:krimson/utilities/color_res.dart';
import 'package:krimson/utilities/text_style_custom.dart';
import 'package:krimson/utilities/theme_res.dart';

class CustomDropDownBtn<T> extends StatelessWidget {
  final List<T> items;
  final T selectedValue;
  final Function(T?)? onChanged;
  final double height;
  final double? width;
  final bool isExpanded;
  final EdgeInsetsGeometry? padding;
  final TextStyle? style;
  final double? menuMaxHeight;
  final String Function(T) getTitle;

  final Color? bgColor;

  const CustomDropDownBtn(
      {super.key,
      required this.items,
      required this.selectedValue,
      required this.onChanged,
      required this.getTitle,
      this.height = 37,
      this.width,
      this.isExpanded = false,
      this.padding,
      this.style,
      this.menuMaxHeight,
      this.bgColor});

  @override
  Widget build(BuildContext context) {
    final fieldBg = bgColor ?? ColorRes.whitePure;
    return Container(
      height: height,
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: ShapeDecoration(
        color: fieldBg,
        shape: SmoothRectangleBorder(
          borderRadius: SmoothBorderRadius(cornerRadius: 8, cornerSmoothing: 1),
          side: const BorderSide(color: ColorRes.bgGrey, width: 1),
        ),
      ),
      alignment: Alignment.center,
      child: DropdownButton<T>(
        value: selectedValue,
        icon: Align(
            alignment: Alignment.bottomCenter,
            child: Image.asset(
              AssetRes.icDownArrow_1,
              width: 23,
              height: 20,
              color: ColorRes.textDarkGrey,
            )),
        dropdownColor: ColorRes.whitePure,
        style: TextStyleCustom.outFitRegular400(
            color: ColorRes.textDarkGrey, fontSize: 15),
        underline: const SizedBox(),
        isDense: true,
        isExpanded: isExpanded,
        padding: padding,
        alignment: Alignment.center,
        onChanged: onChanged,
        menuMaxHeight: menuMaxHeight ?? 220,
        borderRadius: BorderRadius.circular(12),
        items: items.map<DropdownMenuItem<T>>((T item) {
          final selected = item == selectedValue;
          return DropdownMenuItem<T>(
            value: item,
            child: Text(
              getTitle(item),
              style: TextStyleCustom.outFitRegular400(
                color: selected
                    ? ColorRes.coralRed
                    : ColorRes.textDarkGrey,
                fontSize: 15,
              ),
            ),
          );
        }).toList(),
        selectedItemBuilder: (context) {
          return items.map((item) {
            return Align(
              alignment: Alignment.centerLeft,
              child: Text(
                getTitle(item),
                style: style ??
                    TextStyleCustom.outFitMedium500(
                      color: textDarkGrey(context),
                      fontSize: 15,
                    ),
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList();
        },
      ),
    );
  }
}
