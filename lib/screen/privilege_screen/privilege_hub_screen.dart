import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krimson/common/extensions/common_extension.dart';
import 'package:krimson/common/extensions/string_extension.dart';
import 'package:krimson/common/manager/app_role.dart';
import 'package:krimson/common/manager/session_manager.dart';
import 'package:krimson/common/service/api/privilege_service.dart';
import 'package:krimson/common/widget/custom_app_bar.dart';
import 'package:krimson/common/widget/custom_image.dart';
import 'package:krimson/common/widget/framed_avatar.dart';
import 'package:krimson/common/widget/loader_widget.dart';
import 'package:krimson/common/widget/no_data_widget.dart';
import 'package:krimson/common/widget/text_button_custom.dart';
import 'package:krimson/languages/catalog_i18n.dart';
import 'package:krimson/languages/languages_keys.dart';
import 'package:krimson/screen/leaderboard_screen/leaderboard_screen.dart';
import 'package:krimson/screen/level_screen/level_screen.dart';
import 'package:krimson/screen/tasks_screen/tasks_screen.dart';
import 'package:krimson/utilities/asset_res.dart';
import 'package:krimson/utilities/color_res.dart';
import 'package:krimson/utilities/style_res.dart';
import 'package:krimson/utilities/text_style_custom.dart';
import 'package:krimson/utilities/theme_res.dart';
import 'package:krimson/common/widget/podium_icon.dart';

class PrivilegeHubScreen extends StatefulWidget {
  const PrivilegeHubScreen({super.key});

  @override
  State<PrivilegeHubScreen> createState() => _PrivilegeHubScreenState();
}

class _PrivilegeHubScreenState extends State<PrivilegeHubScreen> {
  Map<String, dynamic>? hub;
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      hub = await PrivilegeService.instance.hub();
    } catch (e) {
      error = e.toString();
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = hub?['user'] as Map?;
    final svip = hub?['svip'] as Map?;
    final isSvip = user?['is_svip'] == 1 || user?['is_svip'] == true;

    return Scaffold(
      body: Column(
        children: [
          CustomAppBar(title: LKey.privilegeHub.tr),
          Expanded(
            child: loading
                ? const LoaderWidget()
                : error != null
                    ? Center(child: Text(error!))
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 30),
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                gradient: StyleRes.themeGradient,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(LKey.svip.tr,
                                            style: TextStyleCustom
                                                .unboundedSemiBold600(
                                                    color: whitePure(context),
                                                    fontSize: 22)),
                                        const SizedBox(height: 6),
                                        Text(
                                          isSvip
                                              ? LKey.youAreSvip.tr
                                              : (svip?['description']
                                                      ?.toString() ??
                                                  ''),
                                          style:
                                              TextStyleCustom.outFitRegular400(
                                                  color: whitePure(context),
                                                  fontSize: 13),
                                        ),
                                        if (!isSvip) ...[
                                          const SizedBox(height: 8),
                                          Text(
                                            '${LKey.level.tr} ${svip?['required_level'] ?? 5}+',
                                            style:
                                                TextStyleCustom.outFitMedium500(
                                                    color: whitePure(context),
                                                    fontSize: 13),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  Icon(Icons.workspace_premium,
                                      color: whitePure(context), size: 48),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            _HubTile(
                              icon: AssetRes.icVideoRequest,
                              title: LKey.myLevel.tr,
                              subtitle:
                                  '${LKey.level.tr} ${user?['level_number'] ?? 1}',
                              onTap: () {
                                final me = SessionManager.instance.getUser();
                                Get.to(() =>
                                    LevelScreen(userLevels: me?.getLevel));
                              },
                            ),
                            _HubTile(
                              icon: AssetRes.icGift,
                              title: LKey.dressingCenter.tr,
                              subtitle: (user?['unlock_dressing'] == 1)
                                  ? LKey.learnMore.tr
                                  : LKey.locked.tr,
                              onTap: () =>
                                  Get.to(() => const DressingCenterScreen()),
                            ),
                            if (AppRole.canAccessTasks())
                              _HubTile(
                                icon: AssetRes.icWallet,
                                title: LKey.tasks.tr,
                                subtitle:
                                    LKey.keepCompletingTasksToWithdraw.tr,
                                onTap: () =>
                                    Get.to(() => const TasksScreen()),
                              ),
                            _HubTile(
                              iconWidget: const PodiumIcon(
                                size: 28,
                                color: ColorRes.textDarkGrey,
                              ),
                              title: LKey.honorWall.tr,
                              subtitle: user?['honor_rank'] != null
                                  ? '#${user?['honor_rank']}'
                                  : LKey.leaderboard.tr,
                              onTap: () =>
                                  Get.to(() => const LeaderboardScreen()),
                            ),
                            _HubTile(
                              icon: AssetRes.icRanking,
                              title: LKey.leaderboard.tr,
                              subtitle: LKey.learnMore.tr,
                              onTap: () =>
                                  Get.to(() => const LeaderboardScreen()),
                            ),
                          ],
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

class _HubTile extends StatelessWidget {
  final String? icon;
  final Widget? iconWidget;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _HubTile({
    this.icon,
    this.iconWidget,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: bgLightGrey(context),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            iconWidget ??
                Image.asset(
                  icon!,
                  width: 28,
                  height: 28,
                  color: textDarkGrey(context),
                ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyleCustom.outFitMedium500(
                          color: textDarkGrey(context), fontSize: 15)),
                  Text(subtitle,
                      style: TextStyleCustom.outFitRegular400(
                          color: textLightGrey(context), fontSize: 12)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: textLightGrey(context)),
          ],
        ),
      ),
    );
  }
}

class DressingCenterScreen extends StatefulWidget {
  const DressingCenterScreen({super.key});

  @override
  State<DressingCenterScreen> createState() => _DressingCenterScreenState();
}

class _DressingCenterScreenState extends State<DressingCenterScreen> {
  List<DressingItemModel> items = [];
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      items = await PrivilegeService.instance.dressingCatalog();
    } catch (e) {
      error = e.toString();
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _equip(DressingItemModel item) async {
    if (item.id == null || !item.unlocked) return;
    try {
      final user = await PrivilegeService.instance.equipDressing(item.id!);
      if (user != null) {
        SessionManager.instance.setUser(user);
      }
      await _load();
    } catch (e) {
      Get.snackbar(LKey.dressingCenter.tr, e.toString());
    }
  }

  Color _parseColor(String? hex) {
    if (hex == null || hex.isEmpty) return Colors.grey;
    var h = hex.replaceAll('#', '');
    if (h.length == 6) h = 'FF$h';
    return Color(int.tryParse(h, radix: 16) ?? 0xFF888888);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          CustomAppBar(title: LKey.dressingCenter.tr),
          Expanded(
            child: loading
                ? const LoaderWidget()
                : error != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(error!, textAlign: TextAlign.center),
                        ),
                      )
                    : NoDataView(
                        showShow: items.isEmpty,
                        title: LKey.dressingCenter.tr,
                        description: LKey.noData.tr,
                        child: GridView.builder(
                          padding: const EdgeInsets.all(12),
                          gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  mainAxisExtent: 190,
                                  crossAxisSpacing: 10,
                                  mainAxisSpacing: 10),
                          itemCount: items.length,
                          itemBuilder: (context, index) {
                            final item = items[index];
                            return Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: bgLightGrey(context),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: item.equipped
                                      ? themeAccentSolid(context)
                                      : Colors.transparent,
                                  width: 1.5,
                                ),
                              ),
                              child: Column(
                                children: [
                                  _DressingPreview(item: item, parseColor: _parseColor),
                                  const SizedBox(height: 8),
                                  Text(CatalogI18n.dressingTitle(item.title),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyleCustom.outFitMedium500(
                                          color: textDarkGrey(context),
                                          fontSize: 13)),
                                  Text(
                                    '${LKey.level.tr} ${item.unlockLevel}',
                                    style: TextStyleCustom.outFitRegular400(
                                        color: textLightGrey(context),
                                        fontSize: 11),
                                  ),
                                  const Spacer(),
                                  TextButtonCustom(
                                    onTap: item.unlocked
                                        ? () => _equip(item)
                                        : () {},
                                    title: !item.unlocked
                                        ? LKey.locked.tr
                                        : item.equipped
                                            ? LKey.equipped.tr
                                            : LKey.equip.tr,
                                    backgroundColor: item.unlocked
                                        ? themeAccentSolid(context)
                                        : bgGrey(context),
                                    titleColor: item.unlocked
                                        ? whitePure(context)
                                        : textLightGrey(context),
                                    btnHeight: 32,
                                    fontSize: 12,
                                    horizontalMargin: 0,
                                    margin: EdgeInsets.zero,
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

class _DressingPreview extends StatelessWidget {
  const _DressingPreview({required this.item, required this.parseColor});

  final DressingItemModel item;
  final Color Function(String?) parseColor;

  @override
  Widget build(BuildContext context) {
    final image = (item.image ?? '').trim();
    if (image.isNotEmpty) {
      final me = SessionManager.instance.getUser();
      final isFrame = item.type == 'frame';
      return FramedAvatar.fitted(
        size: 72,
        image: me?.profilePhoto,
        fullName: me?.fullname ?? me?.username,
        frameImage: isFrame ? image : null,
        badgeImage: isFrame ? null : image,
        photoRatio: 0.62,
        photoOnTop: false,
      );
    }
    return Container(
      height: 64,
      width: 64,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: parseColor(item.colorHex), width: 4),
      ),
      alignment: Alignment.center,
      child: Text(
        (item.type ?? 'f')[0].toUpperCase(),
        style: TextStyleCustom.outFitBold700(
            color: textDarkGrey(context), fontSize: 18),
      ),
    );
  }
}

class HonorWallScreen extends StatefulWidget {
  const HonorWallScreen({super.key});

  @override
  State<HonorWallScreen> createState() => _HonorWallScreenState();
}

class _HonorWallScreenState extends State<HonorWallScreen> {
  List<HonorUserModel> users = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => loading = true);
    try {
      users = await PrivilegeService.instance.honorWall();
    } catch (_) {
      users = [];
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          CustomAppBar(title: LKey.honorWall.tr),
          Expanded(
            child: loading
                ? const LoaderWidget()
                : NoDataView(
                    showShow: users.isEmpty,
                    title: LKey.honorWall.tr,
                    description: LKey.noData.tr,
                    child: ListView.separated(
                      padding: const EdgeInsets.all(12),
                      itemCount: users.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final u = users[index];
                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: bgLightGrey(context),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Text('#${index + 1}',
                                  style: TextStyleCustom.unboundedMedium500(
                                      color: themeAccentSolid(context),
                                      fontSize: 14)),
                              const SizedBox(width: 10),
                              CustomImage(
                                size: const Size(44, 44),
                                image: u.profilePhoto?.addBaseURL(),
                                fullName: u.fullname ?? u.username,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(u.fullname ?? u.username ?? '-',
                                        style: TextStyleCustom.outFitMedium500(
                                            color: textDarkGrey(context),
                                            fontSize: 14)),
                                    Text(
                                      '${LKey.level.tr} ${u.levelNumber}'
                                      '${u.isSvip == 1 ? ' · ${LKey.svip.tr}' : ''}',
                                      style: TextStyleCustom.outFitRegular400(
                                          color: textLightGrey(context),
                                          fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                              Image.asset(AssetRes.icCoin,
                                  width: 16, height: 16),
                              const SizedBox(width: 4),
                              Text(u.coinCollectedLifetime.numberFormat,
                                  style: TextStyleCustom.outFitRegular400(
                                      color: textDarkGrey(context),
                                      fontSize: 13)),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
