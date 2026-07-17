import 'package:get/get.dart';
import 'package:krimson/common/controller/base_controller.dart';
import 'package:krimson/common/manager/logger.dart';
import 'package:krimson/common/service/api/post_service.dart';
import 'package:krimson/model/post_story/post/explore_page_model.dart';
import 'package:krimson/model/post_story/post_model.dart';
import 'package:krimson/screen/hashtag_screen/hashtag_screen.dart';
import 'package:krimson/screen/post_screen/single_post_screen.dart';
import 'package:krimson/screen/reels_screen/reels_screen.dart';
import 'package:krimson/screen/reels_screen/widget/reel_page_type.dart';

class ExploreScreenController extends BaseController {
  Rx<ExplorePageData?> explorePageData = Rx(null);

  @override
  void onInit() {
    super.onInit();
    fetchExplorePageData();
  }

  Future<void> fetchExplorePageData() async {
    isLoading.value = true;
    explorePageData.value = await PostService.instance.fetchExplorePageData();
    isLoading.value = false;
  }

  void onExploreTap(String? hashtag) {
    Get.to(() => HashtagScreen(hashtag: hashtag ?? '', index: 0),
        preventDuplicates: false);
  }

  void onPostTap(Post post) {
    switch (post.postType) {
      case PostType.reel:
      case PostType.video:
        Get.to(() => ReelsScreen(reels: [post].obs, position: 0, pageType: ReelPageType.search));
        break;
      case PostType.image:
        Get.to(() => SinglePostScreen(post: post, isFromNotification: false));
        break;
      case PostType.text:
        break;
      case PostType.none:
        Loggers.error('Post Type none');
        break;
    }
  }
}
