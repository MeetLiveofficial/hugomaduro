import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krimson/common/manager/app_role.dart';
import 'package:krimson/common/manager/session_manager.dart';
import 'package:krimson/common/widget/custom_back_button.dart';
import 'package:krimson/common/widget/my_refresh_indicator.dart';
import 'package:krimson/common/widget/text_button_custom.dart';
import 'package:krimson/languages/languages_keys.dart';
import 'package:krimson/model/user_model/user_model.dart';
import 'package:krimson/screen/profile_screen/profile_screen_controller.dart';
import 'package:krimson/screen/profile_screen/widget/profile_page_view.dart';
import 'package:krimson/screen/profile_screen/widget/profile_tab_bar_view.dart';
import 'package:krimson/screen/profile_screen/widget/profile_user_header.dart';
import 'package:krimson/screen/profile_screen/widget/streamer_gallery_profile.dart';
import 'package:krimson/utilities/text_style_custom.dart';
import 'package:krimson/utilities/theme_res.dart';

class ProfileScreen extends StatelessWidget {
  final User? user;
  final bool isTopBarVisible;
  final bool isDashBoard;
  final Function(User? user)? onUserUpdate;

  const ProfileScreen(
      {super.key,
      this.user,
      this.isTopBarVisible = true,
      this.isDashBoard = false,
      this.onUserUpdate});

  @override
  Widget build(BuildContext context) {
    ProfileScreenController controller = Get.put(
        ProfileScreenController(
          user.obs,
          onUserUpdate,
        ),
        tag: isDashBoard
            ? ProfileScreenController.tag
            : "${DateTime.now().millisecondsSinceEpoch}");

    return Scaffold(
      backgroundColor: const Color(0xFF0B0B0F),
      body: PopScope(
        onPopInvokedWithResult: (didPop, result) {
          controller.adsController
              .showInterstitialAdIfAvailable(isPopScope: true);
        },
        child: Obx(() {
          final profileUser = controller.userData.value;
          final isClientProfile = profileUser != null &&
              AppRole.isClient(profileUser) &&
              !AppRole.canReceivePaidCalls(profileUser) &&
              profileUser.isLive != 1;

          final Widget content;
          if (!isClientProfile) {
            content = StreamerGalleryProfile(
              controller: controller,
              showBack: isTopBarVisible,
            );
          } else {
            content = SafeArea(
              bottom: false,
              child: Column(
                children: [
                  _TopViewForOtherUser(
                      user: profileUser,
                      isTopBarVisible: isTopBarVisible,
                      controller: controller),
                  Expanded(
                    child: DefaultTabController(
                      length: 2,
                      child: MyRefreshIndicator(
                        depth: 2,
                        onRefresh: controller.onRefresh,
                        child: NestedScrollView(
                          headerSliverBuilder: (context, _) {
                            return [
                              SliverList(
                                delegate: SliverChildListDelegate([
                                  ProfileUserHeader(controller: controller)
                                ]),
                              ),
                            ];
                          },
                          body: AppRole.isClient(profileUser)
                              ? const _ClientProfileEmptyBody()
                              : Column(
                                  children: [
                                    ProfileTabs(controller: controller),
                                    ProfilePageView(controller: controller)
                                  ],
                                ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          return Stack(
            children: [
              content,
              if (profileUser?.isFreez == 1)
                Positioned.fill(
                  child: Container(
                    color: scaffoldBackgroundColor(context)
                        .withValues(alpha: 0.4),
                    child: ClipRRect(
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.lock_person_rounded,
                                size: 80, color: textLightGrey(context)),
                            const SizedBox(height: 20),
                            Text(
                              LKey.profileUnavailable.tr,
                              style: TextStyleCustom.unboundedSemiBold600(
                                  color: textLightGrey(context), fontSize: 18),
                            ),
                            const SizedBox(height: 10),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 30.0),
                              child: Text(
                                LKey.profileTemporarilyFrozen.tr,
                                textAlign: TextAlign.center,
                                style: TextStyleCustom.outFitMedium500(
                                    color: textLightGrey(context),
                                    fontSize: 16),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Obx(() {
                              bool isModerator = SessionManager
                                      .instance.isModerator.value ==
                                  1;
                              if (!isModerator) {
                                return const SizedBox();
                              }
                              return TextButtonCustom(
                                onTap: () =>
                                    controller.freezeUnfreezeUser(true),
                                title: LKey.unFreeze.tr,
                                titleColor: whitePure(context),
                                backgroundColor: textDarkGrey(context),
                              );
                            })
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        }),
      ),
    );
  }
}

class _TopViewForOtherUser extends StatelessWidget {
  final User? user;
  final bool isTopBarVisible;
  final ProfileScreenController controller;

  const _TopViewForOtherUser(
      {this.user, required this.isTopBarVisible, required this.controller});

  @override
  Widget build(BuildContext context) {
    return isTopBarVisible
        ? Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CustomBackButton(
                onTap: () {
                  controller.adsController.showInterstitialAdIfAvailable();
                },
                padding: const EdgeInsets.all(15),
              ),
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0),
                  child: Text(
                    user?.username ?? '',
                    style: TextStyleCustom.unboundedMedium500(
                        color: textDarkGrey(context)),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              const SizedBox(width: 18 + 30),
            ],
          )
        : const SizedBox();
  }
}

/// Cuerpo vacío al visitar un perfil client (sin grid Posts/Reels).
class _ClientProfileEmptyBody extends StatelessWidget {
  const _ClientProfileEmptyBody();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(32, 24, 32, 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.person_outline,
                size: 56, color: textLightGrey(context)),
            const SizedBox(height: 14),
            Text(
              'Perfil de cliente',
              style: TextStyleCustom.unboundedSemiBold600(
                color: textDarkGrey(context),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Este usuario no publica Posts ni Reels.',
              textAlign: TextAlign.center,
              style: TextStyleCustom.outFitRegular400(
                color: textLightGrey(context),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
