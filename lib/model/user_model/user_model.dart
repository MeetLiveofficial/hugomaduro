import 'dart:convert';

import 'package:krimson/common/extensions/common_extension.dart';
import 'package:krimson/common/manager/session_manager.dart';
import 'package:krimson/model/general/settings_model.dart';
import 'package:krimson/model/post_story/story/story_model.dart';

class UserModel {
  UserModel({
    bool? status,
    String? message,
    User? data,
  }) {
    _status = status;
    _message = message;
    _data = data;
  }

  UserModel.fromJson(dynamic json) {
    _status = _readBool(json['status']);
    _message = json['message']?.toString();
    _data = json['data'] != null ? User.fromJson(json['data']) : null;
  }

  static bool? _readBool(dynamic value) {
    if (value == null) return null;
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final v = value.toLowerCase().trim();
      return v == 'true' || v == '1' || v == 'yes';
    }
    return null;
  }

  bool? _status;
  String? _message;
  User? _data;

  bool? get status => _status;

  String? get message => _message;

  User? get data => _data;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['status'] = _status;
    map['message'] = _message;
    if (_data != null) {
      map['data'] = _data?.toJson();
    }
    return map;
  }
}

class User {
  User(
      {this.id,
      this.identity,
      this.isDummy,
      this.isAnonymous,
      this.fullname,
      this.username,
      this.userEmail,
      this.dob,
      this.mobileCountryCode,
      this.userMobileNo,
      this.profilePhoto,
      this.loginMethod,
      this.device,
      this.deviceToken,
      this.notifyPostLike,
      this.notifyPostComment,
      this.notifyFollow,
      this.notifyMention,
      this.notifyGiftReceived,
      this.notifyChat,
      this.isVerify,
      this.kycStatus,
      this.diditSessionId,
      this.kycVerifiedAt,
      this.whoCanViewPost,
      this.showMyFollowing,
      this.receiveMessage,
      this.matchEnabled = 1,
      this.coinWallet,
      this.withdrawalPoints,
      this.withdrawWalletAccount,
      this.coinCollectedLifetime,
      this.coinGiftedLifetime,
      this.coinPurchasedLifetime,
      this.bio,
      this.followerCount,
      this.followingCount,
      this.totalPostLikesCount,
      this.isFreez,
      this.country,
      this.countryCode,
      this.region,
      this.regionName,
      this.city,
      this.lat,
      this.lon,
      this.timezone,
      this.appLastUsedAt,
      this.savedMusicIds,
      this.isModerator,
      this.createdAt,
      this.updatedAt,
      this.isFollowing,
      this.followStatus,
      this.isBlock,
      this.links,
      this.stories,
      this.appLanguage,
      this.newRegister,
      this.followingIds,
      this.levelNumber,
      this.levelTitle,
      this.callRequestCoins = 0,
      this.canReceiveCalls = 0,
      this.canGoLive = 0,
      this.appRole,
      this.agencyId,
      this.agencyName,
      this.isAgencyWorker = 0,
      this.weeklyCallGrade,
      this.levelBenefits = const [],
      this.impressionQualities = const [],
      this.impressionRating,
      this.equippedFrame,
      this.equippedBadge});

  User copyWith({
    int? id,
    int? isDummy,
    int? isAnonymous,
    String? identity,
    String? fullname,
    String? username,
    String? userEmail,
    String? dob,
    int? mobileCountryCode,
    String? userMobileNo,
    String? profilePhoto,
    String? loginMethod,
    int? device,
    String? deviceToken,
    int? notifyPostLike,
    int? notifyPostComment,
    int? notifyFollow,
    int? notifyMention,
    int? notifyGiftReceived,
    int? notifyChat,
    int? isVerify,
    String? kycStatus,
    String? diditSessionId,
    String? kycVerifiedAt,
    int? whoCanViewPost,
    int? showMyFollowing,
    int? receiveMessage,
    int? matchEnabled,
    int? coinWallet,
    int? withdrawalPoints,
    int? coinCollectedLifetime,
    int? coinGiftedLifetime,
    int? coinPurchasedLifetime,
    String? bio,
    int? followerCount,
    int? followingCount,
    int? totalPostLikesCount,
    int? isFreez,
    String? country,
    String? countryCode,
    dynamic region,
    dynamic regionName,
    dynamic city,
    double? lat,
    double? lon,
    String? timezone,
    dynamic appLastUsedAt,
    String? savedMusicIds,
    int? isModerator,
    String? appLanguage,
    dynamic password,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isFollowing,
    int? followStatus,
    bool? isBlock,
    bool? newRegister,
    List<Link>? links,
    List<Story>? stories,
    List<int>? followingIds,
    int? levelNumber,
    String? levelTitle,
    int? callRequestCoins,
    int? canReceiveCalls,
    int? canGoLive,
    String? appRole,
    String? weeklyCallGrade,
    List<String>? levelBenefits,
    List<ImpressionQuality>? impressionQualities,
    double? impressionRating,
    Map<String, dynamic>? equippedFrame,
    Map<String, dynamic>? equippedBadge,
  }) =>
      User(
        id: id ?? this.id,
        isDummy: isDummy ?? this.isDummy,
        isAnonymous: isAnonymous ?? this.isAnonymous,
        identity: identity ?? this.identity,
        fullname: fullname ?? this.fullname,
        username: username ?? this.username,
        userEmail: userEmail ?? this.userEmail,
        dob: dob ?? this.dob,
        mobileCountryCode: mobileCountryCode ?? this.mobileCountryCode,
        userMobileNo: userMobileNo ?? this.userMobileNo,
        profilePhoto: profilePhoto ?? this.profilePhoto,
        loginMethod: loginMethod ?? this.loginMethod,
        device: device ?? this.device,
        deviceToken: deviceToken ?? this.deviceToken,
        notifyPostLike: notifyPostLike ?? this.notifyPostLike,
        notifyPostComment: notifyPostComment ?? this.notifyPostComment,
        notifyFollow: notifyFollow ?? this.notifyFollow,
        notifyMention: notifyMention ?? this.notifyMention,
        notifyGiftReceived: notifyGiftReceived ?? this.notifyGiftReceived,
        notifyChat: notifyChat ?? this.notifyChat,
        isVerify: isVerify ?? this.isVerify,
        kycStatus: kycStatus ?? this.kycStatus,
        diditSessionId: diditSessionId ?? this.diditSessionId,
        kycVerifiedAt: kycVerifiedAt ?? this.kycVerifiedAt,
        whoCanViewPost: whoCanViewPost ?? this.whoCanViewPost,
        showMyFollowing: showMyFollowing ?? this.showMyFollowing,
        receiveMessage: receiveMessage ?? this.receiveMessage,
        matchEnabled: matchEnabled ?? this.matchEnabled,
        coinWallet: coinWallet ?? this.coinWallet,
        withdrawalPoints: withdrawalPoints ?? this.withdrawalPoints,
        coinCollectedLifetime:
            coinCollectedLifetime ?? this.coinCollectedLifetime,
        coinGiftedLifetime: coinGiftedLifetime ?? this.coinGiftedLifetime,
        coinPurchasedLifetime:
            coinPurchasedLifetime ?? this.coinPurchasedLifetime,
        bio: bio ?? this.bio,
        followerCount: followerCount ?? this.followerCount,
        followingCount: followingCount ?? this.followingCount,
        totalPostLikesCount: totalPostLikesCount ?? this.totalPostLikesCount,
        isFreez: isFreez ?? this.isFreez,
        country: country ?? this.country,
        countryCode: countryCode ?? this.countryCode,
        region: region ?? this.region,
        regionName: regionName ?? this.regionName,
        city: city ?? this.city,
        lat: lat ?? this.lat,
        lon: lon ?? this.lon,
        timezone: timezone ?? this.timezone,
        appLastUsedAt: appLastUsedAt ?? this.appLastUsedAt,
        savedMusicIds: savedMusicIds ?? this.savedMusicIds,
        isModerator: isModerator ?? this.isModerator,
        appLanguage: appLanguage ?? this.appLanguage,
        isFollowing: isFollowing ?? this.isFollowing,
        followStatus: followStatus ?? this.followStatus,
        isBlock: isBlock ?? this.isBlock,
        links: links ?? this.links,
        stories: stories ?? this.stories,
        newRegister: newRegister ?? this.newRegister,
        followingIds: followingIds ?? this.followingIds,
        levelNumber: levelNumber ?? this.levelNumber,
        levelTitle: levelTitle ?? this.levelTitle,
        callRequestCoins: callRequestCoins ?? this.callRequestCoins,
        canReceiveCalls: canReceiveCalls ?? this.canReceiveCalls,
        canGoLive: canGoLive ?? this.canGoLive,
        appRole: appRole ?? this.appRole,
        weeklyCallGrade: weeklyCallGrade ?? this.weeklyCallGrade,
        levelBenefits: levelBenefits ?? this.levelBenefits,
        impressionQualities: impressionQualities ?? this.impressionQualities,
        impressionRating: impressionRating ?? this.impressionRating,
        equippedFrame: equippedFrame ?? this.equippedFrame,
        equippedBadge: equippedBadge ?? this.equippedBadge,
      );

  static num? _asNum(dynamic v) {
    if (v == null) return null;
    if (v is num) return v;
    return num.tryParse('$v');
  }

  static int? _asInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse('$v');
  }

  User.fromJson(dynamic json) {
    id = _asInt(json['id']);
    identity = json['identity']?.toString();
    isDummy = _asInt(json['is_dummy']);
    isAnonymous = _asInt(json['is_anonymous']);
    fullname = json['fullname']?.toString();
    username = json['username']?.toString();
    userEmail = json['user_email']?.toString();
    dob = json['dob']?.toString();
    mobileCountryCode = _asInt(json['mobile_country_code']);
    userMobileNo = json['user_mobile_no']?.toString();
    profilePhoto = json['profile_photo']?.toString();
    loginMethod = json['login_method']?.toString();
    device = _asInt(json['device']);
    deviceToken = json['device_token']?.toString();
    notifyPostLike = _asNum(json['notify_post_like']);
    notifyPostComment = _asNum(json['notify_post_comment']);
    notifyFollow = _asNum(json['notify_follow']);
    notifyMention = _asNum(json['notify_mention']);
    notifyGiftReceived = _asNum(json['notify_gift_received']);
    notifyChat = _asNum(json['notify_chat']);
    isVerify = _asInt(json['is_verify']);
    kycStatus = json['kyc_status']?.toString();
    diditSessionId = json['didit_session_id']?.toString();
    kycVerifiedAt = json['kyc_verified_at']?.toString();
    whoCanViewPost = _asNum(json['who_can_view_post']);
    showMyFollowing = _asNum(json['show_my_following']);
    receiveMessage = _asNum(json['receive_message']);
    matchEnabled = _asNum(json['match_enabled']) ?? 1;
    coinWallet = _asNum(json['coin_wallet']);
    withdrawalPoints = _asInt(json['withdrawal_points']);
    withdrawWalletAccount = json['withdraw_wallet_account']?.toString();
    coinCollectedLifetime = _asNum(json['coin_collected_lifetime']);
    coinGiftedLifetime = _asNum(json['coin_gifted_lifetime']);
    coinPurchasedLifetime = _asNum(json['coin_purchased_lifetime']);
    bio = json['bio']?.toString();
    followerCount = _asNum(json['follower_count']);
    followingCount = _asNum(json['following_count']);
    totalPostLikesCount = _asInt(json['total_post_likes_count']);
    isFreez = _asNum(json['is_freez']);
    country = json['country']?.toString();
    countryCode = json['countryCode']?.toString();
    region = json['region']?.toString();
    regionName = json['regionName']?.toString();
    city = json['city']?.toString();
    lat = _asNum(json['lat']);
    lon = _asNum(json['lon']);
    timezone = json['timezone']?.toString();
    appLastUsedAt = json['app_last_used_at']?.toString();
    savedMusicIds = json['saved_music_ids']?.toString();
    isModerator = _asInt(json['is_moderator']);
    createdAt = json['created_at']?.toString();
    updatedAt = json['updated_at']?.toString();
    isFollowing = json['is_following'] == null
        ? null
        : (json['is_following'] == true || json['is_following'] == 1);
    followStatus = _asInt(json['follow_status']);
    isBlock = json['is_block'] == null
        ? null
        : (json['is_block'] == true || json['is_block'] == 1);
    appLanguage = json['app_language']?.toString();
    newRegister = json['new_register'] == null
        ? null
        : (json['new_register'] == true || json['new_register'] == 1);
    levelNumber = _asInt(json['level_number']);
    levelTitle = json['level_title']?.toString();
    callRequestCoins = _asInt(json['call_request_coins']) ?? 0;
    canReceiveCalls = _asInt(json['can_receive_calls']) ?? 0;
    canGoLive = _asInt(json['can_go_live']) ?? 0;
    appRole = json['app_role']?.toString();
    agencyId = _asInt(json['agency_id']);
    agencyName = json['agency_name']?.toString();
    isAgencyWorker = _asInt(json['is_agency_worker']) ?? 0;
    weeklyCallGrade = json['weekly_call_grade']?.toString();
    isLive = _asInt(json['is_live']) ?? 0;
    liveRoomId = json['live_room_id']?.toString();
    isActive = _asInt(json['is_active']) ?? 0;
    inCall = _asInt(json['in_call']) ?? 0;
    lastCallAt = json['last_call_at']?.toString();
    liveViewers = _asInt(json['live_viewers']) ?? 0;
    isVip = _asInt(json['is_vip']) ?? 0;
    vipExpiresAt = json['vip_expires_at']?.toString();
    dailyFreeMatchesQuota = _asInt(json['daily_free_matches_quota']) ?? 2;
    dailyFreeMatchesUsed = _asInt(json['daily_free_matches_used']) ?? 0;
    dailyFreeMatchesRemaining =
        _asInt(json['daily_free_matches_remaining']) ??
            (dailyFreeMatchesQuota - dailyFreeMatchesUsed)
                .clamp(0, dailyFreeMatchesQuota)
                .toInt();
    if (json['level_benefits'] is List) {
      levelBenefits = (json['level_benefits'] as List)
          .map((e) => e.toString())
          .where((e) => e.isNotEmpty)
          .toList();
    }
    token = json['token'] != null ? Token.fromJson(json['token']) : null;
    followingIds = json["following_ids"] != null
        ? List<int>.from(json["following_ids"].map((x) => x))
        : null;
    if (json['links'] != null) {
      links = [];
      json['links'].forEach((v) {
        links?.add(Link.fromJson(v));
      });
    }
    if (json['stories'] != null) {
      stories = [];
      json['stories'].forEach((v) {
        var s = Story.fromJson(v);
        s.user = this;
        stories?.add(s);
      });
    }
    if (json['equipped_frame'] is Map) {
      equippedFrame = Map<String, dynamic>.from(json['equipped_frame']);
    }
    if (json['equipped_badge'] is Map) {
      equippedBadge = Map<String, dynamic>.from(json['equipped_badge']);
    }
    impressionQualities = ImpressionQuality.listFrom(json['impression_qualities']);
    impressionRating = _asNum(json['impression_rating'])?.toDouble();
  }

  int? id;
  String? identity;
  int? isDummy;
  int? isAnonymous;
  String? fullname;
  String? username;
  String? userEmail;
  String? dob;
  int? mobileCountryCode;
  String? userMobileNo;
  String? profilePhoto;
  String? loginMethod;
  int? device;
  String? deviceToken;
  num? notifyPostLike;
  num? notifyPostComment;
  num? notifyFollow;
  num? notifyMention;
  num? notifyGiftReceived;
  num? notifyChat;
  int? isVerify;
  String? kycStatus;
  String? diditSessionId;
  String? kycVerifiedAt;
  num? whoCanViewPost;

  /// Didit KYC approved (or grandfathered PLUS+ with is_verify).
  bool get isKycApproved {
    if ((kycStatus ?? 'none').toLowerCase() == 'approved') return true;
    // Fallback before migration / old cached session: verified badge holders.
    return (isVerify ?? 0) == 1 &&
        (kycStatus == null ||
            kycStatus == '' ||
            kycStatus == 'none');
  }
  num? showMyFollowing;
  num? receiveMessage;
  /// 1 = acepta Match de clientes; 0 = no aparece en Match.
  num matchEnabled = 1;
  num? coinWallet;
  int? withdrawalPoints;
  String? withdrawWalletAccount;
  num? coinCollectedLifetime;
  num? coinGiftedLifetime;
  num? coinPurchasedLifetime;
  String? bio;
  num? followerCount;
  num? followingCount;
  int? totalPostLikesCount;
  num? isFreez;
  String? country;
  String? countryCode;
  String? region;
  String? regionName;
  String? city;
  num? lat;
  num? lon;
  String? timezone;
  String? appLastUsedAt;
  String? savedMusicIds;
  int? isModerator;
  String? createdAt;
  String? updatedAt;
  String? appLanguage;
  bool? isFollowing;
  int? followStatus;
  bool? isBlock;
  bool? newRegister;
  Token? token;
  List<Link>? links;
  List<int>? followingIds;
  List<Story>? stories;
  int? levelNumber;
  String? levelTitle;
  int callRequestCoins = 0;
  int canReceiveCalls = 0;
  int canGoLive = 0;
  /// `streamer` | `client` | `agency`
  String? appRole;
  int? agencyId;
  String? agencyName;
  int isAgencyWorker = 0;
  /// Rango semanal de llamadas: NEW, C, B, A, S.
  String? weeklyCallGrade;
  List<String> levelBenefits = const [];
  int isLive = 0;
  String? liveRoomId;
  int isActive = 0;
  int inCall = 0;
  String? lastCallAt;
  int liveViewers = 0;
  int isVip = 0;
  String? vipExpiresAt;
  int dailyFreeMatchesQuota = 2;
  int dailyFreeMatchesUsed = 0;
  int dailyFreeMatchesRemaining = 2;
  List<ImpressionQuality> impressionQualities = const [];
  double? impressionRating;
  Map<String, dynamic>? equippedFrame;
  Map<String, dynamic>? equippedBadge;

  String? get equippedFrameImage {
    final v = equippedFrame?['image']?.toString().trim();
    return (v == null || v.isEmpty) ? null : v;
  }

  double get framePhotoRatio {
    final v = equippedFrame?['photo_ratio'];
    if (v is num && v > 0.15 && v < 0.9) {
      return v.toDouble();
    }
    return 0.62;
  }

  String? get effectiveStreamerGrade {
    final g = (weeklyCallGrade ?? '').trim();
    if (g.isNotEmpty) return g;
    if ((appRole ?? '').toLowerCase() == 'streamer') return 'NEW';
    return null;
  }

  bool get isVipActive => isVip == 1;

  bool get isAnonymousUser => (isAnonymous ?? 0) == 1;

  String? get equippedBadgeImage {
    final v = equippedBadge?['image']?.toString().trim();
    return (v == null || v.isEmpty) ? null : v;
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = id;
    map['is_dummy'] = isDummy;
    map['is_anonymous'] = isAnonymous;
    map['identity'] = identity;
    map['fullname'] = fullname;
    map['username'] = username;
    map['user_email'] = userEmail;
    map['dob'] = dob;
    map['mobile_country_code'] = mobileCountryCode;
    map['user_mobile_no'] = userMobileNo;
    map['profile_photo'] = profilePhoto;
    map['login_method'] = loginMethod;
    map['device'] = device;
    map['device_token'] = deviceToken;
    map['notify_post_like'] = notifyPostLike;
    map['notify_post_comment'] = notifyPostComment;
    map['notify_follow'] = notifyFollow;
    map['notify_mention'] = notifyMention;
    map['notify_gift_received'] = notifyGiftReceived;
    map['notify_chat'] = notifyChat;
    map['is_verify'] = isVerify;
    map['kyc_status'] = kycStatus;
    map['didit_session_id'] = diditSessionId;
    map['kyc_verified_at'] = kycVerifiedAt;
    map['who_can_view_post'] = whoCanViewPost;
    map['show_my_following'] = showMyFollowing;
    map['receive_message'] = receiveMessage;
    map['match_enabled'] = matchEnabled;
    map['coin_wallet'] = coinWallet;
    map['withdrawal_points'] = withdrawalPoints;
    map['withdraw_wallet_account'] = withdrawWalletAccount;
    map['coin_collected_lifetime'] = coinCollectedLifetime;
    map['coin_gifted_lifetime'] = coinGiftedLifetime;
    map['coin_purchased_lifetime'] = coinPurchasedLifetime;
    map['bio'] = bio;
    map['follower_count'] = followerCount;
    map['following_count'] = followingCount;
    map['total_post_likes_count'] = totalPostLikesCount;
    map['is_freez'] = isFreez;
    map['country'] = country;
    map['countryCode'] = countryCode;
    map['region'] = region;
    map['regionName'] = regionName;
    map['city'] = city;
    map['lat'] = lat;
    map['lon'] = lon;
    map['timezone'] = timezone;
    map['app_last_used_at'] = appLastUsedAt;
    map['saved_music_ids'] = savedMusicIds;
    map['is_moderator'] = isModerator;
    map['created_at'] = createdAt;
    map['updated_at'] = updatedAt;
    map['is_following'] = isFollowing;
    map['follow_status'] = followStatus;
    map['is_block'] = isBlock;
    map['new_register'] = newRegister;
    map['app_language'] = appLanguage;
    map['level_number'] = levelNumber;
    map['level_title'] = levelTitle;
    map['call_request_coins'] = callRequestCoins;
    map['can_receive_calls'] = canReceiveCalls;
    map['can_go_live'] = canGoLive;
    map['app_role'] = appRole;
    map['agency_id'] = agencyId;
    map['agency_name'] = agencyName;
    map['is_agency_worker'] = isAgencyWorker;
    map['weekly_call_grade'] = weeklyCallGrade;
    map['level_benefits'] = levelBenefits;
    map['is_live'] = isLive;
    map['live_room_id'] = liveRoomId;
    map['is_active'] = isActive;
    map['in_call'] = inCall;
    map['last_call_at'] = lastCallAt;
    map['live_viewers'] = liveViewers;
    map['is_vip'] = isVip;
    map['vip_expires_at'] = vipExpiresAt;
    map['daily_free_matches_quota'] = dailyFreeMatchesQuota;
    map['daily_free_matches_used'] = dailyFreeMatchesUsed;
    map['daily_free_matches_remaining'] = dailyFreeMatchesRemaining;
    map['impression_qualities'] =
        impressionQualities.map((e) => e.toJson()).toList();
    map['impression_rating'] = impressionRating;
    map['equipped_frame'] = equippedFrame;
    map['equipped_badge'] = equippedBadge;
    map["following_ids"] = followingIds;
    if (token != null) {
      map['token'] = token?.toJson();
    }
    if (links != null) {
      map['links'] = links?.map((v) => v.toJson()).toList();
    }
    if (stories != null) {
      map['stories'] = stories?.map((v) => v.toJson()).toList();
    }
    return map;
  }

  void checkIsBlocked(Function completion) {
    if (isBlock == false || id == SessionManager.instance.getUserID()) {
      completion();
    }
  }

  void updateFollowerCount(bool isFollowing) {
    int i = isFollowing ? 1 : -1;
    followerCount = ((followerCount ?? 0) + i)
        .clamp(0, double.infinity)
        .toInt(); // followerCount not less then 0
  }

  void updateBlockStatus(bool isBlock) {
    this.isBlock = isBlock;
  }

  double coinEstimatedValue(double? coinValue) {
    return (coinWallet?.toInt() ?? 0) * (coinValue ?? 0);
  }

  num removeCoinFromWallet(num amount) {
    return coinWallet = (coinWallet ?? 0) - amount;
  }

  UserLevel get getLevel {
    return (coinCollectedLifetime ?? 0).getUserLevelByTotalCoins;
  }
}

class Link {
  Link({
    this.id,
    this.userId,
    this.title,
    this.url,
    this.createdAt,
    this.updatedAt,
  });

  Link.fromJson(dynamic json) {
    id = json['id'];
    userId = json['user_id'];
    title = json['title'];
    url = json['url'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
  }

  num? id;
  num? userId;
  String? title;
  String? url;
  String? createdAt;
  String? updatedAt;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = id;
    map['user_id'] = userId;
    map['title'] = title;
    map['url'] = url;
    map['created_at'] = createdAt;
    map['updated_at'] = updatedAt;
    return map;
  }
}

class ImpressionQuality {
  final int? id;
  final String label;
  final int stars;
  final int votes;
  final bool isPick;
  final bool checked;

  const ImpressionQuality({
    required this.label,
    this.id,
    this.stars = 0,
    this.votes = 0,
    this.isPick = false,
    this.checked = false,
  });

  ImpressionQuality copyWith({bool? checked}) {
    return ImpressionQuality(
      id: id,
      label: label,
      stars: stars,
      votes: votes,
      isPick: isPick,
      checked: checked ?? this.checked,
    );
  }

  int get clampedStars => stars.clamp(0, 5);

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'stars': clampedStars,
        'votes': votes,
        'is_pick': isPick ? 1 : 0,
        'checked': checked ? 1 : 0,
      };

  static List<ImpressionQuality> listFrom(dynamic raw) {
    List<dynamic> rows = const [];
    if (raw is List) {
      rows = raw;
    } else if (raw is String && raw.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is List) rows = decoded;
      } catch (_) {}
    }
    final out = <ImpressionQuality>[];
    for (final row in rows) {
      if (row is! Map) continue;
      final label = (row['label'] ?? row['name'])?.toString().trim() ?? '';
      if (label.isEmpty) continue;
      final stars = User._asInt(row['stars'] ?? row['rating']) ?? 0;
      final votes = User._asInt(row['votes'] ?? row['vote_count']) ?? 0;
      final isPick = row['is_pick'] == true ||
          row['is_pick'] == 1 ||
          '${row['is_pick']}' == '1';
      final checked = row['checked'] == true ||
          row['checked'] == 1 ||
          '${row['checked']}' == '1';
      out.add(ImpressionQuality(
        id: User._asInt(row['id']),
        label: label,
        stars: stars.clamp(0, 5),
        votes: votes < 0 ? 0 : votes,
        isPick: isPick,
        checked: checked,
      ));
    }
    return out;
  }
}

class Token {
  Token({
    this.userId,
    this.authToken,
    this.updatedAt,
    this.createdAt,
    this.id,
  });

  Token.fromJson(dynamic json) {
    userId = json['user_id'];
    authToken = json['auth_token'];
    updatedAt = json['updated_at'];
    createdAt = json['created_at'];
    id = json['id'];
  }

  num? userId;
  String? authToken;
  String? updatedAt;
  String? createdAt;
  num? id;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['user_id'] = userId;
    map['auth_token'] = authToken;
    map['updated_at'] = updatedAt;
    map['created_at'] = createdAt;
    map['id'] = id;
    return map;
  }
}
