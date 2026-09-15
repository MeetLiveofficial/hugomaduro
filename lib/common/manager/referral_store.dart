import 'package:get_storage/get_storage.dart';

class ReferralStore {
  ReferralStore._();

  static const _key = 'pending_referral_code';
  static final _box = GetStorage('krimson');

  static String normalize(String raw) {
    return raw.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
  }

  static String get pending {
    return normalize((_box.read(_key) ?? '').toString());
  }

  static void save(String raw) {
    final code = normalize(raw);
    if (code.length < 4) return;
    _box.write(_key, code);
  }

  static void clear() {
    _box.remove(_key);
  }

  static bool captureFromUri(Uri uri) {
    final segments = uri.pathSegments;
    if (segments.isNotEmpty && segments.first.toLowerCase() == 'r') {
      save(segments.last);
      return pending.isNotEmpty;
    }
    final ref = uri.queryParameters['ref'] ?? uri.queryParameters['referral'];
    if (ref != null && ref.trim().isNotEmpty) {
      save(ref);
      return pending.isNotEmpty;
    }
    return false;
  }
}
