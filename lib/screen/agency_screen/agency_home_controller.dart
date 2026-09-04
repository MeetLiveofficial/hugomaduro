import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:krimson/common/controller/base_controller.dart';
import 'package:krimson/common/manager/streamer_invite.dart';
import 'package:krimson/common/service/api/agency_service.dart';
import 'package:krimson/languages/dynamic_translations.dart';
import 'package:krimson/languages/languages_keys.dart';
import 'package:krimson/model/agency/agency_dashboard_model.dart';

class AgencyHomeController extends BaseController {
  final dashboard = AgencyDashboard().obs;
  final creating = false.obs;

  List<AgencyWorker> get workers => dashboard.value.workers;

  @override
  void onReady() {
    super.onReady();
    try {
      Get.find<DynamicTranslations>().ensureAgencyFallbacks();
    } catch (_) {}
    loadWorkers();
  }

  Future<void> loadWorkers() async {
    isLoading.value = true;
    try {
      dashboard.value = await AgencyService.instance.fetchDashboard();
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
      await AgencyService.instance.createWorker(
        fullname: fullname.trim(),
        identity: identity.trim(),
        password: password,
        username: username,
      );
      await loadWorkers();
      showSnackBar(
          'Streamer creado. Ya puede entrar con su email y contraseña.');
      return true;
    } catch (e) {
      showSnackBar(e.toString().replaceFirst('Exception: ', ''));
      return false;
    } finally {
      creating.value = false;
    }
  }

  Future<void> copyAgencyCode() async {
    final code = dashboard.value.agencyCode.trim();
    if (code.isEmpty) {
      showSnackBar(LKey.agencyNoInviteCode.tr);
      return;
    }
    await Clipboard.setData(ClipboardData(text: code));
    showSnackBar(LKey.agencyCodeCopied.tr);
  }

  Future<void> copyInviteLink() async {
    final code = dashboard.value.agencyCode.trim();
    if (code.isEmpty) {
      showSnackBar(LKey.agencyNoInviteCode.tr);
      return;
    }
    await Clipboard.setData(ClipboardData(text: StreamerInvite.inviteUrl(code)));
    showSnackBar(LKey.inviteLinkCopied.tr);
  }
}
