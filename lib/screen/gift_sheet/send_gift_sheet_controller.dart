import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krimson/common/controller/base_controller.dart';
import 'package:krimson/common/functions/debounce_action.dart';
import 'package:krimson/common/manager/app_role.dart';
import 'package:krimson/common/manager/coin_gate.dart';
import 'package:krimson/common/manager/firebase_notification_manager.dart';
import 'package:krimson/common/manager/gift_media_cache.dart';
import 'package:krimson/common/manager/guest_gate.dart';
import 'package:krimson/common/manager/haptic_manager.dart';
import 'package:krimson/common/manager/logger.dart';
import 'package:krimson/common/manager/session_manager.dart';
import 'package:krimson/common/service/api/gift_wallet_service.dart';
import 'package:krimson/languages/languages_keys.dart';
import 'package:krimson/model/general/settings_model.dart';
import 'package:krimson/model/livestream/app_user.dart';
import 'package:krimson/model/post_story/post_model.dart';
import 'package:krimson/model/user_model/user_model.dart';
import 'package:krimson/screen/gift_sheet/send_gift_dialog.dart';
import 'package:krimson/screen/gift_sheet/send_gift_sheet.dart';
import 'package:krimson/screen/live_stream/livestream_screen/livestream_screen_controller.dart';

class SendGiftSheetController extends BaseController {
  static const int pageSize = 10;

  Rx<Setting?> settings = Rx<Setting?>(null);
  Rx<User?> myUser = Rx<User?>(null);
  int? userId;
  List<AppUser> liveUsers;
  GiftType? giftType;
  String? giftSource;
  LivestreamScreenController? livestreamController;

  /// 0 = todas las categorías.
  final RxInt selectedCategoryId = 0.obs;
  final RxList<GiftCategory> categories = <GiftCategory>[].obs;
  final RxList<Gift> visibleGifts = <Gift>[].obs;
  final RxBool hasMore = false.obs;
  final ScrollController scrollController = ScrollController();

  List<Gift> _filteredGifts = [];
  int _loadedCount = 0;
  bool _loadingMore = false;

  SendGiftSheetController(this.giftType, this.userId, this.liveUsers,
      {this.giftSource});

  @override
  void onInit() {
    super.onInit();
    _initData();
    scrollController.addListener(_onScroll);

    if (liveUsers.isNotEmpty &&
        (giftType == GiftType.livestream || giftType == GiftType.battle)) {
      livestreamController = LivestreamScreenController.activeInstance;
      if (livestreamController != null) {
        if (livestreamController!.selectedGiftUser.value == null) {
          livestreamController!.selectedGiftUser = liveUsers.first.obs;
        } else {
          DebounceAction.shared.call(() {
            livestreamController!.selectedGiftUser.value =
                liveUsers.firstWhere(
                    (element) =>
                        element.userId ==
                        livestreamController!.selectedGiftUser.value?.userId,
                    orElse: () => liveUsers.first);
          });
        }
      } else {
        // Fallback: usar primer stream user como destino.
      }
    }
  }

  @override
  void onClose() {
    scrollController.removeListener(_onScroll);
    scrollController.dispose();
    super.onClose();
  }

  _initData() {
    settings.value = SessionManager.instance.getSettings();
    myUser.value = SessionManager.instance.getUser();
    final cats = List<GiftCategory>.from(settings.value?.giftCategories ?? []);
    cats.sort((a, b) => (a.sortOrder ?? 0).compareTo(b.sortOrder ?? 0));
    categories.assignAll(cats);
    GiftMediaCache.precacheGifts(settings.value?.gifts);
    selectCategory(0);
  }

  void selectCategory(int categoryId) {
    selectedCategoryId.value = categoryId;
    final all = settings.value?.gifts ?? [];
    if (categoryId <= 0) {
      _filteredGifts = List<Gift>.from(all);
    } else {
      _filteredGifts =
          all.where((g) => (g.categoryId ?? 0) == categoryId).toList();
    }
    _loadedCount = 0;
    visibleGifts.clear();
    hasMore.value = _filteredGifts.isNotEmpty;
    loadMore();
    if (scrollController.hasClients) {
      scrollController.jumpTo(0);
    }
  }

  void loadMore() {
    if (_loadingMore || _loadedCount >= _filteredGifts.length) {
      hasMore.value = _loadedCount < _filteredGifts.length;
      return;
    }
    _loadingMore = true;
    final end = (_loadedCount + pageSize).clamp(0, _filteredGifts.length);
    visibleGifts.addAll(_filteredGifts.sublist(_loadedCount, end));
    _loadedCount = end;
    hasMore.value = _loadedCount < _filteredGifts.length;
    _loadingMore = false;
  }

  void _onScroll() {
    if (!scrollController.hasClients || !hasMore.value) return;
    final pos = scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 100) {
      loadMore();
    }
  }

  void onGiftTap(Gift gift, BuildContext context) {
    if (gift.id == null) {
      return showSnackBar('Gift Not Found');
    }

    final price = gift.coinPrice ?? 0;
    final wallet = (myUser.value?.coinWallet ?? 0).toInt();
    if (wallet < price) {
      CoinGate.ensureEnough(price);
      return;
    }

    sendGift(gift, context);
  }

  Future<void> sendGift(Gift gift, BuildContext context) async {
    if (giftType == GiftType.none && !AppRole.canSendGifts()) {
      return;
    }
    final giftId = gift.id?.toInt() ?? -1;

    var coinPrice = gift.coinPrice ?? 0;
    userId ??= livestreamController?.selectedGiftUser.value?.userId ??
        (liveUsers.isNotEmpty ? liveUsers.first.userId : null);

    if (giftId == -1 || userId == null || userId == -1) {
      return Loggers.error('Invalid Gift: $giftId or User: $userId');
    }

    if (coinPrice <= 0) {
      // Último intento: catálogo local.
      final catalog = SessionManager.instance.getSettings()?.gifts ?? [];
      for (final g in catalog) {
        if (g.id == gift.id && (g.coinPrice ?? 0) > 0) {
          coinPrice = g.coinPrice!;
          gift.coinPrice = coinPrice;
          break;
        }
      }
    }
    if (coinPrice <= 0) {
      return Loggers.error(
          'Invalid coin price: $coinPrice, skipping gift sending.');
    }
    showLoader();
    final detailed = await GiftWalletService.instance.sendGiftDetailed(
      giftId: giftId,
      userId: userId,
      source: resolvedGiftSource,
    );
    stopLoader();
    if (detailed.ok) {
      // Precio confirmado por API (fuente de verdad).
      if (detailed.coinPrice > 0) {
        coinPrice = detailed.coinPrice;
        gift.coinPrice = coinPrice;
      }
      if ((detailed.image ?? '').isNotEmpty) {
        gift.image = detailed.image;
      }
      // Deduct gift coins from user wallet
      myUser.update((val) {
        val?.removeCoinFromWallet(coinPrice);
      });
      Loggers.info(myUser.value?.coinWallet);
      SessionManager.instance.setUser(myUser.value);
      if (giftType == GiftType.none) {
        Get.back(result: GiftManager(gift));
      } else {
        Get.back(
            result: GiftManager(gift,
                streamUser: livestreamController?.selectedGiftUser.value ??
                    (liveUsers.isNotEmpty ? liveUsers.first : null)));
      }
    } else {
      showSnackBar(detailed.message);
    }
  }

  String get resolvedGiftSource {
    if (giftType == GiftType.livestream || giftType == GiftType.battle) {
      return 'live';
    }
    final source = (giftSource ?? '').trim();
    if (source.isNotEmpty) return source;
    return 'gift';
  }
}

class GiftManager {
  Gift gift;
  AppUser? streamUser;

  GiftManager(this.gift, {this.streamUser});

  static Future<void> openGiftSheet(
      {int? userId,
      Post? post,
      GiftType giftType = GiftType.none,
      BattleView battleViewType = BattleView.red,
      List<AppUser> streamUsers = const [],
      String? giftSource,
      required Function(GiftManager giftManager) onCompletion}) async {
    if (GuestGate.block()) return;
    if (giftType == GiftType.none && !AppRole.canSendGifts()) {
      return;
    }
    if (Get.isRegistered<SendGiftSheetController>()) {
      Get.delete<SendGiftSheetController>(force: true);
    }
    await Get.bottomSheet<GiftManager>(
      SendGiftSheet(
        userId: userId,
        giftType: giftType,
        battleViewType: battleViewType,
        streamUsers: streamUsers,
        giftSource: giftSource,
      ),
      isScrollControlled: true,
    ).then((gift) {
      if (Get.isRegistered<SendGiftSheetController>()) {
        Get.delete<SendGiftSheetController>(force: true);
      }
      if (gift != null) {
        onCompletion(gift);
      }
    });
  }

  static bool _giftDialogOpen = false;

  static void showAnimationDialog(Gift gift) {
    final ctx = Get.context;
    if (ctx == null) return;
    if ((gift.image ?? '').trim().isEmpty) return;

    // Si ya hay uno, cerrarlo para no apilar stickers.
    if (_giftDialogOpen) {
      try {
        final nav = Navigator.of(ctx, rootNavigator: true);
        if (nav.canPop()) nav.pop();
      } catch (_) {}
      _giftDialogOpen = false;
    }

    _giftDialogOpen = true;
    showGeneralDialog(
      context: ctx,
      barrierDismissible: true,
      barrierLabel: 'gift',
      barrierColor: Colors.transparent,
      pageBuilder: (context, animation, secondaryAnimation) {
        return SendGiftDialog(gift: gift);
      },
      // La animación visual la hace SendGiftDialog (entrada + hold + salida).
      transitionDuration: const Duration(milliseconds: 80),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        if (animation.status == AnimationStatus.forward) {
          HapticManager.shared.light();
        }
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
    ).whenComplete(() {
      _giftDialogOpen = false;
    });
  }

  static void sendNotification(Post? post) {
    final user = post?.user;
    if (user == null || user.id == SessionManager.instance.getUserID()) return;

    if (user.notifyGiftReceived == 1) {
      FirebaseNotificationManager.instance.sendLocalisationNotification(
        LKey.activitySentGift,
        type: NotificationType.post,
        deviceType: user.device,
        deviceToken: user.deviceToken,
        languageCode: user.appLanguage,
        body: NotificationInfo(id: post?.id),
      );
    }
  }
}
