import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krimson/common/controller/base_controller.dart';
import 'package:krimson/common/manager/logger.dart';
import 'package:krimson/common/manager/session_manager.dart';
import 'package:krimson/common/service/api/post_service.dart';
import 'package:krimson/common/service/api/user_service.dart';
import 'package:krimson/languages/languages_keys.dart';
import 'package:krimson/model/general/settings_model.dart';
import 'package:krimson/model/general/status_model.dart';
import 'package:krimson/screen/report_sheet/report_sheet.dart';

class ReportSheetController extends BaseController {
  List<ReportReason> reports =
      SessionManager.instance.getSettings()?.reportReason ?? [];
  Rx<ReportReason?> selectedValue = Rx(null);
  int reportId;
  ReportType reportType;

  TextEditingController descriptionController = TextEditingController();

  ReportSheetController(this.reportId, this.reportType);

  @override
  void onReady() {
    super.onReady();
    selectedValue.value = reports.isNotEmpty ? reports.first : null;
  }

  void onReportSubmit() {
    if (descriptionController.text.isEmpty) {
      return showSnackBar(LKey.provideReportReason.tr);
    }
    if (reportId == -1) {
      return Loggers.error('Invalid Post Id : $reportId');
    }
    if (reportType == ReportType.post) {
      _reportPost();
    } else {
      _reportUser();
    }
  }

  void _reportPost() async {
    showLoader();
    StatusModel model = await PostService.instance.reportPost(
        postId: reportId,
        reason: selectedValue.value?.title ?? '',
        description: descriptionController.text.trim());
    stopLoader();

    Get.back();
    if (model.status == true) {
      showSnackBar(LKey.reportSubmitted.tr);
    } else {
      showSnackBar(model.message?.tr.capitalizeFirst);
    }
  }

  void _reportUser() async {
    showLoader();
    StatusModel model = await UserService.instance.reportPost(
        userId: reportId,
        reason: selectedValue.value?.title ?? '',
        description: descriptionController.text.trim());
    stopLoader();

    Get.back();
    if (model.status == true) {
      showSnackBar(LKey.reportSubmitted.tr);
    } else {
      showSnackBar(model.message?.tr.capitalizeFirst);
    }
  }
}
