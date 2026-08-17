import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krimson/common/extensions/string_extension.dart';
import 'package:krimson/common/widget/custom_app_bar.dart';
import 'package:krimson/common/widget/custom_image.dart';
import 'package:krimson/common/widget/load_more_widget.dart';
import 'package:krimson/common/widget/loader_widget.dart';
import 'package:krimson/common/widget/no_data_widget.dart';
import 'package:krimson/languages/languages_keys.dart';
import 'package:krimson/model/misc/admin_notification_model.dart';
import 'package:krimson/screen/notification_screen/notification_screen_controller.dart';
import 'package:krimson/screen/notification_screen/widget/activity_notification_page.dart';
import 'package:krimson/utilities/text_style_custom.dart';
import 'package:krimson/utilities/theme_res.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(NotificationScreenController());

    return Scaffold(
      body: Column(
        children: [
          CustomAppBar(
            title: LKey.notifications.tr,
            widget: _Tabs(controller: controller),
          ),
          Expanded(
            child: Obx(() {
              if (controller.selectedTab.value == 0) {
                return ActivityNotificationPage(
                  notifications: controller.activity,
                  isLoading: controller.isActivityLoading,
                  onLoadMore: () => controller.fetchActivity(),
                  onRefresh: () => controller.fetchActivity(reset: true),
                );
              }
              return _AdminNotificationsPage(controller: controller);
            }),
          ),
        ],
      ),
    );
  }
}

class _Tabs extends StatelessWidget {
  final NotificationScreenController controller;

  const _Tabs({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final selected = controller.selectedTab.value;
      return Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.22),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          children: [
            _tab(context, LKey.activity.tr, 0, selected == 0),
            _tab(context, LKey.admin.tr, 1, selected == 1),
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
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active ? whitePure(context) : Colors.transparent,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Text(
            label,
            style: TextStyleCustom.outFitMedium500(
              color: active ? textDarkGrey(context) : Colors.white,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}

class _AdminNotificationsPage extends StatelessWidget {
  final NotificationScreenController controller;

  const _AdminNotificationsPage({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isAdminLoading.value && controller.admin.isEmpty) {
        return const LoaderWidget();
      }

      return RefreshIndicator(
        onRefresh: () => controller.fetchAdmin(reset: true),
        child: LoadMoreWidget(
          loadMore: () => controller.fetchAdmin(),
          child: NoDataView(
            showShow:
                !controller.isAdminLoading.value && controller.admin.isEmpty,
            title: LKey.notifications.tr,
            description: LKey.noContentMessage.tr,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount: controller.admin.length,
              separatorBuilder: (_, __) => Divider(color: bgGrey(context)),
              itemBuilder: (context, index) {
                final AdminNotificationData item = controller.admin[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomImage(
                        size: const Size(48, 48),
                        radius: 10,
                        image: item.image?.addBaseURL(),
                        isShowPlaceHolder: true,
                        fullName: item.title,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.title ?? '',
                              style: TextStyleCustom.outFitMedium500(
                                color: textDarkGrey(context),
                                fontSize: 14,
                              ),
                            ),
                            if ((item.description ?? '').isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  item.description!,
                                  style: TextStyleCustom.outFitRegular400(
                                    color: textLightGrey(context),
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            if ((item.createdAt ?? '').isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  item.createdAt!.formatDate,
                                  style: TextStyleCustom.outFitLight300(
                                    color: textLightGrey(context),
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      );
    });
  }
}
