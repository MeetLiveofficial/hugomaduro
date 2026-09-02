import 'dart:async';

import 'package:get/get.dart';
import 'package:krimson/common/manager/logger.dart';
import 'package:krimson/common/service/livekit/livekit_room_service.dart';
import 'package:livekit_client/livekit_client.dart';

/// Capa GetX sobre [LiveKitRoomService].
///
/// Uso:
/// ```dart
/// final lk = Get.put(LiveKitRoomController(), tag: 'live');
/// await lk.connect(roomName: 'stream_1', identity: '42', name: 'Ana',
///   publishCamera: true, publishMicrophone: true);
/// ```
class LiveKitRoomController extends GetxController {
  final LiveKitRoomService _service = LiveKitRoomService();
  StreamSubscription? _mediaSub;
  StreamSubscription? _statusSub;
  StreamSubscription? _statsSub;

  final RxBool isConnecting = false.obs;
  final RxBool isConnected = false.obs;
  final RxBool cameraEnabled = false.obs;
  final RxBool microphoneEnabled = false.obs;
  /// frontal = true, trasera = false (solo informativo para UI).
  final RxBool cameraIsFront = true.obs;
  /// Mute local del audio remoto (audiencia silencia el mic del host).
  final RxBool remoteAudioMuted = false.obs;
  /// Pausa local: host corta cam/mic; audiencia congela video + audio.
  final RxBool streamPaused = false.obs;
  final RxString statusMessage = ''.obs;
  final Rxn<LocalParticipant> localParticipant = Rxn<LocalParticipant>();
  final RxList<RemoteParticipant> remoteParticipants = <RemoteParticipant>[].obs;
  final RxInt mediaRevision = 0.obs;
  final RxInt pingMs = 0.obs;
  final RxInt fps = 0.obs;
  final Rx<LiveKitQualityProfile> qualityProfile =
      LiveKitQualityProfile.medium.obs;

  Room? get room => _service.room;
  Stream<DataReceivedEvent> get onDataReceived => _service.onDataReceived;

  StreamSubscription? _qualitySub;

  @override
  void onInit() {
    super.onInit();
    _mediaSub = _service.onMediaChanged.listen((_) => _syncFromService());
    _statusSub = _service.onStatus.listen((msg) {
      statusMessage.value = msg;
    });
    _statsSub = _service.onStats.listen((pair) {
      pingMs.value = pair.$1;
      fps.value = pair.$2;
    });
    _qualitySub = _service.onQualityChanged.listen((profile) {
      qualityProfile.value = profile;
    });
  }

  /// Sala LiveKit actual (para detectar PK / rejoin a otra room).
  String? connectedRoomName;

  Future<void> connect({
    required String roomName,
    required String identity,
    String? name,
    bool publishCamera = false,
    bool publishMicrophone = false,
    String? wsUrl,
    LiveKitQualityProfile? forceProfile,
    bool forceReconnect = false,
    bool adaptiveStream = true,
    bool dynacast = true,
  }) async {
    if (isConnecting.value) {
      if (!forceReconnect) return;
      isConnecting.value = false;
    }

    // Si ya estamos en otra sala (o hay que forzar), cerrar antes.
    // Evita el no-op que dejaba la cámara en la sala vieja del PK.
    final sameRoom = isConnected.value && connectedRoomName == roomName;
    if (isConnected.value && (!sameRoom || forceReconnect)) {
      try {
        await disconnect();
      } catch (_) {}
    } else if (sameRoom && !forceReconnect) {
      return;
    }

    isConnecting.value = true;
    statusMessage.value = 'Conectando…';

    try {
      await _service.connect(
        roomName: roomName,
        identity: identity,
        name: name,
        publishCamera: publishCamera,
        publishMicrophone: publishMicrophone,
        wsUrl: wsUrl,
        // Entrada en media por defecto (540×720 @ 20fps). Baja solo si falla.
        forceProfile: forceProfile ?? LiveKitQualityProfile.medium,
        adaptiveStream: adaptiveStream,
        dynacast: dynacast,
      );
      _syncFromService();
      isConnected.value = true;
      connectedRoomName = roomName;
      qualityProfile.value = _service.qualityProfile;
      if (statusMessage.value.startsWith('Camera failed')) {
        // Mantener aviso de cámara.
      } else {
        statusMessage.value = '';
      }
      Loggers.info(
          'LiveKit connected room=$roomName identity=$identity');
    } catch (e, st) {
      Loggers.error('LiveKit connect failed: $e\n$st');
      statusMessage.value = 'Sin video (red débil). Toca Reintentar.';
      isConnected.value = false;
      connectedRoomName = null;
      rethrow;
    } finally {
      isConnecting.value = false;
    }
  }

  /// Cambia resolución/calidad desde el LIVE (Baja / Media / Alta).
  Future<void> setQualityProfile(
    LiveKitQualityProfile profile, {
    required bool asHost,
  }) async {
    await _service.setQualityProfile(profile, asHost: asHost);
    qualityProfile.value = profile;
    mediaRevision.value++;
  }

  /// Reconecta forzando calidad baja (útil tras fallo o red mala).
  Future<void> reconnectLowQuality({
    required String roomName,
    required String identity,
    String? name,
    bool publishCamera = false,
    bool publishMicrophone = false,
    String? wsUrl,
  }) async {
    if (isConnecting.value) return;
    try {
      await disconnect();
    } catch (_) {}
    await connect(
      roomName: roomName,
      identity: identity,
      name: name,
      publishCamera: publishCamera,
      publishMicrophone: publishMicrophone,
      wsUrl: wsUrl,
      forceProfile: LiveKitQualityProfile.low,
    );
  }

  void _syncFromService() {
    localParticipant.value = _service.localParticipant;
    remoteParticipants.assignAll(_service.remoteParticipants);
    isConnected.value = _service.isConnected;
    final lp = _service.localParticipant;
    if (lp != null) {
      cameraEnabled.value = lp.isCameraEnabled();
      microphoneEnabled.value = lp.isMicrophoneEnabled();
    }
    cameraIsFront.value = _service.cameraPosition == CameraPosition.front;
    mediaRevision.value++;
  }

  Future<void> setCameraEnabled(bool enabled) async {
    await _service.setCameraEnabled(enabled);
    cameraEnabled.value = enabled;
    _syncFromService();
  }

  Future<void> setMicrophoneEnabled(bool enabled) async {
    await _service.setMicrophoneEnabled(enabled);
    microphoneEnabled.value = enabled;
    _syncFromService();
  }

  Future<void> toggleCamera() => setCameraEnabled(!cameraEnabled.value);

  Future<void> switchCamera() async {
    await _service.switchCamera();
    cameraIsFront.value = _service.cameraPosition == CameraPosition.front;
    _syncFromService();
  }

  Future<void> toggleMicrophone() =>
      setMicrophoneEnabled(!microphoneEnabled.value);

  /// Silencia/reactiva el audio del host en el dispositivo local.
  Future<void> setRemoteAudioMuted(bool muted) async {
    remoteAudioMuted.value = muted;
    for (final p in remoteParticipants) {
      for (final pub in p.audioTrackPublications) {
        try {
          if (muted) {
            await pub.disable();
          } else {
            await pub.enable();
          }
        } catch (e) {
          Loggers.error('setRemoteAudioMuted: $e');
        }
      }
    }
    mediaRevision.value++;
  }

  /// Suscribe el video remoto (preview Match). [preferIdentity] = id del streamer.
  Future<void> subscribeRemoteVideos({String? preferIdentity}) async {
    final room = this.room;
    if (room == null) return;
    final wanted = (preferIdentity ?? '').trim();
    Future<void> sub(RemoteParticipant p) async {
      for (final pub in p.videoTrackPublications) {
        try {
          if (!pub.subscribed) {
            await pub.subscribe();
          }
          await pub.enable();
        } catch (e) {
          Loggers.error('subscribeRemoteVideos: $e');
        }
      }
    }

    final remotes = room.remoteParticipants.values.toList();
    remotes.sort((a, b) {
      final am = _identityLooksLike(a.identity, wanted) ? 0 : 1;
      final bm = _identityLooksLike(b.identity, wanted) ? 0 : 1;
      return am.compareTo(bm);
    });
    for (final p in remotes) {
      await sub(p);
    }
    _syncFromService();
  }

  static bool _identityLooksLike(String identity, String want) {
    if (want.isEmpty) return false;
    final a = identity.trim();
    if (a == want) return true;
    if (a.endsWith('_$want') || a == 'matchwait_$want') return true;
    return false;
  }

  /// Silencia audio de un participante remoto por identity (p.ej. rival PK).
  Future<void> muteRemoteParticipantAudio(String identity) async {
    if (identity.isEmpty) return;
    for (final p in List<RemoteParticipant>.from(remoteParticipants)) {
      if (p.identity != identity) continue;
      for (final pub in p.audioTrackPublications) {
        try {
          await pub.disable();
        } catch (e) {
          Loggers.error('muteRemoteParticipantAudio: $e');
        }
      }
    }
    mediaRevision.value++;
  }

  Future<void> toggleRemoteAudio() =>
      setRemoteAudioMuted(!remoteAudioMuted.value);

  /// Host: pausa publicación cam/mic. Audiencia: deshabilita video/audio remoto.
  Future<void> setStreamPaused({
    required bool paused,
    required bool asHost,
  }) async {
    streamPaused.value = paused;
    if (asHost) {
      if (paused) {
        await setCameraEnabled(false);
        await setMicrophoneEnabled(false);
      } else {
        await setCameraEnabled(true);
        await setMicrophoneEnabled(true);
      }
    } else {
      for (final p in remoteParticipants) {
        for (final pub in p.videoTrackPublications) {
          try {
            if (paused) {
              await pub.disable();
            } else {
              await pub.enable();
            }
          } catch (e) {
            Loggers.error('setStreamPaused video: $e');
          }
        }
        for (final pub in p.audioTrackPublications) {
          try {
            if (paused || remoteAudioMuted.value) {
              await pub.disable();
            } else {
              await pub.enable();
            }
          } catch (e) {
            Loggers.error('setStreamPaused audio: $e');
          }
        }
      }
    }
    mediaRevision.value++;
  }

  Future<void> toggleStreamPaused({required bool asHost}) =>
      setStreamPaused(paused: !streamPaused.value, asHost: asHost);

  Future<void> publishData(List<int> bytes, {String topic = 'live_chat'}) =>
      _service.publishDataBytes(bytes, topic: topic);

  Future<void> disconnect({bool silent = false}) async {
    isConnecting.value = false;
    if (!silent) {
      statusMessage.value = 'Leaving…';
    }
    try {
      await _service.disconnect();
    } finally {
      cameraEnabled.value = false;
      microphoneEnabled.value = false;
      remoteAudioMuted.value = false;
      streamPaused.value = false;
      isConnected.value = false;
      connectedRoomName = null;
      statusMessage.value = '';
      _syncFromService();
    }
  }

  @override
  void onClose() {
    unawaited(_mediaSub?.cancel());
    unawaited(_statusSub?.cancel());
    unawaited(_statsSub?.cancel());
    unawaited(_qualitySub?.cancel());
    unawaited(_service.dispose());
    super.onClose();
  }
}

/// Primer [VideoTrack] publicable/suscrito de un participante (evita pantalla negra).
VideoTrack? firstVideoTrackOf(Participant? participant) {
  if (participant == null) return null;
  for (final pub in participant.videoTrackPublications) {
    final track = pub.track;
    if (track is VideoTrack && !pub.muted) {
      if (participant is LocalParticipant || pub.subscribed || track != null) {
        return track;
      }
    }
  }
  for (final pub in participant.videoTrackPublications) {
    final track = pub.track;
    if (track is VideoTrack) {
      return track;
    }
  }
  return null;
}
