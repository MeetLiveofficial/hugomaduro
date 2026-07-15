import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krimson/languages/languages_keys.dart';
import 'package:krimson/screen/coin_wallet_screen/coin_wallet_screen_controller.dart';
import 'package:krimson/screen/coin_wallet_screen/widget/coin_wallet_list.dart';
import 'package:krimson/screen/coin_wallet_screen/widget/coin_wallet_top_view.dart';
import 'package:krimson/utilities/text_style_custom.dart';
import 'package:krimson/utilities/theme_res.dart';

class CoinWalletScreen extends StatelessWidget {
  const CoinWalletScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(CoinWalletScreenController());
    return Scaffold(
      body: Column(
        children: [
          const CoinWalletTopView(),
          const SizedBox(height: 10),
          Text(LKey.coinShop.tr,
              style: TextStyleCustom.unboundedRegular400(
                color: textDarkGrey(context),
                fontSize: 15,
              )),
          const SizedBox(height: 2),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(LKey.rechargeWallet.tr,
                style: TextStyleCustom.outFitLight300(
                    color: textLightGrey(context), fontSize: 13),
                textAlign: TextAlign.center),
          ),
          CoinWalletList(controller: controller)
        ],
      ),
    );
  }
}
