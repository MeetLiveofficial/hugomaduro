import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krimson/common/manager/coin_gate.dart';
import 'package:krimson/languages/languages_keys.dart';
import 'package:krimson/utilities/client_colors.dart';
import 'package:krimson/utilities/text_style_custom.dart';

/// Tras colgar un Match por saldo: mensaje + recarga. La room ya está cerrada.
class MatchRechargeDialog {
  MatchRechargeDialog._();

  static Future<bool> show({
    CallParty? peer,
    int callCost = 0,
    List<MatchTier>? tiers,
    int graceSeconds = 10,
    DateTime? graceEndsAt,
    bool autoCloseOnTimeout = true,
    String? subtitle,
    int privateMinuteCoins = 0,
    Future<bool> Function(MatchTier tier)? onExtend,
  }) async {
    if (peer?.id == null) return false;
    final settings = SessionManager.instance.getSettings();
    final resolvedTiers = privateMinuteCoins > 0
        ? [
            MatchTier(
              tier: 1,
              seconds: 60,
              coins: privateMinuteCoins,
            )
          ]
        : ((tiers != null && tiers.isNotEmpty)
            ? tiers
            : (settings?.matchTiers ?? MatchTier.defaults));
    final resolvedGrace = graceSeconds > 0
        ? graceSeconds
        : (settings?.matchGraceSeconds ?? 10);

    final result = await Get.dialog<bool>(
      _MatchContinueBody(
        peer: peer!,
        callCost: callCost,
        tiers: resolvedTiers,
        graceSeconds: resolvedGrace,
        graceEndsAt: graceEndsAt,
        autoCloseOnTimeout: autoCloseOnTimeout,
        subtitle: subtitle,
        onExtend: onExtend,
      ),
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.78),
    );
    if (recharge == true) {
      CoinGate.openCoinShopSheet();
    }
  }
}

class _MatchOutOfCoinsBody extends StatelessWidget {
  const _MatchOutOfCoinsBody();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: ClientColors.surfaceDark,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 24, 22, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              LKey.matchOutOfCoins.tr,
              textAlign: TextAlign.center,
              style: TextStyleCustom.outFitMedium500(
                color: ClientColors.textOnDark,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: ClientColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () => Get.back(result: true),
                child: Text(
                  LKey.rechargeCoins.tr,
                  style: TextStyleCustom.outFitSemiBold600(
                    color: Colors.white,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
            TextButton(
              onPressed: () => Get.back(result: false),
              child: Text(
                LKey.cancel.tr,
                style: TextStyleCustom.outFitMedium500(
                  color: ClientColors.textOnDarkMuted,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
