class CallRequestModel {
  CallRequestModel({
    this.id,
    this.callerId,
    this.calleeId,
    this.coinsCost = 0,
    this.userLevel = 1,
    this.status,
    this.roomId,
    this.matchSeconds = 0,
    this.isMatch = false,
    this.respondedAt,
    this.endedAt,
    this.createdAt,
    this.caller,
    this.callee,
  });

  factory CallRequestModel.fromJson(Map<String, dynamic> json) {
    final matchSeconds = json['match_seconds'] is num
        ? (json['match_seconds'] as num).toInt()
        : int.tryParse('${json['match_seconds'] ?? 0}') ?? 0;
    final roomId = json['room_id']?.toString();
    final isMatchFlag = json['is_match'] == true ||
        json['is_match'] == 1 ||
        '${json['is_match']}' == '1' ||
        matchSeconds > 0 ||
        (roomId ?? '').toLowerCase().startsWith('match');
    return CallRequestModel(
      id: json['id'] is num ? (json['id'] as num).toInt() : int.tryParse('${json['id']}'),
      callerId: json['caller_id'] is num
          ? (json['caller_id'] as num).toInt()
          : int.tryParse('${json['caller_id']}'),
      calleeId: json['callee_id'] is num
          ? (json['callee_id'] as num).toInt()
          : int.tryParse('${json['callee_id']}'),
      coinsCost: json['coins_cost'] is num
          ? (json['coins_cost'] as num).toInt()
          : int.tryParse('${json['coins_cost'] ?? 0}') ?? 0,
      userLevel: json['user_level'] is num
          ? (json['user_level'] as num).toInt()
          : int.tryParse('${json['user_level'] ?? 1}') ?? 1,
      status: json['status']?.toString(),
      roomId: roomId,
      matchSeconds: matchSeconds > 0
          ? matchSeconds
          : (matchSecondsFromRoomId(roomId) ?? 0),
      isMatch: isMatchFlag,
      respondedAt: json['responded_at']?.toString(),
      endedAt: json['ended_at']?.toString(),
      createdAt: json['created_at']?.toString(),
      caller: json['caller'] is Map
          ? CallParty.fromJson(Map<String, dynamic>.from(json['caller']))
          : null,
      callee: json['callee'] is Map
          ? CallParty.fromJson(Map<String, dynamic>.from(json['callee']))
          : null,
    );
  }

  static int? matchSecondsFromRoomId(String? roomId) {
    if (roomId == null || roomId.isEmpty) return null;
    final m = RegExp(r'^match(\d+)_', caseSensitive: false).firstMatch(roomId);
    if (m == null) return null;
    return int.tryParse(m.group(1)!);
  }

  final int? id;
  final int? callerId;
  final int? calleeId;
  final int coinsCost;
  final int userLevel;
  final String? status;
  final String? roomId;
  /// Ventana Match planificada (s). >0 o [isMatch] = llamada Match.
  final int matchSeconds;
  final bool isMatch;
  final String? respondedAt;
  final String? endedAt;
  final String? createdAt;
  final CallParty? caller;
  final CallParty? callee;

  bool get isPending =>
      (status ?? '').toLowerCase().trim() == 'pending';
  bool get isAccepted =>
      (status ?? '').toLowerCase().trim() == 'accepted';
  bool get isRejected =>
      (status ?? '').toLowerCase().trim() == 'rejected';

  /// True si viene del flujo Match (misma lógica de llamada, naming distinto).
  bool get isMatchSession =>
      isMatch ||
      matchSeconds > 0 ||
      (roomId ?? '').toLowerCase().startsWith('match');

  CallRequestModel copyWith({
    int? id,
    int? callerId,
    int? calleeId,
    int? coinsCost,
    int? userLevel,
    String? status,
    String? roomId,
    int? matchSeconds,
    bool? isMatch,
    String? respondedAt,
    String? endedAt,
    String? createdAt,
    CallParty? caller,
    CallParty? callee,
  }) {
    return CallRequestModel(
      id: id ?? this.id,
      callerId: callerId ?? this.callerId,
      calleeId: calleeId ?? this.calleeId,
      coinsCost: coinsCost ?? this.coinsCost,
      userLevel: userLevel ?? this.userLevel,
      status: status ?? this.status,
      roomId: roomId ?? this.roomId,
      matchSeconds: matchSeconds ?? this.matchSeconds,
      isMatch: isMatch ?? this.isMatch,
      respondedAt: respondedAt ?? this.respondedAt,
      endedAt: endedAt ?? this.endedAt,
      createdAt: createdAt ?? this.createdAt,
      caller: caller ?? this.caller,
      callee: callee ?? this.callee,
    );
  }
}

class CallParty {
  CallParty({
    this.id,
    this.username,
    this.fullname,
    this.profilePhoto,
    this.isVerify,
    this.levelNumber,
    this.levelTitle,
    this.canReceiveCalls = 0,
    this.callRequestCoins = 0,
  });

  factory CallParty.fromJson(Map<String, dynamic> json) {
    return CallParty(
      id: json['id'] is num ? (json['id'] as num).toInt() : int.tryParse('${json['id']}'),
      username: json['username']?.toString(),
      fullname: json['fullname']?.toString(),
      profilePhoto: json['profile_photo']?.toString(),
      isVerify: json['is_verify'] is num
          ? (json['is_verify'] as num).toInt()
          : int.tryParse('${json['is_verify'] ?? 0}'),
      levelNumber: json['level_number'] is num
          ? (json['level_number'] as num).toInt()
          : int.tryParse('${json['level_number'] ?? 1}'),
      levelTitle: json['level_title']?.toString(),
      canReceiveCalls: json['can_receive_calls'] is num
          ? (json['can_receive_calls'] as num).toInt()
          : int.tryParse('${json['can_receive_calls'] ?? 0}') ?? 0,
      callRequestCoins: json['call_request_coins'] is num
          ? (json['call_request_coins'] as num).toInt()
          : int.tryParse('${json['call_request_coins'] ?? 0}') ?? 0,
    );
  }

  final int? id;
  final String? username;
  final String? fullname;
  final String? profilePhoto;
  final int? isVerify;
  final int? levelNumber;
  final String? levelTitle;
  final int canReceiveCalls;
  final int callRequestCoins;
}
