import 'dart:io';
import 'dart:ui' as ui;

import 'package:camera/camera.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:krimson/common/manager/logger.dart';

Future<XFile?> captureRepaintBoundaryToFile(GlobalKey boundaryKey) async {
  try {
    final boundary = boundaryKey.currentContext?.findRenderObject()
        as RenderRepaintBoundary?;
    if (boundary == null) return null;
    final image = await boundary.toImage(pixelRatio: 2);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) return null;
    final dir = await getTemporaryDirectory();
    final path = p.join(
      dir.path,
      'face_filter_${DateTime.now().millisecondsSinceEpoch}.png',
    );
    await File(path).writeAsBytes(byteData.buffer.asUint8List());
    return XFile(path);
  } catch (e) {
    Loggers.error('Baked capture failed: $e');
    return null;
  }
}
