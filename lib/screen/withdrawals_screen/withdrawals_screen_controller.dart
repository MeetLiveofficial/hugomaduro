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
  RxBool hasMore = true.obs;

  @override
  void onInit() {
    super.onInit();
    _fetchWithdrawals();
  }

  Future<void> refreshList() async {
    withdraws.clear();
    hasMore.value = true;
    await _fetchWithdrawals();
  }

  Future<void> loadMore() async {
    if (!hasMore.value || isLoading.value) return;
    await _fetchWithdrawals();
  }

  Future<void> _fetchWithdrawals() async {
    if (isLoading.value) return;
    isLoading.value = true;

    List<Withdraw> items =
        await GiftWalletService.instance.fetchMyWithdrawalRequest(
      lastItemId: withdraws.isEmpty ? null : withdraws.last.id?.toInt(),
    );

    if (items.isEmpty) {
      hasMore.value = false;
    } else {
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
  double get commissionPercent =>
      settings?.withdrawalCommissionPercent ?? 0;
  int get walletCoins =>
      (SessionManager.instance.getUser()?.coinWallet ?? 0).toInt();
  String get currency => settings?.currency ?? '\$';

  int get coinsEntered => int.tryParse(coinsCtrl.text.trim()) ?? 0;
  double get usdAmount => coinsEntered * coinValue;
  double get feeAmount =>
      double.parse((usdAmount * (commissionPercent / 100)).toStringAsFixed(2));
  double get netAmount =>
      double.parse((usdAmount - feeAmount).toStringAsFixed(2));

  int get minCoinsForUsd {
    if (coinValue <= 0) return minCoins;
    final needed = (minUsd / coinValue).ceil();
    return needed > minCoins ? needed : minCoins;
  }

  @override
  void initState() {
    super.initState();
    if (gateways.isNotEmpty) selectedGateway = gateways.first;
    final saved =
        SessionManager.instance.getUser()?.withdrawWalletAccount?.trim();
    if (saved != null && saved.isNotEmpty) {
      accountCtrl.text = saved;
    }
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
      setState(() => errorText = 'Ingresa las monedas a retirar');
      return;
    }
    if (coinsEntered < minCoinsForUsd) {
      setState(() {
        errorText =
            'Mínimo $currency${minUsd.toStringAsFixed(2)} '
            '($minCoinsForUsd monedas)';
      });
      return;
    }
    if (usdAmount < minUsd) {
      setState(() {
        errorText =
            'El retiro mínimo es $currency${minUsd.toStringAsFixed(2)}';
      });
      return;
    }
    if (coinsEntered > walletCoins) {
      setState(() => errorText = 'Monedas insuficientes');
      return;
    }
    final account = accountCtrl.text.trim();
    if (account.length < 3) {
      setState(() => errorText = 'Ingresa la dirección/wallet de destino');
      return;
    }
    if (netAmount <= 0) {
      setState(() => errorText = 'El monto neto a recibir debe ser mayor a 0');
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
          user.withdrawWalletAccount = account;
          SessionManager.instance.setUser(user);
        }
        Get.back(result: true);
        Get.snackbar('OK', res.message ?? 'Solicitud de retiro enviada');
      } else {
        setState(() => errorText = res.message ?? 'Error al solicitar retiro');
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
                'Mín. $currency${minUsd.toStringAsFixed(2)} · '
                'Saldo: ${walletCoins.numberFormat} monedas '
                '($currency${(walletCoins * coinValue).toStringAsFixed(2)})',
                style: TextStyleCustom.outFitRegular400(
                  color: textLightGrey(context),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 14),
              Text('Método / Gateway',
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
              Text('Wallet / cuenta de destino',
                  style: TextStyleCustom.outFitMedium500(
                      color: textDarkGrey(context), fontSize: 13)),
              const SizedBox(height: 6),
              TextField(
                controller: accountCtrl,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'Ej: dirección USDT (TRC20) o correo PayPal',
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
                  hintText: 'Mín. $minCoinsForUsd monedas',
                  filled: true,
                  fillColor: bgLightGrey(context),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              if (coinsEntered > 0) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: bgLightGrey(context),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      _MoneyRow(
                        label: 'Monto bruto',
                        value: '$currency${usdAmount.toStringAsFixed(2)}',
                        context: context,
                      ),
                      const SizedBox(height: 4),
                      _MoneyRow(
                        label:
                            'Comisión (${commissionPercent.toStringAsFixed(2)}%)',
                        value: '-$currency${feeAmount.toStringAsFixed(2)}',
                        context: context,
                        muted: true,
                      ),
                      const Divider(height: 16),
                      _MoneyRow(
                        label: 'Recibirás',
                        value: '$currency${netAmount.toStringAsFixed(2)}',
                        context: context,
                        bold: true,
                      ),
                    ],
                  ),
                ),
              ],
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

class _MoneyRow extends StatelessWidget {
  final String label;
  final String value;
  final BuildContext context;
  final bool muted;
  final bool bold;

  const _MoneyRow({
    required this.label,
    required this.value,
    required this.context,
    this.muted = false,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyleCustom.outFitRegular400(
              color: muted ? textLightGrey(context) : textDarkGrey(context),
              fontSize: 13,
            ),
          ),
        ),
        Text(
          value,
          style: bold
              ? TextStyleCustom.outFitBold700(
                  color: ColorRes.themeAccentSolid,
                  fontSize: 15,
                )
              : TextStyleCustom.outFitMedium500(
                  color: textDarkGrey(context),
                  fontSize: 13,
                ),
        ),
      ],
    );
  }
}
