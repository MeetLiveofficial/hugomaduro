import 'dart:async';

import 'package:flutter/foundation.dart';
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
  final RxString statusMessage = ''.obs;
  final Rxn<LocalParticipant> localParticipant = Rxn<LocalParticipant>();
  final RxList<RemoteParticipant> remoteParticipants = <RemoteParticipant>[].obs;
  final RxInt mediaRevision = 0.obs;
  final RxInt pingMs = 0.obs;
  final RxInt fps = 0.obs;

  Room? get room => _service.room;
  Stream<DataReceivedEvent> get onDataReceived => _service.onDataReceived;

  bool get isSupported => !kIsWeb;

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
  }

  Future<void> connect({
    required String roomName,
    required String identity,
    String? name,
    bool publishCamera = false,
    bool publishMicrophone = false,
    String? wsUrl,
  }) async {
    if (!isSupported) {
      statusMessage.value =
          'LiveKit A/V is limited on Web. Use Android/iOS for full experience.';
      return;
    }
    if (isConnecting.value || isConnected.value) return;

    isConnecting.value = true;
    statusMessage.value = 'Preparing camera…';

    try {
      await _service.connect(
        roomName: roomName,
        identity: identity,
        name: name,
        publishCamera: publishCamera,
        publishMicrophone: publishMicrophone,
        wsUrl: wsUrl,
      );
      _syncFromService();
      isConnected.value = true;
      if (statusMessage.value.startsWith('Camera failed')) {
        // Mantener aviso; el usuario puede reintentar con el botón de cámara.
      } else {
        statusMessage.value = '';
      }
      Loggers.info(
          'LiveKit connected room=$roomName identity=$identity');
    } catch (e, st) {
      Loggers.error('LiveKit connect failed: $e\n$st');
      statusMessage.value = e.toString();
      isConnected.value = false;
      rethrow;
    } finally {
      isConnecting.value = false;
    }
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

  Future<void> toggleMicrophone() =>
      setMicrophoneEnabled(!microphoneEnabled.value);

  Future<void> publishData(List<int> bytes, {String topic = 'live_chat'}) =>
      _service.publishDataBytes(bytes, topic: topic);

  Future<void> disconnect() async {
    statusMessage.value = 'Leaving…';
    try {
      await _service.disconnect();
    } finally {
      cameraEnabled.value = false;
      microphoneEnabled.value = false;
      isConnected.value = false;
      statusMessage.value = '';
      _syncFromService();
    }
  }

  @override
  void onClose() {
    unawaited(_mediaSub?.cancel());
    unawaited(_statusSub?.cancel());
    unawaited(_statsSub?.cancel());
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
      // Local: no necesita "subscribed"; remoto: preferir tracks ya suscritos.
      if (participant is LocalParticipant || pub.subscribed) {
        return track;
      }
    }
  }
  // Fallback: track existente aunque esté muted (UI puede mostrar placeholder).
  for (final pub in participant.videoTrackPublications) {
    final track = pub.track;
    if (track is VideoTrack) {
      if (participant is LocalParticipant || pub.subscribed) {
        return track;
      }
    }
  }
  return null;
}
