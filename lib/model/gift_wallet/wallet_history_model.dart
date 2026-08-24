class WalletHistoryResponse {
  WalletHistoryResponse({
    this.status,
    this.message,
    this.summary,
    this.items,
    this.hasMore,
  });

  factory WalletHistoryResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    Map<String, dynamic>? map;
    if (data is Map) {
      map = Map<String, dynamic>.from(data);
    }
    final itemsRaw = map?['items'];
    return WalletHistoryResponse(
      status: json['status'] == true,
      message: json['message']?.toString(),
      summary: map?['summary'] is Map
          ? WalletHistorySummary.fromJson(
              Map<String, dynamic>.from(map!['summary'] as Map))
          : null,
      items: itemsRaw is List
          ? itemsRaw
              .whereType<Map>()
              .map((e) => WalletHistoryItem.fromJson(
                  Map<String, dynamic>.from(e)))
              .toList()
          : <WalletHistoryItem>[],
      hasMore: map?['has_more'] == true,
    );
  }

  final bool? status;
  final String? message;
  final WalletHistorySummary? summary;
  final List<WalletHistoryItem>? items;
  final bool? hasMore;
}

class WalletHistorySummary {
  WalletHistorySummary({
    this.todayCoins = 0,
    this.totalCoins = 0,
    this.availableCoins = 0,
    this.withdrawCoins = 0,
    this.coinValue = 0,
    this.coinsPerDollar = 0,
    this.currency = '\$',
    this.periodIncome = 0,
    this.periodWithdraw = 0,
    this.startDate,
    this.endDate,
  });

  factory WalletHistorySummary.fromJson(Map<String, dynamic> json) {
    return WalletHistorySummary(
      todayCoins: _asInt(json['today_coins']),
      totalCoins: _asInt(json['total_coins']),
      availableCoins: _asInt(json['available_coins']),
      withdrawCoins: _asInt(json['withdraw_coins']),
      coinValue: _asDouble(json['coin_value']),
      coinsPerDollar: _asInt(json['coins_per_dollar']),
      currency: json['currency']?.toString() ?? '\$',
      periodIncome: _asInt(json['period_income']),
      periodWithdraw: _asInt(json['period_withdraw']),
      startDate: json['start_date']?.toString(),
      endDate: json['end_date']?.toString(),
    );
  }

  final int todayCoins;
  final int totalCoins;
  final int availableCoins;
  final int withdrawCoins;
  final double coinValue;
  final int coinsPerDollar;
  final String currency;
  final int periodIncome;
  final int periodWithdraw;
  final String? startDate;
  final String? endDate;

  static int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse('$value') ?? 0;
  }

  static double _asDouble(dynamic value) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse('$value') ?? 0;
  }
}

class WalletHistoryItem {
  WalletHistoryItem({
    this.id,
    this.type,
    this.source,
    this.coins = 0,
    this.direction = 'in',
    this.quantity = 1,
    this.durationSeconds,
    this.createdAt,
    this.user,
    this.gift,
    this.note,
  });

  factory WalletHistoryItem.fromJson(Map<String, dynamic> json) {
    return WalletHistoryItem(
      id: WalletHistorySummary._asInt(json['id']),
      type: json['type']?.toString() ?? '',
      source: json['source']?.toString() ?? '',
      coins: WalletHistorySummary._asInt(json['coins']),
      direction: json['direction']?.toString() ?? 'in',
      quantity: WalletHistorySummary._asInt(json['quantity']).clamp(1, 9999),
      durationSeconds: json['duration_seconds'] == null
          ? null
          : WalletHistorySummary._asInt(json['duration_seconds']),
      createdAt: json['created_at']?.toString(),
      user: json['user'] is Map
          ? WalletHistoryUser.fromJson(Map<String, dynamic>.from(json['user']))
          : null,
      gift: json['gift'] is Map
          ? WalletHistoryGift.fromJson(Map<String, dynamic>.from(json['gift']))
          : null,
      note: json['note']?.toString(),
    );
  }

  final int? id;
  final String? type;
  final String? source;
  final int coins;
  final String direction;
  final int quantity;
  final int? durationSeconds;
  final String? createdAt;
  final WalletHistoryUser? user;
  final WalletHistoryGift? gift;
  final String? note;

  bool get isIncome => direction != 'out';

  String get displayName {
    final full = (user?.fullname ?? '').trim();
    if (full.isNotEmpty) return full;
    final userName = (user?.username ?? '').trim();
    if (userName.isNotEmpty) return userName;
    return '';
  }
}

class WalletHistoryUser {
  WalletHistoryUser({
    this.id,
    this.username,
    this.fullname,
    this.profilePhoto,
  });

  factory WalletHistoryUser.fromJson(Map<String, dynamic> json) {
    return WalletHistoryUser(
      id: WalletHistorySummary._asInt(json['id']),
      username: json['username']?.toString(),
      fullname: json['fullname']?.toString(),
      profilePhoto: json['profile_photo']?.toString(),
    );
  }

  final int? id;
  final String? username;
  final String? fullname;
  final String? profilePhoto;
}

class WalletHistoryGift {
  WalletHistoryGift({this.id, this.image, this.coinPrice = 0});

  factory WalletHistoryGift.fromJson(Map<String, dynamic> json) {
    return WalletHistoryGift(
      id: WalletHistorySummary._asInt(json['id']),
      image: json['image']?.toString(),
      coinPrice: WalletHistorySummary._asInt(json['coin_price']),
    );
  }

  final int? id;
  final String? image;
  final int coinPrice;
}
