import 'package:get/get.dart';
import 'package:krimson/common/controller/base_controller.dart';
import 'package:krimson/common/service/api/agency_service.dart';
import 'package:krimson/model/user_model/user_model.dart';

class AgencyHomeController extends BaseController {
  final workers = <User>[].obs;
  final creating = false.obs;

  @override
  void onReady() {
    super.onReady();
    loadWorkers();
  }

  Future<void> loadWorkers() async {
    isLoading.value = true;
    try {
      workers.assignAll(await AgencyService.instance.listWorkers());
    } catch (e) {
      showSnackBar(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> createWorker({
    required String fullname,
    required String identity,
    required String password,
    String username = '',
  }) async {
    if (creating.value) return false;
    creating.value = true;
    try {
      final created = await AgencyService.instance.createWorker(
        fullname: fullname.trim(),
        identity: identity.trim(),
        password: password,
        username: username,
      );
      workers.insert(0, created);
      showSnackBar('Streamer creado. Ya puede entrar con su email y contraseña.');
      return true;
    } catch (e) {
      showSnackBar(e.toString().replaceFirst('Exception: ', ''));
      return false;
    } finally {
      creating.value = false;
    }
  }
}
