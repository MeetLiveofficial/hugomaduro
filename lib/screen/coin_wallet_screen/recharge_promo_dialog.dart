import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krimson/common/widget/custom_image.dart';
import 'package:krimson/languages/languages_keys.dart';
import 'package:krimson/screen/coin_wallet_screen/coin_wallet_screen_controller.dart';
import 'package:krimson/utilities/color_res.dart';
import 'package:krimson/utilities/text_style_custom.dart';

/// Anuncio de recarga (~mitad de pantalla) cuando el cliente se queda sin coins.
class RechargePromo {
  RechargePromo._();

  static bool _open = false;

  static const Color _bg = Color(0xFF5C2D8C);
  static const Color _card = Color(0xFF7B46B0);
  static const Color _priceBtn = Color(0xFF2A1548);
  static const Color _gold = Color(0xFFFFD54F);

  static Future<void> show({
    String? peerName,
    String? peerPhotoUrl,
  }) async {
    if (_open) return;
    _open = true;
    if (!Get.isRegistered<CoinWalletScreenController>()) {
      Get.put(CoinWalletScreenController());
    } else {
      Get.find<CoinWalletScreenController>().fetchData();
      Get.find<CoinWalletScreenController>().fetchOfferings();
    }
    try {
      await Get.bottomSheet<void>(
        _RechargePromoBody(
          peerName: (peerName ?? '').trim(),
          peerPhotoUrl: (peerPhotoUrl ?? '').trim(),
        ),
        isScrollControlled: true,
        isDismissible: true,
        enableDrag: true,
        backgroundColor: Colors.transparent,
        barrierColor: Colors.black54,
      );
    } finally {
      _open = false;
    }
  }
}

class _RechargePromoBody extends StatelessWidget {
  const _RechargePromoBody({
    required this.peerName,
    required this.peerPhotoUrl,
  });

  final String peerName;
  final String peerPhotoUrl;

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<CoinWalletScreenController>();
    final sheetH = MediaQuery.sizeOf(context).height * 0.5;
    final hasPeer = peerPhotoUrl.isNotEmpty || peerName.isNotEmpty;
    return SizedBox(
      height: sheetH,
      child: Material(
        color: RechargePromo._bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
        clipBehavior: Clip.antiAlias,
        child: SafeArea(
          top: false,
          child: Stack(
            children: [
              Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  onPressed: Get.back,
                  icon: const Icon(Icons.close_rounded, color: Colors.white70),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Column(
                  children: [
                    Container(
                      width: 36,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    if (hasPeer) ...[
                      CustomImage(
                        size: const Size(52, 52),
                        image: peerPhotoUrl.isEmpty ? null : peerPhotoUrl,
                        fullName: peerName,
                        strokeWidth: 2,
                        strokeColor: Colors.white24,
                        isShowPlaceHolder: true,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        peerName.isEmpty ? '' : '$peerName 💞',
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyleCustom.outFitSemiBold600(
                          color: Colors.white,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    _LikeTitle(text: LKey.likeThem.tr),
                    const SizedBox(height: 4),
                    Text(
                      LKey.rechargeAndCallAgain.tr,
                      textAlign: TextAlign.center,
                      style: TextStyleCustom.outFitSemiBold600(
                        color: Colors.white,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _RecargarDivider(label: LKey.recharge.tr),
                    const SizedBox(height: 10),
                    Expanded(
                      child: Obx(() {
                        if (controller.isLoading.value &&
                            controller.coinPlans.isEmpty) {
                          return const Center(
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.4,
                            ),
                          );
                        }
                        final plans = controller.coinPlans.take(3).toList();
                        if (plans.isEmpty) {
                          return Center(
                            child: Text(
                              LKey.rechargeWallet.tr,
                              textAlign: TextAlign.center,
                              style: TextStyleCustom.outFitMedium500(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          );
                        }
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            for (var i = 0; i < plans.length; i++) ...[
                              if (i > 0) const SizedBox(width: 8),
                              Expanded(
                                child: _PromoPlanCard(
                                  plan: plans[i],
                                  onBuy: () {
                                    Get.back();
                                    controller.onPurchase(plans[i]);
                                  },
                                ),
                              ),
                            ],
                          ],
                        );
                      }),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LikeTitle extends StatelessWidget {
  const _LikeTitle({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyleCustom.unboundedMedium500(
            color: Colors.white,
            fontSize: 22,
          ),
        ),
        const Positioned(
          left: 8,
          top: 0,
          child: Icon(Icons.auto_awesome, color: ColorRes.roseMuted, size: 16),
        ),
        const Positioned(
          right: 18,
          bottom: 4,
          child: Icon(Icons.auto_awesome, color: ColorRes.crimson, size: 14),
        ),
      ],
    );
  }
}

class _RecargarDivider extends StatelessWidget {
  const _RecargarDivider({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0x00F9A8D4), ColorRes.crimson],
              ),
            ),
            child: SizedBox(height: 1.4),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            label,
            style: TextStyleCustom.outFitMedium500(
              color: Colors.white,
              fontSize: 14,
            ),
          ),
        ),
        const Expanded(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [ColorRes.mlPurple, Color(0x0027D3F5)],
              ),
            ),
            child: SizedBox(height: 1.4),
          ),
        ),
      ],
    );
  }
}

class _PromoPlanCard extends StatelessWidget {
  const _PromoPlanCard({required this.plan, required this.onBuy});

  final CoinPlan plan;
  final VoidCallback onBuy;

  @override
  Widget build(BuildContext context) {
    final price = plan.amountUsd != null
        ? '\$${CoinPlan.formatUsdAmount(plan.amountUsd!)}'
        : plan.priceString;
    return Container(
      padding: const EdgeInsets.fromLTRB(6, 8, 6, 8),
      decoration: BoxDecoration(
        color: RechargePromo._card,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Text(
            '${plan.coin}',
            style: TextStyleCustom.unboundedMedium500(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            LKey.beginnerDiscount.tr,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyleCustom.outFitMedium500(
              color: RechargePromo._gold,
              fontSize: 10,
            ),
          ),
          const Spacer(),
          const Icon(
            Icons.diamond_rounded,
            color: Color(0xFFFF7AD9),
            size: 36,
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: 36,
            child: ElevatedButton(
              onPressed: onBuy,
              style: ElevatedButton.styleFrom(
                backgroundColor: RechargePromo._priceBtn,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              child: Text(
                price,
                style: TextStyleCustom.outFitSemiBold600(
                  color: Colors.white,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
