import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krimson/common/controller/base_controller.dart';
import 'package:krimson/common/service/api/user_service.dart';
import 'package:krimson/languages/languages_keys.dart';
import 'package:krimson/model/user_model/block_user_model.dart';
import 'package:krimson/model/user_model/user_model.dart';

class BlockUserController extends BaseController {
  Future<void> blockUser(User? user, VoidCallback onSuccess) async {
    final userId = user?.id;
    if (userId == null) return;
    final response = await UserService.instance.blockUser(userId: userId);
    if (response.status == true) onSuccess();
  }

  Future<void> unblockUser(User? user, VoidCallback onSuccess) async {
    final userId = user?.id;
    if (userId == null) return;
    final response = await UserService.instance.unBlockUser(userId: userId);
    if (response.status == true) onSuccess();
  }
}

class BlockedUsersListController extends BaseController {
  final users = <BlockUsers>[].obs;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    isLoading.value = true;
    try {
      users.assignAll(await UserService.instance.fetchMyBlockedUsers());
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> confirmUnblock(BlockUsers item) async {
    final user = item.toUser;
    final id = user?.id;
    if (id == null) return;
    final ok = await Get.dialog<bool>(
      AlertDialog(
        title: Text(LKey.unBlock.tr),
        content: Text(LKey.unblockUserConfirmation.tr),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text(LKey.cancel.tr),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: Text(LKey.yes.tr),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final response = await UserService.instance.unBlockUser(userId: id);
    if (response.status == true) {
      users.removeWhere((e) => e.id == item.id || e.toUserId?.toInt() == id);
    }
  }
}
