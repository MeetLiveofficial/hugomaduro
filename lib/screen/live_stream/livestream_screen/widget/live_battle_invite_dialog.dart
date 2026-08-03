import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krimson/common/extensions/string_extension.dart';
import 'package:krimson/common/manager/livekit_room_controller.dart';
import 'package:krimson/common/manager/logger.dart';
import 'package:krimson/common/manager/session_manager.dart';
import 'package:krimson/common/service/api/live_session_service.dart';
import 'package:krimson/common/widget/custom_image.dart';
import 'package:krimson/model/livestream/livestream.dart';
import 'package:krimson/screen/live_stream/livestream_screen/host/livestream_host_screen.dart';
import 'package:krimson/screen/live_stream/livestream_screen/livestream_screen_controller.dart';
import 'package:krimson/utilities/color_res.dart';
import 'package:krimson/utilities/text_style_custom.dart';

/// Pantalla completa: "{host} te invita a una BATALLA" → Aceptar / Rechazar.
class LiveBattleInviteDialog extends StatefulWidget {
  final Livestream livestream;

  const LiveBattleInviteDialog({super.key, required this.livestream});

  static final Set<String> _shownRoomIds = {};
  static bool _opening = false;

  /// Muestra una sola vez por room mientras la batalla esté en WAITING.
  static Future<void> showIfNeeded(Livestream stream) async {
    final roomId = stream.roomID ?? '';
    if (roomId.isEmpty) return;
    if (stream.battleType != BattleType.waiting) return;
    if (stream.type != LivestreamType.battle) return;
    if (_shownRoomIds.contains(roomId) || _opening) return;

    final me = SessionManager.instance.getUserID();
    final hostId = stream.hostId ?? 0;
    if (me <= 0 || me == hostId) return;

    // Solo el rival listado en co-hosts.
    final opponents = (stream.coHostIds ?? [])
        .where((id) => id > 0 && id != hostId)
        .toList();
    if (opponents.isNotEmpty && !opponents.contains(me)) return;

    final ctx = Get.overlayContext ?? Get.context;
    if (ctx == null) return;

    _opening = true;
    _shownRoomIds.add(roomId);
    try {
      await showGeneralDialog(
        context: ctx,
        barrierDismissible: false,
        barrierLabel: 'battle_invite',
        barrierColor: Colors.black.withValues(alpha: 0.92),
        useRootNavigator: true,
        pageBuilder: (context, animation, secondaryAnimation) {
          return LiveBattleInviteDialog(livestream: stream);
        },
        transitionBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      );
    } finally {
      _opening = false;
    }
  }

  static void clearShown(String roomId) => _shownRoomIds.remove(roomId);

  @override
  State<LiveBattleInviteDialog> createState() => _LiveBattleInviteDialogState();
}

class _LiveBattleInviteDialogState extends State<LiveBattleInviteDialog> {
  bool _busy = false;

  Livestream get livestream => widget.livestream;

  Future<void> _respond(bool accept) async {
    if (_busy) return;
    final roomId = livestream.roomID;
    if (roomId == null || roomId.isEmpty) return;

    setState(() => _busy = true);
    try {
      final result = await LiveSessionService.instance.respondBattle(
        roomId: roomId,
        accept: accept,
      );
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();

      if (!accept || !result.accepted) {
        LiveBattleInviteDialog.clearShown(roomId);
        return;
      }

      LiveBattleInviteDialog.clearShown(roomId);

      // No usar endOrLeave(): tumba endBattle/leave y borra la sala del rival
      // que acabamos de dejar en RUNNING (desaparece del listado PK).
      final myLive = result.opponentSession ?? result.session;
      final keepRoom = (myLive.roomID ?? '').trim();
      final prev = LivestreamScreenController.activeInstance;
      if (prev != null) {
        try {
          await prev.handoffCleanup(
            preserveLaravelSession: prev.roomId == keepRoom,
          );
        } catch (e) {
          Loggers.error('cleanup before battle accept: $e');
        }
        await Future.delayed(const Duration(milliseconds: 250));
      }

      // El rival abre SU propia sala (vinculada) como host.
      final hostTag = 'live_${myLive.roomID}';
      final lkTag = 'lk_live_${myLive.roomID}';
      if (Get.isRegistered<LivestreamScreenController>(tag: hostTag)) {
        Get.delete<LivestreamScreenController>(tag: hostTag, force: true);
      }
      if (Get.isRegistered<LiveKitRoomController>(tag: lkTag)) {
        try {
          await Get.find<LiveKitRoomController>(tag: lkTag).disconnect();
        } catch (_) {}
        Get.delete<LiveKitRoomController>(tag: lkTag, force: true);
      }

      Get.to(
        () => LivestreamHostScreen(isHost: true, livestream: myLive),
      );
    } catch (e) {
      Loggers.error('respondBattle dialog: $e');
      if (mounted) {
        setState(() => _busy = false);
        Get.snackbar(
          'Batalla',
          e.toString(),
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.black87,
          colorText: Colors.white,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final host = livestream.hostUser;
    final name = host?.fullname ?? host?.username ?? 'Alguien';
    final photo = host?.profile;
    final minutes = livestream.battleDuration > 0
        ? livestream.battleDuration
        : 5;

    return Material(
      color: const Color(0xFF0B0F14),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          child: Column(
            children: [
              const Spacer(flex: 2),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: ColorRes.themeAccentSolid.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: ColorRes.themeAccentSolid.withValues(alpha: 0.7),
                  ),
                ),
                child: Text(
                  'BATALLA',
                  style: TextStyleCustom.outFitSemiBold600(
                    color: ColorRes.themeAccentSolid,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(height: 28),
              CustomImage(
                size: const Size(110, 110),
                strokeWidth: 2,
                strokeColor: ColorRes.themeAccentSolid,
                image: photo?.addBaseURL(),
                fullName: name,
              ),
              const SizedBox(height: 22),
              Text(
                name,
                textAlign: TextAlign.center,
                style: TextStyleCustom.unboundedSemiBold600(
                  color: Colors.white,
                  fontSize: 22,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'te está invitando a una batalla',
                textAlign: TextAlign.center,
                style: TextStyleCustom.outFitMedium500(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Duración: $minutes min',
                style: TextStyleCustom.outFitRegular400(
                  color: Colors.white54,
                  fontSize: 14,
                ),
              ),
              const Spacer(flex: 3),
              if (_busy)
                const Padding(
                  padding: EdgeInsets.only(bottom: 24),
                  child: CircularProgressIndicator(
                    color: ColorRes.themeAccentSolid,
                  ),
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _respond(false),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white70,
                          side: const BorderSide(color: Colors.white38),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                        ),
                        child: Text(
                          'Rechazar',
                          style: TextStyleCustom.outFitMedium500(
                            color: Colors.white70,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _respond(true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ColorRes.themeAccentSolid,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                        ),
                        child: Text(
                          'Aceptar',
                          style: TextStyleCustom.outFitSemiBold600(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
