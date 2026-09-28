import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:krimson/common/controller/base_controller.dart';
import 'package:krimson/common/extensions/string_extension.dart';
import 'package:krimson/common/manager/app_role.dart';
import 'package:krimson/common/manager/session_manager.dart';
import 'package:krimson/common/service/api/common_service.dart';
import 'package:krimson/common/service/api/gift_wallet_service.dart';
import 'package:krimson/common/service/api/user_service.dart';
import 'package:krimson/common/service/subscription/subscription_manager.dart';
import 'package:krimson/languages/catalog_i18n.dart';
import 'package:krimson/languages/languages_keys.dart';
import 'package:krimson/model/general/settings_model.dart';
import 'package:krimson/model/user_model/user_model.dart';
import 'package:krimson/utilities/app_res.dart';
import 'package:krimson/utilities/client_colors.dart';
import 'package:krimson/utilities/style_res.dart';
import 'package:krimson/utilities/text_style_custom.dart';
import 'package:krimson/utilities/theme_res.dart';

class CoinWalletScreenController extends BaseController {
  Rx<User?> myUser = Rx<User?>(null);
  RxList<Package> offerings = <Package>[].obs;
  RxList<CoinPlan> coinPlans = <CoinPlan>[].obs;
  Worker? _userWorker;
  Worker? _coinWorker;

  Setting? get settings => SessionManager.instance.getSettings();

  @override
  void onInit() {
    super.onInit();
    fetchData();
    // CoinGate / promo hacen Get.put y el controller vive fuera de la ruta:
    // hay que seguir SessionManager o el saldo queda stale hasta reiniciar.
    _userWorker = ever<User?>(SessionManager.instance.userRx, (u) {
      if (u != null) myUser.value = u;
    });
    _coinWorker = ever<int>(SessionManager.instance.coinWalletRx, (coins) {
      final u = myUser.value;
      if (u == null) return;
      if ((u.coinWallet ?? 0).toInt() == coins) return;
      myUser.value = u.copyWith(coinWallet: coins);
    });
    _loadPlans();
  }

  @override
  void onClose() {
    _userWorker?.dispose();
    _coinWorker?.dispose();
    super.onClose();
  }

  Future<void> _loadPlans() async {
    isLoading.value = true;
    try {
      await CommonService.instance.fetchGlobalSettings();
      final user = await UserService.instance
          .fetchUserDetails(userId: SessionManager.instance.getUserID());
      if (user != null) {
        myUser.value = user;
        SessionManager.instance.setUser(user);
      }
    } catch (_) {
      // Si falla el refresh, usamos settings/usuario en caché.
    }
    fetchOfferings();
    isLoading.value = false;
  }

  void fetchData() {
    myUser.value = SessionManager.instance.getUser();
  }

  void fetchOfferings() {
    coinPlans.clear();
    offerings.clear();

    final items = SubscriptionManager.shared.offering;
    offerings.addAll(items);

    final packages = settings?.coinPackages ?? [];
    final currency = settings?.currency ?? AppRes.currency;

    for (final data in packages) {
      if (data.status != 1) continue;

      Package? matched;
      for (final element in items) {
        final productId = element.storeProduct.identifier;
        if (productId == data.appstoreProductId ||
            productId == data.playStoreProductId) {
          matched = element;
          break;
        }
      }

      final apiPrice = data.coinPlanPrice;
      final priceString = matched?.storeProduct.priceString ??
          (apiPrice == null
              ? ''
              : '$currency${_formatPrice(apiPrice)}');
      final base = data.coinAmount ?? 0;
      final pct = data.bonusPercent ?? 0;
      final bonus = data.bonusCoins ??
          (pct > 0 ? (base * pct / 100).round() : 0);
      final total = data.totalCoins ?? (base + bonus);

      coinPlans.add(
        CoinPlan(
          coin: total,
          baseCoins: base,
          bonusCoins: bonus,
          bonusPercent: pct,
          name: data.name,
          slug: data.slug,
          coinPackageId: data.id ?? -1,
          id: matched?.storeProduct.identifier ??
              data.playStoreProductId ??
              data.appstoreProductId ??
              '',
          priceString: priceString,
          amountUsd: apiPrice,
          image: data.image,
          canPurchaseViaStore: matched != null && !kIsWeb,
        ),
      );
    }
  }

  String _formatPrice(num price) {
    if (price % 1 == 0) return price.toInt().toString();
    return price.toStringAsFixed(2);
  }

  void onPurchase(CoinPlan offer) {
    _showPaymentMethodSheet(offer);
  }

  void _showPaymentMethodSheet(CoinPlan offer) {
    final ctx = Get.context;
    final client = AppRole.isClient();
    Widget sheet = SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
        decoration: BoxDecoration(
          color: client
              ? const Color(0xFF0B162C)
              : Get.theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          gradient: client
              ? const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF143056),
                    Color(0xFF0B162C),
                    Color(0xFF08101E),
                  ],
                )
              : null,
          border: client
              ? Border.all(
                  color: ClientColors.primary.withValues(alpha: 0.55),
                  width: 1.4,
                )
              : null,
          boxShadow: client
              ? ClientColors.neonGlow(alpha: 0.4, blur: 24)
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: client
                      ? const Color(0xFF5CE1FF)
                      : Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 14),
            _PaymentTitle(client: client),
            const SizedBox(height: 6),
            Text(
              offer.priceString.isEmpty
                  ? LKey.coinsCount.trParams({'count': '${offer.coin}'})
                  : '${CatalogI18n.packageName(offer.name)} · ${LKey.coinsCount.trParams({'count': '${offer.coin}'})} · ${offer.usdLabel}',
              textAlign: TextAlign.center,
              style: TextStyleCustom.outFitRegular400(
                color: client
                    ? ClientColors.textMuted
                    : textLightGrey(Get.context!),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 16),
            if (settings?.voletEnabled != false)
              _PaymentOptionTile(
                client: client,
                highlighted: true,
                kind: _PayVisual.card,
                icon: Icons.credit_card_rounded,
                title: LKey.payCardPseNequi.tr,
                subtitle: offer.usdAmountText.isEmpty
                    ? LKey.payWompi.tr
                    : LKey.wompiLocalChargeHint.trParams(
                        {'amount': offer.usdAmountText},
                      ),
                onTap: () {
                  Get.back();
                  Future<void>.delayed(
                    const Duration(milliseconds: 180),
                    () => onPurchaseVolet(offer),
                  );
                },
              ),
            if (settings?.nowpaymentsEnabled != false)
              _PaymentOptionTile(
                client: client,
                kind: _PayVisual.crypto,
                icon: Icons.currency_bitcoin,
                title: LKey.cryptocurrencies.tr,
                subtitle: LKey.usdtNowPayments.tr,
                onTap: () {
                  Get.back();
                  onPurchaseCrypto(offer);
                },
              ),
            if (offer.canPurchaseViaStore)
              _PaymentOptionTile(
                client: client,
                kind: _PayVisual.store,
                icon: Icons.phone_android,
                title: LKey.appStorePlayStore.tr,
                subtitle: LKey.inAppPurchase.tr,
                onTap: () {
                  Get.back();
                  onPurchaseStore(offer);
                },
              ),
            if (settings?.voletEnabled == false &&
                settings?.nowpaymentsEnabled == false &&
                !offer.canPurchaseViaStore)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  LKey.noPaymentMethods.tr,
                  textAlign: TextAlign.center,
                  style: TextStyleCustom.outFitRegular400(
                    color: client
                        ? ClientColors.textMuted
                        : textLightGrey(Get.context!),
                    fontSize: 13,
                  ),
                ),
              ),
            if (client) ...[
              const SizedBox(height: 8),
              Divider(
                height: 1,
                color: ClientColors.primary.withValues(alpha: 0.2),
              ),
              const SizedBox(height: 12),
              const _PaymentTrustRow(),
            ],
          ],
        ),
      ),
    );
    if (client && ctx != null) {
      sheet = Theme(data: ThemeRes.clientTheme(ctx), child: sheet);
    }
    Get.bottomSheet(
      sheet,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  void onPurchaseStore(CoinPlan offer) {
    if (!offer.canPurchaseViaStore) {
      showSnackBar(
        'Las compras in-app requieren App Store / Play Store y RevenueCat configurado.',
      );
      return;
    }

    showLoader(barrierDismissible: false);
    final package = offerings.firstWhereOrNull(
      (element) => element.storeProduct.identifier == offer.id,
    );
    if (package == null) {
      stopLoader();
      showSnackBar(LKey.somethingWentWrong.tr);
      return;
    }

    SubscriptionManager.shared.makePurchaseCustom(package).then((value) async {
      if (value != null) {
        final isoTime = value.nonSubscriptionTransactions.last.purchaseDate;
        final dt = DateTime.parse(isoTime);
        final millis = dt.millisecondsSinceEpoch;
        final bought = await GiftWalletService.instance
            .buyCoins(id: offer.coinPackageId, purchasedAt: millis.toString());
        stopLoader();
        if (bought != null) {
          final user = await UserService.instance
              .fetchUserDetails(userId: myUser.value?.id);
          if (user != null) {
            myUser.value = user;
            SessionManager.instance.setUser(user);
          }
        }
      } else {
        stopLoader();
      }
    });
  }

  Future<void> onPurchaseCrypto(CoinPlan offer) async {
    if (offer.coinPackageId < 1) {
      showSnackBar(LKey.somethingWentWrong.tr);
      return;
    }

    showLoader(barrierDismissible: false);
    final result = await GiftWalletService.instance
        .createCryptoPayment(coinPackageId: offer.coinPackageId);
    stopLoader();

    if (result['ok'] != true) {
      showSnackBar(
        (result['message'] ?? 'No se pudo iniciar el pago crypto. Intenta de nuevo.')
            .toString(),
      );
      return;
    }

    final created = result['data'] as Map<String, dynamic>?;
    if (created == null) {
      showSnackBar('No se pudo iniciar el pago crypto. Intenta de nuevo.');
      return;
    }

    final invoiceUrl = (created['invoice_url'] ?? '').toString();
    final orderId = (created['order_id'] ?? '').toString();
    if (invoiceUrl.isEmpty || orderId.isEmpty) {
      showSnackBar(LKey.somethingWentWrong.tr);
      return;
    }

    final launched = await invoiceUrl.lunchUrl;
    if (launched.status != true) {
      showSnackBar('Abre el pago con el botón del siguiente diálogo.');
    }

    await _showPaymentPendingDialog(
      orderId,
      _PaymentKind.crypto,
      checkoutUrl: invoiceUrl,
    );
  }

  Future<void> onPurchaseVolet(CoinPlan offer) async {
    if (offer.coinPackageId < 1) {
      showSnackBar(LKey.somethingWentWrong.tr);
      return;
    }

    showLoader(barrierDismissible: false);
    Map<String, dynamic> result;
    try {
      result = await GiftWalletService.instance.createVoletPayment(
        coinPackageId: offer.coinPackageId,
        appLanguage: Get.locale?.languageCode,
      );
    } catch (_) {
      stopLoader();
      showSnackBar('No se pudo iniciar el pago con Volet. Intenta de nuevo.');
      return;
    }
    stopLoader();

    if (result['ok'] != true) {
      showSnackBar(
        (result['message'] ??
                'No se pudo iniciar el pago con Volet. Intenta de nuevo.')
            .toString(),
      );
      return;
    }

    final created = result['data'] as Map<String, dynamic>?;
    if (created == null) {
      showSnackBar('No se pudo iniciar el pago con Volet. Intenta de nuevo.');
      return;
    }

    final invoiceUrl = _withCheckoutLang((created['invoice_url'] ??
            created['checkout_url'] ??
            '')
        .toString());
    final orderId = (created['order_id'] ?? '').toString();
    if (invoiceUrl.isEmpty || orderId.isEmpty) {
      showSnackBar(LKey.somethingWentWrong.tr);
      return;
    }

    await invoiceUrl.lunchUrl;
    await _showPaymentPendingDialog(
      orderId,
      _PaymentKind.volet,
      checkoutUrl: invoiceUrl,
      amountUsd: created['amount_usd'] ?? offer.amountUsd,
    );
  }

  String _withCheckoutLang(String url) {
    final lang = (Get.locale?.languageCode ?? 'es').toLowerCase();
    final uri = Uri.tryParse(url);
    if (url.isEmpty || uri == null) {
      return url;
    }
    final query = Map<String, String>.from(uri.queryParameters);
    query.putIfAbsent('lang', () => lang);
    return uri.replace(queryParameters: query).toString();
  }

  Future<void> _showPaymentPendingDialog(
    String orderId,
    _PaymentKind kind, {
    String? checkoutUrl,
    num? amountUsd,
  }) async {
    await Get.dialog(
      _PaymentPendingDialog(
        orderId: orderId,
        kind: kind,
        checkoutUrl: checkoutUrl,
        amountUsd: amountUsd,
        onFinished: (user) {
          if (user != null) {
            myUser.value = user;
            SessionManager.instance.setUser(user);
          }
        },
      ),
      barrierDismissible: false,
    );
  }
}

class _PaymentTitle extends StatelessWidget {
  const _PaymentTitle({required this.client});

  final bool client;

  @override
  Widget build(BuildContext context) {
    final raw = LKey.paymentMethod.tr.trim();
    if (!client) {
      return Text(
        raw,
        textAlign: TextAlign.center,
        style: TextStyleCustom.outFitMedium500(
          color: textDarkGrey(context),
          fontSize: 18,
        ),
      );
    }
    final parts = raw.split(RegExp(r'\s+'));
    final last = parts.isEmpty ? raw : parts.last;
    final head = parts.length <= 1
        ? ''
        : '${parts.sublist(0, parts.length - 1).join(' ')} ';
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: head,
            style: TextStyleCustom.unboundedMedium500(
              color: Colors.white,
              fontSize: 20,
            ),
          ),
          TextSpan(
            text: last,
            style: TextStyleCustom.unboundedMedium500(
              color: ClientColors.primary,
              fontSize: 20,
            ),
          ),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}

enum _PayVisual { card, crypto, store }

class _PaymentOptionTile extends StatelessWidget {
  const _PaymentOptionTile({
    required this.client,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.highlighted = false,
    this.kind = _PayVisual.store,
  });

  final bool client;
  final bool highlighted;
  final _PayVisual kind;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    if (!client) {
      return ListTile(
        leading: Icon(icon),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        onTap: onTap,
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Ink(
            padding: const EdgeInsets.fromLTRB(12, 12, 10, 12),
            decoration: BoxDecoration(
              color: highlighted
                  ? const Color(0xFF12304F)
                  : const Color(0xFF102038),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: highlighted
                    ? const Color(0xFF5CE1FF)
                    : ClientColors.primary.withValues(alpha: 0.35),
                width: highlighted ? 1.7 : 1,
              ),
              boxShadow: highlighted
                  ? ClientColors.neonGlow(
                      color: const Color(0xFF5CE1FF),
                      alpha: 0.45,
                      blur: 18,
                    )
                  : ClientColors.neonGlow(alpha: 0.16, blur: 10),
            ),
            child: Row(
              children: [
                _PayLeading(kind: kind),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyleCustom.outFitSemiBold600(
                          color: Colors.white,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: TextStyleCustom.outFitRegular400(
                          color: ClientColors.textMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: highlighted
                        ? const LinearGradient(
                            colors: [Color(0xFF5CE1FF), Color(0xFF27D3F5)],
                          )
                        : null,
                    color: highlighted ? null : const Color(0xFF12304F),
                    border: Border.all(
                      color: const Color(0xFF5CE1FF).withValues(alpha: 0.85),
                    ),
                    boxShadow: highlighted
                        ? ClientColors.neonGlow(
                            color: const Color(0xFF5CE1FF),
                            alpha: 0.45,
                            blur: 10,
                          )
                        : null,
                  ),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    color: highlighted
                        ? Colors.white
                        : const Color(0xFF5CE1FF),
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PayLeading extends StatelessWidget {
  const _PayLeading({required this.kind});

  final _PayVisual kind;

  @override
  Widget build(BuildContext context) {
    switch (kind) {
      case _PayVisual.card:
        return SizedBox(
          width: 62,
          height: 46,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: 14,
                top: 4,
                child: Transform.rotate(
                  angle: 0.22,
                  child: Container(
                    width: 42,
                    height: 28,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(7),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF7DD3FC), Color(0xFF2563EB)],
                      ),
                      boxShadow: ClientColors.neonGlow(
                        color: const Color(0xFF3B82F6),
                        alpha: 0.4,
                        blur: 8,
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                top: 12,
                child: Container(
                  width: 44,
                  height: 28,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(7),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF38BDF8), Color(0xFF4F46E5)],
                    ),
                    boxShadow: ClientColors.neonGlow(alpha: 0.35, blur: 8),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.fromLTRB(7, 6, 6, 5),
                    child: Row(
                      children: [
                        Icon(Icons.wifi_rounded, color: Colors.white70, size: 12),
                        Spacer(),
                        Icon(Icons.contactless_rounded,
                            color: Colors.white54, size: 11),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                right: -2,
                bottom: -3,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF10B981),
                    border: Border.all(
                      color: const Color(0xFF0B162C),
                      width: 1.6,
                    ),
                    boxShadow: ClientColors.neonGlow(
                      color: const Color(0xFF34D399),
                      alpha: 0.5,
                      blur: 8,
                    ),
                  ),
                  child: const Icon(
                    Icons.lock_rounded,
                    color: Colors.white,
                    size: 10,
                  ),
                ),
              ),
            ],
          ),
        );
      case _PayVisual.crypto:
        return SizedBox(
          width: 64,
          height: 36,
          child: Stack(
            children: [
              Positioned(
                left: 0,
                child: _cryptoDot(
                  const Color(0xFFF7931A),
                  Icons.currency_bitcoin,
                ),
              ),
              Positioned(
                left: 18,
                child: _cryptoDot(
                  const Color(0xFF627EEA),
                  Icons.hexagon_rounded,
                ),
              ),
              Positioned(
                left: 36,
                child: _cryptoDot(
                  const Color(0xFF26A17B),
                  Icons.attach_money_rounded,
                ),
              ),
            ],
          ),
        );
      case _PayVisual.store:
        return Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: ClientColors.primary.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.phone_android, color: ClientColors.primary),
        );
    }
  }

  Widget _cryptoDot(Color color, IconData icon) {
    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        border: Border.all(color: const Color(0xFF0B162C), width: 1.8),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.45), blurRadius: 8),
        ],
      ),
      child: Icon(icon, color: Colors.white, size: 14),
    );
  }
}

class _PaymentTrustRow extends StatelessWidget {
  const _PaymentTrustRow();

  @override
  Widget build(BuildContext context) {
    final es = Get.locale?.languageCode == 'es';
    Widget item(IconData icon, String label) {
      return Expanded(
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFF5CE1FF), size: 18),
            const SizedBox(height: 5),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyleCustom.outFitRegular400(
                color: ClientColors.textMuted,
                fontSize: 10,
              ),
            ),
          ],
        ),
      );
    }

    Widget divider() => Container(
          width: 1,
          height: 36,
          color: ClientColors.primary.withValues(alpha: 0.22),
        );

    return Row(
      children: [
        item(
          Icons.verified_user_outlined,
          es ? 'Seguro' : 'Safe & Secure',
        ),
        divider(),
        item(
          Icons.bolt_rounded,
          es ? 'Proceso rápido' : 'Fast Processing',
        ),
        divider(),
        item(
          Icons.lock_outline_rounded,
          es ? 'Varios métodos' : 'Multiple Payment Methods',
        ),
      ],
    );
  }
}

enum _PaymentKind { crypto, volet }

class _PaymentPendingDialog extends StatefulWidget {
  final String orderId;
  final _PaymentKind kind;
  final String? checkoutUrl;
  final num? amountUsd;
  final void Function(User? user) onFinished;

  const _PaymentPendingDialog({
    required this.orderId,
    required this.kind,
    required this.onFinished,
    this.checkoutUrl,
    this.amountUsd,
  });

  @override
  State<_PaymentPendingDialog> createState() => _PaymentPendingDialogState();
}

class _PaymentPendingDialogState extends State<_PaymentPendingDialog> {
  Timer? _timer;
  String _status = 'pending';
  bool _checking = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 4), (_) => _poll());
    _poll();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _poll() async {
    if (_checking) return;
    _checking = true;
    try {
      final data = widget.kind == _PaymentKind.volet
          ? await GiftWalletService.instance
              .checkVoletPayment(orderId: widget.orderId)
          : await GiftWalletService.instance
              .checkCryptoPayment(orderId: widget.orderId);
      if (!mounted || data == null) return;

      final status = (data['status'] ?? 'pending').toString();
      final isVolet = widget.kind == _PaymentKind.volet;
      setState(() {
        _status = status;
        if (status == 'confirming') {
          _message = isVolet
              ? LKey.confirmingPayment.tr
              : LKey.confirmingBlockchain.tr;
        } else if (status == 'partially_paid') {
          _message = LKey.partialPaymentDetected.tr;
        } else if (status == 'failed' || status == 'expired') {
          _message = LKey.paymentNotCompleted.tr;
        } else {
          _message = isVolet
              ? LKey.waitingVoletPayment.tr
              : LKey.waitingCryptoPayment.tr;
        }
      });

      if (status == 'finished') {
        _timer?.cancel();
        final user = await UserService.instance.fetchUserDetails(
          userId: SessionManager.instance.getUserID(),
        );
        widget.onFinished(user);
        if (mounted) {
          Get.back();
          Get.snackbar(
            '',
            'Monedas acreditadas correctamente',
            snackPosition: SnackPosition.TOP,
            backgroundColor: Colors.black87,
            colorText: Colors.white,
            margin: const EdgeInsets.all(12),
            titleText: const SizedBox.shrink(),
            messageText: const Text(
              'Monedas acreditadas correctamente',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white),
            ),
          );
        }
      } else if (status == 'failed' || status == 'expired' || status == 'refunded') {
        _timer?.cancel();
      }
    } finally {
      _checking = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final failed = _status == 'failed' ||
        _status == 'expired' ||
        _status == 'refunded';

    return AlertDialog(
      title: Text(
        failed
            ? 'Pago no completado'
            : (widget.kind == _PaymentKind.volet
                ? 'Pago Volet en curso'
                : 'Pago crypto en curso'),
        style: TextStyleCustom.outFitMedium500(
          color: textDarkGrey(context),
          fontSize: 16,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!failed) ...[
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
            const SizedBox(height: 14),
          ],
          Text(
            _message ??
                (failed
                    ? 'Puedes cerrar e intentar de nuevo.'
                    : 'Completa el pago en el navegador. Esta ventana se actualizará sola.'),
            textAlign: TextAlign.center,
            style: TextStyleCustom.outFitRegular400(
              color: textLightGrey(context),
              fontSize: 13,
            ),
          ),
          if (!failed &&
              widget.kind == _PaymentKind.volet &&
              widget.amountUsd != null) ...[
            const SizedBox(height: 12),
            Text(
              LKey.voletUsdHint.trParams({
                'amount': CoinPlan.formatUsdAmount(widget.amountUsd!),
              }),
              textAlign: TextAlign.center,
              style: TextStyleCustom.outFitRegular400(
                color: textLightGrey(context),
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Get.back(),
          child: Text(
            failed ? 'Cerrar' : 'Seguir en segundo plano',
            style: TextStyle(color: StyleRes.brandAccent),
          ),
        ),
        if (!failed && (widget.checkoutUrl ?? '').isNotEmpty)
          TextButton(
            onPressed: () => widget.checkoutUrl!.lunchUrl,
            child: Text(
              widget.kind == _PaymentKind.volet
                  ? 'Abrir Volet'
                  : 'Abrir pago',
              style: TextStyle(color: StyleRes.brandAccent),
            ),
          ),
        if (!failed)
          TextButton(
            onPressed: _poll,
            child: Text(
              'Verificar ahora',
              style: TextStyle(color: StyleRes.brandAccent),
            ),
          ),
      ],
    );
  }
}

class CoinPlan {
  final int coin;
  final int baseCoins;
  final int bonusCoins;
  final num bonusPercent;
  final String? name;
  final String? slug;
  final int coinPackageId;
  final String id;
  final String priceString;
  final num? amountUsd;
  final String? image;
  final bool canPurchaseViaStore;

  CoinPlan({
    required this.coin,
    required this.coinPackageId,
    required this.id,
    required this.priceString,
    this.amountUsd,
    this.baseCoins = 0,
    this.bonusCoins = 0,
    this.bonusPercent = 0,
    this.name,
    this.slug,
    this.image,
    this.canPurchaseViaStore = false,
  });

  static String formatUsdAmount(num amount) {
    if (amount % 1 == 0) return amount.toInt().toString();
    return amount.toStringAsFixed(2);
  }

  String get usdAmountText =>
      amountUsd == null ? '' : formatUsdAmount(amountUsd!);

  String get usdLabel {
    if (usdAmountText.isEmpty) return priceString;
    return '\$$usdAmountText USD';
  }
}
