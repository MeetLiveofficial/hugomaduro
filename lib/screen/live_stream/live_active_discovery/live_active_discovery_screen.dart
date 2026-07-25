import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krimson/common/controller/firebase_firestore_controller.dart';
import 'package:krimson/common/extensions/string_extension.dart';
import 'package:krimson/common/manager/app_role.dart';
import 'package:krimson/common/widget/custom_image.dart';
import 'package:krimson/common/widget/live_tv_icon.dart';
import 'package:krimson/common/widget/podium_icon.dart';
import 'package:krimson/languages/languages_keys.dart';
import 'package:krimson/model/livestream/app_user.dart';
import 'package:krimson/model/livestream/livestream.dart';
import 'package:krimson/screen/dashboard_screen/dashboard_screen_controller.dart';
import 'package:krimson/screen/home_screen/widget/home_mode_switcher.dart';
import 'package:krimson/screen/leaderboard_screen/leaderboard_screen.dart';
import 'package:krimson/screen/live_stream/live_active_discovery/live_active_discovery_controller.dart';
import 'package:krimson/utilities/color_res.dart';
import 'package:krimson/utilities/text_style_custom.dart';

/// LIVE discovery: grid 2 columnas (solo lives activos) + búsqueda.
class LiveActiveDiscoveryScreen extends StatelessWidget {
  const LiveActiveDiscoveryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(LiveActiveDiscoveryController());
    const bg = ColorRes.bgVoid;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Header estilo referencia Live
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 8, 6),
              child: Row(
                children: [
                  // Ranking — podio flat (sin círculo / trofeo)
                  Tooltip(
                    message: LKey.leaderboard.tr,
                    child: InkWell(
                      onTap: () => Get.to(() => const LeaderboardScreen()),
                      borderRadius: BorderRadius.circular(8),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                        child: PodiumIcon(size: 28),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Expanded(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: HomeModeSwitcher(lightOnDark: true),
                    ),
                  ),
                  IconButton(
                    onPressed: controller.toggleSearch,
                    icon: Obx(() => Icon(
                          controller.showSearch.value
                              ? Icons.close
                              : Icons.search,
                          color: Colors.white,
                          size: 24,
                        )),
                  ),
                  if (AppRole.canStartLive())
                    IconButton(
                      onPressed: () {
                        if (Get.isRegistered<DashboardScreenController>()) {
                          Get.find<DashboardScreenController>()
                              .onChanged(DashboardScreenController.tabLive);
                        }
                      },
                      icon: const Icon(Icons.add_box_outlined,
                          color: Colors.white, size: 24),
                      tooltip: LKey.startLive.tr,
                    ),
                ],
              ),
            ),
            Obx(() {
              if (!controller.showSearch.value) {
                return const SizedBox.shrink();
              }
              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: TextField(
                  controller: controller.searchController,
                  autofocus: true,
                  style: TextStyleCustom.outFitRegular400(
                    color: Colors.white,
                    fontSize: 15,
                  ),
                  cursorColor: ColorRes.themeAccentSolid,
                  decoration: InputDecoration(
                    hintText: LKey.searchHere.tr,
                    hintStyle: TextStyleCustom.outFitRegular400(
                      color: Colors.white38,
                      fontSize: 15,
                    ),
                    filled: true,
                    fillColor: ColorRes.surfaceDeep,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    prefixIcon: const Icon(Icons.search,
                        color: Colors.white54, size: 22),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              );
            }),
            Expanded(
              child: Obx(() {
                if (controller.isLoading.value &&
                    controller.livestreams.isEmpty) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.white54),
                  );
                }

                if (controller.livestreams.isEmpty) {
                  final searching =
                      controller.searchQuery.value.trim().isNotEmpty;
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const LiveTvIcon(size: 64, color: Colors.white38),
                          const SizedBox(height: 16),
                          Text(
                            searching
                                ? LKey.noData.tr
                                : LKey.noLivestreamsTitle.tr,
                            textAlign: TextAlign.center,
                            style: TextStyleCustom.unboundedSemiBold600(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            searching
                                ? LKey.searchPageEmptyDescription.tr
                                : LKey.noLivestreamsDescription.tr,
                            textAlign: TextAlign.center,
                            style: TextStyleCustom.outFitRegular400(
                              color: Colors.white60,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextButton(
                            onPressed: controller.refreshList,
                            child: Text(
                              LKey.refresh.tr,
                              style: TextStyleCustom.outFitMedium500(
                                color: ColorRes.themeAccentSolid,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return RefreshIndicator(
                  color: ColorRes.themeAccentSolid,
                  backgroundColor: ColorRes.surfaceDeep,
                  onRefresh: controller.refreshList,
                  child: GridView.builder(
                    padding: const EdgeInsets.fromLTRB(10, 4, 10, 20),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      childAspectRatio: 0.72,
                    ),
                    itemCount: controller.livestreams.length,
                    itemBuilder: (context, index) {
                      final stream = controller.livestreams[index];
                      return _LiveGridCard(
                        stream: stream,
                        onTap: () => controller.openLivestream(stream),
                      );
                    },
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

class _LiveGridCard extends StatelessWidget {
  final Livestream stream;
  final VoidCallback onTap;

  const _LiveGridCard({required this.stream, required this.onTap});

  AppUser? _resolveHost() {
    if (Get.isRegistered<FirebaseFirestoreController>()) {
      final users = Get.find<FirebaseFirestoreController>().users;
      final fromFs = users.firstWhereOrNull((u) => u.userId == stream.hostId);
      if (fromFs != null) return fromFs;
    }
    return stream.hostUser;
  }

  @override
  Widget build(BuildContext context) {
    final host = _resolveHost();
    final title = (stream.description ?? '').trim().isEmpty
        ? 'Live'
        : stream.description!.split('\n').first.trim();
    final cover = (stream.coverImage ?? '').trim().addBaseURL();
    final profileRaw = (host?.profile ?? '').trim();
    final profile =
        profileRaw.isEmpty ? '' : profileRaw.addBaseURL();
    final name = host?.fullname ?? host?.username ?? 'Host';
    // Portada del LIVE; si no hay, foto de perfil del host (p.ej. invitado PK).
    final cardImage = cover.isNotEmpty
        ? cover
        : (profile.isNotEmpty ? profile : '');

    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (cardImage.isNotEmpty)
              CustomImage(
                size: const Size(400, 600),
                image: cardImage,
                fit: BoxFit.cover,
                radius: 0,
                isShowPlaceHolder: true,
              )
            else
              ColoredBox(
                color: ColorRes.surfaceDeep,
                child: Center(
                  child: CustomImage(
                    size: const Size(72, 72),
                    image: profile.isEmpty ? null : profile,
                    fullName: name,
                    radius: 40,
                  ),
                ),
              ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.transparent,
                    Color(0xE6000000),
                  ],
                  stops: [0, 0.4, 1],
                ),
              ),
            ),
            // Viewers
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.remove_red_eye,
                        color: Colors.white, size: 12),
                    const SizedBox(width: 4),
                    Text(
                      '${stream.watchingCount ?? 0}',
                      style: TextStyleCustom.outFitMedium500(
                        color: Colors.white,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // LIVE / PK badge
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: stream.type == LivestreamType.battle
                      ? ColorRes.baseRaspberry
                      : ColorRes.themeAccentSolid,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      stream.type == LivestreamType.battle
                          ? Icons.sports_kabaddi_rounded
                          : Icons.videocam,
                      color: Colors.white,
                      size: 11,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      stream.type == LivestreamType.battle ? 'PK' : 'Live',
                      style: TextStyleCustom.outFitMedium500(
                        color: Colors.white,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Name + title
            Positioned(
              left: 10,
              right: 10,
              bottom: 10,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyleCustom.outFitSemiBold600(
                      color: Colors.white,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyleCustom.outFitRegular400(
                      color: Colors.white70,
                      fontSize: 11,
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
