import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krimson/common/extensions/common_extension.dart';
import 'package:krimson/common/extensions/string_extension.dart';
import 'package:krimson/common/manager/app_role.dart';
import 'package:krimson/common/widget/brand_wash_bg.dart';
import 'package:krimson/common/widget/custom_app_bar.dart';
import 'package:krimson/common/widget/loader_widget.dart';
import 'package:krimson/languages/languages_keys.dart';
import 'package:krimson/screen/wallet_history_screen/wallet_history_screen.dart';
import 'package:krimson/screen/withdrawals_screen/withdrawals_screen_controller.dart';
import 'package:krimson/utilities/app_res.dart';
import 'package:krimson/utilities/asset_res.dart';
import 'package:krimson/utilities/client_colors.dart';
import 'package:krimson/utilities/color_res.dart';
import 'package:krimson/utilities/text_style_custom.dart';
import 'package:krimson/utilities/theme_res.dart';

class WithdrawalsScreen extends StatelessWidget {
  const WithdrawalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(WithdrawalsScreenController());
    final client = AppRole.isClient();
    final streamer = AppRole.isStreamer();
    return Scaffold(
      backgroundColor: client
          ? ClientColors.bg
          : (streamer ? const Color(0xFF07010E) : null),
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
            title: LKey.withdrawals.tr,
            bgColor: streamer ? Colors.transparent : null,
            iconColor: streamer ? Colors.white : null,
            titleStyle: streamer
                ? TextStyleCustom.unboundedMedium500(
                    color: Colors.white,
                    fontSize: 18,
                  )
                : null,
            rowWidget: IconButton(
              onPressed: () => Get.to(() => const WalletHistoryScreen()),
              tooltip: LKey.walletHistory.tr,
              icon: const Icon(Icons.history,
                  color: ColorRes.whitePure, size: 22),
            ),
          ),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value && controller.withdraws.isEmpty) {
                return const LoaderWidget();
              }
              return RefreshIndicator(
                onRefresh: controller.refreshList,
                child: CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(15, 8, 15, 0),
                        child: _WithdrawInfoCard(controller: controller),
                      ),
                    ),
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.only(top: 10, bottom: 6),
                        child: Center(
                          child: SizedBox(
                            width: 42,
                            height: 4,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: Color(0xFFFF4D9A),
                                borderRadius:
                                    BorderRadius.all(Radius.circular(4)),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(15, 4, 15, 8),
                        child: RequestWithdrawalSheet(
                          embedded: true,
                          onDone: controller.refreshList,
                        ),
                      ),
                    ),
                    if (controller.withdraws.isNotEmpty)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
                          child: Text(
                            LKey.withdrawals.tr,
                            style: TextStyleCustom.outFitSemiBold600(
                              color: streamer ? Colors.white : textDarkGrey(context),
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                    if (controller.withdraws.isNotEmpty)
                      SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            if (index >= controller.withdraws.length) {
                              controller.loadMore();
                              return const SizedBox(height: 40);
                            }
                            final withdraw = controller.withdraws[index];
                            final statusColor = withdraw.status == 0
                                ? ColorRes.orange
                                : withdraw.status == 1
                                    ? ColorRes.green
                                    : ColorRes.likeRed;
                            final feePct =
                                (withdraw.commissionPercent ?? 0).toDouble();
                            return Container(
                              color: AppRole.isStreamer()
                                  ? const Color(0xCC160820)
                                  : bgLightGrey(context),
                              margin: const EdgeInsets.symmetric(vertical: 1),
                              child: Column(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 20.0, vertical: 8),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                '${AppRes.hash}${withdraw.requestNumber}',
                                                style: TextStyleCustom
                                                    .unboundedSemiBold600(
                                                        color: AppRole.isStreamer()
                                                            ? Colors.white
                                                            : textDarkGrey(
                                                                context)),
                                              ),
                                              Text(
                                                '${withdraw.gateway}',
                                                style: TextStyleCustom
                                                    .outFitMedium500(
                                                        color: AppRole.isStreamer()
                                                            ? Colors.white
                                                            : textDarkGrey(
                                                                context),
                                                        fontSize: 13),
                                              ),
                                              Text(
                                                withdraw.account ?? '',
                                                style: TextStyleCustom
                                                    .outFitLight300(
                                                        color: streamer
                                                            ? Colors.white70
                                                            : textLightGrey(
                                                                context),
                                                        fontSize: 12),
                                              ),
                                              Text(
                                                (withdraw.createdAt ?? '')
                                                    .formatDate1,
                                                style: TextStyleCustom
                                                    .outFitLight300(
                                                        color: streamer
                                                            ? Colors.white70
                                                            : textLightGrey(
                                                                context),
                                                        fontSize: 12),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              '${(withdraw.coins ?? 0).toInt().numberFormat} ${LKey.coins.tr}',
                                              style: TextStyleCustom
                                                  .outFitMedium500(
                                                      color: AppRole.isStreamer()
                                                          ? Colors.white
                                                          : textDarkGrey(
                                                              context)),
                                            ),
                                            Text(
                                              'Net ${((withdraw.netAmount ?? withdraw.amount ?? 0) as num).toDouble().toStringAsFixed(2)}'
                                              '${feePct > 0 ? ' · fee ${feePct.toStringAsFixed(1)}%' : ''}',
                                              style: TextStyleCustom
                                                  .outFitRegular400(
                                                      color: streamer
                                                          ? Colors.white70
                                                          : textLightGrey(
                                                              context),
                                                      fontSize: 12),
                                            ),
                                            Text(
                                              withdraw.status == 0
                                                  ? LKey.pending.tr
                                                  : withdraw.status == 1
                                                      ? LKey.completed.tr
                                                      : LKey.rejected.tr,
                                              style: TextStyleCustom
                                                  .outFitMedium500(
                                                      color: statusColor,
                                                      fontSize: 12),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                          childCount: controller.withdraws.length +
                              (controller.hasMore.value ? 1 : 0),
                        ),
                      ),
                    const SliverToBoxAdapter(child: SizedBox(height: 24)),
                  ],
                ),
              );
            }),
          ),
        ],
          ),
        ],
      ),
    );
  }
}

class _WithdrawInfoCard extends StatelessWidget {
  const _WithdrawInfoCard({required this.controller});

  final WithdrawalsScreenController controller;

  @override
  Widget build(BuildContext context) {
    final currency = controller.currency;
    final balanceUsd = controller.walletCoins * controller.coinValue;
    final methods = controller.enabledGateways;

    final methodLabel = methods
        .map((g) => (g.title ?? '').trim())
        .where((t) => t.isNotEmpty)
        .join(' / ');

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF5EAE), Color(0xFFE23D9A), Color(0xFF7A28C4)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE879F9).withValues(alpha: 0.28),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.account_balance_wallet_outlined,
                      color: Colors.white, size: 22),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Monedas retirables',
                        style: TextStyleCustom.outFitMedium500(
                          color: Colors.white.withValues(alpha: 0.92),
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Image.asset(AssetRes.icCoin, width: 22, height: 22),
                          const SizedBox(width: 6),
                          Flexible(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                controller.walletCoins.fullNumberFormat,
                                maxLines: 1,
                                style: TextStyleCustom.unboundedSemiBold600(
                                  color: Colors.white,
                                  fontSize: 28,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '(${controller.rateLabel})',
                            style: TextStyleCustom.outFitMedium500(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 1,
                  height: 46,
                  color: Colors.white.withValues(alpha: 0.35),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: () => Get.to(() => const WalletHistoryScreen()),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$currency${balanceUsd.toStringAsFixed(2)}',
                        style: TextStyleCustom.outFitSemiBold600(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                      Icon(Icons.chevron_right,
                          color: Colors.white.withValues(alpha: 0.9), size: 20),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Divider(
              height: 1, color: Colors.white.withValues(alpha: 0.28)),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
            child: Row(
              children: [
                _stat(Icons.layers_outlined,
                    'Min. $currency${controller.minUsd.toStringAsFixed(2)}'),
                _stat(Icons.verified_user_outlined,
                    'Comisión global ${controller.globalCommission.toStringAsFixed(2)}%'),
                _stat(Icons.account_balance_wallet_outlined,
                    'Min. ${controller.minCoinsForUsd.fullNumberFormat} monedas'),
              ],
            ),
          ),
          if (methodLabel.isNotEmpty)
            Divider(height: 1, color: Colors.white.withValues(alpha: 0.28)),
          if (methodLabel.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 10, 12),
              child: Row(
                children: [
                  Icon(Icons.show_chart,
                      color: Colors.white.withValues(alpha: 0.95), size: 16),
                  const SizedBox(width: 6),
                  Text(
                    'Métodos habilitados',
                    style: TextStyleCustom.outFitMedium500(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                  const Spacer(),
                  Flexible(
                    child: Text(
                      methodLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.end,
                      style: TextStyleCustom.outFitMedium500(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Icon(Icons.chevron_right,
                      color: Colors.white.withValues(alpha: 0.9), size: 18),
                ],
              ),
            ),
          if (controller.infoText.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
              child: Text(
                controller.infoText,
                style: TextStyleCustom.outFitRegular400(
                  color: Colors.white.withValues(alpha: 0.88),
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _stat(IconData icon, String text) {
    return Expanded(
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              text,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyleCustom.outFitMedium500(
                color: Colors.white,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
