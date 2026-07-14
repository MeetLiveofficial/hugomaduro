import 'package:get/get.dart';
import 'package:krimson/common/controller/base_controller.dart';
import 'package:krimson/common/manager/firebase_notification_manager.dart';
import 'package:krimson/common/manager/logger.dart';
import 'package:krimson/common/manager/session_manager.dart';
import 'package:krimson/common/service/api/user_service.dart';
import 'package:krimson/common/service/navigation/navigate_with_controller.dart';
import 'package:krimson/languages/languages_keys.dart';
import 'package:krimson/model/user_model/user_model.dart';

enum FollowListType { followers, following }

class FollowListController extends BaseController {
  final int userId;
  final num? showMyFollowing;
  final FollowListType initialType;
  final void Function(int deltaFollowing)? onMyFollowingCountChanged;

  FollowListController({
    required this.userId,
    required this.initialType,
    this.showMyFollowing,
    this.onMyFollowingCountChanged,
  });

  late final Rx<FollowListType> selectedType;
  final RxList<User> users = <User>[].obs;
  final RxBool isListLoading = false.obs;
  final RxBool isFollowingHidden = false.obs;
  final RxList<int> processingIds = <int>[].obs;

  int _lastFollowerItemId = -1;
  int _lastFollowingItemId = -1;

  bool get isMe => userId == SessionManager.instance.getUserID();

  @override
  void onInit() {
    super.onInit();
    selectedType = initialType.obs;
    fetchList(reset: true);
  }

  void changeTab(FollowListType type) {
    if (selectedType.value == type) return;
    selectedType.value = type;
    fetchList(reset: true);
  }

  Future<void> fetchList({bool reset = false}) async {
    if (isListLoading.value) return;

    if (selectedType.value == FollowListType.following &&
        !isMe &&
        (showMyFollowing ?? 1) == 0) {
      isFollowingHidden.value = true;
      users.clear();
      isListLoading.value = false;
      return;
    }

    isFollowingHidden.value = false;
    isListLoading.value = true;

    try {
      if (selectedType.value == FollowListType.followers) {
        final items = await UserService.instance.fetchMyFollowers(
          lastItemId: reset ? -1 : _lastFollowerItemId,
          userId: userId,
        );
        if (reset) {
          users.clear();
          _lastFollowerItemId = -1;
        }
        for (final item in items) {
          final user = item.fromUser;
          if (user != null) users.add(user);
        }
        if (items.isNotEmpty) {
          _lastFollowerItemId = items.last.id ?? -1;
        }
      } else {
        final items = await UserService.instance.fetchMyFollowing(
          lastItemId: reset ? -1 : _lastFollowingItemId,
          userId: userId,
        );
        if (reset) {
          users.clear();
          _lastFollowingItemId = -1;
        }
        for (final item in items) {
          final user = item.toUser;
          if (user == null) continue;
          if (isMe) {
            user.isFollowing = true;
          }
          users.add(user);
        }
        if (items.isNotEmpty) {
          _lastFollowingItemId = items.last.id ?? -1;
        }
      }
    } catch (e) {
      Loggers.error('FollowList fetch error: $e');
      showSnackBar(LKey.somethingWentWrong.tr);
    } finally {
      isListLoading.value = false;
    }
  }

  Future<void> loadMore() => fetchList(reset: false);

  Future<void> toggleFollow(User user) async {
    final targetId = user.id;
    if (targetId == null || targetId == SessionManager.instance.getUserID()) {
      return;
    }
    if (processingIds.contains(targetId)) return;

    processingIds.add(targetId);

    final wasFollowing = user.isFollowing == true;
    try {
      final response = wasFollowing
          ? await UserService.instance.unFollowUser(userId: targetId)
          : await UserService.instance.followUser(userId: targetId);

      if (response.status == true) {
        final isNowFollowing = !wasFollowing;
        user.isFollowing = isNowFollowing;
        users.refresh();

        onMyFollowingCountChanged?.call(isNowFollowing ? 1 : -1);
        _syncSessionFollowingCount(isNowFollowing ? 1 : -1);

        if (isNowFollowing) {
          FirebaseNotificationManager.instance
              .subscribeToTopic(topic: '$targetId');
          if (user.notifyFollow == 1) {
            FirebaseNotificationManager.instance.sendLocalisationNotification(
              LKey.notifyStartedFollowing,
              type: NotificationType.user,
              languageCode: user.appLanguage,
              deviceToken: user.deviceToken,
              deviceType: user.device,
              body: NotificationInfo(
                  id: SessionManager.instance.getUserID()),
            );
          }
        } else {
          FirebaseNotificationManager.instance
              .unsubscribeToTopic(topic: '$targetId');
        }
      } else {
        showSnackBar(response.message);
      }
    } catch (e) {
      Loggers.error('toggleFollow error: $e');
      showSnackBar(LKey.somethingWentWrong.tr);
    } finally {
      processingIds.remove(targetId);
    }
  }

  void _syncSessionFollowingCount(int delta) {
    final me = SessionManager.instance.getUser();
    if (me == null) return;
    final next = ((me.followingCount ?? 0) + delta).clamp(0, 1 << 30);
    me.followingCount = next;
    SessionManager.instance.setUser(me);
  }

  void onUserTap(User user) {
    Get.back();
    NavigationService.shared.openProfileScreen(user);
  }
}
