import 'package:figma_squircle_updated/figma_squircle.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krimson/common/extensions/common_extension.dart';
import 'package:krimson/common/manager/session_manager.dart';
import 'package:krimson/common/widget/gradient_border.dart';
import 'package:krimson/common/widget/gradient_text.dart';
import 'package:krimson/languages/languages_keys.dart';
import 'package:krimson/model/general/settings_model.dart';
import 'package:krimson/utilities/asset_res.dart';
import 'package:krimson/utilities/style_res.dart';
import 'package:krimson/utilities/text_style_custom.dart';
import 'package:krimson/utilities/theme_res.dart';

class LevelScreen extends StatelessWidget {
  final UserLevel? userLevels;

  const LevelScreen({super.key, this.userLevels});

  @override
  Widget build(BuildContext context) {
    List<UserLevel> levels =
        SessionManager.instance.getSettings()?.userLevels ?? [];
    levels = [...levels]
      ..sort((a, b) => a.coinsCollection.compareTo(b.coinsCollection));
    final current = userLevels ?? SessionManager.instance.getUser()?.getLevel;

    return Scaffold(
      body: Column(
        children: [
          Container(
            decoration: BoxDecoration(gradient: StyleRes.themeGradient),
            child: SafeArea(
                bottom: false,
                child: Column(
                  children: [
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: InkWell(
                        onTap: Get.back,
                        child: Padding(
                          padding: const EdgeInsets.only(
                              left: 20.0, right: 20.0, top: 10),
                          child: Icon(Icons.arrow_back,
                              color: whitePure(context)),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(
                          left: 32, right: 32, bottom: 20),
                      child: Column(
                        children: [
                          Text(
                            LKey.myLevel.tr.toUpperCase(),
                            style: TextStyleCustom.unboundedExtraBold800(
                                fontSize: 36, color: whitePure(context)),
                          ),
                          if ((current?.title ?? '').isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              current!.title!,
                              style: TextStyleCustom.outFitMedium500(
                                  fontSize: 16, color: whitePure(context)),
                            ),
                          ],
                          const SizedBox(height: 10),
                          Text(
                            LKey.gatherMoreCoins.tr,
                            style: TextStyleCustom.outFitRegular400(
                                fontSize: 15, color: whitePure(context)),
                            textAlign: TextAlign.center,
                          ),
                          if ((current?.benefits ?? []).isNotEmpty) ...[
                            const SizedBox(height: 14),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: whitePure(context).withValues(alpha: .15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(LKey.benefits.tr,
                                      style: TextStyleCustom.outFitMedium500(
                                          color: whitePure(context),
                                          fontSize: 14)),
                                  const SizedBox(height: 6),
                                  ...current!.benefits.map(
                                    (b) => Padding(
                                      padding: const EdgeInsets.only(bottom: 4),
                                      child: Text('• $b',
                                          style:
                                              TextStyleCustom.outFitRegular400(
                                                  color: whitePure(context),
                                                  fontSize: 13)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    )
                  ],
                )),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 25.0, right: 25.0, top: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(LKey.level.tr,
                    style: TextStyleCustom.outFitRegular400(
                        color: textLightGrey(context), fontSize: 15)),
                Text(LKey.collection.tr,
                    style: TextStyleCustom.outFitRegular400(
                        color: textLightGrey(context), fontSize: 15)),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: levels.length,
              padding: const EdgeInsets.only(bottom: 24),
              itemBuilder: (context, index) {
                UserLevel level = levels[index];
                bool isLevelCurrent = level.level == current?.level;
                return Container(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                  decoration: ShapeDecoration(
                      shape: SmoothRectangleBorder(
                          borderRadius: SmoothBorderRadius(
                              cornerRadius: 10, cornerSmoothing: 1))),
                  child: GradientBorder(
                    strokeWidth: 2,
                    radius: 10,
                    gradient: isLevelCurrent
                        ? StyleRes.themeGradient
                        : StyleRes.textLightGreyGradient(opacity: .2),
                    child: Container(
                      decoration: ShapeDecoration(
                          shape: SmoothRectangleBorder(
                              borderRadius: SmoothBorderRadius(
                                  cornerRadius: 10, cornerSmoothing: 1),
                              side: BorderSide(
                                color:
                                    textLightGrey(context).withValues(alpha: 0),
                              )),
                          color: bgLightGrey(context)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      margin: const EdgeInsets.all(2),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              GradientText(
                                'Lv ${level.level}',
                                gradient: isLevelCurrent
                                    ? StyleRes.themeGradient
                                    : StyleRes.textLightGreyGradient(),
                                style: TextStyleCustom.outFitBold700(
                                    color: textLightGrey(context),
                                    fontSize: 18),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  level.title?.isNotEmpty == true
                                      ? level.title!
                                      : '${LKey.level.tr} ${level.level}',
                                  style: TextStyleCustom.outFitMedium500(
                                      color: textDarkGrey(context),
                                      fontSize: 14),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (isLevelCurrent)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                      gradient: StyleRes.themeGradient,
                                      borderRadius: BorderRadius.circular(8)),
                                  child: Text(LKey.you.tr,
                                      style: TextStyleCustom.outFitSemiBold600(
                                          color: whitePure(context),
                                          fontSize: 12)),
                                ),
                              const SizedBox(width: 8),
                              Image.asset(AssetRes.icCoin,
                                  width: 16, height: 16),
                              const SizedBox(width: 4),
                              Text(level.coinsCollection.numberFormat,
                                  style: TextStyleCustom.outFitRegular400(
                                      fontSize: 14,
                                      color: textLightGrey(context))),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${LKey.callPrice.tr}: ${level.callRequestCoins} ${LKey.coins.tr}',
                            style: TextStyleCustom.outFitRegular400(
                                fontSize: 12, color: textLightGrey(context)),
                          ),
                          Text(
                            '${LKey.receiveCalls.tr}: ${level.canReceiveCalls == 1 ? LKey.yes.tr : LKey.no.tr}',
                            style: TextStyleCustom.outFitRegular400(
                                fontSize: 12, color: textLightGrey(context)),
                          ),
                          if (level.benefits.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            ...level.benefits.take(3).map(
                                  (b) => Text('• $b',
                                      style: TextStyleCustom.outFitLight300(
                                          fontSize: 12,
                                          color: textLightGrey(context))),
                                ),
                          ],
                        ],
                      ),
                    ),
                    onPressed: () {},
                  ),
                );
              },
            ),
          )
        ],
      ),
    );
  }
}
