import 'dart:async';

import 'package:get/get.dart';
import 'package:krimson/common/controller/base_controller.dart';
import 'package:krimson/common/service/api/privilege_service.dart';

enum LeaderboardTab { clients, streamers }

enum LeaderboardPeriod { today, week, month }

class LeaderboardController extends BaseController {
  final tab = LeaderboardTab.clients.obs;
  final period = LeaderboardPeriod.today.obs;
  final users = <LeaderboardEntry>[].obs;
  final me = Rxn<LeaderboardEntry>();
  final countdown = '00:00:00'.obs;

  DateTime? _endsAt;
  Timer? _timer;

  String get typeParam =>
      tab.value == LeaderboardTab.clients ? 'clients' : 'streamers';

  String get periodParam {
    switch (period.value) {
      case LeaderboardPeriod.week:
        return 'week';
      case LeaderboardPeriod.month:
        return 'month';
      case LeaderboardPeriod.today:
        return 'today';
    }
  }

  @override
  void onInit() {
    super.onInit();
    load();
  }

  @override
  void onClose() {
    _timer?.cancel();
    super.onClose();
  }

  Future<void> setTab(LeaderboardTab value) async {
    if (tab.value == value) return;
    tab.value = value;
    users.clear();
    me.value = null;
    await load();
  }

  Future<void> setPeriod(LeaderboardPeriod value) async {
    if (period.value == value) return;
    period.value = value;
    await load();
  }

  Future<void> load() async {
    isLoading.value = true;
    try {
      final result = await PrivilegeService.instance.leaderboard(
        type: typeParam,
        period: periodParam,
      );
      users.assignAll(result.users);
      me.value = result.me;
      _endsAt = DateTime.tryParse(result.endsAt ?? '');
      _startCountdown();
    } catch (_) {
      users.clear();
      me.value = null;
    } finally {
      isLoading.value = false;
    }
  }

  void _startCountdown() {
    _timer?.cancel();
    _tickCountdown();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _tickCountdown();
    });
  }

  void _tickCountdown() {
    final end = _endsAt;
    if (end == null) {
      countdown.value = '00:00:00';
      return;
    }
    var diff = end.difference(DateTime.now());
    if (diff.isNegative) {
      countdown.value = '00:00:00';
      return;
    }
    final h = diff.inHours.toString().padLeft(2, '0');
    final m = (diff.inMinutes % 60).toString().padLeft(2, '0');
    final s = (diff.inSeconds % 60).toString().padLeft(2, '0');
    countdown.value = '$h:$m:$s';
  }
}
