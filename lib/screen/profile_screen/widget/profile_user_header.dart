import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krimson/common/extensions/common_extension.dart';
import 'package:krimson/common/manager/app_role.dart';
import 'package:krimson/common/manager/call_availability.dart';
import 'package:krimson/common/manager/content_protection.dart';
import 'package:krimson/common/manager/session_manager.dart';
import 'package:krimson/common/manager/share_manager.dart';
import 'package:krimson/common/widget/framed_avatar.dart';
import 'package:krimson/common/widget/full_name_with_blue_tick.dart';
import 'package:krimson/common/widget/loader_widget.dart';
import 'package:krimson/common/widget/text_button_custom.dart';
import 'package:krimson/languages/languages_keys.dart';
import 'package:krimson/model/user_model/user_model.dart';
import 'package:krimson/screen/level_screen/level_screen.dart';
import 'package:krimson/screen/privilege_screen/privilege_hub_screen.dart';
import 'package:krimson/screen/profile_screen/profile_screen_controller.dart';
import 'package:krimson/screen/profile_screen/widget/follow_list_controller.dart';
import 'package:krimson/screen/profile_screen/widget/user_link_sheet.dart';
import 'package:krimson/screen/match_screen/match_screen.dart';
import 'package:krimson/screen/settings_screen/settings_screen.dart';
import 'package:krimson/screen/tasks_screen/tasks_screen.dart';
import 'package:krimson/screen/work_screen/work_screen.dart';
import 'package:krimson/utilities/asset_res.dart';
import 'package:krimson/utilities/color_res.dart';
import 'package:krimson/utilities/language_display.dart';
import 'package:krimson/utilities/level_avatar_style.dart';
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

      final tags = _profileTagLabels(user, isMe: isMe);
      final bio = (user.bio ?? '').trim();
      final handle = (user.username ?? '').trim();

      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _Avatar(
                  user: user,
                  hasStories: hasStories,
                  onTap: () {
                    if (user.isLive == 1) {
                      controller.openUserLiveIfAny();
                    } else {
                      controller.onStoryTap(hasStories);
                    }
                  },
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child:                             FullNameWithBlueTick(
                              username: user.fullname ?? user.username,
                              isVerify: user.isVerify,
                              isVip: user.isVip,
                              fontSize: 15,
                              style: TextStyleCustom.unboundedMedium500(
                                color: textDarkGrey(context),
                                fontSize: 15,
                              ).copyWith(height: 1.2),
                              mainAxisAlignment: MainAxisAlignment.start,
                            ),
                          ),
                          if (isMe)
                            _HeaderEditButton(
                              onTap: () => Get.to(
                                () => SettingsScreen(
                                  onUpdateUser: controller.onUpdateUser,
                                ),
                              ),
                            ),
                        ],
                      ),
                      if (handle.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            '@$handle',
                            style: TextStyleCustom.outFitRegular400(
                              color: textLightGrey(context),
                              fontSize: 13,
                            ),
                          ),
                        ),
                      if (user.isLive == 1 && AppRole.isStreamer(user)) ...[
                        const SizedBox(height: 6),
                        InkWell(
                          onTap: () => controller.openUserLiveIfAny(),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: ColorRes.themeAccentSolid,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'LIVE',
                              style: TextStyleCustom.outFitMedium500(
                                color: Colors.white,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _StatsRow(controller: controller, user: user),
            const SizedBox(height: 8),
            if (bio.isNotEmpty)
              Text(
                bio,
                textAlign: TextAlign.center,
                style: TextStyleCustom.outFitRegular400(
                  color: textDarkGrey(context),
                  fontSize: 14,
                ),
              )
            else if (isMe)
              _GhostPill(
                icon: Icons.add,
                label: 'Añade descripción',
                onTap: () => Get.to(
                  () => SettingsScreen(onUpdateUser: controller.onUpdateUser),
                ),
              ),
            if (tags.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final tag in tags)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
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
              ),
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: 6,
                runSpacing: 6,
                children: [
                  InkWell(
                    onTap: () =>
                        Get.to(() => LevelScreen(userLevels: user.getLevel)),
                    child: _SoftPill(
                      label:
                          '${LKey.level.tr} ${user.levelNumber ?? user.getLevel.level ?? 1}',
                      color: themeAccentSolid(context),
                    ),
                  ),
                  if (isMe && AppRole.canAccessTasks())
                    InkWell(
                      onTap: () async {
                        await Get.to(() => const TasksScreen());
                        await controller.fetchUserDetail();
                      },
                      child: _SoftPill(
                        label:
                            '${LKey.withdrawalPoints.tr}: ${user.withdrawalPoints ?? 0}',
                        color: ColorRes.brandMagenta,
                      ),
                    ),
                ],
              ),
            ),
            if (links.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: InkWell(
                  onTap: () => Get.bottomSheet(
                    UserLinkSheet(links: links),
                    isScrollControlled: true,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
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
            const SizedBox(height: 10),
            if (isMe && AppRole.isStreamer(user)) ...[
              InkWell(
                onTap: () => Get.to(() => const PrivilegeHubScreen()),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  width: double.infinity,
                  height: 36,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    gradient: StyleRes.themeGradient,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: ColorRes.brandMagenta.withValues(alpha: 0.35),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Text(
                        LKey.svip.tr,
                        style: TextStyleCustom.unboundedSemiBold600(
                          color: ColorRes.whitePure,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        LKey.learnMore.tr,
                        style: TextStyleCustom.outFitMedium500(
                          color: ColorRes.whitePure,
                          fontSize: 12,
                        ),
                      ),
                      const Spacer(),
                      const Icon(Icons.workspace_premium,
                          color: ColorRes.whitePure, size: 18),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
            ],
            _ActionButtons(controller: controller, isMe: isMe, user: user),
          ],
        ),
      );
    });
  }
}

/// Botón flotante de videollamada (perfil ajeno).
class ProfileVideoCallFab extends StatelessWidget {
  final User user;
  final VoidCallback onTap;

  const ProfileVideoCallFab({
    super.key,
    required this.user,
    required this.onTap,
  });

  bool get _canReceive => AppRole.canReceivePaidCalls(user);

  int get _cost => CallAvailability.callCost(user);

  @override
  Widget build(BuildContext context) {
    final enabled = _canReceive;
    final buttonColor =
        enabled ? ColorRes.brandMagenta : textLightGrey(context).withValues(alpha: 0.55);

    return Material(
      elevation: 8,
      shadowColor: Colors.black45,
      borderRadius: BorderRadius.circular(40),
      color: buttonColor,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(40),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                AssetRes.icVideoCamera,
                height: 18,
                width: 18,
                color: whitePure(context),
              ),
              const SizedBox(width: 8),
              Image.asset(
                AssetRes.icCoin,
                height: 18,
                width: 18,
              ),
              const SizedBox(width: 5),
              Text(
                LKey.callCostPerMin.trParams({'coins': '$_cost'}),
                style: TextStyleCustom.outFitSemiBold600(
                  color: whitePure(context),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final ProfileScreenController controller;
  final User user;

  const _StatsRow({required this.controller, required this.user});

  @override
  Widget build(BuildContext context) {
    final items = <Widget>[];
    void addStat(_StatColumn stat) {
      if (items.isNotEmpty) {
        items.add(
          Container(
            width: 1,
            height: 28,
            color: textLightGrey(context).withValues(alpha: 0.28),
          ),
        );
      }
      items.add(Expanded(child: stat));
    }

    if (AppRole.isStreamer(user)) {
      addStat(_StatColumn(
        value: controller.posts.length,
        label: LKey.posts.tr,
      ));
      addStat(_StatColumn(
        value: user.totalPostLikesCount ?? 0,
        label: LKey.likes.tr,
      ));
    }
    addStat(_StatColumn(
      value: (user.followerCount ?? 0).toInt(),
      label: LKey.followers.tr,
      onTap: () => controller.openFollowList(FollowListType.followers),
    ));
    addStat(_StatColumn(
      value: (user.followingCount ?? 0).toInt(),
      label: LKey.following.tr,
      onTap: () => controller.openFollowList(FollowListType.following),
    ));

    return Row(children: items);
  }
}

class _HeaderEditButton extends StatelessWidget {
  final VoidCallback onTap;

  const _HeaderEditButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        height: 34,
        width: 34,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: StyleRes.themeGradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: ColorRes.crimson.withValues(alpha: 0.28),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Image.asset(
          AssetRes.icEdit,
          height: 16,
          width: 16,
          color: ColorRes.whitePure,
        ),
      ),
    );
  }
}

class _GhostPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _GhostPill({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: bgGrey(context),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: textDarkGrey(context)),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyleCustom.outFitMedium500(
                color: textDarkGrey(context),
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SoftPill extends StatelessWidget {
  final String label;
  final Color color;

  const _SoftPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyleCustom.outFitMedium500(
          color: color,
          fontSize: 12,
        ),
      ),
    );
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
    final isLive = user.isLive == 1;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(50),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          FramedAvatar.fromUser(
            user,
            size: 96,
            compact: true,
            ring: (child) => LevelAvatarRing(
              user: user,
              padding: 3,
              child: child,
            ),
          ),
          if (isLive)
            Positioned(
              left: 0,
              right: 0,
              bottom: -2,
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: ColorRes.themeAccentSolid,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'LIVE',
                    style: TextStyleCustom.outFitMedium500(
                      color: Colors.white,
                      fontSize: 9,
                    ),
                  ),
                ),
              ),
            ),
          Positioned(
            right: 10,
            bottom: 10,
            child: Builder(
              builder: (context) {
                final isMe = user.id == SessionManager.instance.getUserID();
                final isPresent =
                    isMe || user.isActive == 1 || user.isLive == 1;
                return Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: isPresent
                        ? const Color(0xFF22C55E)
                        : const Color(0xFF9CA3AF),
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: scaffoldBackgroundColor(context), width: 2),
                  ),
                );
              },
            ),
          ),
        ],
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
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value.numberFormat,
            maxLines: 1,
            style: TextStyleCustom.unboundedSemiBold600(
              color: textDarkGrey(context),
              fontSize: 17,
            ).copyWith(
              height: 1.2,
              leadingDistribution: TextLeadingDistribution.even,
            ),
          ),
        ),
        const SizedBox(height: 4),
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
      final canPublish = AppRole.canPublish(user);
      return Column(
        children: [
          Row(
            children: [
              if (canPublish)
                Expanded(
                  child: TextButtonCustom(
                    onTap: () => controller.handlePublishOrMessageBtn(true),
                    title: LKey.publish.tr,
                    backgroundColor: themeAccentSolid(context),
                    titleColor: whitePure(context),
                    btnHeight: 36,
                    fontSize: 15,
                    radius: 22,
                    horizontalMargin: 0,
                    margin: EdgeInsets.zero,
                  ),
                )
              else
                Expanded(
                  child: TextButtonCustom(
                    onTap: () => Get.to(
                      () =>
                          SettingsScreen(onUpdateUser: controller.onUpdateUser),
                    ),
                    title: LKey.settings.tr,
                    backgroundColor: themeAccentSolid(context),
                    titleColor: whitePure(context),
                    btnHeight: 36,
                    fontSize: 15,
                    radius: 22,
                    horizontalMargin: 0,
                    margin: EdgeInsets.zero,
                  ),
                ),
              if (AppRole.isStreamer(user)) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: TextButtonCustom(
                    onTap: () => Get.to(() => const MatchScreen()),
                    title: LKey.matchLabel.tr,
                    backgroundColor: ColorRes.coralRed,
                    titleColor: whitePure(context),
                    btnHeight: 36,
                    fontSize: 15,
                    radius: 22,
                    horizontalMargin: 0,
                    margin: EdgeInsets.zero,
                  ),
                ),
                const SizedBox(width: 8),
                _WorkIconAction(
                  onTap: () => Get.to(() => const WorkScreen()),
                ),
              ],
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
            ],
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
                  ? ColorRes.bgGrey
                  : ColorRes.brandMagenta,
                    titleColor: following
                        ? ColorRes.textDarkGrey
                        : ColorRes.whitePure,
                    btnHeight: 36,
                    fontSize: 15,
                    radius: 22,
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
            btnHeight: 36,
            fontSize: 15,
            radius: 22,
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
      borderRadius: BorderRadius.circular(21),
      child: Container(
        height: 36,
        width: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: StyleRes.themeGradient,
          borderRadius: BorderRadius.circular(21),
          boxShadow: [
            BoxShadow(
              color: ColorRes.crimson.withValues(alpha: 0.28),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Image.asset(
          icon,
          height: 20,
          width: 20,
          color: ColorRes.whitePure,
        ),
      ),
    );
  }
}

class _WorkIconAction extends StatelessWidget {
  final VoidCallback onTap;

  const _WorkIconAction({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(21),
      child: Container(
        height: 36,
        width: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: StyleRes.themeGradient,
          borderRadius: BorderRadius.circular(21),
          boxShadow: [
            BoxShadow(
              color: ColorRes.crimson.withValues(alpha: 0.28),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Icon(
          Icons.work_outline_rounded,
          size: 22,
          color: ColorRes.whitePure,
        ),
      ),
    );
  }
}

/// Pills de idioma / país para el header de perfil.
List<(String, Color)> _profileTagLabels(User user, {required bool isMe}) {
  final tags = <(String, Color)>[];
  // En el propio perfil, el locale de sesión es la fuente de verdad (Settings).
  final code = isMe ? SessionManager.instance.getLang() : user.appLanguage;
  final lang = LanguageDisplay.name(code);
  if (lang.isNotEmpty) {
    tags.add((lang, const Color(0xFF60A5FA)));
  }
  final country = (user.country ?? '').trim();
  if (country.isNotEmpty) {
    tags.add((country, const Color(0xFFA78BFA)));
  }
  return tags;
}
