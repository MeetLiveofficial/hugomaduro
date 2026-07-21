class AppUser {
  int? userId;
  String? username;
  String? fullname;
  String? profile;
  int? isVerify;
  String? identity;
  /// 1 = ACTIVE (app abierta / LIVE reciente).
  int isActive;
  /// 1 = en transmisión LIVE ahora.
  int isLive;

  AppUser({
    this.userId,
    this.username,
    this.fullname,
    this.profile,
    this.isVerify,
    this.identity,
    this.isActive = 0,
    this.isLive = 0,
  });

  bool get isPresent => isActive == 1 || isLive == 1;

  AppUser.fromJson(Map<String, dynamic> json)
      : isActive = _asInt(json['is_active']) ?? 0,
        isLive = _asInt(json['is_live']) ?? 0 {
    userId = json['user_id'];
    identity = json['identity'];
    username = json['username'];
    fullname = json['fullname'];
    profile = json['profile'];
    isVerify = json['is_verify'];
  }

  static int? _asInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse('$v');
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['user_id'] = userId;
    data['identity'] = identity;
    data['username'] = username;
    data['fullname'] = fullname;
    data['profile'] = profile;
    data['is_verify'] = isVerify;
    data['is_active'] = isActive;
    data['is_live'] = isLive;
    return data;
  }
}
