import 'package:krimson/common/service/api/api_service.dart';
import 'package:krimson/common/service/utils/web_service.dart';
import 'package:krimson/model/livestream/livestream.dart';
import 'package:krimson/model/livestream/livestream_user_state.dart';

class LiveSessionPayload {
  LiveSessionPayload({required this.session, required this.participants});
  final Livestream session;
  final List<LivestreamUserState> participants;
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
}
