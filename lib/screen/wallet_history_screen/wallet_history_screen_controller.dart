import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:krimson/common/controller/base_controller.dart';
import 'package:krimson/common/service/api/gift_wallet_service.dart';
import 'package:krimson/languages/languages_keys.dart';
import 'package:krimson/model/gift_wallet/wallet_history_model.dart';
import 'package:krimson/utilities/app_res.dart';

class WalletHistoryController extends BaseController {
  static const filters = <String>[
    'all',
    'live',
    'chat',
    'call',
    'gift',
  ];

  final RxList<WalletHistoryItem> items = <WalletHistoryItem>[].obs;
  final Rx<WalletHistorySummary?> summary = Rx<WalletHistorySummary?>(null);
  final RxString filter = 'all'.obs;
  final RxBool hasMore = true.obs;
  final RxBool loadingMore = false.obs;
  final Rx<DateTimeRange> range = DateTimeRange(
    start: DateTime.now().subtract(const Duration(days: 6)),
    end: DateTime.now(),
  ).obs;

  final DateFormat apiDate = DateFormat('yyyy-MM-dd');
  final DateFormat rangeDate = DateFormat('yyyy-MM-dd');

  String get rangeLabel {
    final r = range.value;
    return '${rangeDate.format(r.start)} ~ ${rangeDate.format(r.end)}';
  }

  String filterLabel(String key) {
    switch (key) {
      case 'live':
        return LKey.walletFilterLive.tr;
      case 'chat':
        return LKey.walletFilterChat.tr;
      case 'call':
        return LKey.walletFilterCalls.tr;
      case 'gift':
        return LKey.walletFilterGifts.tr;
      default:
        return LKey.walletFilterAll.tr;
    }
  }

  @override
  void onInit() {
    super.onInit();
    fetch(reset: true);
  }

  Future<void> fetch({bool reset = false}) async {
    if (reset) {
      if (isLoading.value) return;
      isLoading.value = true;
      items.clear();
      hasMore.value = true;
    } else {
      if (loadingMore.value || !hasMore.value) return;
      loadingMore.value = true;
    }

    try {
      final r = range.value;
      final response = await GiftWalletService.instance.fetchWalletHistory(
        startDate: apiDate.format(r.start),
        endDate: apiDate.format(r.end),
        filter: filter.value,
        offset: reset ? 0 : items.length,
        limit: AppRes.paginationLimit,
      );
      if (response.status == true) {
        summary.value = response.summary;
        if (reset) {
          items.assignAll(response.items ?? []);
        } else {
          items.addAll(response.items ?? []);
        }
        hasMore.value = response.hasMore == true;
      }
    } catch (_) {
    } finally {
      isLoading.value = false;
      loadingMore.value = false;
    }
  }

  Future<void> refreshList() => fetch(reset: true);

  void loadMore() {
    if (!hasMore.value || loadingMore.value || isLoading.value) return;
    fetch(reset: false);
  }

  void setFilter(String value) {
    if (filter.value == value) return;
    filter.value = value;
    fetch(reset: true);
  }

  Future<void> pickRange(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 3),
      lastDate: now,
      initialDateRange: DateTimeRange(
        start: DateTime(range.value.start.year, range.value.start.month,
            range.value.start.day),
        end: DateTime(range.value.end.year, range.value.end.month,
            range.value.end.day),
      ),
    );
    if (picked == null) return;
    range.value = picked;
    await fetch(reset: true);
  }
}
