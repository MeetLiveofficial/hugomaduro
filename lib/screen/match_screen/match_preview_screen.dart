import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krimson/common/extensions/string_extension.dart';
import 'package:krimson/common/manager/coin_gate.dart';
import 'package:krimson/common/manager/livekit_room_controller.dart';
import 'package:krimson/common/manager/logger.dart';
import 'package:krimson/common/manager/session_manager.dart';
import 'package:krimson/common/service/api/call_service.dart';
import 'package:krimson/common/widget/custom_image.dart';
import 'package:krimson/common/widget/livekit/livekit_video_view.dart';
import 'package:krimson/model/call/call_request_model.dart';
import 'package:krimson/model/general/settings_model.dart';
import 'package:krimson/model/user_model/user_model.dart';
import 'package:krimson/screen/call_screen/match_recharge_dialog.dart';
import 'package:krimson/screen/call_screen/video_call_screen.dart';
import 'package:krimson/screen/match_screen/match_screen_controller.dart';
import 'package:krimson/utilities/color_res.dart';
import 'package:krimson/utilities/const_res.dart';
import 'package:krimson/utilities/text_style_custom.dart';

/// Preview en vivo (~40s): el cliente ve a la streamer y puede aceptar o pasar.
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

  late MatchRecommendation _match;
  late List<int> _seenIds;
  late int _secondsLeft;
  Timer? _timer;
  bool _busy = false;
  bool _closing = false;
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
      );
      if (!mounted || _closing) return;
      setState(() => _status = 'Esperando cámara…');
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
      final lang = (_match.appLanguage ?? '').trim();
      final next = await CallService.instance.findMatch(
        appLanguage: lang.isEmpty ? null : lang,
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
        'Match',
        'No hay más streamers en Match ahora',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.black87,
        colorText: Colors.white,
        margin: const EdgeInsets.all(12),
      );
      Get.back();
    }
  }

  Future<void> _accept({int? remaining, int? tier}) async {
    if (_busy || _closing) return;
    final peerId = _user.id;
    if (peerId == null) return;
    setState(() => _busy = true);
    try {
      final seconds = remaining ?? _secondsLeft.clamp(5, _previewSeconds);
      final call = await CallService.instance.create(
        userId: peerId,
        isMatch: true,
        matchSeconds: tier == null ? seconds : null,
        tier: tier,
      );
      if (!mounted || _closing) return;
      await _enterCall(call);
    } catch (e) {
      Loggers.error('Match preview accept: $e');
      if (!mounted || _closing) return;
      setState(() => _busy = false);
      final msg = e.toString().replaceFirst('Exception: ', '');
      if (msg.toLowerCase().contains('insufficient')) {
        CoinGate.ensureEnough(999999, message: 'Monedas insuficientes');
      } else {
        Get.snackbar(
          'Match',
          msg,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.black87,
          colorText: Colors.white,
          margin: const EdgeInsets.all(12),
        );
      }
    }
  }

  Future<void> _enterCall(CallRequestModel call) async {
    _timer?.cancel();
    await _teardownLiveKit();
    if (Get.isRegistered<MatchScreenController>()) {
      await Get.find<MatchScreenController>().leavePool();
    } else {
      await CallService.instance.leaveMatch();
    }
    if (!mounted || _closing) return;
    Get.off(() => VideoCallScreen(
          call: call,
          isMatchPreview: true,
          matchFreeSeconds:
              call.matchSeconds > 0 ? call.matchSeconds : _previewSeconds,
        ));
  }

  Future<void> _onPreviewTimeout() async {
    if (_busy || _closing || !mounted) return;
    CallRequestModel? paidCall;
    final paid = await MatchRechargeDialog.show(
      peer: _party(_user),
      tiers: _match.matchTiers,
      graceSeconds: _match.matchGraceSeconds,
      onExtend: (MatchTier tier) async {
        if (!CoinGate.ensureEnough(
          tier.coins,
          message: 'Necesitas ${tier.coins} coins para ${tier.minutes} min',
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
    if (!mounted || _closing) return;
    if (paid && paidCall != null) {
      await _enterCall(paidCall!);
      return;
    }
    await _loadNext();
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
    return PopScope(
      canPop: !_busy,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) {
          _closing = true;
          _timer?.cancel();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF120E18),
        body: Stack(
          fit: StackFit.expand,
          children: [
            _VideoLayer(lkTag: _lkTag, status: _status),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x66000000),
                    Colors.transparent,
                    Color(0xCC0A0610),
                  ],
                ),
              ),
            ),
            SafeArea(
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
                  const Spacer(),
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
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
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
                              onTap: () => _accept(),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VideoLayer extends StatelessWidget {
  const _VideoLayer({required this.lkTag, required this.status});

  final String lkTag;
  final String status;

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<LiveKitRoomController>(tag: lkTag)) {
      return _Placeholder(status: status);
    }
    final lk = Get.find<LiveKitRoomController>(tag: lkTag);
    return Obx(() {
      lk.mediaRevision.value;
      final remotes = lk.remoteParticipants;
      final remote = remotes.isNotEmpty ? remotes.first : null;
      const allowRenderer = !kIsWeb;
      if (allowRenderer && firstVideoTrackOf(remote) != null) {
        return LiveKitParticipantVideo(
          participant: remote,
          forcePortraitUpright: false,
        );
      }
      return _Placeholder(status: status);
    });
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFF140E18),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Text(
            kIsWeb
                ? 'Preview en vivo. El video va por la APP, no por el navegador.'
                : status,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ),
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
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: ColorRes.themeAccentSolid.withValues(alpha: 0.8)),
      ),
      child: Text(
        '${seconds}s',
        style: TextStyleCustom.outFitSemiBold600(
          color: Colors.white,
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
      color: filled ? ColorRes.themeAccentSolid : Colors.black.withValues(alpha: 0.45),
      borderRadius: BorderRadius.circular(28),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: filled
                  ? Colors.transparent
                  : Colors.white.withValues(alpha: 0.28),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 22),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyleCustom.outFitSemiBold600(
                  color: Colors.white,
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
