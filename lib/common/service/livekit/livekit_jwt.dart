import 'dart:convert';

/// Utilidades de payload JWT LiveKit (documentación + validación de claims).
///
/// ⚠️ SEGURIDAD
/// -------------
/// El **API Secret** NO debe empaquetarse en el APK/IPA.
/// La firma del JWT se hace en el backend:
///   Flutter → `POST /api/livekit/token` (Laravel auth)
///          → microservicio Node (`livekit-server-sdk`) o servicio Dart server-side
///          → JWT firmado HS256 con API Key/Secret
///
/// Este archivo NO firma tokens. Para firmar en Dart (solo servidor), usa el
/// ejemplo de `dart_jsonwebtoken` documentado en comentarios abajo / respuesta.
class LiveKitJwtClaims {
  const LiveKitJwtClaims({
    required this.identity,
    required this.roomName,
    this.name,
    this.ttlSeconds = 7200,
    this.roomJoin = true,
    this.roomCreate = true,
    this.roomList = true,
    this.roomAdmin = true,
    this.canPublish = true,
    this.canSubscribe = true,
  });

  final String identity;
  final String roomName;
  final String? name;
  final int ttlSeconds;
  final bool roomJoin;
  final bool roomCreate;
  final bool roomList;
  final bool roomAdmin;
  final bool canPublish;
  final bool canSubscribe;

  /// Claim `video` que espera LiveKit Server.
  Map<String, dynamic> toVideoGrant() => {
        'roomJoin': roomJoin,
        'room': roomName,
        'roomCreate': roomCreate,
        'roomList': roomList,
        'roomAdmin': roomAdmin,
        'canPublish': canPublish,
        'canSubscribe': canSubscribe,
      };

  /// Payload lógico (sin firmar) para depuración / logs seguros.
  Map<String, dynamic> toPayloadPreview({required String apiKey}) {
    final now = DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000;
    return {
      'iss': apiKey,
      'sub': identity,
      'name': name ?? identity,
      'nbf': now - 10,
      'exp': now + ttlSeconds,
      'video': toVideoGrant(),
    };
  }

  String toPrettyJson({required String apiKey}) =>
      const JsonEncoder.withIndent('  ').convert(toPayloadPreview(apiKey: apiKey));
}

/*
═══════════════════════════════════════════════════════════════════════════════
EJEMPLO SERVER-SIDE (NO pegar secretos en Flutter release)

Dependencia: dart_jsonwebtoken
```dart
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';

String signLiveKitJwt({
  required String apiKey,
  required String apiSecret,
  required LiveKitJwtClaims claims,
}) {
  final now = DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000;
  final jwt = JWT(
    {
      'sub': claims.identity,
      'name': claims.name ?? claims.identity,
      'nbf': now - 10,
      'video': claims.toVideoGrant(),
    },
    issuer: apiKey,
  );
  return jwt.sign(
    SecretKey(apiSecret),
    algorithm: JWTAlgorithm.HS256,
    expiresIn: Duration(seconds: claims.ttlSeconds),
  );
}
```

En producción Krimson: firma el Node `livekit-token-service` (o Laravel).
Flutter solo consume el JWT ya firmado vía [LiveKitTokenService].
═══════════════════════════════════════════════════════════════════════════════
*/
