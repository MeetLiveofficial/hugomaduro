import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krimson/common/extensions/common_extension.dart';
import 'package:krimson/common/extensions/string_extension.dart';
import 'package:krimson/common/widget/custom_app_bar.dart';
import 'package:krimson/common/widget/loader_widget.dart';
import 'package:krimson/common/widget/no_data_widget.dart';
import 'package:krimson/common/widget/text_button_custom.dart';
import 'package:krimson/languages/languages_keys.dart';
import 'package:krimson/screen/withdrawals_screen/withdrawals_screen_controller.dart';
import 'package:krimson/utilities/app_res.dart';
import 'package:krimson/utilities/color_res.dart';
import 'package:krimson/utilities/text_style_custom.dart';
import 'package:krimson/utilities/theme_res.dart';

class WithdrawalsScreen extends StatelessWidget {
  const WithdrawalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(WithdrawalsScreenController());
    return Scaffold(
      body: Column(
        children: [
          CustomAppBar(title: LKey.withdrawals.tr),
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
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(15, 12, 15, 8),
                        child: TextButtonCustom(
                          onTap: controller.openRequestSheet,
                          title: LKey.requestWithdrawal.tr,
                          backgroundColor: ColorRes.themeAccentSolid,
                          titleColor: Colors.white,
                          btnHeight: 42,
                          horizontalMargin: 0,
                          margin: EdgeInsets.zero,
                        ),
                      ),
                    ),
                    if (!controller.isLoading.value &&
                        controller.withdraws.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: NoDataView(
                          showShow: true,
                          title: LKey.withdrawals.tr,
                          description: 'Aquí verás el historial de tus retiros.',
                          child: const SizedBox.shrink(),
                        ),
                      )
                    else
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
                              color: bgLightGrey(context),
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
                                                        color: textDarkGrey(
                                                            context)),
                                              ),
                                              Text(
                                                '${withdraw.gateway}',
                                                style: TextStyleCustom
                                                    .outFitMedium500(
                                                        color: textDarkGrey(
                                                            context),
                                                        fontSize: 13),
                                              ),
                                              Text(
                                                withdraw.account ?? '',
                                                style: TextStyleCustom
                                                    .outFitLight300(
                                                        color: textLightGrey(
                                                            context),
                                                        fontSize: 12),
                                              ),
                                              Text(
                                                (withdraw.createdAt ?? '')
                                                    .formatDate1,
                                                style: TextStyleCustom
                                                    .outFitLight300(
                                                        color: textLightGrey(
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
                                              '${(withdraw.coins ?? 0).toInt().numberFormat} coins',
                                              style: TextStyleCustom
                                                  .outFitMedium500(
                                                      color: textDarkGrey(
                                                          context)),
                                            ),
                                            Text(
                                              'Net ${((withdraw.netAmount ?? withdraw.amount ?? 0) as num).toDouble().toStringAsFixed(2)}'
                                              '${feePct > 0 ? ' · fee ${feePct.toStringAsFixed(1)}%' : ''}',
                                              style: TextStyleCustom
                                                  .outFitRegular400(
                                                      color: textLightGrey(
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

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF5A196), Color(0xFF4F214A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Monedas retirables',
            style: TextStyleCustom.outFitMedium500(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    controller.walletCoins.fullNumberFormat,
                    maxLines: 1,
                    style: TextStyleCustom.unboundedSemiBold600(
                      color: Colors.white,
                      fontSize: 24,
                    ).copyWith(
                      height: 1.4,
                      leadingDistribution: TextLeadingDistribution.even,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '(${controller.rateLabel})',
                style: TextStyleCustom.outFitMedium500(
                  color: const Color(0xFFFFD54A),
                  fontSize: 13,
                ),
              ),
              const Spacer(),
              Text(
                '$currency${balanceUsd.toStringAsFixed(2)}',
                style: TextStyleCustom.outFitSemiBold600(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _chip('Mín. $currency${controller.minUsd.toStringAsFixed(2)}'),
              _chip(
                  'Comisión global ${controller.globalCommission.toStringAsFixed(2)}%'),
              _chip('Mín. ${controller.minCoinsForUsd} monedas'),
            ],
          ),
          if (methods.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Métodos habilitados',
              style: TextStyleCustom.outFitMedium500(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final g in methods)
                  _chip(
                    '${g.title} · '
                    '${g.resolveCommission(controller.globalCommission).toStringAsFixed(1)}%',
                  ),
              ],
            ),
          ],
          if (controller.infoText.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Información',
              style: TextStyleCustom.outFitSemiBold600(
                color: Colors.white,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              controller.infoText,
              style: TextStyleCustom.outFitRegular400(
                color: Colors.white.withValues(alpha: 0.88),
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _chip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyleCustom.outFitRegular400(
          color: Colors.white,
          fontSize: 11,
        ),
      ),
    );
  }
}
