import 'package:flutter/foundation.dart';
import 'package:krimson/common/manager/logger.dart';
import 'package:permission_handler/permission_handler.dart';

/// Permisos de cámara/mic: si ya están concedidos, no vuelve a pedirlos.
class MediaPermissions {
  static Future<bool> ensure({
    bool camera = false,
    bool microphone = false,
  }) async {
    if (kIsWeb) return true;
    final toRequest = <Permission>[];
    if (camera) {
      final status = await Permission.camera.status;
      if (!status.isGranted) toRequest.add(Permission.camera);
    }
    if (microphone) {
      final status = await Permission.microphone.status;
      if (!status.isGranted) toRequest.add(Permission.microphone);
    }
    if (toRequest.isEmpty) return true;

    final statuses = await toRequest.request();
    var ok = true;
    for (final entry in statuses.entries) {
      if (!entry.value.isGranted) {
        Loggers.error('Permission denied: ${entry.key}');
        ok = false;
      }
    }
    return ok;
  }

  static Future<bool> cameraGranted() async {
    if (kIsWeb) return true;
    return Permission.camera.status.isGranted;
  }
}
