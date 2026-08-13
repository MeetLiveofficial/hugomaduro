import 'package:krimson/common/service/api/api_service.dart';
import 'package:krimson/common/service/utils/web_service.dart';
import 'package:krimson/model/livestream/live_chat_message.dart';
import 'package:krimson/model/livestream/livestream.dart';
import 'package:krimson/model/livestream/livestream_user_state.dart';
import 'dart:convert';

class LiveSessionPayload {
  LiveSessionPayload({required this.session, required this.participants});
  final Livestream session;
  final List<LivestreamUserState> participants;
}

class LiveCommentsPayload {
  LiveCommentsPayload({required this.comments, required this.lastServerId});
  final List<LiveChatMessage> comments;
  final int lastServerId;
}

class LiveSessionService {
  LiveSessionService._();
  static final LiveSessionService instance = LiveSessionService._();

  Future<List<Livestream>> listActive() async {
    final json = await ApiService.instance.call(
      url: WebService.live.listActive,
      fromJson: (j) => j,
    );
    if (json['status'] != true) {
      throw Exception(json['message'] ?? 'listActive failed');
    }
    final data = json['data'];
    final list = data is List ? data : <dynamic>[];
    return list
        .map((e) => Livestream.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<Livestream> start({
    required String description,
    String? coverImage,
    List<int> coHostIds = const [],
    int isRestrictToJoin = 0,
    List<LiveGiftIncentive> giftIncentives = const [],
  }) async {
    final json = await ApiService.instance.call(
      url: WebService.live.start,
      param: {
        'description': description,
        if (coverImage != null && coverImage.isNotEmpty)
          'cover_image': coverImage,
        'is_restrict_to_join': isRestrictToJoin,
        'co_host_ids': coHostIds.join(','),
        'type': 'LIVESTREAM',
        if (giftIncentives.isNotEmpty)
          'gift_incentives': jsonEncode(giftIncentives
              .where((e) => e.isConfigured)
              .map((e) => e.toJson())
              .toList()),
      },
      fromJson: (j) => j,
    );
    if (json['status'] != true) {
      throw Exception(json['message'] ?? 'start live failed');
    }
    return Livestream.fromJson(
        Map<String, dynamic>.from(json['data'] as Map));
  }

  Future<LiveSessionPayload> join({required String roomId}) async {
    final json = await ApiService.instance.call(
      url: WebService.live.join,
      param: {'room_id': roomId},
      fromJson: (j) => j,
    );
    if (json['status'] != true) {
      throw Exception(json['message'] ?? 'join failed');
    }
    final data = json['data'] as Map<String, dynamic>;
    return LiveSessionPayload(
      session: Livestream.fromJson(
          Map<String, dynamic>.from(data['session'] as Map)),
      participants: ((data['participants'] as List?) ?? [])
          .map((e) =>
              LivestreamUserState.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }

  Future<void> leave({required String roomId}) async {
    await ApiService.instance.call(
      url: WebService.live.leave,
      param: {'room_id': roomId},
      fromJson: (j) => j,
    );
  }

  Future<LiveLikeResult> like({
    required String roomId,
    int? battleForUserId,
  }) async {
    final json = await ApiService.instance.call(
      url: WebService.live.like,
      param: {
        'room_id': roomId,
        if (battleForUserId != null && battleForUserId > 0)
          'battle_for_user_id': battleForUserId,
      },
      fromJson: (j) => j,
    );
    if (json['status'] != true) {
      throw Exception(json['message'] ?? 'like failed');
    }
    final data = json['data'];
    int likeCount = 0;
    int? hostCoin;
    int? oppCoin;
    if (data is Map) {
      if (data['like_count'] != null) {
        likeCount = data['like_count'] is num
            ? (data['like_count'] as num).toInt()
            : int.tryParse('${data['like_count']}') ?? 0;
      }
      if (data['battle_host_coin'] != null) {
        hostCoin = data['battle_host_coin'] is num
            ? (data['battle_host_coin'] as num).toInt()
            : int.tryParse('${data['battle_host_coin']}');
      }
      if (data['battle_opponent_coin'] != null) {
        oppCoin = data['battle_opponent_coin'] is num
            ? (data['battle_opponent_coin'] as num).toInt()
            : int.tryParse('${data['battle_opponent_coin']}');
      }
    }
    return LiveLikeResult(
      likeCount: likeCount,
      battleHostCoin: hostCoin,
      battleOpponentCoin: oppCoin,
    );
  }

  /// Registra regalo en la sesión (coins desde DB). Devuelve lista actualizada.
  Future<List<LiveGiftSender>> recordGift({
    required String roomId,
    required int giftId,
    int coins = 0,
    String? image,
    String? clientId,
    int? battleForUserId,
  }) async {
    final json = await ApiService.instance.call(
      url: WebService.live.recordGift,
      param: {
        'room_id': roomId,
        'gift_id': giftId,
        'coins': coins,
        if (image != null && image.isNotEmpty) 'image': image,
        if (clientId != null && clientId.isNotEmpty) 'client_id': clientId,
        if (battleForUserId != null && battleForUserId > 0)
          'battle_for_user_id': battleForUserId,
      },
      fromJson: (j) => j,
    );
    if (json['status'] != true) {
      throw Exception(json['message'] ?? 'recordGift failed');
    }
    final data = json['data'];
    final list = (data is Map ? data['gift_senders'] : null);
    if (list is! List) return const [];
    return list.map((e) {
      final m = Map<String, dynamic>.from(e as Map);
      return LiveGiftSender(
        userId: m['user_id'] is num
            ? (m['user_id'] as num).toInt()
            : int.tryParse('${m['user_id']}') ?? 0,
        userName: '${m['user_name'] ?? 'User'}',
        totalCoins: m['total_coins'] is num
            ? (m['total_coins'] as num).toInt()
            : int.tryParse('${m['total_coins']}') ?? 0,
        giftCount: m['gift_count'] is num
            ? (m['gift_count'] as num).toInt()
            : int.tryParse('${m['gift_count']}') ?? 0,
        lastGiftImage: m['last_gift_image']?.toString(),
      );
    }).toList();
  }

  Future<LiveChatMessage?> sendComment({
    required String roomId,
    required String clientId,
    required String type,
    String? text,
    String? gifUrl,
  }) async {
    final json = await ApiService.instance.call(
      url: WebService.live.sendComment,
      param: {
        'room_id': roomId,
        'client_id': clientId,
        'type': type,
        if (text != null) 'text': text,
        if (gifUrl != null) 'gif_url': gifUrl,
      },
      fromJson: (j) => j,
    );
    if (json['status'] != true) {
      throw Exception(json['message'] ?? 'sendComment failed');
    }
    final data = json['data'];
    if (data is Map) {
      return LiveChatMessage.fromJson(Map<String, dynamic>.from(data));
    }
    return null;
  }

  Future<LiveCommentsPayload> fetchComments({
    required String roomId,
    int? afterId,
    int limit = 20,
  }) async {
    final json = await ApiService.instance.call(
      url: WebService.live.fetchComments,
      param: {
        'room_id': roomId,
        'limit': limit,
        if (afterId != null && afterId > 0) 'after_id': afterId,
      },
      fromJson: (j) => j,
    );
    if (json['status'] != true) {
      return LiveCommentsPayload(
          comments: const [], lastServerId: afterId ?? 0);
    }
    final data = json['data'];
    if (data is! Map) {
      return LiveCommentsPayload(
          comments: const [], lastServerId: afterId ?? 0);
    }
    final list = (data['comments'] as List?) ?? const [];
    final comments = list
        .map((e) =>
            LiveChatMessage.fromJson(Map<String, dynamic>.from(e as Map)))
        .where((m) => m.type != 'like')
        .toList();
    final last = data['last_server_id'];
    final lastServerId = last is num
        ? last.toInt()
        : int.tryParse('$last') ?? (afterId ?? 0);
    return LiveCommentsPayload(comments: comments, lastServerId: lastServerId);
  }

  Future<LiveSessionPayload?> fetchSession({required String roomId}) async {
    final json = await ApiService.instance.call(
      url: WebService.live.fetchSession,
      param: {'room_id': roomId},
      fromJson: (j) => j,
    );
    if (json['status'] != true) return null;
    final data = json['data'] as Map<String, dynamic>;
    return LiveSessionPayload(
      session: Livestream.fromJson(
          Map<String, dynamic>.from(data['session'] as Map)),
      participants: ((data['participants'] as List?) ?? [])
          .map((e) =>
              LivestreamUserState.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }

  Future<void> invite({required String roomId, required int userId}) async {
    final json = await ApiService.instance.call(
      url: WebService.live.invite,
      param: {
        'room_id': roomId,
        'user_id': userId,
      },
      fromJson: (j) => j,
    );
    if (json['status'] != true) {
      throw Exception(json['message'] ?? 'invite failed');
    }
  }

  Future<Livestream> startBattle({
    required String roomId,
    required int opponentId,
    int durationMinutes = 5,
  }) async {
    final json = await ApiService.instance.call(
      url: WebService.live.startBattle,
      param: {
        'room_id': roomId,
        'opponent_id': opponentId,
        'duration_minutes': durationMinutes,
      },
      fromJson: (j) => j,
    );
    if (json['status'] != true) {
      throw Exception(json['message'] ?? 'start battle failed');
    }
    final data = json['data'] as Map<String, dynamic>;
    return Livestream.fromJson(
        Map<String, dynamic>.from(data['session'] as Map));
  }

  Future<({Livestream session, Livestream? opponentSession, bool accepted})>
      respondBattle({
    required String roomId,
    required bool accept,
  }) async {
    final json = await ApiService.instance.call(
      url: WebService.live.respondBattle,
      param: {
        'room_id': roomId,
        'accept': accept ? '1' : '0',
      },
      fromJson: (j) => j,
    );
    if (json['status'] != true) {
      throw Exception(json['message'] ?? 'respond battle failed');
    }
    final data = json['data'] as Map<String, dynamic>;
    final session = Livestream.fromJson(
        Map<String, dynamic>.from(data['session'] as Map));
    Livestream? opp;
    if (data['opponent_session'] is Map) {
      opp = Livestream.fromJson(
          Map<String, dynamic>.from(data['opponent_session'] as Map));
    }
    final accepted = data['accepted'] == true ||
        data['accepted'] == 1 ||
        '${data['accepted']}' == 'true';
    return (session: session, opponentSession: opp, accepted: accepted);
  }

  Future<Livestream> endBattle({required String roomId}) async {
    final json = await ApiService.instance.call(
      url: WebService.live.endBattle,
      param: {'room_id': roomId},
      fromJson: (j) => j,
    );
    if (json['status'] != true) {
      throw Exception(json['message'] ?? 'end battle failed');
    }
    final data = json['data'] as Map<String, dynamic>;
    return Livestream.fromJson(
        Map<String, dynamic>.from(data['session'] as Map));
  }

  Future<Livestream> restartBattle({
    required String roomId,
    int? durationMinutes,
  }) async {
    final json = await ApiService.instance.call(
      url: WebService.live.restartBattle,
      param: {
        'room_id': roomId,
        if (durationMinutes != null) 'duration_minutes': durationMinutes,
      },
      fromJson: (j) => j,
    );
    if (json['status'] != true) {
      throw Exception(json['message'] ?? 'restart battle failed');
    }
    final data = json['data'] as Map<String, dynamic>;
    return Livestream.fromJson(
        Map<String, dynamic>.from(data['session'] as Map));
  }

  Future<List<Livestream>> pendingInvites() async {
    final json = await ApiService.instance.call(
      url: WebService.live.pendingInvites,
      fromJson: (j) => j,
    );
    if (json['status'] != true) return [];
    final data = json['data'];
    final list = data is List ? data : <dynamic>[];
    return list
        .map((e) => Livestream.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }
}

class LiveLikeResult {
  final int likeCount;
  final int? battleHostCoin;
  final int? battleOpponentCoin;

  const LiveLikeResult({
    required this.likeCount,
    this.battleHostCoin,
    this.battleOpponentCoin,
  });
}
