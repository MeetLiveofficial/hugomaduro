import 'dart:async';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:krimson/common/extensions/string_extension.dart';
import 'package:krimson/common/widget/gift_media.dart';
import 'package:krimson/model/general/settings_model.dart';

/// Overlay del regalo: tamaño original, pantalla completa o mitad inferior.
/// MP4: se reproduce completo (con audio) y solo entonces se cierra.
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
  Timer? _safetyTimer;
  AudioPlayer? _soundPlayer;

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
      _ctrl.forward();
    }
  }

  double get _opacityValue {
    if (_exiting) return _opacityOut.value.clamp(0.0, 1.0);
    return _opacityIn.value.clamp(0.0, 1.0);
  }

  void _onVideoReady(Duration duration) {
    if (duration.inMilliseconds <= 0) return;
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
    setState(() {});
    _exitCtrl.forward().whenComplete(_dismiss);
  }

  void _dismiss() {
    if (_closing || !mounted) return;
    _closing = true;
    _safetyTimer?.cancel();
    final nav = Navigator.of(context, rootNavigator: true);
    if (nav.canPop()) {
      nav.pop();
    }
  }

  Future<void> _playGiftSound() async {
    if (!_hasSeparateSound) return;
    final url = widget.gift.sound!.trim().addBaseURL();
    if (url.isEmpty) return;
    final player = AudioPlayer();
    _soundPlayer = player;
    try {
      await player.setUrl(url);
      await player.play();
    } catch (_) {
      await player.dispose();
      if (_soundPlayer == player) _soundPlayer = null;
    }
  }

  @override
  void dispose() {
    _safetyTimer?.cancel();
    final player = _soundPlayer;
    _soundPlayer = null;
    unawaited(player?.dispose());
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

  Widget _buildGiftContent(Size size) {
    if (_halfScreenBottom) {
      final halfH = size.height * 0.5;
      return Align(
        alignment: Alignment.bottomCenter,
        child: ColoredBox(
          color: Colors.black,
          child: SizedBox(
            width: size.width,
            height: halfH,
            child: _buildMedia(size.width, halfH, BoxFit.contain),
          ),
        ),
      );
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
          color: _expandedDisplay
              ? Colors.black.withValues(alpha: 0.35)
              : Colors.transparent,
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
