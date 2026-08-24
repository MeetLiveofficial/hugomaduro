import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:krimson/common/extensions/common_extension.dart';
import 'package:krimson/common/extensions/string_extension.dart';
import 'package:krimson/common/manager/app_role.dart';
import 'package:krimson/common/manager/call_availability.dart';
import 'package:krimson/common/manager/content_protection.dart';
import 'package:krimson/common/manager/guest_gate.dart';
import 'package:krimson/common/manager/session_manager.dart';
import 'package:krimson/common/manager/share_manager.dart';
import 'package:krimson/common/controller/base_controller.dart';
import 'package:krimson/common/widget/custom_back_button.dart';
import 'package:krimson/common/widget/custom_image.dart';
import 'package:krimson/common/widget/framed_avatar.dart';
import 'package:krimson/common/widget/live_tv_icon.dart';
import 'package:krimson/common/widget/loader_widget.dart';
import 'package:krimson/common/widget/my_refresh_indicator.dart';
import 'package:krimson/common/service/api/post_service.dart';
import 'package:krimson/common/service/api/user_service.dart';
import 'package:krimson/languages/languages_keys.dart';
import 'package:krimson/model/post_story/post_model.dart';
import 'package:krimson/model/user_model/streamer_average.dart';
import 'package:krimson/model/user_model/user_model.dart';
import 'package:krimson/screen/edit_profile_screen/edit_profile_screen.dart';
import 'package:krimson/screen/post_screen/single_post_screen.dart';
import 'package:krimson/screen/profile_screen/profile_screen_controller.dart';
import 'package:krimson/screen/profile_screen/widget/follow_list_controller.dart';
import 'package:krimson/screen/reels_screen/reels_screen.dart';
import 'package:krimson/screen/reels_screen/widget/reel_page_type.dart';
import 'package:krimson/screen/settings_screen/settings_screen.dart';
import 'package:krimson/screen/work_screen/work_screen.dart';
import 'package:krimson/utilities/asset_res.dart';
import 'package:krimson/utilities/color_res.dart';
import 'package:krimson/utilities/language_display.dart';
import 'package:krimson/utilities/text_style_custom.dart';
import 'package:krimson/utilities/theme_res.dart';

const _callOrange = Color(0xFFFF8A3D);
const _liveGreen = Color(0xFF22C55E);
const _sheet = Color(0xFF0B0B0F);
const _chipDark = Color(0xCC1A1A1F);

/// Perfil streamer: foto a pantalla, carrusel de lo que sube, ficha oscura.
class StreamerGalleryProfile extends StatefulWidget {
  final ProfileScreenController controller;
  final bool showBack;

  const StreamerGalleryProfile({
    super.key,
    required this.controller,
    this.showBack = true,
  });

  @override
  State<StreamerGalleryProfile> createState() => _StreamerGalleryProfileState();
}

class _StreamerGalleryProfileState extends State<StreamerGalleryProfile> {
  late final PageController _pager;

  ProfileScreenController get controller => widget.controller;

  @override
  void initState() {
    super.initState();
    _pager = PageController(initialPage: controller.galleryIndex.value);
  }

  @override
  void dispose() {
    _pager.dispose();
    super.dispose();
  }

  Future<void> _goTo(int i, int total) async {
    if (total <= 0) return;
    final next = i.clamp(0, total - 1);
    controller.galleryIndex.value = next;
    if (_pager.hasClients) {
      await _pager.animateToPage(
        next,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
      );
    }
    if (next >= total - 3) {
      controller.fetchPost();
      controller.fetchReel();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: ColoredBox(
        color: _sheet,
        child: MyRefreshIndicator(
          onRefresh: controller.onRefresh,
          child: Obx(() {
            final user = controller.userData.value;
            if (user == null) {
              return const Center(
                child: CircularProgressIndicator(color: Colors.white),
              );
            }
            final slides =
                _gallerySlides(user, controller.posts, controller.reels);
            var index = controller.galleryIndex.value;
            if (slides.isNotEmpty && index >= slides.length) {
              index = 0;
              controller.galleryIndex.value = 0;
            }
            final size = MediaQuery.sizeOf(context);
            final heroH = (size.height * 0.62).clamp(340.0, size.height * 0.70);
            final isMe = user.id == SessionManager.instance.getUserID();
            const galleryH = 68.0;

            final bottomPad = widget.showBack ? 12.0 : 88.0;

            return SizedBox(
              height: size.height,
              width: size.width,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Column(
                    children: [
                      Expanded(
                        child: CustomScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          slivers: [
                            SliverToBoxAdapter(
                              child: SizedBox(
                                height: heroH,
                                width: size.width,
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    _HeroPager(
                                      user: user,
                                      slides: slides,
                                      pager: _pager,
                                      onPage: (i) {
                                        controller.galleryIndex.value = i;
                                        if (i >= slides.length - 3) {
                                          controller.fetchPost();
                                          controller.fetchReel();
                                        }
                                      },
                                    ),
                                    const IgnorePointer(
                                      child: DecoratedBox(
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                            colors: [
                                              Color(0x88000000),
                                              Colors.transparent,
                                              Colors.transparent,
                                              Color(0xCC000000),
                                            ],
                                            stops: [0, 0.16, 0.52, 1],
                                          ),
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      left: 14,
                                      right: 14,
                                      bottom: slides.isNotEmpty
                                          ? galleryH + 12
                                          : 18,
                                      child: _HeroChrome(
                                        user: user,
                                        isMe: isMe,
                                        controller: controller,
                                      ),
                                    ),
                                    if (slides.isNotEmpty)
                                      Positioned(
                                        left: 0,
                                        right: 0,
                                        bottom: 8,
                                        height: galleryH,
                                        child: _GalleryStrip(
                                          slides: slides,
                                          selected: index,
                                          onSelect: (i) =>
                                              _goTo(i, slides.length),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                            SliverToBoxAdapter(
                              child: _InfoSheet(
                                user: user,
                                controller: controller,
                                isMe: isMe,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ColoredBox(
                        color: _sheet,
                        child: SafeArea(
                          top: false,
                          bottom: bottomPad < 40,
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(16, 10, 16, bottomPad),
                            child: _BottomActions(
                              user: user,
                              controller: controller,
                              isMe: isMe,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: SafeArea(
                      bottom: false,
                      child: _TopBar(
                        showBack: widget.showBack,
                        controller: controller,
                        user: user,
                        isMe: isMe,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _HeroPager extends StatelessWidget {
  final User user;
  final List<_GallerySlide> slides;
  final PageController pager;
  final ValueChanged<int> onPage;

  const _HeroPager({
    required this.user,
    required this.slides,
    required this.pager,
    required this.onPage,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        final fallback = user.profilePhoto?.addBaseURL();
        if (slides.isEmpty) {
          return CustomImage(
            size: size,
            image: fallback,
            radius: 0,
            fit: BoxFit.cover,
            isShowPlaceHolder: true,
            fullName: user.fullname ?? user.username,
            webPreferHtmlElement: false,
          );
        }
        return PageView.builder(
          controller: pager,
          itemCount: slides.length,
          onPageChanged: onPage,
          itemBuilder: (context, i) {
            final slide = slides[i];
            return GestureDetector(
              onTap: () {
                if (slide.post != null) _openPost(slide.post!);
              },
              child: CustomImage(
                size: size,
                image: slide.url,
                radius: 0,
                fit: BoxFit.cover,
                isShowPlaceHolder: true,
                fullName: user.fullname ?? user.username,
                webPreferHtmlElement: false,
              ),
            );
          },
        );
      },
    );
  }
}

class _HeroChrome extends StatelessWidget {
  final User user;
  final bool isMe;
  final ProfileScreenController controller;

  const _HeroChrome({
    required this.user,
    required this.isMe,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: _StatusBadges(
            user: user,
            onJoinLive:
                user.isLive == 1 ? controller.openUserLiveIfAny : null,
          ),
        ),
        if (!isMe)
          _FollowButton(
            following: user.isFollowing == true,
            onTap: controller.followUnFollowUser,
          ),
      ],
    );
  }
}

class _FollowButton extends StatelessWidget {
  final bool following;
  final VoidCallback onTap;

  const _FollowButton({required this.following, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _callOrange,
      shape: const CircleBorder(),
      elevation: 4,
      shadowColor: Colors.black54,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () {
          if (GuestGate.block()) return;
          onTap();
        },
        child: SizedBox(
          width: 46,
          height: 46,
          child: Icon(
            following ? Icons.person_rounded : Icons.person_add_alt_1_rounded,
            color: Colors.white,
            size: 22,
          ),
        ),
      ),
    );
  }
}

class _InfoSheet extends StatelessWidget {
  final User user;
  final ProfileScreenController controller;
  final bool isMe;

  const _InfoSheet({
    required this.user,
    required this.controller,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: _sheet,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _IdentityBlock(user: user, controller: controller),
            const SizedBox(height: 12),
            if (AppRole.isStreamer(user)) ...[
              if (user.streamerAverage != null) ...[
                _StreamerAvgCard(
                  avg: user.streamerAverage!,
                  showBars: isMe,
                ),
                const SizedBox(height: 12),
              ],
              _ImpressionCard(
                user: user,
                controller: controller,
                isMe: isMe,
              ),
            ],
            if ((user.bio ?? '').trim().isNotEmpty) ...[
              const SizedBox(height: 14),
              Text(
                user.bio!.trim(),
                style: TextStyleCustom.outFitRegular400(
                  color: Colors.white70,
                  fontSize: 13,
                ),
              ),
            ],
            if ((user.levelTitle ?? '').trim().isNotEmpty ||
                (user.levelNumber ?? 0) > 0) ...[
              const SizedBox(height: 14),
              _LevelBar(user: user),
            ],
          ],
        ),
      ),
    );
  }
}

class _GallerySlide {
  final Post? post;
  final String url;
  final bool isVideo;

  const _GallerySlide({
    required this.url,
    this.post,
    this.isVideo = false,
  });
}

List<_GallerySlide> _gallerySlides(
  User user,
  List<Post> posts,
  List<Post> reels,
) {
  final slides = <_GallerySlide>[];
  final seen = <String>{};

  void addRaw(String? raw, {Post? post, bool isVideo = false}) {
    final value = (raw ?? '').trim();
    if (value.isEmpty) return;
    final url = value.addBaseURL();
    if (url.isEmpty || !seen.add(url)) return;
    slides.add(_GallerySlide(post: post, url: url, isVideo: isVideo));
  }

  addRaw(user.profilePhoto);
  for (final post in posts) {
    final isVideo =
        post.postType == PostType.video || post.postType == PostType.reel;
    if (post.postType == PostType.image &&
        (post.images?.isNotEmpty ?? false)) {
      for (final img in post.images!) {
        addRaw(img.image, post: post);
      }
    } else {
      addRaw(post.getThumbnail, post: post, isVideo: isVideo);
    }
  }
  for (final post in reels) {
    addRaw(post.getThumbnail, post: post, isVideo: true);
  }
  return slides;
}

void _openPost(Post post) {
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

class _TopBar extends StatelessWidget {
  final bool showBack;
  final ProfileScreenController controller;
  final User user;
  final bool isMe;

  const _TopBar({
    required this.showBack,
    required this.controller,
    required this.user,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          if (showBack)
            CustomBackButton(
              color: Colors.white,
              padding: const EdgeInsets.all(12),
              onTap: () {
                controller.adsController.showInterstitialAdIfAvailable();
                Get.back();
              },
            )
          else
            const SizedBox(width: 44, height: 44),
          const Spacer(),
          IconButton(
            onPressed: () =>
                _showMoreOptions(context, controller, user, isMe),
            icon: const Icon(Icons.more_horiz, color: Colors.white, size: 26),
          ),
        ],
      ),
    );
  }
}

class _StatusBadges extends StatelessWidget {
  final User user;
  final VoidCallback? onJoinLive;

  const _StatusBadges({required this.user, this.onJoinLive});

  @override
  Widget build(BuildContext context) {
    final chips = <Widget>[];
    if (CallAvailability.isInCall(user)) {
      chips.add(_pill(
        color: _callOrange,
        child: Text(
          LKey.inCall.tr,
          style: TextStyleCustom.outFitMedium500(
            color: Colors.white,
            fontSize: 11,
          ),
        ),
      ));
    } else if (user.isLive == 1) {
      chips.add(GestureDetector(
        onTap: onJoinLive,
        child: _pill(
          color: const Color(0xE8E24AB7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                LKey.liveBadge.tr,
                style: TextStyleCustom.outFitMedium500(
                  color: Colors.white,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ));
    } else if (CallAvailability.isOnline(user)) {
      chips.add(_pill(
        color: _chipDark,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: _liveGreen,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              LKey.onlineNow.tr,
              style: TextStyleCustom.outFitMedium500(
                color: Colors.white,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ));
    }
    final lastCall = _lastCallLabel(user);
    if (lastCall != null) {
      chips.add(_pill(
        color: _callOrange,
        child: Text(
          lastCall,
          style: TextStyleCustom.outFitMedium500(
            color: Colors.white,
            fontSize: 10,
          ),
        ),
      ));
    }
    if (user.liveViewers > 0) {
      chips.add(_pill(
        color: const Color(0x99000000),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.remove_red_eye_outlined,
                color: _callOrange, size: 13),
            const SizedBox(width: 4),
            Text(
              LKey.peopleWatching.trParams({'count': '${user.liveViewers}'}),
              style: TextStyleCustom.outFitMedium500(
                color: Colors.white,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ));
    }

    if (chips.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final chip in chips) ...[
          chip,
          const SizedBox(height: 6),
        ],
      ],
    );
  }

  Widget _pill({required Color color, required Widget child}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: child,
    );
  }
}

class _GalleryStrip extends StatelessWidget {
  final List<_GallerySlide> slides;
  final int selected;
  final ValueChanged<int> onSelect;

  const _GalleryStrip({
    required this.slides,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      scrollDirection: Axis.horizontal,
      itemCount: slides.length,
      separatorBuilder: (_, __) => const SizedBox(width: 8),
      itemBuilder: (context, i) {
        final slide = slides[i];
        final isSelected = i == selected;
        return GestureDetector(
          onTap: () => onSelect(i),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            width: 62,
            height: 62,
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFF5B9DFF)
                    : Colors.white24,
                width: isSelected ? 2.4 : 1,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x66000000),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(9),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CustomImage(
                    size: const Size(58, 58),
                    image: slide.url,
                    radius: 0,
                    fit: BoxFit.cover,
                    isShowPlaceHolder: true,
                    webPreferHtmlElement: false,
                  ),
                  if (slide.isVideo)
                    const Center(
                      child: Icon(Icons.play_circle_fill_rounded,
                          color: Colors.white, size: 22),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _IdentityBlock extends StatelessWidget {
  final User user;
  final ProfileScreenController controller;

  const _IdentityBlock({required this.user, required this.controller});

  @override
  Widget build(BuildContext context) {
    final name = user.fullname ?? user.username ?? '';
    final tags = _galleryTags(user);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyleCustom.unboundedSemiBold600(
                        color: Colors.white,
                        fontSize: 22,
                      ),
                    ),
                  ),
                  if (user.isVerify == 1) ...[
                    const SizedBox(width: 6),
                    Image.asset(AssetRes.icBlueTick, width: 18, height: 18),
                  ],
                ],
              ),
              if (tags.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final tag in tags)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 9, vertical: 3),
                        decoration: BoxDecoration(
                          color: tag.$2,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          tag.$1,
                          style: TextStyleCustom.outFitMedium500(
                            color: Colors.white,
                            fontSize: 11,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  GestureDetector(
                    onTap: () => controller.openFollowList(
                      FollowListType.followers,
                    ),
                    child: Text(
                      '${(user.followerCount ?? 0).numberFormat} ${LKey.followers.tr}',
                      style: TextStyleCustom.outFitRegular400(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      '|',
                      style: TextStyleCustom.outFitRegular400(
                        color: Colors.white38,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => controller.openFollowList(
                      FollowListType.following,
                    ),
                    child: Text(
                      '${(user.followingCount ?? 0).numberFormat} ${LKey.following.tr}',
                      style: TextStyleCustom.outFitRegular400(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        FramedAvatar.fromUser(user, size: 88, compact: true),
      ],
    );
  }
}

List<(String, Color)> _galleryTags(User user) {
  final tags = <(String, Color)>[];
  final age = _ageFromDob(user.dob);
  if (age != null) {
    tags.add(('$age', const Color(0xFFF472B6)));
  }
  final country = (user.country ?? '').trim();
  if (country.isNotEmpty) {
    tags.add((country, const Color(0xFFA78BFA)));
  }
  final lang = LanguageDisplay.name(user.appLanguage);
  if (lang.isNotEmpty) {
    tags.add((lang, const Color(0xFF60A5FA)));
  }
  return tags;
}

String? _lastCallLabel(User user) {
  final raw = (user.lastCallAt ?? '').trim();
  if (raw.isEmpty) return null;
  final parsed = DateTime.tryParse(raw);
  if (parsed == null) return null;
  final diff = DateTime.now().difference(parsed.toLocal());
  if (diff.isNegative) return null;
  if (diff.inMinutes < 60) {
    final min = diff.inMinutes < 1 ? 1 : diff.inMinutes;
    return LKey.lastCallMinutesAgo.trParams({'min': '$min'});
  }
  if (diff.inHours < 48) {
    return LKey.lastCallHoursAgo.trParams({'hours': '${diff.inHours}'});
  }
  return null;
}

int? _ageFromDob(String? dob) {
  final raw = (dob ?? '').trim();
  if (raw.isEmpty) return null;
  final parsed = DateTime.tryParse(raw);
  if (parsed == null) return null;
  final now = DateTime.now();
  var age = now.year - parsed.year;
  if (now.month < parsed.month ||
      (now.month == parsed.month && now.day < parsed.day)) {
    age--;
  }
  if (age < 1 || age > 120) return null;
  return age;
}

double? _impressionAvg(User user) {
  if (user.impressionRating != null) return user.impressionRating;
  final qualities = user.impressionQualities;
  if (qualities.isEmpty) return null;
  final maxVotes =
      qualities.fold<int>(0, (best, q) => q.votes > best ? q.votes : best);
  if (maxVotes > 0) {
    final fill = qualities.fold<int>(0, (sum, q) => sum + q.votes) /
        (qualities.length * maxVotes);
    return 3.5 + (1.5 * fill);
  }
  final starred = qualities.where((q) => q.stars > 0).toList();
  if (starred.isEmpty) return null;
  return starred.fold<int>(0, (sum, q) => sum + q.stars) / starred.length;
}

class _StreamerAvgCard extends StatelessWidget {
  const _StreamerAvgCard({required this.avg, required this.showBars});

  final StreamerAverage avg;
  final bool showBars;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                avg.avg.toStringAsFixed(0),
                style: TextStyleCustom.unboundedSemiBold600(
                  color: _callOrange,
                  fontSize: 22,
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${LKey.streamerAverage.tr} / 100',
                    style: TextStyleCustom.outFitMedium500(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    '${LKey.weeklyLevel.tr} ${avg.grade}',
                    style: TextStyleCustom.outFitSemiBold600(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (avg.nextGrade != null && avg.need > 0) ...[
            const SizedBox(height: 6),
            Text(
              avg.need == 1
                  ? LKey.streamerAverageNeedOne.trParams({
                      'grade': avg.nextGrade!,
                    })
                  : LKey.streamerAverageNeed.trParams({
                      'n': '${avg.need}',
                      'grade': avg.nextGrade!,
                    }),
              style: TextStyleCustom.outFitRegular400(
                color: Colors.white54,
                fontSize: 11,
              ),
            ),
          ],
          if (showBars) ...[
            const SizedBox(height: 10),
            for (final row in [
              (LKey.avgCoins.tr, avg.coins),
              (LKey.avgCalls.tr, avg.calls),
              (LKey.avgLive.tr, avg.live),
              (LKey.avgActivity.tr, avg.interaction),
              (LKey.avgQuality.tr, avg.quality),
            ]) ...[
              Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: Row(
                  children: [
                    SizedBox(
                      width: 78,
                      child: Text(
                        row.$1,
                        style: TextStyleCustom.outFitMedium500(
                          color: Colors.white54,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: (row.$2 / 100).clamp(0.02, 1),
                          minHeight: 5,
                          backgroundColor: Colors.white12,
                          valueColor:
                              const AlwaysStoppedAnimation(_callOrange),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${row.$2}',
                      style: TextStyleCustom.outFitSemiBold600(
                        color: Colors.white,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _ImpressionCard extends StatelessWidget {
  final User user;
  final ProfileScreenController controller;
  final bool isMe;

  const _ImpressionCard({
    required this.user,
    required this.controller,
    required this.isMe,
  });

  bool get _canRate => !isMe && AppRole.isClient();

  @override
  Widget build(BuildContext context) {
    final qualities = user.impressionQualities;
    final grade = AssetRes.streamerBadgeLabel(user.effectiveStreamerGrade);
    final avg = _impressionAvg(user);

    final maxVotes = qualities.isEmpty
        ? 0
        : qualities.map((q) => q.votes).fold<int>(0, (a, b) => a > b ? a : b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Icon(Icons.local_fire_department_rounded,
                color: _callOrange, size: 16),
            const SizedBox(width: 8),
            Text(
              LKey.impression.tr,
              style: TextStyleCustom.outFitMedium500(
                color: Colors.white,
                fontSize: 13,
              ),
            ),
            const Spacer(),
            if (_canRate)
              TextButton(
                onPressed: () => _openRateSheet(context),
                child: Text(
                  LKey.rateImpression.tr,
                  style: TextStyleCustom.outFitMedium500(
                    color: _callOrange,
                    fontSize: 13,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _canRate ? () => _openRateSheet(context) : null,
          child: Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white12),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    if (avg != null) ...[
                      Text(
                        avg.toStringAsFixed(1),
                        style: TextStyleCustom.unboundedSemiBold600(
                          color: _callOrange,
                          fontSize: 22,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            LKey.rating.tr,
                            style: TextStyleCustom.outFitMedium500(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                          _StarRow(value: avg, size: 14),
                        ],
                      ),
                    ] else ...[
                      const Icon(Icons.thumb_up_alt_rounded,
                          color: _callOrange, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        (user.totalPostLikesCount ?? 0).toInt().numberFormat,
                        style: TextStyleCustom.outFitMedium500(
                          color: Colors.white,
                          fontSize: 13,
                        ),
                      ),
                    ],
                    const Spacer(),
                    Image.asset(AssetRes.icBlueTick, width: 16, height: 16),
                    const SizedBox(width: 4),
                    Text(
                      LKey.rankLabel.trParams(
                          {'grade': grade.isEmpty ? 'NEW' : grade}),
                      style: TextStyleCustom.outFitMedium500(
                        color: Colors.white,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                if (qualities.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  for (var i = 0; i < qualities.length; i++)
                    _TraitBar(
                      quality: qualities[i],
                      maxVotes: maxVotes,
                      highlight: i == 0,
                    ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _openRateSheet(BuildContext context) async {
    if (GuestGate.block()) return;
    final streamerId = user.id;
    if (streamerId == null) return;
    Get.bottomSheet(
      _ImpressionRateSheet(
        streamerId: streamerId,
        onSaved: (updated) {
          if (updated != null) {
            controller.userData.value = updated;
          }
        },
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }
}

class _TraitBar extends StatelessWidget {
  final ImpressionQuality quality;
  final int maxVotes;
  final bool highlight;

  const _TraitBar({
    required this.quality,
    required this.maxVotes,
    required this.highlight,
  });

  @override
  Widget build(BuildContext context) {
    final fill = maxVotes <= 0
        ? (quality.stars / 5)
        : (quality.votes / maxVotes).clamp(0.0, 1.0);
    final count = quality.votes > 0
        ? quality.votes
        : (quality.stars > 0 ? quality.stars : 0);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 110),
            child: Text(
              quality.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyleCustom.outFitMedium500(
                color: highlight ? const Color(0xFFC4B5FD) : Colors.white,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: fill,
                minHeight: 8,
                backgroundColor: const Color(0xFF2A2A30),
                color: ColorRes.mlPurple,
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 28,
            child: Text(
              '$count',
              textAlign: TextAlign.right,
              style: TextStyleCustom.outFitMedium500(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ImpressionRateSheet extends StatefulWidget {
  final int streamerId;
  final ValueChanged<User?> onSaved;

  const _ImpressionRateSheet({
    required this.streamerId,
    required this.onSaved,
  });

  @override
  State<_ImpressionRateSheet> createState() => _ImpressionRateSheetState();
}

class _ImpressionRateSheetState extends State<_ImpressionRateSheet> {
  static const _maxChecks = 6;
  final _query = TextEditingController();
  List<ImpressionQuality> _traits = const [];
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final traits = await UserService.instance.fetchImpressionCatalog(
      streamerId: widget.streamerId,
    );
    if (!mounted) return;
    setState(() {
      _traits = traits;
      _loading = false;
    });
  }

  int get _checkedCount => _traits.where((t) => t.checked).length;

  List<ImpressionQuality> get _visible {
    final q = _query.text.trim().toLowerCase();
    if (q.isEmpty) return _traits;
    return _traits.where((t) => t.label.toLowerCase().contains(q)).toList();
  }

  void _toggle(ImpressionQuality trait) {
    final id = trait.id;
    if (id == null) return;
    if (!trait.checked && _checkedCount >= _maxChecks) {
      BaseController.share.showSnackBar(
        LKey.maxTraitsHint.trParams({'count': '$_maxChecks'}),
      );
      return;
    }
    setState(() {
      _traits = [
        for (final item in _traits)
          if (item.id == id) item.copyWith(checked: !item.checked) else item,
      ];
    });
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    final ids = _traits
        .where((t) => t.checked && t.id != null)
        .map((t) => t.id!)
        .toList();
    final updated = await UserService.instance.rateImpression(
      streamerId: widget.streamerId,
      traitIds: ids,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (updated == null) return;
    Get.back();
    widget.onSaved(updated);
    BaseController.share.showSnackBar(LKey.ratingSaved.tr, translate: false);
  }

  @override
  Widget build(BuildContext context) {
    final visible = _visible;
    final picks = visible.where((t) => t.isPick).toList();
    final others = visible.where((t) => !t.isPick).toList();
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Container(
          height: MediaQuery.sizeOf(context).height * 0.82,
          decoration: const BoxDecoration(
            color: _sheet,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        LKey.rateImpression.tr,
                        style: TextStyleCustom.outFitMedium500(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    Text(
                      LKey.maxTraitsHint.trParams({'count': '$_maxChecks'}),
                      style: TextStyleCustom.outFitRegular400(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: TextField(
                  controller: _query,
                  onChanged: (_) => setState(() {}),
                  style: TextStyleCustom.outFitRegular400(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                  decoration: InputDecoration(
                    hintText: LKey.searchHere.tr,
                    hintStyle: TextStyleCustom.outFitRegular400(
                      color: Colors.white38,
                      fontSize: 14,
                    ),
                    prefixIcon:
                        const Icon(Icons.search, color: Colors.white38, size: 20),
                    filled: true,
                    fillColor: const Color(0xFF1A1A1F),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: _loading
                    ? const LoaderWidget(color: ColorRes.mlPurple)
                    : visible.isEmpty
                        ? Center(
                            child: Text(
                              LKey.callEmptyTitle.tr,
                              style: TextStyleCustom.outFitRegular400(
                                color: Colors.white54,
                                fontSize: 14,
                              ),
                            ),
                          )
                        : ListView(
                            padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
                            children: [
                              if (picks.isNotEmpty) ...[
                                _TraitSectionTitle(
                                  title: LKey.herTraits.tr,
                                  color: const Color(0xFFC4B5FD),
                                ),
                                for (final trait in picks) _TraitCheckRow(
                                  trait: trait,
                                  highlight: true,
                                  onTap: () => _toggle(trait),
                                ),
                                const SizedBox(height: 8),
                              ],
                              if (others.isNotEmpty) ...[
                                _TraitSectionTitle(
                                  title: LKey.otherTraits.tr,
                                  color: Colors.white70,
                                ),
                                for (final trait in others) _TraitCheckRow(
                                  trait: trait,
                                  highlight: false,
                                  onTap: () => _toggle(trait),
                                ),
                              ],
                            ],
                          ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _saving || _loading ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ColorRes.mlPurple,
                      disabledBackgroundColor: Colors.white12,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    child: _saving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            '${LKey.saveRating.tr}  ($_checkedCount/$_maxChecks)',
                            style: TextStyleCustom.outFitMedium500(
                              color: Colors.white,
                              fontSize: 15,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TraitSectionTitle extends StatelessWidget {
  final String title;
  final Color color;

  const _TraitSectionTitle({required this.title, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
      child: Text(
        title,
        style: TextStyleCustom.outFitMedium500(color: color, fontSize: 13),
      ),
    );
  }
}

class _TraitCheckRow extends StatelessWidget {
  final ImpressionQuality trait;
  final bool highlight;
  final VoidCallback onTap;

  const _TraitCheckRow({
    required this.trait,
    required this.highlight,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          children: [
            Expanded(
              child: Text(
                trait.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyleCustom.outFitMedium500(
                  color: highlight ? const Color(0xFFC4B5FD) : Colors.white,
                  fontSize: 14,
                ),
              ),
            ),
            if (trait.votes > 0)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Text(
                  '${trait.votes}',
                  style: TextStyleCustom.outFitRegular400(
                    color: Colors.white38,
                    fontSize: 12,
                  ),
                ),
              ),
            SizedBox(
              width: 24,
              height: 24,
              child: Checkbox(
                value: trait.checked,
                onChanged: (_) => onTap(),
                activeColor: ColorRes.mlPurple,
                checkColor: Colors.white,
                side: const BorderSide(color: Colors.white38),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StarRow extends StatelessWidget {
  final double value;
  final double size;

  const _StarRow({required this.value, this.size = 16});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 1; i <= 5; i++)
          Icon(
            i <= value.floor()
                ? Icons.star_rounded
                : (i == value.floor() + 1 && value - value.floor() >= 0.4)
                    ? Icons.star_half_rounded
                    : Icons.star_border_rounded,
            color: _callOrange,
            size: size,
          ),
      ],
    );
  }
}

class _LevelBar extends StatelessWidget {
  final User user;

  const _LevelBar({required this.user});

  @override
  Widget build(BuildContext context) {
    final title = (user.levelTitle ?? '').trim();
    final level = user.levelNumber ?? 0;
    final label = title.isNotEmpty ? title : 'Level $level';
    final progress = (level / 20).clamp(0.15, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyleCustom.outFitMedium500(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 4,
            backgroundColor: Colors.white12,
            color: ColorRes.mlPurple,
          ),
        ),
      ],
    );
  }
}

class _BottomActions extends StatelessWidget {
  final User user;
  final ProfileScreenController controller;
  final bool isMe;

  const _BottomActions({
    required this.user,
    required this.controller,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    if (isMe) {
      return Row(
        children: [
          if (AppRole.isStreamer(user)) ...[
            Material(
              color: const Color(0xFF2A2A30),
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => Get.to(() => const WorkScreen()),
                child: const SizedBox(
                  width: 52,
                  height: 52,
                  child: Icon(
                    Icons.work_outline_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Material(
              color: const Color(0xFF2A2A30),
              borderRadius: BorderRadius.circular(28),
              child: InkWell(
                borderRadius: BorderRadius.circular(28),
                onTap: () => Get.to(() => EditProfileScreen(
                      onUpdateUser: controller.onUpdateUser,
                    )),
                child: SizedBox(
                  height: 52,
                  child: Center(
                    child: Text(
                      LKey.editProfile.tr,
                      style: TextStyleCustom.outFitSemiBold600(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }

    final isLive = CallAvailability.isLive(user);
    final watchingLive = CallAvailability.isWatchingThisLive(user);
    final canCall = CallAvailability.canPlaceCall(user);
    final showJoinLive = isLive && !watchingLive;
    final showCall = !showJoinLive && AppRole.canReceivePaidCalls(user);
    final cost = CallAvailability.callCost(user);
    final inCall = CallAvailability.isInCall(user);
    final offline = CallAvailability.isOffline(user);

    String callLabel = LKey.callCostPerMin.trParams({'coins': '$cost'});
    if (inCall) {
      callLabel = LKey.inCall.tr;
    } else if (offline) {
      callLabel = LKey.offlineBadge.tr;
    }

    return Row(
      children: [
        Material(
          color: const Color(0xFF2A2A30),
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () {
              if (GuestGate.block()) return;
              controller.handlePublishOrMessageBtn(false);
            },
            child: const SizedBox(
              width: 52,
              height: 52,
              child: Icon(Icons.chat_bubble_outline_rounded,
                  color: Colors.white, size: 22),
            ),
          ),
        ),
        if (showJoinLive) ...[
          const SizedBox(width: 10),
          Expanded(
            child: _PrimaryPill(
              color: ColorRes.mlPurple,
              onTap: () {
                if (GuestGate.block()) return;
                controller.openUserLiveIfAny();
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const LiveTvIcon(size: 26, color: Colors.white),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      LKey.joinThisLive.tr,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyleCustom.outFitSemiBold600(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ] else if (showCall) ...[
          const SizedBox(width: 10),
          Expanded(
            child: _PrimaryPill(
              color: canCall ? _callOrange : const Color(0xFF5C5C62),
              onTap: canCall
                  ? controller.requestVideoCall
                  : () {
                      final msg = CallAvailability.blockMessage(user);
                      if (msg != null) controller.showSnackBar(msg);
                    },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    AssetRes.icVideoCamera,
                    width: 20,
                    height: 20,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 8),
                  if (canCall) ...[
                    Image.asset(AssetRes.icCoin, width: 18, height: 18),
                    const SizedBox(width: 4),
                  ],
                  Flexible(
                    child: Text(
                      callLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyleCustom.outFitSemiBold600(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _PrimaryPill extends StatelessWidget {
  final Color color;
  final VoidCallback onTap;
  final Widget child;

  const _PrimaryPill({
    required this.color,
    required this.onTap,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(28),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        child: SizedBox(height: 52, child: child),
      ),
    );
  }
}

void _showMoreOptions(
  BuildContext context,
  ProfileScreenController controller,
  User user,
  bool isMe,
) {
  final isBlocked = user.isBlock == true;
  final following = user.isFollowing == true;
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
            if (isMe) ...[
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: Text(LKey.editProfile.tr),
                onTap: () {
                  Get.back();
                  Get.to(() => EditProfileScreen(
                        onUpdateUser: controller.onUpdateUser,
                      ));
                },
              ),
              ListTile(
                leading: const Icon(Icons.settings_outlined),
                title: Text(LKey.settings.tr),
                onTap: () {
                  Get.back();
                  Get.to(() => SettingsScreen(
                        onUpdateUser: controller.onUpdateUser,
                      ));
                },
              ),
            ] else ...[
              ListTile(
                leading: Icon(
                  following
                      ? Icons.person_remove_outlined
                      : Icons.person_add_alt,
                  color: ColorRes.textDarkGrey,
                ),
                title: Text(following ? LKey.unFollow.tr : LKey.follow.tr),
                onTap: () {
                  Get.back();
                  controller.followUnFollowUser();
                },
              ),
              if (ContentProtection.canShare)
                ListTile(
                  leading:
                      Image.asset(AssetRes.icShare2, height: 22, width: 22),
                  title: Text(LKey.share.tr),
                  onTap: () {
                    Get.back();
                    ShareManager.shared.showCustomShareSheet(
                      user: user,
                      keys: ShareKeys.user,
                    );
                  },
                ),
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
            ],
            const SizedBox(height: 8),
          ],
        ),
      ),
    ),
  );
}
