import 'package:flutter/material.dart';
import 'package:krimson/utilities/color_res.dart';

/// Fondo dark Meet&Live — glows suaves (contraste alto para formularios).
class ThemeBlurBg extends StatelessWidget {
  const ThemeBlurBg({super.key, this.intense = false});

  /// Si true, glows un poco más visibles (splash). Auth usa el default oscuro.
  final bool intense;

  @override
  Widget build(BuildContext context) {
    final glow = intense ? 1.0 : 0.55;

    return Container(
      height: double.infinity,
      width: double.infinity,
      color: const Color(0xFF0A080C),
      child: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(-0.35, -0.75),
                radius: 1.05,
                colors: [
                  ColorRes.softSalmon.withValues(alpha: 0.12 * glow),
                  ColorRes.coralRed.withValues(alpha: 0.06 * glow),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.35, 1.0],
              ),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0.85, 0.2),
                radius: 0.9,
                colors: [
                  ColorRes.mauve.withValues(alpha: 0.14 * glow),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(-0.7, 0.95),
                radius: 0.75,
                colors: [
                  ColorRes.darkPurple.withValues(alpha: 0.2 * glow),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          // Vignette fuerte: mantiene el centro oscuro para leer el form.
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF0A080C).withValues(alpha: 0.35),
                  Colors.transparent,
                  const Color(0xFF0A080C).withValues(alpha: 0.55),
                  const Color(0xFF08060A),
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
