import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krimson/common/extensions/string_extension.dart';
import 'package:krimson/common/widget/custom_image.dart';
import 'package:krimson/languages/languages_keys.dart';
import 'package:krimson/model/livestream/livestream.dart';
import 'package:krimson/screen/live_stream/livestream_screen/audience/live_stream_audience_screen.dart';
import 'package:krimson/screen/live_stream/livestream_screen/host/livestream_host_screen.dart';
import 'package:krimson/common/manager/session_manager.dart';
import 'package:krimson/utilities/text_style_custom.dart';
import 'package:krimson/utilities/theme_res.dart';

/// Diálogo in-app: "{host} te invita a su LIVE" → Unirse / Más tarde.
class LiveInviteDialog extends StatelessWidget {
  final Livestream livestream;

  const LiveInviteDialog({super.key, required this.livestream});

  static final Set<String> _shownRoomIds = {};

  /// Muestra el diálogo una sola vez por room (evita spam de poll/FCM).
  static Future<void> showIfNeeded(Livestream stream) async {
    final roomId = stream.roomID ?? '${stream.hostId ?? ''}';
    if (roomId.isEmpty) return;
    if (_shownRoomIds.contains(roomId)) return;
    final ctx = Get.context;
    if (ctx == null) return;

    // Ya estoy en ese LIVE.
    if (Get.currentRoute.contains(roomId)) return;

    _shownRoomIds.add(roomId);
    await Get.dialog(
      LiveInviteDialog(livestream: stream),
      barrierDismissible: true,
      barrierColor: Colors.black54,
    );
  }

  static void clearShown(String roomId) => _shownRoomIds.remove(roomId);

  void _join() {
    Get.back();
    final me = SessionManager.instance.getUser();
    final stream = livestream;
    if (stream.hostId == me?.id) {
      Get.to(() => LivestreamHostScreen(isHost: true, livestream: stream));
    } else {
      Get.to(() => LiveStreamAudienceScreen(isHost: false, livestream: stream));
    }
  }

  @override
  Widget build(BuildContext context) {
    final host = livestream.hostUser;
    final name = host?.fullname ?? host?.username ?? 'Someone';
    final photo = host?.profile;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomImage(
              size: const Size(72, 72),
              strokeWidth: 0,
              image: photo?.addBaseURL(),
              fullName: name,
            ),
            const SizedBox(height: 14),
            Text(
              '$name ${LKey.invitesYouToLive.tr}',
              textAlign: TextAlign.center,
              style: TextStyleCustom.unboundedSemiBold600(
                color: textDarkGrey(context),
                fontSize: 16,
              ),
            ),
            if ((livestream.description ?? '').trim().isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                livestream.description!.trim(),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyleCustom.outFitRegular400(
                  color: textLightGrey(context),
                  fontSize: 13,
                ),
              ),
            ],
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Get.back(),
                    child: Text(LKey.later.tr),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _join,
                    child: Text(LKey.join.tr),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
