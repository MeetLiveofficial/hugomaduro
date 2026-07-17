import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krimson/common/controller/base_controller.dart';
import 'package:krimson/common/functions/debounce_action.dart';
import 'package:krimson/common/service/api/post_service.dart';
import 'package:krimson/common/service/api/search_service.dart';
import 'package:krimson/common/service/navigation/navigate_with_controller.dart';
import 'package:krimson/languages/languages_keys.dart';
import 'package:krimson/model/post_story/post_model.dart';
import 'package:krimson/model/user_model/user_model.dart';

class SearchScreenController extends BaseController {
  List<SearchTabs> searchTabs = SearchTabs.values;
  Rx<SearchTabs> selectedTabIndex = SearchTabs.values.first.obs;
  RxList<Post> posts = <Post>[].obs;
  RxList<Post> reels = <Post>[].obs;
  RxList<User> users = <User>[].obs;

  RxBool isFeedLoading = false.obs;
  RxBool isReelsLoading = false.obs;
  RxBool isUsersLoading = false.obs;

  TextEditingController searchKeyword = TextEditingController();

  PageController pageController = PageController(initialPage: 0);

  RxBool isTextEmpty = true.obs;

  RxInt currentIndex = 0.obs;

  @override
  void onInit() {
    super.onInit();
    onSearchTabTap(0);
  }

  void onSearchTabTap(int index) {
    selectedTabIndex.value = searchTabs[index];
    onChanged(0);
  }

  onChanged(int milliSecond) {
    if (searchKeyword.text.trim().isEmpty) {
      isTextEmpty.value = true;
    } else {
      isTextEmpty.value = false;
    }
    DebounceAction.shared.call(() {
      switch (selectedTabIndex.value) {
        case SearchTabs.posts:
          searchPosts(reset: true);
          break;
        case SearchTabs.reels:
          searchReels(reset: true);
          break;
        case SearchTabs.users:
          searchUsers(reset: true);
          break;
      }
    }, milliseconds: milliSecond);
  }

  Future<void> searchPosts({bool reset = false}) async {
    if (isFeedLoading.value) return;
    isFeedLoading.value = true;
    final items = await SearchService.instance.searchPost(
        type: PostType.posts,
        lastItemId: reset ? null : posts.lastOrNull?.id,
        keyword: searchKeyword.text);

    if (reset) {
      posts.clear();
    }
    posts.addAll(items);
    isFeedLoading.value = false;
  }

  Future<void> searchReels({bool reset = false}) async {
    if (isReelsLoading.value) return;
    isReelsLoading.value = true;
    final items = await SearchService.instance.searchPost(
        type: PostType.reels,
        lastItemId: reset ? null : reels.lastOrNull?.id,
        keyword: searchKeyword.text);

    if (reset) {
      reels.clear();
    }
    reels.addAll(items);
    isReelsLoading.value = false;
  }

  Future<void> searchUsers({bool reset = false}) async {
    isUsersLoading.value = true;
    List<User> items = await SearchService.instance.searchUsers(
        lastItemId: reset ? null : users.lastOrNull?.id,
        keyword: searchKeyword.text);
    if (reset) {
      users.clear();
    }
    if (items.isNotEmpty) {
      users.addAll(items);
    }
    isUsersLoading.value = false;
  }

  onUserTap(User user) {
    NavigationService.shared.openProfileScreen(user);
  }
}

/// Explore Search: Posts + Reels + Users.
enum SearchTabs {
  posts,
  reels,
  users;

  String get title {
    switch (this) {
      case SearchTabs.posts:
        return LKey.posts;
      case SearchTabs.reels:
        return LKey.reels;
      case SearchTabs.users:
        return LKey.users;
    }
  }
}
