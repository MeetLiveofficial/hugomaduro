import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krimson/common/controller/base_controller.dart';
import 'package:krimson/common/manager/livekit_room_controller.dart';
import 'package:krimson/common/manager/logger.dart';
import 'package:krimson/common/manager/session_manager.dart';
import 'package:krimson/common/service/api/call_service.dart';
import 'package:krimson/common/service/api/live_session_service.dart';
import 'package:krimson/common/service/api/user_service.dart';
import 'package:krimson/languages/languages_keys.dart';
import 'package:krimson/model/general/settings_model.dart';
import 'package:krimson/model/giphy/giphy_model.dart';
import 'package:krimson/model/livestream/app_user.dart';
import 'package:krimson/model/livestream/live_chat_message.dart';
import 'package:krimson/model/livestream/livestream.dart';
import 'package:krimson/model/livestream/livestream_user_state.dart';
import 'package:krimson/model/user_model/user_model.dart';
import 'package:krimson/screen/call_screen/live_incoming_call_overlay.dart';
import 'package:krimson/screen/call_screen/outgoing_call_screen.dart';
import 'package:krimson/screen/gif_sheet/gif_sheet.dart';
import 'package:krimson/screen/gif_sheet/gif_sheet_controller.dart';
import 'package:krimson/screen/gift_sheet/send_gift_sheet.dart';
import 'package:krimson/screen/gift_sheet/send_gift_sheet_controller.dart';
import 'package:krimson/screen/live_stream/livestream_screen/widget/live_host_panel.dart';
import 'package:krimson/screen/live_stream/livestream_screen/widget/live_private_call_sheet.dart';
import 'package:krimson/utilities/const_res.dart';
import 'package:krimson/utilities/firebase_const.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:video_player/video_player.dart';

class LivestreamScreenController extends BaseController {
  /// Instancia activa (para IncomingCall → cerrar LIVE al aceptar).
  static LivestreamScreenController? activeInstance;

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

  final RxInt watchingCount = 0.obs;
  final RxInt likeCount = 0.obs;
  final RxList<LiveChatMessage> chatMessages = <LiveChatMessage>[].obs;
  final TextEditingController commentController = TextEditingController();
  final RxBool isSendingComment = false.obs;
  final RxBool isLiking = false.obs;
  final RxInt pingMs = 0.obs;
  final RxInt fps = 0.obs;
  final RxInt floatingLikes = 0.obs;
  final RxBool isFollowingHost = false.obs;
  final RxBool isFollowBusy = false.obs;

  StreamSubscription<List<ConnectivityResult>>? _netSub;
  StreamSubscription? _dataSub;
  Timer? _sessionPoll;
  Timer? _commentPoll;
  Timer? _callPoll;
  int _lastCommentServerId = 0;
  bool _commentPollBusy = false;
  bool _callPollBusy = false;
  final Set<int> _seenIncomingCallIds = {};
  bool _callPollPrimed = false;

  VideoPlayerController? dummyPlayer;

  /// A/V LiveKit (null en dummy / web).
  LiveKitRoomController? liveKit;

  String get roomId => livestream.roomID ?? '${livestream.hostId}';
  bool get isDummy => (livestream.isDummyLive ?? 0) == 1;

  String get liveTitle {
    final raw = (livestream.description ?? '').trim();
    if (raw.isEmpty) return 'Live';
    return raw.split('\n').first.trim();
  }

  String get liveDescription {
    final raw = (livestream.description ?? '');
    final i = raw.indexOf('\n');
    if (i < 0) return '';
    return raw.substring(i + 1).trim();
  }

  LocalParticipant? get localParticipant => liveKit?.localParticipant.value;
  List<RemoteParticipant> get remoteParticipants =>
      liveKit?.remoteParticipants.toList() ?? const [];

  @override
  void onInit() {
    super.onInit();
    activeInstance = this;
    selectedGiftUser.value = livestream.hostUser;
    invitedIds.addAll(livestream.coHostIds ?? []);
    watchingCount.value = livestream.watchingCount ?? 0;
    likeCount.value = livestream.likeCount ?? 0;
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

    try {
      statusMessage.value = isHost ? 'Starting live…' : 'Joining live…';
      if (!isHost) {
        await _joinLaravelSession();
        await _loadHostFollowStatus();
      } else {
        await _refreshSessionStats(silent: true);
      }
      // Web también entra a LiveKit (chat data + video). Host en web puede
      // fallar cámara; el chat API sigue funcionando.
      await _joinLiveKit();
      _startSessionPolling();
      _startCommentPolling();
      _startIncomingCallPolling();
      // Mantener presencia ACTIVE mientras el LIVE sigue abierto.
      unawaited(UserService.instance.updateLastUsedAt());
      mediaReady.value = true;
      if (kIsWeb && isHost) {
        statusMessage.value =
            'Live camera on Web is limited. Chat works; prefer Android/iOS for full camera.';
      } else {
        statusMessage.value = '';
      }
    } catch (e) {
      statusMessage.value = e.toString();
      mediaReady.value = true;
      // Chat Laravel aunque LiveKit falle.
      _startCommentPolling();
      _startIncomingCallPolling();
      showSnackBar(e.toString());
    }
  }

  /// Poll de llamadas entrantes mientras el LIVE está abierto (no depende de FCM).
  void _startIncomingCallPolling() {
    _callPoll?.cancel();
    Future.microtask(_pollIncomingCalls);
    _callPoll = Timer.periodic(const Duration(seconds: 2), (_) {
      _pollIncomingCalls();
    });
  }

  Future<void> _pollIncomingCalls() async {
    if (_callPollBusy || isEnding.value || isDummy) return;
    // Si ya hay videollamada abierta, no spamear overlay.
    if (Get.currentRoute.contains('VideoCall')) return;
    _callPollBusy = true;
    try {
      final inbox = await CallService.instance.inbox();
      final pending =
          inbox.received.where((e) => e.isPending && e.id != null).toList();

      if (!_callPollPrimed) {
        _seenIncomingCallIds.addAll(pending.map((e) => e.id!));
        _callPollPrimed = true;
        // Si al entrar al LIVE ya había pending, mostrarla.
        if (pending.isNotEmpty) {
          await LiveIncomingCallOverlay.show(pending.first);
        }
        return;
      }

      for (final item in pending) {
        if (_seenIncomingCallIds.add(item.id!)) {
          await LiveIncomingCallOverlay.show(item);
          break;
        }
      }
    } catch (e) {
      Loggers.error('live incoming call poll: $e');
    } finally {
      _callPollBusy = false;
    }
  }

  Future<void> _joinLaravelSession() async {
    try {
      final payload =
          await LiveSessionService.instance.join(roomId: roomId);
      watchingCount.value = payload.session.watchingCount ?? watchingCount.value;
      likeCount.value = payload.session.likeCount ?? likeCount.value;
      livestream.watchingCount = watchingCount.value;
      livestream.likeCount = likeCount.value;
    } catch (e) {
      Loggers.error('live join: $e');
    }
  }

  Future<void> _loadHostFollowStatus() async {
    final hostId = livestream.hostId;
    if (hostId == null || isHost) return;
    final meId = SessionManager.instance.getUserID();
    if (meId == hostId) {
      isFollowingHost.value = true;
      return;
    }
    try {
      final host =
          await UserService.instance.fetchUserDetails(userId: hostId);
      isFollowingHost.value = host?.isFollowing == true;
    } catch (e) {
      Loggers.error('live host follow status: $e');
    }
  }

  Future<void> followHost() async {
    if (isHost || isFollowBusy.value || isFollowingHost.value) return;
    final hostId = livestream.hostId;
    if (hostId == null) return;
    isFollowBusy.value = true;
    try {
      final res = await UserService.instance.followUser(userId: hostId);
      if (res.status == true) {
        isFollowingHost.value = true;
      } else {
        showSnackBar(res.message ?? LKey.somethingWentWrong.tr);
      }
    } catch (e) {
      showSnackBar(e.toString());
    } finally {
      isFollowBusy.value = false;
    }
  }

  void _startSessionPolling() {
    _sessionPoll?.cancel();
    _sessionPoll = Timer.periodic(const Duration(seconds: 4), (_) {
      _refreshSessionStats(silent: true);
    });
  }

  Future<void> _refreshSessionStats({bool silent = false}) async {
    try {
      final payload =
          await LiveSessionService.instance.fetchSession(roomId: roomId);
      if (payload == null) {
        // Live terminado / sala muerta → audiencia debe salir.
        if (!isHost && !isEnding.value) {
          await endOrLeave();
        }
        return;
      }
      var watch = payload.session.watchingCount ?? 0;
      if (isHost && liveKit != null) {
        final remotes = liveKit!.remoteParticipants.length;
        if (remotes > watch) watch = remotes;
      }
      watchingCount.value = watch;
      likeCount.value = payload.session.likeCount ?? likeCount.value;
      livestream.watchingCount = watchingCount.value;
      livestream.likeCount = likeCount.value;
    } catch (e) {
      if (!silent) Loggers.error('fetchSession: $e');
      if (!isHost && !isEnding.value) {
        // Si la API falla de forma persistente tras end, forzar salida.
        final msg = e.toString().toLowerCase();
        if (msg.contains('not found') || msg.contains('ended')) {
          await endOrLeave();
        }
      }
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

    ever(liveKit!.statusMessage, (msg) {
      if (msg.isNotEmpty) {
        statusMessage.value = msg;
      }
    });
    ever(liveKit!.mediaRevision, (_) {
      _syncViewersFromLiveKit();
      update();
    });

    await liveKit!.connect(
      roomName: roomId,
      identity: '${me.id}',
      name: me.fullname ?? me.username ?? 'user',
      // En Web el host puede no publicar cámara; audiencia siempre recibe.
      publishCamera: isHost && !kIsWeb,
      publishMicrophone: isHost && !kIsWeb,
      wsUrl: liveKitWsUrl,
    );

    _dataSub = liveKit!.onDataReceived.listen(_onLiveData);
    ever(liveKit!.pingMs, (v) => pingMs.value = v);
    ever(liveKit!.fps, (v) => fps.value = v);
    _syncViewersFromLiveKit();

    update();
  }

  /// Host: espectadores ≈ participantes remotos en LiveKit (más fiable en vivo).
  void _syncViewersFromLiveKit() {
    if (!isHost || liveKit == null) return;
    final remotes = liveKit!.remoteParticipants.length;
    if (remotes > watchingCount.value) {
      watchingCount.value = remotes;
    }
  }

  static const int maxVisibleComments = 5;

  void _pulseFloatingLike() {
    floatingLikes.value++;
    Future.delayed(const Duration(milliseconds: 900), () {
      if (floatingLikes.value > 0) floatingLikes.value--;
    });
  }

  void _appendChatMessage(LiveChatMessage msg) {
    if (msg.type == 'like') return;
    if (chatMessages.any((m) => m.id == msg.id)) return;
    chatMessages.add(msg);
    while (chatMessages.length > maxVisibleComments) {
      chatMessages.removeAt(0);
    }
  }

  void _showGiftOverlay(LiveChatMessage msg) {
    final image = (msg.giftImage ?? '').trim();
    if (image.isEmpty || Get.context == null) return;
    final gifts = SessionManager.instance.getSettings()?.gifts ?? [];
    Gift? gift;
    for (final g in gifts) {
      if (g.id == msg.giftId || (g.image ?? '') == image) {
        gift = g;
        break;
      }
    }
    gift ??= Gift(id: msg.giftId, image: image, coinPrice: msg.giftCoins);
    try {
      GiftManager.showAnimationDialog(gift);
    } catch (_) {}
  }

  void _onLiveData(DataReceivedEvent event) {
    final msg = LiveChatMessage.tryParseBytes(event.data);
    if (msg == null) return;
    if (msg.type == 'like') {
      _pulseFloatingLike();
      return;
    }
    if (msg.type == 'gift') {
      _appendChatMessage(msg);
      _showGiftOverlay(msg);
      return;
    }
    _appendChatMessage(msg);
  }

  void _startCommentPolling() {
    _commentPoll?.cancel();
    _pollComments(initial: true);
    _commentPoll = Timer.periodic(const Duration(milliseconds: 1200), (_) {
      _pollComments();
    });
  }

  Future<void> _pollComments({bool initial = false}) async {
    if (isDummy || _commentPollBusy || isEnding.value) return;
    _commentPollBusy = true;
    try {
      final payload = await LiveSessionService.instance.fetchComments(
        roomId: roomId,
        afterId: initial ? null : (_lastCommentServerId > 0 ? _lastCommentServerId : null),
        limit: initial ? maxVisibleComments : 20,
      );
      for (final msg in payload.comments) {
        _appendChatMessage(msg);
      }
      if (payload.lastServerId > _lastCommentServerId) {
        _lastCommentServerId = payload.lastServerId;
      }
    } catch (e) {
      Loggers.error('live comments poll: $e');
    } finally {
      _commentPollBusy = false;
    }
  }

  String _liveDisplayName(User me) {
    final full = (me.fullname ?? '').trim();
    if (full.isNotEmpty) return full;
    final user = (me.username ?? '').trim();
    if (user.isNotEmpty) return user;
    return 'User';
  }

  Future<void> sendComment(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || isSendingComment.value) return;
    final me = SessionManager.instance.getUser();
    if (me?.id == null) return;
    isSendingComment.value = true;
    try {
      final clientId = '${me!.id}_${DateTime.now().millisecondsSinceEpoch}';
      final msg = LiveChatMessage(
        id: clientId,
        userId: me.id!,
        userName: _liveDisplayName(me),
        type: 'text',
        text: trimmed,
      );
      _appendChatMessage(msg);
      commentController.clear();
      // Persistencia Laravel (sincroniza a todos, también Web).
      try {
        final saved = await LiveSessionService.instance.sendComment(
          roomId: roomId,
          clientId: clientId,
          type: 'text',
          text: trimmed,
        );
        if (saved != null) {
          _appendChatMessage(saved);
        }
      } catch (e) {
        Loggers.error('live sendComment api: $e');
      }
      // Extra baja latencia si LiveKit está conectado.
      try {
        await liveKit?.publishData(msg.toBytes());
      } catch (_) {}
    } catch (e) {
      showSnackBar(e.toString());
    } finally {
      isSendingComment.value = false;
    }
  }

  Future<void> openGifPicker() async {
    final settings = SessionManager.instance.getSettings();
    if ((settings?.gifSupport ?? 0) != 1) {
      showSnackBar('GIF support is disabled');
      return;
    }
    if ((settings?.giphyKey ?? '').trim().isEmpty) {
      showSnackBar('GIPHY no configurado. Activa giphy_key en el admin.');
      return;
    }
    if (!Get.isRegistered<GifSheetController>()) {
      Get.put(GifSheetController());
    } else {
      // Refrescar trending por si la key se configuró después.
      Get.find<GifSheetController>().fetchTrendingGiphy(isEmpty: true);
    }
    final result = await Get.bottomSheet<dynamic>(
      const GifSheet(),
      isScrollControlled: true,
    );
    String? url;
    if (result is String) {
      url = result;
    } else if (result is GiphyData) {
      url = result.images?.original?.url ??
          result.images?.fixedHeight?.url;
    }
    if (url == null || url.isEmpty) return;
    await sendGif(url);
  }

  Future<void> openGiftSheet() async {
    if (isHost) return;
    final hostId = livestream.hostId;
    if (hostId == null) return;
    final meId = SessionManager.instance.getUserID();
    if (meId != 0 && meId == hostId) return;
    final host = livestream.hostUser ??
        AppUser(userId: hostId, fullname: liveTitle);
    await GiftManager.openGiftSheet(
      userId: hostId,
      giftType: GiftType.livestream,
      streamUsers: [host],
      onCompletion: (gm) async {
        GiftManager.showAnimationDialog(gm.gift);
        await broadcastGift(gm.gift);
      },
    );
  }

  /// Publica el regalo para que host/audiencia lo vean (anim + chat).
  Future<void> broadcastGift(Gift gift) async {
    final me = SessionManager.instance.getUser();
    if (me?.id == null) return;
    final clientId = '${me!.id}_gift_${DateTime.now().millisecondsSinceEpoch}';
    final msg = LiveChatMessage(
      id: clientId,
      userId: me.id!,
      userName: _liveDisplayName(me),
      type: 'gift',
      text: 'sent a gift',
      giftId: gift.id,
      giftImage: gift.image,
      giftCoins: gift.coinPrice,
    );
    _appendChatMessage(msg);
    try {
      await LiveSessionService.instance.sendComment(
        roomId: roomId,
        clientId: clientId,
        type: 'text',
        text: '🎁 ${_liveDisplayName(me)} sent a gift',
      );
    } catch (_) {}
    try {
      await liveKit?.publishData(msg.toBytes());
    } catch (_) {}
  }

  Future<void> openPrivateCall() async {
    if (isHost) return;
    final hostId = livestream.hostId;
    if (hostId == null) return;

    showLoader();
    try {
      final hostUser =
          await UserService.instance.fetchUserDetails(userId: hostId);
      stopLoader();
      if (hostUser == null) {
        showSnackBar('Host not found');
        return;
      }

      final canReceive = hostUser.canReceiveCalls == 1 ||
          hostUser.getLevel.canReceiveCalls == 1;
      if (!canReceive) {
        showSnackBar(LKey.callCannotReceive.tr);
        return;
      }

      final cost = hostUser.callRequestCoins > 0
          ? hostUser.callRequestCoins
          : hostUser.getLevel.callRequestCoins;
      final hostApp = livestream.hostUser ??
          AppUser(
            userId: hostId,
            fullname: hostUser.fullname,
            username: hostUser.username,
            profile: hostUser.profilePhoto,
          );

      await Get.bottomSheet(
        LivePrivateCallSheet(
          host: hostApp,
          cost: cost,
          onConfirm: () {
            Get.to(() => OutgoingCallScreen(callee: hostUser, cost: cost));
          },
        ),
        isScrollControlled: true,
      );
    } catch (e) {
      stopLoader();
      showSnackBar(e.toString());
    }
  }

  /// Cierra sala/media sin hacer pop (para Accept de llamada privada).
  Future<void> prepareExitForPrivateCall() async {
    if (isEnding.value) return;
    isEnding.value = true;
    _sessionPoll?.cancel();
    _commentPoll?.cancel();
    _callPoll?.cancel();
    try {
      if (!isDummy) {
        try {
          await LiveSessionService.instance
              .leave(roomId: roomId)
              .timeout(const Duration(seconds: 8));
        } catch (_) {}
      }
      await _cleanupMedia().timeout(const Duration(seconds: 8));
    } catch (_) {
    } finally {
      isEnding.value = false;
    }
  }

  /// Libera cámara/mic del LIVE sin salir de la sesión (para videollamada).
  Future<void> pauseLiveKitForCall() async {
    try {
      await liveKit?.disconnect();
    } catch (e) {
      Loggers.error('pauseLiveKitForCall: $e');
    }
  }

  /// Reconecta al LIVE tras colgar la videollamada.
  Future<void> resumeLiveKitAfterCall() async {
    if (isDummy || liveKit == null) return;
    final me = SessionManager.instance.getUser();
    if (me == null) return;
    try {
      if (liveKit!.isConnected.value) {
        await liveKit!.setCameraEnabled(isHost && !kIsWeb);
        await liveKit!.setMicrophoneEnabled(isHost && !kIsWeb);
        return;
      }
      await liveKit!.connect(
        roomName: roomId,
        identity: '${me.id}',
        name: me.fullname ?? me.username ?? 'user',
        publishCamera: isHost && !kIsWeb,
        publishMicrophone: isHost && !kIsWeb,
        wsUrl: liveKitWsUrl,
      );
      update();
    } catch (e) {
      Loggers.error('resumeLiveKitAfterCall: $e');
    }
  }

  Future<void> sendGif(String gifUrl) async {
    final me = SessionManager.instance.getUser();
    if (me?.id == null) return;
    try {
      final clientId = '${me!.id}_gif_${DateTime.now().millisecondsSinceEpoch}';
      final msg = LiveChatMessage(
        id: clientId,
        userId: me.id!,
        userName: _liveDisplayName(me),
        type: 'gif',
        gifUrl: gifUrl,
      );
      _appendChatMessage(msg);
      try {
        await LiveSessionService.instance.sendComment(
          roomId: roomId,
          clientId: clientId,
          type: 'gif',
          gifUrl: gifUrl,
        );
      } catch (e) {
        Loggers.error('live sendGif api: $e');
      }
      try {
        await liveKit?.publishData(msg.toBytes());
      } catch (_) {}
    } catch (e) {
      showSnackBar(e.toString());
    }
  }

  Future<void> sendLike() async {
    if (isHost || isLiking.value) return;
    isLiking.value = true;
    try {
      final count = await LiveSessionService.instance.like(roomId: roomId);
      likeCount.value = count;
      livestream.likeCount = count;
      _pulseFloatingLike();
      final me = SessionManager.instance.getUser();
      if (me?.id != null) {
        // Solo señal para animación remota; no entra al chat.
        final msg = LiveChatMessage(
          id: '${me!.id}_like_${DateTime.now().millisecondsSinceEpoch}',
          userId: me.id!,
          userName: me.fullname ?? me.username ?? 'User',
          type: 'like',
          text: '❤️',
        );
        await liveKit?.publishData(msg.toBytes());
      }
    } catch (e) {
      showSnackBar(e.toString());
    } finally {
      isLiking.value = false;
    }
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
      onSearch: _searchInviteCandidates,
    );
  }

  Future<void> _searchInviteCandidates(String keyword) async {
    inviteLoading.value = true;
    try {
      final users = await UserService.instance.searchUsers(
        keyWord: keyword,
        limit: 40,
      );
      inviteCandidates.assignAll(users);
    } catch (e) {
      showSnackBar(e.toString());
    } finally {
      inviteLoading.value = false;
    }
  }

  Future<void> _loadInviteCandidates() async {
    inviteLoading.value = true;
    try {
      final users = await UserService.instance.searchUsers(
        keyWord: '',
        limit: 40,
      );
      inviteCandidates.assignAll(users);
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

    // Laravel: guarda INVITED + notificación activity + FCM al invitado.
    try {
      await LiveSessionService.instance.invite(roomId: roomId, userId: id);
      showSnackBar(LKey.friendInvited.tr);
    } catch (e) {
      Loggers.error('invite api: $e');
      invitedIds.remove(id);
      inviteCandidates.refresh();
      showSnackBar(e.toString());
    }
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
    _sessionPoll?.cancel();
    _commentPoll?.cancel();
    _callPoll?.cancel();
    // Cerrar UI primero: si LiveKit/API se cuelgan, el usuario ya pudo salir.
    await _popLiveUi();
    try {
      // Host: marcar ended + DeleteRoom en backend ANTES de cleanup local.
      if (!isDummy) {
        try {
          await LiveSessionService.instance
              .leave(roomId: roomId)
              .timeout(const Duration(seconds: 8));
        } catch (_) {}
      }

      await _cleanupMedia().timeout(const Duration(seconds: 8));

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
    _commentPoll?.cancel();
    _commentPoll = null;
    if (!isDummy) {
      if (!isHost) {
        try {
          await _bumpWatching(-1);
        } catch (_) {}
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
    if (identical(activeInstance, this)) {
      activeInstance = null;
    }
    _sessionPoll?.cancel();
    _commentPoll?.cancel();
    _callPoll?.cancel();
    _netSub?.cancel();
    _dataSub?.cancel();
    commentController.dispose();
    dummyPlayer?.dispose();
    final tag = 'lk_live_$roomId';
    if (Get.isRegistered<LiveKitRoomController>(tag: tag)) {
      Get.delete<LiveKitRoomController>(tag: tag);
    }
    super.onClose();
  }
}
