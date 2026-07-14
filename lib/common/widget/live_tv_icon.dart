import 'package:flutter/material.dart';

/// Icono tipo televisor con antenas y texto LIVE (nav / cabeceras).
class LiveTvIcon extends StatelessWidget {
  final double size;
  final Color color;

  const LiveTvIcon({
    super.key,
    this.size = 38,
    this.color = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _LiveTvPainter(color: color),
      ),
    );
  }
}

class _LiveTvPainter extends CustomPainter {
  final Color color;

  _LiveTvPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.08
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fill = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final w = size.width;
    final h = size.height;

    // Antenas
    final antennaBase = Offset(w * 0.5, h * 0.22);
    canvas.drawLine(antennaBase, Offset(w * 0.32, h * 0.04), stroke);
    canvas.drawLine(antennaBase, Offset(w * 0.68, h * 0.04), stroke);

    // Marco TV
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.12, h * 0.2, w * 0.76, h * 0.62),
      Radius.circular(w * 0.1),
    );
    canvas.drawRRect(rect, stroke);

    // Texto LIVE
    final textPainter = TextPainter(
      text: TextSpan(
        text: 'LIVE',
        style: TextStyle(
          color: color,
          fontSize: w * 0.22,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
          height: 1,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: w * 0.7);

    final textOffset = Offset(
      (w - textPainter.width) / 2,
      h * 0.2 + (h * 0.62 - textPainter.height) / 2,
    );
    textPainter.paint(canvas, textOffset);

    // Patas pequeñas
    canvas.drawLine(
      Offset(w * 0.32, h * 0.82),
      Offset(w * 0.28, h * 0.94),
      stroke,
    );
    canvas.drawLine(
      Offset(w * 0.68, h * 0.82),
      Offset(w * 0.72, h * 0.94),
      stroke,
    );

    // Punto de encendido opcional (esquina)
    canvas.drawCircle(Offset(w * 0.78, h * 0.72), w * 0.025, fill);
  }

  @override
  bool shouldRepaint(covariant _LiveTvPainter oldDelegate) =>
      oldDelegate.color != color;
}
