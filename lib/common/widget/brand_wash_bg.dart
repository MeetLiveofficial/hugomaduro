import 'package:flutter/material.dart';
import 'package:krimson/common/manager/app_role.dart';
import 'package:krimson/utilities/client_colors.dart';

/// Fondo: streamer seda violeta/magenta; cliente navy + orbes cian.
class BrandWashBg extends StatelessWidget {
  const BrandWashBg({super.key, this.vivid = true});

  /// `true`: brillos más presentes (LIVE). `false`: dusk suave (dashboard).
  final bool vivid;

  static const String streamerAsset = 'assets/images/streamer_silk_bg.jpg';

  @override
  Widget build(BuildContext context) {
    if (!AppRole.isClient()) return _StreamerSilkBg(vivid: vivid);
    return _ClientWashBg(vivid: vivid);
  }
}

class _ClientWashBg extends StatelessWidget {
  const _ClientWashBg({required this.vivid});

  final bool vivid;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: ClientColors.bg),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [ClientColors.bgMid, ClientColors.bgMid, ClientColors.bg],
            ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(-0.75, -0.9),
              radius: 0.95,
              colors: [
                ClientColors.primary.withValues(alpha: vivid ? 0.28 : 0.16),
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
                ClientColors.magenta.withValues(alpha: vivid ? 0.22 : 0.14),
                Colors.transparent,
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Copia del fondo de los mockups streamer: seda magenta sobre negro violeta.
class _StreamerSilkBg extends StatelessWidget {
  const _StreamerSilkBg({required this.vivid});

  final bool vivid;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: Color(0xFF07010E)),
        Image.asset(
          BrandWashBg.streamerAsset,
          fit: BoxFit.cover,
          alignment: Alignment.center,
          filterQuality: FilterQuality.medium,
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(0, -0.15),
              radius: 0.85,
              colors: [
                const Color(0xFF07010E).withValues(alpha: vivid ? 0.12 : 0.28),
                Colors.transparent,
              ],
            ),
          ),
        ),
      ],
    );
  }
}
