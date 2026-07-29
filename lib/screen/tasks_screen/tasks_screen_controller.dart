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

  static const tabCodes = ['daily', 'special', 'bonus'];

  @override
  void onInit() {
    super.onInit();
    loadTasks();
  }

  /// Mantiene perfil / sesión alineados con el saldo real tras auto-claim.
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
        profile.userData.value =
            current.copyWith(withdrawalPoints: points);
        profile.profileController
            .updateUser(profile.userData.value);
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
        _syncWithdrawalPoints(res.data!.withdrawalPoints);
        eligibility.value = res.data!.eligibilityPreview;
        periodKey.value = res.data!.periodKey;
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
    final code = tabCodes[selectedTab.value.clamp(0, tabCodes.length - 1)];
    try {
      return categories.firstWhere((c) => c.code == code);
    } catch (_) {
      return categories.first;
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
