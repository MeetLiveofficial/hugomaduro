import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krimson/common/manager/session_manager.dart';
import 'package:krimson/common/widget/reel_list.dart';
import 'package:krimson/languages/languages_keys.dart';
import 'package:krimson/screen/profile_screen/profile_screen_controller.dart';
import 'package:krimson/screen/profile_screen/widget/profile_media_grid.dart';
import 'package:krimson/screen/reels_screen/widget/reel_page_type.dart';

class ProfilePageView extends StatelessWidget {
  final ProfileScreenController controller;

  const ProfilePageView({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final isMe =
        controller.userData.value?.id == SessionManager.instance.getUserID();

    return Expanded(
      child: PageView(
        controller: controller.pageController,
        onPageChanged: controller.onTabChanged,
        children: [
          ProfileMediaGrid(
            posts: controller.posts,
            isLoading: controller.isPostLoading,
            onFetchMoreData: () => controller.fetchPost(),
            showPin: isMe,
            mode: ProfileMediaGridMode.posts,
            emptyTitle:
                isMe ? LKey.noMyPostsTitle.tr : LKey.noUserPostsTitle.tr,
            emptyDescription: isMe
                ? LKey.noMyPostsDescription.tr
                : LKey.noUserPostsDescription.tr,
            menus: isMe
                ? [
                    ContextMenuElement(
                      title: '',
                      onTap: (post) {
                        if (post.isPinned == 1) {
                          controller.updateUnPinPost(post);
                        } else {
                          controller.updatePinPost(post);
                        }
                      },
                    ),
                  ]
                : null,
          ),
          ProfileMediaGrid(
            posts: controller.reels,
            isLoading: controller.isReelLoading,
            onFetchMoreData: () => controller.fetchReel(),
            showPin: isMe,
            mode: ProfileMediaGridMode.reels,
            reelPageType: ReelPageType.user,
            user: controller.userData.value,
            emptyTitle: LKey.noUserReelsTitle.tr,
            emptyDescription: LKey.noUserReelsDescription.tr,
            menus: isMe
                ? [
                    ContextMenuElement(
                      title: '',
                      onTap: controller.onPinUnpinReel,
                    ),
                  ]
                : null,
          ),
        ],
      ),
    );
  }
}
