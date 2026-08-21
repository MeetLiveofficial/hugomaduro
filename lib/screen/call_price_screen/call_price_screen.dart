import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:krimson/common/widget/custom_app_bar.dart';
import 'package:krimson/languages/languages_keys.dart';
import 'package:krimson/screen/call_price_screen/call_price_screen_controller.dart';
import 'package:krimson/utilities/asset_res.dart';
import 'package:krimson/utilities/color_res.dart';
import 'package:krimson/utilities/style_res.dart';
import 'package:krimson/utilities/text_style_custom.dart';
import 'package:krimson/utilities/theme_res.dart';

class CallPriceScreen extends StatelessWidget {
  const CallPriceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.put(CallPriceScreenController());
    return Scaffold(
      backgroundColor: bgLightGrey(context),
      body: Column(
        children: [
          CustomAppBar(title: LKey.callPriceScreenTitle.tr),
          Expanded(
            child: Obx(() {
              if (c.pageLoading.value && c.stats.value == null) {
                return const Center(child: CircularProgressIndicator());
              }
              return RefreshIndicator(
                onRefresh: c.load,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                  children: [
                    _PriceCard(controller: c),
                    const SizedBox(height: 22),
                    _Tips(canEdit: c.canEdit),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _PriceCard extends StatelessWidget {
  const _PriceCard({required this.controller});

  final CallPriceScreenController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final canEdit = controller.canEdit;
      final price = controller.price;
      final grade = controller.grade;
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
        decoration: BoxDecoration(
          gradient: StyleRes.duskGradient,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: ColorRes.mlPurple.withValues(alpha: 0.28),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              LKey.myPrivateCallPrice.tr,
              style: TextStyleCustom.outFitRegular400(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 14),
            InkWell(
              onTap: canEdit ? () => _openEditor(context) : null,
              borderRadius: BorderRadius.circular(8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(AssetRes.icCoin, width: 28, height: 28),
                  const SizedBox(width: 8),
                  Text(
                    '$price/min',
                    style: TextStyleCustom.outFitExtraBold800(
                      color: Colors.white,
                      fontSize: 32,
                    ),
                  ),
                  if (canEdit) ...[
                    const SizedBox(width: 8),
                    const Icon(Icons.edit_square, color: Colors.white, size: 22),
                  ],
                ],
              ),
            ),
            Container(
              margin: const EdgeInsets.only(top: 6, bottom: 14),
              width: 148,
              height: 1.2,
              color: Colors.white.withValues(alpha: 0.55),
            ),
            Text(
              '${LKey.myCurrentGrade.tr}: $grade',
              style: TextStyleCustom.outFitMedium500(
                color: const Color(0xFFFFE08A),
                fontSize: 14,
              ),
            ),
            if (!canEdit) ...[
              const SizedBox(height: 10),
              Text(
                LKey.callPriceLockedHint.tr,
                textAlign: TextAlign.center,
                style: TextStyleCustom.outFitRegular400(
                  color: Colors.white.withValues(alpha: 0.78),
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
      );
    });
  }

  void _openEditor(BuildContext context) {
    final p = controller.pricing;
    if (p == null || !p.canEdit) return;
    Get.bottomSheet(
      _PricePickerSheet(
        min: p.min,
        max: p.max,
        value: p.effectivePrice,
        onConfirm: controller.savePrice,
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }
}

class _Tips extends StatelessWidget {
  const _Tips({required this.canEdit});

  final bool canEdit;

  @override
  Widget build(BuildContext context) {
    const tips = [
      'El precio de llamada lo ajusta la plataforma según tu rendimiento.',
      'Para cambiar el rango de precio, contacta a soporte o a tu agente.',
      'Subir el precio puede aumentar tus ingresos, pero no lo hagas de golpe.',
      'Si al subir el precio bajan las llamadas, restaura el precio anterior.',
      'Prueba varios montos hasta equilibrar volumen de llamadas e ingresos.',
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          LKey.callPriceTipsTitle.tr,
          style: TextStyleCustom.outFitSemiBold600(
            color: textDarkGrey(context),
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 12),
        for (var i = 0; i < tips.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${i + 1}.  ',
                  style: TextStyleCustom.outFitMedium500(
                    color: textDarkGrey(context),
                    fontSize: 13,
                  ),
                ),
                Expanded(
                  child: Text(
                    tips[i],
                    style: TextStyleCustom.outFitRegular400(
                      color: i == 3 ? ColorRes.crimsonAlt : textLightGrey(context),
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        if (canEdit)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'Rango A: precio dentro del límite A. Rango S: límite más amplio.',
              style: TextStyleCustom.outFitRegular400(
                color: textLightGrey(context),
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }
}

class _PricePickerSheet extends StatefulWidget {
  const _PricePickerSheet({
    required this.min,
    required this.max,
    required this.value,
    required this.onConfirm,
  });

  final int min;
  final int max;
  final int value;
  final Future<bool> Function(int price) onConfirm;

  @override
  State<_PricePickerSheet> createState() => _PricePickerSheetState();
}

class _PricePickerSheetState extends State<_PricePickerSheet> {
  static const double _tickWidth = 16;
  late int _value;
  late int _step;
  late int _majorEvery;
  late ScrollController _scroll;
  bool _snapping = false;

  List<int> get _ticks {
    final out = <int>[];
    for (var v = widget.min; v <= widget.max; v += _step) {
      out.add(v);
    }
    if (out.isEmpty) out.add(widget.min);
    if (out.last != widget.max) out.add(widget.max);
    return out;
  }

  @override
  void initState() {
    super.initState();
    final span = (widget.max - widget.min).abs();
    _step = span <= 40 ? 1 : 10;
    _majorEvery = _step <= 1 ? 10 : 50;
    _value = _snap(widget.value);
    _scroll = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _jumpToValue();
      if (!_scroll.hasClients) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _jumpToValue());
      }
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  int _snap(int v) {
    final clamped = v.clamp(widget.min, widget.max);
    if (_step <= 1) return clamped;
    final n = ((clamped - widget.min) / _step).round();
    return (widget.min + n * _step).clamp(widget.min, widget.max);
  }

  void _jumpToValue() {
    if (!mounted || !_scroll.hasClients) return;
    final idx = _ticks.indexOf(_value).clamp(0, _ticks.length - 1);
    _scroll.jumpTo(idx * _tickWidth);
  }

  void _syncFromScroll({required bool snap}) {
    if (!_scroll.hasClients || _snapping) return;
    final ticks = _ticks;
    final i = (_scroll.offset / _tickWidth).round().clamp(0, ticks.length - 1);
    final v = ticks[i];
    if (v != _value) {
      setState(() => _value = v);
      HapticFeedback.selectionClick();
    }
    if (!snap) return;
    final target = i * _tickWidth;
    if ((_scroll.offset - target).abs() < 0.5) return;
    _snapping = true;
    _scroll
        .animateTo(
          target,
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
        )
        .whenComplete(() {
      _snapping = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final ticks = _ticks;
    return Container(
      height: 268,
      decoration: const BoxDecoration(
        color: Color(0xFFF3F3F3),
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 0),
              child: Row(
                children: [
                  TextButton(
                    onPressed: Get.back,
                    child: Text(
                      LKey.cancel.tr,
                      style: TextStyleCustom.outFitMedium500(
                        color: textLightGrey(context),
                        fontSize: 15,
                      ),
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () async {
                      final ok = await widget.onConfirm(_value);
                      if (ok && mounted) Get.back();
                    },
                    child: Text(
                      LKey.confirm.tr,
                      style: TextStyleCustom.outFitSemiBold600(
                        color: ColorRes.mlPurple,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Text(
              '$_value/min',
              style: TextStyleCustom.outFitExtraBold800(
                color: const Color(0xFF222222),
                fontSize: 34,
              ),
            ),
            const Spacer(),
            SizedBox(
              height: 108,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final sidePad = (constraints.maxWidth - _tickWidth) / 2;
                  return Stack(
                    children: [
                      NotificationListener<ScrollNotification>(
                        onNotification: (n) {
                          if (n is ScrollUpdateNotification) {
                            _syncFromScroll(snap: false);
                          } else if (n is ScrollEndNotification) {
                            _syncFromScroll(snap: true);
                          }
                          return false;
                        },
                        child: ScrollConfiguration(
                          behavior: const MaterialScrollBehavior().copyWith(
                            dragDevices: {
                              PointerDeviceKind.touch,
                              PointerDeviceKind.mouse,
                              PointerDeviceKind.trackpad,
                            },
                          ),
                          child: ListView.builder(
                            controller: _scroll,
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            padding: EdgeInsets.symmetric(horizontal: sidePad),
                            itemCount: ticks.length,
                            itemExtent: _tickWidth,
                            itemBuilder: (context, index) {
                              final v = ticks[index];
                              final selected = v == _value;
                              final major = v % _majorEvery == 0;
                              final h = selected
                                  ? (major ? 36.0 : 30.0)
                                  : (major ? 26.0 : 14.0);
                              return Column(
                                children: [
                                  Expanded(
                                    child: Align(
                                      alignment: Alignment.bottomCenter,
                                      child: Container(
                                        width: selected ? 2 : 1.2,
                                        height: h,
                                        decoration: BoxDecoration(
                                          color: selected
                                              ? ColorRes.mlPurple
                                              : const Color(0xFF2A2A2A),
                                          borderRadius:
                                              BorderRadius.circular(1),
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    height: 22,
                                    child: major
                                        ? OverflowBox(
                                            maxWidth: 64,
                                            child: Text(
                                              '$v/min',
                                              textAlign: TextAlign.center,
                                              style: TextStyleCustom
                                                  .outFitRegular400(
                                                color: selected
                                                    ? ColorRes.mlPurple
                                                    : const Color(0xFF666666),
                                                fontSize: 10,
                                              ),
                                            ),
                                          )
                                        : null,
                                  ),
                                  const SizedBox(height: 14),
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                      const Positioned(
                        left: 0,
                        right: 0,
                        bottom: 2,
                        child: IgnorePointer(
                          child: Center(
                            child: CustomPaint(
                              size: Size(14, 9),
                              painter: _RulerCaretPainter(
                                color: ColorRes.mlPurple,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RulerCaretPainter extends CustomPainter {
  const _RulerCaretPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, size.height)
      ..lineTo(size.width / 2, 0)
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _RulerCaretPainter oldDelegate) =>
      oldDelegate.color != color;
}
