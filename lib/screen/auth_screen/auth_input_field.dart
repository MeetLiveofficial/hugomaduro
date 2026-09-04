import 'package:figma_squircle_updated/figma_squircle.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krimson/utilities/asset_res.dart';
import 'package:krimson/utilities/color_res.dart';
import 'package:krimson/utilities/text_style_custom.dart';

/// Superficie de input de auth: vidrio oscuro, borde rosa, texto blanco.
class AuthFieldShell extends StatelessWidget {
  final Widget child;
  final double? height;

  const AuthFieldShell({super.key, required this.child, this.height});

  static const double radius = 16;

  static ShapeDecoration decoration() {
    return ShapeDecoration(
      shape: SmoothRectangleBorder(
        borderRadius:
            SmoothBorderRadius(cornerRadius: radius, cornerSmoothing: 1),
        side: BorderSide(color: ColorRes.menuBorder),
        borderAlign: BorderAlign.inside,
      ),
      color: ColorRes.bgElevated.withValues(alpha: 0.95),
      shadows: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.35),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: decoration(),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}

class AuthFieldLabel extends StatelessWidget {
  final String title;

  const AuthFieldLabel(this.title, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: TextStyleCustom.outFitMedium500(
          color: ColorRes.whitePure.withValues(alpha: 0.92),
          fontSize: 14,
        ),
      ),
    );
  }
}

class AuthTextField extends StatefulWidget {
  final bool isPasswordField;
  final String hintText;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final String? title;

  const AuthTextField({
    super.key,
    this.isPasswordField = false,
    required this.hintText,
    required this.controller,
    this.keyboardType,
    this.title,
  });

  @override
  State<AuthTextField> createState() => _AuthTextFieldState();
}

class _AuthTextFieldState extends State<AuthTextField> {
  bool isHide = true;

  @override
  Widget build(BuildContext context) {
    final field = AuthFieldShell(
      height: 52,
      child: TextField(
        controller: widget.controller,
        style: TextStyleCustom.outFitRegular400(
            color: ColorRes.whitePure, fontSize: 16),
        onTapOutside: (event) => FocusManager.instance.primaryFocus?.unfocus(),
        obscureText: widget.isPasswordField && isHide,
        keyboardType: widget.keyboardType ?? TextInputType.text,
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: widget.hintText,
          hintStyle: TextStyleCustom.outFitRegular400(
              color: ColorRes.whitePure.withValues(alpha: 0.45), fontSize: 16),
          contentPadding: EdgeInsets.only(
              left: 18, right: 10, top: widget.isPasswordField ? 2 : 0),
          suffixIconConstraints: const BoxConstraints(),
          suffixIcon: widget.isPasswordField
              ? InkWell(
                  onTap: () {
                    isHide = !isHide;
                    setState(() {});
                  },
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: Image.asset(
                        isHide ? AssetRes.icEye : AssetRes.icHideEye,
                        height: 22,
                        width: 36,
                        color: ColorRes.whitePure.withValues(alpha: 0.7),
                        key: UniqueKey()),
                  ),
                )
              : null,
        ),
        cursorColor: ColorRes.mauve,
      ),
    );

    if (widget.title == null) return field;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AuthFieldLabel(widget.title!),
          field,
        ],
      ),
    );
  }
}

/// Alias para pantallas que aún importan el nombre antiguo.
typedef LoginSheetTextField = AuthTextField;

class AuthPickerField extends StatelessWidget {
  final String title;
  final String value;
  final bool isPlaceholder;
  final IconData icon;
  final VoidCallback onTap;

  const AuthPickerField({
    super.key,
    required this.title,
    required this.value,
    required this.isPlaceholder,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AuthFieldLabel(title),
          AuthFieldShell(
            height: 52,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          value,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyleCustom.outFitRegular400(
                            color: isPlaceholder
                                ? ColorRes.whitePure.withValues(alpha: 0.45)
                                : ColorRes.whitePure,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      Icon(
                        icon,
                        size: 20,
                        color: ColorRes.whitePure.withValues(alpha: 0.7),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AuthSelectSheet extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? header;
  final double heightFactor;

  const AuthSelectSheet({
    super.key,
    required this.title,
    required this.child,
    this.header,
    this.heightFactor = 0.55,
  });

  static Future<T?> show<T>({
    required String title,
    required Widget child,
    Widget? header,
    double heightFactor = 0.55,
  }) {
    return Get.bottomSheet<T>(
      AuthSelectSheet(
        title: title,
        header: header,
        heightFactor: heightFactor,
        child: child,
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: Get.height * heightFactor,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: ColorRes.bgElevated,
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: ColorRes.whitePure.withValues(alpha: 0.28),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                title,
                style: TextStyleCustom.outFitMedium500(
                  color: ColorRes.whitePure,
                  fontSize: 17,
                ),
              ),
            ),
            if (header != null) header!,
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}
