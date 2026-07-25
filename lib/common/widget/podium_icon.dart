import 'package:flutter/material.dart';
import 'package:krimson/utilities/color_res.dart';

/// Podio minimalista (3 peldaños). Sin círculo ni glow.
class PodiumIcon extends StatelessWidget {
  const PodiumIcon({
    super.key,
    this.size = 26,
    this.color = ColorRes.whitePure,
  });

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _PodiumPainter(color: color),
      ),
    );
  }
}

class _PodiumPainter extends CustomPainter {
  _PodiumPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final w = size.width;
    final h = size.height;
    final gap = w * 0.06;
    final barW = (w - gap * 2) / 3;
    final heights = [h * 0.55, h * 0.88, h * 0.42];
    final xs = [0.0, barW + gap, (barW + gap) * 2];

    for (var i = 0; i < 3; i++) {
      final top = h - heights[i];
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(xs[i], top, barW, heights[i]),
          Radius.circular(w * 0.07),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _PodiumPainter oldDelegate) =>
      oldDelegate.color != color;
}
