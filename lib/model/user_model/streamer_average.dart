class StreamerAverage {
  StreamerAverage({
    required this.avg,
    this.grade = 'NEW',
    this.coins = 0,
    this.calls = 0,
    this.live = 0,
    this.interaction = 0,
    this.quality = 0,
    this.nextGrade,
    this.need = 0,
    this.windowDays = 30,
    this.pendingGrade,
    this.holdDays = 0,
  });

  factory StreamerAverage.fromJson(dynamic json) {
    if (json is! Map) {
      return StreamerAverage(avg: 0);
    }
    final map = Map<String, dynamic>.from(json);
    final comps = map['components'] is Map
        ? Map<String, dynamic>.from(map['components'])
        : <String, dynamic>{};
    return StreamerAverage(
      avg: _asDouble(map['avg']) ?? 0,
      grade: (map['grade']?.toString() ?? 'NEW').toUpperCase(),
      coins: _asInt(comps['coins']) ?? 0,
      calls: _asInt(comps['calls']) ?? 0,
      live: _asInt(comps['live']) ?? 0,
      interaction: _asInt(comps['interaction']) ?? 0,
      quality: _asInt(comps['quality']) ?? 0,
      nextGrade: map['next_grade']?.toString(),
      need: _asInt(map['need']) ?? 0,
      windowDays: _asInt(map['window_days']) ?? 30,
      pendingGrade: map['pending_grade']?.toString(),
      holdDays: _asInt(map['hold_days']) ?? 0,
    );
  }

  final double avg;
  final String grade;
  final int coins;
  final int calls;
  final int live;
  final int interaction;
  final int quality;
  final String? nextGrade;
  final int need;
  final int windowDays;
  final String? pendingGrade;
  final int holdDays;

  Map<String, dynamic> toJson() => {
        'avg': avg,
        'grade': grade,
        'components': {
          'coins': coins,
          'calls': calls,
          'live': live,
          'interaction': interaction,
          'quality': quality,
        },
        'next_grade': nextGrade,
        'need': need,
        'window_days': windowDays,
        'pending_grade': pendingGrade,
        'hold_days': holdDays,
      };

  static int? _asInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse('$v');
  }

  static double? _asDouble(dynamic v) {
    if (v == null) return null;
    if (v is double) return v;
    if (v is num) return v.toDouble();
    return double.tryParse('$v');
  }
}
