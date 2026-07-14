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
import 'package:krimson/utilities/text_style_custom.dart';
import 'package:krimson/utilities/theme_res.dart';

/// Tres acciones del host: beauty, red e invitar amigos.
class LiveHostActionBar extends StatelessWidget {
  final VoidCallback onBeauty;
  final VoidCallback onInvite;
  final RxString networkLabel;
  final Color? foreground;

  const LiveHostActionBar({
    super.key,
    required this.onBeauty,
    required this.onInvite,
    required this.networkLabel,
    this.foreground,
  });

  @override
  Widget build(BuildContext context) {
    final fg = foreground ?? whitePure(context);
    return Row(
      children: [
        Expanded(
          child: _ActionCard(
            icon: Icons.auto_awesome,
            title: LKey.beautySettings.tr,
            subtitle: LKey.gettingPrettier.tr,
            onTap: onBeauty,
            foreground: fg,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Obx(() => _ActionCard(
                icon: Icons.wifi,
                title: LKey.networkConnection.tr,
                subtitle: networkLabel.value,
                onTap: () {},
                foreground: fg,
              )),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _ActionCard(
            icon: Icons.group_add,
            title: LKey.inviteFriends.tr,
            subtitle: LKey.inviteToLiveBonus.tr,
            onTap: onInvite,
            foreground: fg,
          ),
        ),
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color foreground;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.foreground,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 12, 10, 12),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: foreground, size: 22),
            const SizedBox(height: 8),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyleCustom.outFitMedium500(
                color: foreground,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyleCustom.outFitLight300(
                color: foreground.withValues(alpha: 0.75),
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
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
}) {
  return Get.bottomSheet(
    SafeArea(
      child: Container(
        height: MediaQuery.of(Get.context!).size.height * 0.55,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        decoration: BoxDecoration(
          color: whitePure(Get.context!),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              LKey.inviteFriends.tr,
              textAlign: TextAlign.center,
              style: TextStyleCustom.unboundedSemiBold600(
                color: textDarkGrey(Get.context!),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              LKey.selectFriendsToInvite.tr,
              textAlign: TextAlign.center,
              style: TextStyleCustom.outFitRegular400(
                color: textLightGrey(Get.context!),
                fontSize: 13,
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
                      leading: CustomImage(
                        size: const Size(40, 40),
                        strokeWidth: 0,
                        image: user.profilePhoto?.addBaseURL(),
                        fullName: user.fullname,
                      ),
                      title: Text(user.username ?? user.fullname ?? ''),
                      subtitle: Text(user.fullname ?? ''),
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
  );
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
