import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krimson/common/manager/session_manager.dart';
import 'package:krimson/common/service/api/user_service.dart';
import 'package:krimson/common/widget/custom_app_bar.dart';
import 'package:krimson/common/widget/text_button_custom.dart';
import 'package:krimson/languages/languages_keys.dart';
import 'package:krimson/model/user_model/user_model.dart';
import 'package:krimson/utilities/asset_res.dart';
import 'package:krimson/utilities/color_res.dart';
import 'package:krimson/utilities/style_res.dart';
import 'package:krimson/utilities/text_style_custom.dart';
import 'package:krimson/utilities/theme_res.dart';

class SubscriptionScreen extends StatefulWidget {
  final Function(User? user)? onUpdateUser;

  const SubscriptionScreen({super.key, this.onUpdateUser});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  bool loading = false;
  String? errorText;

  @override
  Widget build(BuildContext context) {
    final settings = SessionManager.instance.getSettings();
    final enabled = (settings?.plusMembershipEnabled ?? 1) == 1;
    final priceUsd = settings?.plusMembershipPrice ?? 9.99;
    final coinValue = settings?.coinValue ?? 0.02;
    final currency = settings?.currency ?? '\$';
    final coinsNeeded =
        coinValue > 0 ? (priceUsd / coinValue).ceil().clamp(1, 999999999) : 0;
    final wallet = SessionManager.instance.getUser()?.coinWallet ?? 0;
    final alreadyPlus = SessionManager.instance.getUser()?.isVerify == 1;

    return Scaffold(
      backgroundColor: whitePure(context),
      body: Column(
        children: [
          CustomAppBar(title: LKey.plus.tr),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: StyleRes.themeGradient,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Image.asset(AssetRes.icPro, width: 48, height: 48),
                        const SizedBox(height: 12),
                        Text(
                          alreadyPlus
                              ? '${LKey.youAre.tr} ${LKey.plus.tr} ${LKey.member.tr}'
                              : '${LKey.become.tr} ${LKey.plus.tr}',
                          textAlign: TextAlign.center,
                          style: TextStyleCustom.outFitMedium500(
                            color: Colors.white,
                            fontSize: 20,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          enabled
                              ? '$currency${priceUsd.toStringAsFixed(2)}'
                              : 'Unavailable',
                          style: TextStyleCustom.unboundedSemiBold600(
                            color: Colors.white,
                            fontSize: 28,
                          ),
                        ),
                        if (enabled) ...[
                          const SizedBox(height: 4),
                          Text(
                            '$coinsNeeded ${LKey.coins.tr}',
                            style: TextStyleCustom.outFitRegular400(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  _Benefit(text: 'Verified PLUS+ badge on profile'),
                  _Benefit(text: 'Exclusive membership status'),
                  _Benefit(text: 'Ad-free experience'),
                  const SizedBox(height: 12),
                  Text(
                    LKey.yourBalanceCoins.trParams(
                        {'coins': '$wallet ${LKey.coins.tr}'}),
                    style: TextStyleCustom.outFitRegular400(
                      color: textLightGrey(context),
                      fontSize: 13,
                    ),
                  ),
                  if (errorText != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      errorText!,
                      textAlign: TextAlign.center,
                      style: TextStyleCustom.outFitRegular400(
                        color: ColorRes.likeRed,
                        fontSize: 13,
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  if (alreadyPlus)
                    Text(
                      '${LKey.youAre.tr} ${LKey.plus.tr} ${LKey.member.tr}',
                      style: TextStyleCustom.outFitMedium500(
                        color: ColorRes.themeAccentSolid,
                        fontSize: 15,
                      ),
                    )
                  else if (!enabled)
                    Text(
                      'PLUS+ is currently disabled by admin',
                      style: TextStyleCustom.outFitRegular400(
                        color: textLightGrey(context),
                        fontSize: 14,
                      ),
                    )
                  else
                    TextButtonCustom(
                      onTap: loading ? () {} : () => _subscribe(coinsNeeded),
                      title: loading
                          ? '…'
                          : 'Subscribe · $currency${priceUsd.toStringAsFixed(2)}',
                      backgroundColor: ColorRes.themeAccentSolid,
                      titleColor: Colors.white,
                      horizontalMargin: 0,
                      margin: EdgeInsets.zero,
                      btnHeight: 52,
                      fontSize: 16,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _subscribe(int coinsNeeded) async {
    setState(() {
      loading = true;
      errorText = null;
    });
    try {
      final user = await UserService.instance.subscribePlus();
      widget.onUpdateUser?.call(user);
      if (!mounted) return;
      Get.back(result: true);
      Get.snackbar('PLUS+', 'Membership activated');
    } catch (e) {
      setState(() => errorText = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }
}

class _Benefit extends StatelessWidget {
  final String text;

  const _Benefit({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          const Icon(Icons.check_circle,
              color: ColorRes.themeAccentSolid, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyleCustom.outFitRegular400(
                color: textDarkGrey(context),
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
