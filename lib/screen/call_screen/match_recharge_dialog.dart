import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krimson/common/extensions/string_extension.dart';
import 'package:krimson/common/manager/coin_gate.dart';
import 'package:krimson/common/manager/session_manager.dart';
import 'package:krimson/common/widget/custom_image.dart';
import 'package:krimson/model/call/call_request_model.dart';
import 'package:krimson/model/general/settings_model.dart';
import 'package:krimson/screen/coin_wallet_screen/coin_wallet_screen_controller.dart';
import 'package:krimson/utilities/color_res.dart';
import 'package:krimson/utilities/text_style_custom.dart';

/// Modal post-Match: recargar coins para volver a llamar.
class MatchRechargeDialog {
  MatchRechargeDialog._();

  static Future<void> show({
    CallParty? peer,
    int callCost = 0,
  }) async {
    if (!Get.isRegistered<CoinWalletScreenController>()) {
      Get.put(CoinWalletScreenController());
    } else {
      final c = Get.find<CoinWalletScreenController>();
      c.fetchData();
      c.fetchOfferings();
    }

    await Get.dialog(
      _MatchRechargeBody(peer: peer, callCost: callCost),
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.72),
    );
  }
}

class _MatchRechargeBody extends StatelessWidget {
  const _MatchRechargeBody({this.peer, this.callCost = 0});

  final CallParty? peer;
  final int callCost;

  @override
  Widget build(BuildContext context) {
    final name = (peer?.fullname ?? peer?.username ?? 'Streamer').trim();
    final packages = (SessionManager.instance.getSettings()?.coinPackages ?? [])
        .where((p) => (p.status ?? 0) == 1)
        .toList();
    final shown = packages.take(3).toList();
    final walletCtrl = Get.find<CoinWalletScreenController>();

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 18),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF6B2D8B), Color(0xFF3D1A55)],
          ),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.18),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.topRight,
              child: IconButton(
                onPressed: Get.back,
                icon: const Icon(Icons.close, color: Colors.white70, size: 20),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
            ),
            CustomImage(
              size: const Size(72, 72),
              image: peer?.profilePhoto?.addBaseURL(),
              fullName: name,
              radius: 36,
              strokeWidth: 2,
              strokeColor: ColorRes.accentPeach,
            ),
            const SizedBox(height: 10),
            Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyleCustom.outFitMedium500(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '¿Te gusta?',
              style: TextStyleCustom.outFitMedium500(
                color: const Color(0xFFFFD6F0),
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              callCost > 0
                  ? '¡Recarga y vuelve a llamar! · $callCost coins/Match'
                  : '¡Recarga y vuelve a llamar!',
              textAlign: TextAlign.center,
              style: TextStyleCustom.outFitRegular400(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Expanded(child: Divider(color: Colors.white24)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Text(
                    'Recargar',
                    style: TextStyleCustom.outFitMedium500(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ),
                const Expanded(child: Divider(color: Colors.white24)),
              ],
            ),
            const SizedBox(height: 12),
            if (shown.isEmpty)
              Text(
                'No hay paquetes disponibles',
                style: TextStyleCustom.outFitRegular400(
                  color: Colors.white60,
                  fontSize: 13,
                ),
              )
            else
              SizedBox(
                height: 150,
                child: Row(
                  children: [
                    for (var i = 0; i < shown.length; i++) ...[
                      if (i > 0) const SizedBox(width: 8),
                      Expanded(
                        child: _PackageCard(
                          package: shown[i],
                          onTap: () {
                            walletCtrl.fetchOfferings();
                            CoinPlan? plan;
                            for (final p in walletCtrl.coinPlans) {
                              if (p.coinPackageId == shown[i].id) {
                                plan = p;
                                break;
                              }
                            }
                            if (plan != null) {
                              walletCtrl.onPurchase(plan);
                            } else {
                              Get.back();
                              CoinGate.openCoinShopSheet();
                            }
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            const SizedBox(height: 4),
            TextButton(
              onPressed: () {
                Get.back();
                CoinGate.openCoinShopSheet();
              },
              child: Text(
                'Ver más paquetes',
                style: TextStyleCustom.outFitMedium500(
                  color: ColorRes.accentPeach,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PackageCard extends StatelessWidget {
  const _PackageCard({required this.package, required this.onTap});

  final CoinPackage package;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final coins = package.coinAmount ?? 0;
    final price = package.coinPlanPrice ?? 0;
    final priceLabel = price % 1 == 0
        ? '\$${price.toInt()}'
        : '\$${price.toStringAsFixed(2)}';

    return Material(
      color: Colors.white.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$coins',
                style: TextStyleCustom.outFitMedium500(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'coins',
                style: TextStyleCustom.outFitRegular400(
                  color: Colors.white60,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 8),
              const Icon(Icons.diamond_rounded,
                  color: Color(0xFFFF7EB6), size: 22),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF4FA3),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  priceLabel,
                  textAlign: TextAlign.center,
                  style: TextStyleCustom.outFitMedium500(
                    color: Colors.white,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
