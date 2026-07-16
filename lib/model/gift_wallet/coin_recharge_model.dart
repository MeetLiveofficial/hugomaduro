class CoinRecharge {
  CoinRecharge({
    this.id,
    this.userId,
    this.coinPackageId,
    this.coins,
    this.amountUsd,
    this.source,
    this.note,
    this.createdAt,
  });

  final int? id;
  final int? userId;
  final int? coinPackageId;
  final int? coins;
  final double? amountUsd;
  final String? source;
  final String? note;
  final String? createdAt;

  factory CoinRecharge.fromJson(Map<String, dynamic> json) {
    double? asDouble(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toDouble();
      return double.tryParse('$v');
    }

    int? asInt(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toInt();
      return int.tryParse('$v');
    }

    return CoinRecharge(
      id: asInt(json['id']),
      userId: asInt(json['user_id']),
      coinPackageId: asInt(json['coin_package_id']),
      coins: asInt(json['coins']),
      amountUsd: asDouble(json['amount_usd']),
      source: json['source']?.toString(),
      note: json['note']?.toString(),
      createdAt: json['created_at']?.toString(),
    );
  }
}
