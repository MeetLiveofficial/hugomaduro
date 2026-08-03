import 'package:flutter/material.dart';
import 'package:krimson/common/manager/livekit_room_controller.dart';
import 'package:livekit_client/livekit_client.dart';

/// Renderiza el video de un [Participant] con [VideoTrackRenderer].
///
/// Si aún no hay track de video (suscripción pendiente / mute), muestra [placeholder].
class LiveKitParticipantVideo extends StatelessWidget {
  const LiveKitParticipantVideo({
    super.key,
    required this.participant,
    this.fit = VideoViewFit.cover,
    this.mirror = false,
    this.placeholder,
    this.forcePortraitUpright = true,
  });

  final Participant? participant;
  final VideoViewFit fit;
  final bool mirror;
  final Widget? placeholder;

  /// En BlueStacks el track a veces llega landscape; rota para UI portrait.
  final bool forcePortraitUpright;

  @override
  Widget build(BuildContext context) {
    final track = firstVideoTrackOf(participant);
    if (track == null) {
      return placeholder ??
          const ColoredBox(
            color: Colors.black,
            child: Center(
              child: Icon(Icons.videocam_off, color: Colors.white38, size: 40),
            ),
          );
    }

    Widget view = VideoTrackRenderer(
      track,
      fit: fit,
      mirrorMode: mirror ? VideoViewMirrorMode.mirror : VideoViewMirrorMode.off,
    );

    if (forcePortraitUpright && _isLandscapeTrack(track)) {
      view = RotatedBox(quarterTurns: 1, child: view);
    }

    return view;
  }

  bool _isLandscapeTrack(VideoTrack track) {
    try {
      if (track is LocalVideoTrack) {
        final d = track.currentOptions.params.dimensions;
        return d.width > d.height;
      }
    } catch (_) {}
    // Fallback: si el viewport es portrait y el plugin no reporta dims,
    // no rotar (evitar doble giro).
    return false;
  }
}

/// Layout típico de llamada: remoto a pantalla completa + local en PiP.
class LiveKitCallLayout extends StatelessWidget {
  const LiveKitCallLayout({
    super.key,
    required this.local,
    required this.remotes,
    this.statusText,
  });

  final LocalParticipant? local;
  final List<RemoteParticipant> remotes;
  final String? statusText;

  @override
  Widget build(BuildContext context) {
    final primaryRemote = remotes.isNotEmpty ? remotes.first : null;

    return Stack(
      fit: StackFit.expand,
      children: [
        if (primaryRemote != null)
          LiveKitParticipantVideo(participant: primaryRemote)
        else
          Center(
            child: Text(
              statusText ?? 'Waiting…',
              style: const TextStyle(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
          ),
        Positioned(
          right: 16,
          top: 16,
          width: 110,
          height: 160,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: LiveKitParticipantVideo(
              participant: local,
              mirror: true,
              placeholder: Container(color: Colors.black54),
            ),
          ),
        ),
        // Remotos adicionales en franja inferior
        if (remotes.length > 1)
          Positioned(
            left: 8,
            right: 8,
            bottom: 96,
            height: 90,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: remotes.length - 1,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                return SizedBox(
                  width: 72,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LiveKitParticipantVideo(
                      participant: remotes[i + 1],
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}
