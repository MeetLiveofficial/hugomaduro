import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:krimson/common/controller/base_controller.dart';
import 'package:krimson/common/manager/call_availability.dart';
import 'package:krimson/common/manager/coin_gate.dart';
import 'package:krimson/common/manager/firebase_app_helper.dart';
import 'package:krimson/common/manager/guest_gate.dart';
import 'package:krimson/common/manager/livekit_room_controller.dart';
import 'package:krimson/common/manager/logger.dart';
import 'package:krimson/common/manager/session_manager.dart';
import 'package:krimson/common/service/api/call_service.dart';
import 'package:krimson/common/service/api/chat_service.dart';
import 'package:krimson/common/service/api/gift_wallet_service.dart';
import 'package:krimson/common/service/api/live_session_service.dart';
import 'package:krimson/common/service/api/user_service.dart';
import 'package:krimson/common/service/livekit/livekit_room_service.dart';
import 'package:krimson/common/service/navigation/navigate_with_controller.dart';
import 'package:krimson/common/service/translation/chat_translator_service.dart';
import 'package:krimson/common/widget/gift_media.dart';
import 'package:krimson/languages/dynamic_translations.dart';
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
import 'package:krimson/screen/call_screen/video_call_screen.dart';
import 'package:krimson/screen/gif_sheet/gif_sheet.dart';
import 'package:krimson/screen/gif_sheet/gif_sheet_controller.dart';
import 'package:krimson/screen/gift_sheet/send_gift_sheet.dart';
import 'package:krimson/screen/gift_sheet/send_gift_sheet_controller.dart';
import 'package:krimson/screen/live_stream/livestream_screen/widget/level_entrance_overlay.dart';
import 'package:krimson/screen/live_stream/livestream_screen/widget/live_host_panel.dart';
import 'package:krimson/screen/live_stream/livestream_screen/widget/live_battle_sheet.dart';
import 'package:krimson/screen/live_stream/livestream_screen/widget/live_battle_invite_dialog.dart';
import 'package:krimson/screen/live_stream/livestream_screen/widget/live_gift_boost_sheet.dart';
import 'package:krimson/screen/live_stream/livestream_screen/widget/live_private_call_sheet.dart';
import 'package:krimson/screen/live_stream/livestream_screen/widget/live_unread_chats_sheet.dart';
import 'package:krimson/screen/live_stream/livestream_screen/audience/live_stream_audience_screen.dart';
import 'package:krimson/screen/face_filters/models/face_filter_effect.dart';
import 'package:krimson/screen/face_filters/widgets/beauty_camera_preview.dart';
import 'package:krimson/screen/gpupixel/gpupixel.dart';
import 'package:krimson/common/extensions/string_extension.dart';
import 'package:krimson/utilities/app_res.dart';
import 'package:krimson/utilities/color_res.dart';
import 'package:krimson/utilities/const_res.dart';
import 'package:krimson/utilities/firebase_const.dart';
import 'package:krimson/utilities/text_style_custom.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:video_player/video_player.dart';

/// Resultado visible al terminar una PK.
class BattleResultBanner {
  final bool isDraw;
  final String winnerName;
  final String loserName;
  final int winnerCoins;
  final int loserCoins;

  const BattleResultBanner({
    required this.isDraw,
    required this.winnerName,
    required this.loserName,
    required this.winnerCoins,
    required this.loserCoins,
  });
}

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
  /// Cliente/host salió a videollamada: hay que reconectar LiveKit al colgar.
  final RxBool pausedForCall = false.obs;
  bool _resumingAfterCall = false;
  DateTime? _lastResumeAfterCallAt;

  /// Hay pantalla de llamada (saliente o activa) encima del LIVE.
  bool get isCallUiActive =>
      OutgoingCallController.activeInstance != null ||
      VideoCallController.activeInstance != null;

  final RxBool beautyOn = false.obs;
  final RxDouble whiten = 50.0.obs;
  final RxDouble rosy = 40.0.obs;
  final RxDouble smooth = 55.0.obs;
  final RxDouble sharpen = 35.0.obs;
  /// Perfilado / ojos grandes (GPUPixel FaceReshapeFilter), 0–100.
  final RxDouble slimFace = 0.0.obs;
  final RxDouble bigEye = 0.0.obs;
  final Rx<FaceFilterId> selectedBeautyFilterId = FaceFilterId.none.obs;
  final RxnInt selectedDeepArFilterId = RxnInt();
  final BeautyShaderController beautyShader = BeautyShaderController();
  /// Motor nativo GPUPixel (preview/params). En LIVE la cámara la tiene LiveKit.
  final GpuPixelController gpuPixel = GpuPixelController();
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
  /// Composer "Di Hola" expandido (input visible).
  final RxBool chatComposerExpanded = false.obs;
  final FocusNode commentFocusNode = FocusNode();
  /// Chats 1:1 con mensajes sin leer (badge en LIVE).
  final RxInt unreadChatCount = 0.obs;
  /// Remitentes de regalos acumulados en esta sesión.
  final RxList<LiveGiftSender> giftSenders = <LiveGiftSender>[].obs;
  final RxList<LiveGiftIncentive> giftIncentives = <LiveGiftIncentive>[].obs;
  /// Gift del slider que se está enviando (spinner en el chip, no Get.dialog).
  final RxnInt sendingGiftId = RxnInt();
  /// Banner "X te sigue" (host + audiencia).
  final Rxn<LiveChatMessage> followBanner = Rxn<LiveChatMessage>();
  Timer? _followBannerTimer;
  /// Banner de entrada por nivel (join destacado).
  final Rxn<LiveChatMessage> joinBanner = Rxn<LiveChatMessage>();
  Timer? _joinBannerTimer;

  /// Host ausente (audiencia): countdown antes de ir a otro LIVE.
  static const int hostAbsentTimeoutSecs = 10;
  final RxBool hostAbsent = false.obs;
  final RxInt hostAbsentSecondsLeft = 0.obs;
  bool _hostEverPublished = false;
  DateTime? _hostAbsentSince;
  Timer? _hostAbsentTimer;
  bool _redirectingToNextLive = false;
  final Set<String> _seenCallInviteIds = {};
  final Set<String> _seenGiftBoostIds = {};

  /// Pausa del LIVE (host o local en audiencia).
  final RxBool isStreamPaused = false.obs;
  /// Mute del audio del LIVE (host: mic; audiencia: audio remoto).
  final RxBool isLiveAudioMuted = false.obs;

  /// Segundos transcurridos del LIVE (badge de tiempo en LIVE normal).
  final RxInt liveElapsedSeconds = 0.obs;
  Timer? _liveElapsedTicker;
  DateTime? _liveStartedAt;

  /// Host (o co-host visible) está en videollamada: chip "EN LLAMADA".
  final RxBool hostInCall = false.obs;

  /// Estado de Batalla 1v1 (PK).
  final RxBool isBattleRunning = false.obs;
  final RxBool isBattleWaiting = false.obs;
  final RxnInt battleOpponentId = RxnInt();
  final RxString battleOpponentName = ''.obs;
  final RxnString battleOpponentPhoto = RxnString();
  final RxInt battleHostCoins = 0.obs;
  final RxInt battleOpponentCoins = 0.obs;
  final RxInt battleRemainingSeconds = 0.obs;
  final RxInt battleDurationMinutes = AppRes.battleDurationInMinutes.obs;
  final RxnInt battleSelectedOpponentId = RxnInt();
  /// Equipo al que van los likes durante la batalla (recordado tras elegir).
  final RxnInt battleLikeForUserId = RxnInt();
  /// Banner ganador/perdedor / empate al cerrar la PK.
  final Rxn<BattleResultBanner> battleResultBanner = Rxn();
  Timer? _battleTicker;
  Timer? _battleResultClearTimer;
  bool _endingBattle = false;
  bool _rematchPromptOpen = false;
  bool _battleResultShown = false;
  /// Última sala LiveKit a la que nos conectamos (para detectar cambio post-PK).
  String? _connectedLiveKitRoom;
  bool _avRoomSyncing = false;

  StreamSubscription? _dataSub;
  Timer? _sessionPoll;
  Timer? _commentPoll;
  Timer? _callPoll;
  Timer? _hostConnectWatchdog;
  DateTime? _lastPresenceHeartbeat;
  int _hostSessionMissingCount = 0;
  static const int hostConnectTimeoutSecs = 75;
  int _lastCommentServerId = 0;
  bool _commentPollBusy = false;
  bool _callPollBusy = false;
  final Set<int> _seenIncomingCallIds = {};
  bool _callPollPrimed = false;

  VideoPlayerController? dummyPlayer;

  /// A/V LiveKit (null en dummy / web).
  LiveKitRoomController? liveKit;

  String get roomId => livestream.roomID ?? '${livestream.hostId}';

  /// Sala LiveKit compartida del PK (sala del que invitó).
  String get avRoomId {
    final primary = (livestream.battlePrimaryRoomId ?? '').trim();
    if (primary.isNotEmpty) return primary;
    final linked = (livestream.battleLinkedRoomId ?? '').trim();
    // Si soy el rival con sala propia, A/V va a la sala linkeada (invitador).
    if (linked.isNotEmpty && isHost && !isBattlePrimaryHost) return linked;
    return roomId;
  }

  bool get isBattlePrimaryHost {
    final primary = (livestream.battlePrimaryRoomId ?? '').trim();
    if (primary.isEmpty) return isHost;
    return roomId == primary;
  }

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

  /// Soy el rival de la batalla (publico cámara en la sala A/V del invitador).
  bool get isBattleOpponentPublisher {
    final inBattle = isBattleRunning.value || isBattleWaiting.value;
    if (!inBattle) return false;
    final me = SessionManager.instance.getUserID();
    if (me <= 0) return false;
    // Audiencia co-host clásico.
    if (!isHost && battleOpponentId.value == me) return true;
    // Host de sala linkeada (no primaria): rival con su propio LIVE.
    if (isHost && !isBattlePrimaryHost) return true;
    return false;
  }

  /// Sala LIVE del rival (para ir a apoyarlo).
  String? get opponentLiveRoomId {
    if (!(isBattleRunning.value || isBattleWaiting.value)) return null;
    if (isBattlePrimaryHost) {
      final linked = (livestream.battleLinkedRoomId ?? '').trim();
      return linked.isEmpty ? null : linked;
    }
    final primary = (livestream.battlePrimaryRoomId ?? '').trim();
    if (primary.isNotEmpty) return primary;
    final linked = (livestream.battleLinkedRoomId ?? '').trim();
    return linked.isEmpty ? null : linked;
  }

  /// ID equipo rojo (invitador / sala primaria).
  int get battleRedUserId {
    final primary = (livestream.battlePrimaryRoomId ?? '').trim();
    final myHost = livestream.hostId ?? 0;
    // Sala primaria: el host local es el equipo rojo.
    if (primary.isEmpty || primary == roomId) {
      return myHost;
    }
    // Sala del rival: el rojo es el invitador (en co-hosts), NUNCA el host local
    // (si no, ambos paneles resuelven a la misma cámara).
    for (final id in livestream.coHostIds ?? const <int>[]) {
      if (id > 0 && id != myHost) return id;
    }
    final cachedOpp = battleOpponentId.value ?? 0;
    if (cachedOpp > 0 && cachedOpp != myHost) return cachedOpp;
    return 0;
  }

  /// ID equipo azul (rival).
  int get battleBlueUserId {
    final red = battleRedUserId;
    final myHost = livestream.hostId ?? 0;
    if (myHost > 0 && myHost != red) return myHost;
    for (final id in livestream.coHostIds ?? const <int>[]) {
      if (id > 0 && id != red) return id;
    }
    final opp = battleOpponentId.value ?? 0;
    if (opp > 0 && opp != red) return opp;
    return 0;
  }

  bool get shouldPublishAv => isHost || isBattleOpponentPublisher;

  Participant? participantForUserId(int userId) {
    if (userId <= 0) return null;
    final id = '$userId';
    final local = liveKit?.localParticipant.value;
    if (local?.identity == id) return local;
    for (final p in liveKit?.remoteParticipants ?? const <RemoteParticipant>[]) {
      if (p.identity == id) return p;
    }
    return null;
  }

  @override
  void onInit() {
    super.onInit();
    if (Get.isRegistered<DynamicTranslations>()) {
      Get.find<DynamicTranslations>().ensureLiveFallbacks();
    }
    activeInstance = this;
    if (!isHost) {
      CallAvailability.watchingLiveHostId = livestream.hostId;
    }
    _enterImmersiveLive();
    selectedGiftUser.value = livestream.hostUser;
    invitedIds.addAll(livestream.coHostIds ?? []);
    watchingCount.value = livestream.watchingCount ?? 0;
    likeCount.value = livestream.likeCount ?? 0;
    _lastSeenLikeCount = likeCount.value;
    _hydrateGiftIncentives(livestream.giftIncentives);
    // Si entro ya en batalla (p.ej. rival aceptó), preparar estado antes de LiveKit.
    _syncBattleFromSession(livestream, const []);
    // Default de apoyo: perfil del LIVE que estoy viendo (host de la sala).
    if (isBattleRunning.value || isBattleWaiting.value) {
      battleLikeForUserId.value ??= livestream.hostId;
    }
    _startLiveElapsedTicker();
    if (isHost) {
      beautyShader.load().then((_) => applyBeauty());
    }
    commentFocusNode.addListener(_onCommentFocusChanged);
    unawaited(refreshUnreadChats());
    _armHostConnectWatchdog();
    _bootstrap();
  }

  void _onCommentFocusChanged() {
    if (commentFocusNode.hasFocus) {
      chatComposerExpanded.value = true;
    }
  }

  void expandChatComposer() {
    chatComposerExpanded.value = true;
    Future.microtask(() => commentFocusNode.requestFocus());
  }

  void collapseChatComposer() {
    if (commentController.text.trim().isNotEmpty) return;
    commentFocusNode.unfocus();
    chatComposerExpanded.value = false;
  }

  void _startLiveElapsedTicker() {
    final created = livestream.createdAt;
    if (created != null && created > 0) {
      // Backend envía created_ms (epoch ms).
      _liveStartedAt = DateTime.fromMillisecondsSinceEpoch(created);
    } else {
      _liveStartedAt = DateTime.now();
    }
    _tickLiveElapsed();
    _liveElapsedTicker?.cancel();
    _liveElapsedTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      _tickLiveElapsed();
    });
  }

  void _tickLiveElapsed() {
    // Si el LIVE está pausado o hay llamada, congelar el badge de tiempo.
    if (isStreamPaused.value || pausedForCall.value || hostInCall.value) {
      return;
    }
    final start = _liveStartedAt;
    if (start == null) return;
    final secs = DateTime.now().difference(start).inSeconds;
    liveElapsedSeconds.value = secs < 0 ? 0 : secs;
  }

  /// Al pausar/reanudar: congelar o reanudar el contador del badge.
  void _syncElapsedTimerWithPause() {
    if (isStreamPaused.value || pausedForCall.value || hostInCall.value) {
      return;
    }
    // Reanudar: el "inicio" se recalcula para continuar desde el valor congelado.
    final frozen = liveElapsedSeconds.value;
    _liveStartedAt =
        DateTime.now().subtract(Duration(seconds: frozen < 0 ? 0 : frozen));
    _tickLiveElapsed();
  }

  String get liveElapsedLabel {
    final total = liveElapsedSeconds.value;
    final h = total ~/ 3600;
    final m = (total % 3600) ~/ 60;
    final s = total % 60;
    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:'
          '${m.toString().padLeft(2, '0')}:'
          '${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  void openLiveTasks() {
    openLiveTasksSheet();
  }

  /// Desplegable de tareas (mismo estilo que Options).
  void openLiveTasksSheet() {
    openLiveTasksMenu();
  }

  Future<void> _broadcastJoin() async {
    if (isHost) return;
    final me = SessionManager.instance.getUser();
    if (me?.id == null) return;
    final clientId = '${me!.id}_join_${DateTime.now().millisecondsSinceEpoch}';
    final name = _liveDisplayName(me);
    final level = me.getLevel;
    final levelNum = me.levelNumber ?? level.level ?? 1;
    final levelTitle = (me.levelTitle ?? level.title ?? '').trim();
    final isSvip = level.isSvipLevel == 1;
    final isVip = me.isVipActive;
    // Video desde el nivel del usuario o catálogo settings (LV 5/6, etc.).
    final entranceVideo =
        (_entranceVideoForLevelNumber(levelNum) ?? (level.entranceVideo ?? ''))
            .trim();
    final joinText = isVip
        ? '👑 VIP ha entrado al LIVE'
        : (isSvip || levelNum >= 8
            ? LKey.arrivedInStyle.tr
            : (levelNum >= 4 ? LKey.joinedShort.tr : LKey.joinedTheLive.tr));
    final msg = LiveChatMessage(
      id: clientId,
      userId: me.id!,
      userName: name,
      type: 'join',
      text: joinText,
      entranceVideo: entranceVideo.isEmpty ? null : entranceVideo,
      userLevel: levelNum,
      levelTitle: isVip ? 'VIP' : (levelTitle.isEmpty ? null : levelTitle),
      isSvip: isSvip,
      isVip: isVip,
    );
    _appendChatMessage(msg);
    try {
      // Payload con meta para hosts que solo reciben el poll de comentarios.
      final safeVideo = entranceVideo.replaceAll('|', '%7C');
      await LiveSessionService.instance.sendComment(
        roomId: roomId,
        clientId: clientId,
        type: 'text',
        text:
            '👋JOIN|$levelNum|${isSvip ? 1 : 0}|$safeVideo|$name $joinText|${isVip ? 1 : 0}',
      );
    } catch (_) {}
    try {
      await liveKit?.publishData(msg.toBytes());
    } catch (_) {}
  }

  /// Video de entrada del catálogo `userLevels` por número de nivel.
  String? _entranceVideoForLevelNumber(int levelNum) {
    if (levelNum <= 0) return null;
    final levels = SessionManager.instance.getSettings()?.userLevels ?? [];
    for (final l in levels) {
      if (l.level == levelNum) {
        final v = (l.entranceVideo ?? '').trim();
        return v.isEmpty ? null : v;
      }
    }
    return null;
  }

  /// Oculta barra de navegación / status del sistema durante el LIVE.
  void _enterImmersiveLive() {
    if (kIsWeb) return;
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  void _exitImmersiveLive() {
    if (kIsWeb) return;
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );
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
        // Precargar traductor: comentarios de Clientes → idioma del Streamer.
        unawaited(ChatTranslatorService.instance.preloadForUserLanguage());
        // Publicar/actualizar doc en Firestore para que el listado muestre
        // también la sala del rival en PK (no solo la del invitador).
        unawaited(_publishLiveDocToFirestore());
      }
      // Web también entra a LiveKit (chat data + video). Host en web puede
      // fallar cámara; el chat API sigue funcionando.
      await _joinLiveKit();
      if (isHost && liveKit?.isConnected.value == true) {
        _disarmHostConnectWatchdog();
      }
      _startSessionPolling();
      _startCommentPolling();
      _startIncomingCallPolling();
      // Avisar en el chat que este viewer entró.
      if (!isHost) {
        unawaited(_broadcastJoin());
      }
      // Mantener presencia ACTIVE mientras el LIVE sigue abierto.
      unawaited(UserService.instance.updateLastUsedAt());
      mediaReady.value = true;
      if (liveKit == null || liveKit!.isConnected.value != true) {
        if (statusMessage.value.isEmpty) {
          statusMessage.value = 'Sin video. Toca Reintentar.';
        }
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
    _callPoll = Timer.periodic(const Duration(seconds: 5), (_) {
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
      _hydrateGiftIncentives(payload.session.giftIncentives);
      livestream.watchingCount = watchingCount.value;
      livestream.likeCount = likeCount.value;
      _syncBattleFromSession(payload.session, payload.participants);
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
      text: LKey.isFollowingYou.tr,
    );
    _appendChatMessage(msg);
    try {
      await LiveSessionService.instance.sendComment(
        roomId: roomId,
        clientId: clientId,
        type: 'text',
        text: 'ðŸ‘¤ $name ${LKey.isFollowingYou.tr}',
      );
    } catch (_) {}
    try {
      await liveKit?.publishData(msg.toBytes());
    } catch (_) {}
  }

  void setReplyTo(LiveChatMessage message) {
    if (message.type == 'like' || message.type == 'follow') return;
    replyingTo.value = message;
    expandChatComposer();
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
      _syncElapsedTimerWithPause();
      update();
      return;
    }
    await lk.toggleStreamPaused(asHost: isHost);
    isStreamPaused.value = lk.streamPaused.value;
    _syncElapsedTimerWithPause();
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
                LKey.giftsReceived.tr,
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
                        LKey.noGiftsYet.tr,
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
                            '${s.giftCount} ${LKey.gift.tr}',
                          ),
                          trailing: Text(
                            LKey.coinsCount.trParams({'count': '${s.totalCoins}'}),
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

  void _applyBattleCoinsFromServer(int? hostCoin, int? oppCoin) {
    if (hostCoin != null) battleHostCoins.value = hostCoin;
    if (oppCoin != null) battleOpponentCoins.value = oppCoin;
  }

  void _applyGiftSendersFromServer(List<LiveGiftSender>? remote) {
    if (remote == null) return;
    // Reemplazar con el tab del servidor (también para audiencia).
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

  void _hydrateGiftIncentives(List<LiveGiftIncentive>? remote) {
    final catalog = SessionManager.instance.getSettings()?.gifts ?? [];
    final byId = <int, Gift>{
      for (final g in catalog)
        if (g.id != null) g.id!: g,
    };
    final source = remote ?? livestream.giftIncentives ?? const [];
    final hydrated = <LiveGiftIncentive>[];
    for (final slot in source) {
      if (!slot.isConfigured) continue;
      final gift = byId[slot.giftId];
      hydrated.add(slot.copyWith(
        coinPrice: slot.coinPrice ?? gift?.coinPrice,
        image: (slot.image ?? '').isNotEmpty ? slot.image : gift?.image,
        message: slot.trimmedMessage,
      ));
    }
    hydrated.sort((a, b) => a.position.compareTo(b.position));
    giftIncentives.assignAll(hydrated);
    livestream.giftIncentives = hydrated;
  }

  LiveGiftIncentive? incentiveForGift(int? giftId) {
    if (giftId == null || giftId <= 0) return null;
    return giftIncentives.firstWhereOrNull((e) => e.giftId == giftId);
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

  void _showJoinBanner(LiveChatMessage msg) {
    if (!msg.isNotableJoin) return;
    joinBanner.value = msg;
    _joinBannerTimer?.cancel();
    final secs = msg.isVip || msg.isSvip || (msg.userLevel ?? 0) >= 8 ? 5 : 4;
    _joinBannerTimer = Timer(Duration(seconds: secs), () {
      if (joinBanner.value?.id == msg.id) {
        joinBanner.value = null;
      }
    });
  }

  /// Completa video de entrada desde settings si el mensaje trae nivel.
  String? _resolveEntranceVideo(LiveChatMessage msg) {
    final direct = (msg.entranceVideo ?? '').trim();
    if (direct.isNotEmpty) return direct;
    final levelNum = msg.userLevel;
    if (levelNum == null || levelNum <= 0) return null;
    return _entranceVideoForLevelNumber(levelNum);
  }

  void _startSessionPolling() {
    _sessionPoll?.cancel();
    _sessionPoll = Timer.periodic(const Duration(seconds: 5), (_) {
      _refreshSessionStats(silent: true);
    });
  }

  Future<void> _refreshSessionStats({bool silent = false}) async {
    try {
      final now = DateTime.now();
      if (_lastPresenceHeartbeat == null ||
          now.difference(_lastPresenceHeartbeat!).inSeconds >= 30) {
        _lastPresenceHeartbeat = now;
        unawaited(UserService.instance.updateLastUsedAt());
      }
      final payload =
          await LiveSessionService.instance.fetchSession(roomId: roomId);
      if (payload == null) {
        // Live terminado / sala muerta → otro LIVE o salir.
        if (isEnding.value) return;
        if (!isHost) {
          await leaveAndRedirectToNextLive();
        } else {
          _hostSessionMissingCount++;
          if (_hostSessionMissingCount >= 3) {
            showSnackBar('El LIVE se cerró');
            await endOrLeave();
          }
        }
        return;
      }
      _hostSessionMissingCount = 0;
      var watch = payload.session.watchingCount ?? 0;
      if (isHost && liveKit != null) {
        final remotes = liveKit!.remoteParticipants.length;
        if (remotes > watch) watch = remotes;
      }
      watchingCount.value = watch;
      final newLikes = payload.session.likeCount ?? likeCount.value;
      _applyRemoteLikeCount(newLikes);
      _applyGiftSendersFromServer(payload.session.giftSenders);
      _hydrateGiftIncentives(payload.session.giftIncentives);
      livestream.watchingCount = watchingCount.value;
      livestream.likeCount = likeCount.value;
      _syncBattleFromSession(payload.session, payload.participants);
    } catch (e) {
      if (!silent) Loggers.error('fetchSession: $e');
      if (!isHost && !isEnding.value) {
        // Si la API falla de forma persistente tras end, forzar salida.
        final msg = e.toString().toLowerCase();
        if (msg.contains('not found') || msg.contains('ended')) {
          await leaveAndRedirectToNextLive();
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
      // Incluir '' para limpiar "Leaving…" / estados tras pause/resume de llamada.
      statusMessage.value = msg;
    });
    ever(liveKit!.mediaRevision, (_) {
      _syncViewersFromLiveKit();
      _checkHostPresence();
      if (isHost) {
        applyBeauty();
      }
      update();
    });

    try {
      await liveKit!.connect(
        roomName: avRoomId,
        identity: '${me.id}',
        name: me.fullname ?? me.username ?? 'user',
        // Host o rival de PK publican A/V; resto solo reciben.
        publishCamera: shouldPublishAv,
        publishMicrophone: shouldPublishAv,
        wsUrl: liveKitWsUrl,
        forceProfile: LiveKitQualityProfile.medium,
        // Si quedó una conexión fantasma (sala no cerrada), forzar rejoin.
        forceReconnect: liveKit!.isConnected.value &&
            liveKit!.connectedRoomName != avRoomId,
      );
      _connectedLiveKitRoom = avRoomId;
      if (isHost) {
        _disarmHostConnectWatchdog();
        await applyBeauty();
      }
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
    _checkHostPresence();

    update();
  }

  void _armHostConnectWatchdog() {
    if (!isHost || isDummy) return;
    _hostConnectWatchdog?.cancel();
    _hostConnectWatchdog = Timer(
      const Duration(seconds: hostConnectTimeoutSecs),
      () {
        if (isEnding.value || pausedForCall.value || isCallUiActive) return;
        if (liveKit?.isConnected.value == true) return;
        Loggers.error('host LiveKit never connected; ending live');
        statusMessage.value = 'No se pudo conectar. Cerrando LIVE…';
        showSnackBar('No se pudo conectar al LIVE');
        unawaited(endOrLeave());
      },
    );
  }

  void _disarmHostConnectWatchdog() {
    _hostConnectWatchdog?.cancel();
    _hostConnectWatchdog = null;
  }

  /// Reintenta LiveKit forzando calidad baja (red débil).
  Future<void> retryLiveConnection() async {
    if (pausedForCall.value && isCallUiActive) return;
    if (isHost) {
      _armHostConnectWatchdog();
    }
    final me = SessionManager.instance.getUser();
    if (me == null || liveKit == null) {
      await _joinLiveKit();
      update();
      return;
    }
    statusMessage.value = 'Reintentando en calidad baja…';
    try {
      await liveKit!.reconnectLowQuality(
        roomName: avRoomId,
        identity: '${me.id}',
        name: me.fullname ?? me.username ?? 'user',
        publishCamera: shouldPublishAv,
        publishMicrophone: shouldPublishAv,
        wsUrl: liveKitWsUrl,
      );
      _dataSub?.cancel();
      _dataSub = liveKit!.onDataReceived.listen(_onLiveData);
      if (liveKit!.isConnected.value) {
        pausedForCall.value = false;
        statusMessage.value = '';
        _syncElapsedTimerWithPause();
        _disarmHostConnectWatchdog();
      }
    } catch (e) {
      statusMessage.value = 'No se pudo conectar. Revisa tu red.';
      Loggers.error('retryLiveConnection: $e');
    }
    update();
  }

  String qualityLabel(LiveKitQualityProfile p) => switch (p) {
        LiveKitQualityProfile.low => LKey.qualityLow.tr,
        LiveKitQualityProfile.medium => LKey.qualityMedium.tr,
        LiveKitQualityProfile.high => LKey.qualityHigh.tr,
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
                  LKey.videoQuality.tr,
                  textAlign: TextAlign.center,
                  style: TextStyleCustom.unboundedSemiBold600(
                    color: Colors.black87,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  LKey.qualityHint.tr,
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
                            ? LKey.qualityLowHint.tr
                            : p == LiveKitQualityProfile.medium
                                ? LKey.qualityMediumHint.tr
                                : LKey.qualityHighHint.tr,
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
  /// Formato corto: ðŸŽGIFT|{giftId}|{coins}|  (sin URL larga → evita max length)
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
    if (msg.type == 'join') return msg;
    if (msg.type == 'gift_boost' || msg.type == 'call_invite') return msg;
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
          entranceVideo: msg.entranceVideo,
        );
      }
      return msg;
    }
    final text = (msg.text ?? '').trim();
    if (text.isEmpty) return msg;

    final callInvite = RegExp(r'CALL_INVITE\|(\d+)\|(.*)').firstMatch(text);
    if (callInvite != null) {
      return LiveChatMessage(
        id: msg.id,
        userId: msg.userId,
        userName: msg.userName,
        type: 'call_invite',
        text: (callInvite.group(2) ?? LKey.invitesToPrivateCall.tr).trim(),
        giftCoins: int.tryParse(callInvite.group(1) ?? '0') ?? 0,
        createdAt: msg.createdAt,
      );
    }
    final giftBoost = RegExp(r'BOOST\|(\d+)\|(.*)').firstMatch(text);
    if (giftBoost != null) {
      final giftId = int.tryParse(giftBoost.group(1) ?? '');
      return LiveChatMessage(
        id: msg.id,
        userId: msg.userId,
        userName: msg.userName,
        type: 'gift_boost',
        text: (giftBoost.group(2) ?? LKey.sendMeGifts.tr).trim(),
        giftId: giftId,
        giftImage: _resolveGiftImage(giftId),
        createdAt: msg.createdAt,
      );
    }

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
        text: LKey.sentAGift.tr,
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
        text: LKey.sentAGift.tr,
        giftId: giftId,
        giftCoins: giftCoins,
        giftImage: image,
        createdAt: msg.createdAt,
      );
    }

    // Formato legado: "ðŸŽ Name sent a gift" / "ðŸŽ|id|coins|img|"
    final legacy = RegExp(r'ðŸŽ\|(\d*)\|(\d*)\|([^|]*)\|').firstMatch(text);
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
        text: LKey.sentAGift.tr,
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
        text: LKey.sentAGift.tr,
        giftId: giftId,
        giftCoins: giftCoins,
        giftImage: image,
        createdAt: msg.createdAt,
      );
    }

    final lower = text.toLowerCase();
    if (text.contains('ðŸŽ') &&
        (lower.contains('sent a gift') ||
            lower.contains('envió un regalo') ||
            lower.contains('enviou um presente'))) {
      return LiveChatMessage(
        id: msg.id,
        userId: msg.userId,
        userName: msg.userName,
        type: 'gift',
        text: LKey.sentAGift.tr,
        createdAt: msg.createdAt,
      );
    }
    if (text.contains('ðŸ‘¤') ||
        lower.contains('te sigue') ||
        lower.contains('is following you') ||
        lower.contains('está te seguindo')) {
      return LiveChatMessage(
        id: msg.id,
        userId: msg.userId,
        userName: msg.userName,
        type: 'follow',
        text: LKey.isFollowingYou.tr,
        createdAt: msg.createdAt,
      );
    }
    final joinMeta =
        RegExp(r'JOIN\|(\d+)\|([01])\|([^|]*)\|(.*?)(?:\|([01]))?$')
            .firstMatch(text);
    if (joinMeta != null ||
        lower.contains('entró al live') ||
        lower.contains('entro al live') ||
        lower.contains('joined the live') ||
        lower.contains('arrived in style') ||
        lower.contains('entrou no live') ||
        text.contains('👋')) {
      final levelNum = joinMeta != null
          ? int.tryParse(joinMeta.group(1) ?? '')
          : null;
      final isSvip = joinMeta?.group(2) == '1';
      final isVip = joinMeta?.group(5) == '1' || msg.isVip;
      var video = (joinMeta?.group(3) ?? '').trim().replaceAll('%7C', '|');
      if (video.isEmpty && levelNum != null) {
        video = _entranceVideoForLevelNumber(levelNum) ?? '';
      }
      final rest = (joinMeta?.group(4) ?? text)
          .replaceFirst('👋', '')
          .trim();
      var joinText = rest;
      // Quitar nombre duplicado al inicio si viene "Name entró".
      if (joinText.toLowerCase().startsWith(msg.userName.toLowerCase())) {
        joinText = joinText.substring(msg.userName.length).trim();
      }
      joinText = joinText
          .replaceAll(RegExp(r'\s*[·•]\s*Lv\.?\s*\d+', caseSensitive: false), '')
          .replaceAll(RegExp(r'\s*Lv\.?\s*\d+', caseSensitive: false), '')
          .trim();
      if (joinText.isEmpty) joinText = LKey.joinedShort.tr;
      return LiveChatMessage(
        id: msg.id,
        userId: msg.userId,
        userName: msg.userName,
        type: 'join',
        text: joinText,
        entranceVideo: video.isEmpty ? null : video,
        userLevel: levelNum ?? msg.userLevel,
        levelTitle: isVip ? 'VIP' : msg.levelTitle,
        isSvip: isSvip || msg.isSvip,
        isVip: isVip,
        createdAt: msg.createdAt,
      );
    }
    return msg;
  }

  String? resolveGiftImage(int? giftId) {
    if (giftId == null) return null;
    final gifts = SessionManager.instance.getSettings()?.gifts ?? [];
    for (final g in gifts) {
      if (g.id == giftId && (g.image ?? '').isNotEmpty) return g.image;
    }
    return null;
  }

  String? _resolveGiftImage(int? giftId) => resolveGiftImage(giftId);

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

    if (msg.type == 'join') {
      final video = _resolveEntranceVideo(msg);
      if ((video != null && video.isNotEmpty) || msg.isVip) {
        LevelEntranceOverlay.show(
          video,
          userName: msg.userName,
          level: msg.userLevel,
          levelTitle: msg.isVip ? 'VIP' : msg.levelTitle,
          isSvip: msg.isSvip,
          isVip: msg.isVip,
        );
      }
      _showJoinBanner(msg);
    }

    if (msg.type == 'call_invite') {
      _handleCallInvite(msg);
      // También al chat para contexto.
    }
    if (msg.type == 'gift_boost') {
      _handleGiftBoost(msg);
    }

    final isFollow = msg.type == 'follow' ||
        (msg.type == 'text' &&
            ((msg.text ?? '').contains('te sigue') ||
                (msg.text ?? '').toLowerCase().contains('is following you')));
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

    // Traducir textos de otros usuarios al idioma de la app (como en CHATS).
    if (msg.type == 'text' &&
        !msg.isTranslated &&
        (msg.text ?? '').trim().isNotEmpty) {
      final raw = (msg.text ?? '').trim();
      final isProtocol = raw.contains('GIFT|') ||
          raw.contains('JOIN|') ||
          raw.contains('BOOST|') ||
          raw.contains('CALL_INVITE|');
      final me = SessionManager.instance.getUserID();
      if (!isProtocol && msg.userId != me) {
        unawaited(_translateLiveChat(msg));
      }
    }
  }

  Future<void> _translateLiveChat(LiveChatMessage msg) async {
    final original = (msg.text ?? '').trim();
    if (original.isEmpty) return;
    try {
      await ChatTranslatorService.instance.ensureReady(
        targetLangCode: SessionManager.instance.getLang(),
      );
      final translated = await ChatTranslatorService.instance.translateText(
        original,
        targetLangCode: SessionManager.instance.getLang(),
      );
      final out = translated.trim();
      if (out.isEmpty || out == original) return;
      final idx = chatMessages.indexWhere((m) => m.id == msg.id);
      if (idx < 0) return;
      // Si ya se tradujo (p. ej. poll + LiveKit), no pisar.
      if (chatMessages[idx].isTranslated) return;
      chatMessages[idx] = msg.copyWithTranslation(
        original: original,
        translated: out,
      );
      chatMessages.refresh();
    } catch (e) {
      Loggers.error('live chat translate: $e');
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
    // 3s: reduce carga API/MySQL (antes 1.2s → ~190 QPS en picos).
    _commentPoll = Timer.periodic(const Duration(seconds: 3), (_) {
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
            (msg.text ?? '').contains('ðŸŽ');
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
    if (GuestGate.block()) return;
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
      collapseChatComposer();
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

    // En PK el regalo va al streamer de ESTE LIVE (el que el cliente apoya).
    final host = livestream.hostUser ??
        AppUser(userId: hostId, fullname: liveTitle);
    selectedGiftUser.value = host;
    await GiftManager.openGiftSheet(
      userId: hostId,
      giftType: isBattleRunning.value ? GiftType.battle : GiftType.livestream,
      battleViewType:
          hostId == battleBlueUserId ? BattleView.blue : BattleView.red,
      streamUsers: [host],
      onCompletion: (gm) async {
        GiftManager.showAnimationDialog(gm.gift);
        await broadcastGift(gm.gift, battleForUserId: hostId);
      },
    );
  }

  /// Envía un regalo concreto al host sin abrir el sheet (boost / slider).
  bool _sendingDirectGift = false;

  Future<void> sendGiftDirectly({
    int? giftId,
    String? giftImage,
    int? coinPrice,
  }) async {
    if (GuestGate.block()) return;
    if (isHost) return;
    if (_sendingDirectGift) return;
    final hostId = livestream.hostId;
    if (hostId == null) return;
    final meId = SessionManager.instance.getUserID();
    if (meId != 0 && meId == hostId) return;
    if (giftId == null || giftId <= 0) {
      await openGiftSheet();
      return;
    }

    Gift? gift;
    final catalog = SessionManager.instance.getSettings()?.gifts ?? [];
    for (final g in catalog) {
      if (g.id == giftId) {
        gift = Gift(
          id: g.id,
          categoryId: g.categoryId,
          coinPrice: g.coinPrice,
          title: g.title,
          image: g.image,
          isFullscreen: g.isFullscreen,
        );
        break;
      }
    }
    gift ??= Gift(
      id: giftId,
      image: giftImage ?? resolveGiftImage(giftId),
      coinPrice: coinPrice,
    );
    if ((gift.image ?? '').isEmpty && (giftImage ?? '').isNotEmpty) {
      gift.image = giftImage;
    }
    if ((gift.coinPrice ?? 0) <= 0 && (coinPrice ?? 0) > 0) {
      gift.coinPrice = coinPrice;
    }

    var price = gift.coinPrice ?? 0;
    if (price <= 0) {
      for (final g in catalog) {
        if (g.id == giftId && (g.coinPrice ?? 0) > 0) {
          price = g.coinPrice!;
          gift.coinPrice = price;
          break;
        }
      }
    }
    if (price <= 0 && (coinPrice ?? 0) > 0) {
      price = coinPrice!;
      gift.coinPrice = price;
    }
    if (price <= 0) {
      showSnackBar(LKey.giftNotAvailable.tr);
      return;
    }

    if (!CoinGate.ensureEnough(price, message: LKey.insufficientCoins.tr)) {
      return;
    }

    _sendingDirectGift = true;
    sendingGiftId.value = giftId;
    try {
      final detailed = await GiftWalletService.instance.sendGiftDetailed(
        giftId: giftId,
        userId: hostId,
        source: 'live',
      );
      if (!detailed.ok) {
        showSnackBar(detailed.message ?? LKey.giftNotAvailable.tr);
        return;
      }
      if (detailed.coinPrice > 0) {
        gift.coinPrice = detailed.coinPrice;
      }
      if ((detailed.image ?? '').isNotEmpty) {
        gift.image = detailed.image;
      }

      final me = SessionManager.instance.getUser();
      me?.removeCoinFromWallet(gift.coinPrice ?? price);
      SessionManager.instance.setUser(me);

      // Cerrar loader residual ANTES de la animación (Get.back pisa dialogs).
      stopLoader();
      GiftManager.showAnimationDialog(gift);
      await broadcastGift(gift, battleForUserId: hostId);
    } finally {
      sendingGiftId.value = null;
      _sendingDirectGift = false;
    }
  }

  /// Envía el regalo del slot de incentivo (slider cliente).
  Future<void> sendIncentiveGift(LiveGiftIncentive slot) async {
    await sendGiftDirectly(
      giftId: slot.giftId,
      giftImage: slot.image,
      coinPrice: slot.coinPrice,
    );
  }

  /// Publica el regalo para que host/audiencia lo vean (anim + chat + tab).
  Future<void> broadcastGift(Gift gift, {int? battleForUserId}) async {
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
      text: LKey.sentAGift.tr,
      giftId: gift.id,
      giftImage: image,
      giftCoins: coins,
    );
    // Ya se animó en openGiftSheet; aquí solo chat + tab.
    _appendChatMessage(msg, animateGift: false);
    // Payload corto (sin URL): evita max length del API y parseo frágil.
    final encoded =
        'ðŸŽGIFT|${gift.id ?? 0}|$coins| $name ${LKey.sentAGift.tr} · $coins ${LKey.coins.tr}';
    try {
      await LiveSessionService.instance.sendComment(
        roomId: roomId,
        clientId: clientId,
        type: 'text',
        text: encoded,
      );
    } catch (e) {
      Loggers.error('broadcastGift api: $e');
    }
    var forUserId = battleForUserId ?? 0;
    if (forUserId <= 0 && isBattleRunning.value) {
      forUserId = livestream.hostId ?? 0;
    }
    if (gift.id != null) {
      try {
        final recorded = await LiveSessionService.instance.recordGift(
          roomId: roomId,
          giftId: gift.id!,
          coins: coins,
          image: image,
          clientId: clientId,
          battleForUserId: forUserId > 0 ? forUserId : null,
        );
        _applyGiftSendersFromServer(recorded.senders);
        _applyBattleCoinsFromServer(
          recorded.battleHostCoin,
          recorded.battleOpponentCoin,
        );
      } catch (e2) {
        Loggers.error('broadcastGift recordGift: $e2');
      }
    }
    try {
      await liveKit?.publishData(msg.toBytes());
    } catch (_) {}
  }

  Future<void> openPrivateCall({bool skipConfirmSheet = false}) async {
    if (isHost) return;
    final hostId = livestream.hostId;
    if (hostId == null) return;

    showLoader();
    try {
      final hostUser =
          await UserService.instance.fetchUserDetails(userId: hostId);
      stopLoader();
      if (hostUser == null) {
        showSnackBar(LKey.somethingWentWrong.tr);
        return;
      }

      final canReceive = hostUser.canReceiveCalls == 1 ||
          hostUser.getLevel.canReceiveCalls == 1;
      if (!canReceive) {
        showSnackBar(LKey.callCannotReceive.tr);
        return;
      }

      final cost = CallAvailability.callCost(hostUser);
      final hostApp = livestream.hostUser ??
          AppUser(
            userId: hostId,
            fullname: hostUser.fullname,
            username: hostUser.username,
            profile: hostUser.profilePhoto,
          );

      void goOutgoing() {
        unawaited(pauseLiveKitForCall());
        Get.to(() => OutgoingCallScreen(callee: hostUser, cost: cost));
      }

      if (skipConfirmSheet) {
        goOutgoing();
        return;
      }

      await Get.bottomSheet(
        LivePrivateCallSheet(
          host: hostApp,
          cost: cost,
          onConfirm: () {
            Get.back();
            goOutgoing();
          },
        ),
        isScrollControlled: true,
      );
    } catch (e) {
      stopLoader();
      showSnackBar(e.toString());
    }
  }

  /// Host: sheet con regalos activos + incentiva a la audiencia.
  Future<void> openGiftBoostSheet() async {
    if (!isHost) return;
    final configured = giftIncentives.toList();
    final gifts = configured.isNotEmpty
        ? configured
            .map((e) => Gift(
                  id: e.giftId,
                  coinPrice: e.coinPrice,
                  image: e.image,
                ))
            .toList()
        : (SessionManager.instance.getSettings()?.gifts ?? []);
    if (gifts.isEmpty) {
      showSnackBar(configured.isEmpty
          ? LKey.noActiveGifts.tr
          : LKey.noIncentivizedGifts.tr);
      return;
    }
    await Get.bottomSheet(
      LiveGiftBoostSheet(
        gifts: gifts,
        incentives: configured,
        onBoost: (gift) {
          final incentive = gift == null
              ? null
              : incentiveForGift(gift.id) ??
                  configured.firstWhereOrNull((e) => e.giftId == gift.id);
          unawaited(broadcastGiftBoost(gift, incentive: incentive));
        },
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  Future<void> broadcastGiftBoost(
    Gift? gift, {
    LiveGiftIncentive? incentive,
  }) async {
    if (!isHost) return;
    final me = SessionManager.instance.getUser();
    if (me?.id == null) return;
    final clientId =
        '${me!.id}_giftboost_${DateTime.now().millisecondsSinceEpoch}';
    final name = _liveDisplayName(me);
    final coins = incentive?.coinPrice ?? gift?.coinPrice ?? 0;
    final customMsg = (incentive?.trimmedMessage ?? '').trim();
    final text = gift == null
        ? LKey.sendMeGifts.tr
        : (customMsg.isNotEmpty
            ? '$customMsg ($coins)'
            : '${LKey.giftMe.tr} ($coins ${LKey.coins.tr})');
    final msg = LiveChatMessage(
      id: clientId,
      userId: me.id!,
      userName: name,
      type: 'gift_boost',
      text: text,
      giftId: gift?.id ?? incentive?.giftId,
      giftImage: gift?.image ?? incentive?.image,
      giftCoins: coins > 0 ? coins : gift?.coinPrice,
    );
    _appendChatMessage(msg);
    try {
      await LiveSessionService.instance.sendComment(
        roomId: roomId,
        clientId: clientId,
        type: 'text',
        text: '🎁BOOST|${gift?.id ?? incentive?.giftId ?? 0}|$text',
      );
    } catch (_) {}
    try {
      await liveKit?.publishData(msg.toBytes());
    } catch (_) {}
    if (Get.isBottomSheetOpen == true) Get.back();
    showSnackBar('Invitación de regalos enviada');
  }

  /// Host: invita a todos los clientes a llamada privada (precio del streamer).
  Future<void> inviteAudienceToCall() async {
    if (!isHost) return;
    final me = SessionManager.instance.getUser();
    if (me?.id == null) return;
    final canReceive =
        me!.canReceiveCalls == 1 || me.getLevel.canReceiveCalls == 1;
    if (!canReceive) {
      showSnackBar('Tu nivel aún no puede recibir llamadas');
      return;
    }
    final cost = CallAvailability.callCost(me);

    final ok = await Get.dialog<bool>(
      AlertDialog(
        backgroundColor: const Color(0xFF1A1224),
        title: Text(
          'Invitar a llamada',
          style: TextStyleCustom.outFitMedium500(
            color: Colors.white,
            fontSize: 16,
          ),
        ),
        content: Text(
          cost > 0
              ? 'Se enviará una invitación a todos los viewers.\n'
                  'Precio: $cost coins.'
              : 'Se enviará una invitación a todos los viewers.',
          style: TextStyleCustom.outFitRegular400(
            color: Colors.white70,
            fontSize: 13,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text(LKey.cancel.tr,
                style: TextStyleCustom.outFitMedium500(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: Text(LKey.send.tr,
                style: TextStyleCustom.outFitMedium500(
                    color: ColorRes.themeAccentSolid)),
          ),
        ],
      ),
    );
    if (ok != true) return;

    final clientId =
        '${me.id}_callinvite_${DateTime.now().millisecondsSinceEpoch}';
    final name = _liveDisplayName(me);
    final msg = LiveChatMessage(
      id: clientId,
      userId: me.id!,
      userName: name,
      type: 'call_invite',
      text: 'te invita a una llamada privada',
      giftCoins: cost,
    );
    _appendChatMessage(msg);
    try {
      await LiveSessionService.instance.sendComment(
        roomId: roomId,
        clientId: clientId,
        type: 'text',
        text: '📞CALL_INVITE|$cost|$name te invita a una llamada privada',
      );
    } catch (_) {}
    try {
      await liveKit?.publishData(msg.toBytes());
    } catch (_) {}
    showSnackBar('Invitación de llamada enviada');
  }

  void _handleGiftBoost(LiveChatMessage msg) {
    if (isHost) return;
    if (!_seenGiftBoostIds.add(msg.id)) return;
    final coins = msg.giftCoins ?? 0;
    final title = msg.text ?? '¡La streamer pide regalos!';
    Get.snackbar(
      'Regalos',
      coins > 0 ? '$title 🎁' : title,
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.black87,
      colorText: Colors.white,
      margin: const EdgeInsets.all(12),
      borderRadius: 16,
      duration: const Duration(seconds: 5),
      onTap: (_) {
        Get.closeCurrentSnackbar();
        unawaited(sendGiftDirectly(
          giftId: msg.giftId,
          giftImage: msg.giftImage,
          coinPrice: msg.giftCoins,
        ));
      },
      icon: (msg.giftImage ?? '').isNotEmpty || msg.giftId != null
          ? Padding(
              padding: const EdgeInsets.all(6),
              child: GiftMedia(
                path: (msg.giftImage ?? '').isNotEmpty
                    ? msg.giftImage
                    : _resolveGiftImage(msg.giftId),
                width: 36,
                height: 36,
                fit: BoxFit.contain,
                muted: true,
                looping: true,
                placeholder: const Icon(Icons.card_giftcard,
                    color: ColorRes.accentPeach),
              ),
            )
          : const Icon(Icons.card_giftcard, color: ColorRes.accentPeach),
      mainButton: TextButton(
        onPressed: () {
          Get.closeCurrentSnackbar();
          unawaited(sendGiftDirectly(
            giftId: msg.giftId,
            giftImage: msg.giftImage,
            coinPrice: msg.giftCoins,
          ));
        },
        child: const Text(
          'Regalar',
          style: TextStyle(color: ColorRes.themeAccentSolid),
        ),
      ),
    );
  }

  void _handleCallInvite(LiveChatMessage msg) {
    if (isHost) return;
    if (!_seenCallInviteIds.add(msg.id)) return;
    showCallInviteDialog(msg);
  }

  void showCallInviteDialog(LiveChatMessage msg) {
    if (isHost) return;
    final cost = msg.giftCoins ?? 0;
    final name = msg.userName;
    Get.dialog(
      AlertDialog(
        backgroundColor: const Color(0xFF1A1224),
        title: Text(
          'Llamada privada',
          style: TextStyleCustom.outFitMedium500(
            color: Colors.white,
            fontSize: 16,
          ),
        ),
        content: Text(
          cost > 0
              ? '$name te invita a una videollamada.\nCosto: $cost coins.'
              : '$name te invita a una videollamada.',
          style: TextStyleCustom.outFitRegular400(
            color: Colors.white70,
            fontSize: 13,
          ),
        ),
        actions: [
          TextButton(
            onPressed: Get.back,
            child: Text(LKey.notNow.tr,
                style: TextStyleCustom.outFitMedium500(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              if (cost > 0 &&
                  !CoinGate.ensureEnough(
                    cost,
                    message: 'Moneda insuficiente para la llamada',
                  )) {
                return;
              }
              openPrivateCall(skipConfirmSheet: true);
            },
            child: Text(
              LKey.callAction.tr,
              style: TextStyleCustom.outFitMedium500(
                color: ColorRes.themeAccentSolid,
              ),
            ),
          ),
        ],
      ),
      barrierDismissible: true,
    );
  }

  Future<void> refreshUnreadChats() async {
    try {
      final result = await ChatService.instance.fetchThreads();
      var n = 0;
      for (final t in result.chats) {
        n += (t.msgCount ?? 0) > 0 ? 1 : 0;
      }
      for (final t in result.requests) {
        n += (t.msgCount ?? 0) > 0 ? 1 : 0;
      }
      unreadChatCount.value = n;
    } catch (_) {}
  }

  Future<void> openUnreadChatsSheet() async {
    await refreshUnreadChats();
    await Get.bottomSheet(
      const LiveUnreadChatsSheet(),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
    unawaited(refreshUnreadChats());
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
    hostInCall.value = true;
    pausedForCall.value = true;
    statusMessage.value = LKey.livePausedInCall.tr;
    update();
    try {
      await liveKit?.disconnect(silent: true);
    } catch (e) {
      Loggers.error('pauseLiveKitForCall: $e');
    } finally {
      update();
    }
  }

  /// Reconecta al LIVE tras colgar la videollamada.
  Future<void> resumeLiveKitAfterCall() async {
    if (_resumingAfterCall || isEnding.value) return;
    if (VideoCallController.activeInstance != null) return;
    _resumingAfterCall = true;
    hostInCall.value = false;
    pausedForCall.value = true;
    statusMessage.value = isHost ? 'Reconectando LIVE…' : 'Reconectando…';
    update();
    try {
      if (isDummy) {
        pausedForCall.value = false;
        statusMessage.value = '';
        update();
        return;
      }
      final me = SessionManager.instance.getUser();
      if (me == null) {
        statusMessage.value = 'Sin video. Toca Reintentar.';
        update();
        return;
      }

      Future<void> join() async {
        if (liveKit == null) {
          await _joinLiveKit();
          return;
        }
        try {
          await liveKit!.disconnect(silent: true);
        } catch (_) {}
        liveKit!.isConnecting.value = false;
        await Future<void>.delayed(const Duration(milliseconds: 500));
        await liveKit!.connect(
          roomName: avRoomId,
          identity: '${me.id}',
          name: me.fullname ?? me.username ?? 'user',
          publishCamera: shouldPublishAv,
          publishMicrophone: shouldPublishAv,
          wsUrl: liveKitWsUrl,
          forceReconnect: true,
        );
        _connectedLiveKitRoom = avRoomId;
        _dataSub?.cancel();
        _dataSub = liveKit!.onDataReceived.listen(_onLiveData);
        if (isHost) {
          await applyBeauty();
        }
      }

      try {
        await join();
      } catch (e) {
        Loggers.error('resumeLiveKitAfterCall first try: $e');
        await Future<void>.delayed(const Duration(milliseconds: 800));
        await join();
      }

      // El host puede tardar un poco en volver a publicar.
      if (!isHost && liveKit != null) {
        for (var i = 0; i < 10; i++) {
          if (liveKit!.isConnected.value &&
              liveKit!.remoteParticipants.isNotEmpty) {
            break;
          }
          await Future<void>.delayed(const Duration(milliseconds: 400));
        }
      }

      if (liveKit?.isConnected.value == true) {
        pausedForCall.value = false;
        statusMessage.value = '';
        _syncElapsedTimerWithPause();
      } else {
        statusMessage.value = 'Sin video. Toca Reintentar.';
      }
      update();
    } catch (e) {
      Loggers.error('resumeLiveKitAfterCall: $e');
      statusMessage.value = 'Sin video. Toca Reintentar.';
      update();
    } finally {
      _resumingAfterCall = false;
      _lastResumeAfterCallAt = DateTime.now();
    }
  }

  /// Si el LIVE volvió a verse tras una llamada y el video no está, reconecta.
  Future<void> ensureLiveKitAfterCallIfNeeded() async {
    if (!pausedForCall.value || _resumingAfterCall || isEnding.value) return;
    if (isCallUiActive) return;
    if (liveKit?.isConnected.value == true) {
      pausedForCall.value = false;
      if (statusMessage.value.isNotEmpty) statusMessage.value = '';
      update();
      return;
    }
    final last = _lastResumeAfterCallAt;
    if (last != null &&
        DateTime.now().difference(last) < const Duration(seconds: 3)) {
      return;
    }
    await resumeLiveKitAfterCall();
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

  /// Doble tap: like visual (no suma al marcador PK).
  Future<void> onBattleDoubleTap(Offset localPosition, Size areaSize) async {
    await sendLike();
  }

  Future<void> sendLike() async {
    if (isHost || isLiking.value) return;
    isLiking.value = true;
    // Feedback inmediato en el que da like.
    _pulseFloatingLike();
    try {
      final result = await LiveSessionService.instance.like(roomId: roomId);
      _lastSeenLikeCount = result.likeCount;
      likeCount.value = result.likeCount;
      livestream.likeCount = result.likeCount;
      final me = SessionManager.instance.getUser();
      if (me?.id != null) {
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

  /// Beauty: shader Flutter (overlay LIVE) + params GPUPixel nativos.
  /// Nota: sin gpuPixel.start() en LIVE (cámara = LiveKit). applyParams es no-op
  /// hasta ExternalVideoTrack; el overlay BeautyShader sí refleja los looks.
  Future<void> applyBeauty() async {
    if (kIsWeb || isDummy) return;
    await beautyShader.load();
    final style = selectedBeautyFilterId.value;
    final preset = style.isBeautyGpu ? style.beautyLook : null;
    if (!beautyOn.value || preset == null) {
      beautyShader.setLook(const BeautyLook(intensity: 0, mode: 0));
    } else {
      beautyShader.setLook(
        BeautyLook(
          intensity: preset.intensity.clamp(0.5, 1.0),
          mode: preset.mode,
          whiten: (whiten.value / 100.0).clamp(0.0, 1.0),
          rosy: (rosy.value / 100.0).clamp(0.0, 1.0),
          sharpen: (sharpen.value / 100.0).clamp(0.0, 1.0),
        ),
      );
    }
    await gpuPixel.applyParams(
      GpuPixelBeautyParams.fromSliders(
        enabled: beautyOn.value,
        whiten: whiten.value,
        smooth: smooth.value,
        slimFace: slimFace.value,
        bigEye: bigEye.value,
      ),
      debounce: false,
    );
  }

  /// Tap filtro DeepAR en LIVE.
  ///
  /// LiveKit publica la cámara nativa (DeepAR no puede compartir el sensor).
  /// Se conserva el ID seleccionado y se aplica un beauty suave como aproximación
  /// (evita el cast amarillo/oscuro del Soft forzado anterior).
  Future<void> onLiveDeepArFilterSelected(DeepARFilters? filter) async {
    selectedDeepArFilterId.value = filter?.id;
    if (filter == null) {
      selectedBeautyFilterId.value = FaceFilterId.none;
      beautyOn.value = false;
      await applyBeauty();
      return;
    }
    final title = (filter.title ?? '').toLowerCase();
    FaceFilterId mapped = FaceFilterId.beauty;
    if (title.contains('rose') || title.contains('pink')) {
      mapped = FaceFilterId.beautyRose;
    } else if (title.contains('warm') || title.contains('sun')) {
      mapped = FaceFilterId.beautyWarm;
    } else if (title.contains('fresh') || title.contains('cool')) {
      mapped = FaceFilterId.beautyFresh;
    } else if (title.contains('porcelain') || title.contains('white')) {
      mapped = FaceFilterId.beautyPorcelain;
    } else if (title.contains('natural')) {
      mapped = FaceFilterId.beautyNatural;
    } else if (title.contains('soft') || title.contains('makeup')) {
      mapped = FaceFilterId.beautySoft;
    }
    selectedBeautyFilterId.value = mapped;
    beautyOn.value = true;
    // Intensidades moderadas — no el Soft 85/70/90 que oscurecía/amarilleaba.
    whiten.value = 40;
    rosy.value = 25;
    smooth.value = 65;
    sharpen.value = 30;
    await applyBeauty();
  }

  void openBeauty() {
    // LIVE: LiveKit posee la cámara. No llamar gpuPixel.start() (conflicto Camera2).
    // Overlay local = BeautyShader; applyParams solo tiene efecto si el engine
    // nativo estuviera corriendo (ExternalVideoTrack pendiente).
    // Docs: https://gpupixel.pixpark.net/guide/intro
    openLiveFiltersSheet(
      beautyOn: beautyOn,
      onApply: applyBeauty,
      selectedFilterId: selectedBeautyFilterId,
      styleEffects: GpuPixelLooks.catalog,
      useDeepArFilters: false,
      whiten: whiten,
      smooth: smooth,
      rosy: rosy,
      sharpen: sharpen,
      slimFace: slimFace,
      bigEye: bigEye,
      onStyleSelected: (id) {
        selectedBeautyFilterId.value = id;
        beautyOn.value = id != FaceFilterId.none;
        GpuPixelLooks.applyToSliders(
          id,
          setBeautyOn: (on) => beautyOn.value = on,
          setWhiten: (v) => whiten.value = v,
          setSmooth: (v) => smooth.value = v,
          setSlimFace: (v) => slimFace.value = v,
          setBigEye: (v) => bigEye.value = v,
        );
        applyBeauty();
      },
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

  /// Abre sheet visible para iniciar Batalla (host).
  Future<void> openBattle() async {
    if (!isHost) return;
    if (isBattleRunning.value || isBattleWaiting.value) {
      await confirmEndBattle();
      return;
    }
    final setting = SessionManager.instance.getSettings();
    if (setting?.liveBattle == 0) {
      showSnackBar('Las batallas están desactivadas en la configuración.');
      return;
    }
    battleSelectedOpponentId.value = null;
    battleDurationMinutes.value = 5;
    await openLiveBattleSheet(
      candidates: inviteCandidates,
      loading: inviteLoading,
      selectedOpponentId: battleSelectedOpponentId,
      durationMinutes: battleDurationMinutes,
      onSearchLoad: _loadBattleCandidates,
      onSearch: _searchBattleCandidates,
      onStart: startBattleWithSelected,
    );
  }

  Future<void> startBattleWithSelected() async {
    final opponentId = battleSelectedOpponentId.value;
    if (opponentId == null || opponentId <= 0) {
      showSnackBar('Selecciona un rival');
      return;
    }
    try {
      final session = await LiveSessionService.instance.startBattle(
        roomId: roomId,
        opponentId: opponentId,
        durationMinutes: battleDurationMinutes.value,
      );
      _applyBattleSession(session);
      if (Get.isBottomSheetOpen == true) Get.back();
      showSnackBar('Invitación de batalla enviada');
      await _refreshSessionStats(silent: true);
    } catch (e) {
      Loggers.error('startBattle: $e');
      showSnackBar(e.toString());
    }
  }

  Future<void> confirmEndBattle() async {
    await _finishBattleWithResult(fromManualStop: true);
  }

  Future<void> endBattle() async {
    if (!isHost || _endingBattle) return;
    _endingBattle = true;
    final rivalId = isBattlePrimaryHost
        ? battleBlueUserId
        : battleRedUserId;
    try {
      // Cortar audio del rival de inmediato (antes del round-trip API).
      if (rivalId > 0) {
        await liveKit?.muteRemoteParticipantAudio('$rivalId');
      }
      final session =
          await LiveSessionService.instance.endBattle(roomId: roomId);
      _applyBattleSession(session);
      // Asegurar estado local aunque el poll tarde.
      isBattleRunning.value = false;
      isBattleWaiting.value = false;
      livestream.type = LivestreamType.livestream;
      livestream.battleType = BattleType.end;
      livestream.battleLinkedRoomId = null;
      livestream.battlePrimaryRoomId = null;
      await _rejoinOwnLiveRoomAfterBattle(muteRivalId: rivalId);
      update();
      showSnackBar('Batalla finalizada · volviste a tu LIVE');
    } catch (e) {
      Loggers.error('endBattle: $e');
      // Aun si falla API, salir del modo PK en UI.
      isBattleRunning.value = false;
      isBattleWaiting.value = false;
      livestream.battleLinkedRoomId = null;
      livestream.battlePrimaryRoomId = null;
      await _rejoinOwnLiveRoomAfterBattle(muteRivalId: rivalId);
      update();
      showSnackBar(e.toString());
    } finally {
      _endingBattle = false;
      _rematchPromptOpen = false;
    }
  }

  /// Timer o stop manual: mostrar ganador y luego preguntar rematch.
  Future<void> _finishBattleWithResult({bool fromManualStop = false}) async {
    if (!isHost || _endingBattle || _rematchPromptOpen) return;
    if (!isBattleRunning.value && !fromManualStop) return;
    await _revealBattleResult();
    await _promptBattleRematch(fromManualStop: fromManualStop);
  }

  BattleResultBanner _buildBattleResult() {
    final redCoins = battleHostCoins.value;
    final blueCoins = battleOpponentCoins.value;
    final redName = _battleRedDisplayName();
    final blueName = _battleBlueDisplayName();
    if (redCoins == blueCoins) {
      return BattleResultBanner(
        isDraw: true,
        winnerName: redName,
        loserName: blueName,
        winnerCoins: redCoins,
        loserCoins: blueCoins,
      );
    }
    final redWins = redCoins > blueCoins;
    return BattleResultBanner(
      isDraw: false,
      winnerName: redWins ? redName : blueName,
      loserName: redWins ? blueName : redName,
      winnerCoins: redWins ? redCoins : blueCoins,
      loserCoins: redWins ? blueCoins : redCoins,
    );
  }

  String _battleRedDisplayName() {
    if (isBattlePrimaryHost) {
      return livestream.hostUser?.fullname ??
          livestream.hostUser?.username ??
          SessionManager.instance.getUser()?.fullname ??
          'Team A';
    }
    // Sala del rival: el rojo es el invitador.
    final opp = battleOpponentName.value.trim();
    if (opp.isNotEmpty) return opp;
    return 'Invitador';
  }

  String _battleBlueDisplayName() {
    if (isBattlePrimaryHost) {
      final opp = battleOpponentName.value.trim();
      if (opp.isNotEmpty) return opp;
      return 'Rival';
    }
    // En mi sala linkeada yo soy el azul.
    return livestream.hostUser?.fullname ??
        livestream.hostUser?.username ??
        SessionManager.instance.getUser()?.fullname ??
        'Team B';
  }

  Future<void> _revealBattleResult() async {
    if (_battleResultShown) return;
    _battleResultShown = true;
    final result = _buildBattleResult();
    battleResultBanner.value = result;
    _battleResultClearTimer?.cancel();

    final text = result.isDraw
        ? 'PK: Empate (${result.winnerCoins} - ${result.loserCoins})'
        : 'PK: Gana ${result.winnerName} (${result.winnerCoins}) · '
            'Pierde ${result.loserName} (${result.loserCoins})';
    final me = SessionManager.instance.getUser();
    _appendChatMessage(LiveChatMessage(
      id: 'pk_result_${DateTime.now().millisecondsSinceEpoch}',
      userId: me?.id ?? 0,
      userName: 'Sistema',
      type: 'text',
      text: text,
    ));
    try {
      if (me?.id != null) {
        await LiveSessionService.instance.sendComment(
          roomId: roomId,
          clientId: 'pk_result_${me!.id}_${DateTime.now().millisecondsSinceEpoch}',
          type: 'text',
          text: text,
        );
      }
    } catch (_) {}

    await Future.delayed(const Duration(seconds: 3));
  }

  void _scheduleClearBattleResult({int seconds = 5}) {
    _battleResultClearTimer?.cancel();
    _battleResultClearTimer = Timer(Duration(seconds: seconds), () {
      battleResultBanner.value = null;
      _battleResultShown = false;
    });
  }

  /// Diálogo post-PK: otra batalla o salir del modo PK.
  Future<void> _promptBattleRematch({bool fromManualStop = false}) async {
    if (!isHost || _rematchPromptOpen || _endingBattle) return;
    if (!isBattleRunning.value && !fromManualStop) return;
    _rematchPromptOpen = true;
    try {
      final rematch = await Get.dialog<bool>(
        AlertDialog(
          title: Text(LKey.battleEndedTitle.tr),
          content: Text(
            fromManualStop
                ? LKey.anotherPkSameRival.tr
                : LKey.timeUpAnotherPk.tr,
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(result: false),
              child: Text(LKey.noLeave.tr),
            ),
            TextButton(
              onPressed: () => Get.back(result: true),
              child: Text(LKey.yesAnotherPk.tr),
            ),
          ],
        ),
        barrierDismissible: false,
      );

      // El rival rechazó / end remoto cerró el diálogo con false/null.
      if (rematch == true) {
        if (!isBattleRunning.value) {
          showSnackBar('El rival ya salió del PK');
          await _rejoinOwnLiveRoomAfterBattle();
          _scheduleClearBattleResult();
          return;
        }
        try {
          final session = await LiveSessionService.instance.restartBattle(
            roomId: roomId,
            durationMinutes: battleDurationMinutes.value,
          );
          _battleResultShown = false;
          battleResultBanner.value = null;
          _applyBattleSession(session);
          showSnackBar('Nueva PK iniciada');
        } catch (e) {
          Loggers.error('restartBattle: $e');
          showSnackBar(e.toString());
          if (isBattleRunning.value) {
            await endBattle();
          } else {
            await _rejoinOwnLiveRoomAfterBattle();
          }
          _scheduleClearBattleResult();
        }
      } else {
        // "No" o cerrado porque el otro terminó la PK.
        if (isBattleRunning.value) {
          await endBattle();
        } else {
          // Ya terminó en servidor: asegurar volver a sala propia.
          await _rejoinOwnLiveRoomAfterBattle();
          update();
        }
        _scheduleClearBattleResult();
      }
    } finally {
      _rematchPromptOpen = false;
    }
  }

  /// Tras PK: volver a la sala propia y dejar de oír al rival.
  Future<void> _rejoinOwnLiveRoomAfterBattle({int? muteRivalId}) async {
    if (liveKit == null || isDummy) return;

    if (muteRivalId != null && muteRivalId > 0) {
      await liveKit!.muteRemoteParticipantAudio('$muteRivalId');
    }

    final remotes = List<RemoteParticipant>.from(liveKit!.remoteParticipants);
    for (final p in remotes) {
      await liveKit!.muteRemoteParticipantAudio(p.identity);
    }

    _hostEverPublished = false;
    _clearHostAbsent();

    final current = _connectedLiveKitRoom ?? liveKit!.connectedRoomName;
    final onOwn = liveKit!.isConnected.value && current == roomId;
    final cameraOk = !shouldPublishAv || liveKit!.cameraEnabled.value;
    final needSwitch = !onOwn || !cameraOk;

    for (var attempt = 0; attempt < (needSwitch ? 3 : 1); attempt++) {
      await _syncLiveKitAvRoom(force: needSwitch);
      if (liveKit?.isConnected.value == true &&
          (_connectedLiveKitRoom == roomId ||
              liveKit!.connectedRoomName == roomId) &&
          (!shouldPublishAv || liveKit!.cameraEnabled.value)) {
        break;
      }
      await Future<void>.delayed(Duration(milliseconds: 400 * (attempt + 1)));
    }

    if (!isHost && liveKit != null) {
      for (var i = 0; i < 12; i++) {
        if (liveKit!.remoteParticipants.isNotEmpty) break;
        await Future<void>.delayed(const Duration(milliseconds: 400));
      }
    }
    if (liveKit?.remoteAudioMuted.value == true) {
      await liveKit!.setRemoteAudioMuted(false);
    }
    update();
  }

  void _syncBattleFromSession(
    Livestream session,
    List<LivestreamUserState> participants,
  ) {
    final hostId = session.hostId ?? livestream.hostId ?? 0;
    final hostRow = participants.firstWhereOrNull((p) => p.userId == hostId);
    final wasHostInCall = hostInCall.value;
    // Si el host local acaba de pausar para llamada, no bajar el flag por race del poll.
    if (isHost && pausedForCall.value) {
      hostInCall.value = true;
    } else if (hostRow != null) {
      hostInCall.value = hostRow.inCall;
    } else if (!isHost) {
      hostInCall.value = false;
    }
    if (wasHostInCall && !hostInCall.value) {
      _syncElapsedTimerWithPause();
    }

    final wasRunning = isBattleRunning.value;
    final prevRivalId = wasRunning
        ? (isBattlePrimaryHost ? battleBlueUserId : battleRedUserId)
        : 0;

    livestream.type = session.type;
    livestream.battleType = session.battleType;
    livestream.battleDuration = session.battleDuration;
    livestream.battleCreatedAt = session.battleCreatedAt;
    livestream.coHostIds = session.coHostIds;
    livestream.battleLinkedRoomId = session.battleLinkedRoomId;
    livestream.battlePrimaryRoomId = session.battlePrimaryRoomId;

    final running = session.type == LivestreamType.battle &&
        session.battleType == BattleType.running;
    final waiting = session.type == LivestreamType.battle &&
        session.battleType == BattleType.waiting;
    isBattleRunning.value = running;
    isBattleWaiting.value = waiting;
    if (!running && !waiting) {
      battleLikeForUserId.value = null;
    } else if (isHost) {
      unawaited(_publishLiveDocToFirestore());
    }

    final redId = battleRedUserId;
    final blueId = battleBlueUserId;
    // Siempre el rival (no uno mismo): primario → azul; linkeado → rojo.
    final rivalId = isBattlePrimaryHost ? blueId : redId;
    battleOpponentId.value = rivalId > 0 ? rivalId : null;

    if (rivalId > 0) {
      final fromParticipants =
          participants.firstWhereOrNull((p) => p.userId == rivalId);
      final fromUser = fromParticipants?.user;
      final fromInvite =
          inviteCandidates.firstWhereOrNull((u) => u.id == rivalId);
      final name = fromUser?.fullname ??
          fromUser?.username ??
          fromInvite?.fullname ??
          fromInvite?.username ??
          (isBattlePrimaryHost ? 'Rival' : 'Invitador');
      battleOpponentName.value = name;
      final photo = (fromUser?.profile ?? fromInvite?.profilePhoto ?? '').trim();
      battleOpponentPhoto.value = photo.isEmpty ? null : photo;
    } else {
      battleOpponentName.value = '';
      battleOpponentPhoto.value = null;
    }

    final hostState =
        participants.firstWhereOrNull((p) => p.userId == redId);
    final oppState = blueId <= 0
        ? null
        : participants.firstWhereOrNull((p) => p.userId == blueId);
    // Base 50/50 si aun no hay datos de participantes.
    battleHostCoins.value = hostState?.currentBattleCoin ?? (running ? 50 : 0);
    battleOpponentCoins.value =
        oppState?.currentBattleCoin ?? (running ? 50 : 0);

    if (running) {
      _ensureBattleTicker();
      _updateBattleRemaining();
      unawaited(_syncLiveKitAvRoom());
    } else {
      _battleTicker?.cancel();
      _battleTicker = null;
      battleRemainingSeconds.value = 0;
    }

    // Batalla terminó en servidor (otro host rechazó rematch / end): limpiar A/V.
    if (wasRunning && !running && !waiting) {
      livestream.battleLinkedRoomId = null;
      livestream.battlePrimaryRoomId = null;
      if (!_battleResultShown) {
        battleResultBanner.value = _buildBattleResult();
        _battleResultShown = true;
        _scheduleClearBattleResult(seconds: 6);
      }
      if (_rematchPromptOpen) {
        try {
          if (Get.isDialogOpen == true) {
            Get.back(result: false);
          }
        } catch (_) {}
      }
      _rematchPromptOpen = false;
      // Si este host está en endBattle(), él ya hace el rejoin.
      if (!_endingBattle) {
        unawaited(() async {
          await _rejoinOwnLiveRoomAfterBattle(
            muteRivalId: prevRivalId > 0 ? prevRivalId : null,
          );
          update();
          if (isHost) {
            showSnackBar('El rival salió del PK · volviste a tu LIVE');
          }
        }());
      }
    }

    if (running) {
      _battleResultShown = false;
      battleResultBanner.value = null;
      _battleResultClearTimer?.cancel();
    }

    // Si me invitaron a batalla y estoy en este LIVE (u otro), mostrar fullscreen.
    if (waiting && !isHost) {
      final me = SessionManager.instance.getUserID();
      if (me > 0 && blueId == me) {
        Future.microtask(() => LiveBattleInviteDialog.showIfNeeded(session));
      }
    }

    // Default de apoyo = host del LIVE que estoy viendo (no uno mismo).
    if ((running || waiting) && battleLikeForUserId.value == null) {
      final me = SessionManager.instance.getUserID();
      final roomHost = livestream.hostId ?? 0;
      if (me == redId) {
        battleLikeForUserId.value = blueId > 0 ? blueId : null;
      } else if (me == blueId) {
        battleLikeForUserId.value = redId > 0 ? redId : null;
      } else if (roomHost > 0 && roomHost != me) {
        battleLikeForUserId.value = roomHost;
      } else {
        battleLikeForUserId.value = redId > 0 ? redId : null;
      }
    }
  }

  /// Host, rival y audiencia: misma sala LiveKit durante PK; sala propia al terminar.
  Future<void> _syncLiveKitAvRoom({bool force = false}) async {
    if (liveKit == null || isDummy) return;
    if (pausedForCall.value) return;
    if (_avRoomSyncing) {
      for (var i = 0; i < 25 && _avRoomSyncing; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 120));
      }
      if (_avRoomSyncing) return;
    }
    final me = SessionManager.instance.getUser();
    if (me?.id == null) return;

    final inBattle = isBattleRunning.value;
    final target = inBattle ? avRoomId : roomId;
    final publish = shouldPublishAv;

    final current = _connectedLiveKitRoom ?? liveKit!.connectedRoomName;
    final onTarget = liveKit!.isConnected.value && current == target;
    final cameraOk = !publish || liveKit!.cameraEnabled.value;

    if (!force && onTarget && cameraOk) {
      return;
    }

    _avRoomSyncing = true;
    try {
      if (!onTarget) {
        _hostEverPublished = false;
        _clearHostAbsent();
      }
      await liveKit!.connect(
        roomName: target,
        identity: '${me!.id}',
        name: me.fullname ?? me.username ?? 'user',
        publishCamera: publish,
        publishMicrophone: publish,
        wsUrl: liveKitWsUrl,
        forceProfile: LiveKitQualityProfile.medium,
        forceReconnect: force || !onTarget || (publish && !cameraOk),
      );
      _connectedLiveKitRoom = target;
      if (liveKit!.remoteAudioMuted.value) {
        await liveKit!.setRemoteAudioMuted(false);
      }
      if (isHost) {
        await applyBeauty();
      }
      update();
    } catch (e) {
      _connectedLiveKitRoom = null;
      Loggers.error('_syncLiveKitAvRoom: $e');
    } finally {
      _avRoomSyncing = false;
    }
  }

  void _applyBattleSession(Livestream session) {
    _syncBattleFromSession(session, const []);
  }

  void _ensureBattleTicker() {
    if (_battleTicker != null) return;
    _battleTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateBattleRemaining();
    });
  }

  void _updateBattleRemaining() {
    if (!isBattleRunning.value) {
      battleRemainingSeconds.value = 0;
      return;
    }
    final created = livestream.battleCreatedAt;
    if (created == null || created <= 0) {
      battleRemainingSeconds.value =
          livestream.battleDuration * 60;
      return;
    }
    final totalMs = livestream.battleDuration * 60 * 1000;
    final elapsed = DateTime.now().millisecondsSinceEpoch - created;
    final left = ((totalMs - elapsed) / 1000).ceil();
    battleRemainingSeconds.value = left.clamp(0, 99999);
    if (left <= 0 && isHost && !_endingBattle && !_rematchPromptOpen) {
      Future.microtask(() => _finishBattleWithResult());
    }
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

  /// Rivales PK: solo hosts en LIVE y que no estén ya en batalla.
  Future<void> _loadBattleCandidates() async {
    await _fetchBattleCandidates(keyword: '');
  }

  Future<void> _searchBattleCandidates(String keyword) async {
    await _fetchBattleCandidates(keyword: keyword);
  }

  Future<void> _fetchBattleCandidates({required String keyword}) async {
    inviteLoading.value = true;
    try {
      final lives = await LiveSessionService.instance.listActive();
      final me = SessionManager.instance.getUserID();
      final q = keyword.trim().toLowerCase();
      final users = <User>[];
      final seen = <int>{};

      for (final live in lives) {
        if (!_isEligibleBattleOpponent(live, myUserId: me)) continue;
        final user = _userFromLiveHost(live);
        final id = user.id ?? 0;
        if (id <= 0 || seen.contains(id)) continue;
        if (q.isNotEmpty) {
          final name = (user.fullname ?? '').toLowerCase();
          final uname = (user.username ?? '').toLowerCase();
          if (!name.contains(q) && !uname.contains(q)) continue;
        }
        seen.add(id);
        users.add(user);
      }
      inviteCandidates.assignAll(users);
    } catch (e) {
      showSnackBar(e.toString());
    } finally {
      inviteLoading.value = false;
    }
  }

  bool _isEligibleBattleOpponent(Livestream live, {required int myUserId}) {
    if ((live.isDummyLive ?? 0) == 1) return false;
    final hostId = live.hostId ?? live.hostUser?.userId ?? 0;
    if (hostId <= 0 || hostId == myUserId) return false;
    final liveRoom = (live.roomID ?? '').trim();
    if (liveRoom.isNotEmpty && liveRoom == roomId) return false;
    // Ya en PK (esperando o en curso).
    if (live.type == LivestreamType.battle &&
        (live.battleType == BattleType.waiting ||
            live.battleType == BattleType.running)) {
      return false;
    }
    return true;
  }

  User _userFromLiveHost(Livestream live) {
    final host = live.hostUser;
    return User(
      id: host?.userId ?? live.hostId,
      username: host?.username,
      fullname: host?.fullname,
      profilePhoto: host?.profile,
      isVerify: host?.isVerify,
      identity: host?.identity,
    );
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

  Future<void> _publishLiveDocToFirestore() async {
    if (!isHost || isDummy || !useFirebase) return;
    final id = roomId.trim();
    if (id.isEmpty) return;
    try {
      final ok = await FirebaseAppHelper.ensureInitialized();
      if (!ok || !FirebaseAppHelper.isReady) return;
      final payload = livestream.toJson();
      final host = livestream.hostUser;
      if (host != null) {
        payload['host_user'] = {
          'user_id': host.userId,
          'username': host.username,
          'fullname': host.fullname,
          'profile': host.profile,
          'is_verify': host.isVerify,
          'identity': host.identity,
        };
      } else {
        final me = SessionManager.instance.getUser();
        if (me != null) {
          payload['host_user'] = {
            'user_id': me.id,
            'username': me.username,
            'fullname': me.fullname,
            'profile': me.profilePhoto,
            'is_verify': me.isVerify,
            'identity': me.identity,
          };
        }
      }
      await FirebaseFirestore.instance
          .collection(FirebaseConst.liveStreams)
          .doc(id)
          .set(payload, SetOptions(merge: true));
    } catch (e) {
      Loggers.error('_publishLiveDocToFirestore: $e');
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

  /// Audiencia: sale de este LIVE y entra al del rival para apoyarlo.
  /// Host: abre el perfil (no puede abandonar su propia transmisión).
  Future<void> goToOpponentLive() async {
    final oppId = battleOpponentId.value ?? 0;
    final oppName = battleOpponentName.value.trim();
    final oppPhoto = battleOpponentPhoto.value;
    if (isHost) {
      if (oppId <= 0) return;
      await openUserProfile(
        userId: oppId,
        fullname: oppName.isEmpty ? null : oppName,
        profilePhoto: oppPhoto,
      );
      return;
    }
    if (isDummy || isEnding.value || _redirectingToNextLive) return;

    showLoader();
    Livestream? next;
    try {
      final targetRoom = opponentLiveRoomId;
      final lives = await LiveSessionService.instance.listActive();
      if (targetRoom != null && targetRoom.isNotEmpty) {
        next = lives.firstWhereOrNull(
          (l) => (l.roomID ?? '').trim() == targetRoom,
        );
      }
      if (next == null && oppId > 0) {
        next = lives.firstWhereOrNull((l) => (l.hostId ?? 0) == oppId);
      }
    } catch (e) {
      Loggers.error('goToOpponentLive: $e');
    }
    stopLoader();
    if (next == null || (next.roomID ?? '').trim().isEmpty) {
      showSnackBar('El LIVE del rival no está disponible');
      return;
    }
    if ((next.roomID ?? '').trim() == roomId) {
      showSnackBar('Ya estás en su LIVE');
      return;
    }

    _redirectingToNextLive = true;
    isEnding.value = true;
    _sessionPoll?.cancel();
    _commentPoll?.cancel();
    _callPoll?.cancel();
    try {
      try {
        await LiveSessionService.instance
            .leave(roomId: roomId)
            .timeout(const Duration(seconds: 8));
      } catch (_) {}
      await _cleanupMedia().timeout(const Duration(seconds: 8));
    } catch (e) {
      Loggers.error('goToOpponentLive cleanup: $e');
    }
    await _popLiveUi();
    final dest = next;
    Future.microtask(() {
      Get.to(
        () => LiveStreamAudienceScreen(isHost: false, livestream: dest),
        preventDuplicates: false,
      );
    });
    isEnding.value = false;
    _redirectingToNextLive = false;
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

  void _checkHostPresence() {
    if (isHost || isDummy || isEnding.value || _redirectingToNextLive) return;
    if (isBattleOpponentPublisher) {
      _clearHostAbsent();
      return;
    }
    final lk = liveKit;
    if (lk == null || lk.isConnected.value != true) return;

    final remotes = lk.remoteParticipants;
    if (remotes.isNotEmpty) {
      _hostEverPublished = true;
      _clearHostAbsent();
      return;
    }

    // Solo cuenta si el host ya publicó al menos una vez (desconexión).
    if (!_hostEverPublished) return;

    _hostAbsentSince ??= DateTime.now();
    hostAbsent.value = true;
    final elapsed = DateTime.now().difference(_hostAbsentSince!).inSeconds;
    final left = hostAbsentTimeoutSecs - elapsed;
    hostAbsentSecondsLeft.value = left < 0 ? 0 : left;

    _hostAbsentTimer ??= Timer.periodic(const Duration(seconds: 1), (_) {
      _tickHostAbsent();
    });

    if (left <= 0) {
      unawaited(leaveAndRedirectToNextLive());
    }
  }

  void _tickHostAbsent() {
    if (isEnding.value || _redirectingToNextLive) {
      _clearHostAbsent();
      return;
    }
    final lk = liveKit;
    if (lk != null && lk.remoteParticipants.isNotEmpty) {
      _hostEverPublished = true;
      _clearHostAbsent();
      return;
    }
    final since = _hostAbsentSince;
    if (since == null) return;
    final elapsed = DateTime.now().difference(since).inSeconds;
    final left = hostAbsentTimeoutSecs - elapsed;
    hostAbsent.value = true;
    hostAbsentSecondsLeft.value = left < 0 ? 0 : left;
    if (left <= 0) {
      unawaited(leaveAndRedirectToNextLive());
    }
  }

  void _clearHostAbsent() {
    _hostAbsentSince = null;
    hostAbsent.value = false;
    hostAbsentSecondsLeft.value = 0;
    _hostAbsentTimer?.cancel();
    _hostAbsentTimer = null;
  }

  Future<Livestream?> _pickNextActiveLive() async {
    try {
      final lives = await LiveSessionService.instance.listActive();
      final me = SessionManager.instance.getUserID();
      for (final live in lives) {
        if ((live.isDummyLive ?? 0) == 1) continue;
        final rid = (live.roomID ?? '').trim();
        if (rid.isEmpty || rid == roomId) continue;
        final hostId = live.hostId ?? live.hostUser?.userId ?? 0;
        if (hostId <= 0 || hostId == me) continue;
        return live;
      }
    } catch (e) {
      Loggers.error('pick next live: $e');
    }
    return null;
  }

  /// Sale del LIVE actual y abre otro disponible (host ausente / live ended).
  Future<void> leaveAndRedirectToNextLive() async {
    if (isHost || isEnding.value || _redirectingToNextLive) return;
    _redirectingToNextLive = true;
    isEnding.value = true;
    _clearHostAbsent();
    _sessionPoll?.cancel();
    _commentPoll?.cancel();
    _callPoll?.cancel();

    Livestream? next;
    try {
      next = await _pickNextActiveLive()
          .timeout(const Duration(seconds: 6));
    } catch (_) {
      next = null;
    }

    try {
      if (!isDummy) {
        try {
          await LiveSessionService.instance
              .leave(roomId: roomId)
              .timeout(const Duration(seconds: 8));
        } catch (_) {}
      }
      await _cleanupMedia().timeout(const Duration(seconds: 8));
    } catch (e) {
      Loggers.error('leaveAndRedirect cleanup: $e');
    }

    await _popLiveUi();

    if (next != null) {
      // Microtask: el pop debe completar antes de abrir el siguiente.
      Future.microtask(() {
        Get.to(
          () => LiveStreamAudienceScreen(isHost: false, livestream: next!),
          preventDuplicates: false,
        );
      });
    } else {
      showSnackBar('El LIVE terminó');
    }

    isEnding.value = false;
    _redirectingToNextLive = false;
  }

  Future<void> endOrLeave() async {
    if (isEnding.value) {
      await _popLiveUi();
      return;
    }
    isEnding.value = true;
    _clearHostAbsent();
    _sessionPoll?.cancel();
    _commentPoll?.cancel();
    _callPoll?.cancel();
    // Si salimos a mitad de PK, cerrar batalla en servidor para no dejar
    // la sala primaria "fantasma" (rival en Esperando cámara…).
    if (!isDummy && (isBattleRunning.value || isBattleWaiting.value)) {
      try {
        await LiveSessionService.instance
            .endBattle(roomId: roomId)
            .timeout(const Duration(seconds: 6));
      } catch (_) {}
      isBattleRunning.value = false;
      isBattleWaiting.value = false;
    }
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

  /// Limpieza al aceptar PK: suelta cámara/UI sin tumbar la batalla ni la sala
  /// Laravel/Firebase que se va a reutilizar como host del rival.
  Future<void> handoffCleanup({required bool preserveLaravelSession}) async {
    if (isEnding.value) {
      await _popLiveUi();
      return;
    }
    isEnding.value = true;
    _sessionPoll?.cancel();
    _commentPoll?.cancel();
    _callPoll?.cancel();
    _battleTicker?.cancel();
    isBattleRunning.value = false;
    isBattleWaiting.value = false;
    await _popLiveUi();
    try {
      if (!preserveLaravelSession && !isDummy) {
        try {
          await LiveSessionService.instance
              .leave(roomId: roomId)
              .timeout(const Duration(seconds: 8));
        } catch (_) {}
      }
      await _cleanupMedia().timeout(const Duration(seconds: 8));
      if (!preserveLaravelSession && isHost && !isDummy && useFirebase) {
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
    _battleTicker?.cancel();
    _battleTicker = null;
    _connectedLiveKitRoom = null;
    if (!isDummy) {
      if (!isHost) {
        try {
          await _bumpWatching(-1);
        } catch (_) {}
      }
      final tag = 'lk_live_$roomId';
      if (liveKit != null) {
        try {
          await liveKit!.disconnect();
        } catch (_) {}
        if (Get.isRegistered<LiveKitRoomController>(tag: tag)) {
          Get.delete<LiveKitRoomController>(tag: tag, force: true);
        }
        liveKit = null;
      } else if (Get.isRegistered<LiveKitRoomController>(tag: tag)) {
        try {
          await Get.find<LiveKitRoomController>(tag: tag).disconnect();
        } catch (_) {}
        Get.delete<LiveKitRoomController>(tag: tag, force: true);
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
    _exitImmersiveLive();
    if (identical(activeInstance, this)) {
      activeInstance = null;
    }
    if (CallAvailability.watchingLiveHostId == livestream.hostId) {
      CallAvailability.watchingLiveHostId = null;
    }
    _sessionPoll?.cancel();
    _commentPoll?.cancel();
    _callPoll?.cancel();
    _hostConnectWatchdog?.cancel();
    _followBannerTimer?.cancel();
    _joinBannerTimer?.cancel();
    _hostAbsentTimer?.cancel();
    _battleTicker?.cancel();
    _liveElapsedTicker?.cancel();
    _dataSub?.cancel();
    commentController.dispose();
    commentFocusNode.dispose();
    dummyPlayer?.dispose();
    beautyShader.dispose();
    gpuPixel.dispose();
    final tag = 'lk_live_$roomId';
    if (Get.isRegistered<LiveKitRoomController>(tag: tag)) {
      Get.delete<LiveKitRoomController>(tag: tag);
    }
    super.onClose();
  }
}

