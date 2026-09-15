import 'package:get/get.dart';
import 'package:krimson/common/controller/base_controller.dart';
import 'package:flutter/services.dart';
import 'package:krimson/common/service/api/user_service.dart';
import 'package:krimson/languages/languages_keys.dart';
import 'package:krimson/model/referral/streamer_referral.dart';
import 'package:share_plus/share_plus.dart';

class StreamerReferralController extends BaseController {
  final data = const StreamerReferral().obs;

  @override
  void onReady() {
    super.onReady();
    load();
  }

  Future<void> load() async {
    isLoading.value = true;
    try {
      data.value = await UserService.instance.fetchMyReferral();
    } catch (e) {
      showSnackBar(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> copyCode() async {
    final code = data.value.code.trim();
    if (code.isEmpty) {
      showSnackBar(LKey.referralCodeNotReady.tr);
      return;
    }
    await Clipboard.setData(ClipboardData(text: code));
    showSnackBar(LKey.referralCodeCopied.tr);
  }

  Future<void> copyLink() async {
    final link = data.value.link.trim();
    if (link.isEmpty) {
      showSnackBar(LKey.referralCodeNotReady.tr);
      return;
    }
    await Clipboard.setData(ClipboardData(text: link));
    showSnackBar(LKey.inviteLinkCopied.tr);
  }

  Future<void> shareLink() async {
    final link = data.value.link.trim();
    final code = data.value.code.trim();
    if (link.isEmpty && code.isEmpty) {
      showSnackBar(LKey.referralCodeNotReady.tr);
      return;
    }
    final text = link.isNotEmpty
        ? '${LKey.referralShareText.trParams({'code': code})} $link'
        : code;
    await SharePlus.instance.share(ShareParams(text: text));
  }
}
