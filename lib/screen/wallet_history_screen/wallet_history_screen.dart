import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:krimson/common/extensions/common_extension.dart';
import 'package:krimson/common/manager/app_role.dart';
import 'package:krimson/common/widget/brand_wash_bg.dart';
import 'package:krimson/common/widget/custom_app_bar.dart';
import 'package:krimson/common/widget/gift_media.dart';
import 'package:krimson/common/widget/loader_widget.dart';
import 'package:krimson/common/widget/no_data_widget.dart';
import 'package:krimson/languages/languages_keys.dart';
import 'package:krimson/model/gift_wallet/wallet_history_model.dart';
import 'package:krimson/screen/recharge_history_screen/recharge_history_screen.dart';
import 'package:krimson/screen/wallet_history_screen/wallet_history_screen_controller.dart';
import 'package:krimson/utilities/asset_res.dart';
import 'package:krimson/utilities/client_colors.dart';
import 'package:krimson/utilities/color_res.dart';
import 'package:krimson/utilities/text_style_custom.dart';
import 'package:krimson/utilities/theme_res.dart';

class WalletHistoryScreen extends StatelessWidget {
  final bool embedded;

  const WalletHistoryScreen({super.key, this.embedded = false});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(WalletHistoryController());
    final body = Obx(() {
      final loading = controller.isLoading.value;
      final items = controller.items.toList();
      final hasMore = controller.hasMore.value;
      final filter = controller.filter.value;
      final summary = controller.summary.value;
      final rangeLabel = controller.rangeLabel;
      if (loading && items.isEmpty) {
        return const LoaderWidget();
      }
      return RefreshIndicator(
        onRefresh: controller.refreshList,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: _RangeAndTotals(
                rangeLabel: rangeLabel,
                periodIncome: summary?.periodIncome ?? 0,
                periodWithdraw: summary?.periodWithdraw ?? 0,
                onPickRange: () => controller.pickRange(context),
              ),
            ),
            SliverToBoxAdapter(
              child: _FilterRow(
                selected: filter,
                onSelect: controller.setFilter,
                labelOf: controller.filterLabel,
              ),
            ),
            if (!loading && items.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: NoDataView(
                  showShow: true,
                  title: LKey.walletNoHistory,
                  description: LKey.walletNoHistoryDesc,
                  child: SizedBox.shrink(),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 28),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      if (index >= items.length) {
                        controller.loadMore();
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Center(
                            child: SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        );
                      }
                      return _HistoryCard(item: items[index]);
                    },
                    childCount: items.length + (hasMore ? 1 : 0),
                  ),
                ),
              ),
          ],
        ),
      );
    });

    final client = AppRole.isClient();
    final streamer = AppRole.isStreamer();
    if (embedded) {
      return ColoredBox(
        color: (client || streamer) ? Colors.transparent : bgLightGrey(context),
        child: body,
      );
    }

    return Scaffold(
      backgroundColor: client
          ? ClientColors.bg
          : (streamer ? const Color(0xFF07010E) : bgLightGrey(context)),
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (client)
            const BrandWashBg(vivid: false)
          else if (streamer)
            const BrandWashBg(vivid: true),
          Column(
        children: [
          CustomAppBar(
            title: LKey.walletHistory.tr,
            bgColor: streamer ? Colors.transparent : null,
            iconColor: streamer ? Colors.white : null,
            titleStyle: streamer
                ? TextStyleCustom.unboundedMedium500(
                    color: Colors.white,
                    fontSize: 18,
                  )
                : null,
            rowWidget: AppRole.canRecharge()
                ? IconButton(
                    onPressed: () =>
                        Get.to(() => const RechargeHistoryScreen()),
                    icon: const Icon(Icons.receipt_long_outlined,
                        color: ColorRes.whitePure, size: 22),
                    tooltip: LKey.walletRechargeItem.tr,
                  )
                : const SizedBox(width: 48),
          ),
          Expanded(child: body),
        ],
          ),
        ],
      ),
    );
  }
}

class _RangeAndTotals extends StatelessWidget {
  final String rangeLabel;
  final int periodIncome;
  final int periodWithdraw;
  final VoidCallback onPickRange;

  const _RangeAndTotals({
    required this.rangeLabel,
    required this.periodIncome,
    required this.periodWithdraw,
    required this.onPickRange,
  });

  @override
  Widget build(BuildContext context) {
    final streamer = AppRole.isStreamer();
    final ink = streamer ? Colors.white : textDarkGrey(context);
    final muted = streamer ? Colors.white70 : textLightGrey(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(15, 10, 15, 0),
      child: Row(
        children: [
          InkWell(
            onTap: onPickRange,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Icon(Icons.calendar_month_outlined, size: 18, color: ink),
                  const SizedBox(width: 6),
                  Text(
                    rangeLabel,
                    style: TextStyleCustom.outFitMedium500(
                      color: ink,
                      fontSize: 13,
                    ),
                  ),
                  Icon(Icons.keyboard_arrow_down, size: 18, color: muted),
                ],
              ),
            ),
          ),
          const Spacer(),
          _TotalLine(
            label: LKey.walletIncome.tr,
            value: periodIncome,
          ),
          const SizedBox(width: 12),
          _TotalLine(
            label: LKey.walletWithdrawLabel.tr,
            value: periodWithdraw,
          ),
        ],
      ),
    );
  }
}

class _TotalLine extends StatelessWidget {
  final String label;
  final int value;

  const _TotalLine({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          '$label: ${value.fullNumberFormat}',
          style: TextStyleCustom.outFitRegular400(
            color: AppRole.isStreamer() ? Colors.white70 : textDarkGrey(context),
            fontSize: 12,
          ),
        ),
        const SizedBox(width: 3),
        Image.asset(AssetRes.icCoin, width: 14, height: 14),
      ],
    );
  }
}

class _FilterRow extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelect;
  final String Function(String key) labelOf;

  const _FilterRow({
    required this.selected,
    required this.onSelect,
    required this.labelOf,
  });

  @override
  Widget build(BuildContext context) {
    final client = AppRole.isClient();
    final streamer = AppRole.isStreamer();
    return SizedBox(
      height: 44,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(15, 8, 15, 0),
        scrollDirection: Axis.horizontal,
        itemCount: WalletHistoryController.filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final key = WalletHistoryController.filters[index];
          final isSelected = selected == key;
          final bg = isSelected
              ? (client
                  ? ClientColors.primary
                  : (streamer ? const Color(0xFFE879F9) : ColorRes.crimson))
              : (client
                  ? ClientColors.surfaceAlt
                  : (streamer ? const Color(0x66140A22) : ColorRes.whitePure));
          final fg = isSelected
              ? (client ? ClientColors.bg : ColorRes.whitePure)
              : (client
                  ? ClientColors.textOnSurface
                  : (streamer ? Colors.white70 : ColorRes.textDarkGrey));
          final border = isSelected
              ? (client
                  ? ClientColors.primary
                  : (streamer ? const Color(0xFFE879F9) : ColorRes.crimson))
              : (client
                  ? ClientColors.border
                  : (streamer ? const Color(0x73E879F9) : ColorRes.roseBorder));
          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => onSelect(key),
              borderRadius: BorderRadius.circular(20),
              child: Ink(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: border, width: 1.2),
                ),
                child: Text(
                  labelOf(key),
                  style: TextStyleCustom.outFitMedium500(
                    color: fg,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final WalletHistoryItem item;

  const _HistoryCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final income = item.isIncome;
    final client = AppRole.isClient();
    final streamer = AppRole.isStreamer();
    final amountColor = income
        ? (streamer ? const Color(0xFFFF4D9A) : ColorRes.likeRed)
        : (streamer ? Colors.white : textDarkGrey(context));
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: client
            ? ClientColors.surfaceAlt
            : (streamer ? const Color(0xCC160820) : ColorRes.whitePure),
        borderRadius: BorderRadius.circular(16),
        border: streamer
            ? Border.all(color: const Color(0x73E879F9))
            : (client ? Border.all(color: ClientColors.border) : null),
      ),
      child: Row(
        children: [
          _TypeIcon(item: item),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _titleFor(item),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyleCustom.outFitMedium500(
                    color: streamer ? Colors.white : textDarkGrey(context),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                _MetaRow(item: item),
                if ((item.createdAt ?? '').isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    _stamp(item.createdAt!),
                    style: TextStyleCustom.outFitLight300(
                      color: streamer ? Colors.white54 : textLightGrey(context),
                      fontSize: 11,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${income ? '+' : '-'}${item.coins.fullNumberFormat}',
            style: TextStyleCustom.outFitBold700(
              color: amountColor,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  String _titleFor(WalletHistoryItem item) {
    final name = item.displayName.isEmpty ? '—' : item.displayName;
    if (item.note == 'agency_share') {
      return LKey.walletAgencyShareFrom.trParams({'name': name});
    }
    switch (item.type) {
      case 'call':
        if (item.note == 'match') {
          return LKey.walletMatchWith.trParams({'name': name});
        }
        return LKey.walletPrivateCallWith.trParams({'name': name});
      case 'withdraw':
        return LKey.walletWithdrawItem.tr;
      case 'recharge':
        return LKey.walletRechargeItem.tr;
      case 'referral':
        return LKey.walletReferralFrom.trParams({'name': name});
      case 'gift':
        switch (item.source) {
          case 'live':
            return LKey.walletGiftLiveFrom.trParams({'name': name});
          case 'chat':
            return LKey.walletGiftChatFrom.trParams({'name': name});
          case 'call':
            return LKey.walletGiftCallFrom.trParams({'name': name});
          default:
            return LKey.walletGiftFrom.trParams({'name': name});
        }
      default:
        return LKey.walletGiftFrom.trParams({'name': name});
    }
  }

  String _stamp(String raw) {
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return raw;
    final local = parsed.toLocal();
    return DateFormat('MM-dd HH:mm').format(local);
  }
}

class _TypeIcon extends StatelessWidget {
  final WalletHistoryItem item;

  const _TypeIcon({required this.item});

  @override
  Widget build(BuildContext context) {
    Color bg;
    IconData icon;
    switch (item.type) {
      case 'call':
        bg = const Color(0xFF2EC4B6);
        icon = Icons.phone;
        break;
      case 'withdraw':
        bg = ColorRes.orange;
        icon = Icons.south_west;
        break;
      case 'recharge':
        bg = themeAccentSolid(context);
        icon = Icons.add_card_outlined;
        break;
      default:
        bg = AppRole.isClient()
            ? ClientColors.primary
            : (AppRole.isStreamer()
                ? const Color(0xFFE879F9)
                : const Color(0xFFFF6B9D));
        icon = Icons.card_giftcard;
    }
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
      child: Icon(icon, color: Colors.white, size: 22),
    );
  }
}

class _MetaRow extends StatelessWidget {
  final WalletHistoryItem item;

  const _MetaRow({required this.item});

  @override
  Widget build(BuildContext context) {
    if (item.type == 'call') {
      return Text(
        _formatDuration(item.durationSeconds),
        style: TextStyleCustom.outFitRegular400(
          color: AppRole.isStreamer() ? Colors.white70 : textLightGrey(context),
          fontSize: 12,
        ),
      );
    }
    if (item.type == 'gift') {
      return Row(
        children: [
          if ((item.gift?.catalogImage ?? '').isNotEmpty)
            GiftMedia(
              path: item.gift!.catalogImage,
              width: 22,
              height: 22,
              fit: BoxFit.contain,
              muted: true,
              looping: true,
            ),
          if ((item.gift?.catalogImage ?? '').isNotEmpty) const SizedBox(width: 6),
          Text(
            'X ${item.quantity}',
            style: TextStyleCustom.outFitRegular400(
              color: AppRole.isStreamer() ? Colors.white70 : textLightGrey(context),
              fontSize: 12,
            ),
          ),
        ],
      );
    }
    if ((item.note ?? '').isNotEmpty) {
      return Text(
        item.note!,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyleCustom.outFitRegular400(
          color: AppRole.isStreamer() ? Colors.white70 : textLightGrey(context),
          fontSize: 12,
        ),
      );
    }
    return const SizedBox.shrink();
  }

  String _formatDuration(int? seconds) {
    final total = seconds ?? 0;
    if (total <= 0) return '';
    final m = total ~/ 60;
    final s = total % 60;
    if (m <= 0) {
      return LKey.durationSecondsAbbr.trParams({'count': '$s'});
    }
    if (s <= 0) {
      return LKey.durationMinutesAbbr.trParams({'count': '$m'});
    }
    return LKey.durationMinSec.trParams({'m': '$m', 's': '$s'});
  }
}
