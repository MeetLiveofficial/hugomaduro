class StreamerReferral {
  const StreamerReferral({
    this.code = '',
    this.link = '',
    this.percent = 0,
    this.referredCount = 0,
    this.rewardedCount = 0,
    this.rewardCoins = 0,
  });

  final String code;
  final String link;
  final double percent;
  final int referredCount;
  final int rewardedCount;
  final int rewardCoins;

  factory StreamerReferral.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map
        ? Map<String, dynamic>.from(json['data'] as Map)
        : json;
    return StreamerReferral(
      code: (data['referral_code'] ?? '').toString(),
      link: (data['referral_link'] ?? '').toString(),
      percent: double.tryParse('${data['percent'] ?? 0}') ?? 0,
      referredCount: int.tryParse('${data['referred_count'] ?? 0}') ?? 0,
      rewardedCount: int.tryParse('${data['rewarded_count'] ?? 0}') ?? 0,
      rewardCoins: int.tryParse('${data['reward_coins'] ?? 0}') ?? 0,
    );
  }
}
