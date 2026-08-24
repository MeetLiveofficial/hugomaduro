import 'package:flutter/material.dart';
import 'package:krimson/common/manager/app_role.dart';
import 'package:krimson/utilities/client_colors.dart';
import 'package:krimson/utilities/color_res.dart';
import 'package:krimson/utilities/style_res.dart';
import 'package:krimson/utilities/text_style_custom.dart';

/// Superficies, chips e inputs alineados a la paleta Coral → Magenta → Purple.
class BrandControls {
  static const double radius = 14;

  static BoxDecoration glass({bool selected = false}) {
    final client = AppRole.isClient();
    return BoxDecoration(
      color: selected
          ? null
          : (client
              ? ClientColors.surfaceAlt.withValues(alpha: 0.92)
              : ColorRes.whitePure.withValues(alpha: 0.92)),
      gradient: selected ? StyleRes.themeGradient : null,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: selected
            ? Colors.white.withValues(alpha: 0.35)
            : (client
                ? ClientColors.secondarySoft.withValues(alpha: 0.45)
                : ColorRes.roseBorder.withValues(alpha: 0.35)),
      ),
      boxShadow: [
        BoxShadow(
          color: (client ? ClientColors.primary : ColorRes.crimson)
              .withValues(alpha: selected ? 0.55 : 0.16),
          blurRadius: selected ? 14 : 8,
          spreadRadius: selected ? 0.5 : 0,
          offset: const Offset(0, 3),
        ),
      ],
    );
  }

  static InputDecoration search({
    required String hint,
    required Color hintColor,
    Widget? prefix,
    Widget? suffix,
  }) {
    final client = AppRole.isClient();
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyleCustom.outFitLight300(fontSize: 15, color: hintColor),
      prefixIcon: prefix,
      suffixIcon: suffix,
      filled: true,
      fillColor: client
          ? ClientColors.surfaceAlt.withValues(alpha: 0.94)
          : ColorRes.whitePure.withValues(alpha: 0.94),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radius),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radius),
        borderSide: BorderSide(
          color: client
              ? ClientColors.border.withValues(alpha: 0.7)
              : ColorRes.roseBorder.withValues(alpha: 0.28),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radius),
        borderSide: BorderSide(
          color: client ? ClientColors.primary : ColorRes.crimson,
          width: 1.4,
        ),
      ),
    );
  }
}

class BrandSegmentChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  final Color? accent;
  final IconData? icon;
  final bool compact;

  const BrandSegmentChip({
    super.key,
    required this.label,
    required this.active,
    required this.onTap,
    this.accent,
    this.icon,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final client = AppRole.isClient();
    final onColor = active
        ? ColorRes.whitePure
        : (client ? ClientColors.text : ColorRes.textDarkGrey);
    final iconColor = active
        ? ColorRes.whitePure
        : (accent ?? (client ? ClientColors.secondary : ColorRes.crimson));
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(BrandControls.radius),
        child: Ink(
          decoration: BrandControls.glass(selected: active),
          child: Padding(
            padding: compact
                ? const EdgeInsets.symmetric(vertical: 6, horizontal: 4)
                : const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(
                    icon,
                    size: icon == Icons.circle
                        ? (compact ? 7 : 8)
                        : (compact ? 13 : 15),
                    color: iconColor,
                  ),
                  SizedBox(width: compact ? 3 : 5),
                ],
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyleCustom.outFitMedium500(
                      color: onColor,
                      fontSize: compact ? 11 : 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class BrandFilterChip extends StatelessWidget {
  final String label;
  final bool active;
  final IconData icon;
  final VoidCallback onTap;
  final bool compact;

  const BrandFilterChip({
    super.key,
    required this.label,
    required this.active,
    required this.icon,
    required this.onTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final client = AppRole.isClient();
    final fg = active
        ? ColorRes.whitePure
        : (client ? ClientColors.text : ColorRes.textDarkGrey);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(BrandControls.radius),
        child: Ink(
          decoration: BrandControls.glass(selected: active),
          child: Padding(
            padding: compact
                ? const EdgeInsets.symmetric(horizontal: 6, vertical: 6)
                : const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(icon, size: compact ? 13 : 16, color: fg),
                SizedBox(width: compact ? 4 : 8),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyleCustom.outFitMedium500(
                      fontSize: compact ? 11 : 13,
                      color: fg,
                    ),
                  ),
                ),
                Icon(Icons.expand_more_rounded,
                    size: compact ? 14 : 18, color: fg),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class BrandStatusPill extends StatelessWidget {
  final String label;
  final Color color;
  final bool solid;

  const BrandStatusPill({
    super.key,
    required this.label,
    required this.color,
    this.solid = false,
  });

  @override
  Widget build(BuildContext context) {
    final bg = solid ? color : ColorRes.whitePure;
    final fg = solid ? ColorRes.whitePure : color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: solid ? ColorRes.whitePure : color,
          width: solid ? 1.6 : 1.3,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Text(
        label,
        style: TextStyleCustom.outFitMedium500(
          fontSize: 11,
          color: fg,
        ).copyWith(letterSpacing: 0.35, height: 1.1),
      ),
    );
  }
}

class BrandPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  const BrandPanel({
    super.key,
    required this.child,
    this.padding,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final client = AppRole.isClient();
    return Container(
      margin: margin ?? const EdgeInsets.fromLTRB(12, 8, 12, 4),
      padding: padding ?? EdgeInsets.zero,
      decoration: BoxDecoration(
        color: client
            ? ClientColors.surface.withValues(alpha: 0.92)
            : ColorRes.whitePure.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: client ? ClientColors.border : ColorRes.menuBorder,
        ),
        boxShadow: [
          BoxShadow(
            color: (client ? ClientColors.primary : ColorRes.crimson)
                .withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}

class BrandPrimaryButton extends StatelessWidget {
  final String title;
  final VoidCallback? onTap;
  final IconData? icon;
  final bool compact;

  const BrandPrimaryButton({
    super.key,
    required this.title,
    this.onTap,
    this.icon,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Ink(
          decoration: BoxDecoration(
            gradient: onTap == null ? null : StyleRes.themeGradient,
            color: onTap == null ? Colors.white24 : null,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(
              vertical: compact ? 8 : 11,
              horizontal: 8,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 14, color: Colors.white),
                  const SizedBox(width: 4),
                ],
                Flexible(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyleCustom.outFitMedium500(
                      color: Colors.white,
                      fontSize: compact ? 11 : 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class BrandGhostButton extends StatelessWidget {
  final String title;
  final VoidCallback? onTap;
  final IconData? icon;

  const BrandGhostButton({
    super.key,
    required this.title,
    this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white.withValues(alpha: 0.45)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 14, color: Colors.white),
                  const SizedBox(width: 4),
                ],
                Flexible(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyleCustom.outFitMedium500(
                      color: Colors.white,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
