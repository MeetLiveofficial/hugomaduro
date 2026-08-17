import 'package:flutter/material.dart';
import 'package:krimson/utilities/color_res.dart';

/// Fondo vivo Meet&Live (coral → magenta → violeta), estilo referencia Funi.
class BrandWashBg extends StatelessWidget {
  const BrandWashBg({super.key, this.vivid = true});

  /// `true`: saturación alta (LIVE / splash). `false`: wash más claro.
  final bool vivid;

  @override
  Widget build(BuildContext context) {
    final colors = vivid
        ? const [
            Color(0xFFFF4D8D),
            Color(0xFFE24AB7),
            Color(0xFFB140D8),
            Color(0xFF6B2BFF),
          ]
        : const [
            Color(0xFFFF9EC8),
            Color(0xFFFF7AD4),
            Color(0xFFD080F0),
            Color(0xFFB08CFF),
          ];

    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: colors,
              stops: const [0.0, 0.32, 0.68, 1.0],
            ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(-0.7, -0.85),
              radius: 0.9,
              colors: [
                ColorRes.accentPeach.withValues(alpha: vivid ? 0.45 : 0.35),
                Colors.transparent,
              ],
            ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(0.95, 0.7),
              radius: 0.85,
              colors: [
                const Color(0xFF4FC3F7).withValues(alpha: vivid ? 0.28 : 0.18),
                Colors.transparent,
              ],
            ),
          ),
        ),
      ],
    );
  }
}
