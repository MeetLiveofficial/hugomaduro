import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krimson/common/manager/livekit_room_controller.dart';
import 'package:krimson/common/widget/custom_image.dart';
import 'package:krimson/languages/languages_keys.dart';
import 'package:krimson/utilities/role_colors.dart';
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

/// Llamada 1:1: el **otro** va a pantalla completa y **tú** en miniatura.
/// Cliente: streamer grande, cliente en PiP. Streamer: cliente grande, streamer en PiP.
class LiveKitCallLayout extends StatelessWidget {
  const LiveKitCallLayout({
    super.key,
    required this.local,
    required this.remotes,
    this.statusText,
    this.remotePhotoUrl,
    this.remoteName,
    this.localPhotoUrl,
    this.localName,
  });

  final LocalParticipant? local;
  final List<RemoteParticipant> remotes;
  final String? statusText;
  final String? remotePhotoUrl;
  final String? remoteName;
  final String? localPhotoUrl;
  final String? localName;

  static const _pipSize = Size(110, 160);

  @override
  Widget build(BuildContext context) {
    final primaryRemote = remotes.isNotEmpty ? remotes.first : null;
    final remoteHasVideo = firstVideoTrackOf(primaryRemote) != null;
    final localHasVideo = firstVideoTrackOf(local) != null;
    final waitingText = (statusText == null || statusText!.trim().isEmpty)
        ? LKey.waitingVideo.tr
        : statusText!;

    return Stack(
      fit: StackFit.expand,
      children: [
        if (remoteHasVideo)
          LiveKitParticipantVideo(
            participant: primaryRemote,
            forcePortraitUpright: false,
          )
        else
          _CallWaitingPhoto(
            imageUrl: remotePhotoUrl,
            name: remoteName,
            overlayText: waitingText,
          ),
        Positioned(
          right: 16,
          top: 16,
          width: _pipSize.width,
          height: _pipSize.height,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white24),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              clipBehavior: kIsWeb ? Clip.none : Clip.antiAlias,
              child: (localHasVideo && !kIsWeb)
                  ? LiveKitParticipantVideo(
                      participant: local,
                      mirror: true,
                      forcePortraitUpright: false,
                      placeholder: _CallWaitingPhoto(
                        imageUrl: localPhotoUrl,
                        name: localName,
                      ),
                    )
                  : _CallWaitingPhoto(
                      imageUrl: localPhotoUrl,
                      name: localName,
                    ),
            ),
          ),
        ),
        if (!kIsWeb && remotes.length > 1)
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

/// Foto de perfil a pantalla completa mientras no hay video (esperando conexión).
class _CallWaitingPhoto extends StatelessWidget {
  const _CallWaitingPhoto({
    this.imageUrl,
    this.name,
    this.overlayText,
  });

  final String? imageUrl;
  final String? name;
  final String? overlayText;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(
          color: RolePalette.bg,
          child: CustomImage(
            size: const Size(double.infinity, double.infinity),
            image: imageUrl,
            radius: 0,
            fit: BoxFit.cover,
            isShowPlaceHolder: true,
            fullName: name,
          ),
        ),
        if (overlayText != null && overlayText!.trim().isNotEmpty) ...[
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x66000000),
                  Color(0x33000000),
                  Color(0x99000000),
                ],
              ),
            ),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                overlayText!,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  shadows: [
                    Shadow(color: Colors.black54, blurRadius: 8),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
