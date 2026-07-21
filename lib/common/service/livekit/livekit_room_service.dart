import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:krimson/common/manager/logger.dart';
import 'package:krimson/common/service/api/livekit_token_service.dart';
import 'package:krimson/utilities/const_res.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:permission_handler/permission_handler.dart';

/// Perfil de calidad de publicación/suscripción LiveKit.
enum LiveKitQualityProfile {
  /// Red buena: 720p / ~1.5 Mbps
  high,

  /// Red media (datos móviles): 360p / ~600 kbps
  medium,

  /// Red mala: 180p / ~250 kbps — prioriza conectar sí o sí
  low,
}

/// Servicio de conexión a salas LiveKit (sin GetX).
///
/// - Timeout + reintentos al conectar
/// - Perfil de calidad según red (baja calidad si Wi‑Fi/datos flojos)
/// - Simulcast + adaptiveStream para que la audiencia baje sola
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

  LiveKitQualityProfile qualityProfile = LiveKitQualityProfile.medium;

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

  final StreamController<LiveKitQualityProfile> _qualityChanges =
      StreamController<LiveKitQualityProfile>.broadcast();
  Stream<LiveKitQualityProfile> get onQualityChanged => _qualityChanges.stream;

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

  Future<LiveKitQualityProfile> detectQualityProfile() async {
    try {
      final results = await Connectivity().checkConnectivity();
      if (results.contains(ConnectivityResult.none) || results.isEmpty) {
        return LiveKitQualityProfile.low;
      }
      if (results.contains(ConnectivityResult.mobile)) {
        return LiveKitQualityProfile.low;
      }
      // Wi‑Fi / ethernet: empezar en medium (más estable que 720p) y subir si va bien.
      return LiveKitQualityProfile.medium;
    } catch (_) {
      return LiveKitQualityProfile.low;
    }
  }

  VideoParameters _captureParams(LiveKitQualityProfile profile) {
    switch (profile) {
      case LiveKitQualityProfile.high:
        return VideoParametersPresets.h720_169;
      case LiveKitQualityProfile.medium:
        return VideoParametersPresets.h360_169;
      case LiveKitQualityProfile.low:
        return VideoParametersPresets.h180_169;
    }
  }

  VideoPublishOptions _publishOptions(LiveKitQualityProfile profile) {
    switch (profile) {
      case LiveKitQualityProfile.high:
        return const VideoPublishOptions(
          videoCodec: 'h264',
          simulcast: true,
          videoEncoding: VideoEncoding(
            maxBitrate: 1500 * 1000,
            maxFramerate: 24,
          ),
          degradationPreference: DegradationPreference.balanced,
        );
      case LiveKitQualityProfile.medium:
        return const VideoPublishOptions(
          videoCodec: 'h264',
          simulcast: true,
          videoEncoding: VideoEncoding(
            maxBitrate: 600 * 1000,
            maxFramerate: 20,
          ),
          degradationPreference: DegradationPreference.balanced,
        );
      case LiveKitQualityProfile.low:
        return const VideoPublishOptions(
          videoCodec: 'h264',
          simulcast: true,
          videoEncoding: VideoEncoding(
            maxBitrate: 250 * 1000,
            maxFramerate: 15,
          ),
          degradationPreference: DegradationPreference.maintainFramerate,
        );
    }
  }

  VideoQuality _subscribeQuality(LiveKitQualityProfile profile) {
    switch (profile) {
      case LiveKitQualityProfile.high:
        return VideoQuality.HIGH;
      case LiveKitQualityProfile.medium:
        return VideoQuality.MEDIUM;
      case LiveKitQualityProfile.low:
        return VideoQuality.LOW;
    }
  }

  /// Conecta a una sala LiveKit (con timeout y reintentos).
  ///
  /// En Web solo se permite suscripción (audiencia). Publicar cámara/mic
  /// sigue siendo nativo.
  Future<Room> connect({
    required String roomName,
    required String identity,
    String? name,
    bool publishCamera = true,
    bool publishMicrophone = true,
    String? wsUrl,
    LiveKitQualityProfile? forceProfile,
    int maxAttempts = 3,
  }) async {
    if (kIsWeb && (publishCamera || publishMicrophone)) {
      throw UnsupportedError(
        'Publicar cámara/mic en Web no está soportado. Usa Android/iOS.',
      );
    }
    if (_room != null) {
      await disconnect();
    }

    qualityProfile = forceProfile ?? await detectQualityProfile();
    if (!_qualityChanges.isClosed) {
      _qualityChanges.add(qualityProfile);
    }

    final profilesToTry = <LiveKitQualityProfile>[
      qualityProfile,
      if (qualityProfile != LiveKitQualityProfile.low) LiveKitQualityProfile.low,
    ];

    Object? lastError;
    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      final profile = profilesToTry[
          attempt < profilesToTry.length ? attempt : profilesToTry.length - 1];
      qualityProfile = profile;
      if (!_qualityChanges.isClosed) {
        _qualityChanges.add(profile);
      }

      final label = switch (profile) {
        LiveKitQualityProfile.high => 'alta',
        LiveKitQualityProfile.medium => 'media',
        LiveKitQualityProfile.low => 'baja',
      };
      _emitStatus(
        attempt == 0
            ? 'Conectando (calidad $label)…'
            : 'Reintentando en calidad $label…',
      );

      try {
        final room = await _connectOnce(
          roomName: roomName,
          identity: identity,
          name: name,
          publishCamera: publishCamera,
          publishMicrophone: publishMicrophone,
          wsUrl: wsUrl,
          profile: profile,
        );
        _emitStatus(
          profile == LiveKitQualityProfile.low
              ? 'Conectado · calidad baja'
              : '',
        );
        return room;
      } catch (e) {
        lastError = e;
        Loggers.error('LiveKit connect attempt ${attempt + 1}: $e');
        await _release();
        if (attempt < maxAttempts - 1) {
          await Future.delayed(Duration(milliseconds: 600 * (attempt + 1)));
        }
      }
    }

    _emitStatus('Sin video. Toca Reintentar.');
    throw lastError ?? Exception('LiveKit connect failed');
  }

  Future<Room> _connectOnce({
    required String roomName,
    required String identity,
    String? name,
    required bool publishCamera,
    required bool publishMicrophone,
    String? wsUrl,
    required LiveKitQualityProfile profile,
  }) async {
    _emitStatus('Preparando…');
    LocalVideoTrack? warmVideo;
    LocalAudioTrack? warmAudio;

    final tokenFuture = LiveKitTokenService.instance.createToken(
      roomName: roomName,
      identity: identity,
      name: name,
    );

    final warmFuture = () async {
      if (!publishCamera && !publishMicrophone) return;
      await _ensureMediaPermissions(
        camera: publishCamera,
        microphone: publishMicrophone,
      );
      if (publishCamera) {
        warmVideo = await _createCameraTrackSafe(profile);
      }
      if (publishMicrophone) {
        warmAudio = await _createMicTrackSafe();
      }
    }();

    late final LiveKitTokenResult tokenResult;
    try {
      final results = await Future.wait([
        tokenFuture.timeout(const Duration(seconds: 12)),
        warmFuture.timeout(const Duration(seconds: 15)),
      ]);
      tokenResult = results[0] as LiveKitTokenResult;
    } catch (e) {
      await warmVideo?.stop();
      await warmVideo?.dispose();
      await warmAudio?.stop();
      await warmAudio?.dispose();
      rethrow;
    }

    final capture = _captureParams(profile);
    final publish = _publishOptions(profile);

    final room = Room(
      roomOptions: RoomOptions(
        adaptiveStream: true,
        dynacast: true,
        defaultCameraCaptureOptions: CameraCaptureOptions(
          cameraPosition: CameraPosition.front,
          params: capture,
        ),
        defaultAudioCaptureOptions: const AudioCaptureOptions(
          echoCancellation: true,
          noiseSuppression: true,
          autoGainControl: true,
        ),
        defaultVideoPublishOptions: publish,
      ),
    );

    final listener = room.createListener();
    _attachEvents(listener);

    final url = (wsUrl ?? tokenResult.wsUrl).trim().isEmpty
        ? liveKitWsUrl
        : (wsUrl ?? tokenResult.wsUrl).trim();

    _emitStatus('Conectando…');
    Loggers.info(
      'LiveKitRoomService connect room=$roomName identity=$identity '
      'url=$url profile=$profile',
    );

    await room
        .connect(
          url,
          tokenResult.token,
          connectOptions: const ConnectOptions(autoSubscribe: true),
        )
        .timeout(const Duration(seconds: 18));

    _room = room;
    _listener = listener;
    _mediaChanges.add(null);

    final lp = room.localParticipant;
    if (lp != null) {
      if (publishMicrophone) {
        _emitStatus('Micrófono…');
        await _publishMic(lp, warmAudio);
        warmAudio = null;
      }
      if (publishCamera) {
        _emitStatus('Cámara…');
        await _publishCamera(lp, warmVideo, profile);
        warmVideo = null;
      }
    }

    await warmVideo?.stop();
    await warmVideo?.dispose();
    await warmAudio?.stop();
    await warmAudio?.dispose();

    // Preferir capa baja al entrar; adaptiveStream puede subir después.
    await preferRemoteVideoQuality(_subscribeQuality(profile));

    _mediaChanges.add(null);
    _startStatsPolling();
    return room;
  }

  /// Fija la calidad de suscripción de video remoto (LOW/MEDIUM/HIGH).
  Future<void> preferRemoteVideoQuality(VideoQuality quality) async {
    for (final p in remoteParticipants) {
      for (final pub in p.videoTrackPublications) {
        try {
          await pub.setVideoQuality(quality);
        } catch (e) {
          Loggers.error('setVideoQuality: $e');
        }
      }
    }
  }

  /// Ajusta calidad según [ConnectionQuality] del propio participante.
  Future<void> applyConnectionQuality(ConnectionQuality q) async {
    final next = switch (q) {
      ConnectionQuality.excellent || ConnectionQuality.good =>
        qualityProfile == LiveKitQualityProfile.low
            ? LiveKitQualityProfile.medium
            : qualityProfile,
      ConnectionQuality.poor || ConnectionQuality.lost =>
        LiveKitQualityProfile.low,
      _ => qualityProfile,
    };
    if (next == qualityProfile) {
      await preferRemoteVideoQuality(_subscribeQuality(qualityProfile));
      return;
    }
    qualityProfile = next;
    if (!_qualityChanges.isClosed) {
      _qualityChanges.add(next);
    }
    await preferRemoteVideoQuality(_subscribeQuality(next));
    Loggers.info('LiveKit quality adapted → $next (from $q)');
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

  Future<void> publishDataBytes(List<int> bytes,
      {String topic = 'live_chat'}) async {
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
    if (kIsWeb) return;
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

  Future<LocalVideoTrack?> _createCameraTrackSafe(
    LiveKitQualityProfile profile,
  ) async {
    final presets = <VideoParameters>[
      _captureParams(profile),
      VideoParametersPresets.h180_169,
    ];
    // Evitar duplicados.
    final tried = <String>{};
    for (final params in presets) {
      final key = '${params.dimensions.width}x${params.dimensions.height}';
      if (!tried.add(key)) continue;
      try {
        return await LocalVideoTrack.createCameraTrack(
          CameraCaptureOptions(
            cameraPosition: CameraPosition.front,
            params: params,
          ),
        ).timeout(const Duration(seconds: 8));
      } catch (e) {
        Loggers.error('createCameraTrack $key: $e');
      }
    }
    return null;
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
    LiveKitQualityProfile profile,
  ) async {
    final publish = _publishOptions(profile);
    if (warm != null) {
      try {
        await lp
            .publishVideoTrack(warm, publishOptions: publish)
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

    final presets = <VideoParameters>[
      _captureParams(profile),
      VideoParametersPresets.h360_169,
      VideoParametersPresets.h180_169,
    ];
    final tried = <String>{};
    for (var i = 0; i < presets.length; i++) {
      final key =
          '${presets[i].dimensions.width}x${presets[i].dimensions.height}';
      if (!tried.add(key)) continue;
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
      await _publishCamera(lp, null, qualityProfile);
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
      ..on<TrackSubscribedEvent>((event) async {
        _mediaChanges.add(null);
        if (event.track is RemoteVideoTrack) {
          try {
            await event.publication.setVideoQuality(
              _subscribeQuality(qualityProfile),
            );
          } catch (_) {}
        }
      })
      ..on<TrackUnsubscribedEvent>((_) => _mediaChanges.add(null))
      ..on<LocalTrackPublishedEvent>((_) => _mediaChanges.add(null))
      ..on<LocalTrackUnpublishedEvent>((_) => _mediaChanges.add(null))
      ..on<TrackMutedEvent>((_) => _mediaChanges.add(null))
      ..on<TrackUnmutedEvent>((_) => _mediaChanges.add(null))
      ..on<ParticipantConnectionQualityUpdatedEvent>((event) {
        // Solo reaccionar a la calidad local.
        final localId = _room?.localParticipant?.identity;
        if (localId != null && event.participant.identity == localId) {
          unawaited(applyConnectionQuality(event.connectionQuality));
        }
        _mediaChanges.add(null);
      })
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
    await _qualityChanges.close();
  }
}
