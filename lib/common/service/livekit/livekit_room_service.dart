import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:krimson/common/manager/logger.dart';
import 'package:krimson/common/service/api/livekit_token_service.dart';
import 'package:krimson/utilities/const_res.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:permission_handler/permission_handler.dart';

/// Servicio de conexión a salas LiveKit (sin GetX).
///
/// Optimizado para calidad fluida y arranque estable:
/// - Permisos antes de conectar
/// - Token y warm-up de tracks en paralelo
/// - Captura 720p @ 30 fps (bitrate alto) para imagen fluida
/// - Reintentos a 540/360 solo si el publish falla
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

  final StreamController<DataReceivedEvent> _dataEvents =
      StreamController<DataReceivedEvent>.broadcast();
  Stream<DataReceivedEvent> get onDataReceived => _dataEvents.stream;

  final StreamController<(int pingMs, int fps)> _stats =
      StreamController<(int, int)>.broadcast();
  Stream<(int pingMs, int fps)> get onStats => _stats.stream;

  Timer? _statsTimer;
  int _lastFps = 0;

  void _emitStatus(String msg) {
    if (!_status.isClosed) _status.add(msg);
  }

  void _emitStats() {
    if (_stats.isClosed || _room == null) return;
    var ping = 0;
    try {
      // ignore: invalid_use_of_internal_member
      ping = _room!.engine.signalClient.rtt;
    } catch (_) {}
    if (!_stats.isClosed) {
      _stats.add((ping, _lastFps));
    }
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
          // 720p @ 30fps → imagen más nítida y fluida.
          params: VideoParametersPresets.h720_169,
        ),
        defaultAudioCaptureOptions: AudioCaptureOptions(
          echoCancellation: true,
          noiseSuppression: true,
          autoGainControl: true,
        ),
        // Encoding de publicación: prioriza fluidez (30 fps) y bitrate alto.
        defaultVideoPublishOptions: VideoPublishOptions(
          videoCodec: 'h264',
          simulcast: true,
          videoEncoding: VideoEncoding(
            maxBitrate: 2 * 1000 * 1000, // ~2 Mbps
            maxFramerate: 30,
          ),
          degradationPreference: DegradationPreference.maintainFramerate,
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
    _startStatsPolling();
    return room;
  }

  void _startStatsPolling() {
    _statsTimer?.cancel();
    _statsTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _sampleFps();
      _emitStats();
    });
  }

  Future<void> _sampleFps() async {
    try {
      Future<int?> readFpsFromReports(List<dynamic> reports) async {
        for (final r in reports) {
          final values = r.values;
          if (values is! Map) continue;
          final raw = values['framesPerSecond'] ??
              values['googFrameRateSent'] ??
              values['googFrameRateReceived'] ??
              values['framesPerSecondDecoded'];
          final n = num.tryParse('$raw');
          if (n != null && n > 0) return n.round();
        }
        return null;
      }

      final lp = _room?.localParticipant;
      for (final pub in lp?.videoTrackPublications ?? []) {
        final track = pub.track;
        if (track is! LocalVideoTrack) continue;
        final sender = track.sender;
        if (sender == null) continue;
        final fps = await readFpsFromReports(await sender.getStats());
        if (fps != null) {
          _lastFps = fps;
          return;
        }
      }
      for (final p in _room?.remoteParticipants.values ??
          const Iterable<RemoteParticipant>.empty()) {
        for (final pub in p.videoTrackPublications) {
          final track = pub.track;
          if (track is! RemoteVideoTrack) continue;
          final receiver = track.receiver;
          if (receiver == null) continue;
          final fps = await readFpsFromReports(await receiver.getStats());
          if (fps != null) {
            _lastFps = fps;
            return;
          }
        }
      }
    } catch (_) {}
  }

  Future<void> publishDataBytes(List<int> bytes, {String topic = 'live_chat'}) async {
    final lp = _room?.localParticipant;
    if (lp == null) return;
    await lp.publishData(
      Uint8List.fromList(bytes),
      reliable: true,
      topic: topic,
    );
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

  static const CameraCaptureOptions _camera720 = CameraCaptureOptions(
    cameraPosition: CameraPosition.front,
    params: VideoParametersPresets.h720_169,
  );

  static const VideoPublishOptions _publishSmooth = VideoPublishOptions(
    videoCodec: 'h264',
    simulcast: true,
    videoEncoding: VideoEncoding(
      maxBitrate: 2 * 1000 * 1000,
      maxFramerate: 30,
    ),
    degradationPreference: DegradationPreference.maintainFramerate,
  );

  Future<LocalVideoTrack?> _createCameraTrackSafe() async {
    try {
      return await LocalVideoTrack.createCameraTrack(_camera720)
          .timeout(const Duration(seconds: 10));
    } catch (e) {
      Loggers.error('createCameraTrack 720p: $e');
      // Fallback rápido si el dispositivo no abre 720p a tiempo.
      try {
        return await LocalVideoTrack.createCameraTrack(
          const CameraCaptureOptions(
            cameraPosition: CameraPosition.front,
            params: VideoParametersPresets.h540_169,
          ),
        ).timeout(const Duration(seconds: 8));
      } catch (e2) {
        Loggers.error('createCameraTrack 540p: $e2');
        return null;
      }
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
            .publishVideoTrack(warm, publishOptions: _publishSmooth)
            .timeout(const Duration(seconds: 12));
        return;
      } catch (e) {
        Loggers.error('publishVideoTrack(warm): $e');
        try {
          await warm.stop();
          await warm.dispose();
        } catch (_) {}
      }
    }

    // Preferir 720p; bajar solo si el publish falla.
    final presets = <VideoParameters>[
      VideoParametersPresets.h720_169,
      VideoParametersPresets.h540_169,
      VideoParametersPresets.h360_169,
    ];
    for (var i = 0; i < presets.length; i++) {
      try {
        await lp
            .setCameraEnabled(
              true,
              cameraCaptureOptions: CameraCaptureOptions(
                cameraPosition: CameraPosition.front,
                params: presets[i],
              ),
            )
            .timeout(const Duration(seconds: 10));
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
    _statsTimer?.cancel();
    _statsTimer = null;
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
      ..on<TrackUnmutedEvent>((_) => _mediaChanges.add(null))
      ..on<DataReceivedEvent>((event) {
        if (!_dataEvents.isClosed) _dataEvents.add(event);
      });
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
    await _dataEvents.close();
    await _stats.close();
  }
}
