import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krimson/common/extensions/common_extension.dart';
import 'package:krimson/common/extensions/string_extension.dart';
import 'package:krimson/common/manager/app_role.dart';
import 'package:krimson/common/manager/content_protection.dart';
import 'package:krimson/common/manager/session_manager.dart';
import 'package:krimson/common/manager/share_manager.dart';
import 'package:krimson/common/widget/custom_image.dart';
import 'package:krimson/common/widget/full_name_with_blue_tick.dart';
import 'package:krimson/common/widget/loader_widget.dart';
import 'package:krimson/common/widget/text_button_custom.dart';
import 'package:krimson/languages/languages_keys.dart';
import 'package:krimson/model/user_model/user_model.dart';
import 'package:krimson/screen/leaderboard_screen/leaderboard_screen.dart';
import 'package:krimson/screen/level_screen/level_screen.dart';
import 'package:krimson/screen/privilege_screen/privilege_hub_screen.dart';
import 'package:krimson/screen/profile_screen/profile_screen_controller.dart';
import 'package:krimson/screen/profile_screen/widget/follow_list_controller.dart';
import 'package:krimson/screen/profile_screen/widget/user_link_sheet.dart';
import 'package:krimson/screen/settings_screen/settings_screen.dart';
import 'package:krimson/screen/tasks_screen/tasks_screen.dart';
import 'package:krimson/screen/withdrawals_screen/withdrawals_screen.dart';
import 'package:krimson/utilities/asset_res.dart';
import 'package:krimson/utilities/color_res.dart';
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
      // Si estoy en la app mirando mi perfil, soy ACTIVE sí o sí.
      final isPresent =
          isMe || user.isActive == 1 || user.isLive == 1;
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
                  onTap: () {
                    if (user.isLive == 1) {
                      controller.openUserLiveIfAny();
                    } else {
                      controller.onStoryTap(hasStories);
                    }
                  },
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Clientes no publican: no mostrar Posts/Likes de creador.
                      if (AppRole.isStreamer(user)) ...[
                        _StatColumn(
                          value: controller.posts.length,
                          label: LKey.posts.tr,
                        ),
                        _StatColumn(
                          value: user.totalPostLikesCount ?? 0,
                          label: LKey.likes.tr,
                        ),
                      ],
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
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (user.isLive == 1 && AppRole.isStreamer(user))
                  InkWell(
                    onTap: () => controller.openUserLiveIfAny(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: ColorRes.themeAccentSolid,
                        borderRadius: BorderRadius.circular(10),
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
                // Siempre visible: ACTIVE o INACTIVE (nunca se oculta).
                Container(
                  key: const ValueKey('presence_badge'),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isPresent
                        ? const Color(0xFF22C55E).withValues(alpha: 0.15)
                        : const Color(0xFF9CA3AF).withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: isPresent
                              ? const Color(0xFF22C55E)
                              : const Color(0xFF9CA3AF),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        isPresent ? 'ACTIVE' : 'INACTIVE',
                        style: TextStyleCustom.outFitMedium500(
                          color: isPresent
                              ? const Color(0xFF15803D)
                              : const Color(0xFF6B7280),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            // Tags idioma / país (pills).
            if (_profileTagLabels(user, isMe: isMe).isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final tag in _profileTagLabels(user, isMe: isMe))
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
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
              padding: const EdgeInsets.only(top: 4),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  InkWell(
                    onTap: () =>
                        Get.to(() => LevelScreen(userLevels: user.getLevel)),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color:
                            themeAccentSolid(context).withValues(alpha: .12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${LKey.level.tr} ${user.levelNumber ?? user.getLevel.level ?? 1}'
                        '${(user.levelTitle ?? user.getLevel.title)?.isNotEmpty == true ? ' · ${user.levelTitle ?? user.getLevel.title}' : ''}',
                        style: TextStyleCustom.outFitMedium500(
                          color: themeAccentSolid(context),
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  if (isMe && AppRole.canAccessTasks())
                    InkWell(
                      onTap: () async {
                        await Get.to(() => const TasksScreen());
                        // Refresca saldo tras reclamaciones / auto-claim en Tasks.
                        await controller.fetchUserDetail();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: ColorRes.brandMagenta.withValues(alpha: .12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${LKey.withdrawalPoints.tr}: ${user.withdrawalPoints ?? 0}',
                          style: TextStyleCustom.outFitMedium500(
                            color: ColorRes.brandMagenta,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
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
            // SVIP / Dressing / Honor: solo streamers en su propio perfil.
            if (isMe && AppRole.isStreamer(user)) ...[
              InkWell(
                onTap: () => Get.to(() => const PrivilegeHubScreen()),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  width: double.infinity,
                  height: 44,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    gradient: StyleRes.themeGradient,
                    borderRadius: BorderRadius.circular(10),
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
                      Icon(Icons.workspace_premium,
                          color: ColorRes.whitePure, size: 18),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _PrivilegeMini(
                      title: LKey.dressingCenter.tr,
                      onTap: () =>
                          Get.to(() => const DressingCenterScreen()),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _PrivilegeMini(
                      title: LKey.myLevel.tr,
                      onTap: () => Get.to(
                          () => LevelScreen(userLevels: user.getLevel)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _PrivilegeMini(
                      title: LKey.honorWall.tr,
                      onTap: () => Get.to(() => const LeaderboardScreen()),
                    ),
                  ),
                ],
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

  int get _cost {
    if (user.levelTitle != null || user.levelNumber != null) {
      return user.callRequestCoins;
    }
    final fromLevel = user.getLevel.callRequestCoins;
    return user.callRequestCoins > 0 ? user.callRequestCoins : fromLevel;
  }

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
    final isClient = AppRole.isClient(user);
    final useLevelRing = isClient && !isLive && !hasStories;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(50),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: isLive
                  ? const LinearGradient(
                      colors: [Color(0xFFFF003F), Color(0xFFFF6B8A)],
                    )
                  : useLevelRing
                      ? LevelAvatarStyle.forUser(user)
                      : (hasStories ? StyleRes.themeGradient : null),
              border: (!isLive && !hasStories && !useLevelRing)
                  ? Border.all(color: bgGrey(context), width: 1.5)
                  : null,
              boxShadow: useLevelRing
                  ? [
                      BoxShadow(
                        color: LevelAvatarStyle.forUser(user)
                            .colors
                            .last
                            .withValues(alpha: 0.35),
                        blurRadius: 10,
                      ),
                    ]
                  : null,
            ),
            child: CustomImage(
              size: const Size(82, 82),
              image: user.profilePhoto?.addBaseURL(),
              fullName: user.fullname,
              strokeWidth: (isLive || hasStories || useLevelRing) ? 2 : 0,
              strokeColor: scaffoldBackgroundColor(context),
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
            right: 2,
            bottom: isLive ? 14 : 4,
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

class _PrivilegeMini extends StatelessWidget {
  final String title;
  final VoidCallback onTap;

  const _PrivilegeMini({required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 6),
        decoration: BoxDecoration(
          color: ColorRes.bgLightGrey,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: ColorRes.bgGrey),
        ),
        alignment: Alignment.center,
        child: Text(
          title,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyleCustom.outFitSemiBold600(
            color: ColorRes.textDarkGrey,
            fontSize: 11,
          ),
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
      final canPublish = AppRole.canPublish(user);
      return Column(
        children: [
          // Streamers ganan (retiros); no recargan. Clientes usan ClientProfileScreen.
          if (canPublish) ...[
            TextButtonCustom(
              onTap: () => Get.to(() => const WithdrawalsScreen()),
              title: LKey.withdrawals.tr,
              backgroundColor: ColorRes.bgGrey,
              titleColor: ColorRes.textDarkGrey,
              btnHeight: 42,
              fontSize: 15,
              horizontalMargin: 0,
              margin: EdgeInsets.zero,
            ),
            const SizedBox(height: 8),
          ],
          Row(
            children: [
              if (canPublish)
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

/// Pills de idioma / país para el header de perfil.
List<(String, Color)> _profileTagLabels(User user, {required bool isMe}) {
  final tags = <(String, Color)>[];
  // En el propio perfil, el locale de sesión es la fuente de verdad (Settings).
  final code = isMe ? SessionManager.instance.getLang() : user.appLanguage;
  final lang = _languageDisplayName(code);
  if (lang != null) {
    tags.add((lang, const Color(0xFF60A5FA)));
  }
  final country = (user.country ?? '').trim();
  if (country.isNotEmpty) {
    tags.add((country, const Color(0xFFA78BFA)));
  }
  return tags;
}

String? _languageDisplayName(String? code) {
  if (code == null || code.trim().isEmpty) return null;
  final c = code.trim().toLowerCase().split(RegExp(r'[_-]')).first;

  final fromSettings = SessionManager.instance
      .getActiveLanguages()
      .firstWhereOrNull((l) => (l.code ?? '').toLowerCase() == c);
  if (fromSettings != null) {
    final title =
        (fromSettings.localizedTitle ?? fromSettings.title ?? '').trim();
    if (title.isNotEmpty) return title;
  }

  const map = {
    'es': 'Español',
    'en': 'English',
    'pt': 'Português',
    'fr': 'Français',
    'de': 'Deutsch',
    'it': 'Italiano',
    'ar': 'العربية',
    'hi': 'हिन्दी',
    'zh': '中文',
    'ja': '日本語',
    'ko': '한국어',
    'ru': 'Русский',
    'uk': 'Українська',
  };
  return map[c] ?? c.toUpperCase();
}
