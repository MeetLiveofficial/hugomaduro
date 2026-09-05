import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krimson/languages/languages_keys.dart';
import 'package:krimson/utilities/asset_res.dart';
import 'package:krimson/utilities/text_style_custom.dart';
import 'package:krimson/utilities/theme_res.dart';

/// Chip de precio/min, igual en perfil streamer y en llamada (saliente/entrante).
class CallPriceMinChip extends StatelessWidget {
  final int coins;
  final double iconSize;
  final double fontSize;
  final EdgeInsetsGeometry padding;

  const CallPriceMinChip({
    super.key,
    required this.coins,
    this.iconSize = 16,
    this.fontSize = 13,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
  });

  @override
  Widget build(BuildContext context) {
    if (coins <= 0) return const SizedBox.shrink();
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(AssetRes.icCoin, height: iconSize, width: iconSize),
          const SizedBox(width: 6),
          Text(
            LKey.callCostPerMin.trParams({'coins': '$coins'}),
            style: TextStyleCustom.outFitMedium500(
              color: whitePure(context),
              fontSize: fontSize,
            ),
          ),
        ],
      ),
    );
  }
}
