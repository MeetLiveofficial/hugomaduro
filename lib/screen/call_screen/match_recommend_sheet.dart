import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krimson/common/extensions/string_extension.dart';
import 'package:krimson/common/manager/app_role.dart';
import 'package:krimson/common/manager/coin_gate.dart';
import 'package:krimson/common/widget/custom_image.dart';
import 'package:krimson/common/service/api/call_service.dart';
import 'package:krimson/model/user_model/user_model.dart';
import 'package:krimson/screen/call_screen/outgoing_call_screen.dart';
import 'package:krimson/utilities/color_res.dart';
import 'package:krimson/utilities/text_style_custom.dart';

/// Sheet: streamer recomendada por Match → tarjeta tipo Explore + Llamar.
class MatchRecommendSheet {
  MatchRecommendSheet._();

  static void dismissIfOpen() {
    try {
      if (Get.isBottomSheetOpen == true) {
        Get.back();
      }
    } catch (_) {}
  }

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
  late List<User> _users;
  int _index = 0;
  bool _loadingNext = false;
  double _dragDx = 0;
  late final String? _appLanguage;
  late final int _matchSeconds;

  static const double _swipeThreshold = 96;

  User get _user => _users[_index];

  @override
  void initState() {
    super.initState();
    _users = List<User>.from(widget.initial.users);
    if (_users.isEmpty) {
      _users = [widget.initial.user];
    }
    _appLanguage = widget.initial.appLanguage;
    _matchSeconds = widget.initial.matchFreeSeconds > 0
        ? widget.initial.matchFreeSeconds
        : 30;
  }

  Future<void> _loadNext() async {
    if (_loadingNext) return;
    if (_index + 1 < _users.length) {
      setState(() {
        _index += 1;
        _dragDx = 0;
      });
      return;
    }
    setState(() {
      _loadingNext = true;
      _dragDx = 0;
    });
    try {
      final seen = _users
          .map((u) => u.id ?? 0)
          .where((id) => id > 0)
          .toList();
      final next = await CallService.instance.findMatch(
        appLanguage: _appLanguage,
        mode: widget.mode,
        excludeUserIds: seen,
      );
      final extra = next.users.where((u) {
        final id = u.id;
        if (id == null || id <= 0) return false;
        return _users.every((e) => e.id != id);
      }).toList();
      if (!mounted) return;
      if (extra.isEmpty) {
        Get.snackbar(
          'Match',
          AppRole.isStreamer()
              ? 'No hay más clientes en Match ahora'
              : 'No hay más streamers en Match ahora',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.black87,
          colorText: Colors.white,
          margin: const EdgeInsets.all(12),
          duration: const Duration(seconds: 2),
        );
        return;
      }
      setState(() {
        _users.addAll(extra);
        _index += 1;
      });
    } catch (_) {
      if (!mounted) return;
      Get.snackbar(
        'Match',
        AppRole.isStreamer()
            ? 'No hay más clientes en Match ahora'
            : 'No hay más streamers en Match ahora',
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
    setState(() => _dragDx = (_dragDx + d.delta.dx).clamp(-180.0, 180.0));
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
    final user = _user;
    final cost = widget.initial.matchInitialCoins > 0
        ? widget.initial.matchInitialCoins
        : widget.initial.callCost;
    if (cost > 0 &&
        !CoinGate.ensureEnough(
          cost,
          message: 'Necesitas $cost coins para el Match',
        )) {
      return;
    }
    Get.back();
    Get.to(
      () => OutgoingCallScreen(
        callee: user,
        cost: cost,
        isMatch: true,
        matchFreeSeconds: _matchSeconds,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final cardH = (size.height * 0.68).clamp(420.0, 560.0);
    final tilt = (_dragDx / 240).clamp(-0.10, 0.10);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 84),
        child: Column(
          children: [
            const Spacer(),
            GestureDetector(
              onHorizontalDragUpdate: _onHorizontalDragUpdate,
              onHorizontalDragEnd: _onHorizontalDragEnd,
              child: AnimatedContainer(
                duration: _loadingNext
                    ? Duration.zero
                    : const Duration(milliseconds: 140),
                transform: Matrix4.identity()
                  ..translateByDouble(_dragDx, 0, 0, 1)
                  ..rotateZ(tilt),
                transformAlignment: Alignment.center,
                child: Opacity(
                  opacity: _loadingNext ? 0.7 : 1,
                  child: SizedBox(
                    height: cardH,
                    width: double.infinity,
                    child: _MatchProfileCard(
                      key: ValueKey(_user.id ?? _index),
                      user: _user,
                      loading: _loadingNext,
                      onCall: _loadingNext ? null : _call,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Desliza para el siguiente',
              style: TextStyleCustom.outFitRegular400(
                color: Colors.white54,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MatchProfileCard extends StatelessWidget {
  final User user;
  final bool loading;
  final VoidCallback? onCall;

  const _MatchProfileCard({
    super.key,
    required this.user,
    required this.loading,
    required this.onCall,
  });

  static String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2 &&
        parts[0].isNotEmpty &&
        parts[1].isNotEmpty) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    final compact = name.replaceAll(RegExp(r'\s+'), '');
    if (compact.length >= 2) return compact.substring(0, 2).toUpperCase();
    if (compact.isNotEmpty) return compact[0].toUpperCase();
    return '?';
  }

  @override
  Widget build(BuildContext context) {
    final name = (user.fullname ?? user.username ?? 'Streamer').trim();
    final handle = (user.username ?? '').trim();
    final photo = (user.profilePhoto ?? '').trim().addBaseURL();
    final country = (user.country ?? '').trim();
    final countryLabel = country.isNotEmpty
        ? country.toUpperCase()
        : (user.countryCode ?? '').trim().toUpperCase();

    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF8B6AA8),
                  Color(0xFF4A3270),
                  Color(0xFF1C1228),
                ],
              ),
            ),
          ),
          if (photo.isNotEmpty)
            CustomImage(
              size: const Size(400, 700),
              image: photo,
              fit: BoxFit.cover,
              radius: 0,
              isShowPlaceHolder: true,
              fullName: name,
            )
          else
            Center(
              child: Text(
                _initials(name),
                style: TextStyleCustom.outFitRegular400(
                  color: Colors.white.withValues(alpha: 0.28),
                  fontSize: 88,
                ),
              ),
            ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x33000000),
                  Colors.transparent,
                  Color(0xF2140E1C),
                ],
                stops: [0, 0.38, 1],
              ),
            ),
          ),
          if (countryLabel.isNotEmpty)
            Positioned(
              top: 14,
              left: 14,
              child: _Pill(
                child: Text(
                  countryLabel,
                  style: TextStyleCustom.outFitMedium500(
                    color: Colors.white,
                    fontSize: 11,
                  ),
                ),
              ),
            ),
          Positioned(
            top: 14,
            right: 14,
            child: _Pill(
              color: const Color(0xE6166534),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFF4ADE80),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'En Match',
                    style: TextStyleCustom.outFitMedium500(
                      color: Colors.white,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyleCustom.outFitSemiBold600(
                    color: Colors.white,
                    fontSize: 22,
                  ),
                ),
                if (handle.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    handle.startsWith('@') ? handle : '@$handle',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyleCustom.outFitRegular400(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: onCall,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ColorRes.themeAccentSolid,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: const Icon(Icons.videocam_rounded, size: 18),
                    label: Text(
                      'Llamar',
                      style: TextStyleCustom.outFitMedium500(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (loading)
            const ColoredBox(
              color: Color(0x66000000),
              child: Center(
                child: SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final Widget child;
  final Color color;

  const _Pill({
    required this.child,
    this.color = const Color(0x99000000),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: child,
    );
  }
}
