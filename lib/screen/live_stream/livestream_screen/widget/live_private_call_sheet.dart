import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krimson/common/extensions/string_extension.dart';
import 'package:krimson/common/manager/coin_gate.dart';
import 'package:krimson/common/manager/session_manager.dart';
import 'package:krimson/common/widget/custom_image.dart';
import 'package:krimson/common/widget/text_button_custom.dart';
import 'package:krimson/languages/languages_keys.dart';
import 'package:krimson/model/livestream/app_user.dart';
import 'package:krimson/utilities/asset_res.dart';
import 'package:krimson/utilities/color_res.dart';
import 'package:krimson/utilities/text_style_custom.dart';
import 'package:krimson/utilities/theme_res.dart';

/// Confirmación de videochat privado desde LIVE.
class LivePrivateCallSheet extends StatelessWidget {
  final AppUser host;
  final int cost;
  final VoidCallback onConfirm;

  const LivePrivateCallSheet({
    super.key,
    required this.host,
    required this.cost,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final me = SessionManager.instance.getUser();
    final wallet = (me?.coinWallet ?? 0).toInt();

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF2A1030), Color(0xFF120818)],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CustomImage(
                  size: const Size(64, 64),
                  image: host.profile?.addBaseURL(),
                  fullName: host.fullname ?? host.username,
                  strokeWidth: 0,
                ),
                const SizedBox(width: 8),
                Icon(Icons.favorite, color: ColorRes.themeAccentSolid, size: 28),
                const SizedBox(width: 8),
                CustomImage(
                  size: const Size(64, 64),
                  image: me?.profilePhoto?.addBaseURL(),
                  fullName: me?.fullname ?? me?.username,
                  strokeWidth: 0,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Videochat solo para ti',
              textAlign: TextAlign.center,
              style: TextStyleCustom.outFitMedium500(
                color: Colors.white,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              cost > 0
                  ? LKey.callRequestCost.trParams({'coins': '$cost'})
                  : LKey.sendCallRequest.tr,
              textAlign: TextAlign.center,
              style: TextStyleCustom.outFitRegular400(
                color: Colors.white70,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Image.asset(AssetRes.icCoin, width: 22, height: 22),
                const SizedBox(width: 6),
                Text(
                  '$wallet',
                  style: TextStyleCustom.unboundedSemiBold600(
                    color: Colors.white,
                    fontSize: 18,
                  ),
                ),
                const Spacer(),
                Expanded(
                  flex: 2,
                  child: TextButtonCustom(
                    onTap: () {
                      if (!CoinGate.ensureEnough(cost)) return;
                      Get.back(result: true);
                      onConfirm();
                    },
                    title: '¡Empezar ahora!',
                    backgroundColor: const Color(0xFFFF8A00),
                    titleColor: Colors.white,
                    btnHeight: 48,
                    horizontalMargin: 0,
                    margin: EdgeInsets.zero,
                    radius: 28,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.videocam, color: Colors.white, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          '¡Empezar ahora!',
                          style: TextStyleCustom.outFitMedium500(
                            color: Colors.white,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
