import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:krimson/common/controller/base_controller.dart';
import 'package:krimson/common/extensions/string_extension.dart';
import 'package:krimson/common/manager/session_manager.dart';
import 'package:krimson/common/service/api/common_service.dart';
import 'package:krimson/common/service/api/gift_wallet_service.dart';
import 'package:krimson/common/service/api/user_service.dart';
import 'package:krimson/common/service/subscription/subscription_manager.dart';
import 'package:krimson/languages/languages_keys.dart';
import 'package:krimson/model/general/settings_model.dart';
import 'package:krimson/model/user_model/user_model.dart';
import 'package:krimson/utilities/app_res.dart';
import 'package:krimson/utilities/color_res.dart';
import 'package:krimson/utilities/text_style_custom.dart';
import 'package:krimson/utilities/theme_res.dart';

class CoinWalletScreenController extends BaseController {
  Rx<User?> myUser = Rx<User?>(null);
  RxList<Package> offerings = <Package>[].obs;
  RxList<CoinPlan> coinPlans = <CoinPlan>[].obs;

  Setting? get settings => SessionManager.instance.getSettings();

  @override
  void onInit() {
    super.onInit();
    fetchData();
    _loadPlans();
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

      coinPlans.add(
        CoinPlan(
          coin: data.coinAmount ?? 0,
          coinPackageId: data.id ?? -1,
          id: matched?.storeProduct.identifier ??
              data.playStoreProductId ??
              data.appstoreProductId ??
              '',
          priceString: priceString,
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
    Get.bottomSheet(
      SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          decoration: BoxDecoration(
            color: Get.theme.scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
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
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Método de pago',
                textAlign: TextAlign.center,
                style: TextStyleCustom.outFitMedium500(
                  color: textDarkGrey(Get.context!),
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                offer.priceString.isEmpty
                    ? '${offer.coin} monedas'
                    : '${offer.coin} monedas · ${offer.priceString}',
                textAlign: TextAlign.center,
                style: TextStyleCustom.outFitRegular400(
                  color: textLightGrey(Get.context!),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 16),
              if (settings?.wompiEnabled != false)
                ListTile(
                  leading: const Icon(Icons.credit_card),
                  title: const Text('Tarjeta / PSE / Nequi'),
                  subtitle: const Text('Wompi · Colombia e Internacional'),
                  onTap: () {
                    Get.back();
                    Future<void>.delayed(
                      const Duration(milliseconds: 180),
                      () => onPurchaseWompi(offer),
                    );
                  },
                ),
              if (settings?.nowpaymentsEnabled != false)
                ListTile(
                  leading: const Icon(Icons.currency_bitcoin),
                  title: const Text('Criptomonedas'),
                  subtitle: const Text('USDT y más (NOWPayments)'),
                  onTap: () {
                    Get.back();
                    onPurchaseCrypto(offer);
                  },
                ),
              if (offer.canPurchaseViaStore)
                ListTile(
                  leading: const Icon(Icons.phone_android),
                  title: const Text('App Store / Play Store'),
                  subtitle: const Text('Compra in-app'),
                  onTap: () {
                    Get.back();
                    onPurchaseStore(offer);
                  },
                ),
              if (settings?.wompiEnabled == false &&
                  settings?.nowpaymentsEnabled == false &&
                  !offer.canPurchaseViaStore)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'No hay métodos de pago disponibles.',
                    textAlign: TextAlign.center,
                    style: TextStyleCustom.outFitRegular400(
                      color: textLightGrey(Get.context!),
                      fontSize: 13,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
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

  Future<void> onPurchaseWompi(CoinPlan offer) async {
    if (offer.coinPackageId < 1) {
      showSnackBar(LKey.somethingWentWrong.tr);
      return;
    }

    showLoader(barrierDismissible: false);
    Map<String, dynamic> result;
    try {
      result = await GiftWalletService.instance
          .createWompiPayment(coinPackageId: offer.coinPackageId);
    } catch (_) {
      stopLoader();
      showSnackBar('No se pudo iniciar el pago con tarjeta. Intenta de nuevo.');
      return;
    }
    stopLoader();

    if (result['ok'] != true) {
      showSnackBar(
        (result['message'] ??
                'No se pudo iniciar el pago con tarjeta. Intenta de nuevo.')
            .toString(),
      );
      return;
    }

    final created = result['data'] as Map<String, dynamic>?;
    if (created == null) {
      showSnackBar('No se pudo iniciar el pago con tarjeta. Intenta de nuevo.');
      return;
    }

    final invoiceUrl = (created['invoice_url'] ??
            created['checkout_url'] ??
            '')
        .toString();
    final orderId = (created['order_id'] ?? '').toString();
    if (invoiceUrl.isEmpty || orderId.isEmpty) {
      showSnackBar(LKey.somethingWentWrong.tr);
      return;
    }

    // En Web el navegador bloquea popups tras el await de la API.
    // En Android se intenta abrir igual; si falla, el diálogo tiene el botón.
    await invoiceUrl.lunchUrl;
    await _showPaymentPendingDialog(
      orderId,
      _PaymentKind.wompi,
      checkoutUrl: invoiceUrl,
    );
  }

  Future<void> _showPaymentPendingDialog(
    String orderId,
    _PaymentKind kind, {
    String? checkoutUrl,
  }) async {
    await Get.dialog(
      _PaymentPendingDialog(
        orderId: orderId,
        kind: kind,
        checkoutUrl: checkoutUrl,
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

enum _PaymentKind { crypto, wompi }

class _PaymentPendingDialog extends StatefulWidget {
  final String orderId;
  final _PaymentKind kind;
  final String? checkoutUrl;
  final void Function(User? user) onFinished;

  const _PaymentPendingDialog({
    required this.orderId,
    required this.kind,
    required this.onFinished,
    this.checkoutUrl,
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
      final data = widget.kind == _PaymentKind.wompi
          ? await GiftWalletService.instance
              .checkWompiPayment(orderId: widget.orderId)
          : await GiftWalletService.instance
              .checkCryptoPayment(orderId: widget.orderId);
      if (!mounted || data == null) return;

      final status = (data['status'] ?? 'pending').toString();
      final isWompi = widget.kind == _PaymentKind.wompi;
      setState(() {
        _status = status;
        if (status == 'confirming') {
          _message = isWompi
              ? 'Confirmando el pago…'
              : 'Confirmando en blockchain…';
        } else if (status == 'partially_paid') {
          _message = 'Pago parcial detectado. Completa el monto.';
        } else if (status == 'failed' || status == 'expired') {
          _message = 'El pago no se completó.';
        } else {
          _message = isWompi
              ? 'Esperando tu pago con tarjeta…'
              : 'Esperando tu pago en crypto…';
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
            : (widget.kind == _PaymentKind.wompi
                ? 'Pago con tarjeta en curso'
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
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Get.back(),
          child: Text(
            failed ? 'Cerrar' : 'Seguir en segundo plano',
            style: TextStyle(color: ColorRes.themeAccentSolid),
          ),
        ),
        if (!failed && (widget.checkoutUrl ?? '').isNotEmpty)
          TextButton(
            onPressed: () => widget.checkoutUrl!.lunchUrl,
            child: Text(
              widget.kind == _PaymentKind.wompi
                  ? 'Abrir Wompi'
                  : 'Abrir pago',
              style: TextStyle(color: ColorRes.themeAccentSolid),
            ),
          ),
        if (!failed)
          TextButton(
            onPressed: _poll,
            child: Text(
              'Verificar ahora',
              style: TextStyle(color: ColorRes.themeAccentSolid),
            ),
          ),
      ],
    );
  }
}

class CoinPlan {
  final int coin;
  final int coinPackageId;
  final String id;
  final String priceString;
  final String? image;
  final bool canPurchaseViaStore;

  CoinPlan({
    required this.coin,
    required this.coinPackageId,
    required this.id,
    required this.priceString,
    this.image,
    this.canPurchaseViaStore = false,
  });
}
