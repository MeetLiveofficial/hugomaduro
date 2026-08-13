import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krimson/common/controller/base_controller.dart';
import 'package:krimson/common/manager/app_role.dart';
import 'package:krimson/common/manager/logger.dart';
import 'package:krimson/common/manager/session_manager.dart';
import 'package:krimson/common/service/api/call_service.dart';
import 'package:krimson/screen/call_screen/match_recommend_sheet.dart';
import 'package:krimson/screen/coin_wallet_screen/coin_wallet_screen.dart';
import 'package:krimson/screen/dashboard_screen/dashboard_screen_controller.dart';
import 'package:krimson/screen/subscription_screen/subscription_screen.dart';

enum MatchSearchMode { random, goddess }

class MatchScreenController extends BaseController
    with GetTickerProviderStateMixin {
  final Rx<MatchSearchMode> mode = MatchSearchMode.random.obs;
  final RxBool isMatching = false.obs;

  late final AnimationController pulseController;
  Worker? _tabWorker;

  int get walletCoins =>
      SessionManager.instance.getUser()?.coinWallet?.toInt() ?? 0;

  bool get isPlusMember =>
      (SessionManager.instance.getUser()?.isVerify ?? 0) == 1;

  /// Hint de costo Random (mínimo de niveles activos).
  int get randomHintCost {
    final levels = SessionManager.instance.getSettings()?.userLevels ?? [];
    final prices = levels
        .map((e) => e.callRequestCoins)
        .where((c) => c > 0)
        .toList();
    if (prices.isEmpty) return 9;
    prices.sort();
    return prices.first;
  }

  /// Hint Goddess: streamers grado A/S (más alto).
  int get goddessHintCost {
    final base = randomHintCost;
    return base < 30 ? 30 : (base * 3).clamp(30, 9999);
  }

  int get membershipHintCost {
    final mid = ((randomHintCost + goddessHintCost) / 2).round();
    return mid.clamp(1, 9999);
  }

  @override
  void onInit() {
    super.onInit();
    pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    );
    _syncPulse();
    if (Get.isRegistered<DashboardScreenController>()) {
      _tabWorker = ever(
        Get.find<DashboardScreenController>().selectedPageIndex,
        (_) => _syncPulse(),
      );
    }
  }

  void _syncPulse() {
    var onMatchTab = true;
    if (Get.isRegistered<DashboardScreenController>()) {
      onMatchTab = Get.find<DashboardScreenController>().selectedPageIndex.value ==
          DashboardScreenController.tabLive;
    }
    final shouldRun = onMatchTab && AppRole.isClient();
    if (shouldRun) {
      if (!pulseController.isAnimating) pulseController.repeat();
    } else if (pulseController.isAnimating) {
      pulseController.stop();
    }
  }

  @override
  void onClose() {
    _tabWorker?.dispose();
    pulseController.dispose();
    super.onClose();
  }

  void selectMode(MatchSearchMode value) {
    mode.value = value;
  }

  Future<void> startMatch() async {
    if (AppRole.isStreamer()) {
      showSnackBar('Match solo está disponible para clientes');
      return;
    }
    if (isMatching.value) return;
    isMatching.value = true;
    try {
      final me = SessionManager.instance.getUser();
      final lang = (me?.appLanguage ?? '').trim().toLowerCase();
      final match = await CallService.instance.findMatch(
        appLanguage: lang.isEmpty ? null : lang,
        mode: mode.value == MatchSearchMode.goddess ? 'goddess' : 'random',
      );
      await MatchRecommendSheet.show(
        match,
        mode: mode.value == MatchSearchMode.goddess ? 'goddess' : 'random',
      );
    } catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '');
      if (msg.toLowerCase().contains('no match')) {
        showSnackBar(mode.value == MatchSearchMode.goddess
            ? 'No hay Goddess disponibles ahora. Prueba Random.'
            : 'No hay usuarios disponibles con tu idioma ahora');
      } else {
        showSnackBar(msg);
      }
      Loggers.error('MatchScreen.startMatch: $e');
    } finally {
      isMatching.value = false;
    }
  }

  void openWallet() {
    Get.to(() => const CoinWalletScreen());
  }

  void openMembership() {
    Get.to(() => const SubscriptionScreen());
  }
}
