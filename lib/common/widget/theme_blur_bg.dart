import 'package:flutter/material.dart';
import 'package:krimson/utilities/color_res.dart';

/// Fondo dark Meet&Live — glows coral / magenta / violet.
class ThemeBlurBg extends StatelessWidget {
  const ThemeBlurBg({super.key, this.intense = false});

  /// Si true, glows más visibles (splash). Auth usa el default.
  final bool intense;

  @override
  Widget build(BuildContext context) {
    final glow = intense ? 1.6 : 1.15;

    return Container(
      height: double.infinity,
      width: double.infinity,
      color: ColorRes.obsidian,
      child: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(-0.35, -0.75),
                radius: 1.2,
                colors: [
                  ColorRes.crimsonAlt.withValues(alpha: 0.55 * glow),
                  ColorRes.crimson.withValues(alpha: 0.28 * glow),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.38, 1.0],
              ),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0.9, 0.15),
                radius: 1.05,
                colors: [
                  ColorRes.crimson.withValues(alpha: 0.5 * glow),
                  ColorRes.mlPurple.withValues(alpha: 0.28 * glow),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.45, 1.0],
              ),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(-0.7, 0.95),
                radius: 0.9,
                colors: [
                  ColorRes.mlPurple.withValues(alpha: 0.55 * glow),
                  ColorRes.darkPurple.withValues(alpha: 0.22 * glow),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0.8, -0.6),
                radius: 0.55,
                colors: [
                  const Color(0xFFFFCC66).withValues(alpha: 0.22 * glow),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  ColorRes.obsidian.withValues(alpha: 0.28),
                  Colors.transparent,
                  ColorRes.obsidian.withValues(alpha: 0.45),
                  ColorRes.obsidianDeep,
                ],
                stops: const [0.0, 0.35, 0.7, 1.0],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
