import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:krimson/common/manager/session_manager.dart';
import 'package:krimson/model/general/settings_model.dart';
import 'package:krimson/utilities/app_platform.dart';

class AdsManager {
  AdsManager._();

  static final instance = AdsManager._();

  void loadBannerAd({required Function(Ad) onAdLoaded}) async {
    if (kIsWeb) return;
    Setting? setting = SessionManager.instance.getSettings();
    if (AppPlatform.isAndroid && setting?.admobAndroidStatus == 0) {
      return;
    }
    if (AppPlatform.isIOS && setting?.admobIosStatus == 0) {
      return;
    }
    BannerAd(
      adUnitId: AppPlatform.isAndroid
          ? (setting?.admobBanner ?? '')
          : (setting?.admobBannerIos ?? ''),
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: onAdLoaded,
        onAdFailedToLoad: (ad, err) {
          ad.dispose();
        },
      ),
    ).load();
  }

  Future<void> loadInterstitialAd(
      {required Function(InterstitialAd) onAdLoaded}) async {
    if (kIsWeb) return;
    Setting? setting = SessionManager.instance.getSettings();
    if (AppPlatform.isAndroid && setting?.admobAndroidStatus == 0) {
      return;
    }
    if (AppPlatform.isIOS && setting?.admobIosStatus == 0) {
      return;
    }
    await InterstitialAd.load(
        adUnitId: AppPlatform.isAndroid
            ? (setting?.admobInt ?? '')
            : (setting?.admobIntIos ?? ''),
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: onAdLoaded,
          onAdFailedToLoad: (LoadAdError error) {
            log('InterstitialAd failed to load: $error');
          },
        ));
  }

  void requestConsentInfoUpdate() {
    final params = ConsentRequestParameters(
        consentDebugSettings: ConsentDebugSettings(
            debugGeography: DebugGeography.debugGeographyEea,
            testIdentifiers: ['D5E5A833CA124D2CD5E33A574AF9EA88']));
    ConsentInformation.instance.requestConsentInfoUpdate(
      params,
      () async {
        if (await ConsentInformation.instance.isConsentFormAvailable()) {
          loadForm();
        }
      },
      (FormError error) {
        // Handle the error
      },
    );
  }

  void loadForm() {
    ConsentForm.loadConsentForm(
      (ConsentForm consentForm) async {
        var status = await ConsentInformation.instance.getConsentStatus();
        if (status == ConsentStatus.required) {
          consentForm.show((formError) {
            loadForm();
          });
        }
      },
      (FormError formError) {
        // Handle the error
      },
    );
  }
}
