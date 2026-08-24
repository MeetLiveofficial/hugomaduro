import 'package:flutter/material.dart';
import 'package:krimson/utilities/color_res.dart';

class BlackGradientShadow extends StatelessWidget {
  final double? height;

  const BlackGradientShadow({super.key, this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: height ?? 300,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.transparent,
            ColorRes.crimson.withValues(alpha: 0.22),
            ColorRes.mlPurple.withValues(alpha: 0.55),
            ColorRes.obsidian.withValues(alpha: 0.92),
          ],
          stops: const [0.0, 0.35, 0.7, 1.0],
          begin: Alignment.topCenter,
          end: AlignmentDirectional.bottomCenter,
        ),
      ),
    );
  }
}
