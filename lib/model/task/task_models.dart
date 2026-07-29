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

class TaskListData {
  bool enabled;
  String timezone;
  String periodKey;
  int withdrawalPoints;
  List<TaskCategoryGroup> categories;
  Map<String, dynamic>? eligibilityPreview;

  TaskListData({
    required this.enabled,
    required this.timezone,
    required this.periodKey,
    required this.withdrawalPoints,
    required this.categories,
    this.eligibilityPreview,
  });

  factory TaskListData.fromJson(Map<String, dynamic> json) => TaskListData(
        enabled: json['enabled'] != false,
        timezone: json['timezone']?.toString() ?? '',
        periodKey: json['period_key']?.toString() ?? '',
        withdrawalPoints: _asInt(json['withdrawal_points']),
        categories: (json['categories'] as List? ?? [])
            .whereType<Map>()
            .map((e) => TaskCategoryGroup.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
        eligibilityPreview: json['eligibility_preview'] is Map
            ? Map<String, dynamic>.from(json['eligibility_preview'])
            : null,
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

class TaskItem {
  int id;
  String titleKey;
  String descriptionKey;
  String actionType;
  int targetValue;
  int progressValue;
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
        status: json['status']?.toString() ?? 'pending',
        withdrawalPointsReward: _asInt(json['withdrawal_points_reward']),
        xpReward: _asInt(json['xp_reward']),
        sortOrder: _asInt(json['sort_order']),
      );

  double get progressRatio =>
      targetValue <= 0 ? 0 : (progressValue / targetValue).clamp(0.0, 1.0);

  bool get isDone => status == 'completed' || status == 'claimed';
}

int _asInt(dynamic v) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse('$v') ?? 0;
}
