import 'package:get/get.dart';
import 'package:krimson/common/controller/base_controller.dart';
import 'package:krimson/common/service/api/notification_service.dart';
import 'package:krimson/model/misc/activity_notification_model.dart';
import 'package:krimson/model/misc/admin_notification_model.dart';

class NotificationScreenController extends BaseController {
  final RxInt selectedTab = 0.obs;
  final RxList<ActivityNotification> activity = <ActivityNotification>[].obs;
  final RxList<AdminNotificationData> admin = <AdminNotificationData>[].obs;
  final RxBool isActivityLoading = false.obs;
  final RxBool isAdminLoading = false.obs;

  @override
  void onReady() {
    super.onReady();
    fetchActivity(reset: true);
    fetchAdmin(reset: true);
  }

  void onTabChanged(int index) {
    selectedTab.value = index;
  }

  Future<void> fetchActivity({bool reset = false}) async {
    if (isActivityLoading.value) return;
    isActivityLoading.value = true;
    try {
      final lastId = reset ? null : activity.lastOrNull?.id;
      final items = await NotificationService.instance
          .fetchActivityNotifications(lastItemId: lastId);
      if (reset) activity.clear();
      for (final n in items) {
        if (activity.every((e) => e.id != n.id)) {
          activity.add(n);
        }
      }
    } finally {
      isActivityLoading.value = false;
    }
  }

  Future<void> fetchAdmin({bool reset = false}) async {
    if (isAdminLoading.value) return;
    isAdminLoading.value = true;
    try {
      final lastId = reset ? null : admin.lastOrNull?.id;
      final items = await NotificationService.instance
          .fetchAdminNotifications(lastItemId: lastId);
      if (reset) admin.clear();
      for (final n in items) {
        if (admin.every((e) => e.id != n.id)) {
          admin.add(n);
        }
      }
    } finally {
      isAdminLoading.value = false;
    }
  }

  Future<void> refreshAll() async {
    await Future.wait([
      fetchActivity(reset: true),
      fetchAdmin(reset: true),
    ]);
  }
}
