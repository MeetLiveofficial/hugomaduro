import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:krimson/common/controller/base_controller.dart';
import 'package:krimson/common/manager/share_manager.dart';
import 'package:krimson/common/service/api/user_service.dart';
import 'package:krimson/common/service/navigation/navigate_with_controller.dart';
import 'package:krimson/common/widget/custom_app_bar.dart';
import 'package:krimson/common/widget/custom_back_button.dart';
import 'package:krimson/languages/languages_keys.dart';
import 'package:krimson/model/user_model/user_model.dart';
import 'package:krimson/utilities/text_style_custom.dart';
import 'package:krimson/utilities/theme_res.dart';

class ScanQrCodeScreen extends StatefulWidget {
  const ScanQrCodeScreen({super.key});

  @override
  State<ScanQrCodeScreen> createState() => _ScanQrCodeScreenState();
}

class _ScanQrCodeScreenState extends State<ScanQrCodeScreen> {
  final MobileScannerController? _scannerController =
      kIsWeb ? null : MobileScannerController();
  bool _isHandling = false;

  @override
  void dispose() {
    _scannerController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return Scaffold(
        body: Column(
          children: [
            CustomAppBar(title: LKey.scanQrCode.tr),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.qr_code_scanner,
                      size: 72,
                      color: textLightGrey(context),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      LKey.scanQrCode.tr,
                      style: TextStyleCustom.unboundedSemiBold600(
                        color: textDarkGrey(context),
                        fontSize: 18,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'QR scanning is not available in the web browser. Use the Android or iOS app to scan profile QR codes.',
                      style: TextStyleCustom.outFitRegular400(
                        color: textLightGrey(context),
                        fontSize: 15,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    TextButton(
                      onPressed: () => Get.back(),
                      child: Text(LKey.getBack.tr),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: blackPure(context),
      body: Stack(
        children: [
          MobileScanner(
            controller: _scannerController,
            onDetect: _onDetect,
          ),
          SafeArea(
            child: Column(
              children: [
                Row(
                  children: [
                    CustomBackButton(
                      padding: const EdgeInsets.all(15),
                      color: whitePure(context),
                    ),
                    Expanded(
                      child: Text(
                        LKey.scanQrCode.tr,
                        style: TextStyleCustom.unboundedMedium500(
                          color: whitePure(context),
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
                  child: Text(
                    LKey.scanQrProfileSearch.tr,
                    style: TextStyleCustom.outFitRegular400(
                      color: whitePure(context),
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
          Center(
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                border: Border.all(color: themeAccentSolid(context), width: 2),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_isHandling) return;
    final raw = capture.barcodes
        .map((b) => b.rawValue)
        .whereType<String>()
        .firstWhere((v) => v.trim().isNotEmpty, orElse: () => '');
    if (raw.isEmpty) return;

    _isHandling = true;
    await _scannerController?.stop();

    try {
      final userId = _parseUserIdFromQr(raw);
      if (userId == null) {
        BaseController.share.showSnackBar(LKey.userNotFound.tr);
        await _scannerController?.start();
        _isHandling = false;
        return;
      }

      User? user = await UserService.instance.fetchUserDetails(userId: userId);
      if (user == null) {
        BaseController.share.showSnackBar(LKey.userNotFound.tr);
        await _scannerController?.start();
        _isHandling = false;
        return;
      }

      Get.back();
      await NavigationService.shared.openProfileScreen(user);
    } catch (_) {
      BaseController.share.showSnackBar(LKey.userNotFound.tr);
      await _scannerController?.start();
      _isHandling = false;
    }
  }

  int? _parseUserIdFromQr(String raw) {
    try {
      final uri = Uri.tryParse(raw.trim());
      String encoded = raw.trim();
      if (uri != null && uri.pathSegments.isNotEmpty) {
        encoded = uri.pathSegments.last;
      }

      final decoded = ShareManager.shared.safeBase64Decode(encoded);
      final parts = decoded.split('_');
      if (parts.length >= 2 && parts.first == ShareKeys.user.value) {
        return int.tryParse(parts.last);
      }

      // Fallback: plain numeric user id
      return int.tryParse(raw.trim());
    } catch (_) {
      return int.tryParse(raw.trim());
    }
  }
}
