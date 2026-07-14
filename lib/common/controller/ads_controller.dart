import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:krimson/common/controller/base_controller.dart';
import 'package:krimson/common/manager/ads_manager.dart';
import 'package:krimson/common/manager/session_manager.dart';
import 'package:krimson/common/service/subscription/subscription_manager.dart';
import 'package:krimson/utilities/app_platform.dart';

class AdsController extends BaseController {
  InterstitialAd? interstitialAd;

  @override
  void onInit() {
    super.onInit();
    if (!kIsWeb) {
      loadInterstitialAd(); // preload when controller initializes
    }
  }

  Future<void> showInterstitialAdIfAvailable({bool isPopScope = false}) async {
    if (kIsWeb) {
      if (!isPopScope) Get.back();
      return;
    }
    final setting = SessionManager.instance.getSettings();

    // Check ad status for platform
    final isAdDisabled =
        (AppPlatform.isAndroid && setting?.admobAndroidStatus == 0) ||
            (AppPlatform.isIOS && setting?.admobIosStatus == 0);

    // Early return if ads are disabled or user is subscribed or ad is not loaded
    if (isAdDisabled || isSubscribe.value || interstitialAd == null) {
      if (!isPopScope) {
        Get.back();
      }
      return;
    }
    if (!isPopScope) {
      Get.back();
    }
    await interstitialAd!.show(); // Safe to use `!` after null check
  }

  Future<void> loadInterstitialAd() async {
    if (kIsWeb || isSubscribe.value) return;

    AdsManager.instance.loadInterstitialAd(onAdLoaded: (ad) {
      interstitialAd = ad;

      interstitialAd?.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          loadInterstitialAd(); // Reload for next time
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          ad.dispose();
          loadInterstitialAd();
        },
      );
    });
  }
}
