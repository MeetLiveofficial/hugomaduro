import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:krimson/utilities/app_platform.dart';

/// Identidad de dispositivo que sobrevive a borrar la app.
///
/// Apple y Google no dan la MAC. En Android se usa ANDROID_ID (equivalente
/// práctico: mismo valor tras desinstalar). En iOS se guarda en Keychain
/// (local + iCloud Keychain si está activo).
class DeviceIdentity {
  static const _storageKey = 'krimson.device.stable_id';

  static const FlutterSecureStorage _local = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
      synchronizable: false,
    ),
    webOptions: WebOptions(),
  );

  static const FlutterSecureStorage _icloud = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock,
      synchronizable: true,
    ),
    webOptions: WebOptions(),
  );

  static String hashSeed(String seed) {
    return sha256.convert(utf8.encode('krimson-guest|$seed')).toString();
  }

  static Future<String?> readPersisted() async {
    if (kIsWeb) return null;
    try {
      final local = await _local.read(key: _storageKey);
      if (local != null && local.length >= 8) return local;
    } catch (_) {}
    try {
      final cloud = await _icloud.read(key: _storageKey);
      if (cloud != null && cloud.length >= 8) return cloud;
    } catch (_) {}
    return null;
  }

  static Future<void> writePersisted(String uuid) async {
    if (kIsWeb) return;
    try {
      await _local.write(key: _storageKey, value: uuid);
    } catch (_) {}
    try {
      await _icloud.write(key: _storageKey, value: uuid);
    } catch (_) {}
  }

  /// Semilla de hardware. En Android es ANDROID_ID (estable tras uninstall).
  static Future<String?> hardwareSeed() async {
    try {
      final plugin = DeviceInfoPlugin();
      if (AppPlatform.isAndroid) {
        final info = await plugin.androidInfo;
        final id = info.id.trim();
        if (id.isNotEmpty && id.toLowerCase() != 'unknown') {
          return 'android:$id';
        }
        return null;
      }
      if (AppPlatform.isIOS) {
        final info = await plugin.iosInfo;
        final vendor = (info.identifierForVendor ?? '').trim();
        if (vendor.isNotEmpty) {
          return 'ios:$vendor';
        }
        return null;
      }
      if (kIsWeb) {
        final info = await plugin.webBrowserInfo;
        final vendor = (info.vendor ?? '').trim();
        final ua = (info.userAgent ?? '').trim();
        if (vendor.isEmpty && ua.isEmpty) return null;
        return 'web:$vendor|$ua';
      }
    } catch (_) {}
    return null;
  }
}
