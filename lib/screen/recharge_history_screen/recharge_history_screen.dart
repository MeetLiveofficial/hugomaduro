import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krimson/common/controller/base_controller.dart';
import 'package:krimson/common/extensions/common_extension.dart';
import 'package:krimson/common/extensions/string_extension.dart';
import 'package:krimson/common/manager/session_manager.dart';
import 'package:krimson/common/service/api/gift_wallet_service.dart';
import 'package:krimson/common/service/api/user_service.dart';
import 'package:krimson/common/widget/custom_app_bar.dart';
import 'package:krimson/common/widget/loader_widget.dart';
import 'package:krimson/common/widget/no_data_widget.dart';
import 'package:krimson/languages/languages_keys.dart';
import 'package:krimson/model/gift_wallet/coin_recharge_model.dart';
import 'package:krimson/screen/coin_wallet_screen/coin_wallet_screen_controller.dart';
import 'package:krimson/utilities/asset_res.dart';
import 'package:krimson/utilities/text_style_custom.dart';
import 'package:krimson/utilities/theme_res.dart';

class RechargeHistoryScreen extends StatelessWidget {
  const RechargeHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(RechargeHistoryController());
    final currency = SessionManager.instance.getSettings()?.currency ?? '\$';

    return Scaffold(
      body: Column(
        children: [
          CustomAppBar(title: LKey.rechargeHistory.tr),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value && controller.items.isEmpty) {
                return const LoaderWidget();
              }
              return NoDataView(
                showShow:
                    !controller.isLoading.value && controller.items.isEmpty,
                title: LKey.noRecharges.tr,
                description: LKey.noRechargesDesc.tr,
                child: ListView.builder(
                  itemCount: controller.items.length,
                  padding: const EdgeInsets.only(top: 1, bottom: 24),
                  itemBuilder: (context, index) {
                    final item = controller.items[index];
                    return Container(
                      color: bgLightGrey(context),
                      margin: const EdgeInsets.symmetric(vertical: 1),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      child: Row(
                        children: [
                          Image.asset(AssetRes.icCoin, width: 28, height: 28),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '+${(item.coins ?? 0).numberFormat} ${LKey.coins.tr}',
                                  style: TextStyleCustom.outFitMedium500(
                                    color: textDarkGrey(context),
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  item.note ??
                                      (item.source == 'admin'
                                          ? LKey.rechargeSourceAdmin.tr
                                          : item.source == 'crypto'
                                              ? LKey.rechargeSourceCrypto.tr
                                              : item.source == 'wompi'
                                                  ? LKey.rechargeSourceWompi.tr
                                                  : LKey.inAppPurchase.tr),
                                  style: TextStyleCustom.outFitRegular400(
                                    color: textLightGrey(context),
                                    fontSize: 12,
                                  ),
                                ),
                                if ((item.createdAt ?? '').isNotEmpty)
                                  Text(
                                    item.createdAt!.formatDate1,
                                    style: TextStyleCustom.outFitLight300(
                                      color: textLightGrey(context),
                                      fontSize: 11,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Text(
                            '$currency${(item.amountUsd ?? 0).toStringAsFixed(2)}',
                            style: TextStyleCustom.outFitBold700(
                              color: textDarkGrey(context),
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class RechargeHistoryController extends BaseController {
  final RxList<CoinRecharge> items = <CoinRecharge>[].obs;

  @override
  void onInit() {
    super.onInit();
    _fetch();
  }

  Future<void> _fetch() async {
    if (isLoading.value) return;
    isLoading.value = true;
    try {
      await GiftWalletService.instance.syncPendingCryptoPayments();
      await GiftWalletService.instance.syncPendingWompiPayments();
      final list = await GiftWalletService.instance.fetchMyRecharges();
      items.assignAll(list);
      final user = await UserService.instance.fetchUserDetails(
        userId: SessionManager.instance.getUserID(),
      );
      if (user != null) {
        SessionManager.instance.setUser(user);
        if (Get.isRegistered<CoinWalletScreenController>()) {
          Get.find<CoinWalletScreenController>().myUser.value = user;
        }
      }
    } catch (_) {
    } finally {
      isLoading.value = false;
    }
  }
}