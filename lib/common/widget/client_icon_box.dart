import 'package:flutter/material.dart';
import 'package:krimson/utilities/client_colors.dart';

/// Recuadro de icono neon (settings, headers, guest, notificaciones).
class ClientIconBox extends StatelessWidget {
  const ClientIconBox({
    super.key,
    this.icon,
    this.asset,
    this.accent = ClientColors.primary,
    this.size = 36,
    this.iconSize = 20,
    this.radius = 10,
  });

  final IconData? icon;
  final String? asset;
  final Color accent;
  final double size;
  final double iconSize;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: accent.withValues(alpha: 0.45)),
        boxShadow: ClientColors.neonGlow(
          color: accent,
          alpha: 0.22,
          blur: 10,
          offset: Offset.zero,
        ),
      ),
      alignment: Alignment.center,
      child: asset != null
          ? Image.asset(
              asset!,
              width: iconSize,
              height: iconSize,
              color: accent,
              errorBuilder: (_, __, ___) => Icon(
                icon ?? Icons.circle,
                size: iconSize,
                color: accent,
              ),
            )
          : Icon(icon ?? Icons.circle, size: iconSize, color: accent),
    );
  }
}
