class AgencyDashboard {
  AgencyDashboard({
    this.agencyId = 0,
    this.agencyCode = '',
    this.agencyWallet = 0,
    this.agencyCollected = 0,
    this.count = 0,
    AgencyDashboardTotals? totals,
    List<AgencyWorker>? workers,
  })  : totals = totals ?? AgencyDashboardTotals(),
        workers = workers ?? <AgencyWorker>[];

  factory AgencyDashboard.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map
        ? Map<String, dynamic>.from(json['data'] as Map)
        : json;
    final rawWorkers = data['workers'];
    return AgencyDashboard(
      agencyId: _asInt(data['agency_id']),
      agencyCode: (data['agency_code'] ?? '').toString().trim().toUpperCase(),
      agencyWallet: _asInt(data['agency_wallet']),
      agencyCollected: _asInt(data['agency_collected']),
      count: _asInt(data['count']),
      totals: data['totals'] is Map
          ? AgencyDashboardTotals.fromJson(
              Map<String, dynamic>.from(data['totals'] as Map))
          : AgencyDashboardTotals(),
      workers: rawWorkers is List
          ? rawWorkers
              .whereType<Map>()
              .map((e) =>
                  AgencyWorker.fromJson(Map<String, dynamic>.from(e)))
              .toList()
          : <AgencyWorker>[],
    );
  }

  final int agencyId;
  final String agencyCode;
  final int agencyWallet;
  final int agencyCollected;
  final int count;
  final AgencyDashboardTotals totals;
  final List<AgencyWorker> workers;
}

class AgencyDashboardTotals {
  AgencyDashboardTotals({
    this.streamerEarnedToday = 0,
    this.streamerEarnedWeek = 0,
    this.streamerEarnedMonth = 0,
    this.streamerEarnedLifetime = 0,
    this.agencyEarnedToday = 0,
    this.agencyEarnedWeek = 0,
    this.agencyEarnedMonth = 0,
    this.agencyEarnedLifetime = 0,
  });

  factory AgencyDashboardTotals.fromJson(Map<String, dynamic> json) {
    return AgencyDashboardTotals(
      streamerEarnedToday: _asInt(json['streamer_earned_today']),
      streamerEarnedWeek: _asInt(json['streamer_earned_week']),
      streamerEarnedMonth: _asInt(json['streamer_earned_month']),
      streamerEarnedLifetime: _asInt(json['streamer_earned_lifetime']),
      agencyEarnedToday: _asInt(json['agency_earned_today']),
      agencyEarnedWeek: _asInt(json['agency_earned_week']),
      agencyEarnedMonth: _asInt(json['agency_earned_month']),
      agencyEarnedLifetime: _asInt(json['agency_earned_lifetime']),
    );
  }

  final int streamerEarnedToday;
  final int streamerEarnedWeek;
  final int streamerEarnedMonth;
  final int streamerEarnedLifetime;
  final int agencyEarnedToday;
  final int agencyEarnedWeek;
  final int agencyEarnedMonth;
  final int agencyEarnedLifetime;
}

class AgencyWorker {
  AgencyWorker({required this.user, AgencyWorkerStats? stats})
      : stats = stats ?? AgencyWorkerStats();

  factory AgencyWorker.fromJson(Map<String, dynamic> json) {
    return AgencyWorker(
      user: UserLite.fromJson(json),
      stats: json['stats'] is Map
          ? AgencyWorkerStats.fromJson(
              Map<String, dynamic>.from(json['stats'] as Map))
          : AgencyWorkerStats(
              streamerWallet: _asInt(json['coin_wallet']),
              streamerEarnedLifetime:
                  _asInt(json['coin_collected_lifetime']),
            ),
    );
  }

  final UserLite user;
  final AgencyWorkerStats stats;
}

class UserLite {
  UserLite({
    this.id,
    this.fullname,
    this.username,
    this.identity,
    this.userEmail,
    this.profilePhoto,
    this.weeklyCallGrade,
    this.isFreez = 0,
  });

  factory UserLite.fromJson(Map<String, dynamic> json) {
    return UserLite(
      id: _asInt(json['id']),
      fullname: json['fullname']?.toString(),
      username: json['username']?.toString(),
      identity: json['identity']?.toString(),
      userEmail: json['user_email']?.toString(),
      profilePhoto: json['profile_photo']?.toString(),
      weeklyCallGrade: json['weekly_call_grade']?.toString(),
      isFreez: _asInt(json['is_freez']),
    );
  }

  final int? id;
  final String? fullname;
  final String? username;
  final String? identity;
  final String? userEmail;
  final String? profilePhoto;
  final String? weeklyCallGrade;
  final int isFreez;

  String get displayName {
    final name = (fullname ?? '').trim();
    if (name.isNotEmpty) return name;
    final user = (username ?? '').trim();
    if (user.isNotEmpty) return user;
    return 'Streamer';
  }

  String get handle {
    final user = (username ?? '').trim();
    if (user.isNotEmpty) return '@$user';
    return identity ?? userEmail ?? '';
  }
}

class AgencyWorkerStats {
  AgencyWorkerStats({
    this.streamerWallet = 0,
    this.streamerEarnedLifetime = 0,
    this.streamerEarnedToday = 0,
    this.streamerEarnedWeek = 0,
    this.streamerEarnedMonth = 0,
    this.agencyEarnedLifetime = 0,
    this.agencyEarnedToday = 0,
    this.agencyEarnedWeek = 0,
    this.agencyEarnedMonth = 0,
    this.giftsCount = 0,
    this.callsCount = 0,
    this.live = 0,
    this.chat = 0,
    this.call = 0,
    this.gift = 0,
  });

  factory AgencyWorkerStats.fromJson(Map<String, dynamic> json) {
    final bySource = json['by_source'] is Map
        ? Map<String, dynamic>.from(json['by_source'] as Map)
        : const <String, dynamic>{};
    return AgencyWorkerStats(
      streamerWallet: _asInt(json['streamer_wallet']),
      streamerEarnedLifetime: _asInt(json['streamer_earned_lifetime']),
      streamerEarnedToday: _asInt(json['streamer_earned_today']),
      streamerEarnedWeek: _asInt(json['streamer_earned_week']),
      streamerEarnedMonth: _asInt(json['streamer_earned_month']),
      agencyEarnedLifetime: _asInt(json['agency_earned_lifetime']),
      agencyEarnedToday: _asInt(json['agency_earned_today']),
      agencyEarnedWeek: _asInt(json['agency_earned_week']),
      agencyEarnedMonth: _asInt(json['agency_earned_month']),
      giftsCount: _asInt(json['gifts_count']),
      callsCount: _asInt(json['calls_count']),
      live: _asInt(bySource['live']),
      chat: _asInt(bySource['chat']),
      call: _asInt(bySource['call']),
      gift: _asInt(bySource['gift']),
    );
  }

  final int streamerWallet;
  final int streamerEarnedLifetime;
  final int streamerEarnedToday;
  final int streamerEarnedWeek;
  final int streamerEarnedMonth;
  final int agencyEarnedLifetime;
  final int agencyEarnedToday;
  final int agencyEarnedWeek;
  final int agencyEarnedMonth;
  final int giftsCount;
  final int callsCount;
  final int live;
  final int chat;
  final int call;
  final int gift;
}

int _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse('$value') ?? 0;
}
