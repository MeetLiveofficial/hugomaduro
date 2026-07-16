import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krimson/model/call/call_request_model.dart';
import 'package:krimson/screen/call_screen/incoming_call_screen.dart';
import 'package:krimson/screen/live_stream/livestream_screen/livestream_screen_controller.dart';

/// Muestra la llamada entrante sobre LIVE: panel inferior = 50% de altura.
class LiveIncomingCallOverlay {
  LiveIncomingCallOverlay._();

  static bool _opening = false;

  static Future<void> show(CallRequestModel call) async {
    final id = call.id;
    if (id == null) return;
    if (LivestreamScreenController.activeInstance == null) return;

    final tag = 'incoming_$id';
    if (Get.isRegistered<IncomingCallController>(tag: tag)) return;
    if (_opening) return;
    if (Get.isDialogOpen == true) return;

    final ctx = Get.overlayContext ?? Get.context;
    if (ctx == null) return;

    _opening = true;
    try {
      await showGeneralDialog(
        context: ctx,
        barrierDismissible: false,
        barrierLabel: 'incoming_call',
        barrierColor: Colors.black38,
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
    } finally {
      _opening = false;
    }
  }
}
