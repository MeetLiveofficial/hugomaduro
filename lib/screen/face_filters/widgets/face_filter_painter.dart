import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:krimson/screen/face_filters/models/face_filter_effect.dart';
import 'package:krimson/screen/face_filters/models/face_mesh_frame.dart';

class FaceFilterPainter extends CustomPainter {
  FaceFilterPainter({
    required this.frame,
    required this.effectId,
  });

  final FaceMeshFrame? frame;
  final FaceFilterId effectId;

  @override
  void paint(Canvas canvas, Size size) {
    final data = frame;
    if (data == null || data.normalizedLandmarks.isEmpty) return;
    if (effectId == FaceFilterId.none) return;

    switch (effectId) {
      case FaceFilterId.none:
      case FaceFilterId.beautySoft:
      case FaceFilterId.beautyNatural:
      case FaceFilterId.beautyPorcelain:
      case FaceFilterId.beautyFresh:
      case FaceFilterId.beautyWarm:
      case FaceFilterId.beautyRose:
        break;
      case FaceFilterId.meshDebug:
        _paintMesh(canvas, size, data);
      case FaceFilterId.glasses:
        _paintGlasses(canvas, size, data);
      case FaceFilterId.dogEars:
        _paintDogEars(canvas, size, data);
      case FaceFilterId.blush:
        _paintBlush(canvas, size, data);
      case FaceFilterId.mustache:
        _paintMustache(canvas, size, data);
      case FaceFilterId.sparkleEyes:
        _paintSparkleEyes(canvas, size, data);
      case FaceFilterId.cyberNeon:
        _paintCyberNeon(canvas, size, data);
      case FaceFilterId.freckles:
        _paintFreckles(canvas, size, data);
      case FaceFilterId.heartEyes:
        _paintHeartEyes(canvas, size, data);
      case FaceFilterId.catWhiskers:
        _paintCatWhiskers(canvas, size, data);
      case FaceFilterId.softGlow:
        _paintSoftGlow(canvas, size, data);
    }
  }

  void _paintMesh(Canvas canvas, Size size, FaceMeshFrame data) {
    final stroke = Paint()
      ..color = const Color(0xFF69F0AE).withValues(alpha: 0.55)
      ..strokeWidth = 0.7
      ..style = PaintingStyle.stroke;

    if (data.triangles.isNotEmpty) {
      for (final tri in data.triangles) {
        if (tri.length < 3) continue;
        final a = data.landmark(tri[0], size);
        final b = data.landmark(tri[1], size);
        final c = data.landmark(tri[2], size);
        if (a == null || b == null || c == null) continue;
        final path = Path()
          ..moveTo(a.dx, a.dy)
          ..lineTo(b.dx, b.dy)
          ..lineTo(c.dx, c.dy)
          ..close();
        canvas.drawPath(path, stroke);
      }
    } else {
      final fill = Paint()
        ..color = const Color(0xFF69F0AE)
        ..style = PaintingStyle.fill;
      for (final p in data.allLandmarks(size)) {
        canvas.drawCircle(p, 1.2, fill);
      }
    }
  }

  void _paintGlasses(Canvas canvas, Size size, FaceMeshFrame data) {
    final left = data.leftEyeOuter(size);
    final right = data.rightEyeOuter(size);
    final leftInner = data.landmark(FaceMeshLandmarkIndex.leftEyeInner, size);
    final rightInner = data.landmark(FaceMeshLandmarkIndex.rightEyeInner, size);
    if (left == null || right == null) return;

    final eyeSpan = (right - left).distance;
    final lensRadius = eyeSpan * 0.22;
    final leftCenter = leftInner != null
        ? Offset((left.dx + leftInner.dx) / 2, (left.dy + leftInner.dy) / 2)
        : left;
    final rightCenter = rightInner != null
        ? Offset((right.dx + rightInner.dx) / 2, (right.dy + rightInner.dy) / 2)
        : right;

    final framePaint = Paint()
      ..color = Colors.black87
      ..strokeWidth = math.max(2.5, eyeSpan * 0.035)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final tint = Paint()
      ..color = const Color(0xFF40C4FF).withValues(alpha: 0.28)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(leftCenter, lensRadius, tint);
    canvas.drawCircle(rightCenter, lensRadius, tint);
    canvas.drawCircle(leftCenter, lensRadius, framePaint);
    canvas.drawCircle(rightCenter, lensRadius, framePaint);
    canvas.drawLine(
      Offset(leftCenter.dx + lensRadius * 0.85, leftCenter.dy),
      Offset(rightCenter.dx - lensRadius * 0.85, rightCenter.dy),
      framePaint,
    );
  }

  void _paintDogEars(Canvas canvas, Size size, FaceMeshFrame data) {
    final forehead = data.forehead(size);
    final left = data.leftEyeOuter(size);
    final right = data.rightEyeOuter(size);
    if (forehead == null || left == null || right == null) return;

    final span = (right - left).distance;
    final earH = span * 0.55;
    final earW = span * 0.32;
    final paint = Paint()
      ..color = const Color(0xFFFFAB40)
      ..style = PaintingStyle.fill;
    final inner = Paint()
      ..color = const Color(0xFFFFE0B2)
      ..style = PaintingStyle.fill;

    void ear(Offset anchor, bool flip) {
      final dir = flip ? 1.0 : -1.0;
      final tip = Offset(anchor.dx + dir * earW * 0.2, anchor.dy - earH);
      final baseL = Offset(anchor.dx - earW * 0.45, anchor.dy + earH * 0.05);
      final baseR = Offset(anchor.dx + earW * 0.45, anchor.dy + earH * 0.05);
      final path = Path()
        ..moveTo(baseL.dx, baseL.dy)
        ..quadraticBezierTo(
            tip.dx - dir * earW * 0.35, tip.dy + earH * 0.2, tip.dx, tip.dy)
        ..quadraticBezierTo(
            tip.dx + dir * earW * 0.35, tip.dy + earH * 0.2, baseR.dx, baseR.dy)
        ..close();
      canvas.drawPath(path, paint);
      canvas.drawCircle(
        Offset(anchor.dx + dir * earW * 0.05, anchor.dy - earH * 0.35),
        earW * 0.22,
        inner,
      );
    }

    ear(Offset(forehead.dx - span * 0.42, forehead.dy - span * 0.05), false);
    ear(Offset(forehead.dx + span * 0.42, forehead.dy - span * 0.05), true);
  }

  void _paintBlush(Canvas canvas, Size size, FaceMeshFrame data) {
    final left = data.leftCheek(size);
    final right = data.rightCheek(size);
    final eyeSpan = data.leftEyeOuter(size) != null &&
            data.rightEyeOuter(size) != null
        ? (data.rightEyeOuter(size)! - data.leftEyeOuter(size)!).distance
        : 80.0;
    final smile = data.smileIntensity;
    final radius = eyeSpan * (0.18 + smile * 0.08);
    final paint = Paint()
      ..color =
          const Color(0xFFFF80AB).withValues(alpha: 0.22 + smile * 0.25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    if (left != null) canvas.drawCircle(left, radius, paint);
    if (right != null) canvas.drawCircle(right, radius, paint);
  }

  void _paintMustache(Canvas canvas, Size size, FaceMeshFrame data) {
    final nose = data.noseTip(size);
    final lip = data.upperLip(size);
    final mouthL = data.landmark(FaceMeshLandmarkIndex.mouthLeft, size);
    final mouthR = data.landmark(FaceMeshLandmarkIndex.mouthRight, size);
    if (nose == null || lip == null) return;
    final width = mouthL != null && mouthR != null
        ? (mouthR - mouthL).distance * 0.95
        : 70.0;
    final center = Offset(
      (nose.dx + lip.dx) / 2,
      nose.dy * 0.35 + lip.dy * 0.65,
    );
    final paint = Paint()
      ..color = const Color(0xFF5D4037)
      ..style = PaintingStyle.fill;
    final path = Path()
      ..moveTo(center.dx, center.dy)
      ..quadraticBezierTo(center.dx - width * 0.35, center.dy - width * 0.12,
          center.dx - width * 0.5, center.dy + width * 0.08)
      ..quadraticBezierTo(center.dx - width * 0.2, center.dy + width * 0.18,
          center.dx, center.dy + width * 0.04)
      ..quadraticBezierTo(center.dx + width * 0.2, center.dy + width * 0.18,
          center.dx + width * 0.5, center.dy + width * 0.08)
      ..quadraticBezierTo(center.dx + width * 0.35, center.dy - width * 0.12,
          center.dx, center.dy)
      ..close();
    canvas.drawPath(path, paint);
  }

  void _paintSparkleEyes(Canvas canvas, Size size, FaceMeshFrame data) {
    final open = data.eyeOpenIntensity;
    if (open < 0.25) return;
    final left = data.leftIris(size) ?? data.leftEyeOuter(size);
    final right = data.rightIris(size) ?? data.rightEyeOuter(size);
    final eyeSpan = data.leftEyeOuter(size) != null &&
            data.rightEyeOuter(size) != null
        ? (data.rightEyeOuter(size)! - data.leftEyeOuter(size)!).distance
        : 80.0;
    final star = eyeSpan * 0.12 * open;

    void sparkle(Offset? center) {
      if (center == null) return;
      final paint = Paint()
        ..color = const Color(0xFFFFD740).withValues(alpha: 0.85 * open)
        ..style = PaintingStyle.fill;
      final path = Path();
      for (var i = 0; i < 4; i++) {
        final angle = (math.pi / 2) * i - math.pi / 4;
        final outer = Offset(
          center.dx + math.cos(angle) * star,
          center.dy + math.sin(angle) * star,
        );
        final midAngle = angle + math.pi / 4;
        final inner = Offset(
          center.dx + math.cos(midAngle) * star * 0.35,
          center.dy + math.sin(midAngle) * star * 0.35,
        );
        if (i == 0) {
          path.moveTo(outer.dx, outer.dy);
        } else {
          path.lineTo(outer.dx, outer.dy);
        }
        path.lineTo(inner.dx, inner.dy);
      }
      path.close();
      canvas.drawPath(path, paint);
    }

    sparkle(left == null
        ? null
        : Offset(left.dx + star * 0.6, left.dy - star * 0.5));
    sparkle(right == null
        ? null
        : Offset(right.dx + star * 0.6, right.dy - star * 0.5));
  }

  void _paintCyberNeon(Canvas canvas, Size size, FaceMeshFrame data) {
    final jaw = [
      data.landmark(FaceMeshLandmarkIndex.chin, size),
      data.landmark(FaceMeshLandmarkIndex.mouthLeft, size),
      data.landmark(FaceMeshLandmarkIndex.mouthRight, size),
      data.leftCheek(size),
      data.rightCheek(size),
      data.forehead(size),
    ].whereType<Offset>().toList();
    if (jaw.length < 3) return;
    final paint = Paint()
      ..color = const Color(0xFFE040FB).withValues(alpha: 0.85)
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 2);
    final path = Path()..moveTo(jaw.first.dx, jaw.first.dy);
    for (var i = 1; i < jaw.length; i++) {
      path.lineTo(jaw[i].dx, jaw[i].dy);
    }
    path.close();
    canvas.drawPath(path, paint);
    final left = data.leftEyeOuter(size);
    final right = data.rightEyeOuter(size);
    if (left != null && right != null) {
      canvas.drawLine(left, right, paint);
    }
  }

  void _paintFreckles(Canvas canvas, Size size, FaceMeshFrame data) {
    final left = data.leftCheek(size);
    final right = data.rightCheek(size);
    final nose = data.noseTip(size);
    if (left == null || right == null || nose == null) return;
    final paint = Paint()
      ..color = const Color(0xFF8D6E63).withValues(alpha: 0.7)
      ..style = PaintingStyle.fill;
    final rnd = math.Random(42);
    void sprinkle(Offset center, double radius) {
      for (var i = 0; i < 10; i++) {
        final a = rnd.nextDouble() * math.pi * 2;
        final r = rnd.nextDouble() * radius;
        canvas.drawCircle(
          Offset(center.dx + math.cos(a) * r, center.dy + math.sin(a) * r),
          1.6 + rnd.nextDouble(),
          paint,
        );
      }
    }

    final span = (right - left).distance;
    sprinkle(left, span * 0.18);
    sprinkle(right, span * 0.18);
    sprinkle(Offset(nose.dx, nose.dy + span * 0.05), span * 0.1);
  }

  void _paintHeartEyes(Canvas canvas, Size size, FaceMeshFrame data) {
    final left = data.leftIris(size) ?? data.leftEyeOuter(size);
    final right = data.rightIris(size) ?? data.rightEyeOuter(size);
    final eyeSpan = data.leftEyeOuter(size) != null &&
            data.rightEyeOuter(size) != null
        ? (data.rightEyeOuter(size)! - data.leftEyeOuter(size)!).distance
        : 80.0;
    final s = eyeSpan * 0.18;
    final paint = Paint()
      ..color = const Color(0xFFFF1744)
      ..style = PaintingStyle.fill;

    void heart(Offset? c) {
      if (c == null) return;
      final path = Path()
        ..moveTo(c.dx, c.dy + s * 0.35)
        ..cubicTo(c.dx - s, c.dy - s * 0.2, c.dx - s * 0.9, c.dy - s,
            c.dx, c.dy - s * 0.35)
        ..cubicTo(c.dx + s * 0.9, c.dy - s, c.dx + s, c.dy - s * 0.2, c.dx,
            c.dy + s * 0.35);
      canvas.drawPath(path, paint);
    }

    heart(left);
    heart(right);
  }

  void _paintCatWhiskers(Canvas canvas, Size size, FaceMeshFrame data) {
    final nose = data.noseTip(size);
    final left = data.leftCheek(size);
    final right = data.rightCheek(size);
    if (nose == null || left == null || right == null) return;
    final paint = Paint()
      ..color = Colors.black87
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    for (final t in [-0.2, 0.0, 0.2]) {
      canvas.drawLine(
        Offset(nose.dx - 4, nose.dy + t * 18),
        Offset(left.dx, left.dy + t * 22),
        paint,
      );
      canvas.drawLine(
        Offset(nose.dx + 4, nose.dy + t * 18),
        Offset(right.dx, right.dy + t * 22),
        paint,
      );
    }
    final earPaint = Paint()
      ..color = const Color(0xFFFF6E40)
      ..style = PaintingStyle.fill;
    final forehead = data.forehead(size);
    final eyeL = data.leftEyeOuter(size);
    final eyeR = data.rightEyeOuter(size);
    if (forehead != null && eyeL != null && eyeR != null) {
      final span = (eyeR - eyeL).distance;
      void triangle(Offset base, double dir) {
        final path = Path()
          ..moveTo(base.dx - span * 0.12, base.dy)
          ..lineTo(base.dx + dir * span * 0.05, base.dy - span * 0.4)
          ..lineTo(base.dx + span * 0.12, base.dy)
          ..close();
        canvas.drawPath(path, earPaint);
      }

      triangle(Offset(forehead.dx - span * 0.35, forehead.dy), -1);
      triangle(Offset(forehead.dx + span * 0.35, forehead.dy), 1);
    }
  }

  void _paintSoftGlow(Canvas canvas, Size size, FaceMeshFrame data) {
    final left = data.leftCheek(size);
    final right = data.rightCheek(size);
    final forehead = data.forehead(size);
    final eyeSpan = data.leftEyeOuter(size) != null &&
            data.rightEyeOuter(size) != null
        ? (data.rightEyeOuter(size)! - data.leftEyeOuter(size)!).distance
        : 80.0;
    final paint = Paint()
      ..color = const Color(0xFFFFF59D).withValues(alpha: 0.22)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16);
    if (left != null) canvas.drawCircle(left, eyeSpan * 0.28, paint);
    if (right != null) canvas.drawCircle(right, eyeSpan * 0.28, paint);
    if (forehead != null) {
      canvas.drawCircle(forehead, eyeSpan * 0.35, paint);
    }
  }

  @override
  bool shouldRepaint(covariant FaceFilterPainter oldDelegate) {
    return oldDelegate.frame != frame || oldDelegate.effectId != effectId;
  }
}
