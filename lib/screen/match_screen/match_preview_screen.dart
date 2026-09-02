import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krimson/common/extensions/string_extension.dart';
import 'package:krimson/common/manager/coin_gate.dart';
import 'package:krimson/common/manager/livekit_room_controller.dart';
import 'package:krimson/common/service/livekit/livekit_room_service.dart';
import 'package:krimson/common/manager/logger.dart';
import 'package:krimson/common/manager/session_manager.dart';
import 'package:krimson/common/service/api/call_service.dart';
import 'package:krimson/common/widget/custom_image.dart';
import 'package:krimson/common/widget/livekit/livekit_video_view.dart';
import 'package:krimson/languages/languages_keys.dart';
import 'package:krimson/model/call/call_request_model.dart';
import 'package:krimson/model/general/settings_model.dart';
import 'package:krimson/model/user_model/user_model.dart';
import 'package:krimson/screen/call_screen/match_recharge_dialog.dart';
import 'package:krimson/screen/call_screen/video_call_screen.dart';
import 'package:krimson/screen/match_screen/match_screen_controller.dart';
import 'package:krimson/screen/match_screen/match_web_video.dart';
import 'package:krimson/utilities/client_colors.dart';
import 'package:krimson/utilities/const_res.dart';
import 'package:krimson/utilities/text_style_custom.dart';
import 'package:livekit_client/livekit_client.dart';

/// Preview en vivo (40s): ver, deslizar a otra, o pagar 5/10/15 min para quedarse.
class MatchPreviewScreen extends StatefulWidget {
  const MatchPreviewScreen({
    super.key,
    required this.initial,
    this.mode = 'random',
  });

  final MatchRecommendation initial;
  final String mode;

  @override
  State<MatchPreviewScreen> createState() => _MatchPreviewScreenState();
}

class _MatchPreviewScreenState extends State<MatchPreviewScreen> {
  static const _lkTag = 'match_preview';
  static const _swipeThreshold = 88;

  late MatchRecommendation _match;
  late List<int> _seenIds;
  late int _secondsLeft;
  Timer? _timer;
  bool _busy = false;
  bool _closing = false;
  double _dragDx = 0;
  String _status = 'Conectando…';
  LiveKitRoomController? _lk;

  User get _user => _match.user;

  int get _previewSeconds {
    if (_match.previewSeconds > 0) return _match.previewSeconds;
    if (_match.matchFreeSeconds > 0) return _match.matchFreeSeconds;
    return 40;
  }

  @override
  void initState() {
    super.initState();
    _match = widget.initial;
    _seenIds = [
      for (final u in _match.users)
        if ((u.id ?? 0) > 0) u.id!,
    ];
    if ((_user.id ?? 0) > 0 && !_seenIds.contains(_user.id)) {
      _seenIds.add(_user.id!);
    }
    _secondsLeft = _previewSeconds;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_connectCurrent());
    });
  }

  @override
  void dispose() {
    _closing = true;
    _timer?.cancel();
    unawaited(_teardownLiveKit());
    super.dispose();
  }

  Future<void> _teardownLiveKit() async {
    try {
      if (Get.isRegistered<LiveKitRoomController>(tag: _lkTag)) {
        await Get.find<LiveKitRoomController>(tag: _lkTag).disconnect();
        Get.delete<LiveKitRoomController>(tag: _lkTag, force: true);
      }
    } catch (_) {}
    _lk = null;
  }

  void _startCountdown() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _busy) return;
      unawaited(_lk?.subscribeRemoteVideos(
        preferIdentity: '${_user.id ?? ''}',
      ));
      if (_secondsLeft <= 1) {
        _timer?.cancel();
        setState(() => _secondsLeft = 0);
        unawaited(_onPreviewTimeout());
        return;
      }
      setState(() => _secondsLeft -= 1);
    });
  }

  Future<void> _connectCurrent() async {
    if (_closing) return;
    final me = SessionManager.instance.getUser();
    final room = _match.roomIdFor(_user);
    final streamerId = '${_user.id ?? ''}';
    if (me?.id == null || room.isEmpty) {
      setState(() => _status = 'Sala de espera inválida');
      return;
    }
    _timer?.cancel();
    setState(() {
      _secondsLeft = _previewSeconds;
      _status = 'Conectando…';
    });
    try {
      if (!Get.isRegistered<LiveKitRoomController>(tag: _lkTag)) {
        _lk = Get.put(LiveKitRoomController(), tag: _lkTag);
      } else {
        _lk = Get.find<LiveKitRoomController>(tag: _lkTag);
      }
      await _lk!.connect(
        roomName: room,
        identity: '${me!.id}',
        name: me.fullname ?? me.username ?? 'client',
        publishCamera: false,
        publishMicrophone: false,
        wsUrl: liveKitWsUrl,
        forceReconnect: true,
        adaptiveStream: false,
        dynacast: false,
        forceProfile: LiveKitQualityProfile.high,
      );
      if (!mounted || _closing) return;
      setState(() => _status = LKey.waitingCamera.tr);
      for (var i = 0; i < 80; i++) {
        if (!mounted || _closing) return;
        await _lk?.subscribeRemoteVideos(preferIdentity: streamerId);
        final peer = _previewPeer(_lk, streamerId);
        if (firstVideoTrackOf(peer) != null) {
          setState(() => _status = '');
          break;
        }
        await Future<void>.delayed(const Duration(milliseconds: 250));
      }
      if (!mounted || _closing) return;
      _startCountdown();
    } catch (e) {
      Loggers.error('Match preview connect: $e');
      if (!mounted || _closing) return;
      setState(() => _status = 'Sin video. Puedes pasar a otra streamer.');
      _startCountdown();
    }
  }

  Future<void> _loadNext() async {
    if (_busy || _closing) return;
    setState(() => _busy = true);
    try {
      final next = await CallService.instance.findMatch(
        mode: widget.mode,
        excludeUserIds: _seenIds,
      );
      if (!mounted || _closing) return;
      _match = next;
      final id = next.user.id ?? 0;
      if (id > 0 && !_seenIds.contains(id)) {
        _seenIds.add(id);
      }
      setState(() => _busy = false);
      await _connectCurrent();
    } catch (e) {
      Loggers.error('Match preview next: $e');
      if (!mounted || _closing) return;
      setState(() => _busy = false);
      Get.snackbar(
        LKey.matchLabel.tr,
        LKey.noMoreMatchStreamers.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.black87,
        colorText: Colors.white,
        margin: const EdgeInsets.all(12),
      );
      Get.back();
    }
  }

  Future<void> _accept() async {
    if (_busy || _closing) return;
    setState(() => _busy = true);
    _timer?.cancel();
    final paid = await _promptPayToStay(autoClose: false);
    if (!mounted || _closing) return;
    if (paid) return;
    setState(() => _busy = false);
    if (_secondsLeft > 0) {
      _startCountdown();
      return;
    }
    await _loadNext();
  }

  Future<void> _enterCall(CallRequestModel call) async {
    _closing = true;
    _timer?.cancel();
    await _teardownLiveKit();
    if (Get.isRegistered<MatchScreenController>()) {
      Get.find<MatchScreenController>().markLeftPoolLocally();
    }
    unawaited(CallService.instance.leaveMatch());
    final screen = VideoCallScreen(
      call: call,
      isMatchPreview: false,
      matchFreeSeconds:
          call.matchSeconds > 0 ? call.matchSeconds : _previewSeconds,
    );
    // Si Get.back del dialog ya cerró el preview, empujar la llamada;
    // si sigue abierto, reemplazarlo para no volver al preview al colgar.
    if (Get.key.currentState?.canPop() == true) {
      Get.off(() => screen);
    } else {
      Get.to(() => screen);
    }
  }

  Future<void> _onPreviewTimeout() async {
    if (_busy || _closing || !mounted) return;
    setState(() => _busy = true);
    final paid = await _promptPayToStay(autoClose: true);
    if (!mounted || _closing) return;
    if (paid) return;
    setState(() => _busy = false);
    await _loadNext();
  }

  Future<bool> _promptPayToStay({required bool autoClose}) async {
    CallRequestModel? paidCall;
    final grace = _match.matchGraceSeconds > 0 ? _match.matchGraceSeconds : 10;
    final paid = await MatchRechargeDialog.show(
      peer: _party(_user),
      tiers: _match.matchTiers,
      graceSeconds: grace,
      autoCloseOnTimeout: autoClose,
      subtitle: autoClose
          ? null
          : 'Elige 5, 10 o 15 min para quedarte con ella',
      onExtend: (MatchTier tier) async {
        if (!CoinGate.ensureEnough(
          tier.coins,
          message: LKey.needCoinsForMinutes.trParams({
            'coins': '${tier.coins}',
            'minutes': '${tier.minutes}',
          }),
        )) {
          return false;
        }
        try {
          paidCall = await CallService.instance.create(
            userId: _user.id ?? 0,
            isMatch: true,
            tier: tier.tier,
          );
          final me = SessionManager.instance.getUser();
          if (me != null && tier.coins > 0) {
            me.removeCoinFromWallet(tier.coins);
            SessionManager.instance.setUser(me);
          }
          return true;
        } catch (e) {
          Loggers.error('Match preview pack: $e');
          return false;
        }
      },
    );
    if (paid && paidCall != null) {
      await _enterCall(paidCall!);
      return true;
    }
    return false;
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    if (_busy || _closing) return;
    setState(() => _dragDx += details.delta.dx);
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    if (_busy || _closing) return;
    final velocity = details.primaryVelocity ?? 0;
    final skip = _dragDx.abs() >= _swipeThreshold || velocity.abs() >= 650;
    setState(() => _dragDx = 0);
    if (skip) {
      unawaited(_loadNext());
    }
  }

  CallParty _party(User u) => CallParty(
        id: u.id,
        username: u.username,
        fullname: u.fullname,
        profilePhoto: u.profilePhoto,
        isVerify: u.isVerify,
        levelNumber: u.levelNumber,
        levelTitle: u.levelTitle,
        canReceiveCalls: u.canReceiveCalls,
        callRequestCoins: u.callRequestCoins,
      );

  @override
  Widget build(BuildContext context) {
    final name = (_user.fullname ?? _user.username ?? 'Streamer').trim();
    final streamerId = '${_user.id ?? ''}';
    return PopScope(
      canPop: !_busy,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) {
          _closing = true;
          _timer?.cancel();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: GestureDetector(
          onHorizontalDragUpdate: _onHorizontalDragUpdate,
          onHorizontalDragEnd: _onHorizontalDragEnd,
          child: Column(
            children: [
              ColoredBox(
                color: Colors.black,
                child: SafeArea(
                  bottom: false,
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(8, 4, 16, 0),
                        child: Row(
                          children: [
                            IconButton(
                              onPressed: _busy ? null : Get.back,
                              icon: const Icon(Icons.close,
                                  color: Colors.white, size: 22),
                            ),
                            CustomImage(
                              size: const Size(36, 36),
                              image: _user.profilePhoto?.addBaseURL(),
                              fullName: name,
                              radius: 18,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyleCustom.outFitSemiBold600(
                                  color: Colors.white,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                            _CountdownBadge(seconds: _secondsLeft),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: _previewSeconds > 0
                                ? (_secondsLeft / _previewSeconds)
                                    .clamp(0.0, 1.0)
                                : 0,
                            minHeight: 6,
                            backgroundColor: Colors.white24,
                            color: ClientColors.secondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: _VideoLayer(
                  lkTag: _lkTag,
                  streamerIdentity: streamerId,
                  status: _status,
                  photoUrl: _user.profilePhoto?.addBaseURL(),
                  displayName: name,
                ),
              ),
              ColoredBox(
                color: Colors.black,
                child: SafeArea(
                  top: false,
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 12, 24, 10),
                        child: Text(
                          'Desliza para otra streamer · ${_previewSeconds}s de preview',
                          textAlign: TextAlign.center,
                          style: TextStyleCustom.outFitRegular400(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      if (_busy)
                        const Padding(
                          padding: EdgeInsets.only(bottom: 18),
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            color: Colors.white70,
                          ),
                        )
                      else
                        Padding(
                          padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
                          child: Row(
                            children: [
                              Expanded(
                                child: _ActionButton(
                                  label: 'Siguiente',
                                  icon: Icons.skip_next_rounded,
                                  filled: false,
                                  onTap: _loadNext,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: _ActionButton(
                                  label: 'Aceptar',
                                  icon: Icons.favorite_rounded,
                                  filled: true,
                                  onTap: _accept,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VideoLayer extends StatelessWidget {
  const _VideoLayer({
    required this.lkTag,
    required this.streamerIdentity,
    required this.status,
    this.photoUrl,
    this.displayName,
  });

  final String lkTag;
  final String streamerIdentity;
  final String status;
  final String? photoUrl;
  final String? displayName;

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<LiveKitRoomController>(tag: lkTag)) {
      return _Placeholder(
        status: status,
        photoUrl: photoUrl,
        displayName: displayName,
      );
    }
    final lk = Get.find<LiveKitRoomController>(tag: lkTag);
    return Obx(() {
      lk.mediaRevision.value;
      lk.remoteParticipants.length;
      final peer = _previewPeer(lk, streamerIdentity);
      final hasVideo = firstVideoTrackOf(peer) != null;
      if (kIsWeb) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          passThroughMatchVideoClicks();
        });
      }
      if (!hasVideo) {
        return _Placeholder(
          status: status,
          photoUrl: photoUrl,
          displayName: displayName,
        );
      }
      // En Web no Clip ni Stack opaco: el <video> de LiveKit queda
      // tapado si hay canvas encima (la espera de la streamer no lo hace).
      return ClipRRect(
        clipBehavior: kIsWeb ? Clip.none : Clip.hardEdge,
        child: LiveKitParticipantVideo(
          participant: peer,
          fit: VideoViewFit.cover,
          forcePortraitUpright: false,
        ),
      );
    });
  }
}

Participant? _previewPeer(LiveKitRoomController? lk, String identity) {
  if (lk == null) return null;
  final remotes = lk.remoteParticipants;
  final want = identity.trim();
  bool matches(RemoteParticipant p) {
    final a = p.identity.trim();
    if (want.isEmpty) return false;
    return a == want || a == 'matchwait_$want' || a.endsWith('_$want');
  }

  if (want.isNotEmpty) {
    for (final p in remotes) {
      if (matches(p) && firstVideoTrackOf(p) != null) return p;
    }
    for (final p in remotes) {
      if (matches(p)) return p;
    }
  }
  for (final p in remotes) {
    if (firstVideoTrackOf(p) != null) return p;
  }
  return remotes.isNotEmpty ? remotes.first : null;
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({
    required this.status,
    this.photoUrl,
    this.displayName,
  });

  final String status;
  final String? photoUrl;
  final String? displayName;

  @override
  Widget build(BuildContext context) {
    final hasPhoto = (photoUrl ?? '').trim().isNotEmpty;
    return ColoredBox(
      color: ClientColors.surfaceDark,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (hasPhoto)
            CustomImage(
              size: const Size(double.infinity, double.infinity),
              image: photoUrl,
              radius: 0,
              fit: BoxFit.cover,
              fullName: displayName,
            )
          else
            const Center(
              child: Icon(Icons.person, color: ClientColors.textOnDarkMuted, size: 72),
            ),
          ColoredBox(color: Colors.black.withValues(alpha: 0.38)),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Text(
                status,
                textAlign: TextAlign.center,
                style: const TextStyle(color: ClientColors.textOnDarkMuted, fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CountdownBadge extends StatelessWidget {
  const _CountdownBadge({required this.seconds});

  final int seconds;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: ClientColors.surfaceDark.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: ClientColors.secondarySoft),
      ),
      child: Text(
        '${seconds}s',
        style: TextStyleCustom.outFitSemiBold600(
          color: ClientColors.textOnDark,
          fontSize: 14,
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.filled,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool filled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: filled ? ClientColors.primary : ClientColors.surfaceDarkAlt,
      borderRadius: BorderRadius.circular(28),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: filled ? ClientColors.primaryHover : ClientColors.secondarySoft,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: ClientColors.textOnDark, size: 22),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyleCustom.outFitSemiBold600(
                  color: ClientColors.textOnDark,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
