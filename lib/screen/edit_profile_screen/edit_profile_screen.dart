import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:krimson/common/extensions/string_extension.dart';
import 'package:krimson/common/manager/app_role.dart';
import 'package:krimson/common/widget/brand_wash_bg.dart';
import 'package:krimson/common/widget/custom_app_bar.dart';
import 'package:krimson/common/widget/custom_image.dart';
import 'package:krimson/common/widget/loader_widget.dart';
import 'package:krimson/common/widget/text_button_custom.dart';
import 'package:krimson/common/widget/text_field_custom.dart';
import 'package:krimson/languages/languages_keys.dart';
import 'package:krimson/model/user_model/user_model.dart';
import 'package:krimson/screen/edit_profile_screen/edit_profile_screen_controller.dart';
import 'package:krimson/utilities/client_colors.dart';
import 'package:krimson/utilities/text_style_custom.dart';
import 'package:krimson/utilities/theme_res.dart';

class EditProfileScreen extends StatelessWidget {
  final Function(User? user)? onUpdateUser;

  const EditProfileScreen({super.key, this.onUpdateUser});

  @override
  Widget build(BuildContext context) {
    final controller =
        Get.put(EditProfileScreenController(onUpdateUser: onUpdateUser));

    final client = AppRole.isClient();
    final streamer = AppRole.isStreamer();
    final accent = client ? ClientColors.primary : const Color(0xFFE879F9);

    return ThemeRes.applyIfClient(
      context,
      Scaffold(
      backgroundColor: client
          ? ClientColors.bg
          : (streamer ? const Color(0xFF07010E) : null),
      body: Stack(
        children: [
          if (client)
            const BrandWashBg(vivid: false)
          else if (streamer)
            const BrandWashBg(vivid: true),
          Column(
            children: [
              CustomAppBar(
                title: LKey.editProfile.tr,
                bgColor: streamer ? Colors.transparent : null,
                iconColor: streamer ? Colors.white : null,
                titleStyle: streamer
                    ? TextStyleCustom.unboundedMedium500(
                        color: Colors.white,
                        fontSize: 18,
                      )
                    : null,
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      Obx(() {
                        final picked = controller.pickedPhoto.value;
                        final path = controller.previewPhotoUrl.value;
                        final progress = controller.uploadProgress.value;
                        final networkUrl = () {
                          if (path == null || path.isEmpty) return null;
                          if (path.startsWith('http') ||
                              path.startsWith('blob:')) {
                            return path;
                          }
                          return path.addBaseURL();
                        }();

                        return Column(
                          children: [
                            InkWell(
                              onTap: controller.onPickPhoto,
                              borderRadius: BorderRadius.circular(60),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(3),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: accent,
                                        width: 2,
                                      ),
                                      boxShadow: ClientColors.neonGlow(
                                        color: accent,
                                        alpha: 0.45,
                                        blur: 16,
                                        offset: Offset.zero,
                                      ),
                                    ),
                                    child: picked != null
                                        ? _PickedAvatar(file: picked)
                                        : CustomImage(
                                            size: const Size(110, 110),
                                            image: networkUrl,
                                            fullName: controller
                                                    .user.value?.fullname ??
                                                controller
                                                    .fullNameController.text,
                                          ),
                                  ),
                                  if (progress > 0 && progress < 1)
                                    Container(
                                      width: 110,
                                      height: 110,
                                      decoration: const BoxDecoration(
                                        color: Colors.black45,
                                        shape: BoxShape.circle,
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        '${(progress * 100).toInt()}%',
                                        style: TextStyleCustom.outFitMedium500(
                                          color: whitePure(context),
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                  Positioned(
                                    bottom: 0,
                                    right: 4,
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: accent,
                                        shape: BoxShape.circle,
                                        boxShadow: ClientColors.neonGlow(
                                          color: accent,
                                          alpha: 0.5,
                                          blur: 10,
                                          offset: Offset.zero,
                                        ),
                                      ),
                                      child: Icon(
                                        Icons.camera_alt,
                                        size: 16,
                                        color: whitePure(context),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            TextButton(
                              onPressed: controller.onPickPhoto,
                              child: Text(
                                LKey.editProfile.tr,
                                style: TextStyleCustom.outFitMedium500(
                                  color: accent,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        );
                      }),
                      const SizedBox(height: 12),
                      TextFieldCustom(
                        title: LKey.fullName.tr,
                        controller: controller.fullNameController,
                        showChevron: true,
                        prefixIcon: Padding(
                          padding: const EdgeInsets.only(left: 12, right: 4),
                          child: Icon(Icons.person_outline_rounded,
                              color: accent, size: 22),
                        ),
                      ),
                      TextFieldCustom(
                        title: LKey.username.tr,
                        controller: controller.usernameController,
                        showChevron: true,
                        prefixIcon: Padding(
                          padding: const EdgeInsets.only(left: 12, right: 4),
                          child: Icon(Icons.alternate_email_rounded,
                              color: accent, size: 22),
                        ),
                      ),
                      TextFieldCustom(
                        title: LKey.bio.tr,
                        controller: controller.bioController,
                        height: 110,
                        prefixIcon: Padding(
                          padding: const EdgeInsets.only(left: 12, right: 4, top: 12),
                          child: Icon(Icons.edit_outlined,
                              color: accent, size: 22),
                        ),
                      ),
                      TextFieldCustom(
                        title: LKey.email.tr,
                        controller: controller.emailController,
                        keyboardType: TextInputType.emailAddress,
                        prefixIcon: Padding(
                          padding: const EdgeInsets.only(left: 12, right: 4),
                          child: Icon(Icons.mail_outline_rounded,
                              color: accent, size: 22),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Obx(
                        () => TextButtonCustom(
                          onTap: controller.isSaving.value
                              ? () {}
                              : controller.onSave,
                          title: LKey.save.tr,
                          gradient: true,
                          titleColor: whitePure(context),
                          radius: 24,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Obx(() {
            if (!controller.isSaving.value) {
              return const SizedBox.shrink();
            }
            return const Positioned.fill(
              child: ColoredBox(
                color: Color(0x66000000),
                child: LoaderWidget(),
              ),
            );
          }),
        ],
      ),
    ),
    );
  }
}

class _PickedAvatar extends StatelessWidget {
  final XFile file;

  const _PickedAvatar({required this.file});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List>(
      future: file.readAsBytes(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return ClipOval(
            child: Image.memory(
              snapshot.data!,
              width: 110,
              height: 110,
              fit: BoxFit.cover,
            ),
          );
        }
        return Container(
          width: 110,
          height: 110,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: bgGrey(context),
          ),
          child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        );
      },
    );
  }
}
