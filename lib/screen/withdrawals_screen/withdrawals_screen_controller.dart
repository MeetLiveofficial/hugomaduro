import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krimson/common/controller/base_controller.dart';
import 'package:krimson/common/extensions/common_extension.dart';
import 'package:krimson/common/manager/session_manager.dart';
import 'package:krimson/common/service/api/gift_wallet_service.dart';
import 'package:krimson/common/widget/text_button_custom.dart';
import 'package:krimson/languages/languages_keys.dart';
import 'package:krimson/model/general/settings_model.dart';
import 'package:krimson/model/gift_wallet/withdraw_model.dart';
import 'package:krimson/screen/coin_wallet_screen/coin_wallet_screen_controller.dart';
import 'package:krimson/utilities/color_res.dart';
import 'package:krimson/utilities/text_style_custom.dart';
import 'package:krimson/utilities/theme_res.dart';

class WithdrawalsScreenController extends BaseController {
  RxList<Withdraw> withdraws = <Withdraw>[].obs;

  @override
  void onInit() {
    super.onInit();
    _fetchWithdrawals();
  }

  Future<void> refreshList() async {
    withdraws.clear();
    await _fetchWithdrawals();
  }

  Future<void> _fetchWithdrawals() async {
    if (isLoading.value) return;
    isLoading.value = true;

    List<Withdraw> items =
        await GiftWalletService.instance.fetchMyWithdrawalRequest(
      lastItemId: withdraws.isEmpty ? null : withdraws.last.id?.toInt(),
    );

    if (items.isNotEmpty) {
      withdraws.addAll(items);
    }
    isLoading.value = false;
  }

  Future<void> openRequestSheet() async {
    final ok = await Get.bottomSheet<bool>(
      const RequestWithdrawalSheet(),
      isScrollControlled: true,
    );
    if (ok == true) {
      await refreshList();
      if (Get.isRegistered<CoinWalletScreenController>()) {
        final wallet = Get.find<CoinWalletScreenController>();
        wallet.myUser.value = SessionManager.instance.getUser();
        wallet.myUser.refresh();
      }
    }
  }
}

class RequestWithdrawalSheet extends StatefulWidget {
  const RequestWithdrawalSheet({super.key});

  @override
  State<RequestWithdrawalSheet> createState() => _RequestWithdrawalSheetState();
}

class _RequestWithdrawalSheetState extends State<RequestWithdrawalSheet> {
  final coinsCtrl = TextEditingController();
  final accountCtrl = TextEditingController();
  final settings = SessionManager.instance.getSettings();
  late final List<RedeemGateway> gateways =
      settings?.redeemGateways ?? const <RedeemGateway>[];
  RedeemGateway? selectedGateway;
  bool submitting = false;
  String? errorText;

  double get coinValue => settings?.coinValue ?? 0;
  double get minUsd => settings?.minWithdrawUsd ?? 20;
  int get minCoins => settings?.minRedeemCoins ?? 0;
  int get walletCoins =>
      (SessionManager.instance.getUser()?.coinWallet ?? 0).toInt();
  String get currency => settings?.currency ?? '\$';

  int get coinsEntered => int.tryParse(coinsCtrl.text.trim()) ?? 0;
  double get usdAmount => coinsEntered * coinValue;

  int get minCoinsForUsd {
    if (coinValue <= 0) return minCoins;
    final needed = (minUsd / coinValue).ceil();
    return needed > minCoins ? needed : minCoins;
  }

  @override
  void initState() {
    super.initState();
    if (gateways.isNotEmpty) selectedGateway = gateways.first;
  }

  @override
  void dispose() {
    coinsCtrl.dispose();
    accountCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => errorText = null);
    if (selectedGateway == null) {
      setState(() => errorText = LKey.redeemGatewayNotFound.tr);
      return;
    }
    if (coinsEntered <= 0) {
      setState(() => errorText = 'Enter coins to withdraw');
      return;
    }
    if (coinsEntered < minCoinsForUsd) {
      setState(() {
        errorText =
            'Minimum is $currency${minUsd.toStringAsFixed(2)} '
            '($minCoinsForUsd coins)';
      });
      return;
    }
    if (usdAmount < minUsd) {
      setState(() {
        errorText =
            'Minimum withdrawal is $currency${minUsd.toStringAsFixed(2)}';
      });
      return;
    }
    if (coinsEntered > walletCoins) {
      setState(() => errorText = 'Insufficient coins');
      return;
    }
    final account = accountCtrl.text.trim();
    if (account.isEmpty) {
      setState(() => errorText = LKey.accountDetails.tr);
      return;
    }

    setState(() => submitting = true);
    try {
      final res = await GiftWalletService.instance.submitWithdrawalRequest(
        coins: '$coinsEntered',
        gateway: selectedGateway!.title ?? '',
        account: account,
      );
      if (res.status == true) {
        final user = SessionManager.instance.getUser();
        if (user != null) {
          user.coinWallet = (user.coinWallet ?? 0) - coinsEntered;
          SessionManager.instance.setUser(user);
        }
        Get.back(result: true);
        Get.snackbar('OK', res.message ?? 'Withdrawal submitted');
      } else {
        setState(() => errorText = res.message ?? 'Failed');
      }
    } catch (e) {
      setState(() => errorText = e.toString());
    } finally {
      if (mounted) setState(() => submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 16,
      ),
      decoration: BoxDecoration(
        color: whitePure(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: bgGrey(context),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              Text(
                LKey.requestWithdrawal.tr,
                style: TextStyleCustom.outFitMedium500(
                  color: textDarkGrey(context),
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Min. $currency${minUsd.toStringAsFixed(2)} · '
                'Balance: ${walletCoins.numberFormat} coins '
                '($currency${(walletCoins * coinValue).toStringAsFixed(2)})',
                style: TextStyleCustom.outFitRegular400(
                  color: textLightGrey(context),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 14),
              Text('Gateway',
                  style: TextStyleCustom.outFitMedium500(
                      color: textDarkGrey(context), fontSize: 13)),
              const SizedBox(height: 6),
              DropdownButtonFormField<RedeemGateway>(
                // ignore: deprecated_member_use
                value: selectedGateway,
                items: gateways
                    .map((g) => DropdownMenuItem(
                          value: g,
                          child: Text(g.title ?? ''),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => selectedGateway = v),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: bgLightGrey(context),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(LKey.accountDetails.tr,
                  style: TextStyleCustom.outFitMedium500(
                      color: textDarkGrey(context), fontSize: 13)),
              const SizedBox(height: 6),
              TextField(
                controller: accountCtrl,
                decoration: InputDecoration(
                  hintText: 'Email / account ID',
                  filled: true,
                  fillColor: bgLightGrey(context),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(LKey.coins.tr,
                  style: TextStyleCustom.outFitMedium500(
                      color: textDarkGrey(context), fontSize: 13)),
              const SizedBox(height: 6),
              TextField(
                controller: coinsCtrl,
                keyboardType: TextInputType.number,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Min $minCoinsForUsd coins',
                  filled: true,
                  fillColor: bgLightGrey(context),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  suffixText: '$currency${usdAmount.toStringAsFixed(2)}',
                ),
              ),
              if (errorText != null) ...[
                const SizedBox(height: 8),
                Text(
                  errorText!,
                  style: TextStyleCustom.outFitRegular400(
                    color: ColorRes.likeRed,
                    fontSize: 12,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              TextButtonCustom(
                onTap: submitting ? () {} : _submit,
                title: submitting ? '…' : LKey.requestWithdrawal.tr,
                backgroundColor: ColorRes.themeAccentSolid,
                titleColor: Colors.white,
                horizontalMargin: 0,
                margin: EdgeInsets.zero,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
