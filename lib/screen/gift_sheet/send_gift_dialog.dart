import 'dart:async';

import 'package:flutter/material.dart';
import 'package:krimson/common/widget/gift_media.dart';
import 'package:krimson/model/general/settings_model.dart';

/// Overlay del regalo: tamaño original (180) o pantalla completa (100%×100%).
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

  bool get _fullscreen => widget.gift.fullscreen;

  bool get _isVideo => GiftMedia.isVideoPath(widget.gift.image);

  Duration get _imageDuration {
    final path = (widget.gift.image ?? '').toLowerCase();
    final animated = path.endsWith('.gif') ||
        path.endsWith('.webp') ||
        path.contains('.gif?') ||
        path.contains('.webp?');
    final holdMs = animated
        ? (_fullscreen ? 2600 : 1800)
        : (_fullscreen ? 1400 : 900);
    return Duration(milliseconds: 350 + holdMs + 300);
  }

  @override
  void initState() {
    super.initState();
    _videoMode = _isVideo;
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
      final enterBegin = _fullscreen ? 1.0 : 0.55;
      final enterPeak = _fullscreen ? 1.0 : 1.08;
      final exitEnd = _fullscreen ? 1.0 : 0.85;

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
    // Duración completa del MP4 + buffer de red + fade.
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

  @override
  void dispose() {
    _safetyTimer?.cancel();
    _ctrl.dispose();
    _exitCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final w = _fullscreen ? size.width : 180.0;
    final h = _fullscreen ? size.height : 180.0;
    final fit = _fullscreen ? BoxFit.cover : BoxFit.contain;

    final media = GiftMedia(
      path: widget.gift.image,
      width: w,
      height: h,
      fit: fit,
      muted: false,
      looping: false,
      onVideoEnded: _onVideoEnded,
      onVideoReady: _onVideoReady,
      placeholder: Icon(
        Icons.card_giftcard,
        size: _fullscreen ? 120 : 80,
        color: Colors.white70,
      ),
    );

    return Material(
      type: MaterialType.transparency,
      color: Colors.transparent,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        // MP4: no cerrar a mitad para que se vea/oiga completo.
        onTap: _videoMode ? null : _dismiss,
        child: ColoredBox(
          color: _fullscreen
              ? Colors.black.withValues(alpha: 0.35)
              : Colors.transparent,
          child: AnimatedBuilder(
            animation: Listenable.merge([_ctrl, _exitCtrl]),
            builder: (context, child) {
              return Opacity(
                opacity: _opacityValue,
                child: _fullscreen
                    ? child
                    : Transform.scale(scale: _scale.value, child: child),
              );
            },
            child: _fullscreen
                ? IgnorePointer(
                    child: SizedBox(width: w, height: h, child: media),
                  )
                : Center(child: IgnorePointer(child: media)),
          ),
        ),
      ),
    );
  }
}
