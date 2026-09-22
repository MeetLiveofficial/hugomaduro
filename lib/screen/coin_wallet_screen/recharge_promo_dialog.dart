import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krimson/common/extensions/common_extension.dart';
import 'package:krimson/common/manager/session_manager.dart';
import 'package:krimson/languages/catalog_i18n.dart';
import 'package:krimson/languages/languages_keys.dart';
import 'package:krimson/screen/coin_wallet_screen/coin_wallet_screen_controller.dart';
import 'package:krimson/screen/coin_wallet_screen/widget/coin_pack_visuals.dart';
import 'package:krimson/utilities/asset_res.dart';
import 'package:krimson/utilities/client_colors.dart';
import 'package:krimson/utilities/text_style_custom.dart';

/// Overlay de recarga (LIVE / llamada): lista de paquetes estilo mock neon.
class RechargePromo {
  RechargePromo._();

  static bool _open = false;

  /// [peerName] / [peerPhotoUrl] se conservan por call sites.
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
        const _RechargePromoBody(),
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
  const _RechargePromoBody();

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<CoinWalletScreenController>();
    final mq = MediaQuery.of(context);
    final sheetH = (mq.size.height * 0.82) + mq.padding.bottom;

    return SizedBox(
      height: sheetH,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFF5C542),
                Color(0xFFE879F9),
                Color(0xFF27D3F5),
                Color(0xFF8B5CF6),
              ],
            ),
            boxShadow: ClientColors.neonGlow(
              color: ClientColors.magentaHot,
              alpha: 0.45,
              blur: 28,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(1.6),
            child: Material(
              color: const Color(0xFF0A1224),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(26.5)),
              clipBehavior: Clip.antiAlias,
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFF1A1548),
                      Color(0xFF0E1633),
                      Color(0xFF070E1C),
                    ],
                  ),
                ),
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                    child: Column(
                      children: [
                        Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.white24,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 10),
                        const _PromoHeader(),
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
                            final plans = controller.coinPlans.toList();
                            if (plans.isEmpty) {
                              return Center(
                                child: Text(
                                  LKey.rechargeWallet.tr,
                                  textAlign: TextAlign.center,
                                  style: TextStyleCustom.outFitMedium500(
                                    color: Colors.white70,
                                    fontSize: 13,
                                  ),
                                ),
                              );
                            }
                            return ListView.separated(
                              padding: const EdgeInsets.only(bottom: 8),
                              itemCount: plans.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 8),
                              itemBuilder: (context, i) {
                                final plan = plans[i];
                                return _PromoPlanRow(
                                  plan: plan,
                                  style: CoinPackVisual.of(i),
                                  onBuy: () => controller.onPurchase(plan),
                                );
                              },
                            );
                          }),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PromoHeader extends StatelessWidget {
  const _PromoHeader();

  bool get _es => Get.locale?.languageCode == 'es';

  @override
  Widget build(BuildContext context) {
    final tagline = _es
        ? 'Más monedas, más regalos, ¡más diversión!'
        : 'More coins, more gifts, more fun!';
    final ctaTop = _es ? '¡Recarga ahora y' : 'Top up now and';
    final ctaMain = _es ? 'apoya a tus favoritas!' : 'Support Your Favorite Girls!';

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 10, 12),
      decoration: BoxDecoration(
        color: const Color(0xFF121A38),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: ClientColors.gold.withValues(alpha: 0.55)),
        boxShadow: [
          ...ClientColors.neonGlow(color: ClientColors.gold, alpha: 0.22),
          ...ClientColors.neonGlow(
            color: ClientColors.magentaHot,
            alpha: 0.18,
            blur: 18,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: ClientColors.neonGlow(
                color: ClientColors.gold,
                alpha: 0.55,
                blur: 16,
              ),
            ),
            child: Image.asset(AssetRes.icCoin, width: 46, height: 46),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 6,
            child: Obx(() {
              final coins = SessionManager.instance.coinWalletRx.value;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          LKey.myCoinsCount
                              .trParams({'coins': ''}).replaceAll(
                            RegExp(r'[:：]\s*$'),
                            '',
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyleCustom.outFitMedium500(
                            color: Colors.white,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.workspace_premium_rounded,
                        color: ClientColors.gold,
                        size: 15,
                      ),
                    ],
                  ),
                  Text(
                    coins.fullNumberFormat,
                    style: TextStyleCustom.unboundedBold700(
                      color: Colors.white,
                      fontSize: 24,
                    ),
                  ),
                  Text(
                    tagline,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyleCustom.outFitRegular400(
                      color: Colors.white54,
                      fontSize: 10,
                    ),
                  ),
                ],
              );
            }),
          ),
          const SizedBox(width: 6),
          Expanded(
            flex: 5,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        ctaTop,
                        textAlign: TextAlign.right,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyleCustom.outFitMedium500(
                          color: ClientColors.magentaHot,
                          fontSize: 11,
                        ),
                      ),
                      ShaderMask(
                        blendMode: BlendMode.srcIn,
                        shaderCallback: (b) =>
                            ClientColors.titleGradient.createShader(b),
                        child: Text(
                          ctaMain,
                          textAlign: TextAlign.right,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyleCustom.unboundedBold700(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: ClientColors.neonGlow(
                          color: ClientColors.magentaHot,
                          alpha: 0.5,
                          blur: 12,
                        ),
                      ),
                      child: Image.asset(
                        AssetRes.icGift,
                        width: 32,
                        height: 32,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.card_giftcard_rounded,
                          color: ClientColors.magentaHot,
                          size: 28,
                        ),
                      ),
                    ),
                    const Positioned(
                      right: -4,
                      top: -4,
                      child: Icon(
                        Icons.favorite_rounded,
                        color: Color(0xFFF472B6),
                        size: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PromoPlanRow extends StatelessWidget {
  const _PromoPlanRow({
    required this.plan,
    required this.style,
    required this.onBuy,
  });

  final CoinPlan plan;
  final CoinPackVisual style;
  final VoidCallback onBuy;

  @override
  Widget build(BuildContext context) {
    final name = CatalogI18n.packageName(plan.name);
    final price = plan.usdLabel;
    final badge = style.badge;
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 10, 8, 10),
      decoration: BoxDecoration(
        color: const Color(0xFF10182F),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: style.accent, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: style.accent.withValues(alpha: 0.42),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CoinPackLeading(
            accent: style.accent,
            stackCount: style.stackCount,
            hasGift: style.hasGift,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (badge != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 3),
                    child: Row(
                      children: [
                        Icon(style.badgeIcon, color: style.accent, size: 12),
                        const SizedBox(width: 4),
                        Text(
                          badge,
                          style: TextStyleCustom.outFitSemiBold600(
                            color: style.accent,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                Text(
                  name.isEmpty ? LKey.coins.tr : name,
                  style: TextStyleCustom.outFitMedium500(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
                Row(
                  children: [
                    Image.asset(AssetRes.icCoin, width: 14, height: 14),
                    const SizedBox(width: 4),
                    Text(
                      plan.coin.numberFormat,
                      style: TextStyleCustom.unboundedBold700(
                        color: Colors.white,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
                Text(
                  price,
                  style: TextStyleCustom.outFitRegular400(
                    color: Colors.white54,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onBuy,
              borderRadius: BorderRadius.circular(22),
              child: Ink(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: style.button,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: style.button.withValues(alpha: 0.5),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      LKey.recharge.tr,
                      style: TextStyleCustom.outFitSemiBold600(
                        color: Colors.white,
                        fontSize: 13,
                      ),
                    ),
                    const Icon(Icons.chevron_right,
                        color: Colors.white, size: 18),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
