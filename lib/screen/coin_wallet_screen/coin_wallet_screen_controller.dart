import 'package:get/get.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:krimson/common/controller/base_controller.dart';
import 'package:krimson/common/manager/session_manager.dart';
import 'package:krimson/common/service/api/common_service.dart';
import 'package:krimson/common/service/api/gift_wallet_service.dart';
import 'package:krimson/common/service/api/user_service.dart';
import 'package:krimson/common/service/subscription/subscription_manager.dart';
import 'package:krimson/languages/languages_keys.dart';
import 'package:krimson/model/general/settings_model.dart';
import 'package:krimson/model/user_model/user_model.dart';
import 'package:krimson/utilities/app_res.dart';

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
          canPurchaseViaStore: matched != null,
        ),
      );
    }
  }

  String _formatPrice(num price) {
    if (price % 1 == 0) return price.toInt().toString();
    return price.toStringAsFixed(2);
  }

  void onPurchase(CoinPlan offer) {
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
