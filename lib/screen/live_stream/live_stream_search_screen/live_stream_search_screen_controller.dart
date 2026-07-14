import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krimson/common/controller/base_controller.dart';
import 'package:krimson/common/extensions/user_extension.dart';
import 'package:krimson/common/manager/session_manager.dart';
import 'package:krimson/common/service/api/user_service.dart';
import 'package:krimson/languages/languages_keys.dart';
import 'package:krimson/model/general/settings_model.dart';
import 'package:krimson/model/livestream/livestream.dart';
import 'package:krimson/model/livestream/livestream_user_state.dart';
import 'package:krimson/model/user_model/user_model.dart';
import 'package:krimson/screen/live_stream/livestream_screen/audience/live_stream_audience_screen.dart';
import 'package:krimson/screen/live_stream/livestream_screen/host/livestream_host_screen.dart';
import 'package:krimson/screen/live_stream/livestream_screen/widget/live_host_panel.dart';
import 'package:krimson/utilities/const_res.dart';
import 'package:krimson/utilities/firebase_const.dart';
import 'package:krimson/utilities/text_style_custom.dart';
import 'package:krimson/utilities/theme_res.dart';

class LiveStreamSearchScreenController extends BaseController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final RxList<Livestream> livestreams = <Livestream>[].obs;
  final RxBool isBootstrapping = true.obs;

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _sub;
  StreamSubscription<List<ConnectivityResult>>? _netSub;
  final TextEditingController titleController = TextEditingController();

  /// Preferencias pre-live (beauty / invite / red).
  final RxBool beautyOn = false.obs;
  final RxDouble whiten = 50.0.obs;
  final RxDouble rosy = 40.0.obs;
  final RxDouble smooth = 55.0.obs;
  final RxDouble sharpen = 35.0.obs;
  final RxString networkLabel = LKey.networkWifi.obs;
  final RxList<User> inviteCandidates = <User>[].obs;
  final RxSet<int> invitedIds = <int>{}.obs;
  final RxBool inviteLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    _listenNetwork();
    _bootstrap();
  }

  void _listenNetwork() {
    final connectivity = Connectivity();
    connectivity.checkConnectivity().then((r) {
      networkLabel.value = networkLabelFromResults(r);
    });
    _netSub = connectivity.onConnectivityChanged.listen((r) {
      networkLabel.value = networkLabelFromResults(r);
    });
  }

  Future<void> _bootstrap() async {
    try {
      await syncDummyLivesToFirestore();
      _listenActiveLives();
    } catch (e) {
      showSnackBar(e.toString());
    } finally {
      isBootstrapping.value = false;
    }
  }

  /// Publica en Firestore los dummy lives del admin para que aparezcan en la lista.
  Future<void> syncDummyLivesToFirestore() async {
    if (!useFirebase) return;
    final settings = SessionManager.instance.getSettings();
    if ((settings?.liveDummyShow ?? 0) != 1) return;

    final dummyLives = settings?.dummyLives ?? [];
    for (final dummy in dummyLives) {
      if ((dummy.status ?? 0) != 1 || dummy.userId == null) continue;
      final roomId = dummy.userId.toString();
      final stream = Livestream(
        description: (dummy.title ?? '').trim().isEmpty
            ? 'Live'
            : dummy.title!.trim(),
        isRestrictToJoin: 0,
        type: LivestreamType.dummy,
        watchingCount: 0,
        roomID: roomId,
        hostViewID: -1,
        likeCount: 0,
        coHostIds: [],
        hostId: dummy.userId,
        createdAt: DateTime.now().millisecondsSinceEpoch,
        battleType: BattleType.initiate,
        isDummyLive: 1,
        dummyUserLink: dummy.link ?? '',
      );
      await _db
          .collection(FirebaseConst.liveStreams)
          .doc(roomId)
          .set(stream.toJson(), SetOptions(merge: true));
    }
  }

  void _listenActiveLives() {
    if (!useFirebase) {
      // Sin Firebase: muestra dummy lives locales desde settings.
      final settings = SessionManager.instance.getSettings();
      final list = <Livestream>[];
      if ((settings?.liveDummyShow ?? 0) == 1) {
        for (final dummy in settings?.dummyLives ?? <DummyLive>[]) {
          if ((dummy.status ?? 0) != 1) continue;
          list.add(Livestream(
            description: dummy.title ?? 'Live',
            isRestrictToJoin: 0,
            type: LivestreamType.dummy,
            watchingCount: 0,
            roomID: '${dummy.userId}',
            hostViewID: -1,
            likeCount: 0,
            coHostIds: [],
            hostId: dummy.userId,
            createdAt: DateTime.now().millisecondsSinceEpoch,
            battleType: BattleType.initiate,
            isDummyLive: 1,
            dummyUserLink: dummy.link ?? '',
          ));
        }
      }
      livestreams.assignAll(list);
      return;
    }

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
            .toList();
        items.sort((a, b) => (b.createdAt ?? 0).compareTo(a.createdAt ?? 0));
        livestreams.assignAll(items);
      },
      onError: (e) => showSnackBar(e.toString()),
    );
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

  Future<void> refreshList() async {
    isBootstrapping.value = true;
    await _bootstrap();
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

  Future<void> onTapGoLive() async {
    final user = SessionManager.instance.getUser();
    final settings = SessionManager.instance.getSettings();
    if (user == null) {
      showSnackBar(LKey.somethingWentWrong.tr);
      return;
    }

    // Perfil usado como dummy live en admin
    final dummyConflict = (settings?.dummyLives ?? []).any(
      (d) => d.userId == user.id && (d.status ?? 0) == 1,
    );
    if (dummyConflict) {
      showSnackBar(LKey.yourProfileIsAlreadyInUseForDummyEtc.tr);
      return;
    }

    if (kIsWeb) {
      // En Web no hay cámara Zego nativa; aún así permitimos abrir host en modo demo.
      showSnackBar(
        'Live publishing on Web is limited. Prefer Android/iOS for full camera.',
        second: 3,
      );
    }

    titleController.clear();
    invitedIds.clear();
    inviteCandidates.clear();
    final ok = await Get.bottomSheet<bool>(
      _StartLiveSheet(controller: this),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
    if (ok == true) {
      await _startLive(user);
    }
  }

  void openPreLiveBeauty() {
    openLiveBeautySheet(
      liveController: null,
      whiten: whiten,
      rosy: rosy,
      smooth: smooth,
      sharpen: sharpen,
      beautyOn: beautyOn,
      onApply: () async {},
    );
  }

  Future<void> openPreLiveInvite() async {
    await _loadInviteCandidates();
    openLiveInviteSheet(
      candidates: inviteCandidates,
      loading: inviteLoading,
      selectedIds: invitedIds,
      onInvite: (user) async {
        final id = user.id;
        if (id == null) return;
        invitedIds.add(id);
        inviteCandidates.refresh();
        showSnackBar(LKey.friendInvited.tr);
      },
    );
  }

  Future<void> _loadInviteCandidates() async {
    if (inviteCandidates.isNotEmpty) return;
    inviteLoading.value = true;
    try {
      final meId = SessionManager.instance.getUserID();
      final following = await UserService.instance.fetchMyFollowing(
        lastItemId: -1,
        userId: meId,
      );
      inviteCandidates.assignAll(
        following.map((e) => e.toUser).whereType<User>().toList(),
      );
      if (inviteCandidates.isEmpty) {
        final followers = await UserService.instance.fetchMyFollowers(
          lastItemId: -1,
          userId: meId,
        );
        inviteCandidates.assignAll(
          followers.map((e) => e.fromUser).whereType<User>().toList(),
        );
      }
    } catch (e) {
      showSnackBar(e.toString());
    } finally {
      inviteLoading.value = false;
    }
  }

  Future<void> _startLive(User user) async {
    final title = titleController.text.trim();
    if (title.isEmpty) {
      showSnackBar(LKey.enterLiveStreamTitle.tr);
      return;
    }

    showLoader();
    try {
      final now = DateTime.now().millisecondsSinceEpoch;
      final coHosts = invitedIds.toList();
      final stream = user.livestream(
        type: LivestreamType.livestream,
        time: now,
        description: title,
        restrictToJoin: 0,
        isDummyLive: 0,
        coHostIds: coHosts,
      );
      final hostState = user.streamState(
        stateType: LivestreamUserType.host,
        time: now,
      )..user = user.appUser;

      if (useFirebase) {
        final roomRef =
            _db.collection(FirebaseConst.liveStreams).doc(stream.roomID);
        await roomRef.set(stream.toJson());
        await roomRef
            .collection(FirebaseConst.userState)
            .doc('${user.id}')
            .set(hostState.toJson());

        for (final coHostId in coHosts) {
          final invitee = inviteCandidates
              .firstWhereOrNull((u) => u.id == coHostId);
          final state = LivestreamUserState(
            type: LivestreamUserType.invited,
            userId: coHostId,
            liveCoin: 0,
            currentBattleCoin: 0,
            totalBattleCoin: 0,
            followersGained: [],
            joinStreamTime: now,
            user: invitee?.appUser,
          );
          await roomRef
              .collection(FirebaseConst.userState)
              .doc('$coHostId')
              .set(state.toJson(), SetOptions(merge: true));
        }
      }

      stopLoader();
      Get.to(() => LivestreamHostScreen(
            isHost: true,
            livestream: stream,
            initialBeautyOn: beautyOn.value,
            initialWhiten: whiten.value,
            initialRosy: rosy.value,
            initialSmooth: smooth.value,
            initialSharpen: sharpen.value,
          ));
    } catch (e) {
      stopLoader();
      showSnackBar(e.toString());
    }
  }

  @override
  void onClose() {
    _sub?.cancel();
    _netSub?.cancel();
    titleController.dispose();
    super.onClose();
  }
}

class _StartLiveSheet extends StatelessWidget {
  final LiveStreamSearchScreenController controller;

  const _StartLiveSheet({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Container(
        decoration: BoxDecoration(
          color: whitePure(context),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: bgGrey(context),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              Text(
                LKey.goLive.tr,
                textAlign: TextAlign.center,
                style: TextStyleCustom.unboundedSemiBold600(
                  color: textDarkGrey(context),
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller.titleController,
                autofocus: true,
                maxLength: 80,
                decoration: InputDecoration(
                  hintText: LKey.enterLiveStreamTitle.tr,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  counterText: '',
                ),
              ),
              Obx(() {
                if (controller.invitedIds.isEmpty) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    '${LKey.invited.tr}: ${controller.invitedIds.length}',
                    textAlign: TextAlign.center,
                    style: TextStyleCustom.outFitMedium500(
                      color: themeAccentSolid(context),
                      fontSize: 13,
                    ),
                  ),
                );
              }),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Get.back(result: true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: themeColor(context),
                  foregroundColor: whitePure(context),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(LKey.startLive.tr),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
