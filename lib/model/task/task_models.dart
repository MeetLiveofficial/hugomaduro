class TaskListModel {
  bool? status;
  String? message;
  TaskListData? data;

  TaskListModel({this.status, this.message, this.data});

  factory TaskListModel.fromJson(Map<String, dynamic> json) => TaskListModel(
        status: json['status'] == true,
        message: json['message']?.toString(),
        data: json['data'] is Map
            ? TaskListData.fromJson(Map<String, dynamic>.from(json['data']))
            : null,
      );
}

class TaskBuckets {
  final int livePoints;
  final int liveMax;
  final int otherPoints;
  final int otherMax;
  final int targetTotal;

  TaskBuckets({
    required this.livePoints,
    required this.liveMax,
    required this.otherPoints,
    required this.otherMax,
    required this.targetTotal,
  });

  factory TaskBuckets.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return TaskBuckets(
        livePoints: 0,
        liveMax: 120,
        otherPoints: 0,
        otherMax: 30,
        targetTotal: 150,
      );
    }
    final live = json['live'] is Map
        ? Map<String, dynamic>.from(json['live'])
        : <String, dynamic>{};
    final other = json['other'] is Map
        ? Map<String, dynamic>.from(json['other'])
        : <String, dynamic>{};
    return TaskBuckets(
      livePoints: _asInt(live['points']),
      liveMax: _asInt(live['max'], fallback: 120),
      otherPoints: _asInt(other['points']),
      otherMax: _asInt(other['max'], fallback: 30),
      targetTotal: _asInt(json['target_total'], fallback: 150),
    );
  }

  int get combinedPoints => livePoints + otherPoints;
}

class TaskListData {
  bool enabled;
  String timezone;
  String periodKey;
  DateTime? periodEndsAt;
  int withdrawalPoints;
  List<TaskCategoryGroup> categories;
  Map<String, dynamic>? eligibilityPreview;
  TaskBuckets buckets;
  String? weeklyCallGrade;

  TaskListData({
    required this.enabled,
    required this.timezone,
    required this.periodKey,
    this.periodEndsAt,
    required this.withdrawalPoints,
    required this.categories,
    this.eligibilityPreview,
    required this.buckets,
    this.weeklyCallGrade,
  });

  factory TaskListData.fromJson(Map<String, dynamic> json) => TaskListData(
        enabled: json['enabled'] != false,
        timezone: json['timezone']?.toString() ?? '',
        periodKey: json['period_key']?.toString() ?? '',
        periodEndsAt: _asDateTime(json['period_ends_at']),
        withdrawalPoints: _asInt(json['withdrawal_points']),
        categories: (json['categories'] as List? ?? [])
            .whereType<Map>()
            .map((e) => TaskCategoryGroup.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
        eligibilityPreview: json['eligibility_preview'] is Map
            ? Map<String, dynamic>.from(json['eligibility_preview'])
            : null,
        buckets: TaskBuckets.fromJson(
          json['buckets'] is Map
              ? Map<String, dynamic>.from(json['buckets'])
              : null,
        ),
        weeklyCallGrade: json['weekly_call_grade']?.toString(),
      );
}

class TaskCategoryGroup {
  String code;
  String nameKey;
  int completedCount;
  int totalCount;
  List<TaskItem> tasks;

  TaskCategoryGroup({
    required this.code,
    required this.nameKey,
    required this.completedCount,
    required this.totalCount,
    required this.tasks,
  });

  factory TaskCategoryGroup.fromJson(Map<String, dynamic> json) =>
      TaskCategoryGroup(
        code: json['code']?.toString() ?? '',
        nameKey: json['name_key']?.toString() ?? '',
        completedCount: _asInt(json['completed_count']),
        totalCount: _asInt(json['total_count']),
        tasks: (json['tasks'] as List? ?? [])
            .whereType<Map>()
            .map((e) => TaskItem.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
      );
}

class TaskRequires {
  final int minutes;
  final int coins;

  TaskRequires({required this.minutes, required this.coins});

  factory TaskRequires.fromJson(dynamic json) {
    if (json is! Map) return TaskRequires(minutes: 0, coins: 0);
    final m = Map<String, dynamic>.from(json);
    return TaskRequires(
      minutes: _asInt(m['minutes']),
      coins: _asInt(m['coins']),
    );
  }
}

class TaskItem {
  int id;
  String titleKey;
  String descriptionKey;
  String actionType;
  int targetValue;
  int progressValue;
  int progressMinutes;
  int progressCoins;
  TaskRequires? requires;
  String? bucket;
  String? code;
  bool isMaxTask;
  String status;
  int withdrawalPointsReward;
  int xpReward;
  int sortOrder;

  TaskItem({
    required this.id,
    required this.titleKey,
    required this.descriptionKey,
    required this.actionType,
    required this.targetValue,
    required this.progressValue,
    required this.progressMinutes,
    required this.progressCoins,
    this.requires,
    this.bucket,
    this.code,
    required this.isMaxTask,
    required this.status,
    required this.withdrawalPointsReward,
    required this.xpReward,
    required this.sortOrder,
  });

  factory TaskItem.fromJson(Map<String, dynamic> json) => TaskItem(
        id: _asInt(json['id']),
        titleKey: json['title_key']?.toString() ?? '',
        descriptionKey: json['description_key']?.toString() ?? '',
        actionType: json['action_type']?.toString() ?? '',
        targetValue: _asInt(json['target_value']),
        progressValue: _asInt(json['progress_value']),
        progressMinutes: _asInt(json['progress_minutes']),
        progressCoins: _asInt(json['progress_coins']),
        requires: json['requires'] != null
            ? TaskRequires.fromJson(json['requires'])
            : null,
        bucket: json['bucket']?.toString(),
        code: json['code']?.toString(),
        isMaxTask: json['is_max_task'] == true,
        status: json['status']?.toString() ?? 'pending',
        withdrawalPointsReward: _asInt(json['withdrawal_points_reward']),
        xpReward: _asInt(json['xp_reward']),
        sortOrder: _asInt(json['sort_order']),
      );

  bool get isDual =>
      requires != null && (requires!.minutes > 0 || requires!.coins > 0);

  double get progressRatio {
    if (isDual) {
      final rm = requires!.minutes <= 0
          ? 1.0
          : (progressMinutes / requires!.minutes).clamp(0.0, 1.0);
      final rc = requires!.coins <= 0
          ? 1.0
          : (progressCoins / requires!.coins).clamp(0.0, 1.0);
      return ((rm + rc) / 2).clamp(0.0, 1.0);
    }
    return targetValue <= 0
        ? 0
        : (progressValue / targetValue).clamp(0.0, 1.0);
  }

  bool get isDone => status == 'completed' || status == 'claimed';
}

int _asInt(dynamic v, {int fallback = 0}) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse('$v') ?? fallback;
}

DateTime? _asDateTime(dynamic v) {
  if (v == null) return null;
  return DateTime.tryParse(v.toString())?.toUtc();
}
