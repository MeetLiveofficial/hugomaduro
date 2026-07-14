import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krimson/common/extensions/common_extension.dart';
import 'package:krimson/common/extensions/string_extension.dart';
import 'package:krimson/common/manager/context_menu_widget.dart';
import 'package:krimson/common/widget/custom_image.dart';
import 'package:krimson/common/widget/load_more_widget.dart';
import 'package:krimson/common/widget/loader_widget.dart';
import 'package:krimson/common/widget/no_data_widget.dart';
import 'package:krimson/common/service/api/post_service.dart';
import 'package:krimson/common/widget/reel_list.dart';
import 'package:krimson/languages/languages_keys.dart';
import 'package:krimson/model/post_story/post_model.dart';
import 'package:krimson/model/user_model/user_model.dart';
import 'package:krimson/screen/post_screen/single_post_screen.dart';
import 'package:krimson/screen/reels_screen/reels_screen.dart';
import 'package:krimson/screen/reels_screen/widget/reel_page_type.dart';
import 'package:krimson/utilities/asset_res.dart';
import 'package:krimson/utilities/text_style_custom.dart';
import 'package:krimson/utilities/theme_res.dart';

enum ProfileMediaGridMode { posts, reels }

/// Grid de publicaciones del perfil (estilo Instagram / Reels).
class ProfileMediaGrid extends StatelessWidget {
  final RxList<Post> posts;
  final RxBool isLoading;
  final Future<void> Function() onFetchMoreData;
  final String emptyTitle;
  final String emptyDescription;
  final bool showPin;
  final ProfileMediaGridMode mode;
  final ReelPageType? reelPageType;
  final List<ContextMenuElement>? menus;
  final User? user;

  const ProfileMediaGrid({
    super.key,
    required this.posts,
    required this.isLoading,
    required this.onFetchMoreData,
    required this.emptyTitle,
    required this.emptyDescription,
    this.showPin = false,
    this.mode = ProfileMediaGridMode.posts,
    this.reelPageType,
    this.menus,
    this.user,
  });

  @override
  Widget build(BuildContext context) {
    return LoadMoreWidget(
      loadMore: onFetchMoreData,
      child: Obx(() {
        if (isLoading.value && posts.isEmpty) {
          return const LoaderWidget();
        }

        return NoDataView(
          title: emptyTitle,
          description: emptyDescription,
          showShow: !isLoading.value && posts.isEmpty,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final columns = _columnCount(constraints.maxWidth);
              return ColoredBox(
                color: whitePure(context),
                child: GridView.builder(
                  itemCount: posts.length,
                  padding: const EdgeInsets.fromLTRB(6, 6, 6, 80),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    mainAxisSpacing: 6,
                    crossAxisSpacing: 6,
                    childAspectRatio: 0.78,
                  ),
                  itemBuilder: (context, index) {
                    final post = posts[index];
                    return ProfileMediaTile(
                      post: post,
                      showPin: showPin,
                      menus: menus,
                      onTap: () => _onTap(post, index),
                    );
                  },
                ),
              );
            },
          ),
        );
      }),
    );
  }

  int _columnCount(double width) {
    if (width >= 1100) return 6;
    if (width >= 850) return 5;
    if (width >= 600) return 4;
    return 3;
  }

  void _onTap(Post post, int index) {
    if (mode == ProfileMediaGridMode.reels) {
      Get.to(
        () => ReelsScreen(
          reels: posts,
          position: index,
          onFetchMoreData: onFetchMoreData,
          pageType: reelPageType ?? ReelPageType.user,
          user: user,
        ),
        preventDuplicates: false,
      );
      return;
    }

    switch (post.postType) {
      case PostType.reel:
      case PostType.video:
        Get.to(
          () => ReelsScreen(
            reels: [post].obs,
            position: 0,
            pageType: ReelPageType.single,
          ),
          preventDuplicates: false,
        );
        break;
      case PostType.image:
      case PostType.text:
        Get.to(
          () => SinglePostScreen(
            post: post,
            isFromNotification: false,
          ),
          preventDuplicates: false,
        );
        break;
      case PostType.none:
        break;
    }
  }
}

class ProfileMediaTile extends StatelessWidget {
  final Post post;
  final VoidCallback onTap;
  final bool showPin;
  final List<ContextMenuElement>? menus;

  const ProfileMediaTile({
    super.key,
    required this.post,
    required this.onTap,
    this.showPin = false,
    this.menus,
  });

  bool get _isCarousel => (post.images?.length ?? 0) > 1;

  bool get _isVideo =>
      post.postType == PostType.video || post.postType == PostType.reel;

  String? get _imageUrl {
    if (post.postType == PostType.image &&
        (post.images?.isNotEmpty ?? false)) {
      return post.images!.first.image?.addBaseURL();
    }
    final thumb = (post.thumbnail?.isNotEmpty ?? false)
        ? post.thumbnail!
        : post.getThumbnail;
    if (thumb.isEmpty) return null;
    return thumb.addBaseURL();
  }

  @override
  Widget build(BuildContext context) {
    final tile = InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(
              color: bgGrey(context),
              child: CustomImage(
                size: const Size(double.infinity, double.infinity),
                strokeWidth: 0,
                image: _imageUrl,
                radius: 0,
                fit: BoxFit.cover,
                isShowPlaceHolder: true,
              ),
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.center,
                  colors: [
                    Color(0x99000000),
                    Color(0x00000000),
                  ],
                ),
              ),
            ),
            if (showPin && post.isPinned == 1)
              Positioned(
                top: 6,
                left: 6,
                child: Image.asset(
                  AssetRes.icPinned,
                  width: 16,
                  height: 16,
                ),
              ),
            if (_isCarousel)
              const Positioned(
                top: 6,
                right: 6,
                child: Icon(
                  Icons.filter_none_rounded,
                  color: Colors.white,
                  size: 16,
                ),
              )
            else if (_isVideo)
              const Positioned(
                top: 6,
                right: 6,
                child: Icon(
                  Icons.play_circle_fill_rounded,
                  color: Colors.white70,
                  size: 18,
                ),
              ),
            Positioned(
              left: 6,
              bottom: 6,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    AssetRes.icPlay1,
                    height: 14,
                    width: 14,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    (post.views?.toInt() ?? 0).numberFormat,
                    style: TextStyleCustom.outFitMedium500(
                      fontSize: 12,
                      color: whitePure(context),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    if (menus == null || menus!.isEmpty) return tile;

    return ContextMenuWidget(
      menuProvider: (_) {
        return Menu(
          children: menus!.map((element) {
            return MenuAction(
              title: element.title.isEmpty
                  ? (post.isPinned == 1 ? LKey.unpin.tr : LKey.pin.tr)
                  : element.title,
              callback: () => element.onTap?.call(post),
            );
          }).toList(),
        );
      },
      child: tile,
    );
  }
}
