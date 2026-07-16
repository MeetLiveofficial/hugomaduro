import 'package:krimson/common/service/api/api_service.dart';
import 'package:krimson/common/service/utils/web_service.dart';
import 'package:krimson/utilities/const_res.dart';

class LiveKitTokenResult {
  LiveKitTokenResult({
    required this.token,
    required this.wsUrl,
    this.identity,
    this.roomName,
    this.expiresIn,
  });

  final String token;
  final String wsUrl;
  final String? identity;
  final String? roomName;
  final int? expiresIn;
}

/// Obtiene Access Tokens LiveKit de forma segura (siempre vía backend).
///
/// Arquitectura:
/// ```
/// App (autenticada) ──POST /api/livekit/token──► Laravel (authorizeUser)
///                                              └──► live.nexusdevtech.com/token
///                                                   (firma con API Secret)
/// App ◄── JWT + wssUrl ────────────────────────────────────────┘
/// App ──wss──► wss://live.nexusdevtech.com
/// ```
class LiveKitTokenService {
  LiveKitTokenService._();
  static final LiveKitTokenService instance = LiveKitTokenService._();

  Future<LiveKitTokenResult> createToken({
    required String roomName,
    required String identity,
    String? name,
  }) async {
    final json = await ApiService.instance.call(
      url: WebService.livekit.token,
      param: {
        'roomName': roomName,
        'identity': identity,
        if (name != null && name.isNotEmpty) 'name': name,
      },
      fromJson: (j) => j,
    );

    if (json['status'] != true) {
      throw Exception(json['message'] ?? 'Failed to get LiveKit token');
    }

    final data = Map<String, dynamic>.from(json['data'] as Map);
    final token = (data['token'] as String?)?.trim() ?? '';
    if (token.isEmpty) {
      throw Exception('LiveKit token is empty');
    }

    final wsUrl = (data['wsUrl'] as String?)?.trim();
    return LiveKitTokenResult(
      token: token,
      wsUrl: (wsUrl != null && wsUrl.isNotEmpty) ? wsUrl : liveKitWsUrl,
      identity: data['identity'] as String?,
      roomName: data['roomName'] as String?,
      expiresIn: data['expiresIn'] is int
          ? data['expiresIn'] as int
          : int.tryParse('${data['expiresIn']}'),
    );
  }
}
