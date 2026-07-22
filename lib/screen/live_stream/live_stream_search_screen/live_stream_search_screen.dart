import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krimson/common/manager/session_manager.dart';
import 'package:krimson/common/widget/custom_border_round_icon.dart';
import 'package:krimson/common/widget/custom_image.dart';
import 'package:krimson/common/widget/live_tv_icon.dart';
import 'package:krimson/languages/languages_keys.dart';
import 'package:krimson/screen/dashboard_screen/dashboard_screen_controller.dart';
import 'package:krimson/screen/live_stream/live_stream_search_screen/live_stream_search_screen_controller.dart';
import 'package:krimson/utilities/asset_res.dart';
import 'package:krimson/utilities/color_res.dart';
import 'package:krimson/utilities/text_style_custom.dart';

/// Estudio LIVE sin preview nativo Retrytech (evita pantalla negra en
/// emuladores y libera la cámara para LiveKit al iniciar).
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
      resizeToAvoidBottomInset: false,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(child: _StudioBackdrop(controller: controller)),
          const Positioned(
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
                    colors: [Colors.transparent, Color(0xF2000000)],
                  ),
                ),
              ),
            ),
          ),
          const Positioned(
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
                    colors: [Color(0x99000000), Colors.transparent],
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

class _StudioBackdrop extends StatelessWidget {
  final LiveStreamSearchScreenController controller;

  const _StudioBackdrop({required this.controller});

  @override
  Widget build(BuildContext context) {
    final me = SessionManager.instance.getUser();
    final profileUrl = (me?.profilePhoto ?? '').trim();

    return Obx(() {
      final bytes = controller.coverImageBytes.value;
      Widget bg;
      if (bytes != null && bytes.isNotEmpty) {
        bg = Image.memory(bytes, fit: BoxFit.cover, width: double.infinity,
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
        bg = const ColoredBox(color: Color(0xFF1A1A1A));
      }

      return Stack(
        fit: StackFit.expand,
        children: [
          bg,
          const ColoredBox(color: Color(0x66000000)),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black.withValues(alpha: 0.45),
                    border: Border.all(color: Colors.white24),
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
                    'La cámara se activa al pulsar Start Live',
                    textAlign: TextAlign.center,
                    style: TextStyleCustom.outFitRegular400(
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
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
        padding: const EdgeInsets.only(right: 14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomBorderRoundIcon(
              widget: const Icon(Icons.image_outlined,
                  color: Colors.white, size: 22),
              onTap: controller.pickLiveCover,
            ),
            const SizedBox(height: 14),
            if (!kIsWeb) ...[
              CustomBorderRoundIcon(
                widget: const Icon(Icons.auto_awesome,
                    color: Colors.white, size: 22),
                onTap: controller.openPreLiveBeauty,
              ),
              const SizedBox(height: 14),
            ],
            CustomBorderRoundIcon(
              widget:
                  const Icon(Icons.group_add, color: Colors.white, size: 22),
              onTap: controller.openPreLiveInvite,
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
