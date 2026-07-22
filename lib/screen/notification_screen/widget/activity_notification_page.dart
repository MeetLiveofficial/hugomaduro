import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krimson/common/extensions/string_extension.dart';
import 'package:krimson/common/service/navigation/navigate_with_controller.dart';
import 'package:krimson/common/widget/custom_image.dart';
import 'package:krimson/common/widget/full_name_with_blue_tick.dart';
import 'package:krimson/common/widget/load_more_widget.dart';
import 'package:krimson/common/widget/loader_widget.dart';
import 'package:krimson/common/widget/no_data_widget.dart';
import 'package:krimson/languages/languages_keys.dart';
import 'package:krimson/model/misc/activity_notification_model.dart';
import 'package:krimson/screen/live_stream/livestream_screen/widget/live_invite_dialog.dart';
import 'package:krimson/screen/live_stream/livestream_screen/widget/live_battle_invite_dialog.dart';
import 'package:krimson/screen/post_screen/single_post_screen.dart';
import 'package:krimson/utilities/text_style_custom.dart';
import 'package:krimson/utilities/theme_res.dart';

class ActivityNotifyType {
  final String type;
  final int code;

  const ActivityNotifyType._(this.type, this.code);

  static const ActivityNotifyType none = ActivityNotifyType._('none', 0);
  static const ActivityNotifyType likePost = ActivityNotifyType._('like_post', 1);
  static const ActivityNotifyType commentPost =
      ActivityNotifyType._('comment_post', 2);
  static const ActivityNotifyType mentionPost =
      ActivityNotifyType._('mention_post', 3);
  static const ActivityNotifyType mentionComment =
      ActivityNotifyType._('mention_comment', 4);
  static const ActivityNotifyType followUser =
      ActivityNotifyType._('follow_user', 5);
  static const ActivityNotifyType giftUser = ActivityNotifyType._('gift_user', 6);
  static const ActivityNotifyType replyComment =
      ActivityNotifyType._('reply_comment', 7);
  static const ActivityNotifyType mentionReply =
      ActivityNotifyType._('mention_reply', 8);
  static const ActivityNotifyType callRequest =
      ActivityNotifyType._('call_request', 9);
  static const ActivityNotifyType liveInvite =
      ActivityNotifyType._('live_invite', 10);
  static const ActivityNotifyType battleInvite =
      ActivityNotifyType._('battle_invite', 11);

  static const List<ActivityNotifyType> values = [
    none,
    likePost,
    commentPost,
    mentionPost,
    mentionComment,
    followUser,
    giftUser,
    replyComment,
    mentionReply,
    callRequest,
    liveInvite,
    battleInvite,
  ];

  static ActivityNotifyType fromString(dynamic value) {
    if (value == null) return none;
    final asInt = int.tryParse(value.toString());
    if (asInt != null) {
      return values.firstWhere((e) => e.code == asInt, orElse: () => none);
    }
    final asStr = value.toString();
    return values.firstWhere((e) => e.type == asStr, orElse: () => none);
  }

  String get message {
    switch (code) {
      case 1:
        return LKey.activityLikedPost.tr;
      case 2:
        return LKey.activityCommentedPost.trParams({'comment_description': ''});
      case 3:
        return LKey.notifyMentionedInPost.tr;
      case 4:
        return LKey.notifyMentionedInComment.tr;
      case 5:
        return LKey.notifyStartedFollowing.tr;
      case 6:
        return LKey.activitySentGift.tr;
      case 7:
        return LKey.activityReplyingToComment
            .trParams({'username': '', 'comment_description': ''});
      case 8:
        return LKey.notifyReplyMentionedInComment
            .trParams({'comment_description': ''});
      case 9:
        return 'Video call request';
      case 10:
        return 'te invita a su LIVE';
      case 11:
        return 'te invita a una batalla';
      default:
        return '';
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ActivityNotifyType && other.code == code;

  @override
  int get hashCode => code.hashCode;
}

class ActivityNotificationPage extends StatelessWidget {
  final RxList<ActivityNotification> notifications;
  final RxBool isLoading;
  final Future<void> Function() onLoadMore;
  final Future<void> Function()? onRefresh;

  const ActivityNotificationPage({
    super.key,
    required this.notifications,
    required this.isLoading,
    required this.onLoadMore,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (isLoading.value && notifications.isEmpty) {
        return const LoaderWidget();
      }

      return RefreshIndicator(
        onRefresh: onRefresh ?? () async {},
        child: LoadMoreWidget(
          loadMore: onLoadMore,
          child: NoDataView(
            showShow: !isLoading.value && notifications.isEmpty,
            title: LKey.notifications.tr,
            description: LKey.noContentMessage.tr,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount: notifications.length,
              separatorBuilder: (_, __) => Divider(color: bgGrey(context)),
              itemBuilder: (context, index) {
                final item = notifications[index];
                final user = item.fromUser;
                return InkWell(
                  onTap: () => _onTap(item),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CustomImage(
                          size: const Size(44, 44),
                          image: user?.profilePhoto?.addBaseURL(),
                          fullName: user?.fullname,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              FullNameWithBlueTick(
                                username: user?.username ?? user?.fullname,
                                isVerify: user?.isVerify,
                                fontSize: 14,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                item.type.message,
                                style: TextStyleCustom.outFitRegular400(
                                  color: textLightGrey(context),
                                  fontSize: 13,
                                ),
                              ),
                              if ((item.createdAt ?? '').isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    item.createdAt!.formatDate,
                                    style: TextStyleCustom.outFitLight300(
                                      color: textLightGrey(context),
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      );
    });
  }

  void _onTap(ActivityNotification item) {
    if (item.type == ActivityNotifyType.followUser) {
      NavigationService.shared.openProfileScreen(item.fromUser);
      return;
    }
    if (item.type == ActivityNotifyType.liveInvite) {
      final live = item.data?.livestream;
      if (live != null) {
        LiveInviteDialog.showIfNeeded(live);
      }
      return;
    }
    if (item.type == ActivityNotifyType.battleInvite) {
      final live = item.data?.livestream;
      if (live != null) {
        LiveBattleInviteDialog.showIfNeeded(live);
      }
      return;
    }
    final post = item.data?.post;
    if (post != null) {
      Get.to(() => SinglePostScreen(post: post, isFromNotification: true));
    }
  }
}
