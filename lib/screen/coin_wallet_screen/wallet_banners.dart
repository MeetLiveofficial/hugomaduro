import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krimson/common/manager/session_manager.dart';
import 'package:krimson/model/general/settings_model.dart';

/// Banners del monedero: una vez por sesión, uno tras otro, antes de recargar.
class WalletBanners {
  WalletBanners._();

  static bool shownThisSession = false;

  static Future<void> present() async {
    if (shownThisSession) return;
    shownThisSession = true;
    final slides = SessionManager.instance.getSettings()?.welcomeBanners ??
        const <WelcomeBannerSlide>[];
    if (slides.isEmpty) return;
    for (final slide in slides) {
      if (Get.overlayContext == null && Get.context == null) return;
      await Get.dialog<void>(
        WalletBannerDialog(slide: slide),
        barrierDismissible: false,
        barrierColor: const Color(0xE6000000),
        useSafeArea: false,
      );
    }
  }
}

class WalletBannerDialog extends StatelessWidget {
  const WalletBannerDialog({super.key, required this.slide});

  final WelcomeBannerSlide slide;

  void _close() {
    if (Get.isDialogOpen == true) Get.back();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return Material(
      type: MaterialType.transparency,
      child: Stack(
        children: [
          Positioned.fill(child: _image(size)),
          Positioned(
            top: MediaQuery.paddingOf(context).top + 8,
            right: 12,
            child: IconButton(
              onPressed: _close,
              icon: const Icon(Icons.close, color: Colors.white),
              style: IconButton.styleFrom(
                backgroundColor: Colors.black54,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _image(Size size) {
    final child = CachedNetworkImage(
      imageUrl: slide.url,
      fit: slide.halfScreenBottom ? BoxFit.cover : BoxFit.contain,
      memCacheWidth: 1280,
      maxWidthDiskCache: 1280,
      fadeInDuration: const Duration(milliseconds: 160),
      placeholder: (_, __) => const Center(
        child: SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white70),
        ),
      ),
      errorWidget: (_, __, ___) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _close());
        return const SizedBox.shrink();
      },
    );

    if (slide.fullscreen) {
      return Padding(
        padding: EdgeInsets.symmetric(
          vertical: size.height * 0.12,
          horizontal: size.width * 0.08,
        ),
        child: child,
      );
    }
    if (slide.halfScreenBottom) {
      return Align(
        alignment: Alignment.bottomCenter,
        child: SizedBox(
          width: size.width,
          height: size.height * 0.5,
          child: child,
        ),
      );
    }
    return Center(
      child: SizedBox(
        width: size.width * 0.78,
        height: size.height * 0.42,
        child: child,
      ),
    );
  }
}
