import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krimson/common/extensions/common_extension.dart';
import 'package:krimson/common/widget/brand_wash_bg.dart';
import 'package:krimson/common/widget/custom_app_bar.dart';
import 'package:krimson/common/widget/custom_image.dart';
import 'package:krimson/languages/languages_keys.dart';
import 'package:krimson/model/agency/agency_dashboard_model.dart';
import 'package:krimson/utilities/asset_res.dart';
import 'package:krimson/utilities/color_res.dart';
import 'package:krimson/utilities/text_style_custom.dart';

class AgencyWorkerDetailScreen extends StatelessWidget {
  final AgencyWorker worker;

  const AgencyWorkerDetailScreen({super.key, required this.worker});

  @override
  Widget build(BuildContext context) {
    final u = worker.user;
    final s = worker.stats;
    final photo = (u.profilePhoto ?? '').trim();
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const BrandWashBg(vivid: false),
          Column(
            children: [
              CustomAppBar(
                title: u.displayName,
                subTitle: u.handle,
              ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              children: [
                Center(
                  child: CustomImage(
                    size: const Size(84, 84),
                    image: photo.isEmpty ? null : photo,
                    fullName: u.displayName,
                    radius: 42,
                  ),
                ),
                const SizedBox(height: 10),
                if ((u.weeklyCallGrade ?? '').trim().isNotEmpty)
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: ColorRes.crimson.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        u.weeklyCallGrade!.toUpperCase(),
                        style: TextStyleCustom.outFitSemiBold600(
                          color: ColorRes.accentPeach,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 18),
                _sectionTitle(LKey.agencyStreamerEarned.tr),
                _card([
                  _row(LKey.agencyToday.tr, s.streamerEarnedToday),
                  _row(LKey.agencyWeek.tr, s.streamerEarnedWeek),
                  _row(LKey.agencyMonth.tr, s.streamerEarnedMonth),
                  _row(LKey.agencyLifetime.tr, s.streamerEarnedLifetime),
                  _row(LKey.balance.tr, s.streamerWallet),
                ]),
                const SizedBox(height: 14),
                _sectionTitle(LKey.agencyYourShare.tr),
                _card([
                  _row(LKey.agencyToday.tr, s.agencyEarnedToday),
                  _row(LKey.agencyWeek.tr, s.agencyEarnedWeek),
                  _row(LKey.agencyMonth.tr, s.agencyEarnedMonth),
                  _row(LKey.agencyLifetime.tr, s.agencyEarnedLifetime),
                ]),
                const SizedBox(height: 14),
                _sectionTitle(LKey.walletFilterAll.tr),
                _card([
                  _row('LIVE', s.live),
                  _row(LKey.chats.tr, s.chat),
                  _row(LKey.walletFilterCalls.tr, s.call),
                  _row(LKey.walletFilterGifts.tr, s.gift),
                ]),
              ],
            ),
          ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        title.toUpperCase(),
        style: TextStyleCustom.outFitMedium500(
          color: ColorRes.accentPeach,
          fontSize: 12,
        ).copyWith(letterSpacing: 1.2),
      ),
    );
  }

  Widget _card(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(children: children),
    );
  }

  Widget _row(String label, int coins) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyleCustom.outFitRegular400(
                color: Colors.white70,
                fontSize: 13,
              ),
            ),
          ),
          Image.asset(AssetRes.icCoin, width: 14, height: 14),
          const SizedBox(width: 4),
          Text(
            coins.fullNumberFormat,
            style: TextStyleCustom.outFitSemiBold600(
              color: Colors.white,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
