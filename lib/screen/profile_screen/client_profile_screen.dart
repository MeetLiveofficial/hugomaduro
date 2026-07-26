import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krimson/common/extensions/common_extension.dart';
import 'package:krimson/common/extensions/string_extension.dart';
import 'package:krimson/common/manager/session_manager.dart';
import 'package:krimson/common/service/api/user_service.dart';
import 'package:krimson/common/widget/custom_image.dart';
import 'package:krimson/common/widget/full_name_with_blue_tick.dart';
import 'package:krimson/common/widget/text_button_custom.dart';
import 'package:krimson/languages/languages_keys.dart';
import 'package:krimson/model/user_model/user_model.dart';
import 'package:krimson/screen/coin_wallet_screen/coin_wallet_screen.dart';
import 'package:krimson/screen/level_screen/level_screen.dart';
import 'package:krimson/screen/recharge_history_screen/recharge_history_screen.dart';
import 'package:krimson/screen/settings_screen/settings_screen.dart';
import 'package:krimson/utilities/asset_res.dart';
import 'package:krimson/utilities/color_res.dart';
import 'package:krimson/utilities/level_avatar_style.dart';
import 'package:krimson/utilities/style_res.dart';
import 'package:krimson/utilities/text_style_custom.dart';
import 'package:krimson/utilities/theme_res.dart';

/// Perfil del rol client: centrado en saldo y recarga.
class ClientProfileScreen extends StatefulWidget {
  final User? user;

  const ClientProfileScreen({super.key, this.user});

  @override
  State<ClientProfileScreen> createState() => _ClientProfileScreenState();
}

class _ClientProfileScreenState extends State<ClientProfileScreen> {
  late Rx<User?> userData;

  @override
  void initState() {
    super.initState();
    userData = (widget.user ?? SessionManager.instance.getUser()).obs;
    _refresh();
  }

  Future<void> _refresh() async {
    final id = userData.value?.id ?? SessionManager.instance.getUserID();
    try {
      final fresh = await UserService.instance.fetchUserDetails(userId: id);
      if (fresh != null) {
        // Estoy en la app: presencia ACTIVE en mi perfil.
        if (fresh.id == SessionManager.instance.getUserID()) {
          fresh.isActive = 1;
        }
        userData.value = fresh;
        SessionManager.instance.setUser(fresh);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Obx(() {
          final user = userData.value;
          if (user == null) {
            return const Center(child: CircularProgressIndicator());
          }
          final coins = (user.coinWallet ?? 0).toInt();
          final isMe = user.id == SessionManager.instance.getUserID();
          // En mi propio perfil, si estoy en la app soy ACTIVE.
          final isPresent = isMe || user.isActive == 1 || user.isLive == 1;

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              children: [
                Row(
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        LevelAvatarRing(
                          user: user,
                          padding: 3.5,
                          child: CustomImage(
                            size: const Size(72, 72),
                            image: user.profilePhoto?.addBaseURL(),
                            fullName: user.fullname ?? user.username,
                            radius: 36,
                            strokeWidth: 2,
                            strokeColor: scaffoldBackgroundColor(context),
                          ),
                        ),
                        Positioned(
                          right: 2,
                          bottom: 2,
                          child: Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              gradient: isPresent
                                  ? const LinearGradient(
                                      colors: [
                                        ColorRes.softSalmon,
                                        ColorRes.coralRed,
                                      ],
                                    )
                                  : null,
                              color: isPresent
                                  ? null
                                  : const Color(0xFF9CA3AF),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: scaffoldBackgroundColor(context),
                                width: 2.5,
                              ),
                              boxShadow: isPresent
                                  ? [
                                      BoxShadow(
                                        color: ColorRes.brandPink
                                            .withValues(alpha: 0.55),
                                        blurRadius: 8,
                                      ),
                                    ]
                                  : null,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          FullNameWithBlueTick(
                            username: user.fullname ?? user.username,
                            isVerify: user.isVerify,
                            fontSize: 16,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '@${user.username ?? ''}',
                            style: TextStyleCustom.outFitRegular400(
                              color: textLightGrey(context),
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              gradient: isPresent
                                  ? const LinearGradient(
                                      colors: [
                                        ColorRes.softSalmon,
                                        ColorRes.coralRed,
                                      ],
                                    )
                                  : null,
                              color: isPresent
                                  ? null
                                  : ColorRes.bgSoft.withValues(alpha: 0.9),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isPresent
                                    ? Colors.white24
                                    : Colors.white24,
                              ),
                              boxShadow: isPresent
                                  ? [
                                      BoxShadow(
                                        color: ColorRes.brandPink
                                            .withValues(alpha: 0.45),
                                        blurRadius: 10,
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 7,
                                  height: 7,
                                  decoration: BoxDecoration(
                                    color: isPresent
                                        ? Colors.white
                                        : const Color(0xFF9CA3AF),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  isPresent ? 'ACTIVE' : 'INACTIVE',
                                  style: TextStyleCustom.outFitMedium500(
                                    color: isPresent
                                        ? Colors.white
                                        : const Color(0xFF9CA3AF),
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Get.to(
                        () => SettingsScreen(
                          onUpdateUser: (u) {
                            if (u != null) {
                              userData.value = u;
                              SessionManager.instance.setUser(u);
                            }
                          },
                        ),
                      ),
                      icon: Image.asset(
                        AssetRes.icEdit,
                        height: 22,
                        width: 22,
                        color: textDarkGrey(context),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
                  decoration: BoxDecoration(
                    gradient: StyleRes.themeGradient,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        LKey.coinWallet.tr,
                        style: TextStyleCustom.outFitMedium500(
                          color: whitePure(context).withValues(alpha: 0.9),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Image.asset(AssetRes.icCoin, height: 28, width: 28),
                          const SizedBox(width: 10),
                          Text(
                            coins.numberFormat,
                            style: TextStyleCustom.unboundedSemiBold600(
                              color: whitePure(context),
                              fontSize: 28,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      TextButtonCustom(
                        onTap: () => Get.to(() => const CoinWalletScreen()),
                        title: LKey.recharge.tr,
                        backgroundColor: whitePure(context),
                        titleColor: themeAccentSolid(context),
                        btnHeight: 46,
                        fontSize: 15,
                        horizontalMargin: 0,
                        margin: EdgeInsets.zero,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                _MenuTile(
                  icon: AssetRes.icWallet,
                  title: LKey.coinWallet.tr,
                  onTap: () => Get.to(() => const CoinWalletScreen()),
                ),
                _MenuTile(
                  icon: AssetRes.icGift,
                  title: 'Historial de Recargas',
                  onTap: () => Get.to(() => const RechargeHistoryScreen()),
                ),
                _MenuTile(
                  icon: AssetRes.icCrown,
                  title: LKey.myLevel.tr,
                  onTap: () => Get.to(() => const LevelScreen()),
                ),
                _MenuTile(
                  icon: AssetRes.icEdit,
                  title: LKey.settings.tr,
                  onTap: () => Get.to(
                    () => SettingsScreen(
                      onUpdateUser: (u) {
                        if (u != null) {
                          userData.value = u;
                          SessionManager.instance.setUser(u);
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final String icon;
  final String title;
  final VoidCallback onTap;

  const _MenuTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: bgLightGrey(context),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Image.asset(icon, height: 22, width: 22, color: textDarkGrey(context)),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: TextStyleCustom.outFitMedium500(
                    color: textDarkGrey(context),
                    fontSize: 15,
                  ),
                ),
              ),
              Image.asset(
                AssetRes.icRightArrow,
                height: 16,
                width: 16,
                color: textLightGrey(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
