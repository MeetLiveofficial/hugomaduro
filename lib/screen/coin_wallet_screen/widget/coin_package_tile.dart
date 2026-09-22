import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krimson/common/extensions/common_extension.dart';
import 'package:krimson/common/extensions/string_extension.dart';
import 'package:krimson/common/manager/app_role.dart';
import 'package:krimson/common/widget/custom_image.dart';
import 'package:krimson/common/widget/text_button_custom.dart';
import 'package:krimson/languages/catalog_i18n.dart';
import 'package:krimson/languages/languages_keys.dart';
import 'package:krimson/screen/coin_wallet_screen/coin_wallet_screen_controller.dart';
import 'package:krimson/screen/coin_wallet_screen/widget/coin_pack_visuals.dart';
import 'package:krimson/utilities/asset_res.dart';
import 'package:krimson/utilities/client_colors.dart';
import 'package:krimson/utilities/text_style_custom.dart';
import 'package:krimson/utilities/theme_res.dart';

class CoinPackageTile extends StatelessWidget {
  final CoinPlan plan;
  final VoidCallback onPurchase;
  final Color? buttonColor;
  final int index;

  const CoinPackageTile({
    super.key,
    required this.plan,
    required this.onPurchase,
    this.buttonColor,
    this.index = 0,
  });

  @override
  Widget build(BuildContext context) {
    final client = AppRole.isClient();
    final visual = CoinPackVisual.of(index);
    final accent = client
        ? visual.accent
        : (buttonColor ?? themeAccentSolid(context));
    final titleCol = client ? ClientColors.text : textDarkGrey(context);
    final mutedCol =
        client ? ClientColors.textMuted : textLightGrey(context);
    final hasBonus = plan.bonusCoins > 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: client
          ? BoxDecoration(
              color: const Color(0xFF10182F),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: accent.withValues(alpha: 0.9), width: 1.3),
              boxShadow: ClientColors.neonGlow(
                color: accent,
                alpha: index == 0 ? 0.4 : 0.22,
                blur: index == 0 ? 16 : 10,
              ),
            )
          : BoxDecoration(
              color: bgLightGrey(context),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: hasBonus
                    ? accent.withValues(alpha: 0.55)
                    : Colors.transparent,
              ),
            ),
      child: Row(
        children: [
          if (client && (plan.image ?? '').isEmpty)
            CoinPackLeading(
              accent: accent,
              stackCount: visual.stackCount,
              hasGift: visual.hasGift,
            )
          else
            CustomImage(
              size: const Size(42, 42),
              strokeWidth: 0,
              image: (plan.image ?? '').isNotEmpty
                  ? plan.image!.addBaseURL()
                  : null,
              radius: 10,
              fit: BoxFit.cover,
              isShowPlaceHolder: true,
              fullName: '${plan.coin}',
            ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if ((plan.name ?? '').isNotEmpty)
                  Text(
                    CatalogI18n.packageName(plan.name),
                    style: TextStyleCustom.outFitMedium500(
                      color: titleCol,
                      fontSize: 12,
                    ),
                  ),
                Row(
                  children: [
                    Image.asset(AssetRes.icCoin, height: 16, width: 16),
                    const SizedBox(width: 5),
                    Text(
                      plan.coin.numberFormat,
                      style: TextStyleCustom.unboundedMedium500(
                        color: titleCol,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  client
                      ? plan.usdLabel
                      : hasBonus
                          ? '${plan.baseCoins.numberFormat} + ${plan.bonusPercent.toStringAsFixed(0)}% (${plan.bonusCoins.numberFormat}) · ${plan.usdLabel}'
                          : plan.usdLabel,
                  style: TextStyleCustom.outFitRegular400(
                    color: mutedCol,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          TextButtonCustom(
            onTap: onPurchase,
            title: LKey.purchase.tr,
            gradient: client && index < 3,
            backgroundColor: client
                ? (index < 3 ? null : visual.button)
                : accent,
            titleColor: whitePure(context),
            btnHeight: 32,
            btnWidth: 88,
            fontSize: 12,
            horizontalMargin: 0,
            margin: EdgeInsets.zero,
            radius: client ? 18 : 8,
          ),
        ],
      ),
    );
  }
}
