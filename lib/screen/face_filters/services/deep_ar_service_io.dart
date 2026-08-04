import 'dart:io';

import 'package:deepar_flutter_plus/deepar_flutter_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:krimson/common/extensions/string_extension.dart';
import 'package:krimson/common/manager/logger.dart';
import 'package:krimson/common/manager/session_manager.dart';
import 'package:krimson/model/general/settings_model.dart';
import 'package:krimson/screen/face_filters/services/deep_ar_service.dart';

DeepArService createDeepArService() => DeepArServiceIo.instance;

class DeepArServiceIo extends ChangeNotifier implements DeepArService {
  DeepArServiceIo._();
  static final DeepArServiceIo instance = DeepArServiceIo._();

  DeepArControllerPlus? _controller;
  int? _selectedFilterId;
  bool _initializing = false;
  bool _iosPrimed = false;

  @override
  DeepArControllerPlus? get controller => _controller;

  @override
  int? get selectedFilterId => _selectedFilterId;

  Setting? get _settings => SessionManager.instance.getSettings();

  @override
  bool get isConfigured {
    if (kIsWeb) return false;
    final s = _settings;
    if (s == null || (s.isDeepAr ?? 0) != 1) return false;
    if (Platform.isAndroid) {
      final k = (s.deeparAndroidKey ?? '').trim();
      return k.isNotEmpty && k != '---------';
    }
    if (Platform.isIOS) {
      final k = (s.deeparIOSKey ?? '').trim();
      return k.isNotEmpty && k != '---------';
    }
    return false;
  }

  @override
  bool get isInitialized {
    final c = _controller;
    if (c == null) return false;
    if (Platform.isIOS) return _iosPrimed || _controller != null;
    try {
      return c.isInitialized;
    } catch (_) {
      return false;
    }
  }

  @override
  List<DeepARFilters> get filters {
    final list = _settings?.deepARFilters ?? const <DeepARFilters>[];
    return list
        .where((f) => (f.filterFile ?? '').trim().isNotEmpty)
        .toList(growable: false);
  }

  String? _effectUrl(DeepARFilters filter) {
    final raw = (filter.filterFile ?? '').trim();
    if (raw.isEmpty) return null;
    return raw.addBaseURL();
  }

  /// Call from preview when the native view is ready (iOS).
  @override
  void markPreviewReady() {
    _iosPrimed = true;
    notifyListeners();
  }

  @override
  Widget buildPreview({VoidCallback? onViewCreated}) {
    final ctrl = _controller;
    if (ctrl == null) {
      return const ColoredBox(
        color: Colors.black,
        child: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }
    return DeepArPreviewPlus(
      ctrl,
      onViewCreated: () {
        markPreviewReady();
        onViewCreated?.call();
      },
    );
  }

  @override
  Future<bool> initialize() async {
    if (!isConfigured) {
      Loggers.info('DeepAR: not configured (is_deepAR / keys)');
      return false;
    }
    if (_initializing) return false;
    if (_controller != null) return true;

    _initializing = true;
    try {
      final s = _settings!;
      final ctrl = DeepArControllerPlus();
      final result = await ctrl.initialize(
        androidLicenseKey: s.deeparAndroidKey,
        iosLicenseKey: s.deeparIOSKey,
        resolution: Resolution.medium,
      );
      if (!result.success) {
        Loggers.error('DeepAR init failed: ${result.message}');
        try {
          await ctrl.destroy();
        } catch (_) {}
        return false;
      }
      _controller = ctrl;
      _iosPrimed = Platform.isAndroid;
      notifyListeners();
      Loggers.info('DeepAR: initialized — ${result.message}');
      return true;
    } catch (e, st) {
      Loggers.error('DeepAR initialize: $e\n$st');
      _controller = null;
      return false;
    } finally {
      _initializing = false;
    }
  }

  @override
  Future<void> applyFilter(DeepARFilters? filter) async {
    final ctrl = _controller;
    if (ctrl == null) return;

    if (filter == null || (filter.filterFile ?? '').trim().isEmpty) {
      await clearEffect();
      return;
    }

    final url = _effectUrl(filter);
    if (url == null || url.isEmpty) return;

    try {
      await ctrl.switchEffect(url);
      _selectedFilterId = filter.id;
      notifyListeners();
      Loggers.info('DeepAR effect applied id=${filter.id}');
    } catch (e) {
      Loggers.error('DeepAR switchEffect failed, trying switchFilter: $e');
      try {
        await ctrl.switchFilter(url);
        _selectedFilterId = filter.id;
        notifyListeners();
      } catch (e2, st2) {
        Loggers.error('DeepAR switchFilter failed: $e2\n$st2');
      }
    }
  }

  @override
  Future<void> clearEffect() async {
    final ctrl = _controller;
    if (ctrl == null) return;
    try {
      await ctrl.switchEffect('none');
    } catch (_) {
      try {
        await ctrl.switchFilter('');
      } catch (e) {
        Loggers.error('DeepAR clearEffect: $e');
      }
    }
    _selectedFilterId = null;
    notifyListeners();
  }

  @override
  Future<void> destroy() async {
    final ctrl = _controller;
    _controller = null;
    _selectedFilterId = null;
    _iosPrimed = false;
    notifyListeners();
    if (ctrl == null) return;
    try {
      await ctrl.destroy();
    } catch (e) {
      Loggers.error('DeepAR destroy: $e');
    }
    await Future.delayed(const Duration(milliseconds: 500));
  }

  @override
  Future<String?> startVideoRecording() async {
    final ctrl = _controller;
    if (ctrl == null) return null;
    try {
      await ctrl.startVideoRecording();
      return 'ok';
    } catch (e) {
      Loggers.error('DeepAR startVideoRecording: $e');
      return null;
    }
  }

  @override
  Future<String?> stopVideoRecording() async {
    final ctrl = _controller;
    if (ctrl == null) return null;
    try {
      final file = await ctrl.stopVideoRecording();
      return file.path;
    } catch (e) {
      Loggers.error('DeepAR stopVideoRecording: $e');
      return null;
    }
  }

  @override
  Future<String?> takeScreenshot() async {
    final ctrl = _controller;
    if (ctrl == null) return null;
    try {
      final file = await ctrl.takeScreenshot();
      return file.path;
    } catch (e) {
      Loggers.error('DeepAR takeScreenshot: $e');
      return null;
    }
  }
}
