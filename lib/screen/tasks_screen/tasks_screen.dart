import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krimson/common/manager/app_role.dart';
import 'package:krimson/common/widget/custom_app_bar.dart';
import 'package:krimson/common/widget/loader_widget.dart';
import 'package:krimson/common/widget/no_data_widget.dart';
import 'package:krimson/languages/languages_keys.dart';
import 'package:krimson/model/task/task_models.dart';
import 'package:krimson/screen/tasks_screen/tasks_screen_controller.dart';
import 'package:krimson/utilities/color_res.dart';
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
                    LKey.tasksOnlyForStreamers.tr,
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
    controller.isDashBoard = isDashBoard;

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
                    _CountdownBanner(controller: controller),
                    const SizedBox(height: 12),
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

class _CountdownBanner extends StatelessWidget {
  final TasksScreenController controller;

  const _CountdownBanner({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [ColorRes.mlPurple, ColorRes.crimson],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            const Icon(Icons.timer_outlined, color: Colors.white, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    LKey.tasksEndToday.tr,
                    style: TextStyleCustom.outFitMedium500(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    controller.remainingLabel.value,
                    style: TextStyleCustom.outFitBold700(
                      color: const Color(0xFFFFE082),
                      fontSize: 26,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
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
              LKey.withdrawalPointsProgress.trParams({
                'current': '${b.combinedPoints}',
                'target': '${b.targetTotal}',
              }),
              style: TextStyleCustom.outFitBold700(
                color: textDarkGrey(context),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              LKey.liveAndOtherPoints.trParams({
                'live': '${b.livePoints}',
                'liveMax': '${b.liveMax}',
                'other': '${b.otherPoints}',
                'otherMax': '${b.otherMax}',
              }),
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
                LKey.todayLiveOtherGoal.trParams({
                  'live': '${livePts ?? 0}',
                  'other': '${otherPts ?? 0}',
                  'target': '$target',
                }),
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

  Color _statusColor(BuildContext context) {
    switch (task.status) {
      case 'claimed':
        return Colors.green.shade700;
      case 'completed':
        return themeAccentSolid(context);
      case 'expired':
        return Colors.red.shade400;
      default:
        return textLightGrey(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = task.titleKey.tr;
    final desc = task.descriptionKey.tr;
    final canGo = controller.canGoToCategory(task);
    final showGo = canGo && task.status != 'claimed';
    final showClaim = task.status == 'completed';
    final showClaimed = task.status == 'claimed';
    final highlightNext = !controller.isFirstTask(task) &&
        controller.firstTaskIsDone &&
        !task.isDone;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgGrey(context),
        borderRadius: BorderRadius.circular(14),
        border: highlightNext
            ? Border.all(color: themeAccentSolid(context).withValues(alpha: 0.45))
            : null,
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
          if (highlightNext) ...[
            const SizedBox(height: 8),
            Text(
              LKey.nextTaskUnlocked.tr,
              style: TextStyleCustom.outFitMedium500(
                color: themeAccentSolid(context),
                fontSize: 11,
              ),
            ),
          ],
          const SizedBox(height: 12),
          if (task.isDual && task.requires != null)
            _DualMetrics(task: task)
          else
            _SingleMetric(task: task),
          const SizedBox(height: 8),
          Text(
            _statusLabel(),
            style: TextStyleCustom.outFitMedium500(
              color: _statusColor(context),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 10),
          if (!canGo && !showClaimed)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                LKey.completeFirstTaskToContinue.tr,
                style: TextStyleCustom.outFitRegular400(
                  color: textLightGrey(context),
                  fontSize: 11,
                ),
              ),
            ),
          _TaskActions(
            showClaim: showClaim,
            showClaimed: showClaimed,
            showGo: showGo,
            goLabel: controller.goLabel(task),
            onClaim: () => controller.claimTask(task),
            onGo: () => controller.goToTaskCategory(task),
          ),
        ],
      ),
    );
  }
}

class _DualMetrics extends StatelessWidget {
  final TaskItem task;

  const _DualMetrics({required this.task});

  @override
  Widget build(BuildContext context) {
    final r = task.requires!;
    final minRatio =
        r.minutes <= 0 ? 1.0 : (task.progressMinutes / r.minutes).clamp(0.0, 1.0);
    final coinRatio =
        r.coins <= 0 ? 1.0 : (task.progressCoins / r.coins).clamp(0.0, 1.0);
    return Column(
      children: [
        _LabeledBar(
          icon: Icons.schedule_rounded,
          label: LKey.liveMinutesLabel.tr,
          value: '${task.progressMinutes}/${r.minutes} ${LKey.minutesUnit.tr}',
          ratio: minRatio,
          color: themeAccentSolid(context),
        ),
        const SizedBox(height: 10),
        _LabeledBar(
          icon: Icons.monetization_on_rounded,
          label: LKey.taskCoinsLabel.tr,
          value: '${task.progressCoins}/${r.coins}',
          ratio: coinRatio,
          color: const Color(0xFFE8A017),
        ),
      ],
    );
  }
}

class _SingleMetric extends StatelessWidget {
  final TaskItem task;

  const _SingleMetric({required this.task});

  String get _label {
    switch (task.actionType) {
      case 'user_interactions':
      case 'reply_messages':
        return LKey.goToChatCategory.tr;
      case 'private_call_ge_5':
      case 'private_call_ge_20':
      case 'match_completed':
        return LKey.goToMatchCategory.tr;
      case 'online_minutes':
      case 'watch_lives_minutes':
        return LKey.liveMinutesLabel.tr;
      case 'receive_gift_coins':
      case 'send_gifts':
        return LKey.taskCoinsLabel.tr;
      default:
        return LKey.progressLabel.tr;
    }
  }

  @override
  Widget build(BuildContext context) {
    return _LabeledBar(
      icon: Icons.flag_rounded,
      label: _label,
      value: '${task.progressValue}/${task.targetValue}',
      ratio: task.progressRatio,
      color: themeAccentSolid(context),
    );
  }
}

class _LabeledBar extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final double ratio;
  final Color color;

  const _LabeledBar({
    required this.icon,
    required this.label,
    required this.value,
    required this.ratio,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                label,
                style: TextStyleCustom.outFitMedium500(
                  color: textDarkGrey(context),
                  fontSize: 12,
                ),
              ),
            ),
            Text(
              value,
              style: TextStyleCustom.outFitSemiBold600(
                color: textDarkGrey(context),
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 8,
            backgroundColor: Colors.black12,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _TaskActions extends StatelessWidget {
  final bool showClaim;
  final bool showClaimed;
  final bool showGo;
  final String goLabel;
  final VoidCallback onClaim;
  final VoidCallback onGo;

  const _TaskActions({
    required this.showClaim,
    required this.showClaimed,
    required this.showGo,
    required this.goLabel,
    required this.onClaim,
    required this.onGo,
  });

  @override
  Widget build(BuildContext context) {
    if (showClaimed && !showGo) {
      return _PillButton(
        label: LKey.claimed.tr,
        filled: false,
        enabled: false,
        onTap: () {},
      );
    }

    if (showClaim && showGo) {
      return Row(
        children: [
          Expanded(
            flex: 3,
            child: _PillButton(
              label: LKey.claim.tr,
              filled: true,
              onTap: onClaim,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: _PillButton(
              label: goLabel,
              filled: false,
              onTap: onGo,
            ),
          ),
        ],
      );
    }

    if (showClaim) {
      return _PillButton(
        label: LKey.claim.tr,
        filled: true,
        onTap: onClaim,
      );
    }

    if (showGo) {
      return _PillButton(
        label: goLabel,
        filled: false,
        onTap: onGo,
      );
    }

    return const SizedBox.shrink();
  }
}

class _PillButton extends StatelessWidget {
  final String label;
  final bool filled;
  final bool enabled;
  final VoidCallback onTap;

  const _PillButton({
    required this.label,
    required this.filled,
    required this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final accent = themeAccentSolid(context);
    final bg = !enabled
        ? Colors.black12
        : (filled ? accent : Colors.transparent);
    final fg = !enabled
        ? textLightGrey(context)
        : (filled ? Colors.white : accent);
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: filled || !enabled
                ? null
                : Border.all(color: accent.withValues(alpha: 0.7)),
          ),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyleCustom.outFitSemiBold600(
              color: fg,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}
