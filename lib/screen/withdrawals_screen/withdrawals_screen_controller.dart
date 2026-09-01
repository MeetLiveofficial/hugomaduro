import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krimson/common/controller/base_controller.dart';
import 'package:krimson/common/extensions/common_extension.dart';
import 'package:krimson/common/manager/app_role.dart';
import 'package:krimson/common/manager/session_manager.dart';
import 'package:krimson/common/service/api/gift_wallet_service.dart';
import 'package:krimson/common/service/api/user_service.dart';
import 'package:krimson/common/widget/text_button_custom.dart';
import 'package:krimson/languages/languages_keys.dart';
import 'package:krimson/model/general/settings_model.dart';
import 'package:krimson/model/gift_wallet/withdraw_model.dart';
import 'package:krimson/screen/coin_wallet_screen/coin_wallet_screen_controller.dart';
import 'package:krimson/screen/kyc_screen/kyc_verification_screen.dart';
import 'package:krimson/screen/tasks_screen/tasks_screen.dart';
import 'package:krimson/utilities/color_res.dart';
import 'package:krimson/utilities/text_style_custom.dart';
import 'package:krimson/utilities/theme_res.dart';

class WithdrawalsScreenController extends BaseController {
  RxList<Withdraw> withdraws = <Withdraw>[].obs;
  RxBool hasMore = true.obs;

  Setting? get settings => SessionManager.instance.getSettings();

  double get coinValue => settings?.coinValue ?? 0;
  double get minUsd => settings?.minWithdrawUsd ?? 20;
  int get minCoins => settings?.minRedeemCoins ?? 0;
  double get globalCommission => settings?.withdrawalCommissionPercent ?? 0;
  String get currency => settings?.currency ?? '\$';
  String get infoText => (settings?.withdrawalInfoText ?? '').trim();
  int get walletCoins =>
      (SessionManager.instance.getUser()?.coinWallet ?? 0).toInt();

  List<RedeemGateway> get enabledGateways {
    final all = settings?.redeemGateways ?? const <RedeemGateway>[];
    final enabled = all.where((g) => g.isEnabled == 1).toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return enabled;
  }

  String get rateLabel {
    if (coinValue <= 0) return '—';
    final coinsPerDollar = (1 / coinValue).round();
    return '$coinsPerDollar=1$currency';
  }

  int get minCoinsForUsd {
    if (coinValue <= 0) return minCoins;
    final needed = (minUsd / coinValue).ceil();
    return needed > minCoins ? needed : minCoins;
  }

  @override
  void onInit() {
    super.onInit();
    if (!AppRole.canWithdraw()) {
      Future.microtask(() {
        if (Get.isOverlaysOpen || Get.key.currentState?.canPop() == true) {
          Get.back();
        }
        showSnackBar('Los clientes no pueden solicitar retiros');
      });
      return;
    }
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
    if ((settings?.isWithdrawalOn ?? 0) != 1) {
      showSnackBar('Los retiros están desactivados por el sistema');
      return;
    }
    if (enabledGateways.isEmpty) {
      showSnackBar(LKey.noWithdrawalMethods.tr);
      return;
    }

    // KYC una sola vez, solo al retirar (streamers).
    try {
      final fresh = await UserService.instance.fetchUserDetails(
        userId: SessionManager.instance.getUserID(),
      );
      if (AppRole.needsKycForWithdrawal(fresh)) {
        final verified = await Get.to<bool>(
          () => KycVerificationScreen(user: fresh),
          routeName: '/kyc',
        );
        if (verified != true) {
          showSnackBar('Debes verificar tu identidad para retirar');
          return;
        }
      }
    } catch (e) {
      showSnackBar('No se pudo comprobar la verificacion: $e');
      return;
    }

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

  late final List<RedeemGateway> gateways = () {
    final all = settings?.redeemGateways ?? const <RedeemGateway>[];
    final enabled = all.where((g) => g.isEnabled == 1).toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return enabled;
  }();

  RedeemGateway? selectedGateway;
  bool submitting = false;
  String? errorText;

  double get coinValue => settings?.coinValue ?? 0;
  double get minUsd => settings?.minWithdrawUsd ?? 20;
  int get minCoins => settings?.minRedeemCoins ?? 0;
  double get globalCommission => settings?.withdrawalCommissionPercent ?? 0;
  int get walletCoins =>
      (SessionManager.instance.getUser()?.coinWallet ?? 0).toInt();
  String get currency => settings?.currency ?? '\$';

  double get commissionPercent =>
      selectedGateway?.resolveCommission(globalCommission) ?? globalCommission;

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

  String get rateLabel {
    if (coinValue <= 0) return '—';
    final coinsPerDollar = (1 / coinValue).round();
    return '$coinsPerDollar=1$currency';
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
      if (res['status'] == true) {
        final user = SessionManager.instance.getUser();
        if (user != null) {
          user.coinWallet = (user.coinWallet ?? 0) - coinsEntered;
          user.withdrawWalletAccount = account;
          SessionManager.instance.setUser(user);
        }
        Get.back(result: true);
        Get.snackbar(
            'OK', res['message']?.toString() ?? 'Solicitud de retiro enviada');
      } else {
        final msg = res['message']?.toString() ?? 'Error al solicitar retiro';
        final data = res['data'];
        final errorCode = data is Map ? data['error_code']?.toString() : null;
        setState(() => errorText = msg.tr);
        if (errorCode == 'DAILY_TASKS_INCOMPLETE' ||
            errorCode == 'INSUFFICIENT_WITHDRAWAL_POINTS' ||
            errorCode == 'INSUFFICIENT_TASKS_FOR_AMOUNT') {
          Get.snackbar(
            LKey.tasks.tr,
            msg.tr,
            mainButton: TextButton(
              onPressed: () {
                Get.back();
                Get.to(() => const TasksScreen());
              },
              child: Text(LKey.goToTasks.tr),
            ),
          );
        }
      }
    } catch (e) {
      setState(() => errorText = e.toString());
    } finally {
      if (mounted) setState(() => submitting = false);
    }
  }

  void _setCoins(int coins) {
    final capped = coins.clamp(0, walletCoins);
    coinsCtrl.text = '$capped';
    coinsCtrl.selection =
        TextSelection.collapsed(offset: coinsCtrl.text.length);
    setState(() => errorText = null);
  }

  @override
  Widget build(BuildContext context) {
    final hint = selectedGateway?.accountHint?.trim();
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
                'Tasa $rateLabel · Mín. $currency${minUsd.toStringAsFixed(2)} · '
                'Saldo: ${walletCoins.numberFormat}',
                style: TextStyleCustom.outFitRegular400(
                  color: textLightGrey(context),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 14),
              Text(LKey.withdrawMethod.tr,
                  style: TextStyleCustom.outFitMedium500(
                      color: textDarkGrey(context), fontSize: 13)),
              const SizedBox(height: 6),
              DropdownButtonFormField<RedeemGateway>(
                // ignore: deprecated_member_use
                value: selectedGateway,
                dropdownColor: whitePure(context),
                style: TextStyleCustom.outFitRegular400(
                  color: textDarkGrey(context),
                  fontSize: 15,
                ),
                iconEnabledColor: textDarkGrey(context),
                items: gateways
                    .map((g) => DropdownMenuItem(
                          value: g,
                          child: Text(
                            '${g.title ?? ''} · '
                            '${g.resolveCommission(globalCommission).toStringAsFixed(2)}%',
                            style: TextStyleCustom.outFitRegular400(
                              color: textDarkGrey(context),
                              fontSize: 15,
                            ),
                          ),
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
              Text(LKey.payoutAccount.tr,
                  style: TextStyleCustom.outFitMedium500(
                      color: textDarkGrey(context), fontSize: 13)),
              const SizedBox(height: 6),
              TextField(
                controller: accountCtrl,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: (hint != null && hint.isNotEmpty)
                      ? hint
                      : 'Ej: UID Binance o wallet USDT (TRC20)',
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
                  hintText: 'Mín. $minCoinsForUsd monedas ($rateLabel)',
                  filled: true,
                  fillColor: bgLightGrey(context),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              _CoinsShortcuts(
                walletCoins: walletCoins,
                minCoins: minCoinsForUsd,
                selectedCoins: coinsEntered,
                coinValue: coinValue,
                currency: currency,
                onSelect: _setCoins,
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

class _CoinsShortcuts extends StatelessWidget {
  const _CoinsShortcuts({
    required this.walletCoins,
    required this.minCoins,
    required this.selectedCoins,
    required this.coinValue,
    required this.currency,
    required this.onSelect,
  });

  final int walletCoins;
  final int minCoins;
  final int selectedCoins;
  final double coinValue;
  final String currency;
  final ValueChanged<int> onSelect;

  String _fmtCoins(int coins) {
    if (coins >= 1000) {
      final k = coins / 1000;
      if (k == k.roundToDouble()) return '${k.toInt()}K';
      return '${k.toStringAsFixed(1)}K';
    }
    return '$coins';
  }

  List<({String label, int coins})> get _options {
    if (walletCoins <= 0 || minCoins <= 0 || walletCoins < minCoins) {
      return const [];
    }

    final out = <({String label, int coins})>[];
    void add(String label, int coins) {
      if (coins < minCoins || coins > walletCoins) return;
      if (out.any((e) => e.coins == coins)) return;
      out.add((label: label, coins: coins));
    }

    add('Mín · ${_fmtCoins(minCoins)}', minCoins);
    add('25%', (walletCoins * 0.25).floor());
    add('50%', (walletCoins * 0.5).floor());
    add('75%', (walletCoins * 0.75).floor());
    add('Máx · ${_fmtCoins(walletCoins)}', walletCoins);

    if (coinValue > 0) {
      for (final usd in const [50.0, 100.0, 200.0]) {
        final coins = (usd / coinValue).ceil();
        add('$currency${usd.toStringAsFixed(0)}', coins);
      }
    }

    out.sort((a, b) => a.coins.compareTo(b.coins));
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final options = _options;
    if (options.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Atajos',
          style: TextStyleCustom.outFitRegular400(
            color: textLightGrey(context),
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: options.map((opt) {
            final selected = selectedCoins == opt.coins;
            return Material(
              color: selected
                  ? ColorRes.themeAccentSolid
                  : bgLightGrey(context),
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                onTap: () => onSelect(opt.coins),
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  child: Text(
                    opt.label,
                    style: TextStyleCustom.outFitMedium500(
                      color: selected
                          ? Colors.white
                          : textDarkGrey(context),
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
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
