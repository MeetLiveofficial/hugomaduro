import 'dart:convert';

/// Mensaje de chat en vivo (texto / GIF / like / gift).
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
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  final String id;
  final int userId;
  final String userName;
  final String type; // text | gif | like | gift
  final String? text;
  final String? gifUrl;
  final int? giftId;
  final String? giftImage;
  final int? giftCoins;
  final DateTime createdAt;

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
