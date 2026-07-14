import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:krimson/common/controller/base_controller.dart';
import 'package:krimson/common/functions/media_picker_helper.dart';
import 'package:krimson/common/manager/session_manager.dart';
import 'package:krimson/common/service/api/user_service.dart';
import 'package:krimson/languages/languages_keys.dart';
import 'package:krimson/model/user_model/user_model.dart';

class EditProfileScreenController extends BaseController {
  final Function(User? user)? onUpdateUser;

  EditProfileScreenController({this.onUpdateUser});

  final fullNameController = TextEditingController();
  final usernameController = TextEditingController();
  final bioController = TextEditingController();
  final emailController = TextEditingController();

  Rx<User?> user = Rx<User?>(null);
  Rxn<XFile> pickedPhoto = Rxn<XFile>();
  Rxn<String> previewPhotoUrl = Rxn<String>();
  RxDouble uploadProgress = 0.0.obs;
  RxBool isSaving = false.obs;

  @override
  void onInit() {
    super.onInit();
    final me = SessionManager.instance.getUser();
    user.value = me;
    fullNameController.text = me?.fullname ?? '';
    usernameController.text = me?.username ?? '';
    bioController.text = me?.bio ?? '';
    emailController.text = me?.userEmail ?? '';
    previewPhotoUrl.value =
        (me?.profilePhoto ?? '').isEmpty ? null : me!.profilePhoto;
  }

  @override
  void onClose() {
    fullNameController.dispose();
    usernameController.dispose();
    bioController.dispose();
    emailController.dispose();
    super.onClose();
  }

  Future<void> onPickPhoto() async {
    final file =
        await MediaPickerHelper.shared.pickImage(source: ImageSource.gallery);
    if (file == null) return;
    pickedPhoto.value = file;
    previewPhotoUrl.value = file.path;
    uploadProgress.value = 0;
  }

  Future<void> onSave() async {
    final fullName = fullNameController.text.trim();
    final username = usernameController.text.trim();
    if (fullName.isEmpty) {
      showSnackBar(LKey.fullNameEmpty.tr);
      return;
    }
    if (username.isEmpty) {
      showSnackBar(LKey.validUsernameEmpty.tr);
      return;
    }

    isSaving.value = true;
    showLoader(barrierDismissible: true);
    uploadProgress.value = 0.01;
    try {
      XFile? photo = pickedPhoto.value;
      if (photo != null && !kIsWeb) {
        final compressed =
            await MediaPickerHelper.shared.compressProfileImage(photo.path);
        photo = compressed ?? photo;
      }

      final updated = await UserService.instance
          .updateUserDetails(
            profilePhoto: photo,
            fullname: fullName,
            userName: username,
            bio: bioController.text.trim(),
            email: emailController.text.trim().isEmpty
                ? null
                : emailController.text.trim(),
            onProgress: (p) => uploadProgress.value = p.clamp(0.01, 1),
          )
          .timeout(const Duration(seconds: 45));

      if (updated != null) {
        user.value = updated;
        pickedPhoto.value = null;
        previewPhotoUrl.value = updated.profilePhoto;
        onUpdateUser?.call(updated);
        showSnackBar(LKey.saved.tr);
        stopLoader();
        Get.back(result: updated);
        return;
      } else {
        showSnackBar(LKey.somethingWentWrong.tr);
      }
    } catch (e) {
      showSnackBar('$e');
    } finally {
      uploadProgress.value = 0;
      isSaving.value = false;
      stopLoader();
    }
  }
}
