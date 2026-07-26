import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:proste_indexed_stack/proste_indexed_stack.dart';
import 'package:krimson/common/manager/app_role.dart';
import 'package:krimson/common/manager/session_manager.dart';
import 'package:krimson/common/widget/banner_ads_custom.dart';
import 'package:krimson/common/widget/gradient_border.dart';
import 'package:krimson/common/widget/gradient_icon.dart';
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
import 'package:krimson/utilities/app_platform.dart';
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

  Widget _buildBottomNavigationBar(
      BuildContext context, DashboardScreenController controller) {
    return Obx(() {
      PostUploadingProgress postUpload = controller.postProgress.value;
      bool isPostUploading =
          postUpload.uploadType == UploadType.none ? false : true;
      return AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        decoration: const BoxDecoration(
          color: ColorRes.whitePure,
          border: Border(
            top: BorderSide(color: ColorRes.bgGrey, width: 1),
          ),
        ),
        padding: const EdgeInsets.only(top: 5),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Streamer: Home (LIVE|REELS|POST) + Trabajo (con tareas).
                if (AppRole.isStreamer(
                    SessionManager.instance.getUser() ?? controller.user)) ...[
                  if (AppRole.canAccessHomeFeed(
                      SessionManager.instance.getUser() ?? controller.user))
                    _buildHomeFeedNavItem(context, controller, isPostUploading),
                  _buildWorkNavItem(context, isPostUploading),
                ],
                ...() {
                  final roleUser =
                      SessionManager.instance.getUser() ?? controller.user;
                  final indices = <int>[];
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
                    indices.add(i);
                  }
                  return [
                    for (final index in indices)
                      _buildBottomNavItem(
                          context, controller, index, isPostUploading),
                  ];
                }(),
              ],
            ),
            SafeArea(
              top: false,
              bottom: isPostUploading ? true : false,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 100),
                height: isPostUploading ? 30 : 0,
                margin: AppPlatform.isAndroid || !isPostUploading
                    ? EdgeInsets.zero
                    : const EdgeInsets.only(bottom: 20, top: 5),
                color: Colors.white,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                        height: 30,
                        decoration:
                            BoxDecoration(gradient: StyleRes.themeGradient)),
                    Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: LayoutBuilder(builder: (context, constraints) {
                        double progress =
                            (constraints.maxWidth * postUpload.progress) / 100;
                        return AnimatedContainer(
                          height: 30,
                          width: constraints.maxWidth - progress,
                          duration: const Duration(milliseconds: 250),
                          decoration:
                              BoxDecoration(color: textDarkGrey(context)),
                        );
                      }),
                    ),
                    Align(
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          if (postUpload.uploadType != UploadType.error)
                            Text('${postUpload.progress.toInt()}%',
                                style: TextStyleCustom.outFitMedium500(
                                  color: whitePure(context),
                                  fontSize: 16,
                                )),
                          Text(
                              ' ${postUpload.uploadType.title(postUpload.type)}',
                              style: TextStyleCustom.outFitLight300(
                                  color: whitePure(context), fontSize: 14)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            )
          ],
        ),
      );
    });
  }

  /// Streamer: acceso a LIVE | REELS | POSTS (tab Home). Reemplaza el acceso directo a Tareas.
  Widget _buildHomeFeedNavItem(BuildContext context,
      DashboardScreenController controller, bool isPostUploading) {
    return Obx(() {
      final selected =
          controller.selectedPageIndex.value == DashboardScreenController.tabHome;
      return SafeArea(
        bottom: isPostUploading ? false : true,
        child: GradientBorder(
          onPressed: () {
            controller.setHomeTabMode(HomeTabMode.live);
            controller.onChanged(DashboardScreenController.tabHome);
          },
          strokeWidth: selected ? 2 : 0,
          radius: 30,
          gradient: selected ? StyleRes.themeGradient : null,
          child: Padding(
            padding: const EdgeInsets.all(3),
            child: GradientIcon(
              gradient: selected
                  ? const LinearGradient(
                      colors: [ColorRes.whitePure, ColorRes.whitePure],
                    )
                  : const LinearGradient(
                      colors: [ColorRes.softSalmon, ColorRes.softSalmon],
                    ),
              child: Image.asset(
                AssetRes.icReel,
                height: 38,
                width: 38,
              ),
            ),
          ),
        ),
      );
    });
  }

  /// Trabajo (stats streamer) — incluye tareas dentro de la pantalla.
  Widget _buildWorkNavItem(BuildContext context, bool isPostUploading) {
    return SafeArea(
      bottom: isPostUploading ? false : true,
      child: GradientBorder(
        onPressed: () => Get.to(() => const WorkScreen()),
        strokeWidth: 0,
        radius: 30,
        gradient: null,
          child: const Padding(
          padding: EdgeInsets.all(3),
          child: Icon(
            Icons.work_outline_rounded,
            size: 34,
            color: ColorRes.coralRed,
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavItem(BuildContext context,
      DashboardScreenController controller, int index, bool isPostUploading) {
    return Obx(() {
      final isSelected = controller.selectedPageIndex.value == index;
      final scaleValue = isSelected ? controller.scaleValue.value : 1.0;

      return SafeArea(
        bottom: isPostUploading ? false : true,
        child: GradientBorder(
          onPressed: () => controller.onChanged(index),
          strokeWidth: isSelected ? 2 : 0,
          radius: 30,
          gradient: isSelected ? StyleRes.themeGradient : null,
          child: Padding(
            padding: const EdgeInsets.all(3),
            child: AnimatedScale(
              scale: scaleValue,
              duration: const Duration(milliseconds: 300),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (index == DashboardScreenController.tabLive)
                    LiveTvIcon(
                      size: 36,
                      color: isSelected
                          ? ColorRes.whitePure
                          : ColorRes.softSalmon.withValues(alpha: 0.85),
                    )
                  else
                    GradientIcon(
                      gradient: isSelected
                          ? const LinearGradient(
                              colors: [
                                ColorRes.whitePure,
                                ColorRes.whitePure,
                              ],
                            )
                          : LinearGradient(
                              colors: [
                                ColorRes.softSalmon.withValues(alpha: 0.85),
                                ColorRes.softSalmon.withValues(alpha: 0.85),
                              ],
                            ),
                      child: Image.asset(controller.bottomIconList[index],
                          height: 38, width: 38),
                    ),
                  if (index == DashboardScreenController.tabChat)
                    _buildUnreadCount(controller, context),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }

  Widget _buildUnreadCount(
      DashboardScreenController controller, BuildContext context) {
    return Obx(() {
      final count = controller.unReadCount.value;
      return count > 0
          ? Text(count > 9 ? '9+' : '$count',
              style: TextStyleCustom.outFitRegular400(
                  color: whitePure(context), fontSize: 12))
          : const SizedBox();
    });
  }
}
