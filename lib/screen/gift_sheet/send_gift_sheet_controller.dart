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
import 'package:krimson/common/manager/livekit_room_controller.dart';
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
  static const int pageSize = 20;

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
  final RxBool isInitialLoad = true.obs;
  final ScrollController scrollController = ScrollController();

  int? _lastItemId;
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
    selectCategory(0);
  }

  void selectCategory(int categoryId) {
    selectedCategoryId.value = categoryId;
    _lastItemId = null;
    _loadingMore = false;
    visibleGifts.clear();
    hasMore.value = true;
    isInitialLoad.value = true;
    if (scrollController.hasClients) {
      scrollController.jumpTo(0);
    }
    loadMore();
  }

  Future<void> loadMore() async {
    if (_loadingMore) return;
    if (!hasMore.value && visibleGifts.isNotEmpty) return;

    _loadingMore = true;
    try {
      final result = await GiftWalletService.instance.fetchGiftsCatalog(
        categoryId: selectedCategoryId.value,
        lastItemId: _lastItemId,
        limit: pageSize,
      );
      visibleGifts.addAll(result.gifts);
      hasMore.value = result.hasMore;
      if (result.gifts.isNotEmpty) {
        _lastItemId = result.gifts.last.id;
        GiftManager.rememberAll(result.gifts);
        GiftMediaCache.precacheGifts(result.gifts);
      }
    } catch (e) {
      Loggers.error('fetchGiftsCatalog failed: $e');
      if (visibleGifts.isEmpty && _lastItemId == null) {
        _loadFromSettingsCache(selectedCategoryId.value);
      }
    } finally {
      _loadingMore = false;
      isInitialLoad.value = false;
    }
  }

  /// Respaldo si el endpoint aún no está desplegado en el servidor.
  void _loadFromSettingsCache(int categoryId) {
    final all = settings.value?.gifts ?? [];
    final filtered = categoryId <= 0
        ? List<Gift>.from(all)
        : all.where((g) => (g.categoryId ?? 0) == categoryId).toList();
    visibleGifts.assignAll(filtered);
    hasMore.value = false;
    GiftManager.rememberAll(filtered);
    GiftMediaCache.precacheGifts(filtered);
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
      if (detailed.isFullscreen != 0) {
        gift.isFullscreen = detailed.isFullscreen;
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

  static final Map<int, Gift> _knownGifts = {};

  static void rememberAll(List<Gift>? gifts) {
    if (gifts == null || gifts.isEmpty) return;
    for (final g in gifts) {
      if (g.id != null) _knownGifts[g.id!] = g;
    }
  }

  static Gift? knownById(int? id) {
    if (id == null) return null;
    return _knownGifts[id];
  }

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
  static OverlayEntry? _giftOverlay;

  static Gift _hydrateFromCatalog(Gift gift) {
    rememberAll(SessionManager.instance.getSettings()?.gifts);
    Gift? match = gift.id != null ? _knownGifts[gift.id!] : null;
    final image = (gift.image ?? '').trim();
    if (match == null && image.isNotEmpty) {
      for (final g in _knownGifts.values) {
        if ((g.image ?? '').trim() == image) {
          match = g;
          break;
        }
      }
    }
    if (match == null) {
      final catalog = SessionManager.instance.getSettings()?.gifts ?? [];
      if (gift.id != null) {
        for (final g in catalog) {
          if (g.id == gift.id) {
            match = g;
            break;
          }
        }
      }
      if (match == null && image.isNotEmpty) {
        for (final g in catalog) {
          if ((g.image ?? '').trim() == image) {
            match = g;
            break;
          }
        }
      }
    }
    if (match == null) return gift;
    rememberAll([match]);
    return Gift(
      id: match.id ?? gift.id,
      categoryId: match.categoryId,
      coinPrice: gift.coinPrice ?? match.coinPrice,
      title: match.title ?? gift.title,
      image: image.isNotEmpty ? gift.image : match.image,
      sound: ((gift.sound ?? '').trim().isNotEmpty) ? gift.sound : match.sound,
      isFullscreen:
          gift.isFullscreen != 0 ? gift.isFullscreen : match.isFullscreen,
    );
  }

  static void _removeGiftOverlay() {
    final entry = _giftOverlay;
    _giftOverlay = null;
    _giftDialogOpen = false;
    entry?.remove();
    LiveKitRoomController.bumpAllRenderers();
  }

  static void showAnimationDialog(Gift gift) {
    final ctx = Get.overlayContext ?? Get.context;
    if (ctx == null) return;
    final resolved = _hydrateFromCatalog(gift);
    if ((resolved.image ?? '').trim().isEmpty) return;
    GiftManager.rememberAll([resolved]);

    if (_giftOverlay != null || _giftDialogOpen) {
      _removeGiftOverlay();
    }

    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => IgnorePointer(
        child: SendGiftDialog(
          gift: resolved,
          onFinished: () {
            if (_giftOverlay == entry) {
              _removeGiftOverlay();
            }
          },
        ),
      ),
    );
    _giftOverlay = entry;
    _giftDialogOpen = true;
    HapticManager.shared.light();
    final overlay = Navigator.of(ctx, rootNavigator: true).overlay ??
        Overlay.of(ctx, rootOverlay: true);
    overlay.insert(entry);
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
