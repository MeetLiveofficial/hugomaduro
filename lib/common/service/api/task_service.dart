import 'package:krimson/common/service/api/api_service.dart';
import 'package:krimson/common/service/utils/web_service.dart';
import 'package:krimson/model/task/task_models.dart';

class TaskService {
  TaskService._();

  static final TaskService instance = TaskService._();

  Future<TaskListModel> list({String? category}) async {
    return ApiService.instance.call(
      url: WebService.task.list,
      fromJson: TaskListModel.fromJson,
      param: {
        if (category != null && category.isNotEmpty) 'category': category,
      },
    );
  }

  Future<Map<String, dynamic>> claim({required int taskId}) async {
    return ApiService.instance.call(
      url: WebService.task.claim,
      fromJson: (j) => Map<String, dynamic>.from(j),
      param: {'task_id': taskId},
    );
  }

  Future<Map<String, dynamic>> reportProgress({
    required String actionType,
    int amount = 1,
  }) async {
    return ApiService.instance.call(
      url: WebService.task.reportProgress,
      fromJson: (j) => Map<String, dynamic>.from(j),
      param: {
        'action_type': actionType,
        'amount': amount,
      },
    );
  }

  Future<Map<String, dynamic>> withdrawalEligibility({int? coins}) async {
    return ApiService.instance.call(
      url: WebService.task.withdrawalEligibility,
      fromJson: (j) => Map<String, dynamic>.from(j),
      param: {
        if (coins != null) 'coins': coins,
      },
    );
  }
}
