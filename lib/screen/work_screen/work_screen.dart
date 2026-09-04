import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krimson/common/widget/framed_avatar.dart';
import 'package:krimson/common/widget/loader_widget.dart';
import 'package:krimson/common/extensions/common_extension.dart';
import 'package:krimson/languages/languages_keys.dart';
import 'package:krimson/model/work/streamer_work_stats_model.dart';
import 'package:krimson/model/user_model/streamer_average.dart';
import 'package:krimson/screen/leaderboard_screen/leaderboard_screen.dart';
import 'package:krimson/screen/tasks_screen/tasks_screen.dart';
import 'package:krimson/screen/wallet_history_screen/wallet_history_screen.dart';
import 'package:krimson/screen/withdrawals_screen/withdrawals_screen.dart';
import 'package:krimson/screen/work_screen/work_screen_controller.dart';
import 'package:krimson/utilities/asset_res.dart';
import 'package:krimson/utilities/color_res.dart';
import 'package:krimson/utilities/style_res.dart';
import 'package:krimson/utilities/text_style_custom.dart';

/// Panel de Trabajo del streamer: métricas de llamadas, nivel semanal e ingresos.
class WorkScreen extends StatelessWidget {
  const WorkScreen({super.key});

  static const _bg = ColorRes.bgVoid;
  static const _card = ColorRes.bgElevated;
  static const _pink = ColorRes.mauve;
  static const _gold = ColorRes.accentPeach;
  static const _cyan = ColorRes.accentRose;
  static const _green = Color(0xFF34D399);
  static const _yellow = ColorRes.accentPeach;

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(WorkScreenController());

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Obx(() {
          if (controller.pageLoading.value && controller.stats.value == null) {
            return const Center(child: LoaderWidget());
          }
          final data = controller.stats.value;
          if (data == null) {
            return Center(
              child: TextButton(
                onPressed: controller.loadStats,
                child: Text(LKey.refresh.tr,
                    style: TextStyleCustom.outFitMedium500(
                        color: Colors.white, fontSize: 15)),
              ),
            );
          }
          return RefreshIndicator(
            color: _pink,
            backgroundColor: _card,
            onRefresh: controller.loadStats,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
              children: [
                _Header(data: data, controller: controller),
                const SizedBox(height: 12),
                const _RankingsEntry(),
                const SizedBox(height: 16),
                _MainGrid(data: data),
                const SizedBox(height: 12),
                _PerfRow(data: data),
                const SizedBox(height: 16),
                _EarningsCard(data: data),
                const SizedBox(height: 16),
                _CallPricingCard(data: data, controller: controller),
                const SizedBox(height: 16),
                _TasksSection(),
                if (controller.showDetail.value) ...[
                  const SizedBox(height: 16),
                  _DetailPanel(data: data),
                  const SizedBox(height: 16),
                  _BenefitsCard(benefits: data.benefits),
                ],
                const SizedBox(height: 20),
                Align(
                  alignment: Alignment.centerRight,
                  child: _StatusPill(isActive: data.user.isActive == 1),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.data, required this.controller});

  final StreamerWorkStats data;
  final WorkScreenController controller;

  @override
  Widget build(BuildContext context) {
    final grade = data.weeklyLevel.grade;
    final levelNum = data.user.levelNumber;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconButton(
              onPressed: Get.back,
              icon: const Icon(Icons.arrow_back_ios_new,
                  color: Colors.white, size: 18),
            ),
            FramedAvatar.fitted(
              size: 72,
              image: data.user.profilePhoto,
              fullName: data.user.fullname,
              localFrame: AssetRes.streamerBadgeForGrade(grade),
              photoRatio: AssetRes.streamerBadgePhotoRatio(grade),
              photoOffset: AssetRes.streamerBadgePhotoOffset(grade, outer: 72),
              photoOnTop: false,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  gradient: StyleRes.themeGradient,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: ColorRes.coralRed.withValues(alpha: 0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Text(
                  [
                    '${LKey.level.tr} $levelNum',
                    if (data.average != null)
                      '${LKey.streamerAverage.tr} ${data.average!.avg.toStringAsFixed(0)}/100',
                  ].join(' · '),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyleCustom.outFitSemiBold600(
                    color: Colors.white,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
            TextButton(
              onPressed: controller.toggleDetail,
              child: Text(
                '${LKey.detail.tr} >',
                style: TextStyleCustom.outFitMedium500(
                  color: WorkScreen._yellow,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          data.weeklyLevel.goalMet
              ? LKey.callGoalMet.tr
              : LKey.callGoalNotMet.tr,
          style: TextStyleCustom.outFitMedium500(
            color: Colors.white.withValues(alpha: 0.9),
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 8),
        _GradeProgress(
          grades: data.weeklyLevel.grades,
          current: grade,
          progress: data.weeklyLevel.progress,
        ),
        if (data.average != null) ...[
          const SizedBox(height: 12),
          _AverageBreakdown(avg: data.average!),
        ],
      ],
    );
  }
}

class _RankingsEntry extends StatelessWidget {
  const _RankingsEntry();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: WorkScreen._card,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: () => Get.to(() => const LeaderboardScreen()),
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Image.asset(
                AssetRes.icRanking,
                width: 26,
                height: 26,
                color: WorkScreen._gold,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.emoji_events_outlined,
                  color: WorkScreen._gold,
                  size: 26,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  LKey.leaderboard.tr,
                  style: TextStyleCustom.outFitSemiBold600(
                    color: Colors.white,
                    fontSize: 15,
                  ),
                ),
              ),
              Text(
                '>',
                style: TextStyleCustom.outFitMedium500(
                  color: WorkScreen._yellow,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GradeProgress extends StatelessWidget {
  const _GradeProgress({
    required this.grades,
    required this.current,
    required this.progress,
  });

  final List<String> grades;
  final String current;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (final g in grades)
              Column(
                children: [
                  Image.asset(
                    AssetRes.streamerBadgeForGrade(g) ?? AssetRes.streamerBadgeNew,
                    width: g == current ? 36 : 26,
                    height: g == current ? 36 : 26,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Text(
                      g,
                      style: TextStyleCustom.outFitSemiBold600(
                        color: g == current
                            ? WorkScreen._yellow
                            : Colors.white.withValues(alpha: 0.45),
                        fontSize: 11,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    g,
                    style: TextStyleCustom.outFitSemiBold600(
                      color: g == current
                          ? WorkScreen._yellow
                          : Colors.white.withValues(alpha: 0.45),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: progress.clamp(0.05, 1),
            minHeight: 8,
            backgroundColor: Colors.white12,
            valueColor: const AlwaysStoppedAnimation(WorkScreen._pink),
          ),
        ),
      ],
    );
  }
}

class _AverageBreakdown extends StatelessWidget {
  const _AverageBreakdown({required this.avg});

  final StreamerAverage avg;

  @override
  Widget build(BuildContext context) {
    final rows = [
      (LKey.avgCoins.tr, avg.coins, Icons.monetization_on_outlined),
      (LKey.avgCalls.tr, avg.calls, Icons.call_outlined),
      (LKey.avgLive.tr, avg.live, Icons.sensors),
      (LKey.avgActivity.tr, avg.interaction, Icons.forum_outlined),
      (LKey.avgQuality.tr, avg.quality, Icons.star_outline_rounded),
    ];
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
      decoration: BoxDecoration(
        color: WorkScreen._card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (avg.nextGrade != null && avg.need > 0)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                avg.need == 1
                    ? LKey.streamerAverageNeedOne.trParams({
                        'grade': avg.nextGrade!,
                      })
                    : LKey.streamerAverageNeed.trParams({
                        'n': '${avg.need}',
                        'grade': avg.nextGrade!,
                      }),
                style: TextStyleCustom.outFitMedium500(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
            ),
          for (final row in rows) ...[
            Row(
              children: [
                Icon(row.$3, color: WorkScreen._gold, size: 14),
                const SizedBox(width: 6),
                SizedBox(
                  width: 78,
                  child: Text(
                    row.$1,
                    style: TextStyleCustom.outFitMedium500(
                      color: Colors.white70,
                      fontSize: 11,
                    ),
                  ),
                ),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: (row.$2 / 100).clamp(0.02, 1),
                      minHeight: 6,
                      backgroundColor: Colors.white12,
                      valueColor:
                          const AlwaysStoppedAnimation(WorkScreen._pink),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${row.$2}',
                  style: TextStyleCustom.outFitSemiBold600(
                    color: Colors.white,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
          ],
        ],
      ),
    );
  }
}

class _MainGrid extends StatelessWidget {
  const _MainGrid({required this.data});

  final StreamerWorkStats data;

  @override
  Widget build(BuildContext context) {
    final gems =
        (data.user.coinCollectedLifetime / 100).fullDecimalFormat;
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.28,
      children: [
        _StatCard(
          label: LKey.todaysCalls.tr,
          value: data.today.calls.fullNumberFormat,
          color: WorkScreen._pink,
          icon: Icons.videocam_outlined,
        ),
        _StatCard(
          label: LKey.coins.tr,
          value: data.user.coinWallet.fullNumberFormat,
          color: WorkScreen._gold,
          iconAsset: AssetRes.icCoin,
        ),
        _StatCard(
          label: LKey.diamonds.tr,
          value: data.user.withdrawalPoints.fullNumberFormat,
          color: ColorRes.baseLavender,
          icon: Icons.diamond_outlined,
        ),
        _StatCard(
          label: LKey.gems.tr,
          value: gems,
          color: WorkScreen._cyan,
          icon: Icons.auto_awesome,
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
    this.icon,
    this.iconAsset,
  });

  final String label;
  final String value;
  final Color color;
  final IconData? icon;
  final String? iconAsset;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: WorkScreen._card,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (iconAsset != null)
                Image.asset(iconAsset!, height: 18, width: 18)
              else if (icon != null)
                Icon(icon, size: 18, color: color),
              const Spacer(),
            ],
          ),
          const Spacer(),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              maxLines: 1,
              style: TextStyleCustom.unboundedSemiBold600(
                color: color,
                fontSize: 22,
              ).copyWith(
                height: 1.4,
                leadingDistribution: TextLeadingDistribution.even,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyleCustom.outFitRegular400(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _PerfRow extends StatelessWidget {
  const _PerfRow({required this.data});

  final StreamerWorkStats data;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _MiniMetric(
            label: '${LKey.onlineTime.tr} (d)',
            value: (data.today.onlineTime.isNotEmpty &&
                    data.today.onlineTime != '-')
                ? data.today.onlineTime
                : '00:00:00',
            color: WorkScreen._cyan,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _MiniMetric(
            label: '${LKey.avgCallDuration.tr} (d)',
            value: data.today.avgDuration,
            color: ColorRes.basePeach,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _MiniMetric(
            label: LKey.positiveRating.tr,
            value: '${data.today.positiveRate.toStringAsFixed(0)}%',
            color: WorkScreen._green,
            icon: Icons.thumb_up_alt_outlined,
          ),
        ),
      ],
    );
  }
}

class _MiniMetric extends StatelessWidget {
  const _MiniMetric({
    required this.label,
    required this.value,
    required this.color,
    this.icon,
  });

  final String label;
  final String value;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: WorkScreen._card,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          if (icon != null) Icon(icon, size: 14, color: color),
          Text(
            value,
            style: TextStyleCustom.outFitSemiBold600(color: color, fontSize: 13),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyleCustom.outFitRegular400(
              color: Colors.white54,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

class _EarningsCard extends StatelessWidget {
  const _EarningsCard({required this.data});

  final StreamerWorkStats data;

  @override
  Widget build(BuildContext context) {
    final t = data.today;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: WorkScreen._card,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                LKey.todaysEarnings.tr,
                style: TextStyleCustom.outFitSemiBold600(
                  color: Colors.white,
                  fontSize: 15,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => Get.to(() => const WalletHistoryScreen()),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  '${LKey.walletHistory.tr} >',
                  style: TextStyleCustom.outFitMedium500(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              TextButton(
                onPressed: () => Get.to(() => const WithdrawalsScreen()),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  '${LKey.withdraw.tr} >',
                  style: TextStyleCustom.outFitMedium500(
                    color: WorkScreen._yellow,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _EarnItem(LKey.earningsFromCalls.tr, '${t.earningsCalls}',
                  Icons.phone_in_talk_outlined),
              _EarnItem(LKey.earningsFromGifts.tr, '${t.earningsGifts}',
                  Icons.card_giftcard_outlined),
              _EarnItem(LKey.earningsFromTasks.tr, '${t.earningsTasks}',
                  Icons.task_alt_outlined),
              _EarnItem(LKey.earningsFromInvites.tr, '${t.earningsInvites}',
                  Icons.person_add_alt_1_outlined),
              _EarnItem(LKey.managedEarnings.tr, '${t.earningsManaged}',
                  Icons.account_balance_wallet_outlined),
            ],
          ),
        ],
      ),
    );
  }
}

class _EarnItem extends StatelessWidget {
  const _EarnItem(this.label, this.value, this.icon);

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 96,
      child: Column(
        children: [
          Icon(icon, color: Colors.white70, size: 22),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyleCustom.outFitSemiBold600(
              color: Colors.white,
              fontSize: 15,
            ),
          ),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyleCustom.outFitRegular400(
              color: Colors.white54,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailPanel extends StatelessWidget {
  const _DetailPanel({required this.data});

  final StreamerWorkStats data;

  @override
  Widget build(BuildContext context) {
    final tw = data.weeklyLevel.thisWeek;
    final lw = data.weeklyLevel.lastWeek;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _TinyMetric(
              icon: Icons.favorite,
              color: ColorRes.likeRed,
              value: '${data.today.likes}',
              label: LKey.likes.tr,
            ),
            const SizedBox(width: 8),
            _TinyMetric(
              icon: Icons.heart_broken,
              color: WorkScreen._cyan,
              value: '${data.today.rejections}',
              label: LKey.rejections.tr,
            ),
            const SizedBox(width: 8),
            _TinyMetric(
              icon: Icons.pie_chart_outline,
              color: WorkScreen._green,
              value: '${data.today.rejectionRate.toStringAsFixed(0)}%',
              label: LKey.rejectionRate.tr,
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          LKey.weeklyLevelPrivateLiveOnly.tr,
          style: TextStyleCustom.outFitSemiBold600(
            color: Colors.white,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: WorkScreen._card,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              _TableHeader(),
              _TableRow(LKey.levelResponseRate.tr, tw.responseRateLabel,
                  '${lw.responseRate.toStringAsFixed(2)}%'),
              _TableRow(
                  LKey.levelAvgDuration.tr, tw.avgDuration, lw.avgDuration),
              _TableRow(LKey.levelCalls.tr, '${tw.levelCalls}',
                  '${lw.levelCalls}'),
              _TableRow(LKey.levelUpdateTime.tr, tw.updatedAt ?? '-',
                  lw.updatedAt ?? '-'),
            ],
          ),
        ),
      ],
    );
  }
}

class _TinyMetric extends StatelessWidget {
  const _TinyMetric({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final Color color;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: WorkScreen._card,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 4),
            Text(value,
                style:
                    TextStyleCustom.outFitSemiBold600(color: color, fontSize: 18)),
            Text(label,
                textAlign: TextAlign.center,
                style: TextStyleCustom.outFitRegular400(
                    color: Colors.white70, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

class _TableHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
              flex: 3,
              child: Text(LKey.category.tr,
                  style: TextStyleCustom.outFitMedium500(
                      color: WorkScreen._yellow, fontSize: 11))),
          Expanded(
              child: Text(LKey.thisWeek.tr,
                  textAlign: TextAlign.center,
                  style: TextStyleCustom.outFitMedium500(
                      color: WorkScreen._yellow, fontSize: 11))),
          Expanded(
              child: Text(LKey.lastWeek.tr,
                  textAlign: TextAlign.center,
                  style: TextStyleCustom.outFitMedium500(
                      color: WorkScreen._yellow, fontSize: 11))),
        ],
      ),
    );
  }
}

class _TableRow extends StatelessWidget {
  const _TableRow(this.cat, this.a, this.b);

  final String cat;
  final String a;
  final String b;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
              flex: 3,
              child: Text(cat,
                  style: TextStyleCustom.outFitRegular400(
                      color: Colors.white70, fontSize: 11))),
          Expanded(
              child: Text(a,
                  textAlign: TextAlign.center,
                  style: TextStyleCustom.outFitMedium500(
                      color: Colors.white, fontSize: 11))),
          Expanded(
              child: Text(b,
                  textAlign: TextAlign.center,
                  style: TextStyleCustom.outFitMedium500(
                      color: Colors.white, fontSize: 11))),
        ],
      ),
    );
  }
}

class _BenefitsCard extends StatelessWidget {
  const _BenefitsCard({required this.benefits});

  final List<String> benefits;

  @override
  Widget build(BuildContext context) {
    if (benefits.isEmpty) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: WorkScreen._card,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            LKey.currentLevelBenefits.tr,
            style: TextStyleCustom.outFitSemiBold600(
              color: Colors.white,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          for (final b in benefits)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      b,
                      style: TextStyleCustom.outFitRegular400(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const Icon(Icons.check, color: WorkScreen._pink, size: 18),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.isActive});

  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: isActive ? WorkScreen._green.withValues(alpha: 0.2) : _cardMuted,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isActive ? WorkScreen._green : Colors.white24,
        ),
      ),
      child: Text(
        isActive ? LKey.connected.tr : LKey.disconnected.tr,
        style: TextStyleCustom.outFitMedium500(
          color: isActive ? WorkScreen._green : Colors.white70,
          fontSize: 12,
        ),
      ),
    );
  }

  static const _cardMuted = ColorRes.surfaceDeep;
}

/// Acceso a tareas desde Trabajo (antes estaba en el bottom nav).
class _TasksSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: WorkScreen._card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: ColorRes.themeAccentSolid.withValues(alpha: 0.45),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.task_alt_rounded,
                  color: ColorRes.themeAccentSolid, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  LKey.tasks.tr,
                  style: TextStyleCustom.outFitSemiBold600(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => Get.to(() => const TasksScreen()),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: ColorRes.themeAccentSolid,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: Text(
                  LKey.view.tr,
                  style: TextStyleCustom.outFitMedium500(
                    color: Colors.white,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            LKey.tasksWorkHint.tr,
            style: TextStyleCustom.outFitRegular400(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _CallPricingCard extends StatelessWidget {
  const _CallPricingCard({required this.data, required this.controller});

  final StreamerWorkStats data;
  final WorkScreenController controller;

  @override
  Widget build(BuildContext context) {
    final pricing = data.callPricing;
    final price = pricing?.effectivePrice ?? 0;
    final canEdit = pricing?.canEdit == true;
    final grade = pricing?.grade ?? data.weeklyLevel.grade;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: WorkScreen._card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${LKey.callPrice.tr}: $price ${LKey.coins.tr}',
            style: TextStyleCustom.outFitSemiBold600(
              color: Colors.white,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            canEdit
                ? 'Grado $grade: puedes editar el precio (rango ${pricing?.min}-${pricing?.max}).'
                : 'Grado $grade: precio fijo de la plataforma.',
            style: TextStyleCustom.outFitRegular400(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),
          Obx(() {
            final on = controller.matchEnabled.value;
            return Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        LKey.receiveMatch.tr,
                        style: TextStyleCustom.outFitMedium500(
                          color: Colors.white,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        LKey.receiveMatchHint.tr,
                        style: TextStyleCustom.outFitRegular400(
                          color: Colors.white54,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                  Switch(
                  value: on,
                  activeThumbColor: WorkScreen._green,
                  onChanged: controller.matchToggleBusy.value
                      ? null
                      : (v) => controller.setMatchEnabled(v),
                ),
              ],
            );
          }),
          if (canEdit) ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () => _editPrice(context),
                style: TextButton.styleFrom(
                  backgroundColor: WorkScreen._pink,
                  foregroundColor: Colors.white,
                ),
                child: Text(
                  LKey.edit.tr,
                  style: TextStyleCustom.outFitMedium500(
                    color: Colors.white,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _editPrice(BuildContext context) async {
    final pricing = data.callPricing;
    if (pricing == null) return;
    final field = TextEditingController(text: '${pricing.effectivePrice}');
    final ok = await Get.dialog<bool>(
      AlertDialog(
        backgroundColor: WorkScreen._card,
        title: Text(LKey.callPrice.tr,
            style: TextStyleCustom.outFitSemiBold600(color: Colors.white)),
        content: TextField(
          controller: field,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: '${pricing.min} - ${pricing.max}',
            hintStyle: const TextStyle(color: Colors.white54),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text(LKey.cancel.tr),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: Text(LKey.save.tr),
          ),
        ],
      ),
    );
    if (ok == true) {
      final v = int.tryParse(field.text.trim());
      if (v != null) {
        await controller.updateCallPrice(v);
      }
    }
  }
}
