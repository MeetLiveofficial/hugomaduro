import 'package:flutter/material.dart';
import 'package:krimson/common/manager/app_role.dart';
import 'package:krimson/utilities/client_colors.dart';
import 'package:krimson/utilities/streamer_colors.dart';

/// Fondo dusk: streamer `--streamer-950` + cian; cliente `--client-950`.
class BrandWashBg extends StatelessWidget {
  const BrandWashBg({super.key, this.vivid = true});

  /// `true`: brillos más presentes (LIVE). `false`: dusk suave (dashboard).
  final bool vivid;

  @override
  Widget build(BuildContext context) {
    final client = AppRole.isClient();
    final base = client ? ClientColors.bg : StreamerColors.bg;
    final mid = client ? ClientColors.surface : StreamerColors.surface;
    final top = client
        ? (vivid ? ClientColors.surfaceAlt : ClientColors.surface)
        : (vivid ? StreamerColors.surfaceAlt : StreamerColors.surface);
    final orbA = client ? ClientColors.primary : StreamerColors.primary;
    final orbB =
        client ? ClientColors.primaryActive : StreamerColors.primaryActive;

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
