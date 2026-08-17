import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:proste_indexed_stack/proste_indexed_stack.dart';
import 'package:krimson/common/manager/app_role.dart';
import 'package:krimson/common/manager/session_manager.dart';
import 'package:krimson/common/widget/banner_ads_custom.dart';
import 'package:krimson/common/widget/live_tv_icon.dart';
import 'package:krimson/model/user_model/user_model.dart';
import 'package:krimson/screen/dashboard_screen/dashboard_screen_controller.dart';
import 'package:krimson/screen/explore_screen/explore_screen.dart';
import 'package:krimson/screen/home_screen/unified_home_screen.dart';
import 'package:krimson/screen/live_stream/live_stream_search_screen/live_stream_search_screen.dart';
import 'package:krimson/screen/match_screen/match_screen.dart';
import 'package:krimson/screen/match_screen/match_screen_controller.dart';
import 'package:krimson/screen/message_screen/message_screen.dart';
import 'package:krimson/screen/profile_screen/client_profile_screen.dart';
import 'package:krimson/screen/profile_screen/profile_screen.dart';
import 'package:krimson/utilities/color_res.dart';
import 'package:krimson/utilities/style_res.dart';
import 'package:krimson/utilities/text_style_custom.dart';
import 'package:krimson/utilities/theme_res.dart';

class DashboardScreen extends StatefulWidget {
  final User? myUser;

  const DashboardScreen({super.key, this.myUser});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late final List<IndexedStackChild> _pages;
  late final bool _isClient;
  User? get myUser => widget.myUser;

  @override
  void initState() {
    super.initState();
    _isClient = AppRole.isClient(widget.myUser);
    _pages = [
      IndexedStackChild(
          child: UnifiedHomeScreen(myUser: widget.myUser), preload: true),
      IndexedStackChild(child: const ExploreScreen(), preload: true),
      IndexedStackChild(
          child: _isClient
              ? const MatchScreen(asTab: true)
              : const LiveStreamSearchScreen(),
          preload: false),
      IndexedStackChild(child: const MessageScreen(), preload: true),
      IndexedStackChild(
          child: _isClient
              ? ClientProfileScreen(user: widget.myUser)
              : ProfileScreen(
                  isDashBoard: true,
                  user: widget.myUser,
                  isTopBarVisible: false),
          preload: true),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(DashboardScreenController());
    return Obx(() {
      final onLiveTab = controller.selectedPageIndex.value ==
          DashboardScreenController.tabLive;
      final hideBanner = controller.selectedPageIndex.value ==
              DashboardScreenController.tabHome &&
          (controller.homeTabMode.value == HomeTabMode.reels ||
              controller.homeTabMode.value == HomeTabMode.live);
      final hideBannerMatch = _isClient && onLiveTab;
      return Scaffold(
        backgroundColor: ColorRes.bgLightGrey,
        extendBody: true,
        // En Go Live / Match el teclado no debe empujar el layout.
        resizeToAvoidBottomInset: !onLiveTab,
        body: Column(
          children: [
            Expanded(
              child: ProsteIndexedStack(
                index: controller.selectedPageIndex.value,
                children: _pages,
              ),
            ),
            if (!hideBanner && !hideBannerMatch) const BannerAdsCustom(),
          ],
        ),
        bottomNavigationBar: _buildBottomNavigationBar(context, controller),
      );
    });
  }

  static const Color _navBarBg = ColorRes.carbon;

  Widget _buildBottomNavigationBar(
      BuildContext context, DashboardScreenController controller) {
    return Obx(() {
      PostUploadingProgress postUpload = controller.postProgress.value;
      bool isPostUploading =
          postUpload.uploadType == UploadType.none ? false : true;
      final roleUser = SessionManager.instance.getUser() ?? controller.user;

      final items = <Widget>[];
      for (var i = 0; i < controller.bottomIconList.length; i++) {
        // Cliente: Match en el centro (sustituye Go Live).
        if (AppRole.isClient(roleUser) &&
            i == DashboardScreenController.tabLive) {
          items.add(_buildMatchNavItem(controller));
          continue;
        }
        if (AppRole.isStreamer(roleUser) &&
            i == DashboardScreenController.tabHome) {
          continue;
        }
        items.add(_buildBottomNavItem(controller, i));
        if (AppRole.isStreamer(roleUser) &&
            i == DashboardScreenController.tabLive) {
          items.add(_buildStreamerMatchNavItem());
        }
      }

      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isPostUploading)
            Container(
              height: 28,
              margin: const EdgeInsets.fromLTRB(36, 0, 36, 8),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    height: 28,
                    decoration: BoxDecoration(
                      gradient: StyleRes.themeGradient,
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: LayoutBuilder(builder: (context, constraints) {
                      double progress =
                          (constraints.maxWidth * postUpload.progress) / 100;
                      return AnimatedContainer(
                        height: 28,
                        width: constraints.maxWidth - progress,
                        duration: const Duration(milliseconds: 250),
                        decoration: BoxDecoration(
                          color: textDarkGrey(context),
                          borderRadius: BorderRadius.circular(14),
                        ),
                      );
                    }),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (postUpload.uploadType != UploadType.error)
                        Text('${postUpload.progress.toInt()}%',
                            style: TextStyleCustom.outFitMedium500(
                              color: whitePure(context),
                              fontSize: 14,
                            )),
                      Text(
                          ' ${postUpload.uploadType.title(postUpload.type)}',
                          style: TextStyleCustom.outFitLight300(
                              color: whitePure(context), fontSize: 13)),
                    ],
                  ),
                ],
              ),
            ),
          SafeArea(
            top: false,
            minimum: const EdgeInsets.only(bottom: 10),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.sizeOf(context).width - 20,
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Container(
                      height: 56,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: _navBarBg,
                        borderRadius: BorderRadius.circular(32),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.35),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: items,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    });
  }

  Widget _navHitTarget({
    required bool selected,
    required Color accent,
    required VoidCallback onTap,
    required Widget child,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        width: 48,
        height: 56,
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            width: selected ? 44 : 36,
            height: selected ? 34 : 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: selected ? StyleRes.themeGradient : null,
              color: selected ? null : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: accent.withValues(alpha: 0.55),
                        blurRadius: 12,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : null,
            ),
            child: child,
          ),
        ),
      ),
    );
  }

  Widget _navAssetIcon(String asset, {required Color color, double size = 26}) {
    return ColorFiltered(
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
      child: Image.asset(asset, height: size, width: size),
    );
  }

  /// Streamer: Match con clientes (abre pantalla, no sustituye Go Live).
  Widget _buildStreamerMatchNavItem() {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => Get.to(() => const MatchScreen()),
      child: SizedBox(
        width: 58,
        height: 56,
        child: Center(
          child: Container(
            width: 46,
            height: 46,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: StyleRes.themeGradient,
              boxShadow: [
                BoxShadow(
                  color: ColorRes.crimson.withValues(alpha: 0.55),
                  blurRadius: 14,
                  spreadRadius: 1,
                  offset: const Offset(0, 3),
                ),
                BoxShadow(
                  color: ColorRes.mlPurple.withValues(alpha: 0.4),
                  blurRadius: 22,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Icon(
              Icons.favorite_rounded,
              size: 24,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  /// Cliente: Match — círculo rojo llamativo (siempre destacado, no pill “activo”).
  Widget _buildMatchNavItem(DashboardScreenController controller) {
    // Registrar ya el controller para que Obx siempre lea un .obs
    // (si no, GetX muestra error y desborda la barra).
    final matchCtrl = Get.isRegistered<MatchScreenController>()
        ? Get.find<MatchScreenController>()
        : Get.put(MatchScreenController());
    return Obx(() {
      final busy = matchCtrl.isMatching.value;
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => controller.onChanged(DashboardScreenController.tabLive),
        child: SizedBox(
          width: 58,
          height: 56,
          child: Center(
            child: Container(
              width: 46,
              height: 46,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: StyleRes.themeGradient,
                boxShadow: [
                  BoxShadow(
                    color: ColorRes.crimson.withValues(alpha: 0.55),
                    blurRadius: 14,
                    spreadRadius: 1,
                    offset: const Offset(0, 3),
                  ),
                  BoxShadow(
                    color: ColorRes.mlPurple.withValues(alpha: 0.4),
                    blurRadius: 22,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: busy
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(
                      Icons.favorite_rounded,
                      size: 24,
                      color: Colors.white,
                    ),
            ),
          ),
        ),
      );
    });
  }

  Widget _buildBottomNavItem(
      DashboardScreenController controller, int index) {
    return Obx(() {
      final isSelected = controller.selectedPageIndex.value == index;
      final scaleValue = isSelected ? controller.scaleValue.value : 1.0;
      final accent = ColorRes.navIconColors[
          index.clamp(0, ColorRes.navIconColors.length - 1)];
      final iconColor = isSelected
          ? Colors.white
          : accent.withValues(alpha: 0.85);

      return _navHitTarget(
        selected: isSelected,
        accent: accent,
        onTap: () => controller.onChanged(index),
        child: AnimatedScale(
          scale: scaleValue,
          duration: const Duration(milliseconds: 250),
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              if (index == DashboardScreenController.tabLive)
                LiveTvIcon(size: 26, color: iconColor)
              else
                _navAssetIcon(
                  controller.bottomIconList[index],
                  color: iconColor,
                ),
              if (index == DashboardScreenController.tabChat)
                _buildUnreadDot(controller),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildUnreadDot(DashboardScreenController controller) {
    return Obx(() {
      final count = controller.unReadCount.value;
      if (count <= 0) return const SizedBox.shrink();
      return Positioned(
        right: -2,
        bottom: -2,
        child: Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(
            color: ColorRes.likeRed,
            shape: BoxShape.circle,
            border: Border.all(color: _navBarBg, width: 1.5),
          ),
        ),
      );
    });
  }
}
