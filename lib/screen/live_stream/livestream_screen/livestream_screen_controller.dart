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
import 'package:krimson/common/service/livekit/livekit_room_service.dart';
import 'package:krimson/common/service/navigation/navigate_with_controller.dart';
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
import 'package:krimson/common/extensions/string_extension.dart';
import 'package:krimson/utilities/color_res.dart';
import 'package:krimson/utilities/const_res.dart';
import 'package:krimson/utilities/firebase_const.dart';
import 'package:krimson/utilities/text_style_custom.dart';
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
  int _lastSeenLikeCount = 0;
  final RxBool isFollowingHost = false.obs;
  final RxBool isFollowBusy = false.obs;

  /// Comentario al que se responde (tap en burbuja).
  final Rxn<LiveChatMessage> replyingTo = Rxn<LiveChatMessage>();
  /// Remitentes de regalos acumulados en esta sesión.
  final RxList<LiveGiftSender> giftSenders = <LiveGiftSender>[].obs;
  /// Banner "X te sigue" (host + audiencia).
  final Rxn<LiveChatMessage> followBanner = Rxn<LiveChatMessage>();
  Timer? _followBannerTimer;

  /// Pausa del LIVE (host o local en audiencia).
  final RxBool isStreamPaused = false.obs;
  /// Mute del audio del LIVE (host: mic; audiencia: audio remoto).
  final RxBool isLiveAudioMuted = false.obs;

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
    _lastSeenLikeCount = likeCount.value;
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
      if (liveKit == null || liveKit!.isConnected.value != true) {
        if (statusMessage.value.isEmpty) {
          statusMessage.value = 'Sin video. Toca Reintentar.';
        }
      } else if (kIsWeb && isHost) {
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
      _applyRemoteLikeCount(
          payload.session.likeCount ?? likeCount.value);
      _applyGiftSendersFromServer(payload.session.giftSenders);
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
        await _broadcastFollow();
      } else {
        showSnackBar(res.message ?? LKey.somethingWentWrong.tr);
      }
    } catch (e) {
      showSnackBar(e.toString());
    } finally {
      isFollowBusy.value = false;
    }
  }

  Future<void> _broadcastFollow() async {
    final me = SessionManager.instance.getUser();
    if (me?.id == null) return;
    final clientId = '${me!.id}_follow_${DateTime.now().millisecondsSinceEpoch}';
    final name = _liveDisplayName(me);
    final msg = LiveChatMessage(
      id: clientId,
      userId: me.id!,
      userName: name,
      type: 'follow',
      text: '$name te sigue',
    );
    _appendChatMessage(msg);
    try {
      await LiveSessionService.instance.sendComment(
        roomId: roomId,
        clientId: clientId,
        type: 'text',
        text: '👤 $name te sigue',
      );
    } catch (_) {}
    try {
      await liveKit?.publishData(msg.toBytes());
    } catch (_) {}
  }

  void setReplyTo(LiveChatMessage message) {
    if (message.type == 'like' || message.type == 'follow') return;
    replyingTo.value = message;
  }

  void clearReply() => replyingTo.value = null;

  Future<void> togglePauseLive() async {
    final lk = liveKit;
    if (lk == null || !lk.isConnected.value) {
      if (dummyPlayer != null && dummyPlayer!.value.isInitialized) {
        if (dummyPlayer!.value.isPlaying) {
          await dummyPlayer!.pause();
          isStreamPaused.value = true;
        } else {
          await dummyPlayer!.play();
          isStreamPaused.value = false;
        }
      } else {
        isStreamPaused.value = !isStreamPaused.value;
      }
      update();
      return;
    }
    await lk.toggleStreamPaused(asHost: isHost);
    isStreamPaused.value = lk.streamPaused.value;
    if (isHost) {
      isLiveAudioMuted.value = !lk.microphoneEnabled.value;
    }
    update();
  }

  Future<void> toggleLiveAudioMute() async {
    final lk = liveKit;
    if (lk == null) {
      isLiveAudioMuted.value = !isLiveAudioMuted.value;
      return;
    }
    if (isHost) {
      await lk.toggleMicrophone();
      isLiveAudioMuted.value = !lk.microphoneEnabled.value;
    } else {
      await lk.toggleRemoteAudio();
      isLiveAudioMuted.value = lk.remoteAudioMuted.value;
    }
    update();
  }

  void openGiftSendersSheet() {
    // Autocorregir + pedir stats frescos al backend.
    _repairGiftSenderCoins();
    unawaited(_refreshSessionStats(silent: true));
    Get.bottomSheet(
      SafeArea(
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(Get.context!).size.height * 0.55,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              Text(
                'Regalos recibidos',
                style: TextStyleCustom.unboundedSemiBold600(
                  color: Colors.black87,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Flexible(
                child: Obx(() {
                  final items = giftSenders.toList()
                    ..sort((a, b) => b.totalCoins.compareTo(a.totalCoins));
                  if (items.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 28),
                      child: Text(
                        'Aún no hay regalos',
                        style: TextStyleCustom.outFitRegular400(
                          color: Colors.black54,
                          fontSize: 14,
                        ),
                      ),
                    );
                  }
                  return ListView.separated(
                    shrinkWrap: true,
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final s = items[index];
                      return Material(
                        color: Colors.white,
                        child: ListTile(
                          onTap: () => openUserProfile(
                            userId: s.userId,
                            fullname: s.userName,
                          ),
                          leading: CircleAvatar(
                            backgroundColor: ColorRes.themeAccentSolid
                                .withValues(alpha: 0.15),
                            child: (s.lastGiftImage ?? '').isNotEmpty
                                ? ClipOval(
                                    child: Image.network(
                                      s.lastGiftImage!.addBaseURL(),
                                      width: 40,
                                      height: 40,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => const Icon(
                                        Icons.card_giftcard,
                                        color: ColorRes.themeAccentSolid,
                                      ),
                                    ),
                                  )
                                : const Icon(Icons.card_giftcard,
                                    color: ColorRes.themeAccentSolid),
                          ),
                          title: Text(
                            s.userName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            '${s.giftCount} regalo${s.giftCount == 1 ? '' : 's'}',
                          ),
                          trailing: Text(
                            '${s.totalCoins} coins',
                            style: TextStyleCustom.outFitMedium500(
                              color: ColorRes.themeAccentSolid,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      );
                    },
                  );
                }),
              ),
            ],
          ),
        ),
      ),
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
    );
  }

  void _trackGiftSender(LiveChatMessage msg) {
    if (msg.type != 'gift') return;
    final uid = msg.userId;
    // Si falta userId, igual agrupar por nombre para no perder el tab.
    final keyId = uid > 0 ? uid : msg.userName.hashCode;
    final coins = _resolveGiftCoins(msg);
    final idx = giftSenders.indexWhere(
      (e) =>
          (uid > 0 && e.userId == uid) ||
          (uid <= 0 && e.userName == msg.userName),
    );
    if (idx >= 0) {
      final existing = giftSenders[idx];
      existing.giftCount += 1;
      existing.totalCoins += coins;
      // Si antes quedó en 0 por un parse fallido, recalcular con el precio actual.
      if (existing.totalCoins <= 0 && coins > 0) {
        existing.totalCoins = coins * existing.giftCount;
      }
      if ((msg.giftImage ?? '').isNotEmpty) {
        existing.lastGiftImage = msg.giftImage;
      }
      giftSenders[idx] = existing;
      giftSenders.refresh();
    } else {
      giftSenders.add(LiveGiftSender(
        userId: keyId,
        userName: msg.userName,
        totalCoins: coins,
        giftCount: 1,
        lastGiftImage: msg.giftImage,
      ));
    }
  }

  /// Precio real del regalo (payload → texto → catálogo settings).
  int _resolveGiftCoins(LiveChatMessage msg) {
    if ((msg.giftCoins ?? 0) > 0) return msg.giftCoins!;
    final fromText = RegExp(r'(\d+)\s*coins', caseSensitive: false)
        .firstMatch(msg.text ?? '');
    if (fromText != null) {
      final n = int.tryParse(fromText.group(1) ?? '') ?? 0;
      if (n > 0) return n;
    }
    final gifts = SessionManager.instance.getSettings()?.gifts ?? [];
    final wantId = msg.giftId;
    final wantImg = (msg.giftImage ?? '').trim();
    final wantBase = wantImg.isEmpty ? '' : _giftImageBasename(wantImg);

    for (final g in gifts) {
      final price = g.coinPrice ?? 0;
      if (price <= 0) continue;
      if (wantId != null && g.id != null && g.id == wantId) {
        return price;
      }
      final gImg = (g.image ?? '').trim();
      if (wantImg.isNotEmpty && gImg.isNotEmpty) {
        if (gImg == wantImg ||
            gImg.addBaseURL() == wantImg ||
            wantImg.addBaseURL() == gImg ||
            _giftImageBasename(gImg) == wantBase) {
          return price;
        }
      }
    }
    return 0;
  }

  void _applyGiftSendersFromServer(List<LiveGiftSender>? remote) {
    if (remote == null || remote.isEmpty) return;
    // El backend tiene el precio real (tbl_gifts); reemplazar el tab local.
    giftSenders.assignAll(remote
        .map((s) => LiveGiftSender(
              userId: s.userId,
              userName: s.userName,
              totalCoins: s.totalCoins,
              giftCount: s.giftCount,
              lastGiftImage: s.lastGiftImage,
            ))
        .toList());
  }

  String _giftImageBasename(String path) {
    final clean = path.split('?').first.replaceAll('\\', '/');
    final i = clean.lastIndexOf('/');
    return i >= 0 ? clean.substring(i + 1) : clean;
  }

  /// Si un regalo llegó sin coins y luego llega el mismo evento con coins, corrige el tab.
  void _upgradeGiftSenderCoins(LiveChatMessage msg) {
    if (msg.type != 'gift') return;
    final coins = _resolveGiftCoins(msg);
    if (coins <= 0) return;
    final uid = msg.userId;
    final idx = giftSenders.indexWhere(
      (e) =>
          (uid > 0 && e.userId == uid) ||
          (uid <= 0 && e.userName == msg.userName),
    );
    if (idx < 0) {
      _trackGiftSender(msg);
      return;
    }
    final existing = giftSenders[idx];
    if (existing.totalCoins <= 0 && existing.giftCount > 0) {
      existing.totalCoins = coins * existing.giftCount;
      if ((msg.giftImage ?? '').isNotEmpty) {
        existing.lastGiftImage = msg.giftImage;
      }
      giftSenders[idx] = existing;
      giftSenders.refresh();
    }
  }

  void _repairGiftSenderCoins() {
    for (final msg in chatMessages) {
      if (msg.type == 'gift') _upgradeGiftSenderCoins(msg);
    }
    for (var i = 0; i < giftSenders.length; i++) {
      final s = giftSenders[i];
      if (s.totalCoins > 0 || s.giftCount <= 0) continue;
      final coins = _resolveGiftCoins(LiveChatMessage(
        id: 'repair_${s.userId}',
        userId: s.userId,
        userName: s.userName,
        type: 'gift',
        giftImage: s.lastGiftImage,
      ));
      if (coins <= 0) continue;
      s.totalCoins = coins * s.giftCount;
      giftSenders[i] = s;
    }
    giftSenders.refresh();
  }

  void _showFollowBanner(LiveChatMessage msg) {
    // Visible para host y audiencia.
    followBanner.value = msg;
    _followBannerTimer?.cancel();
    _followBannerTimer = Timer(const Duration(seconds: 4), () {
      if (followBanner.value?.id == msg.id) {
        followBanner.value = null;
      }
    });
  }

  void _startSessionPolling() {
    _sessionPoll?.cancel();
    _sessionPoll = Timer.periodic(const Duration(seconds: 2), (_) {
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
      final newLikes = payload.session.likeCount ?? likeCount.value;
      _applyRemoteLikeCount(newLikes);
      _applyGiftSendersFromServer(payload.session.giftSenders);
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
    if (!Get.isRegistered<LiveKitRoomController>(tag: tag)) {
      liveKit = Get.put(LiveKitRoomController(), tag: tag);
    } else {
      liveKit = Get.find<LiveKitRoomController>(tag: tag);
    }

    ever(liveKit!.statusMessage, (msg) {
      if (msg.isNotEmpty) {
        statusMessage.value = msg;
      }
    });
    ever(liveKit!.mediaRevision, (_) {
      _syncViewersFromLiveKit();
      update();
    });

    try {
      await liveKit!.connect(
        roomName: roomId,
        identity: '${me.id}',
        name: me.fullname ?? me.username ?? 'user',
        // En Web el host puede no publicar cámara; audiencia siempre recibe.
        publishCamera: isHost && !kIsWeb,
        publishMicrophone: isHost && !kIsWeb,
        wsUrl: liveKitWsUrl,
        forceProfile: LiveKitQualityProfile.low,
      );
    } catch (e) {
      // No tumbar el LIVE: chat sigue; UI ofrece Reintentar.
      Loggers.error('live join LiveKit: $e');
      if (statusMessage.value.isEmpty) {
        statusMessage.value = 'Sin video (red débil). Toca Reintentar.';
      }
    }

    _dataSub?.cancel();
    _dataSub = liveKit!.onDataReceived.listen(_onLiveData);
    ever(liveKit!.pingMs, (v) => pingMs.value = v);
    ever(liveKit!.fps, (v) => fps.value = v);
    // Sincronizar chip Mute/Abierto con el mic real del host.
    if (isHost) {
      isLiveAudioMuted.value = !liveKit!.microphoneEnabled.value;
      ever(liveKit!.microphoneEnabled, (on) {
        isLiveAudioMuted.value = !on;
      });
    }
    _syncViewersFromLiveKit();

    update();
  }

  /// Reintenta LiveKit forzando calidad baja (red débil).
  Future<void> retryLiveConnection() async {
    final me = SessionManager.instance.getUser();
    if (me == null || liveKit == null) {
      await _joinLiveKit();
      update();
      return;
    }
    statusMessage.value = 'Reintentando en calidad baja…';
    try {
      await liveKit!.reconnectLowQuality(
        roomName: roomId,
        identity: '${me.id}',
        name: me.fullname ?? me.username ?? 'user',
        publishCamera: isHost && !kIsWeb,
        publishMicrophone: isHost && !kIsWeb,
        wsUrl: liveKitWsUrl,
      );
      _dataSub?.cancel();
      _dataSub = liveKit!.onDataReceived.listen(_onLiveData);
      if (liveKit!.isConnected.value) {
        statusMessage.value = '';
      }
    } catch (e) {
      statusMessage.value = 'No se pudo conectar. Revisa tu red.';
      Loggers.error('retryLiveConnection: $e');
    }
    update();
  }

  String qualityLabel(LiveKitQualityProfile p) => switch (p) {
        LiveKitQualityProfile.low => 'Baja',
        LiveKitQualityProfile.medium => 'Media',
        LiveKitQualityProfile.high => 'Alta',
      };

  Future<void> setLiveQuality(LiveKitQualityProfile profile) async {
    final lk = liveKit;
    if (lk == null || !lk.isConnected.value) return;
    try {
      await lk.setQualityProfile(profile, asHost: isHost);
      update();
    } catch (e) {
      showSnackBar(e.toString());
    }
  }

  void openQualitySheet() {
    Get.bottomSheet(
      SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
          child: Obx(() {
            final current = liveKit?.qualityProfile.value ??
                LiveKitQualityProfile.low;
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.black12,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                Text(
                  'Calidad de video',
                  textAlign: TextAlign.center,
                  style: TextStyleCustom.unboundedSemiBold600(
                    color: Colors.black87,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Entras en Baja. Súbela si tu señal mejora.',
                  textAlign: TextAlign.center,
                  style: TextStyleCustom.outFitRegular400(
                    color: Colors.black54,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                for (final p in LiveKitQualityProfile.values)
                  Material(
                    color: Colors.white,
                    child: ListTile(
                      onTap: () async {
                        Get.back();
                        await setLiveQuality(p);
                      },
                      leading: Icon(
                        p == LiveKitQualityProfile.low
                            ? Icons.signal_cellular_alt_1_bar
                            : p == LiveKitQualityProfile.medium
                                ? Icons.signal_cellular_alt_2_bar
                                : Icons.signal_cellular_alt,
                        color: ColorRes.themeAccentSolid,
                      ),
                      title: Text(qualityLabel(p)),
                      subtitle: Text(
                        p == LiveKitQualityProfile.low
                            ? '180p · menos datos'
                            : p == LiveKitQualityProfile.medium
                                ? '360p · equilibrado'
                                : '720p · máxima calidad',
                      ),
                      trailing: current == p
                          ? const Icon(Icons.check_circle,
                              color: ColorRes.themeAccentSolid)
                          : null,
                    ),
                  ),
              ],
            );
          }),
        ),
      ),
      backgroundColor: Colors.transparent,
    );
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

  /// Prefijo en comentarios Laravel para sincronizar regalos sin LiveKit.
  /// Formato corto: 🎁GIFT|{giftId}|{coins}|  (sin URL larga → evita max length)
  static final RegExp _giftPayloadRe =
      RegExp(r'GIFT\|(\d+)\|(\d+)\|');

  void _pulseFloatingLike() {
    floatingLikes.value++;
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (floatingLikes.value > 0) floatingLikes.value--;
    });
  }

  /// Likes remotos sin LiveKit: el poll de sesión sube like_count → animar.
  void _applyRemoteLikeCount(int newCount) {
    if (newCount > _lastSeenLikeCount) {
      final delta = (newCount - _lastSeenLikeCount).clamp(1, 8);
      for (var i = 0; i < delta; i++) {
        Future.delayed(Duration(milliseconds: i * 120), _pulseFloatingLike);
      }
    }
    _lastSeenLikeCount = newCount;
    likeCount.value = newCount;
  }

  LiveChatMessage _normalizeIncomingChat(LiveChatMessage msg) {
    if (msg.type == 'gift') {
      // Completar coins/imagen desde catálogo si vienen vacíos.
      final coins = _resolveGiftCoins(msg);
      final image = (msg.giftImage ?? '').trim().isNotEmpty
          ? msg.giftImage
          : _resolveGiftImage(msg.giftId);
      if ((coins > 0 && (msg.giftCoins == null || msg.giftCoins == 0)) ||
          ((msg.giftImage ?? '').isEmpty && (image ?? '').isNotEmpty)) {
        return LiveChatMessage(
          id: msg.id,
          userId: msg.userId,
          userName: msg.userName,
          type: 'gift',
          text: msg.text,
          giftId: msg.giftId,
          giftImage: image,
          giftCoins: coins > 0 ? coins : msg.giftCoins,
          createdAt: msg.createdAt,
          replyToId: msg.replyToId,
          replyToUserName: msg.replyToUserName,
          replyToText: msg.replyToText,
        );
      }
      return msg;
    }
    final text = (msg.text ?? '').trim();
    if (text.isEmpty) return msg;

    final m = _giftPayloadRe.firstMatch(text);
    if (m != null) {
      final giftId = int.tryParse(m.group(1) ?? '');
      var giftCoins = int.tryParse(m.group(2) ?? '') ?? 0;
      // Tras GIFT|id|coins| puede venir image| (formato largo) o el texto.
      String? image;
      final after = text.substring(m.end);
      final imgMatch = RegExp(r'^([^|\s][^|]*)\|').firstMatch(after);
      if (imgMatch != null) {
        final raw = (imgMatch.group(1) ?? '').trim();
        if (raw.isNotEmpty) image = raw;
      }
      image ??= _resolveGiftImage(giftId);
      final partial = LiveChatMessage(
        id: msg.id,
        userId: msg.userId,
        userName: msg.userName,
        type: 'gift',
        text: 'sent a gift',
        giftId: giftId,
        giftCoins: giftCoins,
        giftImage: image,
        createdAt: msg.createdAt,
      );
      if (giftCoins <= 0) {
        giftCoins = _resolveGiftCoins(partial);
      }
      return LiveChatMessage(
        id: msg.id,
        userId: msg.userId,
        userName: msg.userName,
        type: 'gift',
        text: 'sent a gift',
        giftId: giftId,
        giftCoins: giftCoins,
        giftImage: image,
        createdAt: msg.createdAt,
      );
    }

    // Formato legado: "🎁 Name sent a gift" / "🎁|id|coins|img|"
    final legacy = RegExp(r'🎁\|(\d*)\|(\d*)\|([^|]*)\|').firstMatch(text);
    if (legacy != null) {
      final imageRaw = (legacy.group(3) ?? '').trim();
      final giftId = int.tryParse(legacy.group(1) ?? '');
      var giftCoins = int.tryParse(legacy.group(2) ?? '') ?? 0;
      final image =
          imageRaw.isEmpty ? _resolveGiftImage(giftId) : imageRaw;
      final partial = LiveChatMessage(
        id: msg.id,
        userId: msg.userId,
        userName: msg.userName,
        type: 'gift',
        text: 'sent a gift',
        giftId: giftId,
        giftCoins: giftCoins,
        giftImage: image,
        createdAt: msg.createdAt,
      );
      if (giftCoins <= 0) giftCoins = _resolveGiftCoins(partial);
      return LiveChatMessage(
        id: msg.id,
        userId: msg.userId,
        userName: msg.userName,
        type: 'gift',
        text: 'sent a gift',
        giftId: giftId,
        giftCoins: giftCoins,
        giftImage: image,
        createdAt: msg.createdAt,
      );
    }

    final lower = text.toLowerCase();
    if (text.contains('🎁') &&
        (lower.contains('sent a gift') || lower.contains('envió un regalo'))) {
      return LiveChatMessage(
        id: msg.id,
        userId: msg.userId,
        userName: msg.userName,
        type: 'gift',
        text: 'sent a gift',
        createdAt: msg.createdAt,
      );
    }
    if (text.contains('👤') || lower.contains('te sigue')) {
      return LiveChatMessage(
        id: msg.id,
        userId: msg.userId,
        userName: msg.userName,
        type: 'follow',
        text: text.replaceFirst('👤', '').trim().isEmpty
            ? '${msg.userName} te sigue'
            : text.replaceFirst('👤', '').trim(),
        createdAt: msg.createdAt,
      );
    }
    return msg;
  }

  String? _resolveGiftImage(int? giftId) {
    if (giftId == null) return null;
    final gifts = SessionManager.instance.getSettings()?.gifts ?? [];
    for (final g in gifts) {
      if (g.id == giftId && (g.image ?? '').isNotEmpty) return g.image;
    }
    return null;
  }

  void _appendChatMessage(LiveChatMessage raw, {bool animateGift = false}) {
    final msg = _normalizeIncomingChat(raw);
    if (msg.type == 'like') return;
    if (chatMessages.any((m) => m.id == msg.id)) {
      if (msg.type == 'gift') _upgradeGiftSenderCoins(msg);
      return;
    }

    if (msg.type == 'gift') {
      _trackGiftSender(msg);
      if (animateGift) {
        _showGiftOverlay(msg);
      }
    }

    final isFollow = msg.type == 'follow' ||
        (msg.type == 'text' &&
            (msg.text ?? '').contains('te sigue'));
    if (isFollow) {
      _showFollowBanner(
        msg.type == 'follow'
            ? msg
            : LiveChatMessage(
                id: msg.id,
                userId: msg.userId,
                userName: msg.userName,
                type: 'follow',
                text: msg.text,
              ),
      );
    }
    chatMessages.add(msg);
    while (chatMessages.length > maxVisibleComments) {
      chatMessages.removeAt(0);
    }
  }

  void _showGiftOverlay(LiveChatMessage msg) {
    if (Get.context == null) return;
    final image = (msg.giftImage ?? '').trim();
    final gifts = SessionManager.instance.getSettings()?.gifts ?? [];
    Gift? gift;
    for (final g in gifts) {
      if ((msg.giftId != null && g.id == msg.giftId) ||
          (image.isNotEmpty &&
              ((g.image ?? '') == image ||
                  _giftImageBasename(g.image ?? '') ==
                      _giftImageBasename(image)))) {
        gift = g;
        break;
      }
    }
    gift ??= image.isNotEmpty
        ? Gift(id: msg.giftId, image: image, coinPrice: msg.giftCoins)
        : null;
    // Si el tab quedó en 0, aplicar precio del regalo resuelto.
    final price = gift?.coinPrice ?? _resolveGiftCoins(msg);
    if (price > 0) {
      _upgradeGiftSenderCoins(LiveChatMessage(
        id: msg.id,
        userId: msg.userId,
        userName: msg.userName,
        type: 'gift',
        giftId: gift?.id ?? msg.giftId,
        giftImage: gift?.image ?? msg.giftImage,
        giftCoins: price,
      ));
    }
    if (gift == null) {
      if (gifts.isEmpty) return;
      gift = gifts.first;
    }
    try {
      GiftManager.showAnimationDialog(gift);
    } catch (e) {
      Loggers.error('showGiftOverlay: $e');
    }
  }

  void _onLiveData(DataReceivedEvent event) {
    final msg = LiveChatMessage.tryParseBytes(event.data);
    if (msg == null) return;
    if (msg.type == 'like') {
      _pulseFloatingLike();
      return;
    }
    if (msg.type == 'gift') {
      // Animar al recibir por LiveKit (host / otros viewers).
      _appendChatMessage(msg, animateGift: true);
      return;
    }
    if (msg.type == 'follow') {
      _appendChatMessage(msg);
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
        // En poll inicial no animar (evita spam al entrar). Luego sí.
        final isGiftLike = msg.type == 'gift' ||
            (msg.text ?? '').contains('🎁');
        _appendChatMessage(msg, animateGift: !initial && isGiftLike);
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
    final reply = replyingTo.value;
    try {
      final clientId = '${me!.id}_${DateTime.now().millisecondsSinceEpoch}';
      final replyPreview = (reply?.text ?? '').trim();
      final msg = LiveChatMessage(
        id: clientId,
        userId: me.id!,
        userName: _liveDisplayName(me),
        type: 'text',
        text: trimmed,
        replyToId: reply?.id,
        replyToUserName: reply?.userName,
        replyToText: replyPreview.isEmpty
            ? null
            : (replyPreview.length > 80
                ? '${replyPreview.substring(0, 80)}…'
                : replyPreview),
      );
      _appendChatMessage(msg);
      commentController.clear();
      clearReply();
      // Persistencia Laravel (sincroniza a todos, también Web).
      final apiText = reply == null
          ? trimmed
          : '↳ @${reply.userName}: $trimmed';
      try {
        final saved = await LiveSessionService.instance.sendComment(
          roomId: roomId,
          clientId: clientId,
          type: 'text',
          text: apiText,
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

  /// Publica el regalo para que host/audiencia lo vean (anim + chat + tab).
  Future<void> broadcastGift(Gift gift) async {
    final me = SessionManager.instance.getUser();
    if (me?.id == null) return;
    final clientId = '${me!.id}_gift_${DateTime.now().millisecondsSinceEpoch}';
    final name = _liveDisplayName(me);
    var coins = gift.coinPrice ?? 0;
    if (coins <= 0 && gift.id != null) {
      final catalog = SessionManager.instance.getSettings()?.gifts ?? [];
      for (final g in catalog) {
        if (g.id == gift.id && (g.coinPrice ?? 0) > 0) {
          coins = g.coinPrice!;
          break;
        }
      }
    }
    final image = gift.image;
    final msg = LiveChatMessage(
      id: clientId,
      userId: me.id!,
      userName: name,
      type: 'gift',
      text: 'sent a gift · $coins coins',
      giftId: gift.id,
      giftImage: image,
      giftCoins: coins,
    );
    // Ya se animó en openGiftSheet; aquí solo chat + tab.
    _appendChatMessage(msg, animateGift: false);
    // Payload corto (sin URL): evita max length del API y parseo frágil.
    final encoded = '🎁GIFT|${gift.id ?? 0}|$coins| $name sent a gift · $coins coins';
    try {
      await LiveSessionService.instance.sendComment(
        roomId: roomId,
        clientId: clientId,
        type: 'text',
        text: encoded,
      );
    } catch (e) {
      Loggers.error('broadcastGift api: $e');
      // Fallback: registrar coins directo en la sesión.
      if (gift.id != null) {
        try {
          final senders = await LiveSessionService.instance.recordGift(
            roomId: roomId,
            giftId: gift.id!,
            coins: coins,
            image: image,
            clientId: clientId,
          );
          _applyGiftSendersFromServer(senders);
        } catch (e2) {
          Loggers.error('broadcastGift recordGift: $e2');
        }
      }
    }
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
    // Feedback inmediato en el que da like.
    _pulseFloatingLike();
    try {
      final count = await LiveSessionService.instance.like(roomId: roomId);
      _lastSeenLikeCount = count;
      likeCount.value = count;
      livestream.likeCount = count;
      final me = SessionManager.instance.getUser();
      if (me?.id != null) {
        // Señal LiveKit para animación remota (si hay sala A/V).
        final msg = LiveChatMessage(
          id: '${me!.id}_like_${DateTime.now().millisecondsSinceEpoch}',
          userId: me.id!,
          userName: me.fullname ?? me.username ?? 'User',
          type: 'like',
          text: '❤️',
        );
        try {
          await liveKit?.publishData(msg.toBytes());
        } catch (_) {}
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
    if (!isHost) return;
    await liveKit?.setMicrophoneEnabled(enabled);
  }

  /// Abre el perfil de un usuario (host, chat, invitados, etc.).
  Future<void> openUserProfile({
    required int? userId,
    String? fullname,
    String? username,
    String? profilePhoto,
  }) async {
    if (userId == null || userId <= 0) return;
    final me = SessionManager.instance.getUser()?.id;
    await NavigationService.shared.openProfileScreen(
      User(
        id: userId,
        fullname: fullname,
        username: username,
        profilePhoto: profilePhoto,
      ),
      isTopBarVisible: me == null || me != userId,
    );
  }

  Future<void> openHostProfile() async {
    final host = livestream.hostUser;
    await openUserProfile(
      userId: livestream.hostId ?? host?.userId,
      fullname: host?.fullname,
      username: host?.username,
      profilePhoto: host?.profile,
    );
  }

  Future<void> openChatUserProfile(LiveChatMessage message) async {
    await openUserProfile(
      userId: message.userId,
      fullname: message.userName,
      username: message.userName,
    );
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
    _followBannerTimer?.cancel();
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
