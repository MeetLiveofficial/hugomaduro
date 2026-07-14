import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krimson/common/widget/loader_widget.dart';
import 'package:krimson/common/widget/search_result_tile.dart';
import 'package:krimson/common/widget/user_list.dart';
import 'package:krimson/languages/languages_keys.dart';
import 'package:krimson/model/post_story/hashtag_model.dart';
import 'package:krimson/model/user_model/user_model.dart';
import 'package:krimson/screen/comment_sheet/helper/comment_helper.dart';
import 'package:krimson/screen/create_feed_screen/create_feed_screen_controller.dart';
import 'package:krimson/utilities/app_res.dart';
import 'package:krimson/utilities/asset_res.dart';
import 'package:krimson/utilities/theme_res.dart';

class HashTagAndMentionUserView extends StatelessWidget {
  final CommentHelper helper;

  const HashTagAndMentionUserView({super.key, required this.helper});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final showMention = helper.isMentionUserView.value;
      final showHash = helper.isHashTagView.value;
      if (!showMention && !showHash) {
        return const SizedBox.shrink();
      }

      final isMention = showMention;
      final items = isMention ? helper.searchUsers : helper.hashTags;

      return Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          height: 220,
          width: double.infinity,
          color: bgLightGrey(context),
          child: helper.isLoading.value
              ? const LoaderWidget()
              : items.isEmpty
                  ? const SizedBox.shrink()
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item = items[index];
                        if (isMention) {
                          final user = item as User;
                          return UserCard(
                            onTap: () => helper.appendDetection(
                              user,
                              DetectType.atSign,
                              type: 1,
                            ),
                            fullName: user.fullname,
                            profilePhoto: user.profilePhoto,
                            userName: user.username,
                            isVerified: user.isVerify ?? 0,
                          );
                        }
                        final hashtag = item as Hashtag;
                        return SearchResultTile(
                          description:
                              '${hashtag.postCount} ${LKey.posts.tr}',
                          title: '${AppRes.hash}${hashtag.hashtag ?? ''}',
                          onTap: () => helper.appendDetection(
                            hashtag,
                            DetectType.hashTag,
                            type: 1,
                          ),
                          image: AssetRes.icHashtag,
                        );
                      },
                    ),
        ),
      );
    });
  }
}
