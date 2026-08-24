import 'package:figma_squircle_updated/figma_squircle.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krimson/common/extensions/string_extension.dart';
import 'package:krimson/common/manager/session_manager.dart';
import 'package:krimson/common/widget/custom_divider.dart';
import 'package:krimson/common/widget/custom_image.dart';
import 'package:krimson/common/widget/full_name_with_blue_tick.dart';
import 'package:krimson/common/widget/load_more_widget.dart';
import 'package:krimson/common/widget/loader_widget.dart';
import 'package:krimson/common/widget/no_data_widget.dart';
import 'package:krimson/common/widget/text_button_custom.dart';
import 'package:krimson/languages/languages_keys.dart';
import 'package:krimson/model/user_model/user_model.dart';
import 'package:krimson/screen/profile_screen/widget/follow_list_controller.dart';
import 'package:krimson/utilities/color_res.dart';
import 'package:krimson/utilities/text_style_custom.dart';
import 'package:krimson/utilities/theme_res.dart';

class FollowListSheet extends StatelessWidget {
  final int userId;

  const FollowListSheet({
    super.key,
    required this.userId,
  });

  static Future<void> open({
    required int userId,
    required FollowListType initialType,
    num? showMyFollowing,
    void Function(int deltaFollowing)? onMyFollowingCountChanged,
  }) {
    final tag = 'follow_list_$userId';
    if (Get.isRegistered<FollowListController>(tag: tag)) {
      Get.delete<FollowListController>(tag: tag, force: true);
    }
    Get.put(
      FollowListController(
        userId: userId,
        initialType: initialType,
        showMyFollowing: showMyFollowing,
        onMyFollowingCountChanged: onMyFollowingCountChanged,
      ),
      tag: tag,
    );
    return Get.bottomSheet(
      FollowListSheet(userId: userId),
      isScrollControlled: true,
      ignoreSafeArea: false,
      backgroundColor: Colors.white,
      barrierColor: Colors.black54,
    ).whenComplete(() {
      if (Get.isRegistered<FollowListController>(tag: tag)) {
        Get.delete<FollowListController>(tag: tag, force: true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final tag = 'follow_list_$userId';
    final controller = Get.find<FollowListController>(tag: tag);
    final sheetHeight = MediaQuery.of(context).size.height * 0.72;

    return Container(
      height: sheetHeight,
      clipBehavior: Clip.antiAlias,
      decoration: ShapeDecoration(
        color: whitePure(context),
        shape: const SmoothRectangleBorder(
          borderRadius: SmoothBorderRadius.vertical(
            top: SmoothRadius(cornerRadius: 30, cornerSmoothing: 1),
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            Container(
              height: 1,
              width: Get.width / 4,
              margin: const EdgeInsets.only(top: 10, bottom: 12),
              color: bgGrey(context),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Obx(() {
                final selected = controller.selectedType.value;
                return Row(
                  children: [
                    _TabLabel(
                      title: LKey.followers.tr,
                      isSelected: selected == FollowListType.followers,
                      onTap: () =>
                          controller.changeTab(FollowListType.followers),
                    ),
                    const SizedBox(width: 24),
                    _TabLabel(
                      title: LKey.following.tr,
                      isSelected: selected == FollowListType.following,
                      onTap: () =>
                          controller.changeTab(FollowListType.following),
                    ),
                  ],
                );
              }),
            ),
            const SizedBox(height: 8),
            CustomDivider(color: bgGrey(context)),
            Expanded(
              child: Obx(() {
                if (controller.isFollowingHidden.value) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        LKey.userHidFollowings.tr,
                        textAlign: TextAlign.center,
                        style: TextStyleCustom.outFitRegular400(
                          color: textLightGrey(context),
                          fontSize: 15,
                        ),
                      ),
                    ),
                  );
                }

                if (controller.isListLoading.value &&
                    controller.users.isEmpty) {
                  return const LoaderWidget();
                }

                return LoadMoreWidget(
                  loadMore: controller.loadMore,
                  child: NoDataView(
                    showShow: !controller.isListLoading.value &&
                        controller.users.isEmpty,
                    title: LKey.userListEmptyTitle.tr,
                    description: LKey.userListEmptyDescription.tr,
                    child: ListView.builder(
                      itemCount: controller.users.length,
                      padding: const EdgeInsets.only(
                          bottom: 24, left: 12, right: 12, top: 4),
                      itemBuilder: (context, index) {
                        final user = controller.users[index];
                        return _FollowUserTile(
                          user: user,
                          controller: controller,
                        );
                      },
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

class _TabLabel extends StatelessWidget {
  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  const _TabLabel({
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Text(
            title,
            style: isSelected
                ? TextStyleCustom.outFitMedium500(
                    color: textDarkGrey(context),
                    fontSize: 16,
                  )
                : TextStyleCustom.outFitRegular400(
                    color: textLightGrey(context),
                    fontSize: 16,
                  ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 2,
            width: 28,
            color: isSelected
                ? themeAccentSolid(context)
                : Colors.transparent,
          ),
        ],
      ),
    );
  }
}

class _FollowUserTile extends StatelessWidget {
  final User user;
  final FollowListController controller;

  const _FollowUserTile({
    required this.user,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final myId = SessionManager.instance.getUserID();
    final isSelf = user.id == myId;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => controller.onUserTap(user),
                  child: Row(
                    children: [
                      CustomImage(
                        size: const Size(44, 44),
                        image: user.profilePhoto?.addBaseURL(),
                        fullName: user.fullname,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            FullNameWithBlueTick(
                              username: user.username,
                              fontSize: 13,
                              iconSize: 14,
                              isVerify: user.isVerify,
                            ),
                            Text(
                              user.fullname ?? '',
                              style: TextStyleCustom.outFitLight300(
                                color: textLightGrey(context),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (!isSelf) ...[
                const SizedBox(width: 8),
                Obx(() {
                  // Dependencias observables para refrescar el botón
                  controller.processingIds.length;
                  controller.users.length;
                  final following = user.isFollowing == true;
                  final busy =
                      controller.processingIds.contains(user.id ?? -1);
                  return Opacity(
                    opacity: busy ? 0.6 : 1,
                    child: TextButtonCustom(
                      onTap: busy
                          ? () {}
                          : () => controller.toggleFollow(user),
                      title: following
                          ? LKey.unFollow.tr
                          : LKey.follow.tr,
                      backgroundColor: following
                          ? bgGrey(context)
                          : ColorRes.blueFollow,
                      titleColor: following
                          ? textDarkGrey(context)
                          : whitePure(context),
                      btnHeight: 34,
                      btnWidth: 100,
                      fontSize: 13,
                      horizontalMargin: 0,
                      margin: EdgeInsets.zero,
                      radius: 8,
                    ),
                  );
                }),
              ],
            ],
          ),
        ),
        const CustomDivider(color: Colors.transparent),
      ],
    );
  }
}
