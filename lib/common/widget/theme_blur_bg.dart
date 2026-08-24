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
                center: const Alignment(0.05, -0.05),
                radius: intense ? 0.85 : 0.7,
                colors: [
                  ColorRes.crimson.withValues(alpha: 0.32 * glow),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          if (intense) ...[
            Align(
              alignment: const Alignment(-0.72, -0.62),
              child: _BokehDot(
                size: 18,
                color: ColorRes.roseMuted.withValues(alpha: 0.28),
              ),
            ),
            Align(
              alignment: const Alignment(0.78, -0.38),
              child: _BokehDot(
                size: 12,
                color: ColorRes.crimson.withValues(alpha: 0.22),
              ),
            ),
            Align(
              alignment: const Alignment(-0.55, 0.42),
              child: _BokehDot(
                size: 10,
                color: ColorRes.mlPurple.withValues(alpha: 0.3),
              ),
            ),
            Align(
              alignment: const Alignment(0.62, 0.58),
              child: _BokehDot(
                size: 16,
                color: ColorRes.crimsonAlt.withValues(alpha: 0.18),
              ),
            ),
          ],
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  ColorRes.obsidian.withValues(alpha: intense ? 0.18 : 0.28),
                  Colors.transparent,
                  ColorRes.obsidian.withValues(alpha: 0.38),
                  ColorRes.obsidianDeep,
                ],
                stops: const [0.0, 0.32, 0.72, 1.0],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BokehDot extends StatelessWidget {
  const _BokehDot({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          boxShadow: [
            BoxShadow(
              color: color,
              blurRadius: size * 1.6,
              spreadRadius: size * 0.2,
            ),
          ],
        ),
      ),
    );
  }
}
