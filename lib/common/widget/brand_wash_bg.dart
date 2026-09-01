import 'package:flutter/material.dart';
import 'package:krimson/common/manager/app_role.dart';
import 'package:krimson/utilities/client_colors.dart';
import 'package:krimson/utilities/color_res.dart';

/// Fondo dusk: streamer coral/magenta; cliente `--client-950` + cian.
class BrandWashBg extends StatelessWidget {
  const BrandWashBg({super.key, this.vivid = true});

  /// `true`: brillos más presentes (LIVE). `false`: dusk suave (dashboard).
  final bool vivid;

  @override
  Widget build(BuildContext context) {
    final client = AppRole.isClient();
    final base = client ? ClientColors.bg : ColorRes.obsidianDeep;
    final mid = client ? ClientColors.bg : ColorRes.obsidian;
    final top = client
        ? ClientColors.bg
        : (vivid ? const Color(0xFF2A1224) : const Color(0xFF1C121C));
    final orbA = client ? ClientColors.bg : ColorRes.crimsonAlt;
    final orbB = client ? ClientColors.bg : ColorRes.mlPurple;

    return Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(color: base),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [top, mid, base],
            ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(-0.75, -0.9),
              radius: 0.95,
              colors: [
                orbA.withValues(alpha: vivid ? 0.28 : 0.16),
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
                orbB.withValues(alpha: vivid ? 0.22 : 0.14),
                Colors.transparent,
              ],
            ),
          ),
        ),
      ],
    );
  }
}
