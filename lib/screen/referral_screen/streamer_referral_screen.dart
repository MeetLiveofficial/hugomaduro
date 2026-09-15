import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krimson/common/widget/custom_app_bar.dart';
import 'package:krimson/common/widget/text_button_custom.dart';
import 'package:krimson/languages/languages_keys.dart';
import 'package:krimson/screen/referral_screen/streamer_referral_controller.dart';
import 'package:krimson/utilities/color_res.dart';
import 'package:krimson/utilities/text_style_custom.dart';

class StreamerReferralScreen extends StatelessWidget {
  const StreamerReferralScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(StreamerReferralController());
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          CustomAppBar(title: LKey.referrals.tr),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value &&
                  controller.data.value.code.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }
              final d = controller.data.value;
              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                children: [
                  Text(
                    LKey.referralInviteHint.trParams({
                      'percent': d.percent.toStringAsFixed(
                          d.percent == d.percent.roundToDouble() ? 0 : 2),
                    }),
                    style: TextStyleCustom.outFitRegular400(
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      d.code.isEmpty ? '—' : d.code,
                      textAlign: TextAlign.center,
                      style: TextStyleCustom.unboundedBlack900(
                        color: ColorRes.accentPeach,
                        fontSize: 22,
                      ).copyWith(letterSpacing: 3),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextButtonCustom(
                          title: LKey.copyAgencyCode.tr,
                          onTap: controller.copyCode,
                          horizontalMargin: 0,
                          btnHeight: 46,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextButtonCustom(
                          title: LKey.copyInviteLink.tr,
                          onTap: controller.copyLink,
                          horizontalMargin: 0,
                          btnHeight: 46,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextButtonCustom(
                    title: LKey.share.tr,
                    onTap: controller.shareLink,
                    gradient: true,
                    forceStreamerPalette: true,
                    horizontalMargin: 0,
                    titleColor: ColorRes.whitePure,
                    btnHeight: 48,
                  ),
                  const SizedBox(height: 22),
                  _StatRow(
                    label: LKey.referralClients.tr,
                    value: '${d.referredCount}',
                  ),
                  _StatRow(
                    label: LKey.referralPaid.tr,
                    value: '${d.rewardedCount}',
                  ),
                  _StatRow(
                    label: LKey.referralCoinsEarned.tr,
                    value: '${d.rewardCoins}',
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyleCustom.outFitRegular400(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyleCustom.outFitSemiBold600(
              color: Colors.white,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}
