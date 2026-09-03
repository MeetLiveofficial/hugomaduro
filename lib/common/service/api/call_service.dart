import 'package:krimson/common/service/api/api_service.dart';
import 'package:krimson/common/service/api/live_session_service.dart';
import 'package:krimson/common/service/utils/web_service.dart';
import 'package:krimson/model/call/call_request_model.dart';
import 'package:krimson/model/general/settings_model.dart';
import 'package:krimson/model/livestream/live_chat_message.dart';
import 'package:krimson/model/user_model/user_model.dart';
import 'package:krimson/model/work/streamer_work_stats_model.dart';

class CallService {
  CallService._();
  static final CallService instance = CallService._();

  Future<CallRequestModel> create({
    required int userId,
    bool isMatch = false,
    int? matchSeconds,
    int? coinsCost,
    int? tier,
  }) async {
    final json = await ApiService.instance.call<Map<String, dynamic>>(
      url: WebService.call.create,
      param: {
        'user_id': userId,
        if (isMatch) 'is_match': 1,
        if (matchSeconds != null && matchSeconds > 0)
          'match_seconds': matchSeconds,
        if (coinsCost != null && coinsCost > 0) 'coins_cost': coinsCost,
        if (tier != null && tier >= 1 && tier <= 3) 'tier': tier,
      },
      fromJson: (j) => j,
    );
    if (json['status'] != true) {
      throw Exception(json['message'] ?? 'call create failed');
    }
    return CallRequestModel.fromJson(
        Map<String, dynamic>.from(json['data'] as Map));
  }

  /// Recomienda streamer del pool de Match (sin filtrar país ni idioma).
  /// [mode]: `random` (default) o `goddess` (prioriza grados A/S).
  /// [excludeUserIds]: streamers ya vistos (swipe al siguiente).
  Future<MatchRecommendation> findMatch({
    String mode = 'random',
    List<int> excludeUserIds = const [],
  }) async {
    final exclude = excludeUserIds.where((id) => id > 0).toSet().toList();
    final json = await ApiService.instance.call<Map<String, dynamic>>(
      url: WebService.call.findMatch,
      param: {
        if (mode.trim().isNotEmpty) 'mode': mode.trim().toLowerCase(),
        if (exclude.isNotEmpty) 'exclude_user_ids': exclude.join(','),
      },
      fromJson: (j) => j,
    );
    if (json['status'] != true) {
      throw Exception(json['message'] ?? 'no match available');
    }
    final data = Map<String, dynamic>.from(json['data'] as Map? ?? {});
    final userMap = data['user'];
    if (userMap is! Map) {
      throw Exception('no match available');
    }
    final primary = User.fromJson(Map<String, dynamic>.from(userMap));
    final users = <User>[];
    final rawUsers = data['users'];
    if (rawUsers is List) {
      for (final e in rawUsers) {
        if (e is Map) {
          users.add(User.fromJson(Map<String, dynamic>.from(e)));
        }
      }
    }
    if (users.isEmpty) {
      users.add(primary);
    } else if (primary.id != null &&
        users.every((u) => u.id != primary.id)) {
      users.insert(0, primary);
    }
    return MatchRecommendation(
      user: users.first,
      users: users,
      callCost: data['call_cost'] is num
          ? (data['call_cost'] as num).toInt()
          : int.tryParse('${data['call_cost'] ?? 0}') ?? 0,
      matchFreeSeconds: data['match_free_seconds'] is num
          ? (data['match_free_seconds'] as num).toInt()
          : int.tryParse('${data['match_free_seconds'] ?? 40}') ?? 40,
      matchInitialCoins: data['match_initial_coins'] is num
          ? (data['match_initial_coins'] as num).toInt()
          : int.tryParse('${data['match_initial_coins'] ?? 0}') ?? 0,
      matchGraceSeconds: data['match_grace_seconds'] is num
          ? (data['match_grace_seconds'] as num).toInt()
          : int.tryParse('${data['match_grace_seconds'] ?? 10}') ?? 10,
      matchTiers: MatchTier.listFrom(
        data['match_config'] is Map
            ? (data['match_config'] as Map)['tiers']
            : data['match_tiers'],
      ),
      appLanguage: data['app_language']?.toString(),
      waitRoomId: data['wait_room_id']?.toString(),
      previewSeconds: data['preview_seconds'] is num
          ? (data['preview_seconds'] as num).toInt()
          : int.tryParse('${data['preview_seconds'] ?? 0}') ?? 0,
    );
  }

  /// Paga (si hace falta) la entrada para ver streamers en Match.
  /// Los coins van al monedero de la APP, no al streamer.
  Future<MatchUnlockResult> unlockMatch({String mode = 'random'}) async {
    final json = await ApiService.instance.call<Map<String, dynamic>>(
      url: WebService.call.unlockMatch,
      param: {'mode': mode},
      fromJson: (j) => j,
    );
    if (json['status'] != true) {
      throw Exception(json['message'] ?? 'unlock match failed');
    }
    final data = Map<String, dynamic>.from(json['data'] as Map? ?? {});
    return MatchUnlockResult(
      charged: data['charged'] is num
          ? (data['charged'] as num).toInt()
          : int.tryParse('${data['charged'] ?? 0}') ?? 0,
      coinWallet: data['coin_wallet'] is num
          ? (data['coin_wallet'] as num).toInt()
          : int.tryParse('${data['coin_wallet'] ?? 0}') ?? 0,
      matchTiers: MatchTier.listFrom(
        data['match_config'] is Map
            ? (data['match_config'] as Map)['tiers']
            : null,
      ),
    );
  }

  Future<String?> joinMatch() async {
    final json = await ApiService.instance.call<Map<String, dynamic>>(
      url: WebService.call.joinMatch,
      param: const {},
      fromJson: (j) => j,
    );
    if (json['status'] != true) {
      throw Exception(json['message'] ?? 'join match failed');
    }
    final data = json['data'];
    if (data is Map) {
      final room = data['wait_room_id']?.toString().trim();
      if (room != null && room.isNotEmpty) return room;
    }
    return null;
  }

  Future<void> leaveMatch() async {
    await _matchPresence(WebService.call.leaveMatch);
  }

  Future<void> matchHeartbeat() async {
    await _matchPresence(WebService.call.matchHeartbeat);
  }

  Future<void> _matchPresence(String url) async {
    try {
      await ApiService.instance.call<Map<String, dynamic>>(
        url: url,
        param: const {},
        fromJson: (j) => j,
      );
    } catch (e) {
      // Presencia: no bloquear la UI si el backend aún no tiene el endpoint.
    }
  }

  Future<CallInboxResult> inbox() async {
    final json = await ApiService.instance.call<Map<String, dynamic>>(
      url: WebService.call.inbox,
      conditionalGet: true,
      fromJson: (j) => j,
    );
    if (json['status'] != true) {
      throw Exception(json['message'] ?? 'call inbox failed');
    }
    final data = json['data'] as Map<String, dynamic>? ?? {};
    final received = (data['received'] as List? ?? [])
        .map((e) => CallRequestModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
    final sent = (data['sent'] as List? ?? [])
        .map((e) => CallRequestModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
    return CallInboxResult(received: received, sent: sent);
  }

  Future<CallRequestModel> accept(int callRequestId) async {
    return _mutate(WebService.call.accept, callRequestId);
  }

  Future<CallRequestModel> status(int callRequestId) async {
    return _mutate(WebService.call.status, callRequestId);
  }

  Future<CallRequestModel> reject(int callRequestId) async {
    return _mutate(WebService.call.reject, callRequestId);
  }

  Future<CallRequestModel> cancel(int callRequestId) async {
    return _mutate(WebService.call.cancel, callRequestId);
  }

  Future<CallRequestModel> end(int callRequestId) async {
    return _mutate(WebService.call.end, callRequestId);
  }

  /// Alarga el Match en la misma llamada (misma room LiveKit).
  Future<CallRequestModel> extendMatch({
    required int callRequestId,
    int? tier,
    int? extraSeconds,
    int? coinsCost,
  }) async {
    final json = await ApiService.instance.call<Map<String, dynamic>>(
      url: WebService.call.extendMatch,
      param: {
        'call_request_id': callRequestId,
        if (tier != null && tier >= 1 && tier <= 3) 'tier': tier,
        if (extraSeconds != null && extraSeconds > 0)
          'extra_seconds': extraSeconds,
        if (coinsCost != null && coinsCost > 0) 'coins_cost': coinsCost,
      },
      fromJson: (j) => j,
    );
    if (json['status'] != true) {
      throw Exception(json['message'] ?? 'extend match failed');
    }
    return CallRequestModel.fromJson(
        Map<String, dynamic>.from(json['data'] as Map));
  }

  Future<StreamerWorkStats> workStats() async {
    final json = await ApiService.instance.call<Map<String, dynamic>>(
      url: WebService.call.workStats,
      fromJson: (j) => j,
    );
    if (json['status'] != true) {
      throw Exception(json['message'] ?? 'work stats failed');
    }
    return StreamerWorkStats.fromJson(
        Map<String, dynamic>.from(json['data'] as Map? ?? {}));
  }

  Future<Map<String, dynamic>> updateCallPrice({required int callPrice}) async {
    final json = await ApiService.instance.call<Map<String, dynamic>>(
      url: WebService.call.updateCallPrice,
      param: {'call_price': callPrice},
      fromJson: (j) => j,
    );
    if (json['status'] != true) {
      throw Exception(json['message'] ?? 'update call price failed');
    }
    return Map<String, dynamic>.from(json['data'] as Map? ?? {});
  }

  Future<LiveChatMessage?> sendComment({
    required int callRequestId,
    required String clientId,
    required String type,
    String? text,
    String? gifUrl,
  }) async {
    final json = await ApiService.instance.call(
      url: WebService.call.sendComment,
      param: {
        'call_request_id': callRequestId,
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
    required int callRequestId,
    int? afterId,
    int limit = 20,
  }) async {
    final json = await ApiService.instance.call(
      url: WebService.call.fetchComments,
      param: {
        'call_request_id': callRequestId,
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
        .toList();
    final last = data['last_server_id'];
    final lastServerId = last is num
        ? last.toInt()
        : int.tryParse('$last') ?? (afterId ?? 0);
    return LiveCommentsPayload(comments: comments, lastServerId: lastServerId);
  }

  /// Desbloquea flip o apagado de cámara (Cliente) en una llamada/Match activa.
  /// [feature]: `flip` | `camera_off`
  Future<CallRequestModel> purchaseCameraFeature({
    required int callRequestId,
    required String feature,
  }) async {
    final json = await ApiService.instance.call<Map<String, dynamic>>(
      url: WebService.call.purchaseCameraFeature,
      param: {
        'call_request_id': callRequestId,
        'feature': feature,
      },
      fromJson: (j) => j,
    );
    if (json['status'] != true) {
      throw Exception(json['message'] ?? 'purchase failed');
    }
    final data = Map<String, dynamic>.from(json['data'] as Map? ?? {});
    final callMap = data['call'];
    if (callMap is Map) {
      return CallRequestModel.fromJson(Map<String, dynamic>.from(callMap));
    }
    throw Exception('invalid purchase response');
  }

  Future<CallRequestModel> _mutate(String url, int callRequestId) async {
    final json = await ApiService.instance.call<Map<String, dynamic>>(
      url: url,
      param: {'call_request_id': callRequestId},
      fromJson: (j) => j,
    );
    if (json['status'] != true) {
      throw Exception(json['message'] ?? 'call action failed');
    }
    return CallRequestModel.fromJson(
        Map<String, dynamic>.from(json['data'] as Map));
  }
}

class CallInboxResult {
  CallInboxResult({required this.received, required this.sent});
  final List<CallRequestModel> received;
  final List<CallRequestModel> sent;
}

class MatchRecommendation {
  MatchRecommendation({
    required this.user,
    required this.callCost,
    this.matchFreeSeconds = 40,
    this.matchInitialCoins = 0,
    this.matchGraceSeconds = 10,
    List<MatchTier>? matchTiers,
    this.appLanguage,
    List<User>? users,
    this.waitRoomId,
    this.previewSeconds = 0,
  })  : users = (users == null || users.isEmpty) ? [user] : users,
        matchTiers = matchTiers ?? MatchTier.defaults;

  final User user;
  final List<User> users;
  final int callCost;
  final int matchFreeSeconds;
  final int matchInitialCoins;
  final int matchGraceSeconds;
  final List<MatchTier> matchTiers;
  final String? appLanguage;
  final String? waitRoomId;
  final int previewSeconds;

  String roomIdFor(User u) {
    final id = u.id ?? 0;
    if (u.id == user.id && (waitRoomId ?? '').trim().isNotEmpty) {
      return waitRoomId!.trim();
    }
    return id > 0 ? 'matchwait_$id' : '';
  }
}

class MatchUnlockResult {
  MatchUnlockResult({
    required this.charged,
    required this.coinWallet,
    List<MatchTier>? matchTiers,
  }) : matchTiers = matchTiers ?? MatchTier.defaults;

  final int charged;
  final int coinWallet;
  final List<MatchTier> matchTiers;
}
