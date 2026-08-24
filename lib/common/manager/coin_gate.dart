import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krimson/common/manager/app_role.dart';
import 'package:krimson/common/manager/session_manager.dart';
import 'package:krimson/common/widget/loader_widget.dart';
import 'package:krimson/common/widget/no_data_widget.dart';
import 'package:krimson/languages/languages_keys.dart';
import 'package:krimson/screen/coin_wallet_screen/coin_wallet_screen_controller.dart';
import 'package:krimson/screen/coin_wallet_screen/widget/coin_package_tile.dart';
import 'package:krimson/utilities/client_colors.dart';
import 'package:krimson/utilities/color_res.dart';
import 'package:krimson/utilities/text_style_custom.dart';
import 'package:krimson/utilities/theme_res.dart';

/// Validación de monedas + sheet “Mis monedas” (paquetes).
class CoinGate {
  CoinGate._();

  /// `true` si hay saldo suficiente. Si no, muestra toast y abre la tienda.
  static bool ensureEnough(int needed, {String? message}) {
    final wallet =
        (SessionManager.instance.getUser()?.coinWallet ?? 0).toInt();
    if (wallet >= needed) return true;

    final msg = message ?? LKey.insufficientCoins.tr;
    Get.snackbar(
      '',
      msg,
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.black87,
      colorText: Colors.white,
      margin: const EdgeInsets.all(12),
      borderRadius: 24,
      titleText: const SizedBox.shrink(),
      messageText: Text(
        msg,
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.white, fontSize: 14),
      ),
      duration: const Duration(seconds: 2),
    );
    openCoinShopSheet();
    return false;
  }

  static void openCoinShopSheet({String? headline}) {
    if (!Get.isRegistered<CoinWalletScreenController>()) {
      Get.put(CoinWalletScreenController());
    } else {
      Get.find<CoinWalletScreenController>().fetchData();
      Get.find<CoinWalletScreenController>().fetchOfferings();
    }

    final wallet =
        (SessionManager.instance.getUser()?.coinWallet ?? 0).toInt();

    final ctx = Get.context ?? Get.overlayContext;
    final sheet = _CoinShopSheet(initialCoins: wallet, headline: headline);
    Get.bottomSheet(
      ctx == null ? sheet : ThemeRes.applyIfClient(ctx, sheet),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }
}

class _CoinShopSheet extends StatelessWidget {
  final int initialCoins;
  final String? headline;

  const _CoinShopSheet({required this.initialCoins, this.headline});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<CoinWalletScreenController>();
    final client = AppRole.isClient();
    return Container(
      height: MediaQuery.sizeOf(context).height * 0.72,
      decoration: BoxDecoration(
        color: client ? ClientColors.surface : whitePure(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: client ? ClientColors.border : bgGrey(context),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Obx(() {
                      final coins =
                          (controller.myUser.value?.coinWallet ?? initialCoins)
                              .toInt();
                      return Text(
                        LKey.myCoinsCount.trParams({'coins': '$coins'}),
                        style: TextStyleCustom.outFitMedium500(
                          color: client
                              ? ClientColors.primary
                              : ColorRes.themeAccentSolid,
                          fontSize: 16,
                        ),
                      );
                    }),
                  ),
                  IconButton(
                    onPressed: Get.back,
                    icon: Icon(
                      Icons.close,
                      color: client
                          ? ClientColors.textMuted
                          : textLightGrey(context),
                    ),
                  ),
                ],
              ),
            ),
            if ((headline ?? '').isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Text(
                  headline!,
                  textAlign: TextAlign.center,
                  style: TextStyleCustom.outFitRegular400(
                    color: client
                        ? ClientColors.textMuted
                        : textDarkGrey(context),
                    fontSize: 13,
                  ),
                ),
              ),
            Expanded(
              child: Obx(() {
                if (controller.isLoading.value &&
                    controller.coinPlans.isEmpty) {
                  return const LoaderWidget();
                }
                return NoDataView(
                  showShow: !controller.isLoading.value &&
                      controller.coinPlans.isEmpty,
                  title: LKey.coinShop.tr,
                  description: LKey.rechargeWallet.tr,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(15, 4, 15, 24),
                    itemCount: controller.coinPlans.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final plan = controller.coinPlans[index];
                      return CoinPackageTile(
                        plan: plan,
                        onPurchase: () => controller.onPurchase(plan),
                        buttonColor:
                            client ? ClientColors.primary : ColorRes.themeAccentSolid,
                      );
                    },
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
