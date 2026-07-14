import 'package:flutter/material.dart';

class ReelAnimationLike extends StatelessWidget {
  final GlobalKey likeKey;
  final Offset position;
  final Size size;
  final double leftRightPosition;
  final VoidCallback? onLikeCall;
  final VoidCallback? onCompleteAnimation;

  const ReelAnimationLike({
    super.key,
    required this.likeKey,
    required this.position,
    required this.size,
    this.leftRightPosition = 0,
    this.onLikeCall,
    this.onCompleteAnimation,
  });

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
