import 'dart:convert';

/// Mensaje de chat en vivo (texto / GIF / like / gift / follow / join).
class LiveChatMessage {
  LiveChatMessage({
    required this.id,
    required this.userId,
    required this.userName,
    required this.type,
    this.text,
    this.originalText,
    this.gifUrl,
    this.giftId,
    this.giftImage,
    this.giftCoins,
    this.replyToId,
    this.replyToUserName,
    this.replyToText,
    this.entranceVideo,
    this.userLevel,
    this.levelTitle,
    this.isSvip = false,
    this.isVip = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  final String id;
  final int userId;
  final String userName;
  final String type; // text | gif | like | gift | follow | join
  /// Texto mostrado (traducido al idioma del receptor si aplica).
  final String? text;
  /// Original antes de traducir (solo local, no se envía por LiveKit).
  final String? originalText;
  final String? gifUrl;
  final int? giftId;
  final String? giftImage;
  final int? giftCoins;
  final String? replyToId;
  final String? replyToUserName;
  final String? replyToText;
  /// Video de entrada del nivel (ruta relativa o URL).
  final String? entranceVideo;
  /// Número de nivel del usuario (join / personalización).
  final int? userLevel;
  /// Título del nivel (ej. "Oro", "SVIP").
  final String? levelTitle;
  final bool isSvip;
  final bool isVip;
  final DateTime createdAt;

  String get displayText => (text ?? '').trim();

  bool get isTranslated {
    final o = (originalText ?? '').trim();
    final t = (text ?? '').trim();
    return o.isNotEmpty && t.isNotEmpty && o != t;
  }

  bool get isReply =>
      (replyToId ?? '').isNotEmpty || (replyToUserName ?? '').isNotEmpty;

  /// Entrada destacada: nivel alto, SVIP o video de entrada.
  bool get isNotableJoin {
    if (type != 'join') return false;
    if (isVip) return true;
    if (isSvip) return true;
    if ((entranceVideo ?? '').trim().isNotEmpty) return true;
    return (userLevel ?? 0) >= 4;
  }

  LiveChatMessage copyWithTranslation({
    required String original,
    required String translated,
  }) {
    return LiveChatMessage(
      id: id,
      userId: userId,
      userName: userName,
      type: type,
      text: translated,
      originalText: original,
      gifUrl: gifUrl,
      giftId: giftId,
      giftImage: giftImage,
      giftCoins: giftCoins,
      replyToId: replyToId,
      replyToUserName: replyToUserName,
      replyToText: replyToText,
      entranceVideo: entranceVideo,
      userLevel: userLevel,
      levelTitle: levelTitle,
      isSvip: isSvip,
      isVip: isVip,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'user_name': userName,
        'type': type,
        // Solo el texto original viaja por red / API.
        'text': (originalText ?? text),
        'gif_url': gifUrl,
        'gift_id': giftId,
        'gift_image': giftImage,
        'gift_coins': giftCoins,
        'reply_to_id': replyToId,
        'reply_to_user_name': replyToUserName,
        'reply_to_text': replyToText,
        'entrance_video': entranceVideo,
        'user_level': userLevel,
        'level_title': levelTitle,
        'is_svip': isSvip ? 1 : 0,
        'is_vip': isVip ? 1 : 0,
        'ts': createdAt.millisecondsSinceEpoch,
      };

  factory LiveChatMessage.fromJson(Map<String, dynamic> json) {
    int? asInt(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toInt();
      return int.tryParse('$v');
    }

    bool asBool(dynamic v) {
      if (v == true || v == 1 || v == '1') return true;
      if (v is String && v.toLowerCase() == 'true') return true;
      return false;
    }

    return LiveChatMessage(
      id: '${json['id'] ?? DateTime.now().millisecondsSinceEpoch}',
      userId: asInt(json['user_id']) ?? 0,
      userName: '${json['user_name'] ?? 'User'}',
      type: '${json['type'] ?? 'text'}',
      text: json['text']?.toString(),
      gifUrl: json['gif_url']?.toString(),
      giftId: asInt(json['gift_id']),
      giftImage: json['gift_image']?.toString(),
      giftCoins: asInt(json['gift_coins']),
      replyToId: json['reply_to_id']?.toString(),
      replyToUserName: json['reply_to_user_name']?.toString(),
      replyToText: json['reply_to_text']?.toString(),
      entranceVideo: json['entrance_video']?.toString(),
      userLevel: asInt(json['user_level']),
      levelTitle: json['level_title']?.toString(),
      isSvip: asBool(json['is_svip']),
      isVip: asBool(json['is_vip']),
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        json['ts'] is num
            ? (json['ts'] as num).toInt()
            : DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  static LiveChatMessage? tryParseBytes(List<int> data) {
    try {
      final map = jsonDecode(utf8.decode(data));
      if (map is! Map) return null;
      return LiveChatMessage.fromJson(Map<String, dynamic>.from(map));
    } catch (_) {
      return null;
    }
  }

  List<int> toBytes() => utf8.encode(jsonEncode(toJson()));
}

/// Resumen de quien envió regalos en el LIVE.
class LiveGiftSender {
  LiveGiftSender({
    required this.userId,
    required this.userName,
    required this.totalCoins,
    required this.giftCount,
    this.lastGiftImage,
  });

  final int userId;
  final String userName;
  int totalCoins;
  int giftCount;
  String? lastGiftImage;
}
