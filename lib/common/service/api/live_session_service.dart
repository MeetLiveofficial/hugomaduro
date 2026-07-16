import 'package:krimson/common/service/api/api_service.dart';
import 'package:krimson/common/service/utils/web_service.dart';
import 'package:krimson/model/livestream/live_chat_message.dart';
import 'package:krimson/model/livestream/livestream.dart';
import 'package:krimson/model/livestream/livestream_user_state.dart';

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

  Future<int> like({required String roomId}) async {
    final json = await ApiService.instance.call(
      url: WebService.live.like,
      param: {'room_id': roomId},
      fromJson: (j) => j,
    );
    if (json['status'] != true) {
      throw Exception(json['message'] ?? 'like failed');
    }
    final data = json['data'];
    if (data is Map && data['like_count'] != null) {
      return data['like_count'] is num
          ? (data['like_count'] as num).toInt()
          : int.tryParse('${data['like_count']}') ?? 0;
    }
    return 0;
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
