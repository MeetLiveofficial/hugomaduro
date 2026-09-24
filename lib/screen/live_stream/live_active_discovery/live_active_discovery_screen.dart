import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krimson/common/controller/firebase_firestore_controller.dart';
import 'package:krimson/common/extensions/string_extension.dart';
import 'package:krimson/common/extensions/common_extension.dart';
import 'package:krimson/common/manager/app_role.dart';
import 'package:krimson/common/widget/brand_controls.dart';
import 'package:krimson/common/widget/brand_wash_bg.dart';
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
import 'package:krimson/utilities/client_colors.dart';
import 'package:krimson/utilities/color_res.dart';
import 'package:krimson/utilities/style_res.dart';
import 'package:krimson/utilities/text_style_custom.dart';

/// LIVE discovery: grid 2 columnas (solo lives activos) + búsqueda.
class LiveActiveDiscoveryScreen extends StatelessWidget {
  const LiveActiveDiscoveryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(LiveActiveDiscoveryController());
    final streamer = !AppRole.isClient();
    final accent =
        streamer ? const Color(0xFFE879F9) : ClientColors.primary;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const BrandWashBg(),
          SafeArea(
            bottom: false,
            child: Column(
              children: [
            // Header estilo referencia Live
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 12, 6),
              child: Row(
                children: [
                  // Ranking — podio flat (sin círculo / trofeo)
                  Tooltip(
                    message: LKey.leaderboard.tr,
                    child: InkWell(
                      onTap: () => Get.to(() => const LeaderboardScreen()),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                        child: PodiumIcon(size: 28, color: accent),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Expanded(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: HomeModeSwitcher(),
                    ),
                  ),
                  IconButton(
                    onPressed: controller.toggleSearch,
                    icon: Obx(() => Icon(
                          controller.showSearch.value
                              ? Icons.close
                              : Icons.search,
                          color: accent,
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
                  cursorColor: ClientColors.primary,
                  decoration: BrandControls.search(
                    hint: LKey.searchHere.tr,
                    hintColor: Colors.white54,
                    prefix: const Icon(Icons.search,
                        color: ClientColors.primary, size: 22),
                  ),
                ),
              );
            }),
            if (AppRole.isClient())
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 2, 12, 8),
                child: Obx(() {
                  final current = controller.browseFilter.value;
                  final es = Get.locale?.languageCode == 'es';
                  final chips = <(LiveBrowseFilter, String, IconData?)>[
                    (LiveBrowseFilter.all, LKey.all.tr, null),
                    (LiveBrowseFilter.latinas, 'Latinas', null),
                    (
                      LiveBrowseFilter.newest,
                      es ? 'Nuevas' : 'New',
                      null,
                    ),
                    (LiveBrowseFilter.hot, 'Hot', Icons.local_fire_department_rounded),
                    (LiveBrowseFilter.following, LKey.following.tr, null),
                  ];
                  return SizedBox(
                    height: 36,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: chips.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (_, i) {
                        final (filter, label, icon) = chips[i];
                        final on = current == filter;
                        return GestureDetector(
                          onTap: () => controller.setBrowseFilter(filter),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 7),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(18),
                              color: on
                                  ? const Color(0xFF27D3F5)
                                  : ClientColors.surfaceDarkAlt
                                      .withValues(alpha: 0.9),
                              border: Border.all(
                                color: on
                                    ? const Color(0xFF27D3F5)
                                    : ClientColors.primary
                                        .withValues(alpha: 0.28),
                              ),
                              boxShadow: on
                                  ? ClientColors.neonGlow(
                                      color: const Color(0xFF27D3F5),
                                      alpha: 0.4,
                                      blur: 10,
                                      offset: Offset.zero,
                                    )
                                  : null,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (icon != null) ...[
                                  Icon(
                                    icon,
                                    size: 14,
                                    color: on
                                        ? Colors.white
                                        : const Color(0xFFF97316),
                                  ),
                                  const SizedBox(width: 4),
                                ],
                                Text(
                                  label,
                                  style: TextStyleCustom.outFitSemiBold600(
                                    color: on
                                        ? Colors.white
                                        : Colors.white.withValues(alpha: 0.78),
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  );
                }),
              ),
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
                            controller.emptyTitle(searching: searching),
                            textAlign: TextAlign.center,
                            style: TextStyleCustom.unboundedSemiBold600(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            controller.emptyDescription(searching: searching),
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
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return RefreshIndicator(
                  color: StyleRes.brandAccent,
                  backgroundColor: AppRole.isClient()
                      ? ClientColors.surface
                      : Colors.white,
                  onRefresh: controller.refreshList,
                  child: GridView.builder(
                    padding: const EdgeInsets.fromLTRB(10, 4, 10, 96),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 0.72,
                  ),
                    itemCount: controller.livestreams.length,
                    itemBuilder: (context, index) {
                      final stream = controller.livestreams[index];
                      return _LiveGridCard(
                        key: ValueKey(stream.roomID ?? 'live_$index'),
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
        ],
      ),
    );
  }
}

class _LiveGridCard extends StatelessWidget {
  final Livestream stream;
  final VoidCallback onTap;

  const _LiveGridCard({super.key, required this.stream, required this.onTap});

  AppUser? _resolveHost() {
    // Laravel trae host_user; no pisar con Firestore (fotos viejas/compartidas).
    if (stream.hostUser != null) return stream.hostUser;
    if (Get.isRegistered<FirebaseFirestoreController>()) {
      final users = Get.find<FirebaseFirestoreController>().users;
      final fromFs = users.firstWhereOrNull((u) => u.userId == stream.hostId);
      if (fromFs != null) return fromFs;
    }
    return null;
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
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: AppRole.isClient()
              ? null
              : Border.all(color: const Color(0xFFE879F9).withValues(alpha: 0.45)),
          boxShadow: AppRole.isClient()
              ? ClientColors.neonGlow(alpha: 0.2, blur: 14)
              : [
                  BoxShadow(
                    color: const Color(0xFFE879F9).withValues(alpha: 0.22),
                    blurRadius: 14,
                  ),
                ],
        ),
        child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRole.isClient() ? 18 : 12),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (cardImage.isNotEmpty)
              CustomImage(
                key: ValueKey('${stream.roomID}|$cardImage'),
                size: const Size(400, 600),
                image: cardImage,
                fit: BoxFit.cover,
                radius: 0,
                isShowPlaceHolder: true,
                webPreferHtmlElement: false,
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
              right: 8,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: AppRole.isClient()
                      ? ClientColors.surfaceDarkAlt.withValues(alpha: 0.9)
                      : Colors.black54,
                  borderRadius: BorderRadius.circular(10),
                  border: AppRole.isClient()
                      ? Border.all(
                          color: ClientColors.primary.withValues(alpha: 0.45))
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.remove_red_eye_outlined,
                        color: Colors.white, size: 12),
                    const SizedBox(width: 4),
                    Text(
                      (stream.watchingCount ?? 0).numberFormat,
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
              left: 8,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: stream.type == LivestreamType.battle
                      ? (AppRole.isClient()
                          ? ClientColors.primaryActive
                          : ColorRes.baseRaspberry)
                      : (AppRole.isClient()
                          ? ClientColors.magentaHot
                          : ColorRes.themeAccentSolid),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: AppRole.isClient()
                      ? ClientColors.neonGlow(
                          color: stream.type == LivestreamType.battle
                              ? ClientColors.primary
                              : ClientColors.magentaHot,
                          alpha: 0.45,
                          blur: 10,
                          offset: Offset.zero,
                        )
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      margin: const EdgeInsets.only(right: 5),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                    Text(
                      stream.type == LivestreamType.battle ? 'PK' : 'LIVE',
                      style: TextStyleCustom.outFitSemiBold600(
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
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(1.2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: ClientColors.primary.withValues(alpha: 0.8),
                            width: 1.2,
                          ),
                        ),
                        child: CustomImage(
                          size: const Size(22, 22),
                          image: profile.isEmpty ? null : profile,
                          fullName: name,
                          radius: 11,
                          strokeWidth: 0,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyleCustom.outFitSemiBold600(
                            color: Colors.white,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      if (host?.isVerify == 1)
                        const Icon(Icons.verified_rounded,
                            color: Color(0xFF38BDF8), size: 14)
                      else
                        const Icon(Icons.favorite_rounded,
                            color: Color(0xFFF472B6), size: 13),
                    ],
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
      ),
    );
  }
}
