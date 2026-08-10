import 'package:get/get.dart';
import 'package:krimson/common/controller/base_controller.dart';
import 'package:krimson/common/service/api/call_service.dart';
import 'package:krimson/model/work/streamer_work_stats_model.dart';

class WorkScreenController extends BaseController {
  final pageLoading = true.obs;
  final stats = Rxn<StreamerWorkStats>();
  final showDetail = false.obs;

  @override
  void onInit() {
    super.onInit();
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
