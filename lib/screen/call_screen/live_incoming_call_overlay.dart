import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krimson/model/call/call_request_model.dart';
import 'package:krimson/screen/call_screen/incoming_call_screen.dart';
import 'package:krimson/screen/call_screen/outgoing_call_screen.dart';

/// Overlay de llamada entrante: always half-sheet (no fullscreen).
class LiveIncomingCallOverlay {
  LiveIncomingCallOverlay._();

  static bool _opening = false;

  /// Cierra overlay/dialog de llamada entrante si sigue abierto.
  static void dismiss({int? callId}) {
    if (callId != null) {
      IncomingCallController.forceDismiss(callId);
    }
  }

  /// `true` si se presentó el diálogo (o ya estaba abierto el mismo call).
  static Future<bool> show(CallRequestModel call) async {
    final id = call.id;
    if (id == null) return false;

    final tag = 'incoming_$id';
    if (Get.isRegistered<IncomingCallController>(tag: tag)) return true;
    if (_opening) return false;
    if (Get.isDialogOpen == true) return false;
    if (OutgoingCallController.activeInstance != null) {
      final outgoing = OutgoingCallController.activeInstance!;
      if (outgoing.isMatch && call.isMatchSession) {
        final peerId = outgoing.callee.id;
        if (call.callerId == peerId || call.calleeId == peerId) {
          OutgoingCallController.handleCrossedMatch(call);
          return true;
        }
      }
      return false;
    }
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
