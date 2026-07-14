import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:proste_indexed_stack/proste_indexed_stack.dart';
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
import 'package:krimson/screen/profile_screen/profile_screen.dart';
import 'package:krimson/utilities/app_platform.dart';
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
    return Scaffold(
      backgroundColor: scaffoldBackgroundColor(context),
      resizeToAvoidBottomInset: true,
      body: Obx(() {
        final hideBanner = controller.selectedPageIndex.value ==
                DashboardScreenController.tabHome &&
            controller.homeTabMode.value == HomeTabMode.reels;
        return Column(
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
                      child: const LiveStreamSearchScreen(), preload: true),
                  IndexedStackChild(
                      child: const MessageScreen(), preload: true),
                  IndexedStackChild(
                      child: ProfileScreen(
                          isDashBoard: true,
                          user: myUser,
                          isTopBarVisible: false),
                      preload: true)
                ],
              ),
            ),
            if (!hideBanner) const BannerAdsCustom(),
          ],
        );
      }),
      bottomNavigationBar: _buildBottomNavigationBar(context, controller),
    );
  }

  Widget _buildBottomNavigationBar(
      BuildContext context, DashboardScreenController controller) {
    return Obx(() {
      PostUploadingProgress postUpload = controller.postProgress.value;
      bool isPostUploading =
          postUpload.uploadType == UploadType.none ? false : true;
      return AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        color: blackPure(context),
        padding: const EdgeInsets.only(top: 5),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(
                controller.bottomIconList.length,
                (index) {
                  return _buildBottomNavItem(
                      context, controller, index, isPostUploading);
                },
              ),
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
                          : ColorRes.textDarkGrey,
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
                          : StyleRes.textDarkGreyGradient(),
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
