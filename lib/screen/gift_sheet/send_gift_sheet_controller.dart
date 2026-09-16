import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krimson/common/controller/base_controller.dart';
import 'package:krimson/common/functions/debounce_action.dart';
import 'package:krimson/common/manager/app_role.dart';
import 'package:krimson/common/manager/coin_gate.dart';
import 'package:krimson/common/manager/firebase_notification_manager.dart';
import 'package:krimson/common/manager/gift_media_cache.dart';
import 'package:krimson/common/manager/guest_gate.dart';
import 'package:krimson/common/manager/host_share.dart';
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

  GiftSheetMode mode;
  ValueChanged<Gift?>? onBoost;

  SendGiftSheetController(this.giftType, this.userId, this.liveUsers,
      {this.giftSource,
      this.mode = GiftSheetMode.send,
      this.onBoost});

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

    if (mode == GiftSheetMode.pick) {
      Get.back(result: gift);
      return;
    }
    if (mode == GiftSheetMode.boost) {
      onBoost?.call(gift);
      Get.back();
      return;
    }

    final price = gift.coinPrice ?? 0;
    final wallet = (myUser.value?.coinWallet ?? 0).toInt();
    if (wallet < price) {
      CoinGate.ensureEnough(price);
      return;
    }

    sendGift(gift, context);
  }

  void onBoostGeneral() {
    if (mode != GiftSheetMode.boost) return;
    onBoost?.call(null);
    Get.back();
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
      if (g.id == null) continue;
      final existing = _knownGifts[g.id!];
      if (existing == null) {
        _knownGifts[g.id!] = g;
        continue;
      }
      // Settings cache vs catálogo paginado: no borrar miniatura/animación.
      _knownGifts[g.id!] = Gift(
        id: g.id,
        categoryId: g.categoryId ?? existing.categoryId,
        coinPrice: (g.coinPrice ?? 0) > 0 ? g.coinPrice : existing.coinPrice,
        title: (g.title ?? '').trim().isNotEmpty ? g.title : existing.title,
        image: (g.image ?? '').trim().isNotEmpty ? g.image : existing.image,
        thumbnail: (g.thumbnail ?? '').trim().isNotEmpty
            ? g.thumbnail
            : existing.thumbnail,
        sound: (g.sound ?? '').trim().isNotEmpty ? g.sound : existing.sound,
        isFullscreen:
            g.isFullscreen != 0 ? g.isFullscreen : existing.isFullscreen,
      );
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
    await _presentSheet<GiftManager>(
      SendGiftSheet(
        userId: userId,
        giftType: giftType,
        battleViewType: battleViewType,
        streamUsers: streamUsers,
        giftSource: giftSource,
      ),
    ).then((gift) {
      if (gift != null) {
        onCompletion(gift);
      }
    });
  }

  /// Elegir un regalo del catálogo (incentivos, configuración).
  static Future<Gift?> openGiftPicker() {
    return _presentSheet<Gift>(
      const SendGiftSheet(userId: null, mode: GiftSheetMode.pick),
    );
  }

  /// Host: pedir un regalo a la audiencia (LIVE o llamada).
  static Future<void> openGiftBoost({
    required ValueChanged<Gift?> onBoost,
  }) {
    return _presentSheet<void>(
      SendGiftSheet(
        userId: null,
        mode: GiftSheetMode.boost,
        onBoost: onBoost,
      ),
    );
  }

  static Future<T?> _presentSheet<T>(Widget sheet) async {
    if (Get.isRegistered<SendGiftSheetController>()) {
      Get.delete<SendGiftSheetController>(force: true);
    }
    try {
      return await Get.bottomSheet<T>(
        sheet,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
      );
    } finally {
      if (Get.isRegistered<SendGiftSheetController>()) {
        Get.delete<SendGiftSheetController>(force: true);
      }
    }
  }

  /// Miniatura estática para chat / chips. Nunca el GIF o video de animación.
  static String? previewPath({int? giftId, String? fallback}) {
    var known = knownById(giftId);
    var fromKnown = (known?.staticPreview ?? '').trim();
    if (fromKnown.isNotEmpty) return fromKnown;
    if (known == null) {
      rememberAll(SessionManager.instance.getSettings()?.gifts);
      known = knownById(giftId);
      fromKnown = (known?.staticPreview ?? '').trim();
      if (fromKnown.isNotEmpty) return fromKnown;
    }
    final fb = (fallback ?? '').trim();
    if (fb.isEmpty || Gift.isAnimatedAsset(fb)) return null;
    return fb;
  }

  /// Precio que paga el cliente (100%). No usar en UI de streamer.
  static int catalogCoins(int? giftId, {int? fallback, Gift? gift}) {
    if ((gift?.coinPrice ?? 0) > 0) {
      final selected = gift!;
      rememberAll([selected]);
      return selected.coinPrice!;
    }
    final known = knownById(giftId);
    if ((known?.coinPrice ?? 0) > 0) return known!.coinPrice!;
    rememberAll(SessionManager.instance.getSettings()?.gifts);
    final fromSettings = knownById(giftId)?.coinPrice ?? 0;
    if (fromSettings > 0) return fromSettings;
    return fallback ?? 0;
  }

  /// Precio visible: streamer ve su %; cliente ve el 100%.
  static int visibleCoins(int fullPrice) => HostShare.displayCoins(fullPrice);

  static int visibleCatalogCoins(int? giftId, {int? fallback, Gift? gift}) {
    return visibleCoins(catalogCoins(giftId, fallback: fallback, gift: gift));
  }

  /// Chat LIVE: la host ve su comisión; la audiencia ve lo que paga el cliente.
  static int liveChatCoins(int? giftId, {int? fallback, required bool isHost}) {
    final full = catalogCoins(giftId, fallback: fallback);
    if (isHost) return HostShare.hostCoins(full);
    return full;
  }

  static String _labelWithCoins(String? text, int coins) {
    final raw = (text ?? '').trim();
    final stripped = raw
        .replaceAll(RegExp(r'\s*\(\d+(\s+[^)]+)?\)\s*$'), '')
        .trim();
    if (coins <= 0) {
      return raw.isEmpty ? LKey.sendMeGifts.tr : raw;
    }
    if (stripped.isEmpty) {
      return '${LKey.giftMe.tr} ($coins ${LKey.coins.tr})';
    }
    return '$stripped ($coins ${LKey.coins.tr})';
  }

  /// Texto en el canal (precio 100% para cobro).
  static String boostWireLabel(String? text, int? giftId,
      {int? fallbackCoins, Gift? gift}) {
    return _labelWithCoins(
      text,
      catalogCoins(giftId, fallback: fallbackCoins, gift: gift),
    );
  }

  /// Texto visible: streamer ve su %; cliente ve el 100%.
  static String boostLabel(String? text, int? giftId,
      {int? fallbackCoins, Gift? gift}) {
    return _labelWithCoins(
      text,
      visibleCatalogCoins(giftId, fallback: fallbackCoins, gift: gift),
    );
  }

  /// Pedido de gift en el chat LIVE: host ve su parte; audiencia el precio cliente.
  static String liveBoostLabel(String? text, int? giftId,
      {int? fallbackCoins, required bool isHost}) {
    return _labelWithCoins(
      text,
      liveChatCoins(giftId, fallback: fallbackCoins, isHost: isHost),
    );
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
    final matchImage = (match.image ?? '').trim();
    return Gift(
      id: match.id ?? gift.id,
      categoryId: match.categoryId,
      coinPrice: gift.coinPrice ?? match.coinPrice,
      title: match.title ?? gift.title,
      image: matchImage.isNotEmpty ? match.image : gift.image,
      thumbnail: ((gift.thumbnail ?? '').trim().isNotEmpty)
          ? gift.thumbnail
          : match.thumbnail,
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
