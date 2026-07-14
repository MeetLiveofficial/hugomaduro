import 'package:get/get.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

final RxBool isSubscribe = false.obs;

class SubscriptionManager {
  SubscriptionManager._();
  static final SubscriptionManager shared = SubscriptionManager._();

  List<Package> offering = <Package>[];

  Future<void> initPlatformState() async {}

  Future<void> login(String appUserId) async {}

  void subscriptionListener() {}

  Future<dynamic> makePurchaseCustom(Package package) async {
    return null;
  }
}
