import 'dart:convert';

/// Mensaje de chat en vivo (texto / GIF / like / gift / follow).
class LiveChatMessage {
  LiveChatMessage({
    required this.id,
    required this.userId,
    required this.userName,
    required this.type,
    this.text,
    this.gifUrl,
    this.giftId,
    this.giftImage,
    this.giftCoins,
    this.replyToId,
    this.replyToUserName,
    this.replyToText,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  final String id;
  final int userId;
  final String userName;
  final String type; // text | gif | like | gift | follow
  final String? text;
  final String? gifUrl;
  final int? giftId;
  final String? giftImage;
  final int? giftCoins;
  final String? replyToId;
  final String? replyToUserName;
  final String? replyToText;
  final DateTime createdAt;

  bool get isReply =>
      (replyToId ?? '').isNotEmpty || (replyToUserName ?? '').isNotEmpty;

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'user_name': userName,
        'type': type,
        'text': text,
        'gif_url': gifUrl,
        'gift_id': giftId,
        'gift_image': giftImage,
        'gift_coins': giftCoins,
        'reply_to_id': replyToId,
        'reply_to_user_name': replyToUserName,
        'reply_to_text': replyToText,
        'ts': createdAt.millisecondsSinceEpoch,
      };

  factory LiveChatMessage.fromJson(Map<String, dynamic> json) {
    int? asInt(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toInt();
      return int.tryParse('$v');
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
