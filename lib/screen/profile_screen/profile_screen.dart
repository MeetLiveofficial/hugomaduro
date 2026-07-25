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
      body: PopScope(
        onPopInvokedWithResult: (didPop, result) {
          controller.adsController
              .showInterstitialAdIfAvailable(isPopScope: true);
        },
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Obx(() => _TopViewForOtherUser(
                  user: controller.userData.value,
                  isTopBarVisible: isTopBarVisible,
                  controller: controller)),
              Expanded(
                child: Stack(
                  children: [
                    DefaultTabController(
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
                          body: Obx(() {
                            final profileUser = controller.userData.value;
                            // Perfil visitado de un client: sin Posts/Reels de creador.
                            if (AppRole.isClient(profileUser)) {
                              return const _ClientProfileEmptyBody();
                            }
                            return Column(
                              children: [
                                ProfileTabs(controller: controller),
                                ProfilePageView(controller: controller)
                              ],
                            );
                          }),
                        ),
                      ),
                    ),
                    Obx(() {
                      final user = controller.userData.value;
                      if (user == null || user.isFreez == 1) {
                        return const SizedBox.shrink();
                      }
                      final isMe =
                          user.id == SessionManager.instance.getUserID();
                      if (isMe) return const SizedBox.shrink();
                      // Clientes no ofrecen videollamada de pago.
                      if (!AppRole.canReceivePaidCalls(user)) {
                        return const SizedBox.shrink();
                      }
                      return Positioned(
                        right: 16,
                        bottom: MediaQuery.paddingOf(context).bottom + 20,
                        child: ProfileVideoCallFab(
                          user: user,
                          onTap: controller.requestVideoCall,
                        ),
                      );
                    }),
                    Obx(() {
                      User? user = controller.userData.value;
                      if (user?.isFreez != 1) {
                        return const SizedBox();
                      }
                      return Container(
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
                                      color: textLightGrey(context),
                                      fontSize: 18),
                                ),
                                const SizedBox(height: 10),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 30.0),
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
                      );
                    })
                  ],
                ),
              ),
            ],
          ),
        ),
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
