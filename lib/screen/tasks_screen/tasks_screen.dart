import 'package:flutter/material.dart';
import 'package:get/get.dart';
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
      return Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: bgGrey(context),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          children: [
            _tab(context, LKey.dailyTasks.tr, 0, selected == 0),
            _tab(context, LKey.specialTasks.tr, 1, selected == 1),
            _tab(context, LKey.bonusTasks.tr, 2, selected == 2),
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
      final cat = controller.currentCategory;
      final done = cat?.completedCount ?? 0;
      final total = cat?.totalCount ?? 0;
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bgGrey(context),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    LKey.withdrawalPoints.tr,
                    style: TextStyleCustom.outFitRegular400(
                      color: textLightGrey(context),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${controller.withdrawalPoints.value}',
                    style: TextStyleCustom.outFitBold700(
                      color: textDarkGrey(context),
                      fontSize: 22,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  LKey.progressLabel.tr,
                  style: TextStyleCustom.outFitRegular400(
                    color: textLightGrey(context),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$done / $total',
                  style: TextStyleCustom.outFitSemiBold600(
                    color: textDarkGrey(context),
                    fontSize: 16,
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
        children: tasks.map((t) => _TaskCard(task: t, controller: controller)).toList(),
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
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                '${task.progressValue}/${task.targetValue} · ${_statusLabel()}',
                style: TextStyleCustom.outFitRegular400(
                  color: textLightGrey(context),
                  fontSize: 12,
                ),
              ),
              const Spacer(),
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
