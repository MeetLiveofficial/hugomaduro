import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krimson/common/widget/loader_widget.dart';
import 'package:krimson/common/widget/no_data_widget.dart';
import 'package:krimson/languages/languages_keys.dart';
import 'package:krimson/screen/coin_wallet_screen/coin_wallet_screen_controller.dart';
import 'package:krimson/screen/coin_wallet_screen/widget/coin_package_tile.dart';

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
            padding: const EdgeInsets.fromLTRB(15, 8, 15, 24),
            itemCount: controller.coinPlans.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final plan = controller.coinPlans[index];
              return CoinPackageTile(
                plan: plan,
                onPurchase: () => controller.onPurchase(plan),
              );
            },
          ),
        );
      }),
    );
  }
}
