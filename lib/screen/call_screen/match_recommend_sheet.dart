import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krimson/common/extensions/string_extension.dart';
import 'package:krimson/common/manager/coin_gate.dart';
import 'package:krimson/common/widget/custom_image.dart';
import 'package:krimson/common/service/api/call_service.dart';
import 'package:krimson/screen/call_screen/outgoing_call_screen.dart';
import 'package:krimson/utilities/color_res.dart';
import 'package:krimson/utilities/text_style_custom.dart';

/// Sheet: streamer recomendada por Match → llamar.
class MatchRecommendSheet {
  MatchRecommendSheet._();

  static Future<void> show(MatchRecommendation match) async {
    await Get.bottomSheet(
      _MatchRecommendBody(match: match),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }
}

class _MatchRecommendBody extends StatelessWidget {
  const _MatchRecommendBody({required this.match});

  final MatchRecommendation match;

  @override
  Widget build(BuildContext context) {
    final user = match.user;
    final name = (user.fullname ?? user.username ?? 'Streamer').trim();
    final lang = (match.appLanguage ?? user.appLanguage ?? '').trim();
    final seconds = match.matchFreeSeconds > 0 ? match.matchFreeSeconds : 30;
    final cost = match.callCost;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1224),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: ColorRes.mauve.withValues(alpha: 0.45),
        ),
        boxShadow: [
          BoxShadow(
            color: ColorRes.mauve.withValues(alpha: 0.25),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Match encontrado',
              style: TextStyleCustom.outFitMedium500(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 14),
            CustomImage(
              size: const Size(88, 88),
              image: user.profilePhoto?.addBaseURL(),
              fullName: name,
              radius: 44,
              strokeWidth: 2,
              strokeColor: ColorRes.themeAccentSolid,
            ),
            const SizedBox(height: 12),
            Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyleCustom.outFitMedium500(
                color: Colors.white,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              lang.isEmpty
                  ? 'Preview Match · $seconds s'
                  : 'Idioma: $lang · Preview $seconds s',
              style: TextStyleCustom.outFitRegular400(
                color: Colors.white70,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              cost > 0 ? '$cost coins / llamada' : 'Llamada sin costo',
              style: TextStyleCustom.outFitMedium500(
                color: ColorRes.accentPeach,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: Get.back,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white70,
                      side: const BorderSide(color: Colors.white24),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    child: Text(
                      'Cancelar',
                      style: TextStyleCustom.outFitMedium500(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      if (cost > 0 &&
                          !CoinGate.ensureEnough(
                            cost,
                            message: 'Moneda insuficiente para Match',
                          )) {
                        return;
                      }
                      Get.back();
                      Get.to(
                        () => OutgoingCallScreen(
                          callee: user,
                          cost: cost,
                          isMatch: true,
                          matchFreeSeconds: seconds,
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ColorRes.themeAccentSolid,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    icon: const Icon(Icons.videocam_rounded, size: 18),
                    label: Text(
                      'Llamar',
                      style: TextStyleCustom.outFitMedium500(
                        color: Colors.white,
                        fontSize: 14,
                      ),
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
