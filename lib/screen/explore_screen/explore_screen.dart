import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krimson/common/extensions/string_extension.dart';
import 'package:krimson/common/manager/app_role.dart';
import 'package:krimson/common/widget/custom_image.dart';
import 'package:krimson/common/widget/loader_widget.dart';
import 'package:krimson/common/widget/my_refresh_indicator.dart';
import 'package:krimson/common/widget/no_data_widget.dart';
import 'package:krimson/languages/languages_keys.dart';
import 'package:krimson/model/general/countries_model.dart';
import 'package:krimson/model/general/settings_model.dart';
import 'package:krimson/model/user_model/user_model.dart';
import 'package:krimson/screen/explore_screen/explore_screen_controller.dart';
import 'package:krimson/utilities/color_res.dart';
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
                              ? 'No hay clientes con estos filtros'
                              : 'No hay streamers con estos filtros',
                          child: GridView.builder(
                            controller: controller.scrollController,
                            padding: const EdgeInsets.fromLTRB(10, 4, 10, 24),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing: 8,
                              crossAxisSpacing: 8,
                              childAspectRatio: 0.72,
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
    return Container(
      color: scaffoldBackgroundColor(context),
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            TextField(
              controller: controller.searchController,
              onChanged: controller.onSearchChanged,
              style: TextStyleCustom.outFitRegular400(
                fontSize: 15,
                color: textDarkGrey(context),
              ),
              decoration: InputDecoration(
                hintText: viewerIsStreamer
                    ? 'Buscar clientes…'
                    : 'Buscar streamers…',
                hintStyle: TextStyleCustom.outFitLight300(
                  fontSize: 15,
                  color: textLightGrey(context),
                ),
                prefixIcon: Icon(Icons.search,
                    color: textLightGrey(context), size: 20),
                suffixIcon: Obx(() {
                  final hasFilter =
                      controller.selectedCountryCode.value != null ||
                          controller.selectedLanguageCode.value != null ||
                          controller.presenceFilter.value != 'all' ||
                          controller.searchText.value.trim().isNotEmpty;
                  if (!hasFilter) return const SizedBox.shrink();
                  return IconButton(
                    tooltip: 'Limpiar',
                    onPressed: controller.clearFilters,
                    icon: Icon(Icons.close,
                        size: 18, color: textLightGrey(context)),
                  );
                }),
                filled: true,
                fillColor: bgMediumGrey(context),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Obx(() {
              final presence = controller.presenceFilter.value;
              // Streamers exploran clientes: no aplica "En vivo".
              if (viewerIsStreamer) {
                return Row(
                  children: [
                    Expanded(
                      child: _PresenceChip(
                        label: 'Todos',
                        active: presence == 'all',
                        onTap: () => controller.selectPresence('all'),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: _PresenceChip(
                        label: 'Activos',
                        active: presence == 'active',
                        accent: const Color(0xFF22C55E),
                        icon: Icons.circle,
                        onTap: () => controller.selectPresence('active'),
                      ),
                    ),
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(
                    child: _PresenceChip(
                      label: 'Todos',
                      active: presence == 'all',
                      onTap: () => controller.selectPresence('all'),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: _PresenceChip(
                      label: 'En vivo',
                      active: presence == 'live',
                      accent: ColorRes.themeAccentSolid,
                      icon: Icons.videocam,
                      onTap: () => controller.selectPresence('live'),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: _PresenceChip(
                      label: 'Activos',
                      active: presence == 'active',
                      accent: const Color(0xFF22C55E),
                      icon: Icons.circle,
                      onTap: () => controller.selectPresence('active'),
                    ),
                  ),
                ],
              );
            }),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Obx(() => _FilterChipButton(
                        label: controller.selectedCountryName.value ?? 'País',
                        active: controller.selectedCountryCode.value != null,
                        icon: Icons.public,
                        onTap: () => _pickCountry(context, controller),
                      )),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Obx(() {
                    final code = controller.selectedLanguageCode.value;
                    var label = 'Idioma';
                    if (code != null) {
                      final lang = controller.languages
                          .firstWhereOrNull((l) => l.code == code);
                      label = (lang?.localizedTitle ??
                              lang?.title ??
                              code)
                          .toString();
                    }
                    return _FilterChipButton(
                      label: label,
                      active: code != null,
                      icon: Icons.translate,
                      onTap: () => _pickLanguage(context, controller),
                    );
                  }),
                ),
              ],
            ),
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

  final result = await Get.bottomSheet<Object>(
    Container(
      height: Get.height * 0.72,
      decoration: BoxDecoration(
        color: scaffoldBackgroundColor(context),
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
                    'Filtrar por país',
                    style: TextStyleCustom.outFitSemiBold600(
                      color: textDarkGrey(context),
                      fontSize: 16,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => Get.back(result: '__clear__'),
                  child: const Text('Todos'),
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
                fillColor: bgMediumGrey(context),
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
                          ? const Icon(Icons.check,
                              color: ColorRes.themeAccentSolid)
                          : null,
                      onTap: () => Get.back(result: country),
                    );
                  },
                )),
          ),
        ],
      ),
    ),
    isScrollControlled: true,
  );

  if (result == '__clear__') {
    c.selectCountry(null);
  } else if (result is Country) {
    c.selectCountry(result);
  }
}

Future<void> _pickLanguage(
    BuildContext context, ExploreScreenController c) async {
  final result = await Get.bottomSheet<Object>(
    Container(
      decoration: BoxDecoration(
        color: scaffoldBackgroundColor(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
                      'Filtrar por idioma',
                      style: TextStyleCustom.outFitSemiBold600(
                        color: textDarkGrey(context),
                        fontSize: 16,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Get.back(result: '__clear__'),
                    child: const Text('Todos'),
                  ),
                ],
              ),
            ),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: c.languages.length,
                itemBuilder: (_, i) {
                  final lang = c.languages[i];
                  final active = c.selectedLanguageCode.value == lang.code;
                  final title =
                      (lang.localizedTitle ?? lang.title ?? lang.code ?? '')
                          .toString();
                  return ListTile(
                    dense: true,
                    title: Text(title),
                    subtitle: Text(lang.code ?? ''),
                    trailing: active
                        ? const Icon(Icons.check,
                            color: ColorRes.themeAccentSolid)
                        : null,
                    onTap: () => Get.back(result: lang),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    ),
    isScrollControlled: true,
  );

  if (result == '__clear__') {
    c.selectLanguage(null);
  } else if (result is Language) {
    c.selectLanguage(result);
  }
}

class _FilterChipButton extends StatelessWidget {
  final String label;
  final bool active;
  final IconData icon;
  final VoidCallback onTap;

  const _FilterChipButton({
    required this.label,
    required this.active,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: active
          ? ColorRes.themeAccentSolid.withValues(alpha: 0.15)
          : bgMediumGrey(context),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: Row(
            children: [
              Icon(icon,
                  size: 16,
                  color: active
                      ? ColorRes.themeAccentSolid
                      : textLightGrey(context)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyleCustom.outFitMedium500(
                    fontSize: 13,
                    color: active
                        ? ColorRes.themeAccentSolid
                        : textDarkGrey(context),
                  ),
                ),
              ),
              Icon(Icons.expand_more,
                  size: 18, color: textLightGrey(context)),
            ],
          ),
        ),
      ),
    );
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
    final canCall = showCallButton && AppRole.canReceivePaidCalls(user);
    final isLive = user.isLive == 1;
    final isActive = !isLive && user.isActive == 1;

    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
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
              ColoredBox(
                color: ColorRes.surfaceDeep,
                child: Center(
                  child: CustomImage(
                    size: const Size(72, 72),
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
                  stops: [0, 0.35, 1],
                ),
              ),
            ),
            if (isLive)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: ColorRes.themeAccentSolid,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.videocam, color: Colors.white, size: 11),
                      const SizedBox(width: 3),
                      Text(
                        'LIVE',
                        style: TextStyleCustom.outFitMedium500(
                          color: Colors.white,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else if (isActive)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF166534),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: Color(0xFF4ADE80),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Activo',
                        style: TextStyleCustom.outFitMedium500(
                          color: Colors.white,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
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
                    color: Colors.black54,
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
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyleCustom.outFitRegular400(
                      color: Colors.white70,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _CardActionButton(
                          icon: Icons.chat_bubble_outline_rounded,
                          label: 'Chat',
                          onTap: onMessage,
                          color: showCallButton
                              ? Colors.white24
                              : ColorRes.themeAccentSolid,
                        ),
                      ),
                      if (showCallButton) ...[
                        const SizedBox(width: 6),
                        Expanded(
                          child: _CardActionButton(
                            icon: Icons.videocam_rounded,
                            label: 'Llamar',
                            onTap: canCall ? onCall : null,
                            color: canCall
                                ? ColorRes.themeAccentSolid
                                : Colors.white12,
                          ),
                        ),
                      ],
                    ],
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

class _PresenceChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  final Color? accent;
  final IconData? icon;

  const _PresenceChip({
    required this.label,
    required this.active,
    required this.onTap,
    this.accent,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final color = accent ?? textDarkGrey(context);
    return Material(
      color: active
          ? (accent ?? ColorRes.themeAccentSolid).withValues(alpha: 0.18)
          : bgMediumGrey(context),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: icon == Icons.circle ? 8 : 14,
                  color: active ? color : textLightGrey(context),
                ),
                const SizedBox(width: 4),
              ],
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyleCustom.outFitMedium500(
                    color: active ? color : textDarkGrey(context),
                    fontSize: 12,
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

class _CardActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Color color;

  const _CardActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: Colors.white),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyleCustom.outFitMedium500(
                    color: Colors.white,
                    fontSize: 11,
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
