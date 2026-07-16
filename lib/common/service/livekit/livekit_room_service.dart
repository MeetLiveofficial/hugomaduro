import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:krimson/common/manager/logger.dart';
import 'package:krimson/common/service/api/livekit_token_service.dart';
import 'package:krimson/utilities/const_res.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:permission_handler/permission_handler.dart';

/// Servicio de conexión a salas LiveKit (sin GetX).
///
/// Optimizado para arrancar la cámara más rápido:
/// - Permisos antes de conectar
/// - Token y warm-up de tracks en paralelo
/// - Resolución inicial h540 (más rápida que 720p)
/// - Reintentos si falla el publish (no tumba la sala)
class LiveKitRoomService {
  Room? _room;
  EventsListener<RoomEvent>? _listener;

  Room? get room => _room;
  LocalParticipant? get localParticipant => _room?.localParticipant;
  List<RemoteParticipant> get remoteParticipants =>
      _room?.remoteParticipants.values.toList() ?? const [];

  bool get isConnected =>
      _room != null &&
      (_room?.connectionState == ConnectionState.connected ||
          _room?.connectionState == ConnectionState.reconnecting);

  final StreamController<void> _mediaChanges =
      StreamController<void>.broadcast();
  Stream<void> get onMediaChanged => _mediaChanges.stream;

  final StreamController<String> _status =
      StreamController<String>.broadcast();
  Stream<String> get onStatus => _status.stream;

  void _emitStatus(String msg) {
    if (!_status.isClosed) _status.add(msg);
  }

  /// Conecta a una sala LiveKit.
  Future<Room> connect({
    required String roomName,
    required String identity,
    String? name,
    bool publishCamera = true,
    bool publishMicrophone = true,
    String? wsUrl,
  }) async {
    if (kIsWeb) {
      throw UnsupportedError(
        'LiveKit A/V completo requiere Android/iOS. Web está limitado.',
      );
    }
    if (_room != null) {
      await disconnect();
    }

    _emitStatus('Preparing camera…');
    LocalVideoTrack? warmVideo;
    LocalAudioTrack? warmAudio;

    // Token + permisos/warm-up en paralelo para acortar espera.
    final tokenFuture = LiveKitTokenService.instance.createToken(
      roomName: roomName,
      identity: identity,
      name: name,
    );

    final warmFuture = () async {
      await _ensureMediaPermissions(
        camera: publishCamera,
        microphone: publishMicrophone,
      );
      if (publishCamera) {
        warmVideo = await _createCameraTrackSafe();
      }
      if (publishMicrophone) {
        warmAudio = await _createMicTrackSafe();
      }
    }();

    late final LiveKitTokenResult tokenResult;
    try {
      final results = await Future.wait([tokenFuture, warmFuture]);
      tokenResult = results[0] as LiveKitTokenResult;
    } catch (e) {
      await warmVideo?.stop();
      await warmVideo?.dispose();
      await warmAudio?.stop();
      await warmAudio?.dispose();
      rethrow;
    }

    final room = Room(
      roomOptions: const RoomOptions(
        adaptiveStream: true,
        dynacast: true,
        defaultCameraCaptureOptions: CameraCaptureOptions(
          cameraPosition: CameraPosition.front,
          // h540 arranca más rápido que 720p en muchos dispositivos.
          params: VideoParametersPresets.h540_169,
        ),
        defaultAudioCaptureOptions: AudioCaptureOptions(
          echoCancellation: true,
          noiseSuppression: true,
          autoGainControl: true,
        ),
      ),
    );

    final listener = room.createListener();
    _attachEvents(listener);

    final url = (wsUrl ?? tokenResult.wsUrl).trim().isEmpty
        ? liveKitWsUrl
        : (wsUrl ?? tokenResult.wsUrl).trim();

    _emitStatus('Connecting…');
    Loggers.info(
      'LiveKitRoomService connect room=$roomName identity=$identity url=$url',
    );

    await room.connect(
      url,
      tokenResult.token,
      connectOptions: const ConnectOptions(autoSubscribe: true),
    );

    _room = room;
    _listener = listener;
    _mediaChanges.add(null);

    final lp = room.localParticipant;
    if (lp != null) {
      if (publishMicrophone) {
        _emitStatus('Starting microphone…');
        await _publishMic(lp, warmAudio);
        warmAudio = null;
      }
      if (publishCamera) {
        _emitStatus('Starting camera…');
        await _publishCamera(lp, warmVideo);
        warmVideo = null;
      }
    }

    // Por si warm-up quedó huérfano tras fallo.
    await warmVideo?.stop();
    await warmVideo?.dispose();
    await warmAudio?.stop();
    await warmAudio?.dispose();

    _emitStatus('');
    _mediaChanges.add(null);
    return room;
  }

  Future<void> _ensureMediaPermissions({
    required bool camera,
    required bool microphone,
  }) async {
    final needed = <Permission>[];
    if (camera) needed.add(Permission.camera);
    if (microphone) needed.add(Permission.microphone);
    if (needed.isEmpty) return;

    final statuses = await needed.request();
    for (final entry in statuses.entries) {
      if (!entry.value.isGranted) {
        Loggers.error('Permission denied: ${entry.key}');
      }
    }
  }

  Future<LocalVideoTrack?> _createCameraTrackSafe() async {
    try {
      return await LocalVideoTrack.createCameraTrack(
        const CameraCaptureOptions(
          cameraPosition: CameraPosition.front,
          params: VideoParametersPresets.h540_169,
        ),
      ).timeout(const Duration(seconds: 8));
    } catch (e) {
      Loggers.error('createCameraTrack: $e');
      return null;
    }
  }

  Future<LocalAudioTrack?> _createMicTrackSafe() async {
    try {
      return await LocalAudioTrack.create(
        const AudioCaptureOptions(
          echoCancellation: true,
          noiseSuppression: true,
          autoGainControl: true,
        ),
      ).timeout(const Duration(seconds: 5));
    } catch (e) {
      Loggers.error('createAudioTrack: $e');
      return null;
    }
  }

  Future<void> _publishCamera(
    LocalParticipant lp,
    LocalVideoTrack? warm,
  ) async {
    if (warm != null) {
      try {
        await lp
            .publishVideoTrack(warm)
            .timeout(const Duration(seconds: 10));
        return;
      } catch (e) {
        Loggers.error('publishVideoTrack(warm): $e');
        try {
          await warm.stop();
          await warm.dispose();
        } catch (_) {}
      }
    }

    // Fallback: setCameraEnabled con reintentos y calidad más baja.
    final presets = <VideoParameters>[
      VideoParametersPresets.h540_169,
      VideoParametersPresets.h360_169,
      VideoParametersPresets.h180_169,
    ];
    for (var i = 0; i < presets.length; i++) {
      try {
        await lp.setCameraEnabled(
          true,
          cameraCaptureOptions: CameraCaptureOptions(
            cameraPosition: CameraPosition.front,
            params: presets[i],
          ),
        ).timeout(const Duration(seconds: 8));
        return;
      } catch (e) {
        Loggers.error('setCameraEnabled attempt ${i + 1}: $e');
        await Future.delayed(Duration(milliseconds: 250 * (i + 1)));
      }
    }
    _emitStatus('Camera failed to start. Tap video icon to retry.');
  }

  Future<void> _publishMic(
    LocalParticipant lp,
    LocalAudioTrack? warm,
  ) async {
    if (warm != null) {
      try {
        await lp.publishAudioTrack(warm).timeout(const Duration(seconds: 8));
        return;
      } catch (e) {
        Loggers.error('publishAudioTrack(warm): $e');
        try {
          await warm.stop();
          await warm.dispose();
        } catch (_) {}
      }
    }

    for (var i = 0; i < 3; i++) {
      try {
        await lp
            .setMicrophoneEnabled(true)
            .timeout(const Duration(seconds: 6));
        return;
      } catch (e) {
        Loggers.error('setMicrophoneEnabled attempt ${i + 1}: $e');
        await Future.delayed(Duration(milliseconds: 200 * (i + 1)));
      }
    }
  }

  Future<void> setCameraEnabled(bool enabled) async {
    final lp = _room?.localParticipant;
    if (lp == null) return;
    if (enabled) {
      await _publishCamera(lp, null);
    } else {
      try {
        await lp.setCameraEnabled(false);
      } catch (e) {
        Loggers.error('setCameraEnabled(false): $e');
      }
    }
    _mediaChanges.add(null);
  }

  Future<void> setMicrophoneEnabled(bool enabled) async {
    final lp = _room?.localParticipant;
    if (lp == null) return;
    if (enabled) {
      await _publishMic(lp, null);
    } else {
      try {
        await lp.setMicrophoneEnabled(false);
      } catch (e) {
        Loggers.error('setMicrophoneEnabled(false): $e');
      }
    }
    _mediaChanges.add(null);
  }

  Future<void> toggleCamera() async {
    final lp = _room?.localParticipant;
    if (lp == null) return;
    await setCameraEnabled(!lp.isCameraEnabled());
  }

  Future<void> toggleMicrophone() async {
    final lp = _room?.localParticipant;
    if (lp == null) return;
    await setMicrophoneEnabled(!lp.isMicrophoneEnabled());
  }

  Future<void> disconnect() async {
    try {
      final lp = _room?.localParticipant;
      if (lp != null) {
        try {
          await lp.setCameraEnabled(false);
        } catch (_) {}
        try {
          await lp.setMicrophoneEnabled(false);
        } catch (_) {}
      }
      await _room?.disconnect();
    } catch (e) {
      Loggers.info('LiveKitRoomService disconnect ignored: $e');
    } finally {
      await _release();
    }
  }

  void _attachEvents(EventsListener<RoomEvent> listener) {
    listener
      ..on<RoomConnectedEvent>((_) => _mediaChanges.add(null))
      ..on<RoomDisconnectedEvent>((_) => _mediaChanges.add(null))
      ..on<ParticipantConnectedEvent>((_) => _mediaChanges.add(null))
      ..on<ParticipantDisconnectedEvent>((_) => _mediaChanges.add(null))
      ..on<TrackSubscribedEvent>((_) => _mediaChanges.add(null))
      ..on<TrackUnsubscribedEvent>((_) => _mediaChanges.add(null))
      ..on<LocalTrackPublishedEvent>((_) => _mediaChanges.add(null))
      ..on<LocalTrackUnpublishedEvent>((_) => _mediaChanges.add(null))
      ..on<TrackMutedEvent>((_) => _mediaChanges.add(null))
      ..on<TrackUnmutedEvent>((_) => _mediaChanges.add(null));
  }

  Future<void> _release() async {
    try {
      await _listener?.dispose();
    } catch (_) {}
    _listener = null;
    try {
      await _room?.dispose();
    } catch (_) {}
    _room = null;
    _mediaChanges.add(null);
  }

  Future<void> dispose() async {
    await disconnect();
    await _mediaChanges.close();
    await _status.close();
  }
}
