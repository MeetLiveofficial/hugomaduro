import 'package:get/get.dart';
import 'package:krimson/model/livestream/app_user.dart';

class LivestreamUserState {
  VideoAudioStatus audioStatus;
  VideoAudioStatus videoStatus;
  LivestreamUserType type;
  int userId;
  int liveCoin;

  int currentBattleCoin;
  int totalBattleCoin;
  List<int> followersGained;
  int joinStreamTime;
  AppUser? user;
  /// 1 = usuario en videollamada mientras sigue en la sesión LIVE.
  bool inCall;

  LivestreamUserState({
    this.audioStatus = VideoAudioStatus.on,
    this.videoStatus = VideoAudioStatus.on,
    required this.type,
    required this.userId,
    required this.liveCoin,
    required this.currentBattleCoin,
    required this.totalBattleCoin,
    required this.followersGained,
    required this.joinStreamTime,
    this.user,
    this.inCall = false,
  });

  factory LivestreamUserState.fromJson(Map<String, dynamic> json) {
    final inCallRaw = json['in_call'] ?? json['inCall'] ?? 0;
    final inCall = inCallRaw == true ||
        inCallRaw == 1 ||
        inCallRaw == '1' ||
        '${inCallRaw}'.toLowerCase() == 'true';
    return LivestreamUserState(
      audioStatus: VideoAudioStatus.fromString(json['audio_status']),
      videoStatus: VideoAudioStatus.fromString(json['video_status']),
      type: LivestreamUserType.fromString(json['type'] ?? ''),
      userId: json['user_id'] ?? 0,
      liveCoin: json['live_coin'] ?? 0,
      currentBattleCoin: json['current_battle_coin'] ?? 0,
      totalBattleCoin: json['total_battle_coin'] ?? 0,
      followersGained: json['followers_gained'] is List
          ? (json['followers_gained'] as List)
              .map((e) => int.tryParse('$e') ?? 0)
              .toList()
          : <int>[],
      joinStreamTime: json['join_stream_time'] ?? 0,
      user: json['user'] != null ? AppUser.fromJson(json['user']) : null,
      inCall: inCall,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'audio_status': audioStatus.value,
      'video_status': videoStatus.value,
      'type': type.value,
      'user_id': userId,
      'live_coin': liveCoin,
      'current_battle_coin': currentBattleCoin,
      'total_battle_coin': totalBattleCoin,
      'followers_gained': followersGained,
      'join_stream_time': joinStreamTime,
      'in_call': inCall ? 1 : 0,
      if (user != null) 'user': user?.toJson()
    };
  }

  AppUser? getUser(List<AppUser> users) {
    return users.firstWhereOrNull((element) => element.userId == userId);
  }

  int get totalCoin {
    return totalBattleCoin + liveCoin;
  }
}

enum LivestreamUserType {
  host('HOST'),
  coHost('CO-HOST'),
  audience('AUDIENCE'),
  requested('REQUESTED'),
  invited('INVITED'),
  left('LEFT');

  final String value;

  const LivestreamUserType(this.value);

  static LivestreamUserType fromString(String value) {
    return LivestreamUserType.values.firstWhereOrNull(
          (e) => e.value == value,
        ) ??
        LivestreamUserType.audience;
  }
}

enum VideoAudioStatus {
  on('ON'),
  offByMe('OFF_BY_ME'),
  offByHost('OFF_BY_HOST');

  final String value;

  const VideoAudioStatus(this.value);

  static VideoAudioStatus fromString(String value) {
    return VideoAudioStatus.values.firstWhereOrNull((e) => e.value == value) ??
        VideoAudioStatus.on;
  }
}
