import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krimson/common/extensions/string_extension.dart';
import 'package:krimson/common/manager/session_manager.dart';
import 'package:krimson/common/widget/custom_image.dart';
import 'package:krimson/common/widget/loader_widget.dart';
import 'package:krimson/languages/languages_keys.dart';
import 'package:krimson/model/general/settings_model.dart';
import 'package:krimson/model/user_model/user_model.dart';
import 'package:krimson/screen/live_stream/livestream_screen/livestream_screen_controller.dart';
import 'package:krimson/utilities/color_res.dart';
import 'package:krimson/utilities/text_style_custom.dart';
import 'package:krimson/utilities/theme_res.dart';

/// Un solo botón lateral que abre Beauty / Network / Calidad / Invite / Batalla.
class LiveHostActionBar extends StatelessWidget {
  final VoidCallback onBeauty;
  final VoidCallback onInvite;
  final VoidCallback? onBattle;
  final VoidCallback? onQuality;
  final RxString networkLabel;
  final String? qualityLabel;
  final bool battleRunning;
  final Color? foreground;

  const LiveHostActionBar({
    super.key,
    required this.onBeauty,
    required this.onInvite,
    required this.networkLabel,
    this.onBattle,
    this.onQuality,
    this.qualityLabel,
    this.battleRunning = false,
    this.foreground,
  });

  @override
  Widget build(BuildContext context) {
    final fg = foreground ?? whitePure(context);
    return Material(
      color: Colors.black.withValues(alpha: 0.55),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => openLiveHostOptionsMenu(
          onBeauty: onBeauty,
          onInvite: onInvite,
          onBattle: onBattle,
          onQuality: onQuality,
          networkLabel: networkLabel,
          qualityLabel: qualityLabel,
          battleRunning: battleRunning,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.tune_rounded, color: fg, size: 18),
              const SizedBox(width: 6),
              Text(
                'Options',
                style: TextStyleCustom.outFitMedium500(
                  color: fg,
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 2),
              Icon(Icons.keyboard_arrow_up_rounded, color: fg, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}

void openLiveHostOptionsMenu({
  required VoidCallback onBeauty,
  required VoidCallback onInvite,
  required RxString networkLabel,
  VoidCallback? onBattle,
  VoidCallback? onQuality,
  String? qualityLabel,
  bool battleRunning = false,
}) {
  Get.bottomSheet(
    SafeArea(
      child: Container(
        decoration: BoxDecoration(
          color: whitePure(Get.context!),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: bgGrey(Get.context!),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            if (onBattle != null)
              _HostOptionTile(
                icon: Icons.sports_kabaddi_rounded,
                title: battleRunning ? 'Finalizar batalla' : LKey.startBattle.tr,
                subtitle: battleRunning
                    ? 'Terminar el enfrentamiento 1v1'
                    : 'Batalla 1v1 con regalos de la audiencia',
                onTap: () {
                  Get.back();
                  onBattle();
                },
              ),
            if (onQuality != null)
              _HostOptionTile(
                icon: Icons.high_quality_rounded,
                title: 'Calidad de video',
                subtitle: qualityLabel != null
                    ? 'Actual: $qualityLabel'
                    : 'Baja / Media / Alta',
                onTap: () {
                  Get.back();
                  onQuality();
                },
              ),
            _HostOptionTile(
              icon: Icons.auto_awesome,
              title: LKey.beautySettings.tr,
              subtitle: LKey.gettingPrettier.tr,
              onTap: () {
                Get.back();
                onBeauty();
              },
            ),
            Obx(() => _HostOptionTile(
                  icon: networkIconForLabel(networkLabel.value),
                  title: LKey.networkConnection.tr,
                  subtitle: networkLabel.value,
                  onTap: () {
                    Get.back();
                    openNetworkInfoSheet(networkLabel.value);
                  },
                )),
            _HostOptionTile(
              icon: Icons.group_add,
              title: LKey.inviteFriends.tr,
              subtitle: LKey.inviteToLiveBonus.tr,
              onTap: () {
                Get.back();
                onInvite();
              },
            ),
          ],
        ),
      ),
    ),
    backgroundColor: Colors.transparent,
  );
}

class _HostOptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _HostOptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: themeAccentSolid(context).withValues(alpha: 0.12),
        child: Icon(icon, color: themeAccentSolid(context), size: 20),
      ),
      title: Text(
        title,
        style: TextStyleCustom.outFitMedium500(
          color: textDarkGrey(context),
          fontSize: 15,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyleCustom.outFitRegular400(
          color: textLightGrey(context),
          fontSize: 12,
        ),
      ),
      trailing: Icon(Icons.chevron_right, color: textLightGrey(context)),
    );
  }
}

Future<void> openLiveBeautySheet({
  required LivestreamScreenController? liveController,
  required RxDouble whiten,
  required RxDouble rosy,
  required RxDouble smooth,
  required RxDouble sharpen,
  required RxBool beautyOn,
  required Future<void> Function() onApply,
}) {
  final filters =
      SessionManager.instance.getSettings()?.deepARFilters ?? <DeepARFilters>[];

  return Get.bottomSheet(
    SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        decoration: BoxDecoration(
          color: whitePure(Get.context!),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Obx(() {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: bgGrey(Get.context!),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              Text(
                LKey.beautySettings.tr,
                textAlign: TextAlign.center,
                style: TextStyleCustom.unboundedSemiBold600(
                  color: textDarkGrey(Get.context!),
                  fontSize: 16,
                ),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(LKey.beautySettings.tr),
                value: beautyOn.value,
                activeThumbColor: themeAccentSolid(Get.context!),
                activeTrackColor:
                    themeAccentSolid(Get.context!).withValues(alpha: 0.4),
                onChanged: (v) {
                  beautyOn.value = v;
                  onApply();
                },
              ),
              _BeautySlider(
                label: 'Whiten',
                value: whiten,
                enabled: beautyOn.value,
                onChanged: (_) => onApply(),
              ),
              _BeautySlider(
                label: 'Rosy',
                value: rosy,
                enabled: beautyOn.value,
                onChanged: (_) => onApply(),
              ),
              _BeautySlider(
                label: 'Smooth',
                value: smooth,
                enabled: beautyOn.value,
                onChanged: (_) => onApply(),
              ),
              _BeautySlider(
                label: 'Sharpen',
                value: sharpen,
                enabled: beautyOn.value,
                onChanged: (_) => onApply(),
              ),
              if (filters.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'Styles',
                  style: TextStyleCustom.outFitMedium500(
                    color: textDarkGrey(Get.context!),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 72,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: filters.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final f = filters[index];
                      return Column(
                        children: [
                          CustomImage(
                            size: const Size(48, 48),
                            strokeWidth: 0,
                            radius: 24,
                            image: f.image?.addBaseURL(),
                            fullName: f.title,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            f.title ?? '',
                            style: TextStyleCustom.outFitLight300(
                              color: textLightGrey(context),
                              fontSize: 10,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ],
          );
        }),
      ),
    ),
    isScrollControlled: true,
  );
}

class _BeautySlider extends StatelessWidget {
  final String label;
  final RxDouble value;
  final bool enabled;
  final ValueChanged<double> onChanged;

  const _BeautySlider({
    required this.label,
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$label ${value.value.round()}',
              style: TextStyleCustom.outFitRegular400(
                color: textLightGrey(context),
                fontSize: 12,
              ),
            ),
            Slider(
              value: value.value,
              min: 0,
              max: 100,
              divisions: 20,
              activeColor: themeAccentSolid(context),
              onChanged: enabled
                  ? (v) {
                      value.value = v;
                      onChanged(v);
                    }
                  : null,
            ),
          ],
        ));
  }
}

Future<void> openLiveInviteSheet({
  required RxList<User> candidates,
  required RxBool loading,
  required RxSet<int> selectedIds,
  required Future<void> Function(User user) onInvite,
  Future<void> Function(String keyword)? onSearch,
}) {
  final searchCtrl = TextEditingController();
  return Get.bottomSheet(
    SafeArea(
      child: Container(
        height: MediaQuery.of(Get.context!).size.height * 0.65,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        decoration: BoxDecoration(
          color: whitePure(Get.context!),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Invite Users',
              textAlign: TextAlign.center,
              style: TextStyleCustom.unboundedSemiBold600(
                color: textDarkGrey(Get.context!),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Search and invite any user to your live',
              textAlign: TextAlign.center,
              style: TextStyleCustom.outFitRegular400(
                color: textLightGrey(Get.context!),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: searchCtrl,
              textInputAction: TextInputAction.search,
              onChanged: (v) {
                if (onSearch != null) onSearch(v.trim());
              },
              onSubmitted: (v) {
                if (onSearch != null) onSearch(v.trim());
              },
              decoration: InputDecoration(
                hintText: 'Search users…',
                prefixIcon: const Icon(Icons.search, size: 20),
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: bgGrey(Get.context!)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: bgGrey(Get.context!)),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Obx(() {
                if (loading.value && candidates.isEmpty) {
                  return const LoaderWidget();
                }
                if (candidates.isEmpty) {
                  return Center(
                    child: Text(
                      LKey.userListEmptyTitle.tr,
                      style: TextStyleCustom.outFitRegular400(
                        color: textLightGrey(Get.context!),
                      ),
                    ),
                  );
                }
                return ListView.separated(
                  itemCount: candidates.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final user = candidates[index];
                    final id = user.id ?? -1;
                    final invited = selectedIds.contains(id);
                    return ListTile(
                      onTap: () {
                        if (Get.isRegistered<LivestreamScreenController>()) {
                          Get.find<LivestreamScreenController>().openUserProfile(
                            userId: user.id,
                            fullname: user.fullname,
                            username: user.username,
                            profilePhoto: user.profilePhoto,
                          );
                        }
                      },
                      leading: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          CustomImage(
                            size: const Size(40, 40),
                            strokeWidth: 0,
                            image: user.profilePhoto?.addBaseURL(),
                            fullName: user.fullname,
                          ),
                          Positioned(
                            right: -2,
                            bottom: -2,
                            child: Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: user.isActive == 1
                                    ? const Color(0xFF22C55E)
                                    : const Color(0xFF9CA3AF),
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: whitePure(context), width: 2),
                              ),
                            ),
                          ),
                        ],
                      ),
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(
                              user.username ?? user.fullname ?? '',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (user.isLive == 1) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: ColorRes.themeAccentSolid,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'LIVE',
                                style: TextStyleCustom.outFitMedium500(
                                  color: Colors.white,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      subtitle: Text(
                        '${user.fullname ?? ''} · ${user.isActive == 1 ? 'ACTIVE' : 'INACTIVE'}',
                      ),
                      trailing: TextButton(
                        onPressed: invited ? null : () => onInvite(user),
                        child: Text(
                          invited ? LKey.invited.tr : LKey.invite.tr,
                        ),
                      ),
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    ),
    isScrollControlled: true,
  ).whenComplete(searchCtrl.dispose);
}

String networkLabelFromResults(List<ConnectivityResult> results) {
  if (results.contains(ConnectivityResult.none) || results.isEmpty) {
    return LKey.networkOffline.tr;
  }
  if (results.contains(ConnectivityResult.wifi)) {
    return LKey.networkWifi.tr;
  }
  if (results.contains(ConnectivityResult.mobile)) {
    return LKey.networkMobile.tr;
  }
  if (results.contains(ConnectivityResult.ethernet)) {
    return 'Ethernet';
  }
  return results.first.name;
}

IconData networkIconForLabel(String label) {
  final lower = label.toLowerCase();
  if (lower.contains('off') || lower.contains('sin')) {
    return Icons.wifi_off;
  }
  if (lower.contains('mobile') || lower.contains('móvil') || lower.contains('movil')) {
    return Icons.signal_cellular_alt;
  }
  if (lower.contains('ethernet')) {
    return Icons.settings_ethernet;
  }
  return Icons.wifi;
}

void openNetworkInfoSheet(String networkLabel) {
  final isOffline = networkLabel.toLowerCase().contains('off') ||
      networkLabel.toLowerCase().contains('sin');
  final isWifi = networkLabel.toLowerCase().contains('wi');
  final tip = isOffline
      ? 'Sin conexión. Conéctate a Wi‑Fi o datos móviles para transmitir.'
      : isWifi
          ? 'Wi‑Fi estable recomendado para LIVE. Evita cambiar de red durante la transmisión.'
          : 'Estás en datos móviles. El LIVE puede consumir mucha data y tener más latencia.';

  Get.bottomSheet(
    Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            Row(
              children: [
                Icon(networkIconForLabel(networkLabel), size: 28),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    LKey.networkConnection.tr,
                    style: TextStyleCustom.unboundedSemiBold600(
                      color: Colors.black87,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              networkLabel,
              style: TextStyleCustom.outFitMedium500(
                color: themeAccentSolid(Get.context!),
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              tip,
              style: TextStyleCustom.outFitRegular400(
                color: Colors.black54,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: Get.back,
              style: ElevatedButton.styleFrom(
                backgroundColor: themeColor(Get.context!),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('OK'),
            ),
          ],
        ),
      ),
    ),
  );
}
