import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krimson/common/extensions/string_extension.dart';
import 'package:krimson/common/manager/session_manager.dart';
import 'package:krimson/common/widget/custom_image.dart';
import 'package:krimson/languages/languages_keys.dart';
import 'package:krimson/model/call/call_request_model.dart';
import 'package:krimson/model/user_model/user_model.dart';
import 'package:krimson/utilities/asset_res.dart';
import 'package:krimson/utilities/text_style_custom.dart';

/// Cliente (izquierda) y streamer (derecha) en el loading de Match.
class MatchConnectingParty {
  const MatchConnectingParty({
    required this.name,
    this.photoUrl,
  });

  final String name;
  final String? photoUrl;

  static String _label(String? fullname, String? username) {
    final n = (fullname ?? '').trim();
    if (n.isNotEmpty) return n;
    final u = (username ?? '').trim();
    if (u.isNotEmpty) return u;
    return '—';
  }

  static String? _photo(String? path) {
    final p = (path ?? '').trim();
    if (p.isEmpty) return null;
    return p.addBaseURL();
  }

  factory MatchConnectingParty.fromUser(User? user) {
    return MatchConnectingParty(
      name: _label(user?.fullname, user?.username),
      photoUrl: _photo(user?.profilePhoto),
    );
  }

  factory MatchConnectingParty.fromParty(CallParty? party) {
    return MatchConnectingParty(
      name: _label(party?.fullname, party?.username),
      photoUrl: _photo(party?.profilePhoto),
    );
  }

  static MatchConnectingParty callerOf(CallRequestModel call) {
    final me = SessionManager.instance.getUser();
    if (call.caller != null) {
      return MatchConnectingParty.fromParty(call.caller);
    }
    if (call.callerId != null && call.callerId == me?.id) {
      return MatchConnectingParty.fromUser(me);
    }
    return const MatchConnectingParty(name: '—');
  }

  static MatchConnectingParty calleeOf(CallRequestModel call) {
    final me = SessionManager.instance.getUser();
    if (call.callee != null) {
      return MatchConnectingParty.fromParty(call.callee);
    }
    if (call.calleeId != null && call.calleeId == me?.id) {
      return MatchConnectingParty.fromUser(me);
    }
    return const MatchConnectingParty(name: '—');
  }
}

/// Overlay de espera Match: GIF, nombres y avatares de ambos.
class MatchConnectingView extends StatelessWidget {
  const MatchConnectingView({
    super.key,
    required this.left,
    required this.right,
    this.subtitle,
    this.errorText,
    this.bottom,
  });

  final MatchConnectingParty left;
  final MatchConnectingParty right;
  final String? subtitle;
  final String? errorText;
  final Widget? bottom;

  static const Color _bg = Color(0xFFF3C2D8);
  static const Color _pulse = Color(0xFFFF3B8D);

  @override
  Widget build(BuildContext context) {
    final status = (subtitle ?? '').trim().isEmpty
        ? LKey.connecting.tr
        : subtitle!.trim();
    final err = (errorText ?? '').trim();

    return SizedBox.expand(
      child: ColoredBox(
        color: _bg,
        child: Stack(
          fit: StackFit.expand,
          children: [
            const _MatchConnectingGif(),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x99081220),
                  Color(0x22081220),
                  Color(0x00000000),
                  Color(0x33081220),
                  Color(0xCC12081C),
                ],
                stops: [0, 0.18, 0.48, 0.78, 1],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
              child: Column(
                children: [
                  _MatchNamesHeader(left: left, right: right),
                  const Spacer(),
                  Text(
                    status,
                    textAlign: TextAlign.center,
                    style: TextStyleCustom.outFitMedium500(
                      color: Colors.white.withValues(alpha: 0.92),
                      fontSize: 16,
                    ),
                  ),
                  if (err.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      err,
                      textAlign: TextAlign.center,
                      style: TextStyleCustom.outFitRegular400(
                        color: const Color(0xFFFF8A9A),
                        fontSize: 13,
                      ),
                    ),
                  ],
                  if (bottom != null) ...[
                    const SizedBox(height: 18),
                    bottom!,
                  ],
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ],
        ),
      ),
    );
  }
}

class _MatchConnectingGif extends StatelessWidget {
  const _MatchConnectingGif();

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: Image.asset(
        AssetRes.matchConnectingGif,
        fit: BoxFit.cover,
        alignment: Alignment.center,
        width: double.infinity,
        height: double.infinity,
        gaplessPlayback: true,
        filterQuality: FilterQuality.medium,
        excludeFromSemantics: true,
        errorBuilder: (_, __, ___) => const ColoredBox(
          color: MatchConnectingView._bg,
          child: Center(
            child: Icon(Icons.favorite_rounded, color: Color(0xFFFF3B8D), size: 72),
          ),
        ),
      ),
    );
  }
}

class _MatchNamesHeader extends StatelessWidget {
  const _MatchNamesHeader({
    required this.left,
    required this.right,
  });

  final MatchConnectingParty left;
  final MatchConnectingParty right;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _PartyChip(party: left, alignEnd: false)),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: _HeartbeatMark(),
        ),
        Expanded(child: _PartyChip(party: right, alignEnd: true)),
      ],
    );
  }
}

class _PartyChip extends StatelessWidget {
  const _PartyChip({
    required this.party,
    required this.alignEnd,
  });

  final MatchConnectingParty party;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    final name = Text(
      party.name,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textAlign: alignEnd ? TextAlign.right : TextAlign.left,
      style: TextStyleCustom.unboundedSemiBold600(
        color: Colors.white,
        fontSize: 15,
      ),
    );
    final avatar = _RingAvatar(
      photoUrl: party.photoUrl,
      name: party.name,
    );
    final children = alignEnd
        ? <Widget>[Expanded(child: name), const SizedBox(width: 8), avatar]
        : <Widget>[avatar, const SizedBox(width: 8), Expanded(child: name)];
    return Row(children: children);
  }
}

class _RingAvatar extends StatelessWidget {
  const _RingAvatar({
    required this.photoUrl,
    required this.name,
  });

  final String? photoUrl;
  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2.4),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ClipOval(
        child: CustomImage(
          size: const Size(44, 44),
          image: photoUrl,
          fullName: name,
          radius: 22,
          strokeWidth: 0,
          isShowPlaceHolder: true,
          webPreferHtmlElement: false,
        ),
      ),
    );
  }
}

class _HeartbeatMark extends StatefulWidget {
  const _HeartbeatMark();

  @override
  State<_HeartbeatMark> createState() => _HeartbeatMarkState();
}

class _HeartbeatMarkState extends State<_HeartbeatMark>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.55, end: 1).animate(
        CurvedAnimation(parent: _pulse, curve: Curves.easeInOut),
      ),
      child: CustomPaint(
        size: const Size(42, 22),
        painter: _HeartbeatPainter(),
      ),
    );
  }
}

class _HeartbeatPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = MatchConnectingView._pulse
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;
    final y = size.height * 0.55;
    final path = Path()
      ..moveTo(0, y)
      ..lineTo(size.width * 0.18, y)
      ..lineTo(size.width * 0.30, y - size.height * 0.42)
      ..lineTo(size.width * 0.42, y + size.height * 0.46)
      ..lineTo(size.width * 0.52, y - size.height * 0.16)
      ..lineTo(size.width * 0.64, y)
      ..lineTo(size.width, y);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
