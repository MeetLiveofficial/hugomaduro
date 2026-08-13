import 'package:get/get.dart';
import 'package:krimson/common/controller/base_controller.dart';
import 'package:krimson/common/manager/session_manager.dart';
import 'package:krimson/common/service/api/call_service.dart';
import 'package:krimson/common/service/api/user_service.dart';
import 'package:krimson/model/work/streamer_work_stats_model.dart';

class WorkScreenController extends BaseController {
  final pageLoading = true.obs;
  final stats = Rxn<StreamerWorkStats>();
  final showDetail = false.obs;
  final matchEnabled = true.obs;
  final matchToggleBusy = false.obs;

  @override
  void onInit() {
    super.onInit();
    matchEnabled.value =
        (SessionManager.instance.getUser()?.matchEnabled ?? 1) == 1;
    loadStats();
  }

  Future<void> loadStats() async {
    try {
      if (stats.value == null) pageLoading.value = true;
      stats.value = await CallService.instance.workStats();
    } catch (e) {
      showSnackBar(e.toString());
    } finally {
      pageLoading.value = false;
    }
  }

  void toggleDetail() => showDetail.toggle();

  Future<void> setMatchEnabled(bool value) async {
    if (matchToggleBusy.value) return;
    matchToggleBusy.value = true;
    final prev = matchEnabled.value;
    matchEnabled.value = value;
    try {
      await UserService.instance.updateUserDetails(matchEnabled: value);
      matchEnabled.value =
          (SessionManager.instance.getUser()?.matchEnabled ?? (value ? 1 : 0)) ==
              1;
    } catch (e) {
      matchEnabled.value = prev;
      showSnackBar(e.toString());
    } finally {
      matchToggleBusy.value = false;
    }
  }

  Future<void> updateCallPrice(int price) async {
    showLoader();
    try {
      await CallService.instance.updateCallPrice(callPrice: price);
      await loadStats();
      showSnackBar('Call price updated');
    } catch (e) {
      showSnackBar(e.toString());
    } finally {
      stopLoader();
    }
  }
}
