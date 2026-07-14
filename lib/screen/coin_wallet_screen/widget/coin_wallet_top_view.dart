import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krimson/common/extensions/common_extension.dart';
import 'package:krimson/common/manager/session_manager.dart';
import 'package:krimson/common/widget/custom_app_bar.dart';
import 'package:krimson/common/widget/text_button_custom.dart';
import 'package:krimson/languages/languages_keys.dart';
import 'package:krimson/screen/coin_wallet_screen/coin_wallet_screen_controller.dart';
import 'package:krimson/screen/withdrawals_screen/withdrawals_screen.dart';
import 'package:krimson/utilities/asset_res.dart';
import 'package:krimson/utilities/style_res.dart';
import 'package:krimson/utilities/text_style_custom.dart';
import 'package:krimson/utilities/theme_res.dart';

class CoinWalletTopView extends StatelessWidget {
  const CoinWalletTopView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<CoinWalletScreenController>();
    final settings = SessionManager.instance.getSettings();
    final currency = settings?.currency ?? '\$';
    final coinValue = settings?.coinValue ?? 0;
    final withdrawalOn = settings?.isWithdrawalOn == 1;

    return Column(
      children: [
        CustomAppBar(title: LKey.coinWallet.tr),
        Container(
          width: double.infinity,
          margin: const EdgeInsets.fromLTRB(15, 10, 15, 0),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
          decoration: BoxDecoration(
            gradient: StyleRes.themeGradient,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Obx(() {
            final user = controller.myUser.value;
            final balance = user?.coinWallet ?? 0;
            final estimated =
                user?.coinEstimatedValue(coinValue.toDouble()) ?? 0;
            return Column(
              children: [
                Text(
                  LKey.balance.tr,
                  style: TextStyleCustom.outFitRegular400(
                    color: whitePure(context).withValues(alpha: 0.85),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(AssetRes.icCoin, height: 28, width: 28),
                    const SizedBox(width: 8),
                    Text(
                      balance.numberFormat,
                      style: TextStyleCustom.unboundedSemiBold600(
                        color: whitePure(context),
                        fontSize: 28,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '$currency${estimated.toStringAsFixed(2)}',
                  style: TextStyleCustom.outFitLight300(
                    color: whitePure(context).withValues(alpha: 0.85),
                    fontSize: 14,
                  ),
                ),
              ],
            );
          }),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(15, 12, 15, 0),
          child: Obx(() {
            final user = controller.myUser.value;
            return Row(
              children: [
                _StatChip(
                  label: LKey.collected.tr,
                  value: (user?.coinCollectedLifetime ?? 0).numberFormat,
                ),
                const SizedBox(width: 8),
                _StatChip(
                  label: LKey.gifted.tr,
                  value: (user?.coinGiftedLifetime ?? 0).numberFormat,
                ),
                const SizedBox(width: 8),
                _StatChip(
                  label: LKey.purchased.tr,
                  value: (user?.coinPurchasedLifetime ?? 0).numberFormat,
                ),
              ],
            );
          }),
        ),
        if (withdrawalOn)
          Padding(
            padding: const EdgeInsets.fromLTRB(15, 12, 15, 0),
            child: TextButtonCustom(
              onTap: () => Get.to(() => const WithdrawalsScreen()),
              title: LKey.withdrawals.tr,
              backgroundColor: bgGrey(context),
              titleColor: textDarkGrey(context),
              btnHeight: 42,
              horizontalMargin: 0,
              margin: EdgeInsets.zero,
            ),
          ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;

  const _StatChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: bgLightGrey(context),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyleCustom.unboundedMedium500(
                color: textDarkGrey(context),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyleCustom.outFitRegular400(
                color: textLightGrey(context),
                fontSize: 11,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
