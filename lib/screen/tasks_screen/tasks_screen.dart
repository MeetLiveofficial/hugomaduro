import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krimson/common/manager/app_role.dart';
import 'package:krimson/common/widget/custom_app_bar.dart';
import 'package:krimson/common/widget/loader_widget.dart';
import 'package:krimson/common/widget/no_data_widget.dart';
import 'package:krimson/common/widget/text_button_custom.dart';
import 'package:krimson/languages/languages_keys.dart';
import 'package:krimson/model/task/task_models.dart';
import 'package:krimson/screen/tasks_screen/tasks_screen_controller.dart';
import 'package:krimson/utilities/text_style_custom.dart';
import 'package:krimson/utilities/theme_res.dart';

class TasksScreen extends StatelessWidget {
  final bool isDashBoard;

  const TasksScreen({super.key, this.isDashBoard = false});

  @override
  Widget build(BuildContext context) {
    if (!AppRole.canAccessTasks()) {
      return Scaffold(
        body: Column(
          children: [
            CustomAppBar(title: LKey.tasks.tr, showBack: !isDashBoard),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Las tareas solo están disponibles para streamers.',
                    textAlign: TextAlign.center,
                    style: TextStyleCustom.outFitMedium500(
                      color: textDarkGrey(context),
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    final controller = Get.put(TasksScreenController());

    return Scaffold(
      body: Column(
        children: [
          CustomAppBar(
            title: LKey.tasks.tr,
            showBack: !isDashBoard,
            widget: _Tabs(controller: controller),
          ),
          Expanded(
            child: Obx(() {
              if (controller.pageLoading.value) {
                return const LoaderWidget();
              }
              return RefreshIndicator(
                onRefresh: controller.loadTasks,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  children: [
                    _PointsHeader(controller: controller),
                    const SizedBox(height: 12),
                    _EligibilityBanner(controller: controller),
                    const SizedBox(height: 12),
                    _TaskList(controller: controller),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _Tabs extends StatelessWidget {
  final TasksScreenController controller;

  const _Tabs({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final selected = controller.selectedTab.value;
      final codes = controller.visibleTabCodes;
      return Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: bgGrey(context),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          children: [
            for (var i = 0; i < codes.length; i++)
              _tab(context, controller.tabLabel(codes[i]), i, selected == i),
          ],
        ),
      );
    });
  }

  Widget _tab(BuildContext context, String label, int index, bool active) {
    return Expanded(
      child: InkWell(
        onTap: () => controller.onTabChanged(index),
        borderRadius: BorderRadius.circular(30),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: active ? themeAccentSolid(context) : Colors.transparent,
            borderRadius: BorderRadius.circular(30),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyleCustom.outFitMedium500(
              color: active ? Colors.white : textLightGrey(context),
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}

class _PointsHeader extends StatelessWidget {
  final TasksScreenController controller;

  const _PointsHeader({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final b = controller.buckets.value;
      final cat = controller.currentCategory;
      final done = cat?.completedCount ?? 0;
      final total = cat?.totalCount ?? 0;
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bgGrey(context),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Puntos para retiro ${b.combinedPoints} / ${b.targetTotal} pts',
              style: TextStyleCustom.outFitBold700(
                color: textDarkGrey(context),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'LIVE: ${b.livePoints}/${b.liveMax}  ·  Otras: ${b.otherPoints}/${b.otherMax}',
              style: TextStyleCustom.outFitMedium500(
                color: textLightGrey(context),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${LKey.withdrawalPoints.tr}: ${controller.withdrawalPoints.value}  ·  $done / $total',
              style: TextStyleCustom.outFitRegular400(
                color: textLightGrey(context),
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    });
  }
}

class _EligibilityBanner extends StatelessWidget {
  final TasksScreenController controller;

  const _EligibilityBanner({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final gate = controller.eligibility.value;
      if (gate == null) return const SizedBox.shrink();
      final can = gate['can_withdraw_min'] == true;
      final maxUsd = gate['max_withdrawable_usd_today'];
      final dailyOk = gate['daily_complete_today'] == true;
      final livePts = gate['live_points_today'];
      final otherPts = gate['other_points_today'];
      final target = gate['target_points'] ?? 150;
      final msg = can
          ? LKey.youCanWithdrawToday.tr
          : (dailyOk
              ? LKey.keepCompletingTasksToWithdraw.tr
              : LKey.completeAllDailyTasksBeforeWithdrawing.tr);
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: (can ? Colors.green : Colors.orange).withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: (can ? Colors.green : Colors.orange).withValues(alpha: 0.35),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              msg,
              style: TextStyleCustom.outFitMedium500(
                color: textDarkGrey(context),
                fontSize: 13,
              ),
            ),
            if (livePts != null || otherPts != null) ...[
              const SizedBox(height: 4),
              Text(
                'Hoy LIVE ${livePts ?? 0} + Otras ${otherPts ?? 0} (meta $target)',
                style: TextStyleCustom.outFitRegular400(
                  color: textLightGrey(context),
                  fontSize: 12,
                ),
              ),
            ],
            if (maxUsd != null) ...[
              const SizedBox(height: 4),
              Text(
                '${LKey.maxWithdrawableToday.tr}: \$$maxUsd',
                style: TextStyleCustom.outFitRegular400(
                  color: textLightGrey(context),
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
      );
    });
  }
}

class _TaskList extends StatelessWidget {
  final TasksScreenController controller;

  const _TaskList({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final cat = controller.currentCategory;
      final tasks = cat?.tasks ?? [];
      if (tasks.isEmpty) {
        return NoDataView(title: LKey.noTasksAvailable.tr);
      }
      return Column(
        children:
            tasks.map((t) => _TaskCard(task: t, controller: controller)).toList(),
      );
    });
  }
}

class _TaskCard extends StatelessWidget {
  final TaskItem task;
  final TasksScreenController controller;

  const _TaskCard({required this.task, required this.controller});

  String _statusLabel() {
    switch (task.status) {
      case 'claimed':
        return LKey.claimed.tr;
      case 'completed':
        return LKey.completed.tr;
      case 'in_progress':
        return LKey.inProgress.tr;
      case 'expired':
        return LKey.expired.tr;
      default:
        return LKey.pending.tr;
    }
  }

  String _progressLabel() {
    if (task.isDual && task.requires != null) {
      final r = task.requires!;
      return '${task.progressMinutes}/${r.minutes} min · ${task.progressCoins}/${r.coins} coins · ${_statusLabel()}';
    }
    return '${task.progressValue}/${task.targetValue} · ${_statusLabel()}';
  }

  @override
  Widget build(BuildContext context) {
    final title = task.titleKey.tr;
    final desc = task.descriptionKey.tr;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgGrey(context),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyleCustom.outFitSemiBold600(
                    color: textDarkGrey(context),
                    fontSize: 15,
                  ),
                ),
              ),
              Text(
                '+${task.withdrawalPointsReward} ${LKey.pts.tr}',
                style: TextStyleCustom.outFitMedium500(
                  color: themeAccentSolid(context),
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            desc,
            style: TextStyleCustom.outFitRegular400(
              color: textLightGrey(context),
              fontSize: 12,
            ),
          ),
          if (task.isDual && task.requires != null) ...[
            const SizedBox(height: 8),
            _DualBars(task: task),
          ] else ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: task.progressRatio,
                minHeight: 6,
                backgroundColor: Colors.black12,
                color: themeAccentSolid(context),
              ),
            ),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  _progressLabel(),
                  style: TextStyleCustom.outFitRegular400(
                    color: textLightGrey(context),
                    fontSize: 12,
                  ),
                ),
              ),
              if (task.status == 'completed')
                SizedBox(
                  height: 34,
                  child: TextButtonCustom(
                    onTap: () => controller.claimTask(task),
                    title: LKey.claim.tr,
                    backgroundColor: themeAccentSolid(context),
                    titleColor: Colors.white,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DualBars extends StatelessWidget {
  final TaskItem task;

  const _DualBars({required this.task});

  @override
  Widget build(BuildContext context) {
    final r = task.requires!;
    final minRatio =
        r.minutes <= 0 ? 1.0 : (task.progressMinutes / r.minutes).clamp(0.0, 1.0);
    final coinRatio =
        r.coins <= 0 ? 1.0 : (task.progressCoins / r.coins).clamp(0.0, 1.0);
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: minRatio,
            minHeight: 5,
            backgroundColor: Colors.black12,
            color: themeAccentSolid(context),
          ),
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: coinRatio,
            minHeight: 5,
            backgroundColor: Colors.black12,
            color: Colors.amber.shade700,
          ),
        ),
      ],
    );
  }
}
