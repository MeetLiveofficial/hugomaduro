import 'package:krimson/model/user_model/streamer_average.dart';

class StreamerWorkStats {
  StreamerWorkStats({
    required this.user,
    required this.today,
    required this.weeklyLevel,
    required this.benefits,
    this.callPricing,
    this.average,
  });

  factory StreamerWorkStats.fromJson(Map<String, dynamic> json) {
    return StreamerWorkStats(
      user: WorkUserStats.fromJson(
          Map<String, dynamic>.from(json['user'] as Map? ?? {})),
      today: WorkTodayStats.fromJson(
          Map<String, dynamic>.from(json['today'] as Map? ?? {})),
      weeklyLevel: WorkWeeklyLevel.fromJson(
          Map<String, dynamic>.from(json['weekly_level'] as Map? ?? {})),
      benefits: (json['benefits'] as List? ?? [])
          .map((e) => e.toString())
          .where((e) => e.isNotEmpty)
          .toList(),
      callPricing: json['call_pricing'] is Map
          ? WorkCallPricing.fromJson(
              Map<String, dynamic>.from(json['call_pricing']))
          : null,
      average: json['streamer_average'] is Map
          ? StreamerAverage.fromJson(json['streamer_average'])
          : null,
    );
  }

  final WorkUserStats user;
  final WorkTodayStats today;
  final WorkWeeklyLevel weeklyLevel;
  final List<String> benefits;
  final WorkCallPricing? callPricing;
  final StreamerAverage? average;
}

class WorkCallPricing {
  WorkCallPricing({
    this.canEdit = false,
    this.grade = 'NEW',
    this.levelPrice = 0,
    this.overridePrice,
    this.effectivePrice = 0,
    this.min = 0,
    this.max = 0,
  });

  factory WorkCallPricing.fromJson(Map<String, dynamic> json) {
    return WorkCallPricing(
      canEdit: json['can_edit'] == true,
      grade: json['grade']?.toString() ?? 'NEW',
      levelPrice: _asInt(json['level_price']) ?? 0,
      overridePrice: _asInt(json['override_price']),
      effectivePrice: _asInt(json['effective_price']) ?? 0,
      min: _asInt(json['min']) ?? 0,
      max: _asInt(json['max']) ?? 0,
    );
  }

  final bool canEdit;
  final String grade;
  final int levelPrice;
  final int? overridePrice;
  final int effectivePrice;
  final int min;
  final int max;
}

class WorkUserStats {
  WorkUserStats({
    this.id,
    this.fullname,
    this.username,
    this.profilePhoto,
    this.isActive = 0,
    this.levelNumber = 1,
    this.levelTitle,
    this.coinWallet = 0,
    this.withdrawalPoints = 0,
    this.coinCollectedLifetime = 0,
    this.totalPostLikesCount = 0,
  });

  factory WorkUserStats.fromJson(Map<String, dynamic> json) {
    return WorkUserStats(
      id: _asInt(json['id']),
      fullname: json['fullname']?.toString(),
      username: json['username']?.toString(),
      profilePhoto: json['profile_photo']?.toString(),
      isActive: _asInt(json['is_active']) ?? 0,
      levelNumber: _asInt(json['level_number']) ?? 1,
      levelTitle: json['level_title']?.toString(),
      coinWallet: _asInt(json['coin_wallet']) ?? 0,
      withdrawalPoints: _asInt(json['withdrawal_points']) ?? 0,
      coinCollectedLifetime: _asInt(json['coin_collected_lifetime']) ?? 0,
      totalPostLikesCount: _asInt(json['total_post_likes_count']) ?? 0,
    );
  }

  final int? id;
  final String? fullname;
  final String? username;
  final String? profilePhoto;
  final int isActive;
  final int levelNumber;
  final String? levelTitle;
  final int coinWallet;
  final int withdrawalPoints;
  final int coinCollectedLifetime;
  final int totalPostLikesCount;
}

class WorkTodayStats {
  WorkTodayStats({
    this.calls = 0,
    this.likes = 0,
    this.rejections = 0,
    this.rejectionRate = 0,
    this.avgDurationSec = 0,
    this.avgDuration = '00:00:00',
    this.onlineSeconds = 0,
    this.onlineTime = '00:00:00',
    this.positiveRate = 100,
    this.earningsCalls = 0,
    this.earningsGifts = 0,
    this.earningsTasks = 0,
    this.earningsInvites = 0,
    this.earningsManaged = 0,
  });

  factory WorkTodayStats.fromJson(Map<String, dynamic> json) {
    return WorkTodayStats(
      calls: _asInt(json['calls']) ?? 0,
      likes: _asInt(json['likes']) ?? 0,
      rejections: _asInt(json['rejections']) ?? 0,
      rejectionRate: _asDouble(json['rejection_rate']) ?? 0,
      avgDurationSec: _asInt(json['avg_duration_sec']) ?? 0,
      avgDuration: json['avg_duration']?.toString() ?? '00:00:00',
      onlineSeconds: _asInt(json['online_seconds']) ?? 0,
      onlineTime: json['online_time']?.toString() ?? '00:00:00',
      positiveRate: _asDouble(json['positive_rate']) ?? 100,
      earningsCalls: _asInt(json['earnings_calls']) ?? 0,
      earningsGifts: _asInt(json['earnings_gifts']) ?? 0,
      earningsTasks: _asInt(json['earnings_tasks']) ?? 0,
      earningsInvites: _asInt(json['earnings_invites']) ?? 0,
      earningsManaged: _asInt(json['earnings_managed']) ?? 0,
    );
  }

  final int calls;
  final int likes;
  final int rejections;
  final double rejectionRate;
  final int avgDurationSec;
  final String avgDuration;
  final int onlineSeconds;
  final String onlineTime;
  final double positiveRate;
  final int earningsCalls;
  final int earningsGifts;
  final int earningsTasks;
  final int earningsInvites;
  final int earningsManaged;
}

class WorkWeeklyLevel {
  static const List<String> kGrades = ['NEW', 'C', 'B', 'A', 'S'];

  WorkWeeklyLevel({
    this.grade = 'NEW',
    this.grades = kGrades,
    this.goalMet = false,
    WorkWeekSlice? thisWeek,
    WorkWeekSlice? lastWeek,
  })  : thisWeek = thisWeek ?? WorkWeekSlice(),
        lastWeek = lastWeek ?? WorkWeekSlice();

  factory WorkWeeklyLevel.fromJson(Map<String, dynamic> json) {
    var grade = (json['grade']?.toString() ?? 'NEW').toUpperCase().trim();
    if (grade == 'SS') grade = 'S';
    if (grade == 'D') grade = 'NEW';
    if (!kGrades.contains(grade)) grade = 'NEW';
    return WorkWeeklyLevel(
      grade: grade,
      grades: kGrades,
      goalMet: json['goal_met'] == true,
      thisWeek: WorkWeekSlice.fromJson(
          Map<String, dynamic>.from(json['this_week'] as Map? ?? {})),
      lastWeek: WorkWeekSlice.fromJson(
          Map<String, dynamic>.from(json['last_week'] as Map? ?? {})),
    );
  }

  final String grade;
  final List<String> grades;
  final bool goalMet;
  final WorkWeekSlice thisWeek;
  final WorkWeekSlice lastWeek;

  double get progress {
    final n = grades.length;
    if (n <= 1) return 1;
    final i = grades.indexOf(grade);
    if (i < 0) return 0.05;
    // Los iconos van con spaceBetween: el nivel actual queda en i/(n-1).
    return (i / (n - 1)).clamp(i == 0 ? 0.05 : 0.0, 1.0);
  }
}

class WorkWeekSlice {
  WorkWeekSlice({
    this.responseRate = 0,
    this.responseRateLabel = '0',
    this.avgDuration = '-',
    this.levelCalls = 0,
    this.updatedAt,
  });

  factory WorkWeekSlice.fromJson(Map<String, dynamic> json) {
    return WorkWeekSlice(
      responseRate: _asDouble(json['response_rate']) ?? 0,
      responseRateLabel: json['response_rate_label']?.toString() ?? '0',
      avgDuration: json['avg_duration']?.toString() ?? '-',
      levelCalls: _asInt(json['level_calls']) ?? 0,
      updatedAt: json['updated_at']?.toString(),
    );
  }

  final double responseRate;
  final String responseRateLabel;
  final String avgDuration;
  final int levelCalls;
  final String? updatedAt;
}

int? _asInt(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse('$v');
}

double? _asDouble(dynamic v) {
  if (v == null) return null;
  if (v is double) return v;
  if (v is num) return v.toDouble();
  return double.tryParse('$v');
}
