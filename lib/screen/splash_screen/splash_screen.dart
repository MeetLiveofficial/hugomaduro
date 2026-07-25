import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krimson/common/widget/theme_blur_bg.dart';
import 'package:krimson/screen/splash_screen/splash_screen_controller.dart';
import 'package:krimson/utilities/color_res.dart';
import 'package:krimson/utilities/text_style_custom.dart';
import 'package:krimson/utilities/theme_res.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  static const String _brandName = 'Meet&Live';

  late final AnimationController _enter;
  late final AnimationController _pulse;
  late final Animation<double> _fade;
  late final Animation<double> _scale;
  late final Animation<double> _titleSlide;
  late final Animation<double> _ring;

  @override
  void initState() {
    super.initState();
    Get.put(SplashScreenController());

    _enter = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);

    _fade = CurvedAnimation(parent: _enter, curve: Curves.easeOutCubic);
    _scale = Tween<double>(begin: 0.72, end: 1).animate(
      CurvedAnimation(
        parent: _enter,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOutBack),
      ),
    );
    _titleSlide = Tween<double>(begin: 18, end: 0).animate(
      CurvedAnimation(
        parent: _enter,
        curve: const Interval(0.35, 1.0, curve: Curves.easeOutCubic),
      ),
    );
    _ring = Tween<double>(begin: 0.88, end: 1.08).animate(
      CurvedAnimation(parent: _pulse, curve: Curves.easeInOut),
    );

    _enter.forward();
  }

  @override
  void dispose() {
    _enter.dispose();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const ThemeBlurBg(intense: true),
          // Soft moving highlight
          AnimatedBuilder(
            animation: _pulse,
            builder: (context, _) {
              return Align(
                alignment: Alignment(0, -0.15 + (_pulse.value - 0.5) * 0.08),
                child: Container(
                  width: 280,
                  height: 280,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        ColorRes.brandMagenta.withValues(alpha: 0.22),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          Align(
            alignment: Alignment.center,
            child: FadeTransition(
              opacity: _fade,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ScaleTransition(
                    scale: _scale,
                    child: AnimatedBuilder(
                      animation: _ring,
                      builder: (context, child) {
                        return Stack(
                          alignment: Alignment.center,
                          children: [
                            Transform.scale(
                              scale: _ring.value,
                              child: Container(
                                width: 168,
                                height: 168,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: ColorRes.brandMagenta
                                        .withValues(alpha: 0.28),
                                    width: 1.5,
                                  ),
                                ),
                              ),
                            ),
                            Transform.scale(
                              scale: _ring.value * 0.92,
                              child: Container(
                                width: 148,
                                height: 148,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: ColorRes.brandCoral
                                        .withValues(alpha: 0.18),
                                    width: 1,
                                  ),
                                ),
                              ),
                            ),
                            Container(
                              width: 132,
                              height: 132,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(36),
                                boxShadow: [
                                  BoxShadow(
                                    color: ColorRes.brandMagenta
                                        .withValues(alpha: 0.45),
                                    blurRadius: 36,
                                    spreadRadius: 2,
                                  ),
                                  BoxShadow(
                                    color: ColorRes.brandCoral
                                        .withValues(alpha: 0.25),
                                    blurRadius: 20,
                                  ),
                                ],
                              ),
                              child: child,
                            ),
                          ],
                        );
                      },
                      child: Image.asset(
                        'assets/images/meetlive-logo-icon.png',
                        width: 128,
                        height: 128,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  AnimatedBuilder(
                    animation: _titleSlide,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(0, _titleSlide.value),
                        child: Opacity(
                          opacity: _fade.value.clamp(0.0, 1.0),
                          child: child,
                        ),
                      );
                    },
                    child: Column(
                      children: [
                        Text(
                          _brandName,
                          style: TextStyleCustom.unboundedBlack900(
                            color: whitePure(context),
                            fontSize: 30,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Live · Connect · Grow',
                          style: TextStyleCustom.outFitMedium500(
                            color: ColorRes.brandSoft.withValues(alpha: 0.85),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
