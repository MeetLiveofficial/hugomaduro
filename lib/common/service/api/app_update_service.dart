import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:krimson/common/manager/app_role.dart';
import 'package:krimson/common/manager/logger.dart';
import 'package:krimson/common/manager/session_manager.dart';
import 'package:krimson/common/service/api/api_service.dart';
import 'package:krimson/common/service/utils/web_service.dart';
import 'package:krimson/languages/languages_keys.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class AppUpdateCheckResult {
  AppUpdateCheckResult({
    required this.updateAvailable,
    required this.forceUpdate,
    required this.latestVersion,
    required this.latestBuild,
    required this.downloadUrl,
    required this.title,
    required this.message,
  });

  factory AppUpdateCheckResult.fromJson(Map<String, dynamic> json) {
    return AppUpdateCheckResult(
      updateAvailable: json['update_available'] == true,
      forceUpdate: json['force_update'] == true,
      latestVersion: json['latest_version']?.toString() ?? '',
      latestBuild: int.tryParse('${json['latest_build']}') ?? 0,
      downloadUrl: json['download_url']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
    );
  }

  final bool updateAvailable;
  final bool forceUpdate;
  final String latestVersion;
  final int latestBuild;
  final String downloadUrl;
  final String title;
  final String message;
}

class AppUpdateService {
  AppUpdateService._();
  static final AppUpdateService instance = AppUpdateService._();

  static const _dismissKeyPrefix = 'app_update_dismissed_version_';

  final _storage = GetStorage('krimson');

  bool get _isMobileNative {
    if (kIsWeb) return false;
    try {
      return Platform.isAndroid || Platform.isIOS;
    } catch (_) {
      return false;
    }
  }

  String get _platformName {
    if (kIsWeb) return 'web';
    if (Platform.isIOS) return 'ios';
    if (Platform.isAndroid) return 'android';
    return 'unknown';
  }

  /// Obligatorio solo si hay sesión y el usuario es Streamer.
  bool get _forceForStreamer {
    final user = SessionManager.instance.getUser();
    return user != null && AppRole.isStreamer(user);
  }

  Future<AppUpdateCheckResult?> checkUpdate() async {
    if (!_isMobileNative) return null;
    try {
      final info = await PackageInfo.fromPlatform();
      final build = int.tryParse(info.buildNumber) ?? 0;
      final json = await ApiService.instance.call<Map<String, dynamic>>(
        url: WebService.app.checkUpdate,
        param: {
          'platform': _platformName,
          'version': info.version,
          'build': build,
        },
        fromJson: (j) => j,
        cancelAuthToken: true,
      );
      if (json['status'] != true || json['data'] is! Map) {
        return null;
      }
      return AppUpdateCheckResult.fromJson(
        Map<String, dynamic>.from(json['data'] as Map),
      );
    } catch (e) {
      Loggers.error('checkUpdate failed: $e');
      return null;
    }
  }

  bool wasDismissed(String latestVersion) {
    final v = latestVersion.trim();
    if (v.isEmpty) return false;
    return (_storage.read('$_dismissKeyPrefix$v') == true);
  }

  Future<void> markDismissed(String latestVersion) async {
    final v = latestVersion.trim();
    if (v.isEmpty) return;
    await _storage.write('$_dismissKeyPrefix$v', true);
  }

  Future<void> _openDownload(String downloadUrl) async {
    final url = downloadUrl.trim();
    if (url.isEmpty) return;
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  /// Si la versión instalada != panel: Streamer → obligatorio; Cliente → opcional.
  Future<void> maybeShowUpdateDialog(
      {Duration delay = const Duration(milliseconds: 800)}) async {
    if (!_isMobileNative) return;
    await Future.delayed(delay);
    final result = await checkUpdate();
    if (result == null || !result.updateAvailable) return;

    final forceUpdate = _forceForStreamer || result.forceUpdate;
    if (!forceUpdate && wasDismissed(result.latestVersion)) return;
    if (Get.context == null) return;
    if (Get.isDialogOpen == true) return;

    final title = result.title.trim().isNotEmpty
        ? result.title
        : 'Nueva actualización';
    final message = result.message.trim().isNotEmpty
        ? result.message
        : 'Tu app no está en la versión ${result.latestVersion}. Descárgala desde la web.';

    await Get.dialog(
      PopScope(
        canPop: !forceUpdate,
        child: AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            if (!forceUpdate)
              TextButton(
                onPressed: () async {
                  await markDismissed(result.latestVersion);
                  Get.back();
                },
                child: Text(LKey.later.tr),
              ),
            TextButton(
              onPressed: () => _openDownload(result.downloadUrl),
              child: Text(LKey.updateNow.tr),
            ),
          ],
        ),
      ),
      barrierDismissible: !forceUpdate,
    );
  }
}
