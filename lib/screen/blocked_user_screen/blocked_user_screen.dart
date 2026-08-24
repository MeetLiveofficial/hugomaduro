import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krimson/common/extensions/string_extension.dart';
import 'package:krimson/common/widget/custom_app_bar.dart';
import 'package:krimson/common/widget/custom_image.dart';
import 'package:krimson/common/widget/full_name_with_blue_tick.dart';
import 'package:krimson/common/widget/loader_widget.dart';
import 'package:krimson/common/widget/no_data_widget.dart';
import 'package:krimson/common/widget/text_button_custom.dart';
import 'package:krimson/languages/languages_keys.dart';
import 'package:krimson/model/user_model/user_model.dart';
import 'package:krimson/screen/blocked_user_screen/block_user_controller.dart';
import 'package:krimson/utilities/text_style_custom.dart';
import 'package:krimson/utilities/theme_res.dart';

class BlockedUserScreen extends StatelessWidget {
  const BlockedUserScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(BlockedUsersListController());
    return Scaffold(
      body: Column(
        children: [
          CustomAppBar(title: LKey.blockedUsers.tr),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value && controller.users.isEmpty) {
                return const LoaderWidget();
              }
              return NoDataView(
                showShow: !controller.isLoading.value &&
                    controller.users.isEmpty,
                title: LKey.blockListEmptyTitle,
                description: LKey.blockListEmptyDescription,
                child: RefreshIndicator(
                  onRefresh: controller.load,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: controller.users.length,
                    itemBuilder: (context, index) {
                      final item = controller.users[index];
                      final user = item.toUser;
                      return _BlockedUserTile(
                        user: user,
                        onUnblock: () => controller.confirmUnblock(item),
                      );
                    },
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _BlockedUserTile extends StatelessWidget {
  final User? user;
  final VoidCallback onUnblock;

  const _BlockedUserTile({
    required this.user,
    required this.onUnblock,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          CustomImage(
            size: const Size(44, 44),
            image: user?.profilePhoto?.addBaseURL(),
            fullName: user?.fullname,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FullNameWithBlueTick(
                  username: user?.username,
                  fontSize: 13,
                  iconSize: 14,
                  isVerify: user?.isVerify,
                ),
                Text(
                  user?.fullname ?? '',
                  style: TextStyleCustom.outFitLight300(
                    color: textLightGrey(context),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          TextButtonCustom(
            onTap: onUnblock,
            title: LKey.unBlock.tr,
            btnHeight: 32,
            btnWidth: 110,
            fontSize: 12,
            horizontalMargin: 0,
            margin: EdgeInsets.zero,
            radius: 8,
          ),
        ],
      ),
    );
  }
}
