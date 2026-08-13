import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krimson/common/widget/gift_media.dart';
import 'package:krimson/languages/languages_keys.dart';
import 'package:krimson/model/general/settings_model.dart';
import 'package:krimson/model/livestream/livestream.dart';
import 'package:krimson/utilities/color_res.dart';
import 'package:krimson/utilities/text_style_custom.dart';

/// Host: lista de regalos (configurados o catálogo) para incentivar.
class LiveGiftBoostSheet extends StatelessWidget {
  const LiveGiftBoostSheet({
    super.key,
    required this.gifts,
    required this.onBoost,
    this.incentives = const [],
  });

  final List<Gift> gifts;
  final ValueChanged<Gift?> onBoost;
  final List<LiveGiftIncentive> incentives;

  LiveGiftIncentive? _incentiveFor(Gift g) {
    return incentives.firstWhereOrNull((e) => e.giftId == g.id);
  }

  @override
  Widget build(BuildContext context) {
    final hasConfigured = incentives.isNotEmpty;
    return Container(
      height: MediaQuery.sizeOf(context).height * 0.55,
      decoration: const BoxDecoration(
        color: Color(0xFF160E1C),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      LKey.boostGifts.tr,
                      style: TextStyleCustom.outFitMedium500(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: Get.back,
                    icon: const Icon(Icons.close, color: Colors.white54),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                hasConfigured
                    ? 'Toca un regalo configurado para pedirlo a la audiencia.'
                    : 'Elige un regalo activo o invita a regalar en general.',
                style: TextStyleCustom.outFitRegular400(
                  color: Colors.white60,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.fromLTRB(14, 4, 14, 12),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 0.72,
                ),
                itemCount: gifts.length,
                itemBuilder: (context, index) {
                  final g = gifts[index];
                  final incentive = _incentiveFor(g);
                  final msg = (incentive?.trimmedMessage ?? '').trim();
                  return InkWell(
                    onTap: () => onBoost(g),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white12),
                      ),
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        children: [
                          Expanded(
                            child: GiftMedia(
                              path: g.image,
                              width: 52,
                              height: 52,
                              fit: BoxFit.contain,
                              muted: true,
                              looping: true,
                              placeholder: const Icon(
                                Icons.card_giftcard,
                                color: Colors.white54,
                              ),
                            ),
                          ),
                          Text(
                            '${g.coinPrice ?? 0}',
                            style: TextStyleCustom.outFitMedium500(
                              color: ColorRes.accentPeach,
                              fontSize: 12,
                            ),
                          ),
                          if (msg.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              msg,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: TextStyleCustom.outFitRegular400(
                                color: Colors.white70,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            if (!hasConfigured)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    onPressed: () => onBoost(null),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ColorRes.themeAccentSolid,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    child: Text(
                      LKey.sendMeGifts.tr,
                      style: TextStyleCustom.outFitMedium500(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              )
            else
              const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
