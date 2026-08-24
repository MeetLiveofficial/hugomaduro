import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krimson/common/controller/base_controller.dart';
import 'package:krimson/common/manager/app_role.dart';
import 'package:krimson/common/manager/call_availability.dart';
import 'package:krimson/common/manager/coin_gate.dart';
import 'package:krimson/common/manager/guest_gate.dart';
import 'package:krimson/common/manager/logger.dart';
import 'package:krimson/common/manager/session_manager.dart';
import 'package:krimson/common/service/api/call_service.dart';
import 'package:krimson/common/service/api/live_session_service.dart';
import 'package:krimson/common/service/api/user_service.dart';
import 'package:krimson/common/service/navigation/navigate_with_controller.dart';
import 'package:krimson/languages/languages_keys.dart';
import 'package:krimson/model/general/countries_model.dart';
import 'package:krimson/model/general/settings_model.dart';
import 'package:krimson/model/user_model/user_model.dart';
import 'package:krimson/screen/call_screen/outgoing_call_screen.dart';
import 'package:krimson/screen/live_stream/livestream_screen/audience/live_stream_audience_screen.dart';
import 'package:krimson/screen/match_screen/match_preview_screen.dart';
import 'package:krimson/screen/message_screen/widget/chat_conversation_user_card.dart';
import 'package:krimson/utilities/app_res.dart';
import 'package:krimson/utilities/asset_res.dart';

class ExploreScreenController extends BaseController {
  final RxList<User> streamers = <User>[].obs;
  final RxList<Country> countries = <Country>[].obs;
  final RxList<Language> languages = <Language>[].obs;

  final TextEditingController searchController = TextEditingController();
  final ScrollController scrollController = ScrollController();

  final RxnString selectedCountryCode = RxnString();
  final RxnString selectedCountryName = RxnString();
  final RxnString selectedLanguageCode = RxnString();
  final RxString searchText = ''.obs;
  /// `all` | `live` | `active`
  final RxString presenceFilter = 'all'.obs;

  final RxBool isLoadingMore = false.obs;
  final RxBool hasMore = true.obs;
  final RxBool isMatching = false.obs;

  Timer? _debounce;
  bool _started = false;

  @override
  void onInit() {
    super.onInit();
    scrollController.addListener(_onScroll);
    _bootstrap();
  }

  @override
  void onClose() {
    _debounce?.cancel();
    searchController.dispose();
    scrollController.dispose();
    super.onClose();
  }

  Future<void> _bootstrap() async {
    await Future.wait([_loadCountries(), _loadLanguages()]);
    await refreshList();
    _started = true;
  }

  Future<void> _loadCountries() async {
    try {
      final list = await parseCountries(filePath: AssetRes.countriesCSV);
      list.sort((a, b) => a.countryName.compareTo(b.countryName));
      countries.assignAll(list);
    } catch (e) {
      Loggers.error('explore countries: $e');
    }
  }

  Future<void> _loadLanguages() async {
    final list = (SessionManager.instance.getSettings()?.languages ?? [])
        .where((l) => (l.status ?? 0) == 1 && (l.code ?? '').isNotEmpty)
        .toList();
    languages.assignAll(list);
  }

  void onSearchChanged(String value) {
    searchText.value = value;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (_started) refreshList();
    });
  }

  void selectCountry(Country? country) {
    if (country == null) {
      selectedCountryCode.value = null;
      selectedCountryName.value = null;
    } else {
      selectedCountryCode.value = country.countryCode;
      selectedCountryName.value = country.countryName;
    }
    refreshList();
  }

  void selectLanguage(Language? lang) {
    selectedLanguageCode.value =
        (lang?.code ?? '').trim().isEmpty ? null : lang!.code!.trim();
    refreshList();
  }

  void selectPresence(String value) {
    final next = value.trim().toLowerCase();
    if (next != 'all' && next != 'live' && next != 'active') return;
    // Streamer → clientes: no tiene sentido "En vivo".
    if (AppRole.isStreamer() && next == 'live') return;
    if (presenceFilter.value == next) return;
    presenceFilter.value = next;
    refreshList();
  }

  void clearFilters() {
    selectedCountryCode.value = null;
    selectedCountryName.value = null;
    selectedLanguageCode.value = null;
    presenceFilter.value = 'all';
    searchController.clear();
    searchText.value = '';
    refreshList();
  }

  void _onScroll() {
    if (!scrollController.hasClients || isLoadingMore.value || !hasMore.value) {
      return;
    }
    if (scrollController.position.pixels >=
        scrollController.position.maxScrollExtent - 240) {
      loadMore();
    }
  }

  Future<void> refreshList() async {
    if (AppRole.isStreamer() && presenceFilter.value == 'live') {
      presenceFilter.value = 'all';
    }
    isLoading.value = true;
    hasMore.value = true;
    try {
      final list = await UserService.instance.exploreStreamers(
        limit: AppRes.paginationLimit,
        offset: 0,
        keyWord: searchController.text.trim(),
        country: selectedCountryName.value,
        countryCode: selectedCountryCode.value,
        appLanguage: selectedLanguageCode.value,
        presence: presenceFilter.value,
      );
      streamers.assignAll(list);
      hasMore.value = list.length >= AppRes.paginationLimit;
    } catch (e) {
      Loggers.error('exploreStreamers: $e');
      streamers.clear();
      showSnackBar(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadMore() async {
    if (isLoadingMore.value || !hasMore.value || streamers.isEmpty) return;
    isLoadingMore.value = true;
    try {
      final list = await UserService.instance.exploreStreamers(
        offset: streamers.length,
        limit: AppRes.paginationLimit,
        keyWord: searchController.text.trim(),
        country: selectedCountryName.value,
        countryCode: selectedCountryCode.value,
        appLanguage: selectedLanguageCode.value,
        presence: presenceFilter.value,
      );
      if (list.isEmpty) {
        hasMore.value = false;
      } else {
        streamers.addAll(list);
        hasMore.value = list.length >= AppRes.paginationLimit;
      }
    } catch (e) {
      Loggers.error('exploreStreamers more: $e');
    } finally {
      isLoadingMore.value = false;
    }
  }

  Future<void> openProfile(User user) async {
    await NavigationService.shared.openProfileScreen(user);
  }

  void openChat(User user) {
    if (GuestGate.block()) return;
    openDirectChatWith(user);
  }

  Future<void> startCall(User user) async {
    if (GuestGate.block()) return;
    // Streamer → cliente: solo mensajes, sin videollamada.
    if (AppRole.isStreamer()) {
      showSnackBar(LKey.clientsOnlyMessages.tr);
      return;
    }
    if (CallAvailability.isLive(user) &&
        !CallAvailability.isWatchingThisLive(user)) {
      await _openLive(user);
      return;
    }
    if (!CallAvailability.canPlaceCall(user)) {
      showSnackBar(
        CallAvailability.blockMessage(user) ??
            LKey.streamerNotReceivingCalls.tr,
      );
      return;
    }
    final cost = CallAvailability.callCost(user);
    if (cost > 0 &&
        !CoinGate.ensureEnough(cost, message: LKey.insufficientCoins.tr)) {
      return;
    }
    Get.to(() => OutgoingCallScreen(callee: user, cost: cost));
  }

  Future<void> _openLive(User user) async {
    final roomId = (user.liveRoomId ?? '${user.id}').trim();
    if (roomId.isEmpty) {
      showSnackBar(LKey.liveNotAvailable.tr);
      return;
    }
    showLoader();
    try {
      final payload =
          await LiveSessionService.instance.fetchSession(roomId: roomId);
      stopLoader();
      final stream = payload?.session;
      if (stream == null) {
        showSnackBar(LKey.liveNotAvailable.tr);
        return;
      }
      Get.to(() =>
          LiveStreamAudienceScreen(isHost: false, livestream: stream));
    } catch (e) {
      stopLoader();
      showSnackBar(e.toString());
    }
  }

  /// Match: el cliente paga entrada y ve preview en vivo; el streamer espera en Match.
  Future<void> startMatch() async {
    if (GuestGate.block()) return;
    if (AppRole.isStreamer()) {
      showSnackBar(LKey.enterMatchToWaitClients.tr);
      return;
    }
    if (isMatching.value) return;
    isMatching.value = true;
    try {
      await CallService.instance.joinMatch();
      final remaining =
          SessionManager.instance.getUser()?.dailyFreeMatchesRemaining ?? 2;
      final cost =
          SessionManager.instance.getSettings()?.matchRandomCoins ?? 50;
      if (remaining <= 0 &&
          cost > 0 &&
          !CoinGate.ensureEnough(
            cost,
            message: LKey.needCoinsToSearchMatch.trParams({'coins': '$cost'}),
          )) {
        return;
      }
      final unlock = await CallService.instance.unlockMatch(mode: 'random');
      final me = SessionManager.instance.getUser();
      if (me != null) {
        me.coinWallet = unlock.coinWallet;
        SessionManager.instance.setUser(me);
      }
      final lang = (selectedLanguageCode.value ?? me?.appLanguage ?? '')
          .trim()
          .toLowerCase();
      final match = await CallService.instance.findMatch(
        appLanguage: lang.isEmpty ? null : lang,
      );
      await Get.to(() => MatchPreviewScreen(initial: match));
    } catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '');
      if (msg.toLowerCase().contains('insufficient')) {
        CoinGate.ensureEnough(999999, message: LKey.insufficientCoins.tr);
      } else if (msg.toLowerCase().contains('no match')) {
        showSnackBar(LKey.noStreamersInMatch.tr);
      } else {
        showSnackBar(msg);
      }
      Loggers.error('startMatch: $e');
    } finally {
      isMatching.value = false;
    }
  }
}
