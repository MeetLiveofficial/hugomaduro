import 'dart:io';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:image_picker/image_picker.dart';
import 'package:krimson/common/extensions/common_extension.dart';

import 'logger.dart';

class ScreenshotManager {
  /// Capture widget screenshot
  static Future<XFile?> captureScreenshot(GlobalKey screenshotKey) async {
    try {
      RenderRepaintBoundary? boundary = screenshotKey.currentContext
          ?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        Loggers.error('Screenshot boundary null');
        return null;
      }

      // 2.0 es suficiente para stories; 5.0 generaba PNG enormes y fallos de upload.
      final image = await boundary.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ImageByteFormat.png);
      final Uint8List? imageBytes = byteData?.buffer.asUint8List();
      if (imageBytes == null) {
        return null;
      }

      final localPath = await PlatformPathExtension.localPath;
      if (localPath.isEmpty) {
        Loggers.error('Screenshot localPath vacío');
        return null;
      }

      final file = File(
          '${localPath}screenshot_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(imageBytes, flush: true);
      return XFile(file.path, name: file.uri.pathSegments.last);
    } catch (e) {
      Loggers.error('❌ Screenshot failed: $e');
      return null;
    }
  }
}
