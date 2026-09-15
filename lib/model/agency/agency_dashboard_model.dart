class AgencyDashboard {
  AgencyDashboard({
    this.agencyId = 0,
    this.agencyCode = '',
    this.agencyWallet = 0,
    this.agencyCollected = 0,
    this.count = 0,
    AgencyDashboardTotals? totals,
    AgencyWithdrawalSummary? withdrawals,
    AgencyWithdrawalSummary? streamerWithdrawals,
    List<AgencyWithdrawalItem>? recentWithdrawals,
    List<AgencyWorker>? workers,
  })  : totals = totals ?? AgencyDashboardTotals(),
        withdrawals = withdrawals ?? AgencyWithdrawalSummary(),
        streamerWithdrawals = streamerWithdrawals ?? AgencyWithdrawalSummary(),
        recentWithdrawals = recentWithdrawals ?? <AgencyWithdrawalItem>[],
        workers = workers ?? <AgencyWorker>[];

  factory AgencyDashboard.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map
        ? Map<String, dynamic>.from(json['data'] as Map)
        : json;
    return AgencyDashboard(
      agencyId: _asInt(data['agency_id']),
      agencyCode: _normalizeAgencyCode(data['agency_code']),
      agencyWallet: _asInt(data['agency_wallet']),
      agencyCollected: _asInt(data['agency_collected']),
      count: _asInt(data['count']),
      totals: data['totals'] is Map
          ? AgencyDashboardTotals.fromJson(
              Map<String, dynamic>.from(data['totals'] as Map))
          : AgencyDashboardTotals(),
      withdrawals: data['withdrawals'] is Map
          ? AgencyWithdrawalSummary.fromJson(
              Map<String, dynamic>.from(data['withdrawals'] as Map))
          : AgencyWithdrawalSummary(),
      streamerWithdrawals: data['streamer_withdrawals'] is Map
          ? AgencyWithdrawalSummary.fromJson(
              Map<String, dynamic>.from(data['streamer_withdrawals'] as Map))
          : AgencyWithdrawalSummary(),
      recentWithdrawals: _parseRecent(data['recent_withdrawals']),
      workers: _parseWorkers(data['workers']),
    );
  }

  AgencyDashboard withCode(String code) {
    return AgencyDashboard(
      agencyId: agencyId,
      agencyCode: _normalizeAgencyCode(code),
      agencyWallet: agencyWallet,
      agencyCollected: agencyCollected,
      count: count,
      totals: totals,
      withdrawals: withdrawals,
      streamerWithdrawals: streamerWithdrawals,
      recentWithdrawals: recentWithdrawals,
      workers: workers,
    );
  }

  final int agencyId;
  final String agencyCode;
  final int agencyWallet;
  final int agencyCollected;
  final int count;
  final AgencyDashboardTotals totals;
  final AgencyWithdrawalSummary withdrawals;
  final AgencyWithdrawalSummary streamerWithdrawals;
  final List<AgencyWithdrawalItem> recentWithdrawals;
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

class AgencyWithdrawalSummary {
  AgencyWithdrawalSummary({
    this.pendingCount = 0,
    this.completedCount = 0,
    this.rejectedCount = 0,
    this.pendingCoins = 0,
    this.completedCoins = 0,
    this.rejectedCoins = 0,
    this.pendingUsd = 0,
    this.completedUsd = 0,
    this.completedNetUsd = 0,
  });

  factory AgencyWithdrawalSummary.fromJson(Map<String, dynamic> json) {
    return AgencyWithdrawalSummary(
      pendingCount: _asInt(json['pending_count']),
      completedCount: _asInt(json['completed_count']),
      rejectedCount: _asInt(json['rejected_count']),
      pendingCoins: _asInt(json['pending_coins']),
      completedCoins: _asInt(json['completed_coins']),
      rejectedCoins: _asInt(json['rejected_coins']),
      pendingUsd: _asDouble(json['pending_usd']),
      completedUsd: _asDouble(json['completed_usd']),
      completedNetUsd: _asDouble(json['completed_net_usd']),
    );
  }

  final int pendingCount;
  final int completedCount;
  final int rejectedCount;
  final int pendingCoins;
  final int completedCoins;
  final int rejectedCoins;
  final double pendingUsd;
  final double completedUsd;
  final double completedNetUsd;

  bool get hasAny =>
      pendingCount + completedCount + rejectedCount + pendingCoins + completedCoins >
      0;
}

class AgencyWithdrawalItem {
  AgencyWithdrawalItem({
    this.id = 0,
    this.requestNumber = '',
    this.userId = 0,
    this.userName = '',
    this.isAgency = false,
    this.coins = 0,
    this.amount = 0,
    this.status = 0,
    this.gateway = '',
    this.createdAt = '',
  });

  factory AgencyWithdrawalItem.fromJson(Map<String, dynamic> json) {
    return AgencyWithdrawalItem(
      id: _asInt(json['id']),
      requestNumber: (json['request_number'] ?? '').toString(),
      userId: _asInt(json['user_id']),
      userName: (json['user_name'] ?? '').toString(),
      isAgency: json['is_agency'] == true || json['is_agency'] == 1,
      coins: _asInt(json['coins']),
      amount: _asDouble(json['amount']),
      status: _asInt(json['status']),
      gateway: (json['gateway'] ?? '').toString(),
      createdAt: (json['created_at'] ?? '').toString(),
    );
  }

  final int id;
  final String requestNumber;
  final int userId;
  final String userName;
  final bool isAgency;
  final int coins;
  final double amount;
  final int status;
  final String gateway;
  final String createdAt;
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
              streamerEarnedLifetime: _asInt(json['coin_collected_lifetime']),
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
    this.withdrawnPendingCoins = 0,
    this.withdrawnCompletedCoins = 0,
    this.withdrawnRejectedCoins = 0,
    this.withdrawnPendingCount = 0,
    this.withdrawnCompletedCount = 0,
    this.withdrawnRejectedCount = 0,
    this.withdrawnPendingUsd = 0,
    this.withdrawnCompletedUsd = 0,
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
      withdrawnPendingCoins: _asInt(json['withdrawn_pending_coins']),
      withdrawnCompletedCoins: _asInt(json['withdrawn_completed_coins']),
      withdrawnRejectedCoins: _asInt(json['withdrawn_rejected_coins']),
      withdrawnPendingCount: _asInt(json['withdrawn_pending_count']),
      withdrawnCompletedCount: _asInt(json['withdrawn_completed_count']),
      withdrawnRejectedCount: _asInt(json['withdrawn_rejected_count']),
      withdrawnPendingUsd: _asDouble(json['withdrawn_pending_usd']),
      withdrawnCompletedUsd: _asDouble(json['withdrawn_completed_usd']),
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
  final int withdrawnPendingCoins;
  final int withdrawnCompletedCoins;
  final int withdrawnRejectedCoins;
  final int withdrawnPendingCount;
  final int withdrawnCompletedCount;
  final int withdrawnRejectedCount;
  final double withdrawnPendingUsd;
  final double withdrawnCompletedUsd;
  final int live;
  final int chat;
  final int call;
  final int gift;
}

List<AgencyWorker> _parseWorkers(dynamic raw) {
  Iterable<dynamic> items = const [];
  if (raw is List) {
    items = raw;
  } else if (raw is Map) {
    items = raw.values;
  }
  return items
      .whereType<Map>()
      .map((e) => AgencyWorker.fromJson(Map<String, dynamic>.from(e)))
      .toList();
}

List<AgencyWithdrawalItem> _parseRecent(dynamic raw) {
  if (raw is! List) return <AgencyWithdrawalItem>[];
  return raw
      .whereType<Map>()
      .map((e) =>
          AgencyWithdrawalItem.fromJson(Map<String, dynamic>.from(e)))
      .toList();
}

String _normalizeAgencyCode(dynamic value) {
  final code = (value ?? '').toString().trim();
  if (code.isEmpty || code == '—') return '';
  if (code.contains('-')) return code.toLowerCase();
  return code.toUpperCase();
}

int _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse('$value') ?? 0;
}

double _asDouble(dynamic value) {
  if (value is double) return value;
  if (value is num) return value.toDouble();
  return double.tryParse('$value') ?? 0;
}
