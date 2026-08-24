import 'package:flutter/material.dart';

/// Destello que recorre el widget (misma animación que la tarjeta Monedero).
class ShineSweep extends StatefulWidget {
  const ShineSweep({
    super.key,
    this.gloss = true,
  });

  /// Brillo estático suave arriba a la izquierda.
  final bool gloss;

  /// Pinta el destello solo sobre los píxeles opacos de [child] (marcos PNG).
  static Widget masked({
    required Widget child,
    Duration duration = const Duration(milliseconds: 2800),
  }) {
    return _MaskedShine(duration: duration, child: child);
  }

  @override
  State<ShineSweep> createState() => _ShineSweepState();
}

class _ShineSweepState extends State<ShineSweep>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return LayoutBuilder(
          builder: (context, constraints) {
            return Stack(
              fit: StackFit.expand,
              children: [
                if (widget.gloss)
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.white.withValues(alpha: 0.20),
                          Colors.white.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                CustomPaint(
                  painter: _ShineBandPainter(t: _controller.value),
                  size: Size(constraints.maxWidth, constraints.maxHeight),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _MaskedShine extends StatefulWidget {
  const _MaskedShine({
    required this.child,
    required this.duration,
  });

  final Widget child;
  final Duration duration;

  @override
  State<_MaskedShine> createState() => _MaskedShineState();
}

class _MaskedShineState extends State<_MaskedShine>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          fit: StackFit.passthrough,
          children: [
            child!,
            ShaderMask(
              blendMode: BlendMode.srcATop,
              shaderCallback: (bounds) {
                return LinearGradient(
                  begin: const Alignment(-1.0, -0.35),
                  end: const Alignment(1.0, 0.35),
                  colors: [
                    Colors.white.withValues(alpha: 0),
                    Colors.white.withValues(alpha: 0.72),
                    Colors.white.withValues(alpha: 0),
                  ],
                  stops: const [0.15, 0.5, 0.85],
                  transform: _Slide(t: _controller.value),
                ).createShader(bounds);
              },
              child: child,
            ),
          ],
        );
      },
      child: widget.child,
    );
  }
}

class _Slide extends GradientTransform {
  const _Slide({required this.t});

  final double t;

  @override
  Matrix4 transform(Rect bounds, {TextDirection? textDirection}) {
    final sweep = t < 0.42 ? t / 0.42 : -1.0;
    final dx = (sweep * 2.4 - 0.7) * bounds.width;
    return Matrix4.translationValues(dx, 0, 0);
  }
}

class _ShineBandPainter extends CustomPainter {
  const _ShineBandPainter({required this.t});

  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    if (t >= 0.42) return;
    final sweep = t / 0.42;
    final cx = (sweep * 2.4 - 0.7) * size.width;
    canvas.save();
    canvas.translate(cx, size.height / 2);
    canvas.rotate(-0.55);
    final rect = Rect.fromCenter(
      center: Offset.zero,
      width: 64,
      height: size.height * 1.8,
    );
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          Colors.white.withValues(alpha: 0),
          Colors.white.withValues(alpha: 0.58),
          Colors.white.withValues(alpha: 0),
        ],
        stops: const [0.15, 0.5, 0.85],
      ).createShader(rect);
    canvas.drawRect(rect, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _ShineBandPainter oldDelegate) =>
      oldDelegate.t != t;
}
