import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krimson/common/controller/base_controller.dart';
import 'package:krimson/common/controller/firebase_firestore_controller.dart';
import 'package:krimson/common/manager/firebase_app_helper.dart';
import 'package:krimson/common/manager/session_manager.dart';
import 'package:krimson/common/service/api/live_session_service.dart';
import 'package:krimson/common/service/api/user_service.dart';
import 'package:krimson/languages/languages_keys.dart';
import 'package:krimson/model/livestream/livestream.dart';
import 'package:krimson/screen/live_stream/livestream_screen/audience/live_stream_audience_screen.dart';
import 'package:krimson/screen/live_stream/livestream_screen/host/livestream_host_screen.dart';
import 'package:krimson/utilities/const_res.dart';
import 'package:krimson/utilities/poll_intervals.dart';
import 'package:krimson/utilities/firebase_const.dart';

enum LiveBrowseFilter { all, latinas, newest, hot, following }

/// Descubrimiento: solo lives en transmisión + búsqueda.
class LiveActiveDiscoveryController extends BaseController {
  FirebaseFirestore get _db => FirebaseFirestore.instance;

  final RxList<Livestream> _allLives = <Livestream>[].obs;
  final RxList<Livestream> livestreams = <Livestream>[].obs;
  final RxBool showSearch = false.obs;
  final TextEditingController searchController = TextEditingController();
  final RxString searchQuery = ''.obs;
  final Rx<LiveBrowseFilter> browseFilter = LiveBrowseFilter.all.obs;

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _sub;
  Timer? _laravelPoll;

  @override
  void onInit() {
    super.onInit();
    searchController.addListener(() {
      searchQuery.value = searchController.text;
      _applyFilter();
    });
    refreshList();
  }

  void toggleSearch() {
    showSearch.value = !showSearch.value;
    if (!showSearch.value) {
      searchController.clear();
      searchQuery.value = '';
      _applyFilter();
    }
  }

  void setBrowseFilter(LiveBrowseFilter filter) {
    browseFilter.value = filter;
    _applyFilter();
    if (filter == LiveBrowseFilter.following) {
      unawaited(_refreshFollowingIds());
    }
  }

  /// Lives que empezaron en la última hora. All muestra todos.
  static const _newWindow = Duration(minutes: 60);

  static const _latinaCodes = {
    'AR', 'BO', 'BR', 'CL', 'CO', 'CR', 'CU', 'DO', 'EC', 'SV', 'GT', 'HN',
    'MX', 'NI', 'PA', 'PY', 'PE', 'PR', 'UY', 'VE', 'ES',
  };

  static const _latinaNames = [
    'argentina',
    'bolivia',
    'brasil',
    'brazil',
    'chile',
    'colombia',
    'costa rica',
    'cuba',
    'dominican',
    'ecuador',
    'el salvador',
    'españa',
    'spain',
    'guatemala',
    'honduras',
    'méxico',
    'mexico',
    'nicaragua',
    'panamá',
    'panama',
    'paraguay',
    'perú',
    'peru',
    'puerto rico',
    'uruguay',
    'venezuela',
    'latina',
  ];

  int _createdMs(Livestream s) {
    final raw = s.createdAt ?? 0;
    if (raw <= 0) return 0;
    if (raw < 1000000000000) return raw * 1000;
    return raw;
  }

  int _heat(Livestream s) {
    final watch = s.watchingCount ?? 0;
    final likes = s.likeCount ?? 0;
    final gifts = (s.giftSenders ?? []).fold<int>(
      0,
      (sum, gift) => sum + gift.totalCoins,
    );
    return watch * 1000 + likes * 10 + gifts;
  }

  bool _looksLatina(Livestream s) {
    final host = s.hostUser;
    final code = (host?.countryCode ?? '').trim().toUpperCase();
    if (code.isNotEmpty && _latinaCodes.contains(code)) return true;
    final place =
        '${host?.country ?? ''} ${host?.region ?? ''} ${host?.regionName ?? ''}'
            .toLowerCase();
    if (place.trim().isNotEmpty && _latinaNames.any(place.contains)) {
      return true;
    }
    final blob =
        '${s.description ?? ''} ${host?.fullname ?? ''} ${host?.username ?? ''}'
            .toLowerCase();
    return _latinaNames.any(blob.contains);
  }

  Set<int> _followingIds() {
    final raw = SessionManager.instance.getUser()?.followingIds ?? const <int>[];
    return raw.toSet();
  }

  bool _isFollowedHost(Livestream s, Set<int> ids) {
    if (ids.isEmpty) return false;
    final host = s.hostId;
    if (host != null && ids.contains(host)) return true;
    return (s.coHostIds ?? const <int>[]).any(ids.contains);
  }

  Future<void> _refreshFollowingIds() async {
    final me = SessionManager.instance.getUser();
    final id = me?.id;
    if (me == null || id == null) return;
    try {
      final fresh = await UserService.instance.fetchUserDetails(userId: id);
      final ids = fresh?.followingIds;
      if (ids == null) return;
      me.followingIds = ids;
      SessionManager.instance.setUser(me);
      if (browseFilter.value == LiveBrowseFilter.following) {
        _applyFilter();
      }
    } catch (_) {}
  }

  String emptyTitle({required bool searching}) {
    if (searching) return LKey.noData.tr;
    final es = Get.locale?.languageCode == 'es';
    switch (browseFilter.value) {
      case LiveBrowseFilter.latinas:
        return es ? 'Sin lives latinos' : 'No Latina lives';
      case LiveBrowseFilter.newest:
        return es ? 'Sin lives nuevos' : 'No new lives';
      case LiveBrowseFilter.following:
        return es ? 'Nadie que sigues está en vivo' : 'No one you follow is live';
      case LiveBrowseFilter.hot:
      case LiveBrowseFilter.all:
        return LKey.noLivestreamsTitle.tr;
    }
  }

  String emptyDescription({required bool searching}) {
    if (searching) return LKey.searchPageEmptyDescription.tr;
    final es = Get.locale?.languageCode == 'es';
    switch (browseFilter.value) {
      case LiveBrowseFilter.latinas:
        return es
            ? 'Aparecen las streamers cuyo país es de Latinoamérica o España.'
            : 'Shows streamers whose country is in Latin America or Spain.';
      case LiveBrowseFilter.newest:
        return es
            ? 'Solo lives que empezaron en la última hora.'
            : 'Only lives that started in the last hour.';
      case LiveBrowseFilter.following:
        return es
            ? 'Cuando alguien que sigues entre en vivo, aparecerá aquí.'
            : 'When someone you follow goes live, they will show up here.';
      case LiveBrowseFilter.hot:
        return es
            ? 'Ordenados por espectadores, likes y regalos.'
            : 'Sorted by viewers, likes and gifts.';
      case LiveBrowseFilter.all:
        return LKey.noLivestreamsDescription.tr;
    }
  }

  void _applyFilter() {
    final q = searchQuery.value.trim().toLowerCase();
    var list = _allLives.toList();
    if (q.isNotEmpty) {
      list = list.where((s) {
        final title = (s.description ?? '').toLowerCase();
        final host = s.hostUser;
        final name = (host?.fullname ?? '').toLowerCase();
        final username = (host?.username ?? '').toLowerCase();
        String fsName = '';
        String fsUser = '';
        if (Get.isRegistered<FirebaseFirestoreController>() &&
            s.hostId != null) {
          final u = Get.find<FirebaseFirestoreController>()
              .users
              .firstWhereOrNull((e) => e.userId == s.hostId);
          fsName = (u?.fullname ?? '').toLowerCase();
          fsUser = (u?.username ?? '').toLowerCase();
        }
        return title.contains(q) ||
            name.contains(q) ||
            username.contains(q) ||
            fsName.contains(q) ||
            fsUser.contains(q);
      }).toList();
    }

    switch (browseFilter.value) {
      case LiveBrowseFilter.all:
        list.sort((a, b) => _createdMs(b).compareTo(_createdMs(a)));
        break;
      case LiveBrowseFilter.latinas:
        list = list.where(_looksLatina).toList()
          ..sort((a, b) => _createdMs(b).compareTo(_createdMs(a)));
        break;
      case LiveBrowseFilter.newest:
        final cutoff =
            DateTime.now().millisecondsSinceEpoch - _newWindow.inMilliseconds;
        list = list.where((s) => _createdMs(s) >= cutoff).toList()
          ..sort((a, b) => _createdMs(b).compareTo(_createdMs(a)));
        break;
      case LiveBrowseFilter.hot:
        list.sort((a, b) {
          final byHeat = _heat(b).compareTo(_heat(a));
          if (byHeat != 0) return byHeat;
          return _createdMs(b).compareTo(_createdMs(a));
        });
        break;
      case LiveBrowseFilter.following:
        final ids = _followingIds();
        list = list.where((s) => _isFollowedHost(s, ids)).toList()
          ..sort((a, b) => _createdMs(b).compareTo(_createdMs(a)));
        break;
    }

    livestreams.assignAll(list);
  }

  void _setLives(List<Livestream> list) {
    _allLives.assignAll(list);
    _applyFilter();
  }

  Future<void> refreshList() async {
    isLoading.value = true;
    try {
      // Laravel es la fuente de verdad: en PK existen 2 salas (invitador + rival).
      // Firebase a veces solo tiene la del invitador.
      _listenLaravel();
      if (useFirebase) {
        final ok = await FirebaseAppHelper.ensureInitialized();
        if (ok && FirebaseAppHelper.isReady) {
          _listenFirestore();
        }
      }
    } catch (e) {
      showSnackBar(e.toString());
      _setLives([]);
    } finally {
      isLoading.value = false;
    }
  }

  void _listenLaravel() {
    _refreshLaravel(silent: false);
    _laravelPoll?.cancel();
    _laravelPoll = Timer.periodic(PollIntervals.listActive, (_) {
      _refreshLaravel(silent: true);
    });
  }

  List<Livestream> _firebaseCache = const [];

  Future<void> _refreshLaravel({required bool silent}) async {
    try {
      final list = await LiveSessionService.instance.listActive();
      final laravel = list.where((e) => (e.isDummyLive ?? 0) != 1).toList();
      _mergeLives(laravel: laravel, firebase: _firebaseCache);
    } catch (e) {
      if (!silent) showSnackBar('Lives: $e');
    }
  }

  void _listenFirestore() {
    _sub?.cancel();
    _sub = _db.collection(FirebaseConst.liveStreams).snapshots().listen(
      (snap) {
        final items = snap.docs
            .map((d) {
              try {
                return Livestream.fromJson(_safeLiveJson(d.data()));
              } catch (_) {
                return null;
              }
            })
            .whereType<Livestream>()
            .where((e) => (e.roomID ?? '').isNotEmpty)
            .where((e) => (e.isDummyLive ?? 0) != 1)
            .where((e) => e.type != LivestreamType.dummy)
            .toList();
        _firebaseCache = items;
        // Re-merge con el último Laravel (si aún no llegó, al menos muestra FB).
        unawaited(_refreshLaravel(silent: true));
        isLoading.value = false;
      },
      onError: (e) {
        showSnackBar(e.toString());
        isLoading.value = false;
      },
    );
  }

  /// Une salas Laravel + Firebase por room_id (prioriza Laravel / host_user).
  void _mergeLives({
    required List<Livestream> laravel,
    required List<Livestream> firebase,
  }) {
    final byRoom = <String, Livestream>{};
    for (final s in firebase) {
      final id = (s.roomID ?? '').trim();
      if (id.isEmpty) continue;
      byRoom[id] = s;
    }
    for (final s in laravel) {
      final id = (s.roomID ?? '').trim();
      if (id.isEmpty) continue;
      byRoom[id] = s; // Laravel pisa (tiene host_user y estado PK real)
    }
    final items = byRoom.values.toList()
      ..sort((a, b) => (b.createdAt ?? 0).compareTo(a.createdAt ?? 0));
    _setLives(items);
  }

  Map<String, dynamic> _safeLiveJson(Map<String, dynamic> raw) {
    final data = Map<String, dynamic>.from(raw);
    data['co-host_ids'] ??= <dynamic>[];
    data['watching_count'] ??= 0;
    data['like_count'] ??= 0;
    data['is_dummy_live'] ??= 0;
    data['dummy_user_link'] ??= '';
    data['battle_duration'] ??= 5;
    data['type'] ??= LivestreamType.livestream.value;
    data['battle_type'] ??= BattleType.initiate.value;
    return data;
  }

  void openLivestream(Livestream stream) {
    final me = SessionManager.instance.getUser();
    if (me == null) {
      showSnackBar(LKey.somethingWentWrong.tr);
      return;
    }
    if (stream.hostId == me.id) {
      Get.to(() => LivestreamHostScreen(isHost: true, livestream: stream));
    } else {
      Get.to(() => LiveStreamAudienceScreen(isHost: false, livestream: stream));
    }
  }

  @override
  void onClose() {
    _sub?.cancel();
    _laravelPoll?.cancel();
    searchController.dispose();
    super.onClose();
  }
}
