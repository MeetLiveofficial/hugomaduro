import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krimson/common/extensions/string_extension.dart';
import 'package:krimson/common/service/api/task_service.dart';
import 'package:krimson/common/widget/custom_image.dart';
import 'package:krimson/common/widget/loader_widget.dart';
import 'package:krimson/languages/languages_keys.dart';
import 'package:krimson/model/user_model/user_model.dart';
import 'package:krimson/model/general/settings_model.dart';
import 'package:krimson/screen/face_filters/models/face_filter_effect.dart';
import 'package:krimson/screen/facebetter/facebetter_style_filters_sheet.dart';
import 'package:krimson/screen/live_stream/livestream_screen/livestream_screen_controller.dart';
import 'package:krimson/screen/tasks_screen/tasks_screen.dart';
import 'package:krimson/utilities/color_res.dart';
import 'package:krimson/utilities/text_style_custom.dart';
import 'package:krimson/utilities/theme_res.dart';

/// Un solo botón lateral que abre Options (mic, pausa, calidad…).
class LiveHostActionBar extends StatelessWidget {
  final VoidCallback onInvite;
  final VoidCallback? onQuality;
  final VoidCallback? onPause;
  final VoidCallback? onMic;
  final VoidCallback? onCamera;
  final String? qualityLabel;
  final bool paused;
  final bool muted;
  final bool? cameraOn;
  final Color? foreground;

  const LiveHostActionBar({
    super.key,
    required this.onInvite,
    this.onQuality,
    this.onPause,
    this.onMic,
    this.onCamera,
    this.qualityLabel,
    this.paused = false,
    this.muted = false,
    this.cameraOn,
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
          onInvite: onInvite,
          onQuality: onQuality,
          onPause: onPause,
          onMic: onMic,
          onCamera: onCamera,
          qualityLabel: qualityLabel,
          paused: paused,
          muted: muted,
          cameraOn: cameraOn,
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
  required VoidCallback onInvite,
  VoidCallback? onQuality,
  VoidCallback? onPause,
  VoidCallback? onMic,
  VoidCallback? onCamera,
  VoidCallback? onGiftSenders,
  String? giftSendersSubtitle,
  String? qualityLabel,
  bool paused = false,
  bool muted = false,
  bool? cameraOn,
}) {
  Get.bottomSheet(
    SafeArea(
      child: Container(
        decoration: BoxDecoration(
          color: whitePure(Get.context!),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: (Get.mediaQuery.size.height * 0.72).clamp(320.0, 640.0),
          ),
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
              Flexible(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (onPause != null)
                        _HostOptionTile(
                          icon: paused
                              ? Icons.play_arrow_rounded
                              : Icons.pause_rounded,
                          title: paused ? 'Reanudar' : 'Pausar',
                          subtitle: paused
                              ? 'Continuar la transmisión'
                              : 'Pausar video temporalmente',
                          onTap: () {
                            Get.back();
                            onPause();
                          },
                        ),
                      if (onMic != null)
                        _HostOptionTile(
                          icon: muted
                              ? Icons.mic_off_rounded
                              : Icons.mic_rounded,
                          title: muted
                              ? 'Activar micrófono'
                              : 'Silenciar micrófono',
                          subtitle: muted
                              ? 'El mic está muteado'
                              : 'El mic está abierto',
                          onTap: () {
                            Get.back();
                            onMic();
                          },
                        ),
                      if (onCamera != null)
                        _HostOptionTile(
                          icon: (cameraOn ?? true)
                              ? Icons.videocam_rounded
                              : Icons.videocam_off_rounded,
                          title: (cameraOn ?? true)
                              ? 'Apagar cámara'
                              : 'Encender cámara',
                          subtitle: 'Control de video en vivo',
                          onTap: () {
                            Get.back();
                            onCamera();
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
                      if (onGiftSenders != null)
                        _HostOptionTile(
                          icon: Icons.card_giftcard_rounded,
                          title: 'Regalos recibidos',
                          subtitle: giftSendersSubtitle ??
                              'Ver quién te envió regalos',
                          onTap: () {
                            Get.back();
                            onGiftSenders();
                          },
                        ),
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
            ],
          ),
        ),
      ),
    ),
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
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

/// Sheet de filtros estilo FaceBetter (demo.facebetter.net).
Future<bool?> openLiveFiltersSheet({
  required RxBool beautyOn,
  required Future<void> Function() onApply,
  Rx<FaceFilterId>? selectedFilterId,
  List<FaceFilterEffect>? styleEffects,
  ValueChanged<FaceFilterId>? onStyleSelected,
  bool useDeepArFilters = false,
  RxnInt? deepArSelectedId,
  ValueChanged<DeepARFilters?>? onDeepArStyleSelected,
  /// Sliders nativos (0–100).
  RxDouble? whiten,
  RxDouble? smooth,
  RxDouble? rosy,
  RxDouble? sharpen,
  RxDouble? slimFace,
  RxDouble? bigEye,
}) {
  final effects = styleEffects ?? FaceFilterEffect.catalog;
  return Get.bottomSheet<bool>(
    SafeArea(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: FaceBetterStyleFiltersPanel(
          beautyOn: beautyOn,
          onApply: onApply,
          selectedFilterId: selectedFilterId,
          styleEffects: effects,
          onStyleSelected: onStyleSelected,
          useDeepArFilters: useDeepArFilters,
          deepArSelectedId: deepArSelectedId,
          onDeepArStyleSelected: onDeepArStyleSelected,
          whiten: whiten,
          smooth: smooth,
          rosy: rosy,
          sharpen: sharpen,
          slimFace: slimFace,
          bigEye: bigEye,
        ),
      ),
    ),
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black26,
  );
}

/// @Deprecated — usar [openLiveFiltersSheet].
Future<bool?> openLiveBeautySheet({
  required LivestreamScreenController? liveController,
  required RxDouble whiten,
  required RxDouble rosy,
  required RxDouble smooth,
  required RxDouble sharpen,
  required RxBool beautyOn,
  required Future<void> Function() onApply,
  Rx<FaceFilterId>? selectedFilterId,
  List<FaceFilterEffect>? styleEffects,
  ValueChanged<FaceFilterId>? onStyleSelected,
  bool showAcceptButton = false,
  bool useDeepArFilters = false,
  RxnInt? deepArSelectedId,
  ValueChanged<DeepARFilters?>? onDeepArStyleSelected,
}) {
  return openLiveFiltersSheet(
    beautyOn: beautyOn,
    onApply: onApply,
    selectedFilterId: selectedFilterId,
    styleEffects: styleEffects,
    onStyleSelected: onStyleSelected,
    useDeepArFilters: useDeepArFilters,
    deepArSelectedId: deepArSelectedId,
    onDeepArStyleSelected: onDeepArStyleSelected,
    whiten: whiten,
    smooth: smooth,
    rosy: rosy,
    sharpen: sharpen,
  );
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

/// Desplegable de tareas durante el LIVE (estilo Options).
void openLiveTasksMenu() {
  Get.bottomSheet(
    const _LiveTasksSheet(),
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
  );
}

class _LiveTasksSheet extends StatefulWidget {
  const _LiveTasksSheet();

  @override
  State<_LiveTasksSheet> createState() => _LiveTasksSheetState();
}

class _LiveTasksSheetState extends State<_LiveTasksSheet> {
  bool _loading = true;
  String? _error;
  List<_LiveTaskRow> _rows = const [];
  int _points = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await TaskService.instance.list();
      if (res.status == true && res.data != null) {
        final rows = <_LiveTaskRow>[];
        for (final cat in res.data!.categories) {
          for (final t in cat.tasks) {
            rows.add(_LiveTaskRow(
              title: t.titleKey.tr,
              status: t.status,
              progress: '${t.progressValue}/${t.targetValue}',
              points: t.withdrawalPointsReward,
            ));
          }
        }
        setState(() {
          _rows = rows;
          _points = res.data!.withdrawalPoints;
          _loading = false;
        });
      } else {
        setState(() {
          _error = res.message ?? LKey.somethingWentWrong.tr;
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.sizeOf(context).height * 0.55;
    return SafeArea(
      child: Container(
        constraints: BoxConstraints(maxHeight: h),
        decoration: BoxDecoration(
          color: whitePure(context),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: bgGrey(context),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            Text(
              LKey.tasks.tr,
              style: TextStyleCustom.unboundedSemiBold600(
                color: textDarkGrey(context),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${LKey.withdrawalPoints.tr}: $_points',
              style: TextStyleCustom.outFitRegular400(
                color: textLightGrey(context),
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 10),
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(24),
                child: LoaderWidget(),
              )
            else if (_error != null)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(_error!, textAlign: TextAlign.center),
              )
            else if (_rows.isEmpty)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'No hay tareas por ahora',
                  style: TextStyleCustom.outFitRegular400(
                    color: textLightGrey(context),
                    fontSize: 13,
                  ),
                ),
              )
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _rows.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final t = _rows[i];
                    final done = t.status == 'completed' || t.status == 'claimed';
                    return ListTile(
                      dense: true,
                      leading: Icon(
                        done
                            ? Icons.check_circle_rounded
                            : Icons.radio_button_unchecked,
                        color: done
                            ? const Color(0xFF22C55E)
                            : textLightGrey(context),
                        size: 22,
                      ),
                      title: Text(
                        t.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyleCustom.outFitMedium500(
                          color: textDarkGrey(context),
                          fontSize: 14,
                        ),
                      ),
                      subtitle: Text(
                        '${t.progress} · ${t.status}',
                        style: TextStyleCustom.outFitRegular400(
                          color: textLightGrey(context),
                          fontSize: 11,
                        ),
                      ),
                      trailing: Text(
                        '+${t.points}',
                        style: TextStyleCustom.outFitSemiBold600(
                          color: themeAccentSolid(context),
                          fontSize: 12,
                        ),
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                Get.back();
                Get.to(() => const TasksScreen());
              },
              child: Text(LKey.tasks.tr),
            ),
          ],
        ),
      ),
    );
  }
}

class _LiveTaskRow {
  final String title;
  final String status;
  final String progress;
  final int points;

  const _LiveTaskRow({
    required this.title,
    required this.status,
    required this.progress,
    required this.points,
  });
}
