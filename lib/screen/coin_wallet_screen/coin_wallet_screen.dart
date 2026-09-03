import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krimson/common/manager/app_role.dart';
import 'package:krimson/languages/languages_keys.dart';
import 'package:krimson/screen/coin_wallet_screen/coin_wallet_screen_controller.dart';
import 'package:krimson/screen/coin_wallet_screen/widget/coin_wallet_list.dart';
import 'package:krimson/screen/coin_wallet_screen/widget/coin_wallet_top_view.dart';
import 'package:krimson/screen/wallet_history_screen/wallet_history_screen.dart';
import 'package:krimson/utilities/client_colors.dart';
import 'package:krimson/utilities/text_style_custom.dart';
import 'package:krimson/utilities/theme_res.dart';

class CoinWalletScreen extends StatelessWidget {
  const CoinWalletScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(CoinWalletScreenController());
    final isEarner = AppRole.canEarn();
    return ThemeRes.applyIfClient(
      context,
      Scaffold(
      backgroundColor: AppRole.isClient() ? ClientColors.bg : null,
      body: Column(
        children: [
          const CoinWalletTopView(),
          if (isEarner)
            const Expanded(child: WalletHistoryScreen(embedded: true))
          else ...[
            const SizedBox(height: 10),
            Text(LKey.coinShop.tr,
                style: TextStyleCustom.unboundedRegular400(
                  color: AppRole.isClient()
                      ? ClientColors.text
                      : textDarkGrey(context),
                  fontSize: 15,
                )),
            const SizedBox(height: 2),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                LKey.rechargeWallet.tr,
                style: TextStyleCustom.outFitRegular400(
                  color: AppRole.isClient()
                      ? ClientColors.text.withValues(alpha: 0.92)
                      : textLightGrey(context),
                  fontSize: 14,
                ).copyWith(height: 1.35),
                textAlign: TextAlign.center,
              ),
            ),
            CoinWalletList(controller: controller),
          ],
        ],
      ),
    ),
    );
  }
}
