import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:proste_indexed_stack/proste_indexed_stack.dart';
import 'package:krimson/common/manager/app_role.dart';
import 'package:krimson/common/manager/session_manager.dart';
import 'package:krimson/common/widget/banner_ads_custom.dart';
import 'package:krimson/common/widget/live_tv_icon.dart';
import 'package:krimson/model/user_model/user_model.dart';
import 'package:krimson/screen/dashboard_screen/dashboard_screen_controller.dart';
import 'package:krimson/screen/explore_screen/explore_screen.dart';
import 'package:krimson/screen/home_screen/unified_home_screen.dart';
import 'package:krimson/screen/live_stream/live_stream_search_screen/live_stream_search_screen.dart';
import 'package:krimson/screen/message_screen/message_screen.dart';
import 'package:krimson/screen/profile_screen/client_profile_screen.dart';
import 'package:krimson/screen/profile_screen/profile_screen.dart';
import 'package:krimson/screen/work_screen/work_screen.dart';
import 'package:krimson/utilities/asset_res.dart';
import 'package:krimson/utilities/color_res.dart';
import 'package:krimson/utilities/style_res.dart';
import 'package:krimson/utilities/text_style_custom.dart';
import 'package:krimson/utilities/theme_res.dart';

class DashboardScreen extends StatelessWidget {
  final User? myUser;

  const DashboardScreen({super.key, this.myUser});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(DashboardScreenController());
    return Obx(() {
      final onLiveTab = controller.selectedPageIndex.value ==
          DashboardScreenController.tabLive;
      final hideBanner = controller.selectedPageIndex.value ==
              DashboardScreenController.tabHome &&
          (controller.homeTabMode.value == HomeTabMode.reels ||
              controller.homeTabMode.value == HomeTabMode.live);
      return Scaffold(
        backgroundColor: ColorRes.bgLightGrey,
        extendBody: true,
        // En Go Live el teclado no debe empujar el layout (rompe el diseño).
        resizeToAvoidBottomInset: !onLiveTab,
        body: Column(
          children: [
            Expanded(
              child: ProsteIndexedStack(
                index: controller.selectedPageIndex.value,
                children: [
                  IndexedStackChild(
                      child: UnifiedHomeScreen(myUser: myUser), preload: true),
                  IndexedStackChild(
                      child: const ExploreScreen(), preload: true),
                  IndexedStackChild(
                      child: const LiveStreamSearchScreen(), preload: false),
                  IndexedStackChild(
                      child: const MessageScreen(), preload: true),
                  IndexedStackChild(
                      child: AppRole.isClient(myUser)
                          ? ClientProfileScreen(user: myUser)
                          : ProfileScreen(
                              isDashBoard: true,
                              user: myUser,
                              isTopBarVisible: false),
                      preload: true)
                ],
              ),
            ),
            if (!hideBanner) const BannerAdsCustom(),
          ],
        ),
        bottomNavigationBar: _buildBottomNavigationBar(context, controller),
      );
    });
  }

  static const Color _navBarBg = Color(0xFF1C1C1E);
  static const Color _navActivePill = ColorRes.themeAccentSolid;

  Widget _buildBottomNavigationBar(
      BuildContext context, DashboardScreenController controller) {
    return Obx(() {
      PostUploadingProgress postUpload = controller.postProgress.value;
      bool isPostUploading =
          postUpload.uploadType == UploadType.none ? false : true;
      final roleUser = SessionManager.instance.getUser() ?? controller.user;

      final items = <Widget>[];
      if (AppRole.isStreamer(roleUser)) {
        if (AppRole.canAccessHomeFeed(roleUser)) {
          items.add(_buildHomeFeedNavItem(controller));
        }
        items.add(_buildWorkNavItem());
      }
      for (var i = 0; i < controller.bottomIconList.length; i++) {
        if (AppRole.isClient(roleUser) &&
            i == DashboardScreenController.tabLive) {
          continue;
        }
        if (AppRole.isStreamer(roleUser) &&
            (i == DashboardScreenController.tabHome ||
                i == DashboardScreenController.tabExplore)) {
          continue;
        }
        items.add(_buildBottomNavItem(controller, i));
      }

      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isPostUploading)
            Container(
              height: 28,
              margin: const EdgeInsets.fromLTRB(36, 0, 36, 8),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    height: 28,
                    decoration: BoxDecoration(
                      gradient: StyleRes.themeGradient,
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: LayoutBuilder(builder: (context, constraints) {
                      double progress =
                          (constraints.maxWidth * postUpload.progress) / 100;
                      return AnimatedContainer(
                        height: 28,
                        width: constraints.maxWidth - progress,
                        duration: const Duration(milliseconds: 250),
                        decoration: BoxDecoration(
                          color: textDarkGrey(context),
                          borderRadius: BorderRadius.circular(14),
                        ),
                      );
                    }),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (postUpload.uploadType != UploadType.error)
                        Text('${postUpload.progress.toInt()}%',
                            style: TextStyleCustom.outFitMedium500(
                              color: whitePure(context),
                              fontSize: 14,
                            )),
                      Text(
                          ' ${postUpload.uploadType.title(postUpload.type)}',
                          style: TextStyleCustom.outFitLight300(
                              color: whitePure(context), fontSize: 13)),
                    ],
                  ),
                ],
              ),
            ),
          SafeArea(
            top: false,
            minimum: const EdgeInsets.only(bottom: 10),
            child: Padding(
              // Más margen = barra menos ancha (estilo cápsula).
              padding: const EdgeInsets.fromLTRB(40, 0, 40, 8),
              child: Container(
                height: 56,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: _navBarBg,
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: items,
                ),
              ),
            ),
          ),
        ],
      );
    });
  }

  Widget _navHitTarget({
    required bool selected,
    required VoidCallback onTap,
    required Widget child,
  }) {
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            width: selected ? 48 : 40,
            height: selected ? 36 : 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? _navActivePill : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
              border: selected
                  ? Border.all(color: Colors.white.withValues(alpha: 0.35))
                  : null,
            ),
            child: child,
          ),
        ),
      ),
    );
  }

  Widget _navAssetIcon(String asset, {double size = 26}) {
    return ColorFiltered(
      colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
      child: Image.asset(asset, height: size, width: size),
    );
  }

  /// Streamer: acceso a LIVE | REELS | POSTS (tab Home).
  Widget _buildHomeFeedNavItem(DashboardScreenController controller) {
    return Obx(() {
      final selected =
          controller.selectedPageIndex.value == DashboardScreenController.tabHome;
      return _navHitTarget(
        selected: selected,
        onTap: () {
          controller.setHomeTabMode(HomeTabMode.live);
          controller.onChanged(DashboardScreenController.tabHome);
        },
        child: _navAssetIcon(AssetRes.icReel),
      );
    });
  }

  /// Trabajo (stats streamer).
  Widget _buildWorkNavItem() {
    return _navHitTarget(
      selected: false,
      onTap: () => Get.to(() => const WorkScreen()),
      child: const Icon(
        Icons.work_outline_rounded,
        size: 26,
        color: Colors.white,
      ),
    );
  }

  Widget _buildBottomNavItem(
      DashboardScreenController controller, int index) {
    return Obx(() {
      final isSelected = controller.selectedPageIndex.value == index;
      final scaleValue = isSelected ? controller.scaleValue.value : 1.0;

      return _navHitTarget(
        selected: isSelected,
        onTap: () => controller.onChanged(index),
        child: AnimatedScale(
          scale: scaleValue,
          duration: const Duration(milliseconds: 250),
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              if (index == DashboardScreenController.tabLive)
                const LiveTvIcon(size: 26, color: Colors.white)
              else
                _navAssetIcon(controller.bottomIconList[index]),
              if (index == DashboardScreenController.tabChat)
                _buildUnreadDot(controller),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildUnreadDot(DashboardScreenController controller) {
    return Obx(() {
      final count = controller.unReadCount.value;
      if (count <= 0) return const SizedBox.shrink();
      return Positioned(
        right: -2,
        bottom: -2,
        child: Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(
            color: ColorRes.likeRed,
            shape: BoxShape.circle,
            border: Border.all(color: _navBarBg, width: 1.5),
          ),
        ),
      );
    });
  }
}
