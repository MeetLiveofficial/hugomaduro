import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
import 'package:krimson/common/extensions/string_extension.dart';
import 'package:krimson/common/manager/logger.dart';
import 'package:krimson/common/service/api/call_service.dart';
import 'package:krimson/common/widget/custom_image.dart';
import 'package:krimson/languages/languages_keys.dart';
import 'package:krimson/model/call/call_request_model.dart';
import 'package:krimson/screen/call_screen/video_call_screen.dart';
import 'package:krimson/screen/live_stream/livestream_screen/livestream_screen_controller.dart';
import 'package:krimson/utilities/asset_res.dart';
import 'package:krimson/utilities/color_res.dart';
import 'package:krimson/utilities/text_style_custom.dart';
import 'package:krimson/utilities/theme_res.dart';

/// Pantalla / diálogo entrante estilo WhatsApp.
class IncomingCallScreen extends StatelessWidget {
  final CallRequestModel call;
  final bool asDialog;

  const IncomingCallScreen({
    super.key,
    required this.call,
    this.asDialog = false,
  });

  @override
  Widget build(BuildContext context) {
    final tag = 'incoming_${call.id}';
    final controller = Get.isRegistered<IncomingCallController>(tag: tag)
        ? Get.find<IncomingCallController>(tag: tag)
        : Get.put(IncomingCallController(call), tag: tag);
    final peer = call.caller;

    if (asDialog) {
      // Panel inferior = mitad de pantalla (el LIVE sigue visible arriba).
      final h = MediaQuery.sizeOf(context).height;
      return Material(
        color: Colors.transparent,
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            width: double.infinity,
            height: h * 0.5,
            decoration: const BoxDecoration(
              color: Color(0xFF0B0F14),
              borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                child: Column(
                  children: [
                    Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      LKey.incomingCall.tr,
                      style: TextStyleCustom.outFitRegular400(
                        color: whitePure(context).withValues(alpha: 0.75),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 12),
                    CustomImage(
                      size: const Size(72, 72),
                      image: peer?.profilePhoto?.addBaseURL(),
                      fullName: peer?.fullname ?? peer?.username,
                      strokeWidth: 0,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      peer?.fullname ?? peer?.username ?? '-',
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyleCustom.unboundedSemiBold600(
                        color: whitePure(context),
                        fontSize: 18,
                      ),
                    ),
                    if ((peer?.username ?? '').isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        '@${peer!.username}',
                        style: TextStyleCustom.outFitRegular400(
                          color: whitePure(context).withValues(alpha: 0.55),
                          fontSize: 13,
                        ),
                      ),
                    ],
                    Obx(() {
                      final err = controller.errorText.value;
                      if (err == null || err.isEmpty) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          err,
                          textAlign: TextAlign.center,
                          style: TextStyleCustom.outFitRegular400(
                            color: Colors.redAccent,
                            fontSize: 12,
                          ),
                        ),
                      );
                    }),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _CircleAction(
                          color: Colors.red,
                          icon: Icons.call_end,
                          label: 'Decline',
                          compact: true,
                          onTap: controller.reject,
                        ),
                        _CircleAction(
                          color: ColorRes.themeAccentSolid,
                          icon: Icons.call,
                          label: LKey.accept.tr,
                          compact: true,
                          onTap: controller.accept,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    final content = SafeArea(
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
            Center(
              child: CustomImage(
                size: const Size(120, 120),
                image: peer?.profilePhoto?.addBaseURL(),
                fullName: peer?.fullname ?? peer?.username,
                strokeWidth: 0,
              ),
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
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  err,
                  textAlign: TextAlign.center,
                  style: TextStyleCustom.outFitRegular400(
                    color: Colors.redAccent,
                    fontSize: 13,
                  ),
                ),
              );
            }),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _CircleAction(
                  color: Colors.red,
                  icon: Icons.call_end,
                  label: 'Decline',
                  onTap: controller.reject,
                ),
                _CircleAction(
                  color: ColorRes.themeAccentSolid,
                  icon: Icons.call,
                  label: LKey.accept.tr,
                  onTap: controller.accept,
                ),
              ],
            ),
            const SizedBox(height: 28),
          ],
        ),
      ),
    );

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: const Color(0xFF0B0F14),
        body: content,
      ),
    );
  }
}

class _CircleAction extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool compact;

  const _CircleAction({
    required this.color,
    required this.icon,
    required this.label,
    required this.onTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final radius = compact ? 26.0 : 34.0;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(40),
          child: CircleAvatar(
            radius: radius,
            backgroundColor: color,
            child: Icon(icon, color: Colors.white, size: compact ? 24 : 30),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyleCustom.outFitMedium500(
            color: whitePure(context).withValues(alpha: 0.85),
            fontSize: compact ? 12 : 13,
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
  final AudioPlayer _ringtone = AudioPlayer();

  @override
  void onInit() {
    super.onInit();
    _startRingtone();
  }

  @override
  void onClose() {
    _stopRingtone();
    try {
      _ringtone.dispose();
    } catch (_) {}
    super.onClose();
  }

  Future<void> _startRingtone() async {
    try {
      await _ringtone.setAsset(AssetRes.callSoft);
      await _ringtone.setLoopMode(LoopMode.one);
      await _ringtone.setVolume(0.45);
      await _ringtone.play();
    } catch (e) {
      Loggers.error('incoming ringtone: $e');
    }
  }

  Future<void> _stopRingtone() async {
    try {
      await _ringtone.stop();
    } catch (_) {}
  }

  void _closeIncomingUi() {
    final ctx = Get.overlayContext ?? Get.context;
    if (ctx != null) {
      final nav = Navigator.of(ctx, rootNavigator: true);
      if (nav.canPop()) {
        nav.pop();
        return;
      }
    }
    if (Get.isDialogOpen == true || Get.key.currentState?.canPop() == true) {
      Get.back();
    }
  }

  Future<void> accept() async {
    if (_busy || call.id == null) return;
    _busy = true;
    await _stopRingtone();
    try {
      final updated = await CallService.instance.accept(call.id!);
      final live = LivestreamScreenController.activeInstance;
      final keepLive = live != null;
      // Liberar cámara/mic del LIVE para que la videollamada pueda conectar.
      if (keepLive) {
        try {
          await live.pauseLiveKitForCall();
        } catch (_) {}
      }
      _closeIncomingUi();
      await Future.delayed(const Duration(milliseconds: 80));
      if (keepLive) {
        Get.to(() => VideoCallScreen(call: updated, resumeLiveOnHangup: true));
      } else {
        Get.off(() => VideoCallScreen(call: updated));
      }
    } catch (e) {
      errorText.value = e.toString().replaceFirst('Exception: ', '');
      _busy = false;
      await _startRingtone();
    }
  }

  Future<void> reject() async {
    if (_busy || call.id == null) return;
    _busy = true;
    await _stopRingtone();
    try {
      await CallService.instance.reject(call.id!);
      _closeIncomingUi();
    } catch (e) {
      errorText.value = e.toString().replaceFirst('Exception: ', '');
      _busy = false;
    }
  }
}
