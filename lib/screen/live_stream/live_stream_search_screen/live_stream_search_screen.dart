import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krimson/common/manager/session_manager.dart';
import 'package:krimson/common/widget/brand_wash_bg.dart';
import 'package:krimson/common/widget/custom_border_round_icon.dart';
import 'package:krimson/common/widget/custom_image.dart';
import 'package:krimson/common/widget/live_tv_icon.dart';
import 'package:krimson/languages/languages_keys.dart';
import 'package:krimson/screen/dashboard_screen/dashboard_screen_controller.dart';
import 'package:krimson/screen/face_filters/widgets/face_camera_preview_stack.dart';
import 'package:krimson/screen/face_filters/widgets/face_filter_carousel.dart';
import 'package:krimson/screen/face_filters/widgets/web_camera_preview.dart';
import 'package:krimson/screen/gpupixel/gpupixel.dart';
import 'package:krimson/screen/live_stream/live_stream_search_screen/live_stream_search_screen_controller.dart';
import 'package:krimson/utilities/asset_res.dart';
import 'package:krimson/utilities/color_res.dart';
import 'package:krimson/utilities/style_res.dart';
import 'package:krimson/utilities/text_style_custom.dart';

/// Estudio LIVE: portada = imagen elegida; preview beauty = cámara (temporal).
class LiveStreamSearchScreen extends StatelessWidget {
  const LiveStreamSearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(LiveStreamSearchScreenController());
    final me = SessionManager.instance.getUser();
    final displayName = () {
      final n = (me?.fullname ?? me?.username ?? 'Host').trim();
      return n.isEmpty ? 'Host' : n;
    }();

    return Scaffold(
      backgroundColor: Colors.transparent,
      resizeToAvoidBottomInset: false,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const BrandWashBg(),
          Positioned.fill(child: _StudioBackdrop(controller: controller)),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 260,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      ColorRes.mlPurple.withValues(alpha: 0.45),
                      ColorRes.darkPurple.withValues(alpha: 0.88),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            height: 140,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      ColorRes.crimson.withValues(alpha: 0.55),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _TopBar(controller: controller),
                const Spacer(),
                _RightControls(controller: controller),
                const SizedBox(height: 8),
                if (!kIsWeb &&
                    LiveStreamSearchScreenController
                        .kPreLiveBeautyFiltersEnabled)
                  _PreLiveFiltersBar(controller: controller),
                _BottomBar(
                  controller: controller,
                  displayName: displayName,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StudioBackdrop extends StatelessWidget {
  final LiveStreamSearchScreenController controller;

  const _StudioBackdrop({required this.controller});

  @override
  Widget build(BuildContext context) {
    final me = SessionManager.instance.getUser();
    final profileUrl = (me?.profilePhoto ?? '').trim();

    return Obx(() {
      final gpuReady = !kIsWeb &&
          controller.cameraPreviewActive.value &&
          controller.gpuPixelPreviewActive.value &&
          controller.gpuPixel.hasTexture;
      final webCamReady = kIsWeb &&
          controller.cameraPreviewActive.value &&
          controller.beautyPipeline.isReady &&
          (controller.beautyPipeline.camera.webViewType ?? '').isNotEmpty;

      if (gpuReady) {
        return Stack(
          fit: StackFit.expand,
          children: [
            GpuPixelPreview(controller: controller.gpuPixel),
            Positioned(
              left: 16,
              bottom: 200,
              child: _CoverBadge(controller: controller),
            ),
          ],
        );
      }

      if (webCamReady) {
        return Stack(
          fit: StackFit.expand,
          children: [
            WebCameraPreview(
              viewType: controller.beautyPipeline.camera.webViewType!,
            ),
            if (LiveStreamSearchScreenController.kPreLiveBeautyFiltersEnabled)
              Positioned(
                left: 12,
                right: 12,
                top: 100,
                child: Material(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(8),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    child: Text(
                      'Web: preview de cámara + belleza por shader. '
                      'GPUPixel nativo = Android/iOS.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ),
                ),
              ),
            Positioned(
              left: 16,
              bottom: 200,
              child: _CoverBadge(controller: controller),
            ),
          ],
        );
      }

      final nativeFallbackReady = !kIsWeb &&
          controller.cameraPreviewActive.value &&
          !controller.gpuPixelPreviewActive.value &&
          controller.beautyPipeline.isReady;

      if (nativeFallbackReady) {
        return Stack(
          fit: StackFit.expand,
          children: [
            FaceCameraPreviewStack(
              boundaryKey: controller.beautyPreviewKey,
              controller: controller.beautyPipeline.camera.controller,
              isReady: controller.beautyPipeline.isReady,
              nativeAspectRatio:
                  controller.beautyPipeline.camera.nativeAspectRatio,
              frameListenable: controller.beautyPipeline.frameListenable,
              effectId: controller.selectedFilterId.value,
              beauty: controller.beautyPipeline.beauty,
            ),
            Positioned(
              left: 16,
              bottom: 200,
              child: _CoverBadge(controller: controller),
            ),
          ],
        );
      }

      final bytes = controller.coverImageBytes.value;
      Widget bg;
      if (bytes != null && bytes.isNotEmpty) {
        bg = Image.memory(bytes,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity);
      } else if (profileUrl.isNotEmpty) {
        bg = CustomImage(
          size: MediaQuery.sizeOf(context),
          image: profileUrl,
          fullName: me?.fullname ?? me?.username,
          radius: 0,
          fit: BoxFit.cover,
          strokeWidth: 0,
        );
      } else {
        bg = const BrandWashBg();
      }

      final loading = controller.cameraPreviewLoading.value;

      return Stack(
        fit: StackFit.expand,
        children: [
          bg,
          ColoredBox(color: ColorRes.crimson.withValues(alpha: 0.28)),
          Center(
            child: loading
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        width: 44,
                        height: 44,
                        child: CircularProgressIndicator(
                          color: Colors.white70,
                          strokeWidth: 2.5,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Abriendo cámara…',
                        style: TextStyleCustom.outFitMedium500(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  )
                : GestureDetector(
                    onTap: controller.startBeautyCameraPreview,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: StyleRes.themeGradient,
                            border: Border.all(color: Colors.white70),
                          ),
                          child: const Icon(Icons.videocam_rounded,
                              color: Colors.white70, size: 36),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          LKey.goLive.tr,
                          style: TextStyleCustom.outFitSemiBold600(
                            color: Colors.white,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 40),
                          child: Text(
                            kIsWeb
                                ? 'Toca para abrir la cámara (permiso del navegador)'
                                : 'Toca para abrir la cámara',
                            textAlign: TextAlign.center,
                            style: TextStyleCustom.outFitRegular400(
                              color: Colors.white54,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      );
    });
  }
}

/// Chip con la portada elegida (siempre la imagen, nunca el frame de cámara).
class _CoverBadge extends StatelessWidget {
  final LiveStreamSearchScreenController controller;

  const _CoverBadge({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final bytes = controller.coverImageBytes.value;
      return Material(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 44,
                  height: 44,
                  child: bytes != null && bytes.isNotEmpty
                      ? Image.memory(bytes, fit: BoxFit.cover)
                      : const ColoredBox(
                          color: Color(0xFF333333),
                          child: Icon(Icons.image_outlined,
                              color: Colors.white54, size: 22),
                        ),
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Portada',
                    style: TextStyleCustom.outFitSemiBold600(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    bytes != null ? 'Lista' : 'Sin imagen',
                    style: TextStyleCustom.outFitRegular400(
                      color: Colors.white70,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    });
  }
}

class _TopBar extends StatelessWidget {
  final LiveStreamSearchScreenController controller;

  const _TopBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: Row(
        children: [
          CustomBorderRoundIcon(
            image: AssetRes.icClose,
            onTap: () {
              if (Get.isRegistered<DashboardScreenController>()) {
                Get.find<DashboardScreenController>()
                    .onChanged(DashboardScreenController.tabHome);
              }
            },
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: ColorRes.themeAccentSolid,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.videocam, color: Colors.white, size: 14),
                const SizedBox(width: 4),
                Text(
                  'LIVE',
                  style: TextStyleCustom.outFitBold700(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          const SizedBox(width: 37),
        ],
      ),
    );
  }
}

class _RightControls extends StatelessWidget {
  final LiveStreamSearchScreenController controller;

  const _RightControls({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Padding(
        padding: const EdgeInsets.only(right: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (LiveStreamSearchScreenController.kPreLiveBeautyFiltersEnabled) ...[
              CustomBorderRoundIcon(
                widget: const Icon(Icons.face_retouching_natural,
                    color: ColorRes.roseMuted, size: 22),
                onTap: controller.openPreLiveBeauty,
              ),
              const SizedBox(height: 14),
            ],
            CustomBorderRoundIcon(
              widget: const Icon(Icons.image_outlined,
                  color: ColorRes.crimson, size: 22),
              onTap: controller.pickLiveCover,
            ),
            const SizedBox(height: 14),
            CustomBorderRoundIcon(
              widget:
                  const Icon(Icons.group_add, color: ColorRes.mlPurple, size: 22),
              onTap: controller.openPreLiveInvite,
            ),
          ],
        ),
      ),
    );
  }
}

/// Carrusel de looks GPUPixel (BeautyFace + FaceReshape).
class _PreLiveFiltersBar extends StatelessWidget {
  final LiveStreamSearchScreenController controller;

  const _PreLiveFiltersBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: FaceFilterCarousel(
          selectedId: controller.selectedFilterId.value,
          effects: GpuPixelLooks.catalog,
          onSelected: controller.onPreLiveFilterTap,
        ),
      );
    });
  }
}

class _BottomBar extends StatelessWidget {
  final LiveStreamSearchScreenController controller;
  final String displayName;

  const _BottomBar({
    required this.controller,
    required this.displayName,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              displayName,
              style: TextStyleCustom.outFitSemiBold600(
                color: Colors.white,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: controller.editPreLiveTitle,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white24),
                ),
                child: Obx(() {
                  final t = controller.previewTitle.value.trim();
                  return Text(
                    t.isEmpty ? LKey.enterLiveStreamTitle.tr : t,
                    style: TextStyleCustom.outFitRegular400(
                      color: t.isEmpty ? Colors.white54 : Colors.white,
                      fontSize: 14,
                    ),
                  );
                }),
              ),
            ),
            Obx(() {
              if (controller.invitedIds.isEmpty) {
                return const SizedBox(height: 12);
              }
              return Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 4),
                child: Text(
                  '${LKey.invited.tr}: ${controller.invitedIds.length}',
                  style: TextStyleCustom.outFitMedium500(
                    color: ColorRes.themeAccentSolid,
                    fontSize: 12,
                  ),
                ),
              );
            }),
            // Siempre visible en esta pantalla (solo streamers llegan aquí).
            // El permiso canGoLive se valida en onTapGoLive con mensaje claro.
            Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(28),
              child: InkWell(
                borderRadius: BorderRadius.circular(28),
                onTap: controller.onTapGoLive,
                child: Ink(
                  decoration: BoxDecoration(
                    gradient: StyleRes.themeGradient,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: ColorRes.crimson.withValues(alpha: 0.45),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const LiveTvIcon(size: 22, color: Colors.white),
                        const SizedBox(width: 10),
                        Text(
                          LKey.startLive.tr,
                          style: TextStyleCustom.outFitSemiBold600(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
