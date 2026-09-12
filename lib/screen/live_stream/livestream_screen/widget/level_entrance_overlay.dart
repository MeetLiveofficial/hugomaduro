import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krimson/common/manager/haptic_manager.dart';
import 'package:krimson/common/widget/gift_media.dart';

/// Video / banner de entrada por nivel: 50% inferior de la pantalla del LIVE.
///
/// Se inserta como OverlayEntry (no dialog) para no bloquear el tacto.
class LevelEntranceOverlay {
  LevelEntranceOverlay._();

  static OverlayEntry? _entry;
  static bool _open = false;

  static void _remove() {
    final entry = _entry;
    _entry = null;
    _open = false;
    entry?.remove();
  }

  static void show(
    String? videoPath, {
    String? userName,
    int? level,
    String? levelTitle,
    bool isSvip = false,
    bool isVip = false,
  }) {
    final path = (videoPath ?? '').trim();
    if (path.isEmpty && !isVip) return;
    final ctx = Get.overlayContext ?? Get.context;
    if (ctx == null) return;

    if (_open) {
      _remove();
    }

    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => IgnorePointer(
        child: _LevelEntranceDialog(
          videoPath: path,
          userName: userName,
          level: level,
          levelTitle: levelTitle,
          isSvip: isSvip,
          isVip: isVip,
          onFinished: () {
            if (_entry == entry) {
              _remove();
            }
          },
        ),
      ),
    );
    _entry = entry;
    _open = true;
    HapticManager.shared.light();
    final overlay = Navigator.of(ctx, rootNavigator: true).overlay ??
        Overlay.of(ctx, rootOverlay: true);
    overlay.insert(entry);
  }
}

class _LevelEntranceDialog extends StatefulWidget {
  const _LevelEntranceDialog({
    required this.videoPath,
    required this.onFinished,
    this.userName,
    this.level,
    this.levelTitle,
    this.isSvip = false,
    this.isVip = false,
  });

  final String videoPath;
  final VoidCallback onFinished;
  final String? userName;
  final int? level;
  final String? levelTitle;
  final bool isSvip;
  final bool isVip;

  @override
  State<_LevelEntranceDialog> createState() => _LevelEntranceDialogState();
}

class _LevelEntranceDialogState extends State<_LevelEntranceDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fadeCtrl;
  late final Animation<double> _opacity;
  bool _closing = false;
  Timer? _safetyTimer;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _opacity = Tween<double>(begin: 0, end: 1)
        .chain(CurveTween(curve: Curves.easeOut))
        .animate(_fadeCtrl);
    _fadeCtrl.forward();
    if (widget.videoPath.trim().isEmpty) {
      _safetyTimer = Timer(const Duration(seconds: 4), _dismiss);
    } else {
      _safetyTimer = Timer(const Duration(seconds: 45), _dismiss);
    }
  }

  void _onVideoReady(Duration duration) {
    if (duration.inMilliseconds <= 0) return;
    _safetyTimer?.cancel();
    _safetyTimer = Timer(duration + const Duration(seconds: 3), _dismiss);
  }

  void _onVideoEnded() {
    if (_closing || !mounted) return;
    _dismiss();
  }

  void _dismiss() {
    if (_closing || !mounted) return;
    _closing = true;
    _safetyTimer?.cancel();
    _fadeCtrl.reverse().whenComplete(() {
      if (!mounted) return;
      widget.onFinished();
    });
  }

  @override
  void dispose() {
    _safetyTimer?.cancel();
    _fadeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final h = size.height * 0.5;
    final w = size.width;
    final name = (widget.userName ?? '').trim();
    final level = widget.level ?? 0;
    final title = (widget.levelTitle ?? '').trim();
    final levelLabel = widget.isVip
        ? '👑 VIP'
        : (widget.isSvip
            ? 'SVIP'
            : (level > 0 ? 'Lv. $level' : title));

    return Material(
      type: MaterialType.transparency,
      child: FadeTransition(
        opacity: _opacity,
        child: Align(
          alignment: Alignment.bottomCenter,
          child: SizedBox(
            width: w,
            height: h,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (widget.videoPath.trim().isNotEmpty)
                  GiftMedia(
                    path: widget.videoPath,
                    width: w,
                    height: h,
                    fit: BoxFit.cover,
                    muted: false,
                    looping: false,
                    onVideoEnded: _onVideoEnded,
                    onVideoReady: _onVideoReady,
                    placeholder: const SizedBox.shrink(),
                  )
                else if (widget.isVip)
                  Align(
                    alignment: Alignment.center,
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 24),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFFFFE082),
                            Color(0xFFFFC107),
                            Color(0xFFFF8F00),
                          ],
                        ),
                      ),
                      child: Text(
                        name.isEmpty
                            ? '👑 VIP ha entrado al LIVE'
                            : '👑 VIP — $name ha entrado al LIVE',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFF3E2723),
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                if (widget.videoPath.trim().isNotEmpty &&
                    (name.isNotEmpty || levelLabel.isNotEmpty))
                  Positioned(
                    left: 16,
                    right: 16,
                    top: 12,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (name.isNotEmpty)
                          Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.95),
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              shadows: const [
                                Shadow(blurRadius: 8, color: Colors.black54),
                              ],
                            ),
                          ),
                        if (levelLabel.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            levelLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.88),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              shadows: const [
                                Shadow(blurRadius: 6, color: Colors.black54),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
