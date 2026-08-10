import 'package:get/get.dart';
import 'package:krimson/common/controller/base_controller.dart';
import 'package:krimson/common/controller/profile_controller.dart';
import 'package:krimson/common/manager/session_manager.dart';
import 'package:krimson/common/service/api/task_service.dart';
import 'package:krimson/languages/languages_keys.dart';
import 'package:krimson/model/task/task_models.dart';
import 'package:krimson/screen/profile_screen/profile_screen_controller.dart';

class TasksScreenController extends BaseController {
  final selectedTab = 0.obs;
  final withdrawalPoints = 0.obs;
  final categories = <TaskCategoryGroup>[].obs;
  final eligibility = Rxn<Map<String, dynamic>>();
  final periodKey = ''.obs;
  final pageLoading = true.obs;
  final buckets = TaskBuckets(
    livePoints: 0,
    liveMax: 120,
    otherPoints: 0,
    otherMax: 30,
    targetTotal: 150,
  ).obs;
  final weeklyCallGrade = ''.obs;

  /// Prefer API order; fallback labels for known codes.
  List<String> get visibleTabCodes {
    final codes = categories.map((c) => c.code).toList();
    if (codes.isNotEmpty) return codes;
    return const ['live', 'other', 'private_bc'];
  }

  @override
  void onInit() {
    super.onInit();
    loadTasks();
  }

  void _syncWithdrawalPoints(int points) {
    withdrawalPoints.value = points;

    final sessionUser = SessionManager.instance.getUser();
    if (sessionUser != null) {
      SessionManager.instance
          .setUser(sessionUser.copyWith(withdrawalPoints: points));
    }

    final meId = SessionManager.instance.getUserID();
    if (Get.isRegistered<ProfileScreenController>(
        tag: ProfileScreenController.tag)) {
      final profile =
          Get.find<ProfileScreenController>(tag: ProfileScreenController.tag);
      final current = profile.userData.value;
      if (current != null && current.id == meId) {
        profile.userData.value = current.copyWith(withdrawalPoints: points);
        profile.profileController.updateUser(profile.userData.value);
      }
    }

    if (Get.isRegistered<ProfileController>(tag: '$meId')) {
      final pc = Get.find<ProfileController>(tag: '$meId');
      if (pc.user != null) {
        pc.updateUser(pc.user!.copyWith(withdrawalPoints: points));
      }
    }
  }

  Future<void> loadTasks() async {
    pageLoading.value = true;
    try {
      try {
        await TaskService.instance.reportProgress(actionType: 'open_app');
      } catch (_) {}

      final res = await TaskService.instance.list();
      if (res.status == true && res.data != null) {
        categories.assignAll(res.data!.categories);
        buckets.value = res.data!.buckets;
        weeklyCallGrade.value = res.data!.weeklyCallGrade ?? '';
        _syncWithdrawalPoints(res.data!.withdrawalPoints);
        eligibility.value = res.data!.eligibilityPreview;
        periodKey.value = res.data!.periodKey;
        if (selectedTab.value >= visibleTabCodes.length) {
          selectedTab.value = 0;
        }
      } else {
        showSnackBar(res.message ?? LKey.somethingWentWrong.tr);
      }
    } catch (e) {
      showSnackBar(e.toString());
    } finally {
      pageLoading.value = false;
    }
  }

  TaskCategoryGroup? get currentCategory {
    if (categories.isEmpty) return null;
    final codes = visibleTabCodes;
    final code = codes[selectedTab.value.clamp(0, codes.length - 1)];
    try {
      return categories.firstWhere((c) => c.code == code);
    } catch (_) {
      return categories.first;
    }
  }

  String tabLabel(String code) {
    switch (code) {
      case 'live':
        return 'LIVE';
      case 'other':
        return 'Otras';
      case 'private_bc':
        return 'B/C';
      case 'daily':
        return LKey.dailyTasks.tr;
      case 'special':
        return LKey.specialTasks.tr;
      case 'bonus':
        return LKey.bonusTasks.tr;
      default:
        return code;
    }
  }

  void onTabChanged(int index) {
    selectedTab.value = index;
  }

  Future<void> claimTask(TaskItem task) async {
    if (task.status != 'completed') return;
    showLoader();
    try {
      final res = await TaskService.instance.claim(taskId: task.id);
      stopLoader();
      if (res['status'] == true) {
        showSnackBar(res['message']?.toString() ?? LKey.taskRewardClaimed.tr);
        await loadTasks();
      } else {
        showSnackBar(res['message']?.toString() ?? LKey.somethingWentWrong.tr);
      }
    } catch (e) {
      stopLoader();
      showSnackBar(e.toString());
    }
  }
}
