import 'package:flutter/material.dart';

class JumpAnimationOptions {
  const JumpAnimationOptions();
}

class BadgeOptions {
  final bool active;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const BadgeOptions({
    this.active = false,
    this.backgroundColor,
    this.foregroundColor,
  });
}

class CartIconKey extends State<AddToCartIcon> {
  Future<void> runClearCartAnimation() async {}

  @override
  Widget build(BuildContext context) => widget.icon;
}

class AddToCartIcon extends StatefulWidget {
  final GlobalKey<CartIconKey> cartKey;
  final Widget icon;
  final BadgeOptions badgeOptions;

  const AddToCartIcon({
    super.key,
    required this.cartKey,
    required this.icon,
    this.badgeOptions = const BadgeOptions(),
  });

  @override
  State<AddToCartIcon> createState() => CartIconKey();
}

class AddToCartAnimation extends StatelessWidget {
  final GlobalKey<CartIconKey> cartKey;
  final JumpAnimationOptions jumpAnimation;
  final void Function(Future<void> Function(GlobalKey) runAnimation)
      createAddToCartAnimation;
  final Widget child;

  const AddToCartAnimation({
    super.key,
    required this.cartKey,
    required this.jumpAnimation,
    required this.createAddToCartAnimation,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    createAddToCartAnimation((_) async {});
    return child;
  }
}
