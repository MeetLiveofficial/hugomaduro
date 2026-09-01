class CallRequestModel {
  CallRequestModel({
    this.id,
    this.callerId,
    this.calleeId,
    this.coinsCost = 0,
    this.billedMinutes = 0,
    this.billedCoins = 0,
    this.userLevel = 1,
    this.status,
    this.matchPhase,
    this.roomId,
    this.matchSeconds = 0,
    this.isMatch = false,
    this.respondedAt,
    this.startedAt,
    this.phaseEndsAt,
    this.graceEndsAt,
    this.secondsLeft = 0,
    this.graceSecondsLeft = 0,
    this.endedAt,
    this.endedReason,
    this.createdAt,
    this.caller,
    this.callee,
    this.myCoinWallet,
    this.cameraFlipUnlocked = false,
    this.cameraOffUnlocked = false,
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
      billedMinutes: json['billed_minutes'] is num
          ? (json['billed_minutes'] as num).toInt()
          : int.tryParse('${json['billed_minutes'] ?? 0}') ?? 0,
      billedCoins: json['billed_coins'] is num
          ? (json['billed_coins'] as num).toInt()
          : int.tryParse('${json['billed_coins'] ?? 0}') ?? 0,
      userLevel: json['user_level'] is num
          ? (json['user_level'] as num).toInt()
          : int.tryParse('${json['user_level'] ?? 1}') ?? 1,
      status: json['status']?.toString(),
      matchPhase: json['match_phase']?.toString(),
      roomId: roomId,
      matchSeconds: matchSeconds > 0
          ? matchSeconds
          : (matchSecondsFromRoomId(roomId) ?? 0),
      isMatch: isMatchFlag,
      respondedAt: json['responded_at']?.toString(),
      startedAt: json['started_at']?.toString(),
      phaseEndsAt: json['phase_ends_at']?.toString(),
      graceEndsAt: json['grace_ends_at']?.toString(),
      secondsLeft: json['seconds_left'] is num
          ? (json['seconds_left'] as num).toInt()
          : int.tryParse('${json['seconds_left'] ?? 0}') ?? 0,
      graceSecondsLeft: json['grace_seconds_left'] is num
          ? (json['grace_seconds_left'] as num).toInt()
          : int.tryParse('${json['grace_seconds_left'] ?? 0}') ?? 0,
      endedAt: json['ended_at']?.toString(),
      endedReason: json['ended_reason']?.toString(),
      createdAt: json['created_at']?.toString(),
      caller: json['caller'] is Map
          ? CallParty.fromJson(Map<String, dynamic>.from(json['caller']))
          : null,
      callee: json['callee'] is Map
          ? CallParty.fromJson(Map<String, dynamic>.from(json['callee']))
          : null,
      myCoinWallet: json['my_coin_wallet'] is num
          ? (json['my_coin_wallet'] as num).toInt()
          : int.tryParse('${json['my_coin_wallet'] ?? ''}'),
      cameraFlipUnlocked: json['camera_flip_unlocked'] == true ||
          json['camera_flip_unlocked'] == 1 ||
          '${json['camera_flip_unlocked']}' == '1',
      cameraOffUnlocked: json['camera_off_unlocked'] == true ||
          json['camera_off_unlocked'] == 1 ||
          '${json['camera_off_unlocked']}' == '1',
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
  final int billedMinutes;
  final int billedCoins;
  final int userLevel;
  final String? status;
  final String? matchPhase;
  final String? roomId;
  /// Ventana Match planificada (s). >0 o [isMatch] = llamada Match.
  final int matchSeconds;
  final bool isMatch;
  final String? respondedAt;
  final String? startedAt;
  final String? phaseEndsAt;
  final String? graceEndsAt;
  final int secondsLeft;
  final int graceSecondsLeft;
  final String? endedAt;
  final String? endedReason;
  final String? createdAt;
  final CallParty? caller;
  final CallParty? callee;
  final int? myCoinWallet;
  final bool cameraFlipUnlocked;
  final bool cameraOffUnlocked;

  bool get isPending =>
      (status ?? '').toLowerCase().trim() == 'pending';
  bool get isAccepted =>
      (status ?? '').toLowerCase().trim() == 'accepted';
  bool get isRejected =>
      (status ?? '').toLowerCase().trim() == 'rejected';
  bool get isEnded =>
      (status ?? '').toLowerCase().trim() == 'ended' ||
      (status ?? '').toLowerCase().trim() == 'cancelled' ||
      (status ?? '').toLowerCase().trim() == 'expired';
  bool get isExtensionWindow =>
      (matchPhase ?? '').toLowerCase().trim() == 'extension_window';

  /// True si viene del flujo Match (misma lógica de llamada, naming distinto).
  bool get isMatchSession =>
      isMatch ||
      matchSeconds > 0 ||
      (roomId ?? '').toLowerCase().startsWith('match');

  bool get endedForInsufficientCoins =>
      (endedReason ?? '').toLowerCase().trim() == 'insufficient_coins';

  CallRequestModel copyWith({
    int? id,
    int? callerId,
    int? calleeId,
    int? coinsCost,
    int? billedMinutes,
    int? billedCoins,
    int? userLevel,
    String? status,
    String? matchPhase,
    String? roomId,
    int? matchSeconds,
    bool? isMatch,
    String? respondedAt,
    String? startedAt,
    String? phaseEndsAt,
    String? graceEndsAt,
    int? secondsLeft,
    int? graceSecondsLeft,
    String? endedAt,
    String? endedReason,
    String? createdAt,
    CallParty? caller,
    CallParty? callee,
    int? myCoinWallet,
    bool? cameraFlipUnlocked,
    bool? cameraOffUnlocked,
  }) {
    return CallRequestModel(
      id: id ?? this.id,
      callerId: callerId ?? this.callerId,
      calleeId: calleeId ?? this.calleeId,
      coinsCost: coinsCost ?? this.coinsCost,
      billedMinutes: billedMinutes ?? this.billedMinutes,
      billedCoins: billedCoins ?? this.billedCoins,
      userLevel: userLevel ?? this.userLevel,
      status: status ?? this.status,
      matchPhase: matchPhase ?? this.matchPhase,
      roomId: roomId ?? this.roomId,
      matchSeconds: matchSeconds ?? this.matchSeconds,
      isMatch: isMatch ?? this.isMatch,
      respondedAt: respondedAt ?? this.respondedAt,
      startedAt: startedAt ?? this.startedAt,
      phaseEndsAt: phaseEndsAt ?? this.phaseEndsAt,
      graceEndsAt: graceEndsAt ?? this.graceEndsAt,
      secondsLeft: secondsLeft ?? this.secondsLeft,
      graceSecondsLeft: graceSecondsLeft ?? this.graceSecondsLeft,
      endedAt: endedAt ?? this.endedAt,
      endedReason: endedReason ?? this.endedReason,
      createdAt: createdAt ?? this.createdAt,
      caller: caller ?? this.caller,
      callee: callee ?? this.callee,
      myCoinWallet: myCoinWallet ?? this.myCoinWallet,
      cameraFlipUnlocked: cameraFlipUnlocked ?? this.cameraFlipUnlocked,
      cameraOffUnlocked: cameraOffUnlocked ?? this.cameraOffUnlocked,
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
