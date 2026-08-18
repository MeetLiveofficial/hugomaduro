import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krimson/common/widget/shine_sweep.dart';
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
  late final Animation<double> _tagFade;

  @override
  void initState() {
    super.initState();
    Get.put(SplashScreenController());

    _enter = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1280),
    );
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat(reverse: true);

    _fade = CurvedAnimation(parent: _enter, curve: Curves.easeOutCubic);
    _scale = Tween<double>(begin: 0.78, end: 1).animate(
      CurvedAnimation(
        parent: _enter,
        curve: const Interval(0.0, 0.62, curve: Curves.easeOutBack),
      ),
    );
    _titleSlide = Tween<double>(begin: 16, end: 0).animate(
      CurvedAnimation(
        parent: _enter,
        curve: const Interval(0.32, 0.88, curve: Curves.easeOutCubic),
      ),
    );
    _tagFade = CurvedAnimation(
      parent: _enter,
      curve: const Interval(0.52, 1.0, curve: Curves.easeOut),
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
          AnimatedBuilder(
            animation: _pulse,
            builder: (context, _) {
              final t = _pulse.value;
              return Align(
                alignment: const Alignment(0, -0.08),
                child: Container(
                  width: 300 + (t * 28),
                  height: 300 + (t * 28),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        ColorRes.crimson.withValues(alpha: 0.28 + t * 0.08),
                        ColorRes.mlPurple.withValues(alpha: 0.10),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.42, 1.0],
                    ),
                  ),
                ),
              );
            },
          ),
          Align(
            alignment: const Alignment(0, -0.04),
            child: FadeTransition(
              opacity: _fade,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ScaleTransition(
                    scale: _scale,
                    child: SizedBox(
                      width: 136,
                      height: 136,
                      child: ShineSweep.masked(
                        duration: const Duration(milliseconds: 3200),
                        child: Image.asset(
                          'assets/images/meetlive-logo-icon.png',
                          width: 136,
                          height: 136,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  AnimatedBuilder(
                    animation: Listenable.merge([_titleSlide, _tagFade]),
                    builder: (context, _) {
                      return Transform.translate(
                        offset: Offset(0, _titleSlide.value),
                        child: Opacity(
                          opacity: _fade.value.clamp(0.0, 1.0),
                          child: Column(
                            children: [
                              Text(
                                _brandName,
                                textAlign: TextAlign.center,
                                style: TextStyleCustom.unboundedBlack900(
                                  color: whitePure(context),
                                  fontSize: 32,
                                ).copyWith(
                                  letterSpacing: 0.6,
                                  height: 1.05,
                                  shadows: const [
                                    Shadow(
                                      color: Color(0x66000000),
                                      blurRadius: 18,
                                      offset: Offset(0, 4),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                              Opacity(
                                opacity: _tagFade.value,
                                child: Text(
                                  'Live  ·  Connect  ·  Grow',
                                  textAlign: TextAlign.center,
                                  style: TextStyleCustom.outFitMedium500(
                                    color: ColorRes.roseMuted
                                        .withValues(alpha: 0.92),
                                    fontSize: 13,
                                  ).copyWith(
                                    letterSpacing: 2.4,
                                    height: 1.2,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 48,
            child: FadeTransition(
              opacity: _tagFade,
              child: Center(
                child: _SplashPulseBar(pulse: _pulse),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SplashPulseBar extends StatelessWidget {
  const _SplashPulseBar({required this.pulse});

  final Animation<double> pulse;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulse,
      builder: (context, _) {
        return Container(
          width: 42 + (pulse.value * 10),
          height: 3,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(99),
            gradient: LinearGradient(
              colors: [
                ColorRes.crimsonAlt.withValues(alpha: 0.15),
                ColorRes.roseMuted.withValues(alpha: 0.85),
                ColorRes.mlPurple.withValues(alpha: 0.15),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: ColorRes.crimson.withValues(alpha: 0.35),
                blurRadius: 10,
              ),
            ],
          ),
        );
      },
    );
  }
}
