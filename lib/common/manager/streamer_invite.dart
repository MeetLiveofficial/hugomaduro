import 'package:krimson/utilities/const_res.dart';

/// Registro de streamer en el panel Laravel, no en la APP.
class StreamerInvite {
  StreamerInvite._();

  static String registerUrl({String? agencyCode}) {
    final code = _normalize(agencyCode);
    const base = '${baseURL}register/streamer';
    if (code.isEmpty) return base;
    return '$base?agency=${Uri.encodeQueryComponent(code)}';
  }

  static String inviteUrl(String code) => registerUrl(agencyCode: code);

  static String _normalize(String? agencyCode) {
    final code = (agencyCode ?? '').trim();
    if (code.isEmpty) return '';
    if (code.contains('-')) return code.toLowerCase();
    return code.toUpperCase();
  }
}
