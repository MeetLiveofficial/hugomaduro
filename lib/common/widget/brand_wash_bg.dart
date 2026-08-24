import 'package:flutter/material.dart';
import 'package:krimson/utilities/color_res.dart';

/// Fondo dusk Meet&Live: obsidian + brillos coral/magenta (no wash chicle).
class BrandWashBg extends StatelessWidget {
  const BrandWashBg({super.key, this.vivid = true});

  /// `true`: brillos más presentes (LIVE). `false`: dusk suave (dashboard).
  final bool vivid;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: ColorRes.obsidianDeep),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: vivid
                  ? const [
                      Color(0xFF2A1224),
                      ColorRes.obsidian,
                      ColorRes.obsidianDeep,
                    ]
                  : const [
                      Color(0xFF1C121C),
                      ColorRes.obsidian,
                      ColorRes.obsidianDeep,
                    ],
            ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(-0.75, -0.9),
              radius: 0.95,
              colors: [
                ColorRes.crimsonAlt.withValues(alpha: vivid ? 0.28 : 0.14),
                Colors.transparent,
              ],
            ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(0.9, 0.55),
              radius: 0.9,
              colors: [
                ColorRes.mlPurple.withValues(alpha: vivid ? 0.22 : 0.12),
                Colors.transparent,
              ],
            ),
          ),
        ),
      ],
    );
  }
}
