import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krimson/common/manager/session_manager.dart';
import 'package:krimson/common/widget/custom_border_round_icon.dart';
import 'package:krimson/common/widget/live_tv_icon.dart';
import 'package:krimson/languages/languages_keys.dart';
import 'package:krimson/screen/dashboard_screen/dashboard_screen_controller.dart';
import 'package:krimson/screen/live_stream/live_stream_search_screen/live_stream_search_screen_controller.dart';
import 'package:krimson/utilities/asset_res.dart';
import 'package:krimson/utilities/color_res.dart';
import 'package:krimson/utilities/text_style_custom.dart';
import 'package:retrytech_plugin/retrytech_plugin.dart';

/// Estudio LIVE: preview estable (mismo patrón que CameraScreen) + Start Live.
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
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Full-bleed: LayoutBuilder necesita bounds reales (Center+preload
          // offstage dejaba size 0 → textura gris deformada).
          Positioned.fill(
            child: ColoredBox(
              color: Colors.black,
              child: _CameraPreview(controller: controller),
            ),
          ),
          const Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 240,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Color(0xE6000000)],
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

class _CameraPreview extends StatelessWidget {
  final LiveStreamSearchScreenController controller;

  const _CameraPreview({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final ready = controller.cameraReady.value;
      final starting = controller.cameraStarting.value;
      final gen = controller.cameraGeneration.value;

      if (!kIsWeb && ready) {
        // Mismo enfoque que CameraScreen: AspectRatio fijo + clip.
        // FittedBox/cover sin tamaño nativo deforma el PlatformView.
        return KeyedSubtree(
          key: ValueKey('live_cam_$gen'),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final maxH = constraints.maxHeight.isFinite
                  ? constraints.maxHeight
                  : MediaQuery.sizeOf(context).height;
              final maxW = constraints.maxWidth.isFinite
                  ? constraints.maxWidth
                  : MediaQuery.sizeOf(context).width;
              // 9:16 aprox. (0.56) — cubre sin estirar.
              const ar = 9 / 16;
              double w = maxW;
              double h = w / ar;
              if (h < maxH) {
                h = maxH;
                w = h * ar;
              }
              return ClipRect(
                child: OverflowBox(
                  minWidth: w,
                  maxWidth: w,
                  minHeight: h,
                  maxHeight: h,
                  alignment: Alignment.center,
                  child: SizedBox(
                    width: w,
                    height: h,
                    child: RetrytechPlugin.shared.cameraView,
                  ),
                ),
              );
            },
          ),
        );
      }

      return SizedBox(
        width: MediaQuery.sizeOf(context).width,
        height: MediaQuery.sizeOf(context).height * 0.7,
        child: ColoredBox(
          color: const Color(0xFF121212),
          child: Center(
            child: starting
                ? const CircularProgressIndicator(color: Colors.white54)
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        kIsWeb
                            ? Icons.smartphone_outlined
                            : Icons.videocam_outlined,
                        color: Colors.white38,
                        size: 48,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        kIsWeb
                            ? 'Cámara en la app Android'
                            : 'Activando cámara…',
                        style: TextStyleCustom.outFitMedium500(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      if (!kIsWeb) ...[
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: controller.restartPreviewCamera,
                          child: Text(
                            LKey.refresh.tr,
                            style: TextStyleCustom.outFitMedium500(
                              color: ColorRes.themeAccentSolid,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
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
              controller.stopPreviewCamera();
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
    if (kIsWeb) {
      return const SizedBox.shrink();
    }
    return Align(
      alignment: Alignment.centerRight,
      child: Padding(
        padding: const EdgeInsets.only(right: 14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomBorderRoundIcon(
              image: AssetRes.icCameraFlip,
              onTap: controller.flipPreviewCamera,
            ),
            const SizedBox(height: 14),
            CustomBorderRoundIcon(
              widget: const Icon(Icons.auto_awesome,
                  color: Colors.white, size: 22),
              onTap: controller.openPreLiveBeauty,
            ),
            const SizedBox(height: 14),
            CustomBorderRoundIcon(
              widget:
                  const Icon(Icons.group_add, color: Colors.white, size: 22),
              onTap: controller.openPreLiveInvite,
            ),
            const SizedBox(height: 14),
            CustomBorderRoundIcon(
              widget: const Icon(Icons.refresh, color: Colors.white, size: 22),
              onTap: controller.restartPreviewCamera,
            ),
          ],
        ),
      ),
    );
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
            Material(
              color: ColorRes.themeAccentSolid,
              borderRadius: BorderRadius.circular(28),
              child: InkWell(
                borderRadius: BorderRadius.circular(28),
                onTap: controller.onTapGoLive,
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
          ],
        ),
      ),
    );
  }
}
