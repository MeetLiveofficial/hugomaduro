import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krimson/common/widget/loader_widget.dart';
import 'package:krimson/utilities/color_res.dart';
import 'package:krimson/utilities/text_style_custom.dart';

class BaseController extends FullLifeCycleController {
  RxBool isLoading = false.obs;
  static final share = BaseController();

  void showLoader({bool barrierDismissible = true}) {
    if (isLoading.value) return;
    if (Get.isSnackbarOpen) {
      Get.back();
    }
    isLoading.value = true;
    // No await: Get.dialog bloquea hasta cerrar el dialog y dejaba flujos colgados.
    Get.dialog(
      const LoaderWidget(),
      barrierDismissible: barrierDismissible,
    ).whenComplete(() {
      isLoading.value = false;
    });
  }

  void stopLoader() {
    // No usar Get.back(): con un snackbar abierto GetX cierra el snackbar
    // y deja el diálogo de carga colgado (el perfil se guarda, el spinner no).
    if (!isLoading.value) return;
    isLoading.value = false;
    final ctx = Get.overlayContext;
    if (ctx != null && Get.isDialogOpen == true) {
      Navigator.of(ctx, rootNavigator: true).pop();
    }
  }

  void showSnackBar(String? title, {int second = 2, bool translate = false}) {
    if (Get.isSnackbarOpen) {
      return;
    }

    // No usar .tr en mensajes dinámicos (errores/Firebase): puede corromper
    // el texto y fallar con RangeError en claves largas.
    final raw = title?.trim() ?? '';
    final text = translate ? raw.tr : raw;

    Get.rawSnackbar(
      backgroundColor: ColorRes.obsidian,
      margin: const EdgeInsets.fromLTRB(10, 56, 10, 10),
      padding: const EdgeInsets.all(15),
      borderRadius: 10,
      isDismissible: true,
      duration: Duration(seconds: second),
      snackPosition: SnackPosition.TOP,
      messageText: Text(
        text,
        style: TextStyleCustom.outFitRegular400(
            color: ColorRes.whitePure, fontSize: 17),
      ),
    );
  }

  void stopSnackBar() {
    if (Get.isSnackbarOpen) {
      Get.back();
    }
  }
}
