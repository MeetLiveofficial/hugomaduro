import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krimson/common/extensions/string_extension.dart';
import 'package:krimson/common/manager/app_role.dart';
import 'package:krimson/common/manager/call_availability.dart';
import 'package:krimson/common/widget/brand_controls.dart';
import 'package:krimson/common/widget/custom_image.dart';
import 'package:krimson/common/widget/loader_widget.dart';
import 'package:krimson/common/widget/my_refresh_indicator.dart';
import 'package:krimson/common/widget/no_data_widget.dart';
import 'package:krimson/languages/languages_keys.dart';
import 'package:krimson/model/general/countries_model.dart';
import 'package:krimson/model/user_model/user_model.dart';
import 'package:krimson/screen/explore_screen/explore_screen_controller.dart';
import 'package:krimson/utilities/client_colors.dart';
import 'package:krimson/utilities/color_res.dart';
import 'package:krimson/utilities/style_res.dart';
import 'package:krimson/utilities/text_style_custom.dart';
import 'package:krimson/utilities/theme_res.dart';

/// Explorar: clientes ven streamers (chat/llamar); streamers ven clientes (solo chat).
class ExploreScreen extends StatelessWidget {
  const ExploreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ExploreScreenController());
    final viewerIsStreamer = AppRole.isStreamer();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ExploreHeader(
          controller: controller,
          viewerIsStreamer: viewerIsStreamer,
        ),
        Expanded(
          child: Stack(
            children: [
              Obx(() {
                final isLoading = controller.isLoading.value;
                final list = controller.streamers;
                final hasData = list.isNotEmpty;

                return MyRefreshIndicator(
                  onRefresh: controller.refreshList,
                  child: isLoading && !hasData
                      ? const LoaderWidget()
                      : NoDataView(
                          showShow: !isLoading && !hasData,
                          title: LKey.searchPageEmptyTitle.tr,
                          description: viewerIsStreamer
                              ? LKey.noClientsWithFilters
                              : LKey.noStreamersWithFilters,
                          child: GridView.builder(
                            controller: controller.scrollController,
                            padding: const EdgeInsets.fromLTRB(10, 4, 10, 24),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing: 8,
                              crossAxisSpacing: 8,
                              childAspectRatio: 0.78,
                            ),
                            itemCount: list.length +
                                (controller.isLoadingMore.value ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index >= list.length) {
                                return const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(16),
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  ),
                                );
                              }
                              final user = list[index];
                              return _StreamerExploreCard(
                                user: user,
                                showCallButton: !viewerIsStreamer,
                                onTap: () => controller.openProfile(user),
                                onCall: () => controller.startCall(user),
                                onMessage: () => controller.openChat(user),
                              );
                            },
                          ),
                        ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }
}

class _ExploreHeader extends StatelessWidget {
  final ExploreScreenController controller;
  final bool viewerIsStreamer;

  const _ExploreHeader({
    required this.controller,
    required this.viewerIsStreamer,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
        child: Column(
          children: [
            TextField(
              controller: controller.searchController,
              onChanged: controller.onSearchChanged,
              style: TextStyleCustom.outFitMedium500(
                fontSize: 15,
                color: AppRole.isClient()
                    ? ClientColors.text
                    : textDarkGrey(context),
              ),
              decoration: BrandControls.search(
                hint: LKey.searchUsers.tr,
                hintColor: AppRole.isClient()
                    ? ClientColors.textMuted
                    : textLightGrey(context),
                prefix: Icon(Icons.search,
                    color: StyleRes.brandAccent, size: 22),
                suffix: Obx(() {
                  final hasFilter =
                      controller.selectedCountryCode.value != null ||
                          controller.presenceFilter.value != 'all' ||
                          controller.searchText.value.trim().isNotEmpty;
                  if (!hasFilter) return const SizedBox.shrink();
                  return IconButton(
                    tooltip: LKey.clearFilters.tr,
                    onPressed: controller.clearFilters,
                    icon: Icon(Icons.close,
                        size: 18, color: StyleRes.brandAccent),
                  );
                }),
              ),
            ),
            const SizedBox(height: 8),
            Obx(() {
              final presence = controller.presenceFilter.value;
              return Row(
                children: [
                  Expanded(
                    child: BrandSegmentChip(
                      compact: true,
                      label: LKey.all.tr,
                      active: presence == 'all',
                      onTap: () => controller.selectPresence('all'),
                    ),
                  ),
                  if (!viewerIsStreamer) ...[
                    const SizedBox(width: 6),
                    Expanded(
                      child: BrandSegmentChip(
                        compact: true,
                        label: LKey.liveBadge.tr,
                        active: presence == 'live',
                        accent: StyleRes.brandAccent,
                        icon: Icons.videocam,
                        onTap: () => controller.selectPresence('live'),
                      ),
                    ),
                  ],
                  const SizedBox(width: 6),
                  Expanded(
                    child: BrandSegmentChip(
                      compact: true,
                      label: LKey.activeFilter.tr,
                      active: presence == 'active',
                      accent: const Color(0xFF22C55E),
                      icon: Icons.circle,
                      onTap: () => controller.selectPresence('active'),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: BrandFilterChip(
                      compact: true,
                      label: controller.selectedCountryName.value ??
                          LKey.country.tr,
                      active: controller.selectedCountryCode.value != null,
                      icon: Icons.public,
                      onTap: () => _pickCountry(context, controller),
                    ),
                  ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }
}

Future<void> _pickCountry(
    BuildContext context, ExploreScreenController c) async {
  final q = TextEditingController();
  final filtered = <Country>[].obs;
  filtered.assignAll(c.countries);

  final sheet = Container(
      height: Get.height * 0.72,
      decoration: BoxDecoration(
        color: AppRole.isClient()
            ? ClientColors.surface
            : scaffoldBackgroundColor(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 10),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: bgGrey(context),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 8, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    LKey.filterByCountry.tr,
                    style: TextStyleCustom.outFitSemiBold600(
                      color: textDarkGrey(context),
                      fontSize: 16,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => Get.back(result: '__clear__'),
                  child: Text(LKey.all.tr),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: q,
              onChanged: (v) {
                final t = v.trim().toLowerCase();
                if (t.isEmpty) {
                  filtered.assignAll(c.countries);
                } else {
                  filtered.assignAll(c.countries.where((e) =>
                      e.countryName.toLowerCase().contains(t) ||
                      e.countryCode.toLowerCase().contains(t)));
                }
              },
              decoration: InputDecoration(
                hintText: LKey.searchCountry.tr,
                prefixIcon: const Icon(Icons.search, size: 20),
                filled: true,
                fillColor: AppRole.isClient()
                    ? ClientColors.surfaceAlt
                    : bgMediumGrey(context),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Obx(() => ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (_, i) {
                    final country = filtered[i];
                    final active =
                        c.selectedCountryCode.value == country.countryCode;
                    return ListTile(
                      dense: true,
                      title: Text(country.countryName),
                      trailing: active
                          ? Icon(Icons.check, color: StyleRes.brandAccent)
                          : null,
                      onTap: () => Get.back(result: country),
                    );
                  },
                )),
          ),
        ],
      ),
    );

  final result = await Get.bottomSheet<Object>(
    AppRole.isClient()
        ? Theme(data: ThemeRes.clientTheme(context), child: sheet)
        : sheet,
    isScrollControlled: true,
  );

  if (result == '__clear__') {
    c.selectCountry(null);
  } else if (result is Country) {
    c.selectCountry(result);
  }
}

class _StreamerExploreCard extends StatelessWidget {
  final User user;
  final bool showCallButton;
  final VoidCallback onTap;
  final VoidCallback onCall;
  final VoidCallback onMessage;

  const _StreamerExploreCard({
    required this.user,
    required this.showCallButton,
    required this.onTap,
    required this.onCall,
    required this.onMessage,
  });

  @override
  Widget build(BuildContext context) {
    final name = user.fullname ?? user.username ?? 'User';
    final subtitle = (user.username ?? '').isNotEmpty
        ? '@${user.username}'
        : (user.country ?? user.appLanguage ?? '');
    final photo = (user.profilePhoto ?? '').trim().addBaseURL();
    final isLive = CallAvailability.isLive(user);
    final canCall = showCallButton && CallAvailability.canPlaceCall(user);
    final inCall = CallAvailability.isInCall(user);
    final isActive = !isLive && !inCall && user.isActive == 1;
    final isOffline = !isLive && !inCall && !isActive;

    return GestureDetector(
      onTap: onTap,
        child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (photo.isNotEmpty)
              CustomImage(
                size: const Size(400, 600),
                image: photo,
                fit: BoxFit.cover,
                radius: 0,
                isShowPlaceHolder: true,
                fullName: name,
              )
            else
              DecoratedBox(
                decoration: BoxDecoration(gradient: StyleRes.themeGradient),
                child: Center(
                  child: Text(
                    name.trim().isEmpty
                        ? 'ML'
                        : name.trim().substring(0, 1).toUpperCase(),
                    style: TextStyleCustom.unboundedMedium500(
                      color: Colors.white,
                      fontSize: 36,
                    ),
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
                  stops: [0, 0.35, 1],
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (inCall)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xE6EA580C),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.videocam_rounded,
                              color: Colors.white, size: 11),
                          const SizedBox(width: 3),
                          Text(
                            LKey.inCall.tr,
                            style: TextStyleCustom.outFitMedium500(
                              color: Colors.white,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    )
                  else if (isLive)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        gradient: StyleRes.themeGradient,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: StyleRes.brandAccent.withValues(alpha: 0.45),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.videocam,
                              color: Colors.white, size: 11),
                          const SizedBox(width: 3),
                          Text(
                            LKey.liveBadge.tr,
                            style: TextStyleCustom.outFitMedium500(
                              color: Colors.white,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    )
                  else if (isActive)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xE6166534),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.circle,
                              color: Color(0xFF4ADE80), size: 8),
                          const SizedBox(width: 4),
                          Text(
                            LKey.statusActive.tr,
                            style: TextStyleCustom.outFitMedium500(
                              color: Colors.white,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    )
                  else if (isOffline)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xE63F3F46),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        LKey.offlineBadge.tr,
                        style: TextStyleCustom.outFitMedium500(
                          color: Colors.white70,
                          fontSize: 10,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if ((user.country ?? '').isNotEmpty ||
                (user.countryCode ?? '').isNotEmpty)
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppRole.isClient()
                        ? ClientColors.primaryActive
                        : ColorRes.darkPurple.withValues(alpha: 0.82),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    (user.countryCode ?? user.country ?? '').toUpperCase(),
                    style: TextStyleCustom.outFitMedium500(
                      color: Colors.white,
                      fontSize: 10,
                    ),
                  ),
                ),
              ),
            Positioned(
              left: 10,
              right: 6,
              bottom: 8,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
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
                          subtitle,
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
                  Material(
                    color: Colors.white.withValues(alpha: 0.18),
                    shape: const CircleBorder(),
                    child: PopupMenuButton<String>(
                      tooltip: LKey.options.tr,
                      color: ColorRes.whitePure,
                      padding: EdgeInsets.zero,
                      icon: const Icon(Icons.more_vert_rounded,
                          color: Colors.white, size: 20),
                      onSelected: (value) {
                        if (value == 'chat') onMessage();
                        if (value == 'call') onCall();
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'chat',
                          child: Row(
                            children: [
                              const Icon(Icons.chat_bubble_outline_rounded,
                                  color: ColorRes.textDarkGrey, size: 18),
                              const SizedBox(width: 10),
                              Text(
                                LKey.chat.tr,
                                style: TextStyleCustom.outFitMedium500(
                                  color: ColorRes.textDarkGrey,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (showCallButton && isLive)
                          PopupMenuItem(
                            value: 'call',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.live_tv_rounded,
                                  color: StyleRes.brandAccent,
                                  size: 18,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  LKey.joinThisLive.tr,
                                  style: TextStyleCustom.outFitMedium500(
                                    color: ColorRes.textDarkGrey,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          )
                        else if (showCallButton)
                          PopupMenuItem(
                            value: 'call',
                            enabled: canCall,
                            child: Row(
                              children: [
                                Icon(
                                  Icons.videocam_rounded,
                                  color: canCall
                                      ? StyleRes.brandAccent
                                      : ColorRes.disabledGrey,
                                  size: 18,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  LKey.callAction.tr,
                                  style: TextStyleCustom.outFitMedium500(
                                    color: canCall
                                        ? ColorRes.textDarkGrey
                                        : ColorRes.disabledGrey,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
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
