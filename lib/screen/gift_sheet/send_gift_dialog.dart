import 'package:flutter/material.dart';
import 'package:krimson/common/extensions/string_extension.dart';
import 'package:krimson/model/general/settings_model.dart';
import 'package:krimson/utilities/app_res.dart';

/// Overlay transparente: solo la imagen del regalo; se cierra sola (~20s).
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

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _scale = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack);
    _ctrl.forward();
    Future.delayed(const Duration(seconds: AppRes.giftDialogDismissTime), () {
      _dismiss();
    });
  }

  void _dismiss() {
    if (!mounted) return;
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
    return Material(
      type: MaterialType.transparency,
      color: Colors.transparent,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _dismiss,
        child: Center(
          child: ScaleTransition(
            scale: _scale,
            child: IgnorePointer(
              child: url.isEmpty
                  ? const Icon(Icons.card_giftcard,
                      size: 120, color: Colors.white)
                  : Image.network(
                      url,
                      width: 180,
                      height: 180,
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.high,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.card_giftcard,
                        size: 120,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
