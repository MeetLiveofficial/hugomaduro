import 'package:flutter/material.dart';
import 'package:krimson/common/extensions/string_extension.dart';
import 'package:krimson/model/general/settings_model.dart';

/// Overlay del regalo: tamaño original (180) o pantalla completa según [Gift.isFullscreen].
class SendGiftDialog extends StatefulWidget {
  final Gift gift;

  const SendGiftDialog({super.key, required this.gift});

  @override
  State<SendGiftDialog> createState() => _SendGiftDialogState();
}

class _SendGiftDialogState extends State<SendGiftDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;
  late final Animation<double> _opacity;
  bool _closing = false;

  bool get _fullscreen => widget.gift.fullscreen;

  /// PNG/JPG: animación corta. GIF/WebP animado: hold un poco más.
  Duration get _totalDuration {
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
    final total = _totalDuration;
    _ctrl = AnimationController(vsync: this, duration: total);

    _scale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: _fullscreen ? 0.85 : 0.55, end: 1.08)
            .chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 22,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.08, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 10,
      ),
      TweenSequenceItem(
        tween: ConstantTween(1.0),
        weight: 46,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: _fullscreen ? 0.95 : 0.85)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 22,
      ),
    ]).animate(_ctrl);

    _opacity = TweenSequence<double>([
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

  void _dismiss() {
    if (_closing || !mounted) return;
    _closing = true;
    final nav = Navigator.of(context, rootNavigator: true);
    if (nav.canPop()) {
      nav.pop();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final url = widget.gift.image?.addBaseURL() ?? '';
    final size = MediaQuery.sizeOf(context);

    return Material(
      type: MaterialType.transparency,
      color: Colors.transparent,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _dismiss,
        child: ColoredBox(
          color: _fullscreen
              ? Colors.black.withValues(alpha: 0.55)
              : Colors.transparent,
          child: Center(
            child: AnimatedBuilder(
              animation: _ctrl,
              builder: (context, child) {
                return Opacity(
                  opacity: _opacity.value.clamp(0.0, 1.0),
                  child: Transform.scale(
                    scale: _scale.value,
                    child: child,
                  ),
                );
              },
              child: IgnorePointer(
                child: url.isEmpty
                    ? Icon(Icons.card_giftcard,
                        size: _fullscreen ? 160 : 120, color: Colors.white)
                    : Image.network(
                        url,
                        width: _fullscreen ? size.width : 180,
                        height: _fullscreen ? size.height : 180,
                        fit: _fullscreen ? BoxFit.contain : BoxFit.contain,
                        filterQuality: FilterQuality.high,
                        gaplessPlayback: true,
                        errorBuilder: (_, __, ___) => Icon(
                          Icons.card_giftcard,
                          size: _fullscreen ? 160 : 120,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
