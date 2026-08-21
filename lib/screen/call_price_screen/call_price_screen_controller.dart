import 'package:get/get.dart';
import 'package:krimson/common/controller/base_controller.dart';
import 'package:krimson/common/manager/session_manager.dart';
import 'package:krimson/common/service/api/call_service.dart';
import 'package:krimson/model/work/streamer_work_stats_model.dart';

class CallPriceScreenController extends BaseController {
  final pageLoading = true.obs;
  final stats = Rxn<StreamerWorkStats>();

  WorkCallPricing? get pricing => stats.value?.callPricing;

  bool get canEdit => pricing?.canEdit == true;

  int get price => pricing?.effectivePrice ?? 0;

  String get grade {
    final raw = (pricing?.grade ?? stats.value?.weeklyLevel.grade ?? 'NEW')
        .toUpperCase()
        .trim();
    if (raw == 'SS') return 'S';
    if (raw == 'D') return 'NEW';
    return raw.isEmpty ? 'NEW' : raw;
  }

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    try {
      if (stats.value == null) pageLoading.value = true;
      stats.value = await CallService.instance.workStats();
    } catch (e) {
      showSnackBar(e.toString());
    } finally {
      pageLoading.value = false;
    }
  }

  Future<bool> savePrice(int price) async {
    final p = pricing;
    if (p == null || !p.canEdit) {
      showSnackBar('Solo los rangos A y S pueden editar el precio');
      return false;
    }
    if (price < p.min || price > p.max) {
      showSnackBar('El precio debe estar entre ${p.min} y ${p.max}');
      return false;
    }
    showLoader();
    try {
      final data =
          await CallService.instance.updateCallPrice(callPrice: price);
      await load();
      final me = SessionManager.instance.getUser();
      if (me != null) {
        me.callRequestCoins =
            (data['call_request_coins'] as num?)?.toInt() ?? price;
        SessionManager.instance.setUser(me);
      }
      showSnackBar('Precio de llamada actualizado');
      return true;
    } catch (e) {
      showSnackBar(e.toString());
      return false;
    } finally {
      stopLoader();
    }
  }
}
