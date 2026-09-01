import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krimson/common/controller/base_controller.dart';
import 'package:krimson/common/controller/firebase_firestore_controller.dart';
import 'package:krimson/common/manager/firebase_app_helper.dart';
import 'package:krimson/common/manager/session_manager.dart';
import 'package:krimson/common/service/api/live_session_service.dart';
import 'package:krimson/languages/languages_keys.dart';
import 'package:krimson/model/livestream/livestream.dart';
import 'package:krimson/screen/live_stream/livestream_screen/audience/live_stream_audience_screen.dart';
import 'package:krimson/screen/live_stream/livestream_screen/host/livestream_host_screen.dart';
import 'package:krimson/utilities/const_res.dart';
import 'package:krimson/utilities/poll_intervals.dart';
import 'package:krimson/utilities/firebase_const.dart';

/// Descubrimiento: solo lives en transmisión + búsqueda.
class LiveActiveDiscoveryController extends BaseController {
  FirebaseFirestore get _db => FirebaseFirestore.instance;

  final RxList<Livestream> _allLives = <Livestream>[].obs;
  final RxList<Livestream> livestreams = <Livestream>[].obs;
  final RxBool showSearch = false.obs;
  final TextEditingController searchController = TextEditingController();
  final RxString searchQuery = ''.obs;

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

  void _applyFilter() {
    final q = searchQuery.value.trim().toLowerCase();
    if (q.isEmpty) {
      livestreams.assignAll(_allLives);
      return;
    }

    livestreams.assignAll(_allLives.where((s) {
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
    }));
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
