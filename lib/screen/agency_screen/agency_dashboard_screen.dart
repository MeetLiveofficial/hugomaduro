import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krimson/common/extensions/common_extension.dart';
import 'package:krimson/common/widget/brand_wash_bg.dart';
import 'package:krimson/common/widget/custom_app_bar.dart';
import 'package:krimson/common/widget/custom_image.dart';
import 'package:krimson/common/widget/text_button_custom.dart';
import 'package:krimson/languages/languages_keys.dart';
import 'package:krimson/model/agency/agency_dashboard_model.dart';
import 'package:krimson/screen/agency_screen/agency_home_controller.dart';
import 'package:krimson/screen/agency_screen/agency_worker_detail_screen.dart';
import 'package:krimson/screen/dashboard_screen/dashboard_screen_controller.dart';
import 'package:krimson/screen/message_screen/message_screen.dart';
import 'package:krimson/screen/settings_screen/settings_screen.dart';
import 'package:krimson/utilities/asset_res.dart';
import 'package:krimson/utilities/color_res.dart';
import 'package:krimson/utilities/text_style_custom.dart';

class AgencyDashboardScreen extends StatefulWidget {
  const AgencyDashboardScreen({super.key});

  @override
  State<AgencyDashboardScreen> createState() => _AgencyDashboardScreenState();
}

class _AgencyDashboardScreenState extends State<AgencyDashboardScreen> {
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    Get.put(DashboardScreenController());
  }

  @override
  Widget build(BuildContext context) {
    final dash = Get.find<DashboardScreenController>();
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const BrandWashBg(vivid: false),
          IndexedStack(
            index: _tab,
            children: const [
              AgencyHomeScreen(),
              MessageScreen(),
              SettingsScreen(showBack: false),
            ],
          ),
        ],
      ),
      bottomNavigationBar: Obx(() {
        final unread = dash.chatUnReadCount.value;
        return BottomNavigationBar(
          currentIndex: _tab,
          onTap: (i) => setState(() => _tab = i),
          type: BottomNavigationBarType.fixed,
          backgroundColor: ColorRes.whitePure,
          selectedItemColor: ColorRes.crimson,
          unselectedItemColor: Colors.black45,
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.groups_rounded),
              label: LKey.agencyStreamers.tr,
            ),
            BottomNavigationBarItem(
              icon: Badge(
                isLabelVisible: unread > 0,
                label: Text(unread > 99 ? '99+' : '$unread'),
                child: const Icon(Icons.chat_bubble_rounded),
              ),
              label: LKey.chats.tr,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.settings_rounded),
              label: LKey.settings.tr,
            ),
          ],
        );
      }),
    );
  }
}

class AgencyHomeScreen extends StatelessWidget {
  const AgencyHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.put(AgencyHomeController());
    return Column(
      children: [
        CustomAppBar(
          title: LKey.agencyDashboardTitle.tr,
          showBack: false,
          subTitle: LKey.agencyYourStreamers.tr,
          rowWidget: IconButton(
            onPressed: () => _openCreate(context, c),
            icon: const Icon(Icons.person_add_alt_1_rounded,
                color: Colors.white),
          ),
        ),
        Expanded(
          child: Obx(() {
            if (c.isLoading.value && c.workers.isEmpty) {
              return const Center(
                child: CircularProgressIndicator(color: ColorRes.crimson),
              );
            }
            final invite = _AgencyInviteCard(controller: c);
            if (c.workers.isEmpty) {
              return RefreshIndicator(
                onRefresh: c.loadWorkers,
                child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  invite,
                  const SizedBox(height: 24),
                  const Icon(Icons.groups_outlined,
                      size: 48, color: Colors.white54),
                  const SizedBox(height: 12),
                  Text(
                    LKey.agencyNoStreamers.tr,
                    textAlign: TextAlign.center,
                    style: TextStyleCustom.outFitSemiBold600(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    LKey.agencyCreateStreamerHint.tr,
                    textAlign: TextAlign.center,
                    style: TextStyleCustom.outFitRegular400(
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: TextButtonCustom(
                      title: LKey.agencyCreateStreamer.tr,
                      onTap: () => _openCreate(context, c),
                      gradient: true,
                      btnWidth: 200,
                    ),
                  ),
                ],
              ),
              );
            }
            final totals = c.dashboard.value.totals;
            return RefreshIndicator(
              onRefresh: c.loadWorkers,
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                itemCount: c.workers.length + 2,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) {
                  if (i == 0) return invite;
                  if (i == 1) {
                    return _AgencyTotalsCard(
                      wallet: c.dashboard.value.agencyWallet,
                      totals: totals,
                    );
                  }
                  return _WorkerTile(worker: c.workers[i - 2]);
                },
              ),
            );
          }),
        ),
      ],
    );
  }

  Future<void> _openCreate(
      BuildContext context, AgencyHomeController c) async {
    final fullname = TextEditingController();
    final email = TextEditingController();
    final password = TextEditingController();
    final username = TextEditingController();
    final ok = await Get.dialog<bool>(
      AlertDialog(
        backgroundColor: ColorRes.carbon,
        title: Text(
          LKey.agencyCreateStreamer.tr,
          style: TextStyleCustom.outFitSemiBold600(
            color: Colors.white,
            fontSize: 18,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _field(fullname, LKey.fullName.tr),
              const SizedBox(height: 10),
              _field(email, LKey.enterYourEmail.tr,
                  keyboard: TextInputType.emailAddress),
              const SizedBox(height: 10),
              _field(password, LKey.password.tr, obscure: true),
              const SizedBox(height: 10),
              _field(username, LKey.username.tr),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text(LKey.cancel.tr),
          ),
          Obx(() => TextButton(
                onPressed: c.creating.value
                    ? null
                    : () async {
                        final created = await c.createWorker(
                          fullname: fullname.text,
                          identity: email.text,
                          password: password.text,
                          username: username.text,
                        );
                        if (created) Get.back(result: true);
                      },
                child: c.creating.value
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(LKey.createAccount.tr),
              )),
        ],
      ),
    );
    fullname.dispose();
    email.dispose();
    password.dispose();
    username.dispose();
    if (ok == true) {
      // lista ya actualizada
    }
  }

  Widget _field(
    TextEditingController controller,
    String hint, {
    bool obscure = false,
    TextInputType? keyboard,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboard,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white54),
        filled: true,
        fillColor: Colors.white12,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class _AgencyInviteCard extends StatelessWidget {
  const _AgencyInviteCard({required this.controller});

  final AgencyHomeController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final code = controller.dashboard.value.agencyCode;
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              LKey.agencyInviteTitle.tr,
              style: TextStyleCustom.outFitSemiBold600(
                color: Colors.white,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              LKey.agencyInviteHint.tr,
              style: TextStyleCustom.outFitRegular400(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.22),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                code.isEmpty ? '—' : code,
                textAlign: TextAlign.center,
                style: TextStyleCustom.unboundedBlack900(
                  color: ColorRes.accentPeach,
                  fontSize: 20,
                ).copyWith(letterSpacing: 2),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextButtonCustom(
                    title: LKey.copyAgencyCode.tr,
                    onTap: controller.copyAgencyCode,
                    gradient: true,
                    btnHeight: 42,
                    horizontalMargin: 0,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextButtonCustom(
                    title: LKey.copyInviteLink.tr,
                    onTap: controller.copyInviteLink,
                    gradient: false,
                    btnHeight: 42,
                    horizontalMargin: 0,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }
}

class _AgencyTotalsCard extends StatelessWidget {
  final int wallet;
  final AgencyDashboardTotals totals;

  const _AgencyTotalsCard({required this.wallet, required this.totals});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            LKey.agencyWalletHint.tr,
            style: TextStyleCustom.outFitRegular400(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _miniStat(LKey.balance.tr, wallet),
              const SizedBox(width: 8),
              _miniStat(LKey.agencyToday.tr, totals.agencyEarnedToday),
              const SizedBox(width: 8),
              _miniStat(
                  LKey.agencyLifetime.tr, totals.agencyEarnedLifetime),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _miniStat(
                  LKey.agencyStreamerEarned.tr, totals.streamerEarnedLifetime,
                  flex: 2),
              const SizedBox(width: 8),
              _miniStat(
                  '${LKey.agencyStreamerEarned.tr} · ${LKey.agencyToday.tr}',
                  totals.streamerEarnedToday),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniStat(String label, int coins, {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyleCustom.outFitRegular400(
                color: Colors.white60,
                fontSize: 10,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Image.asset(AssetRes.icCoin, width: 12, height: 12),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    coins.fullNumberFormat,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyleCustom.outFitSemiBold600(
                      color: Colors.white,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _WorkerTile extends StatelessWidget {
  final AgencyWorker worker;

  const _WorkerTile({required this.worker});

  @override
  Widget build(BuildContext context) {
    final user = worker.user;
    final stats = worker.stats;
    final photo = (user.profilePhoto ?? '').trim();
    return InkWell(
      onTap: () => Get.to(() => AgencyWorkerDetailScreen(worker: worker)),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white24),
        ),
        child: Row(
          children: [
            CustomImage(
              size: const Size(44, 44),
              image: photo.isEmpty ? null : photo,
              fullName: user.displayName,
              radius: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.displayName,
                    style: TextStyleCustom.outFitSemiBold600(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    user.handle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyleCustom.outFitRegular400(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _earnChip(LKey.agencyStreamerEarned.tr,
                          stats.streamerEarnedLifetime),
                      const SizedBox(width: 6),
                      _earnChip(
                          LKey.agencyYourShare.tr, stats.agencyEarnedLifetime),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white54),
          ],
        ),
      ),
    );
  }

  Widget _earnChip(String label, int coins) {
    return Flexible(
      child: Text(
        '$label ${coins.fullNumberFormat}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyleCustom.outFitRegular400(
          color: ColorRes.accentPeach,
          fontSize: 11,
        ),
      ),
    );
  }
}
