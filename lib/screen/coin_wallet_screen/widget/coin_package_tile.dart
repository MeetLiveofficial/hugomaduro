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
import 'package:krimson/utilities/asset_res.dart';
import 'package:krimson/utilities/client_colors.dart';
import 'package:krimson/utilities/text_style_custom.dart';
import 'package:krimson/utilities/theme_res.dart';

class CoinPackageTile extends StatelessWidget {
  final CoinPlan plan;
  final VoidCallback onPurchase;
  final Color? buttonColor;

  const CoinPackageTile({
    super.key,
    required this.plan,
    required this.onPurchase,
    this.buttonColor,
  });

  @override
  Widget build(BuildContext context) {
    final client = AppRole.isClient();
    final accent = buttonColor ??
        (client ? ClientColors.primary : themeAccentSolid(context));
    final titleCol = client ? ClientColors.text : textDarkGrey(context);
    final mutedCol = client ? ClientColors.textMuted : textLightGrey(context);
    final hasBonus = plan.bonusCoins > 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: client ? ClientColors.surfaceAlt : bgLightGrey(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasBonus
              ? accent.withValues(alpha: 0.55)
              : (client
                  ? ClientColors.border.withValues(alpha: 0.7)
                  : Colors.transparent),
        ),
      ),
      child: Row(
        children: [
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
                  hasBonus
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
            backgroundColor: accent,
            titleColor: client ? ClientColors.bg : whitePure(context),
            btnHeight: 32,
            btnWidth: 88,
            fontSize: 12,
            horizontalMargin: 0,
            margin: EdgeInsets.zero,
            radius: 8,
          ),
        ],
      ),
    );
  }
}
