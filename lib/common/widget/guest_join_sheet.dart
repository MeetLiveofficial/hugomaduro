import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krimson/common/manager/app_role.dart';
import 'package:krimson/common/widget/text_button_custom.dart';
import 'package:krimson/languages/languages_keys.dart';
import 'package:krimson/screen/auth_screen/auth_screen_controller.dart';
import 'package:krimson/screen/auth_screen/registration_screen.dart';
import 'package:krimson/utilities/client_colors.dart';
import 'package:krimson/utilities/color_res.dart';
import 'package:krimson/utilities/text_style_custom.dart';
import 'package:krimson/utilities/theme_res.dart';

class GuestJoinSheet extends StatelessWidget {
  static const String routeName = 'guest-join-sheet';

  const GuestJoinSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final client = AppRole.isClient();
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
      decoration: BoxDecoration(
        color: client ? ClientColors.surface : ColorRes.whitePure,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
        border: client
            ? Border(
                top: BorderSide(
                    color: ClientColors.magenta.withValues(alpha: 0.55)),
              )
            : null,
        boxShadow: client
            ? ClientColors.neonGlow(color: ClientColors.magenta, alpha: 0.35)
            : null,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: client ? ClientColors.magenta : ColorRes.bgGrey,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 20),
            if (client)
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: ClientColors.magenta.withValues(alpha: 0.16),
                  border: Border.all(
                    color: ClientColors.magenta.withValues(alpha: 0.55),
                  ),
                  boxShadow: ClientColors.neonGlow(
                    color: ClientColors.magentaHot,
                    alpha: 0.4,
                    blur: 16,
                  ),
                ),
                child: const Icon(Icons.person_add_alt_1_rounded,
                    size: 34, color: ClientColors.magentaHot),
              )
            else
              const Icon(Icons.person_add_alt_1_rounded,
                  size: 42, color: ColorRes.crimson),
            const SizedBox(height: 14),
            Text(
              LKey.joinToContinue.tr,
              textAlign: TextAlign.center,
              style: TextStyleCustom.unboundedBlack900(
                fontSize: 18,
                color: client ? ClientColors.text : textDarkGrey(context),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              LKey.joinToContinueDescription.tr,
              textAlign: TextAlign.center,
              style: TextStyleCustom.outFitRegular400(
                fontSize: 15,
                color: client ? ClientColors.textMuted : textLightGrey(context),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              LKey.guestAccountExpires.tr,
              textAlign: TextAlign.center,
              style: TextStyleCustom.outFitRegular400(
                fontSize: 13,
                color: client ? ClientColors.textMuted : textLightGrey(context),
              ),
            ),
            const SizedBox(height: 22),
            TextButtonCustom(
              onTap: () {
                if (Get.isBottomSheetOpen == true) {
                  Get.back();
                }
                if (!Get.isRegistered<AuthScreenController>()) {
                  Get.put(AuthScreenController());
                }
                Get.to(() => const RegistrationScreen());
              },
              title: LKey.joinNow.tr,
              gradient: true,
              horizontalMargin: 0,
              titleColor: whitePure(context),
              radius: 25,
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Get.back(),
              child: Text(
                LKey.later.tr,
                style: TextStyleCustom.outFitMedium500(
                  fontSize: 15,
                  color: client ? ClientColors.primary : textLightGrey(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
