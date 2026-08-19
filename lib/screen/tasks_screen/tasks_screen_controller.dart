import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:krimson/common/controller/base_controller.dart';
import 'package:krimson/common/controller/profile_controller.dart';
import 'package:krimson/common/manager/session_manager.dart';
import 'package:krimson/common/service/api/task_service.dart';
import 'package:krimson/languages/dynamic_translations.dart';
import 'package:krimson/languages/languages_keys.dart';
import 'package:krimson/model/task/task_models.dart';
import 'package:krimson/screen/camera_screen/camera_screen.dart';
import 'package:krimson/screen/create_feed_screen/create_feed_screen.dart';
import 'package:krimson/screen/dashboard_screen/dashboard_screen_controller.dart';
import 'package:krimson/screen/match_screen/match_screen.dart';
import 'package:krimson/screen/profile_screen/profile_screen_controller.dart';

enum TaskGoTarget { live, match, chat, profile, explore, homeLive, feed }

class TasksScreenController extends BaseController {
  bool isDashBoard = false;

  final selectedTab = 0.obs;
  final withdrawalPoints = 0.obs;
  final categories = <TaskCategoryGroup>[].obs;
  final eligibility = Rxn<Map<String, dynamic>>();
  final periodKey = ''.obs;
  final timezone = ''.obs;
  final pageLoading = true.obs;
  final remainingLabel = '--:--:--'.obs;
  final buckets = TaskBuckets(
    livePoints: 0,
    liveMax: 120,
    otherPoints: 0,
    otherMax: 30,
    targetTotal: 150,
  ).obs;
  final weeklyCallGrade = ''.obs;

  DateTime? _periodEndsAt;
  Timer? _countdownTimer;

  /// Prefer API order; fallback labels for known codes.
  List<String> get visibleTabCodes {
    final codes = categories.map((c) => c.code).toList();
    if (codes.isNotEmpty) return codes;
    return const ['live', 'other', 'private_bc'];
  }

  @override
  void onInit() {
    super.onInit();
    if (Get.isRegistered<DynamicTranslations>()) {
      Get.find<DynamicTranslations>().ensureTaskFallbacks();
    }
    loadTasks();
  }

  @override
  void onClose() {
    _countdownTimer?.cancel();
    super.onClose();
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
        timezone.value = res.data!.timezone;
        _periodEndsAt = res.data!.periodEndsAt ??
            _fallbackPeriodEnd(res.data!.periodKey, res.data!.timezone);
        _startCountdown();
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

  DateTime? _fallbackPeriodEnd(String periodKey, String tz) {
    final parts = periodKey.split('-');
    if (parts.length != 3) return null;
    final y = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    final d = int.tryParse(parts[2]);
    if (y == null || m == null || d == null) return null;
    // America/Caracas (UTC-4, sin DST): medianoche siguiente = 04:00 UTC.
    final utcHour = (tz.isEmpty || tz == 'America/Caracas') ? 4 : 0;
    return DateTime.utc(y, m, d + 1, utcHour);
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    _tickCountdown();
    _countdownTimer =
        Timer.periodic(const Duration(seconds: 1), (_) => _tickCountdown());
  }

  void _tickCountdown() {
    final end = _periodEndsAt;
    if (end == null) {
      remainingLabel.value = '--:--:--';
      return;
    }
    var diff = end.difference(DateTime.now().toUtc());
    if (diff.isNegative) diff = Duration.zero;
    remainingLabel.value = _formatHms(diff);
  }

  String _formatHms(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
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

  /// Primera tarea de la categoría actual (p. ej. LIVE Task 1).
  TaskItem? get firstTaskInCategory {
    final tasks = currentCategory?.tasks ?? [];
    if (tasks.isEmpty) return null;
    return tasks.first;
  }

  bool get firstTaskIsDone => firstTaskInCategory?.isDone ?? false;

  bool isFirstTask(TaskItem task) => firstTaskInCategory?.id == task.id;

  /// Tras culminar la tarea 1, el resto puede ir a su categoría.
  bool canGoToCategory(TaskItem task) {
    if (isFirstTask(task)) return true;
    return firstTaskIsDone;
  }

  TaskGoTarget targetFor(TaskItem task) {
    switch (task.actionType) {
      case 'go_live_minutes':
      case 'go_live_coins':
      case 'go_live_dual':
      case 'receive_gifts':
      case 'receive_gift_coins':
      case 'online_minutes':
        return TaskGoTarget.live;
      case 'watch_lives_minutes':
        return TaskGoTarget.homeLive;
      case 'private_call_ge_5':
      case 'private_call_ge_20':
      case 'match_completed':
      case 'call_gifts_distinct':
        return TaskGoTarget.match;
      case 'user_interactions':
      case 'reply_messages':
        return TaskGoTarget.chat;
      case 'complete_profile':
        return TaskGoTarget.profile;
      case 'publish_post':
      case 'publish_story':
      case 'daily_activity':
        return TaskGoTarget.feed;
      case 'give_likes':
      case 'follow_users':
      case 'receive_likes':
      case 'receive_followers':
        return TaskGoTarget.explore;
      default:
        return TaskGoTarget.live;
    }
  }

  String goLabel(TaskItem task) {
    switch (targetFor(task)) {
      case TaskGoTarget.live:
        return LKey.goToLiveCategory.tr;
      case TaskGoTarget.match:
        return LKey.goToMatchCategory.tr;
      case TaskGoTarget.chat:
        return LKey.goToChatCategory.tr;
      case TaskGoTarget.profile:
        return LKey.goToProfileCategory.tr;
      case TaskGoTarget.explore:
        return LKey.goToExploreCategory.tr;
      case TaskGoTarget.homeLive:
        return LKey.goToLiveCategory.tr;
      case TaskGoTarget.feed:
        return LKey.goToFeedCategory.tr;
    }
  }

  void goToTaskCategory(TaskItem task) {
    if (!canGoToCategory(task)) return;
    final target = targetFor(task);
    final shouldPop = !isDashBoard;

    void navigate() {
      switch (target) {
        case TaskGoTarget.live:
          _openDashTab(DashboardScreenController.tabLive);
          break;
        case TaskGoTarget.homeLive:
          if (Get.isRegistered<DashboardScreenController>()) {
            final dash = Get.find<DashboardScreenController>();
            dash.setHomeTabMode(HomeTabMode.live);
            dash.onChanged(DashboardScreenController.tabHome);
          }
          break;
        case TaskGoTarget.match:
          Get.to(() => const MatchScreen());
          break;
        case TaskGoTarget.chat:
          _openDashTab(DashboardScreenController.tabChat);
          break;
        case TaskGoTarget.profile:
          _openDashTab(DashboardScreenController.tabProfile);
          break;
        case TaskGoTarget.explore:
          _openDashTab(DashboardScreenController.tabExplore);
          break;
        case TaskGoTarget.feed:
          if (kIsWeb) {
            Get.to(
                () => const CreateFeedScreen(createType: CreateFeedType.feed));
          } else {
            Get.to(() => const CameraScreen(cameraType: CameraScreenType.post));
          }
          break;
      }
    }

    if (shouldPop) {
      Get.back();
    }
    Future<void>.delayed(Duration.zero, navigate);
  }

  static void _openDashTab(int index) {
    if (Get.isRegistered<DashboardScreenController>()) {
      Get.find<DashboardScreenController>().onChanged(index);
    }
  }
}
