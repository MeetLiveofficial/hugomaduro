import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krimson/common/extensions/string_extension.dart';
import 'package:krimson/common/service/api/call_service.dart';
import 'package:krimson/common/widget/custom_image.dart';
import 'package:krimson/languages/languages_keys.dart';
import 'package:krimson/model/call/call_request_model.dart';
import 'package:krimson/screen/call_screen/video_call_screen.dart';
import 'package:krimson/utilities/asset_res.dart';
import 'package:krimson/utilities/color_res.dart';
import 'package:krimson/utilities/text_style_custom.dart';
import 'package:krimson/utilities/theme_res.dart';

/// Pantalla entrante estilo WhatsApp.
class IncomingCallScreen extends StatelessWidget {
  final CallRequestModel call;

  const IncomingCallScreen({super.key, required this.call});

  @override
  Widget build(BuildContext context) {
    final tag = 'incoming_${call.id}';
    final controller = Get.isRegistered<IncomingCallController>(tag: tag)
        ? Get.find<IncomingCallController>(tag: tag)
        : Get.put(IncomingCallController(call), tag: tag);
    final peer = call.caller;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: const Color(0xFF0B0F14),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              children: [
                const SizedBox(height: 28),
                Text(
                  LKey.incomingCall.tr,
                  style: TextStyleCustom.outFitRegular400(
                    color: whitePure(context).withValues(alpha: 0.75),
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 36),
                CustomImage(
                  size: const Size(120, 120),
                  image: peer?.profilePhoto?.addBaseURL(),
                  fullName: peer?.fullname ?? peer?.username,
                  strokeWidth: 0,
                ),
                const SizedBox(height: 22),
                Text(
                  peer?.fullname ?? peer?.username ?? '-',
                  textAlign: TextAlign.center,
                  style: TextStyleCustom.unboundedSemiBold600(
                    color: whitePure(context),
                    fontSize: 24,
                  ),
                ),
                if ((peer?.username ?? '').isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    '@${peer!.username}',
                    style: TextStyleCustom.outFitRegular400(
                      color: whitePure(context).withValues(alpha: 0.55),
                      fontSize: 14,
                    ),
                  ),
                ],
                if (call.coinsCost > 0) ...[
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(AssetRes.icCoin, height: 16, width: 16),
                      const SizedBox(width: 6),
                      Text(
                        '${call.coinsCost}',
                        style: TextStyleCustom.outFitMedium500(
                          color: whitePure(context),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ],
                const Spacer(),
                Obx(() {
                  final err = controller.errorText.value;
                  if (err == null || err.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      err,
                      textAlign: TextAlign.center,
                      style: TextStyleCustom.outFitRegular400(
                        color: ColorRes.likeRed,
                        fontSize: 14,
                      ),
                    ),
                  );
                }),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _CircleAction(
                      color: ColorRes.likeRed,
                      icon: Icons.call_end,
                      label: LKey.refuse.tr,
                      onTap: controller.reject,
                    ),
                    _CircleAction(
                      color: const Color(0xFF22C55E),
                      icon: Icons.videocam,
                      label: LKey.accept.tr,
                      onTap: controller.accept,
                    ),
                  ],
                ),
                const SizedBox(height: 36),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CircleAction extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _CircleAction({
    required this.color,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(40),
          child: CircleAvatar(
            radius: 34,
            backgroundColor: color,
            child: Icon(icon, color: Colors.white, size: 30),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          label,
          style: TextStyleCustom.outFitMedium500(
            color: whitePure(context).withValues(alpha: 0.85),
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}

class IncomingCallController extends GetxController {
  IncomingCallController(this.call);

  CallRequestModel call;
  final RxnString errorText = RxnString();
  bool _busy = false;

  Future<void> accept() async {
    if (_busy || call.id == null) return;
    _busy = true;
    try {
      final updated = await CallService.instance.accept(call.id!);
      Get.off(() => VideoCallScreen(call: updated));
    } catch (e) {
      errorText.value = e.toString().replaceFirst('Exception: ', '');
      _busy = false;
    }
  }

  Future<void> reject() async {
    if (_busy || call.id == null) return;
    _busy = true;
    try {
      await CallService.instance.reject(call.id!);
      if (Get.key.currentState?.canPop() == true) Get.back();
    } catch (e) {
      errorText.value = e.toString().replaceFirst('Exception: ', '');
      _busy = false;
    }
  }
}
