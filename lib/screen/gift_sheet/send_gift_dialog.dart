import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:krimson/common/extensions/string_extension.dart';
import 'package:krimson/common/widget/gift_media.dart';
import 'package:krimson/model/general/settings_model.dart';

/// Overlay del regalo: tamaño original, pantalla completa o mitad inferior.
/// MP4: se reproduce completo y solo entonces se cierra.
/// El audio auxiliar se recorta a la duración de la animación (nunca al revés).
class SendGiftDialog extends StatefulWidget {
  final Gift gift;

  const SendGiftDialog({super.key, required this.gift});

  @override
  State<SendGiftDialog> createState() => _SendGiftDialogState();
}

class _SendGiftDialogState extends State<SendGiftDialog>
    with TickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final AnimationController _exitCtrl;
  late final Animation<double> _scale;
  late final Animation<double> _opacityIn;
  late final Animation<double> _opacityOut;
  bool _closing = false;
  bool _videoMode = false;
  bool _exiting = false;
  bool _soundStopped = false;
  Timer? _safetyTimer;
  Timer? _soundCapTimer;
  AudioPlayer? _soundPlayer;
  Duration? _videoDuration;
  final Completer<Duration> _videoReady = Completer<Duration>();

  bool get _fullscreen => widget.gift.fullscreen;

  bool get _halfScreenBottom => widget.gift.halfScreenBottom;

  bool get _expandedDisplay => widget.gift.expandedDisplay;

  bool get _isVideo => GiftMedia.isVideoPath(widget.gift.image);

  bool get _hasSeparateSound => widget.gift.hasSound;

  Duration get _imageDuration {
    final path = (widget.gift.image ?? '').toLowerCase();
    final animated = path.endsWith('.gif') ||
        path.endsWith('.webp') ||
        path.contains('.gif?') ||
        path.contains('.webp?');
    final holdMs = animated
        ? (_expandedDisplay ? 2600 : 1800)
        : (_expandedDisplay ? 1400 : 900);
    return Duration(milliseconds: 350 + holdMs + 300);
  }

  @override
  void initState() {
    super.initState();
    _videoMode = _isVideo;
    unawaited(_playGiftSound());
    _exitCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _opacityOut = Tween<double>(begin: 1.0, end: 0.0)
        .chain(CurveTween(curve: Curves.easeIn))
        .animate(_exitCtrl);

    if (_videoMode) {
      _ctrl = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 400),
      );
      _scale = const AlwaysStoppedAnimation(1.0);
      _opacityIn = Tween<double>(begin: 0.0, end: 1.0)
          .chain(CurveTween(curve: Curves.easeOut))
          .animate(_ctrl);
      _ctrl.forward();
      _safetyTimer = Timer(const Duration(seconds: 45), () {
        if (!_closing && mounted) _startVideoExit();
      });
    } else {
      _ctrl = AnimationController(vsync: this, duration: _imageDuration);
      final enterBegin = _expandedDisplay ? 1.0 : 0.55;
      final enterPeak = _expandedDisplay ? 1.0 : 1.08;
      final exitEnd = _expandedDisplay ? 1.0 : 0.85;

      _scale = TweenSequence<double>([
        TweenSequenceItem(
          tween: Tween(begin: enterBegin, end: enterPeak)
              .chain(CurveTween(curve: Curves.easeOutBack)),
          weight: 22,
        ),
        TweenSequenceItem(
          tween: Tween(begin: enterPeak, end: 1.0)
              .chain(CurveTween(curve: Curves.easeOut)),
          weight: 10,
        ),
        TweenSequenceItem(
          tween: ConstantTween(1.0),
          weight: 46,
        ),
        TweenSequenceItem(
          tween: Tween(begin: 1.0, end: exitEnd)
              .chain(CurveTween(curve: Curves.easeIn)),
          weight: 22,
        ),
      ]).animate(_ctrl);

      _opacityIn = TweenSequence<double>([
        TweenSequenceItem(
          tween: Tween(begin: 0.0, end: 1.0)
              .chain(CurveTween(curve: Curves.easeOut)),
          weight: 18,
        ),
        TweenSequenceItem(
          tween: ConstantTween(1.0),
          weight: 60,
        ),
        TweenSequenceItem(
          tween: Tween(begin: 1.0, end: 0.0)
              .chain(CurveTween(curve: Curves.easeIn)),
          weight: 22,
        ),
      ]).animate(_ctrl);

      _ctrl.addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _dismiss();
        }
      });
      // El último ~22 % es el fade de salida: cortar el audio ahí.
      _ctrl.addListener(_onImageAnimTick);
      _ctrl.forward();
    }
  }

  void _onImageAnimTick() {
    if (_videoMode || _soundStopped) return;
    if (_ctrl.value >= 0.78) {
      unawaited(_stopGiftSound(fade: true));
    }
  }

  double get _opacityValue {
    if (_exiting) return _opacityOut.value.clamp(0.0, 1.0);
    return _opacityIn.value.clamp(0.0, 1.0);
  }

  void _onVideoReady(Duration duration) {
    if (duration.inMilliseconds <= 0) return;
    _videoDuration = duration;
    if (!_videoReady.isCompleted) {
      _videoReady.complete(duration);
    }
    _safetyTimer?.cancel();
    final maxWait = duration + const Duration(seconds: 3);
    _safetyTimer = Timer(maxWait, () {
      if (!_closing && mounted) _startVideoExit();
    });
  }

  void _onVideoEnded() {
    if (!_videoMode || _closing || !mounted) return;
    _startVideoExit();
  }

  void _startVideoExit() {
    if (_closing || _exiting || !mounted) return;
    _exiting = true;
    _safetyTimer?.cancel();
    unawaited(_stopGiftSound(fade: true));
    setState(() {});
    _exitCtrl.forward().whenComplete(_dismiss);
  }

  void _dismiss() {
    if (_closing || !mounted) return;
    _closing = true;
    _safetyTimer?.cancel();
    unawaited(_stopGiftSound(fade: false));
    final nav = Navigator.of(context, rootNavigator: true);
    if (nav.canPop()) {
      nav.pop();
    }
  }

  /// La animación manda: el MP3 no alarga el overlay ni sigue sonando después.
  Future<void> _playGiftSound() async {
    if (!_hasSeparateSound || _soundStopped) return;
    final url = widget.gift.sound!.trim().addBaseURL();
    if (url.isEmpty) return;
    final player = AudioPlayer();
    _soundPlayer = player;
    try {
      await player.setUrl(url);
      if (!await _soundStillMine(player)) return;

      final cap = await _animationCap();
      if (!await _soundStillMine(player)) return;

      final audioDur = player.duration;
      if (cap.inMilliseconds > 0 &&
          audioDur != null &&
          audioDur > cap) {
        try {
          await player.setClip(start: Duration.zero, end: cap);
        } catch (_) {}
      }

      if (!await _soundStillMine(player)) return;

      if (cap.inMilliseconds <= 0) {
        await _abandonPlayer(player);
        return;
      }
      _armSoundCap(cap);
      await player.play();
    } catch (_) {
      await _abandonPlayer(player);
    }
  }

  Future<Duration> _animationCap() async {
    if (!_videoMode) return _imageDuration;
    try {
      return await _videoReady.future.timeout(const Duration(seconds: 8));
    } catch (_) {
      return _videoDuration ?? const Duration(seconds: 8);
    }
  }

  Future<bool> _soundStillMine(AudioPlayer player) async {
    if (!_soundStopped && mounted && _soundPlayer == player) return true;
    await _abandonPlayer(player);
    return false;
  }

  Future<void> _abandonPlayer(AudioPlayer player) async {
    // Si ya se cortó el audio, _stopGiftSound es dueño del player.
    if (_soundStopped) return;
    if (_soundPlayer == player) _soundPlayer = null;
    try {
      await player.stop();
    } catch (_) {}
    try {
      await player.dispose();
    } catch (_) {}
  }

  void _armSoundCap(Duration cap) {
    _soundCapTimer?.cancel();
    if (cap.inMilliseconds <= 0) return;
    _soundCapTimer = Timer(cap, () {
      unawaited(_stopGiftSound(fade: true));
    });
  }

  Future<void> _stopGiftSound({required bool fade}) async {
    if (_soundStopped && _soundPlayer == null) return;
    _soundStopped = true;
    _soundCapTimer?.cancel();
    _soundCapTimer = null;
    final player = _soundPlayer;
    _soundPlayer = null;
    if (player == null) return;
    try {
      if (fade) {
        for (var i = 1; i <= 5; i++) {
          await player.setVolume((1.0 - i / 5).clamp(0.0, 1.0));
          await Future<void>.delayed(const Duration(milliseconds: 40));
        }
      }
      await player.stop();
    } catch (_) {}
    try {
      await player.dispose();
    } catch (_) {}
  }

  @override
  void dispose() {
    _safetyTimer?.cancel();
    _soundCapTimer?.cancel();
    _ctrl.removeListener(_onImageAnimTick);
    unawaited(_stopGiftSound(fade: false));
    if (!_videoReady.isCompleted) {
      _videoReady.complete(Duration.zero);
    }
    _ctrl.dispose();
    _exitCtrl.dispose();
    super.dispose();
  }

  Widget _buildMedia(double w, double h, BoxFit fit) {
    return GiftMedia(
      path: widget.gift.image,
      width: w,
      height: h,
      fit: fit,
      muted: _hasSeparateSound,
      looping: false,
      onVideoEnded: _onVideoEnded,
      onVideoReady: _onVideoReady,
      placeholder: Icon(
        Icons.card_giftcard,
        size: _expandedDisplay ? 120 : 80,
        color: Colors.white70,
      ),
    );
  }

  Widget _buildHalfScreenContent(Size size) {
    final halfH = size.height * 0.5;
    const edgeBlurH = 52.0;

    return Align(
      alignment: Alignment.bottomCenter,
      child: SizedBox(
        width: size.width,
        height: halfH,
        child: Stack(
          fit: StackFit.expand,
          clipBehavior: Clip.hardEdge,
          children: [
            ColoredBox(
              color: Colors.black,
              child: Align(
                alignment: Alignment.bottomCenter,
                child: _buildMedia(size.width, halfH, BoxFit.fitWidth),
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: edgeBlurH,
              child: IgnorePointer(
                child: ClipRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.28),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGiftContent(Size size) {
    if (_halfScreenBottom) {
      return _buildHalfScreenContent(size);
    }
    if (_fullscreen) {
      return SizedBox(
        width: size.width,
        height: size.height,
        child: _buildMedia(size.width, size.height, BoxFit.cover),
      );
    }
    return Center(
      child: _buildMedia(180, 180, BoxFit.contain),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    return Material(
      type: MaterialType.transparency,
      color: Colors.transparent,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _videoMode ? null : _dismiss,
        child: ColoredBox(
          color: _halfScreenBottom
              ? Colors.transparent
              : (_expandedDisplay
                  ? Colors.black.withValues(alpha: 0.35)
                  : Colors.transparent),
          child: AnimatedBuilder(
            animation: Listenable.merge([_ctrl, _exitCtrl]),
            builder: (context, child) {
              return Opacity(
                opacity: _opacityValue,
                child: _expandedDisplay
                    ? child
                    : Transform.scale(scale: _scale.value, child: child),
              );
            },
            child: IgnorePointer(child: _buildGiftContent(size)),
          ),
        ),
      ),
    );
  }
}
