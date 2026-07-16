import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krimson/common/controller/base_controller.dart';
import 'package:krimson/common/manager/livekit_room_controller.dart';
import 'package:krimson/common/manager/session_manager.dart';
import 'package:krimson/common/service/api/live_session_service.dart';
import 'package:krimson/common/service/api/user_service.dart';
import 'package:krimson/languages/languages_keys.dart';
import 'package:krimson/model/livestream/app_user.dart';
import 'package:krimson/model/livestream/livestream.dart';
import 'package:krimson/model/livestream/livestream_user_state.dart';
import 'package:krimson/model/user_model/user_model.dart';
import 'package:krimson/screen/live_stream/livestream_screen/widget/live_host_panel.dart';
import 'package:krimson/utilities/const_res.dart';
import 'package:krimson/utilities/firebase_const.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:video_player/video_player.dart';

class LivestreamScreenController extends BaseController {
  final bool isHost;
  final Livestream livestream;

  LivestreamScreenController({
    required this.isHost,
    required this.livestream,
  });

  Rx<AppUser?> selectedGiftUser = Rx<AppUser?>(null);
  final RxBool isEnding = false.obs;
  final RxBool mediaReady = false.obs;
  final RxString statusMessage = ''.obs;

  final RxString networkLabel = LKey.networkWifi.obs;
  final RxBool beautyOn = false.obs;
  final RxDouble whiten = 50.0.obs;
  final RxDouble rosy = 40.0.obs;
  final RxDouble smooth = 55.0.obs;
  final RxDouble sharpen = 35.0.obs;
  final RxSet<int> invitedIds = <int>{}.obs;
  final RxList<User> inviteCandidates = <User>[].obs;
  final RxBool inviteLoading = false.obs;
  bool beautyPrefsApplied = false;

  StreamSubscription<List<ConnectivityResult>>? _netSub;

  VideoPlayerController? dummyPlayer;

  /// A/V LiveKit (null en dummy / web).
  LiveKitRoomController? liveKit;

  String get roomId => livestream.roomID ?? '${livestream.hostId}';
  bool get isDummy => (livestream.isDummyLive ?? 0) == 1;

  LocalParticipant? get localParticipant => liveKit?.localParticipant.value;
  List<RemoteParticipant> get remoteParticipants =>
      liveKit?.remoteParticipants.toList() ?? const [];

  @override
  void onInit() {
    super.onInit();
    selectedGiftUser.value = livestream.hostUser;
    invitedIds.addAll(livestream.coHostIds ?? []);
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
    if (isDummy) {
      statusMessage.value = 'Playing dummy live…';
      await _startDummyPlayback();
      return;
    }

    if (kIsWeb) {
      statusMessage.value =
          'Live camera/stream is limited on Web. Use Android/iOS for full live.';
      mediaReady.value = true;
      return;
    }

    try {
      statusMessage.value = isHost ? 'Starting live…' : 'Joining live…';
      await _joinLiveKit();
      mediaReady.value = true;
      statusMessage.value = '';
    } catch (e) {
      statusMessage.value = e.toString();
      mediaReady.value = true;
      showSnackBar(e.toString());
    }
  }

  Future<void> _startDummyPlayback() async {
    final url = (livestream.dummyUserLink ?? '').trim();
    if (url.isEmpty) {
      statusMessage.value = 'Dummy live has no video link.';
      mediaReady.value = true;
      return;
    }
    try {
      dummyPlayer = VideoPlayerController.networkUrl(Uri.parse(url));
      await dummyPlayer!.initialize();
      await dummyPlayer!.setLooping(true);
      await dummyPlayer!.play();
      mediaReady.value = true;
      statusMessage.value = '';
      update();
    } catch (e) {
      statusMessage.value = e.toString();
      mediaReady.value = true;
      showSnackBar(e.toString());
    }
  }

  Future<void> _joinLiveKit() async {
    final me = SessionManager.instance.getUser();
    if (me == null) return;

    final tag = 'lk_live_$roomId';
    liveKit = Get.put(LiveKitRoomController(), tag: tag);

    // Propagar status del room hacia la UI del live.
    ever(liveKit!.statusMessage, (msg) {
      if (msg.isNotEmpty) {
        statusMessage.value = msg;
      }
    });
    ever(liveKit!.mediaRevision, (_) => update());

    await liveKit!.connect(
      roomName: roomId,
      identity: '${me.id}',
      name: me.fullname ?? me.username ?? 'user',
      publishCamera: isHost,
      publishMicrophone: isHost,
      wsUrl: liveKitWsUrl,
    );

    if (!isHost) {
      await _bumpWatching(1);
      await _saveAudienceState();
    }
    update();
  }

  /// Beauty effects eran nativos de Zego; LiveKit no los incluye.
  /// Se mantienen prefs de UI por compatibilidad (hooks futuros / DeepAR).
  Future<void> applyBeauty() async {
    if (kIsWeb || isDummy) return;
    // No-op: integrar procesador de video externo si se requiere.
  }

  void openBeauty() {
    openLiveBeautySheet(
      liveController: this,
      whiten: whiten,
      rosy: rosy,
      smooth: smooth,
      sharpen: sharpen,
      beautyOn: beautyOn,
      onApply: applyBeauty,
    );
  }

  Future<void> openInvite() async {
    await _loadInviteCandidates();
    openLiveInviteSheet(
      candidates: inviteCandidates,
      loading: inviteLoading,
      selectedIds: invitedIds,
      onInvite: inviteUser,
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

  Future<void> inviteUser(User user) async {
    final id = user.id;
    if (id == null) return;
    invitedIds.add(id);
    inviteCandidates.refresh();

    if (useFirebase) {
      final now = DateTime.now().millisecondsSinceEpoch;
      final state = LivestreamUserState(
        type: LivestreamUserType.invited,
        userId: id,
        liveCoin: 0,
        currentBattleCoin: 0,
        totalBattleCoin: 0,
        followersGained: [],
        joinStreamTime: now,
      );
      final roomRef = FirebaseFirestore.instance
          .collection(FirebaseConst.liveStreams)
          .doc(roomId);
      await roomRef
          .collection(FirebaseConst.userState)
          .doc('$id')
          .set(state.toJson(), SetOptions(merge: true));
      await roomRef.set({
        'co-host_ids': invitedIds.toList(),
      }, SetOptions(merge: true));
    }

    showSnackBar(LKey.friendInvited.tr);
  }

  Future<void> _saveAudienceState() async {
    if (!useFirebase) return;
    final me = SessionManager.instance.getUser();
    if (me == null) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    final state = LivestreamUserState(
      type: LivestreamUserType.audience,
      userId: me.id ?? -1,
      liveCoin: 0,
      currentBattleCoin: 0,
      totalBattleCoin: 0,
      followersGained: [],
      joinStreamTime: now,
    );
    await FirebaseFirestore.instance
        .collection(FirebaseConst.liveStreams)
        .doc(roomId)
        .collection(FirebaseConst.userState)
        .doc('${me.id}')
        .set(state.toJson(), SetOptions(merge: true));
  }

  Future<void> _bumpWatching(int delta) async {
    if (!useFirebase) return;
    final ref =
        FirebaseFirestore.instance.collection(FirebaseConst.liveStreams).doc(roomId);
    await FirebaseFirestore.instance.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) return;
      final current = (snap.data()?['watching_count'] as num?)?.toInt() ?? 0;
      tx.update(ref, {'watching_count': (current + delta).clamp(0, 999999)});
    });
  }

  Future<void> setCameraEnabled(bool enabled) async {
    await liveKit?.setCameraEnabled(enabled);
  }

  Future<void> setMicrophoneEnabled(bool enabled) async {
    await liveKit?.setMicrophoneEnabled(enabled);
  }

  Future<void> confirmExit(BuildContext context) async {
    if (isEnding.value) {
      await _popLiveUi();
      return;
    }

    final leave = await Get.dialog<bool>(
      AlertDialog(
        title: Text(LKey.exitLiveStreamTitle.tr),
        content: Text(LKey.exitLiveStreamDescription.tr),
        actions: [
          TextButton(
              onPressed: () => Get.back(result: false),
              child: Text(LKey.cancel.tr)),
          TextButton(
              onPressed: () => Get.back(result: true),
              child: Text(LKey.yes.tr)),
        ],
      ),
      barrierDismissible: true,
    );
    if (leave == true) {
      await endOrLeave();
    }
  }

  Future<void> endOrLeave() async {
    if (isEnding.value) {
      await _popLiveUi();
      return;
    }
    isEnding.value = true;
    // Cerrar UI primero: si LiveKit/API se cuelgan, el usuario ya pudo salir.
    await _popLiveUi();
    try {
      await _cleanupMedia().timeout(const Duration(seconds: 8));

      if (!isDummy) {
        try {
          await LiveSessionService.instance
              .leave(roomId: roomId)
              .timeout(const Duration(seconds: 5));
        } catch (_) {}
      }

      if (isHost && !isDummy && useFirebase) {
        try {
          await FirebaseFirestore.instance
              .collection(FirebaseConst.liveStreams)
              .doc(roomId)
              .delete();
        } catch (_) {}
      }
    } catch (e) {
      statusMessage.value = e.toString();
    } finally {
      isEnding.value = false;
    }
  }

  Future<void> _cleanupMedia() async {
    if (!isDummy && !kIsWeb) {
      if (!isHost) {
        await _bumpWatching(-1);
      }
      final tag = 'lk_live_$roomId';
      if (liveKit != null) {
        await liveKit!.disconnect();
        if (Get.isRegistered<LiveKitRoomController>(tag: tag)) {
          Get.delete<LiveKitRoomController>(tag: tag);
        }
        liveKit = null;
      }
    }

    try {
      await dummyPlayer?.pause();
      await dummyPlayer?.dispose();
    } catch (_) {}
    dummyPlayer = null;
  }

  Future<void> _popLiveUi() async {
    // PopScope(canPop: false) hace que Navigator.canPop() sea false;
    // igual se puede hacer pop programático para salir del live.
    for (var i = 0; i < 3; i++) {
      if (Get.isDialogOpen == true || Get.isBottomSheetOpen == true) {
        Get.back();
        await Future.delayed(const Duration(milliseconds: 16));
      } else {
        break;
      }
    }
    final context = Get.context;
    if (context != null && context.mounted) {
      Navigator.of(context).pop();
      return;
    }
    Get.back(closeOverlays: true);
  }

  @override
  void onClose() {
    _netSub?.cancel();
    dummyPlayer?.dispose();
    final tag = 'lk_live_$roomId';
    if (Get.isRegistered<LiveKitRoomController>(tag: tag)) {
      Get.delete<LiveKitRoomController>(tag: tag);
    }
    super.onClose();
  }
}
