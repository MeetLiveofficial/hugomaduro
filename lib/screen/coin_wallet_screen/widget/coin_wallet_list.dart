import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krimson/common/extensions/common_extension.dart';
import 'package:krimson/common/extensions/string_extension.dart';
import 'package:krimson/common/widget/custom_image.dart';
import 'package:krimson/common/widget/loader_widget.dart';
import 'package:krimson/common/widget/no_data_widget.dart';
import 'package:krimson/common/widget/text_button_custom.dart';
import 'package:krimson/languages/languages_keys.dart';
import 'package:krimson/screen/coin_wallet_screen/coin_wallet_screen_controller.dart';
import 'package:krimson/utilities/asset_res.dart';
import 'package:krimson/utilities/text_style_custom.dart';
import 'package:krimson/utilities/theme_res.dart';

class CoinWalletList extends StatelessWidget {
  final CoinWalletScreenController controller;

  const CoinWalletList({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Obx(() {
        if (controller.isLoading.value && controller.coinPlans.isEmpty) {
          return const LoaderWidget();
        }

        return NoDataView(
          showShow:
              !controller.isLoading.value && controller.coinPlans.isEmpty,
          title: LKey.coinShop.tr,
          description: LKey.rechargeWallet.tr,
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(15, 10, 15, 30),
            itemCount: controller.coinPlans.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final plan = controller.coinPlans[index];
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: bgLightGrey(context),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    CustomImage(
                      size: const Size(52, 52),
                      strokeWidth: 0,
                      image: (plan.image ?? '').isNotEmpty
                          ? plan.image!.addBaseURL()
                          : null,
                      radius: 12,
                      fit: BoxFit.cover,
                      isShowPlaceHolder: true,
                      fullName: '${plan.coin}',
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Image.asset(
                                AssetRes.icCoin,
                                height: 18,
                                width: 18,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                plan.coin.numberFormat,
                                style: TextStyleCustom.unboundedMedium500(
                                  color: textDarkGrey(context),
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            plan.priceString,
                            style: TextStyleCustom.outFitRegular400(
                              color: textLightGrey(context),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButtonCustom(
                      onTap: () => controller.onPurchase(plan),
                      title: LKey.purchase.tr,
                      backgroundColor: themeAccentSolid(context),
                      titleColor: whitePure(context),
                      btnHeight: 36,
                      btnWidth: 96,
                      fontSize: 13,
                      horizontalMargin: 0,
                      margin: EdgeInsets.zero,
                      radius: 8,
                    ),
                  ],
                ),
              );
            },
          ),
        );
      }),
    );
  }
}
