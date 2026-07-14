import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krimson/common/manager/session_manager.dart';
import 'package:krimson/common/widget/text_button_custom.dart';
import 'package:krimson/languages/languages_keys.dart';
import 'package:krimson/screen/auth_screen/login_screen.dart';
import 'package:krimson/utilities/text_style_custom.dart';
import 'package:krimson/utilities/theme_res.dart';

enum SessionType { freeze, unauthorized }

class SessionExpiredScreen extends StatelessWidget {
  final SessionType type;

  const SessionExpiredScreen({super.key, required this.type});

  @override
  Widget build(BuildContext context) {
    final isFrozen = type == SessionType.freeze;
    return Scaffold(
      backgroundColor: scaffoldBackgroundColor(context),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isFrozen ? Icons.ac_unit : Icons.lock_outline,
                size: 56,
                color: textDarkGrey(context),
              ),
              const SizedBox(height: 16),
              Text(
                isFrozen
                    ? 'Tu cuenta está congelada'
                    : 'Sesión expirada',
                textAlign: TextAlign.center,
                style: TextStyleCustom.unboundedMedium500(
                  color: textDarkGrey(context),
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                isFrozen
                    ? 'Contacta al administrador para reactivar tu cuenta.'
                    : 'Vuelve a iniciar sesión para continuar.',
                textAlign: TextAlign.center,
                style: TextStyleCustom.outFitRegular400(
                  color: textLightGrey(context),
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 28),
              TextButtonCustom(
                onTap: () {
                  SessionManager.instance.clearSomeKey();
                  Get.offAll(() => const LoginScreen(), routeName: '/login');
                },
                title: LKey.logIn.tr,
                backgroundColor: themeAccentSolid(context),
                titleColor: whitePure(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
