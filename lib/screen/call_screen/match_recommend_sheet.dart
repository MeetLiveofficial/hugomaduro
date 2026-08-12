import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krimson/common/extensions/string_extension.dart';
import 'package:krimson/common/widget/custom_image.dart';
import 'package:krimson/common/service/api/call_service.dart';
import 'package:krimson/screen/call_screen/outgoing_call_screen.dart';
import 'package:krimson/utilities/color_res.dart';
import 'package:krimson/utilities/text_style_custom.dart';

/// Sheet: streamer recomendada por Match → llamar o deslizar al siguiente.
class MatchRecommendSheet {
  MatchRecommendSheet._();

  static Future<void> show(
    MatchRecommendation match, {
    String mode = 'random',
  }) async {
    await Get.bottomSheet(
      _MatchRecommendBody(initial: match, mode: mode),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      enableDrag: false,
    );
  }
}

class _MatchRecommendBody extends StatefulWidget {
  const _MatchRecommendBody({
    required this.initial,
    required this.mode,
  });

  final MatchRecommendation initial;
  final String mode;

  @override
  State<_MatchRecommendBody> createState() => _MatchRecommendBodyState();
}

class _MatchRecommendBodyState extends State<_MatchRecommendBody> {
  late MatchRecommendation _match;
  final List<int> _seenIds = [];
  bool _loadingNext = false;
  double _dragDx = 0;

  static const double _swipeThreshold = 96;

  @override
  void initState() {
    super.initState();
    _match = widget.initial;
    final id = _match.user.id;
    if (id != null && id > 0) _seenIds.add(id);
  }

  Future<void> _loadNext() async {
    if (_loadingNext) return;
    setState(() {
      _loadingNext = true;
      _dragDx = 0;
    });
    try {
      final next = await CallService.instance.findMatch(
        appLanguage: _match.appLanguage,
        mode: widget.mode,
        excludeUserIds: List<int>.from(_seenIds),
      );
      final nextId = next.user.id;
      if (nextId != null && nextId > 0) {
        _seenIds.add(nextId);
      }
      if (!mounted) return;
      setState(() => _match = next);
    } catch (_) {
      if (!mounted) return;
      Get.snackbar(
        'Match',
        'No hay más streamers disponibles ahora',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.black87,
        colorText: Colors.white,
        margin: const EdgeInsets.all(12),
        duration: const Duration(seconds: 2),
      );
    } finally {
      if (mounted) setState(() => _loadingNext = false);
    }
  }

  void _onHorizontalDragUpdate(DragUpdateDetails d) {
    if (_loadingNext) return;
    setState(() => _dragDx = (_dragDx + d.delta.dx).clamp(-160.0, 160.0));
  }

  void _onHorizontalDragEnd(DragEndDetails d) {
    if (_loadingNext) return;
    final velocity = d.primaryVelocity ?? 0;
    final shouldSkip =
        _dragDx.abs() >= _swipeThreshold || velocity.abs() > 700;
    if (shouldSkip) {
      _loadNext();
    } else {
      setState(() => _dragDx = 0);
    }
  }

  void _call() {
    final user = _match.user;
    final seconds =
        _match.matchFreeSeconds > 0 ? _match.matchFreeSeconds : 30;
    Get.back();
    Get.to(
      () => OutgoingCallScreen(
        callee: user,
        cost: 0,
        isMatch: true,
        matchFreeSeconds: seconds,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _match.user;
    final name = (user.fullname ?? user.username ?? 'Streamer').trim();
    final lang = (_match.appLanguage ?? user.appLanguage ?? '').trim();
    final seconds =
        _match.matchFreeSeconds > 0 ? _match.matchFreeSeconds : 30;
    final tilt = (_dragDx / 220).clamp(-0.12, 0.12);

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1224),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: ColorRes.mauve.withValues(alpha: 0.45),
        ),
        boxShadow: [
          BoxShadow(
            color: ColorRes.mauve.withValues(alpha: 0.25),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Match encontrado',
              style: TextStyleCustom.outFitMedium500(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Desliza para el siguiente',
              style: TextStyleCustom.outFitRegular400(
                color: Colors.white54,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 14),
            GestureDetector(
              onHorizontalDragUpdate: _onHorizontalDragUpdate,
              onHorizontalDragEnd: _onHorizontalDragEnd,
              child: AnimatedContainer(
                duration: _loadingNext
                    ? Duration.zero
                    : const Duration(milliseconds: 120),
                transform: Matrix4.identity()
                  ..translateByDouble(_dragDx, 0, 0, 1)
                  ..rotateZ(tilt),
                transformAlignment: Alignment.center,
                child: Opacity(
                  opacity: _loadingNext ? 0.55 : 1,
                  child: Column(
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          CustomImage(
                            size: const Size(88, 88),
                            image: user.profilePhoto?.addBaseURL(),
                            fullName: name,
                            radius: 44,
                            strokeWidth: 2,
                            strokeColor: ColorRes.themeAccentSolid,
                          ),
                          if (_loadingNext)
                            const SizedBox(
                              width: 28,
                              height: 28,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.4,
                                color: Colors.white,
                              ),
                            ),
                          if (!_loadingNext && _dragDx.abs() > 28)
                            Positioned(
                              left: _dragDx < 0 ? 0 : null,
                              right: _dragDx > 0 ? 0 : null,
                              child: Icon(
                                _dragDx < 0
                                    ? Icons.keyboard_arrow_left_rounded
                                    : Icons.keyboard_arrow_right_rounded,
                                color: ColorRes.themeAccentSolid
                                    .withValues(alpha: 0.9),
                                size: 28,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyleCustom.outFitMedium500(
                          color: Colors.white,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        lang.isEmpty
                            ? 'Preview gratis · $seconds s'
                            : 'Idioma: $lang · Preview gratis $seconds s',
                        style: TextStyleCustom.outFitRegular400(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _loadingNext ? null : Get.back,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white70,
                      side: const BorderSide(color: Colors.white24),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    child: Text(
                      'Cancelar',
                      style: TextStyleCustom.outFitMedium500(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Material(
                  color: Colors.white.withValues(alpha: 0.08),
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: _loadingNext ? null : _loadNext,
                    child: const SizedBox(
                      width: 48,
                      height: 48,
                      child: Icon(
                        Icons.swipe_rounded,
                        color: Colors.white70,
                        size: 22,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _loadingNext ? null : _call,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ColorRes.themeAccentSolid,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    icon: const Icon(Icons.videocam_rounded, size: 18),
                    label: Text(
                      'Llamar',
                      style: TextStyleCustom.outFitMedium500(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
