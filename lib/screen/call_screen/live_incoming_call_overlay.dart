import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krimson/model/call/call_request_model.dart';
import 'package:krimson/screen/call_screen/incoming_call_screen.dart';
import 'package:krimson/screen/call_screen/outgoing_call_screen.dart';

/// Overlay de llamada entrante: always half-sheet (no fullscreen).
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

    _opening = true;
    try {
      await showGeneralDialog(
        context: ctx,
        barrierDismissible: false,
        barrierLabel: 'incoming_call',
        barrierColor: Colors.black54,
        useRootNavigator: true,
        pageBuilder: (context, animation, secondaryAnimation) {
          return IncomingCallScreen(call: call, asDialog: true);
        },
        transitionBuilder: (context, animation, secondaryAnimation, child) {
          final offset = Tween<Offset>(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut));
          return SlideTransition(position: offset, child: child);
        },
      );
      return true;
    } finally {
      _opening = false;
    }
  }
}
