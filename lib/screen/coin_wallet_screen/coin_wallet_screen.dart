import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krimson/common/manager/app_role.dart';
import 'package:krimson/languages/languages_keys.dart';
import 'package:krimson/screen/coin_wallet_screen/coin_wallet_screen_controller.dart';
import 'package:krimson/screen/coin_wallet_screen/widget/coin_wallet_list.dart';
import 'package:krimson/screen/coin_wallet_screen/widget/coin_wallet_top_view.dart';
import 'package:krimson/screen/wallet_history_screen/wallet_history_screen.dart';
import 'package:krimson/utilities/role_colors.dart';
import 'package:krimson/utilities/text_style_custom.dart';
import 'package:krimson/utilities/theme_res.dart';

class CoinWalletScreen extends StatelessWidget {
  const CoinWalletScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(CoinWalletScreenController());
    final isEarner = AppRole.canEarn();
    return Theme(
      data: ThemeRes.roleTheme(context),
      child: Scaffold(
        backgroundColor: RolePalette.bg,
        body: Column(
          children: [
            const CoinWalletTopView(),
            if (isEarner)
              const Expanded(child: WalletHistoryScreen(embedded: true))
            else ...[
              const SizedBox(height: 10),
              Text(LKey.coinShop.tr,
                  style: TextStyleCustom.unboundedRegular400(
                    color: RolePalette.text,
                    fontSize: 15,
                  )),
              const SizedBox(height: 2),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(LKey.rechargeWallet.tr,
                    style: TextStyleCustom.outFitLight300(
                        color: RolePalette.textMuted, fontSize: 13),
                    textAlign: TextAlign.center),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(15, 8, 15, 0),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: RolePalette.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: RolePalette.primary.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Text(
                    LKey.rechargeWallet.tr,
                    textAlign: TextAlign.center,
                    style: TextStyleCustom.outFitSemiBold600(
                      color: RolePalette.primary,
                      fontSize: 13,
                    ),
                  ),
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
