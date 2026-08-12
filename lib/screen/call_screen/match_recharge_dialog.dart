import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krimson/common/extensions/string_extension.dart';
import 'package:krimson/common/manager/coin_gate.dart';
import 'package:krimson/common/widget/custom_image.dart';
import 'package:krimson/model/call/call_request_model.dart';
import 'package:krimson/model/user_model/user_model.dart';
import 'package:krimson/screen/call_screen/outgoing_call_screen.dart';
import 'package:krimson/utilities/color_res.dart';
import 'package:krimson/utilities/text_style_custom.dart';

/// Tras el Match gratis: ofrecer minutos extra pagando coins a la streamer.
class MatchRechargeDialog {
  MatchRechargeDialog._();

  static Future<bool> show({
    CallParty? peer,
    int callCost = 0,
    Future<bool> Function(int minutes, int coins)? onExtend,
  }) async {
    if (peer?.id == null) return false;

    final result = await Get.dialog<bool>(
      _MatchContinueBody(
        peer: peer!,
        callCost: callCost,
        onExtend: onExtend,
      ),
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.72),
    );
    return result == true;
  }
}

class _MatchOffer {
  const _MatchOffer({
    required this.minutes,
    required this.coins,
    required this.wasCoins,
    required this.badge,
    this.highlight = false,
  });

  final int minutes;
  final int coins;
  final int wasCoins;
  final String badge;
  final bool highlight;
}

List<_MatchOffer> _buildOffers(int callCost) {
  final base = callCost > 0 ? callCost : 100;
  // Precios tipo oferta (descuento fuerte) para seguir hablando.
  final five = (base * 3.2).round().clamp(120, 5000);
  final eight = (base * 4.5).round().clamp(180, 8000);
  final thirteen = (base * 6.2).round().clamp(250, 12000);
  return [
    _MatchOffer(
      minutes: 5,
      coins: five,
      wasCoins: (five * 2.1).round(),
      badge: '-52%',
    ),
    _MatchOffer(
      minutes: 8,
      coins: eight,
      wasCoins: (eight * 2.2).round(),
      badge: 'HOT',
      highlight: true,
    ),
    _MatchOffer(
      minutes: 13,
      coins: thirteen,
      wasCoins: (thirteen * 2.4).round(),
      badge: 'MEJOR',
    ),
  ];
}

class _MatchContinueBody extends StatefulWidget {
  const _MatchContinueBody({
    required this.peer,
    this.callCost = 0,
    this.onExtend,
  });

  final CallParty peer;
  final int callCost;
  final Future<bool> Function(int minutes, int coins)? onExtend;

  @override
  State<_MatchContinueBody> createState() => _MatchContinueBodyState();
}

class _MatchContinueBodyState extends State<_MatchContinueBody> {
  bool _busy = false;

  Future<void> _pick(_MatchOffer offer) async {
    if (_busy) return;
    final peerId = widget.peer.id;
    if (peerId == null) return;

    if (!CoinGate.ensureEnough(
      offer.coins,
      message: 'Necesitas ${offer.coins} coins para ${offer.minutes} min',
    )) {
      return;
    }

    setState(() => _busy = true);
    try {
      final extend = widget.onExtend;
      if (extend != null) {
        final ok = await extend(offer.minutes, offer.coins);
        if (!mounted) return;
        if (ok) {
          Get.back(result: true);
        } else {
          setState(() => _busy = false);
        }
        return;
      }
      Get.back(result: true);
      final user = User(
        id: peerId,
        fullname: widget.peer.fullname,
        username: widget.peer.username,
        profilePhoto: widget.peer.profilePhoto,
        isVerify: widget.peer.isVerify,
        levelNumber: widget.peer.levelNumber,
        levelTitle: widget.peer.levelTitle,
        canReceiveCalls: widget.peer.canReceiveCalls,
        callRequestCoins: widget.peer.callRequestCoins,
      );
      await Get.to(
        () => OutgoingCallScreen(
          callee: user,
          cost: offer.coins,
          isMatch: true,
          matchFreeSeconds: offer.minutes * 60,
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final name =
        (widget.peer.fullname ?? widget.peer.username ?? 'Streamer').trim();
    final offers = _buildOffers(widget.callCost);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 18),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF6B2D8B), Color(0xFF3D1A55)],
          ),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.topRight,
              child: IconButton(
                onPressed: _busy ? null : Get.back,
                icon: const Icon(Icons.close, color: Colors.white70, size: 20),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
            ),
            CustomImage(
              size: const Size(72, 72),
              image: widget.peer.profilePhoto?.addBaseURL(),
              fullName: name,
              radius: 36,
              strokeWidth: 2,
              strokeColor: ColorRes.accentPeach,
            ),
            const SizedBox(height: 10),
            Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyleCustom.outFitMedium500(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '¿Quieres seguir?',
              style: TextStyleCustom.outFitMedium500(
                color: const Color(0xFFFFD6F0),
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Envíale coins y continúa el Match con ella',
              textAlign: TextAlign.center,
              style: TextStyleCustom.outFitRegular400(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Expanded(child: Divider(color: Colors.white24)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Text(
                    'Ofertas de tiempo',
                    style: TextStyleCustom.outFitMedium500(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ),
                const Expanded(child: Divider(color: Colors.white24)),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 168,
              child: Row(
                children: [
                  for (var i = 0; i < offers.length; i++) ...[
                    if (i > 0) const SizedBox(width: 8),
                    Expanded(
                      child: _OfferCard(
                        offer: offers[i],
                        enabled: !_busy,
                        onTap: () => _pick(offers[i]),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (_busy) ...[
              const SizedBox(height: 10),
              const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white70,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _OfferCard extends StatelessWidget {
  const _OfferCard({
    required this.offer,
    required this.onTap,
    this.enabled = true,
  });

  final _MatchOffer offer;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final border = offer.highlight
        ? const Color(0xFFFFD166)
        : Colors.white.withValues(alpha: 0.14);

    return Material(
      color: offer.highlight
          ? Colors.white.withValues(alpha: 0.16)
          : Colors.white.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: border, width: offer.highlight ? 1.6 : 1),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
          child: Column(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: offer.highlight
                      ? const Color(0xFFFFD166)
                      : const Color(0xFFFF4FA3),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  offer.badge,
                  style: TextStyleCustom.outFitMedium500(
                    color: offer.highlight ? Colors.black87 : Colors.white,
                    fontSize: 10,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${offer.minutes} min',
                style: TextStyleCustom.outFitMedium500(
                  color: Colors.white,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'con ella',
                style: TextStyleCustom.outFitRegular400(
                  color: Colors.white60,
                  fontSize: 11,
                ),
              ),
              const Spacer(),
              Text(
                '${offer.wasCoins}',
                style: TextStyleCustom.outFitRegular400(
                  color: Colors.white38,
                  fontSize: 11,
                ).copyWith(decoration: TextDecoration.lineThrough),
              ),
              const SizedBox(height: 2),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF4FA3),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF4FA3).withValues(alpha: 0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Text(
                  '${offer.coins}',
                  textAlign: TextAlign.center,
                  style: TextStyleCustom.outFitMedium500(
                    color: Colors.white,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'coins',
                style: TextStyleCustom.outFitRegular400(
                  color: Colors.white54,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
