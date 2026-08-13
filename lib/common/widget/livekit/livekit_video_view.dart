import 'package:flutter/foundation.dart';
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

    // texture: ColorFilter / ImageFilter.shader pueden aplicarse encima.
    // platformView (UiKitView) ignora los filtros de Flutter.
    Widget view = VideoTrackRenderer(
      track,
      fit: fit,
      mirrorMode: mirror ? VideoViewMirrorMode.mirror : VideoViewMirrorMode.off,
      renderMode: VideoRenderMode.texture,
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
    // En Web, VideoTrackRenderer (HtmlElementView) se pinta ENCIMA de Flutter
    // y tapa botones/cronómetro. En emulador a veces el SurfaceView hace lo mismo.
    final allowRenderer = !kIsWeb;
    final remoteHasVideo =
        allowRenderer && firstVideoTrackOf(primaryRemote) != null;
    final localHasVideo = allowRenderer && firstVideoTrackOf(local) != null;

    return Stack(
      fit: StackFit.expand,
      children: [
        if (remoteHasVideo)
          LiveKitParticipantVideo(
            participant: primaryRemote,
            forcePortraitUpright: false,
          )
        else
          ColoredBox(
            color: const Color(0xFF140E18),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  statusText ??
                      (kIsWeb
                          ? 'Llamada activa. El video va por la APP, no por el navegador.'
                          : 'Esperando video…'),
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        Positioned(
          right: 16,
          top: 16,
          width: 110,
          height: 160,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: localHasVideo
                ? LiveKitParticipantVideo(
                    participant: local,
                    mirror: true,
                    forcePortraitUpright: false,
                    placeholder: const ColoredBox(color: Colors.black54),
                  )
                : const ColoredBox(
                    color: Colors.black54,
                    child: Center(
                      child: Icon(Icons.person, color: Colors.white38, size: 36),
                    ),
                  ),
          ),
        ),
        // Remotos adicionales en franja inferior
        if (allowRenderer && remotes.length > 1)
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
