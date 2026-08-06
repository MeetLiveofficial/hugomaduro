import 'dart:async';
import 'dart:io';

import 'package:deepar_flutter_plus/deepar_flutter_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:krimson/common/extensions/string_extension.dart';
import 'package:krimson/common/manager/logger.dart';
import 'package:krimson/model/general/settings_model.dart';
import 'package:krimson/screen/deepar/deepar_runtime.dart';

/// Wrapper GetX-friendly sobre [DeepArControllerPlus].
class DeepArCameraController {
  DeepArControllerPlus? _controller;
  final RxBool isReady = false.obs;
  final RxString statusMessage = ''.obs;
  final RxnInt selectedFilterId = RxnInt();

  DeepArControllerPlus? get native => _controller;
  bool get isInitialized => _controller?.isInitialized ?? false;

  Future<bool> initialize() async {
    if (kIsWeb || !DeepArRuntime.useDeepAr()) {
      statusMessage.value = 'DeepAR unavailable';
      return false;
    }
    if (isInitialized) {
      isReady.value = true;
      return true;
    }

    final androidKey = DeepArRuntime.androidKey();
    final iosKey = DeepArRuntime.iosKey();
    if ((defaultTargetPlatform == TargetPlatform.android && androidKey == null) ||
        (defaultTargetPlatform == TargetPlatform.iOS && iosKey == null)) {
      statusMessage.value = 'Missing DeepAR license key';
      return false;
    }

    try {
      await destroy();
      final controller = DeepArControllerPlus();
      final result = await controller.initialize(
        androidLicenseKey: androidKey,
        iosLicenseKey: iosKey,
        resolution: Resolution.high,
      );
      if (!result.success) {
        statusMessage.value = result.message;
        Loggers.error('DeepAR init failed: ${result.message}');
        return false;
      }
      _controller = controller;

      if (Platform.isIOS) {
        // iOS necesita el platform view montado antes de isInitialized.
        for (var i = 0; i < 40; i++) {
          await Future.delayed(const Duration(milliseconds: 250));
          if (controller.isInitialized) break;
        }
      }

      isReady.value = controller.isInitialized || Platform.isAndroid;
      statusMessage.value = result.message;
      return isReady.value;
    } catch (e, st) {
      Loggers.error('DeepAR initialize: $e\n$st');
      statusMessage.value = e.toString();
      isReady.value = false;
      return false;
    }
  }

  Future<void> switchFilter(DeepARFilters? filter) async {
    final c = _controller;
    if (c == null || !c.isInitialized) return;
    selectedFilterId.value = filter?.id;
    final path = (filter?.filterFile ?? '').trim();
    if (path.isEmpty ||
        (filter?.title ?? '').toLowerCase() == 'none') {
      await c.switchEffect('');
      return;
    }
    final url = path.addBaseURL();
    try {
      await c.switchEffect(url);
    } catch (e, st) {
      Loggers.error('DeepAR switchEffect: $e\n$st');
    }
  }

  Future<void> clearEffect() async {
    selectedFilterId.value = null;
    try {
      await _controller?.switchEffect('');
    } catch (_) {}
  }

  Future<void> flipCamera() async {
    try {
      await _controller?.flipCamera();
    } catch (e) {
      Loggers.error('DeepAR flipCamera: $e');
    }
  }

  Future<File?> takeScreenshot() async {
    final c = _controller;
    if (c == null || !c.isInitialized) return null;
    try {
      return await c.takeScreenshot();
    } catch (e, st) {
      Loggers.error('DeepAR screenshot: $e\n$st');
      return null;
    }
  }

  Future<void> startVideoRecording() async {
    final c = _controller;
    if (c == null || !c.isInitialized) return;
    if (c.isRecording) return;
    await c.startVideoRecording();
  }

  Future<File?> stopVideoRecording() async {
    final c = _controller;
    if (c == null || !c.isRecording) return null;
    try {
      return await c.stopVideoRecording();
    } catch (e, st) {
      Loggers.error('DeepAR stopVideo: $e\n$st');
      return null;
    }
  }

  bool get isRecording => _controller?.isRecording ?? false;

  Future<void> destroy() async {
    isReady.value = false;
    selectedFilterId.value = null;
    final c = _controller;
    _controller = null;
    if (c == null) return;
    try {
      await c.destroy();
    } catch (e) {
      Loggers.error('DeepAR destroy: $e');
    }
  }
}
