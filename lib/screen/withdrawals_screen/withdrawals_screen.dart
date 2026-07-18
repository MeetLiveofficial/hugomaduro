import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krimson/common/extensions/common_extension.dart';
import 'package:krimson/common/extensions/string_extension.dart';
import 'package:krimson/common/widget/custom_app_bar.dart';
import 'package:krimson/common/widget/loader_widget.dart';
import 'package:krimson/common/widget/no_data_widget.dart';
import 'package:krimson/common/widget/text_button_custom.dart';
import 'package:krimson/languages/languages_keys.dart';
import 'package:krimson/model/gift_wallet/withdraw_model.dart';
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
          Padding(
            padding: const EdgeInsets.fromLTRB(15, 8, 15, 8),
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
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value && controller.withdraws.isEmpty) {
                return const LoaderWidget();
              }
              return NoDataView(
                showShow: !controller.isLoading.value &&
                    controller.withdraws.isEmpty,
                title: LKey.withdrawals.tr,
                description: 'Aquí verás el historial de tus retiros.',
                child: NotificationListener<ScrollNotification>(
                  onNotification: (n) {
                    if (n.metrics.pixels >= n.metrics.maxScrollExtent - 80) {
                      controller.loadMore();
                    }
                    return false;
                  },
                  child: RefreshIndicator(
                    onRefresh: controller.refreshList,
                    child: ListView.builder(
                      itemCount: controller.withdraws.length,
                      padding: const EdgeInsets.only(top: 1, bottom: 24),
                      itemBuilder: (context, index) {
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
                                                    color:
                                                        textDarkGrey(context)),
                                          ),
                                          Text(
                                            '${withdraw.gateway}',
                                            style:
                                                TextStyleCustom.outFitMedium500(
                                                    color:
                                                        textDarkGrey(context),
                                                    fontSize: 13),
                                          ),
                                          Text(
                                            withdraw.account ?? '',
                                            style:
                                                TextStyleCustom.outFitLight300(
                                                    color:
                                                        textLightGrey(context),
                                                    fontSize: 12),
                                          ),
                                          Text(
                                            (withdraw.createdAt ?? '')
                                                .formatDate1,
                                            style:
                                                TextStyleCustom.outFitLight300(
                                                    color:
                                                        textLightGrey(context),
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
                                          withdraw.netUsd.currencyFormat,
                                          style:
                                              TextStyleCustom.outFitBold700(
                                                  fontSize: 18,
                                                  color:
                                                      textDarkGrey(context)),
                                        ),
                                        if (feePct > 0)
                                          Text(
                                            'neto · fee ${feePct.toStringAsFixed(1)}%',
                                            style: TextStyleCustom
                                                .outFitLight300(
                                                    color: textLightGrey(
                                                        context),
                                                    fontSize: 11),
                                          ),
                                        const SizedBox(height: 5),
                                        TextButtonCustom(
                                          onTap: () {},
                                          title: withdraw.status == 0
                                              ? LKey.pending.tr
                                              : withdraw.status == 1
                                                  ? LKey.completed.tr
                                                  : LKey.rejected.tr,
                                          btnHeight: 23,
                                          horizontalMargin: 0,
                                          radius: 5,
                                          fontSize: 12,
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 12),
                                          backgroundColor: statusColor
                                              .withValues(alpha: .15),
                                          titleColor: statusColor,
                                        )
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                color: bgGrey(context),
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 6),
                                child: Text(
                                  '${(withdraw.coins?.toInt() ?? 0).numberFormat} ${LKey.coins.tr}'
                                  ' · bruto ${withdraw.grossUsd.currencyFormat}'
                                  '${feePct > 0 ? ' · comisión ${withdraw.feeUsd.currencyFormat}' : ''}',
                                  style: TextStyleCustom.outFitLight300(
                                      color: textLightGrey(context),
                                      fontSize: 12),
                                ),
                              )
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              );
            }),
          )
        ],
      ),
    );
  }
}
