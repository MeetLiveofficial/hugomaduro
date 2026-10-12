import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krimson/common/manager/session_manager.dart';
import 'package:krimson/common/service/api/app_update_service.dart';
import 'package:krimson/languages/languages_keys.dart';
import 'package:krimson/screen/auth_screen/login_screen.dart';

/// Imagen de bienvenida. Se muestra una vez, antes del primer login.
class WelcomeBannerScreen extends StatefulWidget {
  const WelcomeBannerScreen({super.key});

  @override
  State<WelcomeBannerScreen> createState() => _WelcomeBannerScreenState();
}

class _WelcomeBannerScreenState extends State<WelcomeBannerScreen> {
  bool _left = false;

  void _continue() {
    if (_left) return;
    _left = true;
    SessionManager.instance.setBool(SessionKeys.welcomeBannerSeen, true);
    Get.offAll(() => const LoginScreen(), routeName: '/login');
    unawaited(AppUpdateService.instance.maybeShowUpdateDialog());
  }

  @override
  Widget build(BuildContext context) {
    final url = SessionManager.instance.getSettings()?.welcomeBannerUrl ?? '';
    if (url.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _continue());
    }

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: const Color(0xFF0B0B10),
        body: Column(
          children: [
            Expanded(
              child: url.isEmpty
                  ? const SizedBox.shrink()
                  : CachedNetworkImage(
                      imageUrl: url,
                      fit: BoxFit.contain,
                      memCacheWidth: 1280,
                      maxWidthDiskCache: 1280,
                      fadeInDuration: const Duration(milliseconds: 160),
                      placeholder: (_, __) => const Center(
                        child: SizedBox(
                          width: 28,
                          height: 28,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white70,
                          ),
                        ),
                      ),
                      errorWidget: (_, __, ___) {
                        WidgetsBinding.instance
                            .addPostFrameCallback((_) => _continue());
                        return const SizedBox.shrink();
                      },
                    ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _continue,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF0B0B10),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    child: Text(
                      LKey.continueText.tr,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
