import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krimson/common/controller/firebase_firestore_controller.dart';
import 'package:krimson/common/manager/session_manager.dart';
import 'package:krimson/common/widget/custom_image.dart';
import 'package:krimson/common/widget/live_tv_icon.dart';
import 'package:krimson/languages/languages_keys.dart';
import 'package:krimson/model/livestream/app_user.dart';
import 'package:krimson/model/livestream/livestream.dart';
import 'package:krimson/screen/live_stream/live_stream_search_screen/live_stream_search_screen_controller.dart';
import 'package:krimson/screen/live_stream/livestream_screen/widget/live_host_panel.dart';
import 'package:krimson/utilities/color_res.dart';
import 'package:krimson/utilities/style_res.dart';
import 'package:krimson/utilities/text_style_custom.dart';
import 'package:krimson/utilities/theme_res.dart';

class LiveStreamSearchScreen extends StatelessWidget {
  const LiveStreamSearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(LiveStreamSearchScreenController());

    return Scaffold(
      backgroundColor: scaffoldBackgroundColor(context),
      appBar: AppBar(
        backgroundColor: scaffoldBackgroundColor(context),
        elevation: 0,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            LiveTvIcon(size: 28, color: textDarkGrey(context)),
            const SizedBox(width: 8),
            Text(
              'LIVE',
              style: TextStyleCustom.unboundedSemiBold600(
                color: textDarkGrey(context),
                fontSize: 18,
              ),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: controller.refreshList,
            icon: Icon(Icons.refresh, color: textDarkGrey(context)),
            tooltip: LKey.refresh.tr,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: controller.onTapGoLive,
        backgroundColor: ColorRes.themeGradient1,
        icon: const LiveTvIcon(size: 22, color: Colors.white),
        label: Text(
          LKey.startLive.tr,
          style:
              TextStyleCustom.outFitMedium500(color: Colors.white, fontSize: 14),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Obx(() {
              final count = controller.livestreams.length;
              return Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  count == 0
                      ? LKey.noLivestreamsTitle.tr
                      : '$count ${LKey.liveNow.tr}',
                  style: TextStyleCustom.outFitMedium500(
                    color: textLightGrey(context),
                    fontSize: 13,
                  ),
                ),
              );
            }),
          ),
          Expanded(
            child: Obx(() {
              if (controller.isBootstrapping.value &&
                  controller.livestreams.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }

              if (controller.livestreams.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        LiveTvIcon(
                            size: 64, color: textLightGrey(context)),
                        const SizedBox(height: 16),
                        Text(
                          LKey.noLivestreamsTitle.tr,
                          textAlign: TextAlign.center,
                          style: TextStyleCustom.unboundedSemiBold600(
                            color: textDarkGrey(context),
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          LKey.noLivestreamsDescription.tr,
                          textAlign: TextAlign.center,
                          style: TextStyleCustom.outFitRegular400(
                            color: textLightGrey(context),
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 20),
                        TextButton(
                          onPressed: controller.onTapGoLive,
                          child: Text(LKey.startLive.tr),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: controller.refreshList,
                child: GridView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.72,
                  ),
                  itemCount: controller.livestreams.length,
                  itemBuilder: (context, index) {
                    final stream = controller.livestreams[index];
                    return _LiveCard(
                      stream: stream,
                      onTap: () => controller.openLivestream(stream),
                    );
                  },
                ),
              );
            }),
          ),
          SafeArea(
            top: false,
            child: Container(
              width: double.infinity,
              color: whitePure(context),
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 88),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  LiveHostActionBar(
                    onBeauty: controller.openPreLiveBeauty,
                    onInvite: controller.openPreLiveInvite,
                    networkLabel: controller.networkLabel,
                  ),
                  Obx(() {
                    if (controller.invitedIds.isEmpty) {
                      return const SizedBox.shrink();
                    }
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        '${LKey.invited.tr}: ${controller.invitedIds.length}',
                        style: TextStyleCustom.outFitMedium500(
                          color: themeAccentSolid(context),
                          fontSize: 12,
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LiveCard extends StatelessWidget {
  final Livestream stream;
  final VoidCallback onTap;

  const _LiveCard({required this.stream, required this.onTap});

  AppUser? _resolveHost() {
    if (Get.isRegistered<FirebaseFirestoreController>()) {
      final users = Get.find<FirebaseFirestoreController>().users;
      final fromFs = users.firstWhereOrNull((u) => u.userId == stream.hostId);
      if (fromFs != null) return fromFs;
    }
    final dummy = SessionManager.instance
        .getSettings()
        ?.dummyLives
        ?.firstWhereOrNull((d) => d.userId == stream.hostId)
        ?.user;
    if (dummy != null) {
      return AppUser(
        userId: dummy.id,
        username: dummy.username,
        fullname: dummy.fullname,
        profile: dummy.profilePhoto,
        isVerify: dummy.isVerify,
        identity: dummy.identity,
      );
    }
    return stream.hostUser;
  }

  @override
  Widget build(BuildContext context) {
    final host = _resolveHost();
    final title = (stream.description ?? '').trim().isEmpty
        ? 'Live'
        : stream.description!.trim();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: StyleRes.themeGradient,
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if ((stream.coverImage ?? '').isNotEmpty)
              Positioned.fill(
                child: CustomImage(
                  size: const Size(400, 400),
                  image: stream.coverImage,
                  fit: BoxFit.cover,
                  radius: 0,
                  isShowPlaceHolder: true,
                ),
              )
            else
              ColoredBox(
                color: Colors.black.withValues(alpha: 0.35),
                child: Center(
                  child: CustomImage(
                    size: const Size(72, 72),
                    image: host?.profile,
                    fullName: host?.fullname ?? title,
                    radius: 40,
                  ),
                ),
              ),
            if ((stream.coverImage ?? '').isNotEmpty)
              Positioned.fill(
                child: ColoredBox(
                  color: Colors.black.withValues(alpha: 0.25),
                ),
              ),
            Positioned(
              top: 10,
              left: 10,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.redAccent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'LIVE',
                  style: TextStyleCustom.outFitMedium500(
                    color: Colors.white,
                    fontSize: 10,
                  ),
                ),
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.remove_red_eye,
                        color: Colors.white, size: 12),
                    const SizedBox(width: 4),
                    Text(
                      '${stream.watchingCount ?? 0}',
                      style: TextStyleCustom.outFitRegular400(
                        color: Colors.white,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 10,
              right: 10,
              bottom: 12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    host?.fullname ?? host?.username ?? 'Host',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyleCustom.outFitMedium500(
                      color: Colors.white,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyleCustom.outFitRegular400(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
