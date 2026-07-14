import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krimson/common/extensions/common_extension.dart';
import 'package:krimson/common/extensions/string_extension.dart';
import 'package:krimson/common/manager/content_protection.dart';
import 'package:krimson/common/manager/session_manager.dart';
import 'package:krimson/common/manager/share_manager.dart';
import 'package:krimson/common/widget/custom_image.dart';
import 'package:krimson/common/widget/full_name_with_blue_tick.dart';
import 'package:krimson/common/widget/loader_widget.dart';
import 'package:krimson/common/widget/text_button_custom.dart';
import 'package:krimson/languages/languages_keys.dart';
import 'package:krimson/model/user_model/user_model.dart';
import 'package:krimson/screen/profile_screen/profile_screen_controller.dart';
import 'package:krimson/screen/profile_screen/widget/follow_list_controller.dart';
import 'package:krimson/screen/profile_screen/widget/user_link_sheet.dart';
import 'package:krimson/screen/settings_screen/settings_screen.dart';
import 'package:krimson/utilities/asset_res.dart';
import 'package:krimson/utilities/color_res.dart';
import 'package:krimson/utilities/style_res.dart';
import 'package:krimson/utilities/text_style_custom.dart';
import 'package:krimson/utilities/theme_res.dart';

class ProfileUserHeader extends StatelessWidget {
  final ProfileScreenController controller;

  const ProfileUserHeader({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value && controller.userData.value == null) {
        return const SizedBox(height: 200, child: LoaderWidget());
      }

      if (controller.isUserNotFound.value) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
          child: Center(
            child: Text(
              LKey.userNotFound.tr,
              style: TextStyleCustom.unboundedMedium500(
                color: textLightGrey(context),
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        );
      }

      final user = controller.userData.value;
      if (user == null) {
        return const SizedBox(height: 100);
      }

      final isMe = user.id == SessionManager.instance.getUserID();
      final stories = user.stories ?? [];
      final hasStories = stories.isNotEmpty;
      final links = user.links ?? [];

      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _Avatar(
                  user: user,
                  hasStories: hasStories,
                  onTap: () => controller.onStoryTap(hasStories),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _StatColumn(
                        value: controller.posts.length,
                        label: LKey.posts.tr,
                      ),
                      _StatColumn(
                        value: (user.followerCount ?? 0).toInt(),
                        label: LKey.followers.tr,
                        onTap: () => controller.openFollowList(
                          FollowListType.followers,
                        ),
                      ),
                      _StatColumn(
                        value: (user.followingCount ?? 0).toInt(),
                        label: LKey.following.tr,
                        onTap: () => controller.openFollowList(
                          FollowListType.following,
                        ),
                      ),
                      _StatColumn(
                        value: user.totalPostLikesCount ?? 0,
                        label: LKey.likes.tr,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            FullNameWithBlueTick(
              username: user.fullname ?? user.username,
              isVerify: user.isVerify,
              fontSize: 16,
            ),
            if ((user.username ?? '').isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  '@${user.username}',
                  style: TextStyleCustom.outFitRegular400(
                    color: textLightGrey(context),
                    fontSize: 14,
                  ),
                ),
              ),
            if ((user.bio ?? '').trim().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  user.bio!,
                  style: TextStyleCustom.outFitRegular400(
                    color: textDarkGrey(context),
                    fontSize: 14,
                  ),
                ),
              ),
            if (links.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: InkWell(
                  onTap: () => Get.bottomSheet(
                    UserLinkSheet(links: links),
                    isScrollControlled: true,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(
                        AssetRes.icLink,
                        height: 16,
                        width: 16,
                        color: themeAccentSolid(context),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          links.first.title ?? links.first.url ?? '',
                          style: TextStyleCustom.outFitMedium500(
                            color: themeAccentSolid(context),
                            fontSize: 13,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (links.length > 1)
                        Text(
                          ' +${links.length - 1}',
                          style: TextStyleCustom.outFitMedium500(
                            color: themeAccentSolid(context),
                            fontSize: 13,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 14),
            _ActionButtons(controller: controller, isMe: isMe, user: user),
          ],
        ),
      );
    });
  }
}

class _Avatar extends StatelessWidget {
  final User user;
  final bool hasStories;
  final VoidCallback onTap;

  const _Avatar({
    required this.user,
    required this.hasStories,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(50),
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: hasStories ? StyleRes.themeGradient : null,
          border: hasStories
              ? null
              : Border.all(color: bgGrey(context), width: 1.5),
        ),
        child: CustomImage(
          size: const Size(82, 82),
          image: user.profilePhoto?.addBaseURL(),
          fullName: user.fullname,
          strokeWidth: hasStories ? 2 : 0,
          strokeColor: scaffoldBackgroundColor(context),
        ),
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  final num value;
  final String label;
  final VoidCallback? onTap;

  const _StatColumn({
    required this.value,
    required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final content = Column(
      children: [
        Text(
          value.numberFormat,
          style: TextStyleCustom.unboundedSemiBold600(
            color: textDarkGrey(context),
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyleCustom.outFitRegular400(
            color: textLightGrey(context),
            fontSize: 12,
          ),
        ),
      ],
    );

    if (onTap == null) return content;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: content,
      ),
    );
  }
}

class _ActionButtons extends StatelessWidget {
  final ProfileScreenController controller;
  final bool isMe;
  final User user;

  const _ActionButtons({
    required this.controller,
    required this.isMe,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    if (isMe) {
      return Row(
        children: [
          Expanded(
            child: TextButtonCustom(
              onTap: () => controller.handlePublishOrMessageBtn(true),
              title: LKey.publish.tr,
              backgroundColor: themeAccentSolid(context),
              titleColor: whitePure(context),
              btnHeight: 42,
              fontSize: 15,
              horizontalMargin: 0,
              margin: EdgeInsets.zero,
            ),
          ),
          if (ContentProtection.canShare) ...[
            const SizedBox(width: 8),
            _IconAction(
              icon: AssetRes.icShare2,
              onTap: () => ShareManager.shared.showCustomShareSheet(
                user: user,
                keys: ShareKeys.user,
              ),
            ),
          ],
          const SizedBox(width: 8),
          _IconAction(
            icon: AssetRes.icEdit,
            onTap: () => Get.to(
              () => SettingsScreen(onUpdateUser: controller.onUpdateUser),
            ),
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: Obx(() {
            final following = controller.userData.value?.isFollowing == true;
            return TextButtonCustom(
              onTap: controller.followUnFollowUser,
              title: following ? LKey.unFollow.tr : LKey.follow.tr,
              backgroundColor: following
                  ? bgGrey(context)
                  : ColorRes.blueFollow,
              titleColor: following
                  ? textDarkGrey(context)
                  : whitePure(context),
              btnHeight: 42,
              fontSize: 15,
              horizontalMargin: 0,
              margin: EdgeInsets.zero,
            );
          }),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: TextButtonCustom(
            onTap: () => controller.handlePublishOrMessageBtn(false),
            title: LKey.message.tr,
            backgroundColor: bgGrey(context),
            titleColor: textDarkGrey(context),
            btnHeight: 42,
            fontSize: 15,
            horizontalMargin: 0,
            margin: EdgeInsets.zero,
          ),
        ),
        if (ContentProtection.canShare) ...[
          const SizedBox(width: 8),
          _IconAction(
            icon: AssetRes.icShare2,
            onTap: () => ShareManager.shared.showCustomShareSheet(
              user: user,
              keys: ShareKeys.user,
            ),
          ),
        ],
        const SizedBox(width: 8),
        _IconAction(
          icon: AssetRes.icMore,
          onTap: () => _showMoreOptions(context),
        ),
      ],
    );
  }

  void _showMoreOptions(BuildContext context) {
    final isBlocked = user.isBlock == true;
    Get.bottomSheet(
      SafeArea(
        child: Container(
          decoration: BoxDecoration(
            color: whitePure(context),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Image.asset(AssetRes.icReport, height: 22, width: 22),
                title: Text(LKey.report.tr),
                onTap: () {
                  Get.back();
                  controller.reportUser(user);
                },
              ),
              ListTile(
                leading: Image.asset(AssetRes.icBlock, height: 22, width: 22),
                title: Text(isBlocked ? LKey.unBlock.tr : LKey.block.tr),
                onTap: () {
                  Get.back();
                  controller.toggleBlockUnblock(isBlocked);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _IconAction extends StatelessWidget {
  final String icon;
  final VoidCallback onTap;

  const _IconAction({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: 42,
        width: 42,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: bgGrey(context),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Image.asset(
          icon,
          height: 20,
          width: 20,
          color: textDarkGrey(context),
        ),
      ),
    );
  }
}
