import 'dart:convert';

import 'package:android_id/android_id.dart';
import 'package:crypto/crypto.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:krimson/utilities/app_platform.dart';

/// Identidad de dispositivo que sobrevive a borrar la app.
///
/// En Android se usa Settings.Secure.ANDROID_ID (único por dispositivo,
/// usuario y firma de la app; se mantiene tras desinstalar). En iOS,
/// identifierForVendor más una copia en Keychain.
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

  /// Hash viejo de 64 hex: en Android salía de Build.ID, igual en todos
  /// los teléfonos con la misma versión del sistema. El servidor lo rechaza.
  static bool isLegacySharedUuid(String value) {
    return RegExp(r'^[a-f0-9]{64}$').hasMatch(value);
  }

  /// Identificador v2. No es el SHA-256 completo: así no se confunde con
  /// el hash compartido de Build.ID.
  static String hashSeed(String seed) {
    final digest =
        sha256.convert(utf8.encode('krimson-guest-v2|$seed')).toString();
    return '2${digest.substring(0, 40)}';
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

  /// Semilla única del aparato. Nunca Build.ID: ese valor es la versión
  /// de Android y lo comparten todos los teléfonos con la misma compilación.
  static Future<String?> hardwareSeed() async {
    try {
      if (AppPlatform.isAndroid) {
        final raw = (await const AndroidId().getId() ?? '').trim();
        if (!_usableAndroidId(raw)) return null;
        return 'android:$raw';
      }
      if (AppPlatform.isIOS) {
        final plugin = DeviceInfoPlugin();
        final info = await plugin.iosInfo;
        final vendor = (info.identifierForVendor ?? '').trim();
        if (vendor.isNotEmpty) {
          return 'ios:$vendor';
        }
      }
    } catch (_) {}
    return null;
  }

  /// ANDROID_ID roto que devolvían algunos Android antiguos a todos.
  static bool _usableAndroidId(String raw) {
    if (raw.length < 8) return false;
    final lower = raw.toLowerCase();
    return lower != 'unknown' && lower != '9774d56d682e549c';
  }
}
