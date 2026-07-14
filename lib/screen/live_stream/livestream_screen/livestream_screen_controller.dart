import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:krimson/common/controller/base_controller.dart';
import 'package:krimson/common/manager/session_manager.dart';
import 'package:krimson/common/service/api/user_service.dart';
import 'package:krimson/languages/languages_keys.dart';
import 'package:krimson/model/livestream/app_user.dart';
import 'package:krimson/model/livestream/livestream.dart';
import 'package:krimson/model/livestream/livestream_user_state.dart';
import 'package:krimson/model/user_model/user_model.dart';
import 'package:krimson/screen/live_stream/livestream_screen/widget/live_host_panel.dart';
import 'package:krimson/utilities/const_res.dart';
import 'package:krimson/utilities/firebase_const.dart';
import 'package:video_player/video_player.dart';
import 'package:zego_express_engine/zego_express_engine.dart';

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
  bool _effectsEnvReady = false;

  VideoPlayerController? dummyPlayer;
  Widget? zegoView;
  int? localViewId;

  String get roomId => livestream.roomID ?? '${livestream.hostId}';
  String get streamId => 'stream_$roomId';
  bool get isDummy => (livestream.isDummyLive ?? 0) == 1;

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
      await _joinZego();
      mediaReady.value = true;
      statusMessage.value = '';
    } on MissingPluginException {
      statusMessage.value = 'Zego plugin not available on this platform.';
      mediaReady.value = true;
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

  Future<void> _joinZego() async {
    final me = SessionManager.instance.getUser();
    if (me == null) return;

    final zegoUser = ZegoUser('${me.id}', me.fullname ?? me.username ?? 'user');
    await ZegoExpressEngine.instance.loginRoom(
      roomId,
      zegoUser,
      config: ZegoRoomConfig.defaultConfig()..isUserStatusNotify = true,
    );

    if (isHost) {
      zegoView = await ZegoExpressEngine.instance.createCanvasView((id) async {
        localViewId = id;
        await ZegoExpressEngine.instance.startPreview(
          canvas: ZegoCanvas(id, viewMode: ZegoViewMode.AspectFill),
        );
        await ZegoExpressEngine.instance.startPublishingStream(streamId);
        await applyBeauty();
        update();
      });
      update();
    } else {
      zegoView = await ZegoExpressEngine.instance.createCanvasView((id) async {
        localViewId = id;
        await ZegoExpressEngine.instance.startPlayingStream(
          streamId,
          canvas: ZegoCanvas(id, viewMode: ZegoViewMode.AspectFill),
        );
        update();
      });
      await _bumpWatching(1);
      await _saveAudienceState();
      update();
    }
  }

  Future<void> applyBeauty() async {
    if (kIsWeb || isDummy) return;
    try {
      if (!_effectsEnvReady) {
        await ZegoExpressEngine.instance.startEffectsEnv();
        _effectsEnvReady = true;
      }
      await ZegoExpressEngine.instance.enableEffectsBeauty(beautyOn.value);
      if (beautyOn.value) {
        await ZegoExpressEngine.instance.setEffectsBeautyParam(
          ZegoEffectsBeautyParam(
            whiten.value.round(),
            rosy.value.round(),
            smooth.value.round(),
            sharpen.value.round(),
          ),
        );
      }
    } catch (e) {
      statusMessage.value = e.toString();
    }
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

  Future<void> confirmExit(BuildContext context) async {
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
              child: const Text('Yes')),
        ],
      ),
    );
    if (leave == true) {
      await endOrLeave();
    }
  }

  Future<void> endOrLeave() async {
    if (isEnding.value) return;
    isEnding.value = true;
    try {
      if (!isDummy && !kIsWeb) {
        if (isHost) {
          await ZegoExpressEngine.instance.stopPublishingStream();
          await ZegoExpressEngine.instance.stopPreview();
        } else {
          await ZegoExpressEngine.instance.stopPlayingStream(streamId);
          await _bumpWatching(-1);
        }
        if (localViewId != null) {
          await ZegoExpressEngine.instance.destroyCanvasView(localViewId!);
        }
        await ZegoExpressEngine.instance.logoutRoom(roomId);
      }

      await dummyPlayer?.pause();
      await dummyPlayer?.dispose();
      dummyPlayer = null;

      if (isHost && !isDummy && useFirebase) {
        await FirebaseFirestore.instance
            .collection(FirebaseConst.liveStreams)
            .doc(roomId)
            .delete();
      }
    } catch (e) {
      showSnackBar(e.toString());
    } finally {
      Get.back();
    }
  }

  @override
  void onClose() {
    _netSub?.cancel();
    dummyPlayer?.dispose();
    super.onClose();
  }
}
