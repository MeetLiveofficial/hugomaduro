import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krimson/common/manager/app_role.dart';
import 'package:krimson/common/manager/session_manager.dart';
import 'package:krimson/common/service/api/user_service.dart';
import 'package:krimson/common/widget/custom_app_bar.dart';
import 'package:krimson/common/widget/text_button_custom.dart';
import 'package:krimson/languages/languages_keys.dart';
import 'package:krimson/model/user_model/user_model.dart';
import 'package:krimson/utilities/asset_res.dart';
import 'package:krimson/utilities/client_colors.dart';
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
  static const _gold = Color(0xFFD4AF37);

  bool loading = false;
  String? errorText;

  @override
  Widget build(BuildContext context) {
    final client = AppRole.isClient();
    final settings = SessionManager.instance.getSettings();
    final enabled = (settings?.plusMembershipEnabled ?? 1) == 1;
    final priceUsd = settings?.plusMembershipPrice ?? 9.99;
    final coinValue = settings?.coinValue ?? 0.02;
    final currency = settings?.currency ?? '\$';
    final coinsNeeded =
        coinValue > 0 ? (priceUsd / coinValue).ceil().clamp(1, 999999999) : 0;
    final alreadyPlus = SessionManager.instance.getUser()?.isVerify == 1;
    final bg = client ? ClientColors.bg : ColorRes.whitePure;
    final onBody = client ? ClientColors.textOnDark : ColorRes.textDarkGrey;
    final onMuted = client ? ClientColors.textOnDarkMuted : ColorRes.textLightGrey;
    final cardBg = client ? ClientColors.surfaceDarkAlt : ColorRes.bgLightGrey;

    return ThemeRes.applyIfClient(
      context,
      Scaffold(
        backgroundColor: bg,
        body: Column(
          children: [
            CustomAppBar(title: LKey.plus.tr),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _HeroCard(
                      alreadyPlus: alreadyPlus,
                      enabled: enabled,
                      currency: currency,
                      priceUsd: priceUsd,
                      coinsNeeded: coinsNeeded,
                    ),
                    const SizedBox(height: 22),
                    Text(
                      alreadyPlus
                          ? LKey.plusIncludedPerks.tr
                          : LKey.membership.tr,
                      style: TextStyleCustom.outFitSemiBold600(
                        color: onBody,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: client
                              ? _gold.withValues(alpha: 0.28)
                              : ColorRes.bgGrey,
                        ),
                      ),
                      child: Column(
                        children: [
                          _Benefit(
                            text: LKey.plusBenefitBadge.tr,
                            color: onBody,
                            accent: _gold,
                          ),
                          _Benefit(
                            text: LKey.plusBenefitStatus.tr,
                            color: onBody,
                            accent: _gold,
                          ),
                          _Benefit(
                            text: LKey.plusBenefitAdFree.tr,
                            color: onBody,
                            accent: _gold,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Obx(() {
                      final wallet =
                          SessionManager.instance.coinWalletRx.value;
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            Image.asset(AssetRes.icStar, width: 18, height: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                LKey.yourBalanceCoins.trParams(
                                    {'coins': '$wallet ${LKey.coins.tr}'}),
                                style: TextStyleCustom.outFitMedium500(
                                  color: onMuted,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    if (errorText != null) ...[
                      const SizedBox(height: 12),
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
                    if (!alreadyPlus && !enabled)
                      Text(
                        LKey.plusDisabledAdmin.tr,
                        textAlign: TextAlign.center,
                        style: TextStyleCustom.outFitRegular400(
                          color: onMuted,
                          fontSize: 14,
                        ),
                      )
                    else if (!alreadyPlus && enabled)
                      TextButtonCustom(
                        onTap: loading ? () {} : () => _subscribe(coinsNeeded),
                        title: loading
                            ? '…'
                            : '${LKey.plusSubscribeCta.tr} · $currency${priceUsd.toStringAsFixed(2)}',
                        backgroundColor: ClientColors.primary,
                        titleColor: Colors.white,
                        horizontalMargin: 0,
                        margin: EdgeInsets.zero,
                        btnHeight: 52,
                        fontSize: 16,
                        gradient: true,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
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
      if (user != null) {
        SessionManager.instance.setUser(user);
        SessionManager.instance.applyCoinWallet(user.coinWallet?.toInt());
      }
      if (!mounted) return;
      Get.back(result: true);
      Get.snackbar(LKey.plus.tr, LKey.plusActiveBadge.tr);
    } catch (e) {
      setState(() => errorText = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.alreadyPlus,
    required this.enabled,
    required this.currency,
    required this.priceUsd,
    required this.coinsNeeded,
  });

  final bool alreadyPlus;
  final bool enabled;
  final String currency;
  final double priceUsd;
  final int coinsNeeded;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
      decoration: BoxDecoration(
        gradient: StyleRes.themeGradient,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFE8D48B).withValues(alpha: 0.55),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: ClientColors.primary.withValues(alpha: 0.28),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Image.asset(AssetRes.icPro, width: 52, height: 52),
          const SizedBox(height: 12),
          Text(
            alreadyPlus ? LKey.plusYouAreMember.tr : LKey.plusBecomeTitle.tr,
            textAlign: TextAlign.center,
            style: TextStyleCustom.outFitSemiBold600(
              color: Colors.white,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 10),
          if (alreadyPlus)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                LKey.plusActiveBadge.tr,
                style: TextStyleCustom.outFitMedium500(
                  color: const Color(0xFFE8D48B),
                  fontSize: 13,
                ),
              ),
            )
          else ...[
            Text(
              enabled
                  ? '$currency${priceUsd.toStringAsFixed(2)}'
                  : LKey.plusDisabledAdmin.tr,
              style: TextStyleCustom.unboundedSemiBold600(
                color: Colors.white,
                fontSize: 28,
              ),
            ),
            if (enabled) ...[
              const SizedBox(height: 6),
              Text(
                '$coinsNeeded ${LKey.coins.tr}',
                style: TextStyleCustom.outFitRegular400(
                  color: Colors.white.withValues(alpha: 0.82),
                  fontSize: 14,
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _Benefit extends StatelessWidget {
  final String text;
  final Color color;
  final Color accent;

  const _Benefit({
    required this.text,
    required this.color,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle_rounded, color: accent, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyleCustom.outFitRegular400(
                color: color,
                fontSize: 15,
              ).copyWith(height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}
