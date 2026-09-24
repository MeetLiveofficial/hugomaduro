import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krimson/common/extensions/common_extension.dart';
import 'package:krimson/common/manager/app_role.dart';
import 'package:krimson/common/manager/session_manager.dart';
import 'package:krimson/common/widget/custom_app_bar.dart';
import 'package:krimson/common/widget/text_button_custom.dart';
import 'package:krimson/languages/languages_keys.dart';
import 'package:krimson/screen/coin_wallet_screen/coin_wallet_screen_controller.dart';
import 'package:krimson/screen/withdrawals_screen/withdrawals_screen.dart';
import 'package:krimson/utilities/asset_res.dart';
import 'package:krimson/utilities/client_colors.dart';
import 'package:krimson/utilities/style_res.dart';
import 'package:krimson/utilities/text_style_custom.dart';
import 'package:krimson/utilities/theme_res.dart';

class CoinWalletTopView extends StatelessWidget {
  const CoinWalletTopView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<CoinWalletScreenController>();
    final settings = SessionManager.instance.getSettings();
    final coinValue = settings?.coinValue ?? 0;
    final withdrawalOn = settings?.isWithdrawalOn == 1;
    final canWithdraw = withdrawalOn && AppRole.canWithdraw();
    final client = AppRole.isClient();
    final streamer = AppRole.isStreamer();

    return Column(
      children: [
        CustomAppBar(
          title: LKey.coinWallet.tr,
          bgColor: streamer ? Colors.transparent : null,
          iconColor: streamer ? Colors.white : null,
          titleStyle: streamer
              ? TextStyleCustom.unboundedMedium500(
                  color: Colors.white,
                  fontSize: 18,
                )
              : null,
        ),
        Container(
          width: double.infinity,
          margin: const EdgeInsets.fromLTRB(15, 6, 15, 0),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: client
            ? ClientColors.glass(radius: 16)
            : streamer
                ? BoxDecoration(
                    color: const Color(0xCC160820),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0x73E879F9)),
                  )
                : BoxDecoration(
                    gradient: StyleRes.themeGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
          child: Obx(() {
            // Fuente de verdad en vivo (regalos/llamadas/match).
            final balance = SessionManager.instance.coinWalletRx.value;
            final balanceLabel = balance.fullNumberFormat;
            final showUsdValue = AppRole.canEarn();
            final estimated = showUsdValue ? balance * coinValue.toDouble() : 0.0;
            return Column(
              children: [
            Text(
              LKey.balance.tr,
              style: TextStyleCustom.outFitRegular400(
                color: client
                    ? ClientColors.textMuted
                    : (streamer
                        ? Colors.white70
                        : whitePure(context).withValues(alpha: 0.85)),
                fontSize: 12,
              ),
            ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(AssetRes.icCoin, height: 20, width: 20),
                    const SizedBox(width: 6),
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          balanceLabel,
                          key: ValueKey('wallet_balance_$balanceLabel'),
                          maxLines: 1,
                          style: TextStyleCustom.unboundedSemiBold600(
                            color: client
                                ? ClientColors.text
                                : (streamer
                                    ? const Color(0xFFFF4D9A)
                                    : whitePure(context)),
                            fontSize: 22,
                          ).copyWith(
                            height: 1.4,
                            leadingDistribution: TextLeadingDistribution.even,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                if (showUsdValue) ...[
                  const SizedBox(height: 4),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      estimated.fullCurrencyFormat,
                      maxLines: 1,
                      style: TextStyleCustom.outFitLight300(
                        color: streamer
                            ? Colors.white70
                            : whitePure(context).withValues(alpha: 0.85),
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ],
            );
          }),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(15, 8, 15, 0),
          child: Obx(() {
            final user = controller.myUser.value;
            return Row(
              children: [
                _StatChip(
                  label: LKey.collected.tr,
                  value: (user?.coinCollectedLifetime ?? 0).fullNumberFormat,
                ),
                if (!AppRole.canEarn()) ...[
                  const SizedBox(width: 6),
                  _StatChip(
                    label: LKey.gifted.tr,
                    value: (user?.coinGiftedLifetime ?? 0).fullNumberFormat,
                  ),
                  const SizedBox(width: 6),
                  _StatChip(
                    label: LKey.purchased.tr,
                    value: (user?.coinPurchasedLifetime ?? 0).fullNumberFormat,
                  ),
                ],
              ],
            );
          }),
        ),
        if (canWithdraw)
          Padding(
            padding: const EdgeInsets.fromLTRB(15, 8, 15, 0),
            child: TextButtonCustom(
              onTap: () => Get.to(() => const WithdrawalsScreen()),
              title: LKey.withdrawals.tr,
              backgroundColor: client
                  ? ClientColors.surfaceDarkAlt
                  : (streamer ? const Color(0xCC160820) : bgGrey(context)),
              titleColor: client
                  ? ClientColors.text
                  : (streamer ? Colors.white : textDarkGrey(context)),
              btnHeight: 34,
              horizontalMargin: 0,
              margin: EdgeInsets.zero,
              fontSize: 13,
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
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
        decoration: AppRole.isClient()
            ? ClientColors.glass(radius: 12)
            : AppRole.isStreamer()
                ? BoxDecoration(
                    color: const Color(0xCC160820),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0x73E879F9)),
                  )
                : BoxDecoration(
                    color: bgLightGrey(context),
                    borderRadius: BorderRadius.circular(12),
                  ),
        child: Column(
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                maxLines: 1,
                style: TextStyleCustom.unboundedMedium500(
                  color: AppRole.isClient()
                      ? ClientColors.text
                      : (AppRole.isStreamer()
                          ? Colors.white
                          : textDarkGrey(context)),
                  fontSize: 12,
                ).copyWith(
                  height: 1.4,
                  leadingDistribution: TextLeadingDistribution.even,
                ),
              ),
            ),
            const SizedBox(height: 1),
            Text(
              label,
              style: TextStyleCustom.outFitRegular400(
                color: AppRole.isClient()
                    ? ClientColors.textOnDarkMuted
                    : (AppRole.isStreamer()
                        ? Colors.white70
                        : textLightGrey(context)),
                fontSize: 10,
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
