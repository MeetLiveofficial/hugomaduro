import 'package:flutter/material.dart';

class BorderRoundedButton extends StatelessWidget {
  final String image;
  final Color? color;
  final Color? bgColor;
  final double? height;
  final double? width;

  const BorderRoundedButton({
    super.key,
    required this.image,
    this.color,
    this.bgColor,
    this.height,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height ?? 24,
      width: width ?? 24,
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
      ),
      child: Image.asset(image, color: color, height: height, width: width),
    );
  }
}

class MembersSheet extends StatelessWidget {
  const MembersSheet({super.key});

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
