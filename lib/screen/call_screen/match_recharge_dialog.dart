import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krimson/common/extensions/string_extension.dart';
import 'package:krimson/common/manager/coin_gate.dart';
import 'package:krimson/common/manager/session_manager.dart';
import 'package:krimson/common/widget/custom_image.dart';
import 'package:krimson/languages/languages_keys.dart';
import 'package:krimson/model/call/call_request_model.dart';
import 'package:krimson/model/general/settings_model.dart';
import 'package:krimson/model/user_model/user_model.dart';
import 'package:krimson/screen/call_screen/outgoing_call_screen.dart';
import 'package:krimson/utilities/client_colors.dart';
import 'package:krimson/utilities/text_style_custom.dart';

/// Ventana de gracia: 3 tiers de extensión configurados en el backend.
class MatchRechargeDialog {
  MatchRechargeDialog._();

  static Future<bool> show({
    CallParty? peer,
    int callCost = 0,
    List<MatchTier>? tiers,
    int graceSeconds = 10,
    DateTime? graceEndsAt,
    bool autoCloseOnTimeout = true,
    String? subtitle,
    Future<bool> Function(MatchTier tier)? onExtend,
  }) async {
    if (peer?.id == null) return false;
    final settings = SessionManager.instance.getSettings();
    final resolvedTiers = (tiers != null && tiers.isNotEmpty)
        ? tiers
        : (settings?.matchTiers ?? MatchTier.defaults);
    final resolvedGrace = graceSeconds > 0
        ? graceSeconds
        : (settings?.matchGraceSeconds ?? 10);

    final result = await Get.dialog<bool>(
      _MatchContinueBody(
        peer: peer!,
        callCost: callCost,
        tiers: resolvedTiers,
        graceSeconds: resolvedGrace,
        graceEndsAt: graceEndsAt,
        autoCloseOnTimeout: autoCloseOnTimeout,
        subtitle: subtitle,
        onExtend: onExtend,
      ),
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.78),
    );
    return result == true;
  }
}

class _MatchContinueBody extends StatefulWidget {
  const _MatchContinueBody({
    required this.peer,
    required this.tiers,
    this.callCost = 0,
    this.graceSeconds = 10,
    this.graceEndsAt,
    this.autoCloseOnTimeout = true,
    this.subtitle,
    this.onExtend,
  });

  final CallParty peer;
  final int callCost;
  final List<MatchTier> tiers;
  final int graceSeconds;
  final DateTime? graceEndsAt;
  final bool autoCloseOnTimeout;
  final String? subtitle;
  final Future<bool> Function(MatchTier tier)? onExtend;

  @override
  State<_MatchContinueBody> createState() => _MatchContinueBodyState();
}

class _MatchContinueBodyState extends State<_MatchContinueBody> {
  bool _busy = false;
  Timer? _graceTimer;
  late int _graceLeft;
  late final DateTime _graceDeadline;

  @override
  void initState() {
    super.initState();
    _graceDeadline = widget.graceEndsAt ??
        DateTime.now().add(Duration(seconds: widget.graceSeconds));
    _graceLeft = _computeGraceLeft();
    _graceTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final left = _computeGraceLeft();
      if (!mounted) return;
      setState(() => _graceLeft = left);
      if (left <= 0 && !_busy && widget.autoCloseOnTimeout) {
        _graceTimer?.cancel();
        _popDialog(false);
      }
    });
  }

  int _computeGraceLeft() {
    final s = _graceDeadline.difference(DateTime.now()).inSeconds;
    return s < 0 ? 0 : s;
  }

  @override
  void dispose() {
    _graceTimer?.cancel();
    super.dispose();
  }

  void _popDialog(bool result) {
    if (!mounted) return;
    final nav = Navigator.of(context, rootNavigator: true);
    if (nav.canPop()) {
      nav.pop(result);
    }
  }

  Future<void> _pick(MatchTier tier) async {
    if (_busy || (_graceLeft <= 0 && widget.autoCloseOnTimeout)) return;
    final peerId = widget.peer.id;
    if (peerId == null) return;

    if (!CoinGate.ensureEnough(
      tier.coins,
          message: LKey.needCoinsForMinutes.trParams({
            'coins': '${tier.coins}',
            'minutes': '${tier.minutes}',
          }),
    )) {
      return;
    }

    setState(() => _busy = true);
    try {
      final extend = widget.onExtend;
      if (extend != null) {
        final ok = await extend(tier);
        if (!mounted) return;
        if (ok) {
          _popDialog(true);
        } else {
          setState(() => _busy = false);
        }
        return;
      }
      _popDialog(true);
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
          cost: tier.coins,
          isMatch: true,
          matchFreeSeconds: tier.seconds,
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
    final offers = widget.tiers;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 18),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 18),
        decoration: BoxDecoration(
          gradient: ClientColors.surfaceGradient,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: ClientColors.border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.topRight,
              child: IconButton(
                onPressed: _busy ? null : () => _popDialog(false),
                icon: const Icon(Icons.close, color: ClientColors.textMuted, size: 20),
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
              strokeColor: ClientColors.secondary,
            ),
            const SizedBox(height: 10),
            Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyleCustom.outFitMedium500(
                color: ClientColors.text,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '¿Quieres seguir?',
              style: TextStyleCustom.outFitMedium500(
                color: ClientColors.text,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.subtitle ??
                  (widget.autoCloseOnTimeout
                      ? (_graceLeft > 0
                          ? 'Elige 5, 10 o 15 min para quedarte (${_graceLeft}s)'
                          : 'Tiempo de pago agotado')
                      : 'Elige 5, 10 o 15 min para quedarte'),
              textAlign: TextAlign.center,
              style: TextStyleCustom.outFitRegular400(
                color: ClientColors.textMuted,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: widget.graceSeconds > 0
                    ? (_graceLeft / widget.graceSeconds).clamp(0.0, 1.0)
                    : 0,
                minHeight: 6,
                backgroundColor: ClientColors.secondarySoft.withValues(alpha: 0.28),
                color: ClientColors.secondary,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 168,
              child: Row(
                children: [
                  for (var i = 0; i < offers.length; i++) ...[
                    if (i > 0) const SizedBox(width: 8),
                    Expanded(
                      child: _OfferCard(
                        tier: offers[i],
                        highlight: i == 1,
                        enabled: !_busy &&
                            (_graceLeft > 0 || !widget.autoCloseOnTimeout),
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
                  color: ClientColors.secondarySoft,
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
    required this.tier,
    required this.onTap,
    this.highlight = false,
    this.enabled = true,
  });

  final MatchTier tier;
  final VoidCallback onTap;
  final bool highlight;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final border = highlight ? ClientColors.secondary : ClientColors.border;
    final badge = highlight
        ? 'HOT'
        : (tier.tier == 3 ? 'MEJOR' : 'T${tier.tier}');

    return Material(
      color: highlight
          ? ClientColors.primary.withValues(alpha: 0.28)
          : ClientColors.surfaceAlt.withValues(alpha: 0.72),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: border, width: highlight ? 1.6 : 1),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
          child: Column(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: highlight
                      ? ClientColors.secondary
                      : ClientColors.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  badge,
                  style: TextStyleCustom.outFitMedium500(
                    color: ClientColors.text,
                    fontSize: 10,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${tier.minutes} min',
                style: TextStyleCustom.outFitMedium500(
                  color: ClientColors.text,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'con ella',
                style: TextStyleCustom.outFitRegular400(
                  color: ClientColors.textMuted,
                  fontSize: 11,
                ),
              ),
              const Spacer(),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: ClientColors.primary,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: ClientColors.primaryHover.withValues(alpha: 0.45),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Text(
                  '${tier.coins}',
                  textAlign: TextAlign.center,
                  style: TextStyleCustom.outFitMedium500(
                    color: ClientColors.text,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'coins',
                style: TextStyleCustom.outFitRegular400(
                  color: ClientColors.textMuted,
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
