import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krimson/model/call/call_request_model.dart';
import 'package:krimson/screen/call_screen/incoming_call_screen.dart';
import 'package:krimson/screen/call_screen/outgoing_call_screen.dart';
import 'package:krimson/screen/live_stream/livestream_screen/livestream_screen_controller.dart';

/// Overlay de llamada entrante: half-sheet en LIVE, pantalla completa fuera de LIVE.
class LiveIncomingCallOverlay {
  LiveIncomingCallOverlay._();

  static bool _opening = false;

  /// `true` si se presentó el diálogo (o ya estaba abierto el mismo call).
  static Future<bool> show(CallRequestModel call) async {
    final id = call.id;
    if (id == null) return false;

    final tag = 'incoming_$id';
    if (Get.isRegistered<IncomingCallController>(tag: tag)) return true;
    if (_opening) return false;
    if (Get.isDialogOpen == true) return false;
    if (OutgoingCallController.activeInstance != null) return false;
    if (Get.currentRoute.contains('VideoCall') ||
        Get.currentRoute.contains('OutgoingCall')) {
      return false;
    }

    final ctx = Get.overlayContext ?? Get.context;
    if (ctx == null) return false;

    final onLive = LivestreamScreenController.activeInstance != null;

    _opening = true;
    try {
      await showGeneralDialog(
        context: ctx,
        barrierDismissible: false,
        barrierLabel: 'incoming_call',
        barrierColor: onLive ? Colors.black38 : const Color(0xFF0B0F14),
        useRootNavigator: true,
        pageBuilder: (context, animation, secondaryAnimation) {
          return IncomingCallScreen(call: call, asDialog: onLive);
        },
        transitionBuilder: (context, animation, secondaryAnimation, child) {
          if (onLive) {
            final offset = Tween<Offset>(
              begin: const Offset(0, 1),
              end: Offset.zero,
            ).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOut));
            return SlideTransition(position: offset, child: child);
          }
          return FadeTransition(
            opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.92, end: 1).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOut),
              ),
              child: child,
            ),
          );
        },
      );
      return true;
    } finally {
      _opening = false;
    }
  }
}
