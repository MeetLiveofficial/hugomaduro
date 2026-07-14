import 'package:flutter/material.dart';
import 'package:krimson/common/controller/base_controller.dart';
import 'package:krimson/common/service/api/user_service.dart';
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
