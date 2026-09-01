import 'dart:async';
import 'dart:typed_data';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:krimson/common/manager/logger.dart';
import 'package:krimson/common/manager/media_permissions.dart';
import 'package:krimson/common/service/api/livekit_token_service.dart';
import 'package:krimson/utilities/const_res.dart';
import 'package:livekit_client/livekit_client.dart';

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
  int _lastPingMs = 0;
  bool _samplingStats = false;

  void _emitStatus(String msg) {
    if (!_status.isClosed) _status.add(msg);
  }

  void _emitStats() {
    if (_stats.isClosed || _room == null) return;
    _stats.add((_lastPingMs, _lastFps));
  }

  /// RTT del ping/pong de señalización. En Web suele quedar en 0
  /// (el servidor responde `pong` y no `pongResp`, que es el que actualiza rtt).
  int _signalRttMs() {
    try {
      // ignore: invalid_use_of_internal_member
      final rtt = _room?.engine.signalClient.rtt ?? 0;
      if (rtt > 0 && rtt < 15000) return rtt;
    } catch (_) {}
    return 0;
  }

  /// Extrae RTT de WebRTC: candidate-pair (`currentRoundTripTime`, segundos)
  /// o remote-inbound-rtp (`roundTripTime`).
  int? _rttMsFromReports(List<dynamic> reports) {
    int? pairMs;
    int? rtpMs;
    int? otherMs;

    int? toMs(dynamic raw, {required bool seconds}) {
      final n = raw is num ? raw : num.tryParse('$raw');
      if (n == null || n <= 0) return null;
      final ms = seconds ? (n * 1000).round() : n.round();
      if (ms <= 0 || ms > 15000) return null;
      return ms;
    }

    for (final r in reports) {
      Map? values;
      var type = '';
      try {
        type = '${r.type}';
        final v = r.values;
        if (v is Map) values = v;
      } catch (_) {
        continue;
      }
      if (values == null) continue;

      final crt = toMs(values['currentRoundTripTime'], seconds: true);
      final rtt = toMs(values['roundTripTime'], seconds: true);
      final goog = toMs(values['googRtt'], seconds: false);
      final nominated = values['nominated'] == true ||
          values['selected'] == true ||
          '${values['state']}' == 'succeeded';

      if (type == 'candidate-pair' || type == 'googCandidatePair') {
        final ms = crt ?? goog ?? rtt;
        if (ms == null) continue;
        if (nominated) {
          pairMs = ms;
        } else {
          pairMs ??= ms;
        }
      } else if (type == 'remote-inbound-rtp') {
        rtpMs ??= rtt ?? crt ?? goog;
      } else {
        otherMs ??= crt ?? goog ?? rtt;
      }
    }
    return pairMs ?? rtpMs ?? otherMs;
  }

  int? _fpsFromReports(List<dynamic> reports) {
    for (final r in reports) {
      try {
        final values = r.values;
        if (values is! Map) continue;
        final raw = values['framesPerSecond'] ??
            values['googFrameRateSent'] ??
            values['googFrameRateReceived'] ??
            values['framesPerSecondDecoded'];
        final n = num.tryParse('$raw');
        if (n != null && n > 0) return n.round();
      } catch (_) {}
    }
    return null;
  }

  Future<List<dynamic>> _peerConnectionStats() async {
    final reports = <dynamic>[];
    try {
      final room = _room;
      if (room == null) return reports;
      // ignore: invalid_use_of_internal_member
      final engine = room.engine;
      // ignore: invalid_use_of_internal_member
      final pcs = [engine.publisher?.pc, engine.subscriber?.pc];
      for (final pc in pcs) {
        if (pc == null) continue;
        try {
          reports.addAll(await pc.getStats());
        } catch (_) {}
      }
    } catch (_) {}
    return reports;
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

  /// Portrait capture con FOV más amplio (3:4).
  /// Evita el "zoom" excesivo de forzar 9:16 sobre el sensor frontal.
  VideoParameters _captureParams(LiveKitQualityProfile profile) {
    switch (profile) {
      case LiveKitQualityProfile.high:
        return const VideoParameters(
          dimensions: VideoDimensions(720, 960),
          encoding: VideoEncoding(maxBitrate: 1500 * 1000, maxFramerate: 24),
        );
      case LiveKitQualityProfile.medium:
        return const VideoParameters(
          dimensions: VideoDimensions(540, 720),
          encoding: VideoEncoding(maxBitrate: 1000 * 1000, maxFramerate: 24),
        );
      case LiveKitQualityProfile.low:
        return const VideoParameters(
          dimensions: VideoDimensions(360, 480),
          encoding: VideoEncoding(maxBitrate: 450 * 1000, maxFramerate: 20),
        );
    }
  }

  static const VideoParameters _portraitFallbackLow = VideoParameters(
    dimensions: VideoDimensions(360, 480),
    encoding: VideoEncoding(maxBitrate: 250 * 1000, maxFramerate: 15),
  );

  static const VideoParameters _portraitFallbackMid = VideoParameters(
    dimensions: VideoDimensions(540, 720),
    encoding: VideoEncoding(maxBitrate: 600 * 1000, maxFramerate: 20),
  );

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
            maxBitrate: 900 * 1000,
            maxFramerate: 24,
          ),
          degradationPreference: DegradationPreference.balanced,
        );
      case LiveKitQualityProfile.low:
        return const VideoPublishOptions(
          videoCodec: 'h264',
          simulcast: true,
          videoEncoding: VideoEncoding(
            maxBitrate: 350 * 1000,
            maxFramerate: 20,
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
  /// En Web usa getUserMedia del navegador (requiere HTTPS o localhost).
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
    if (_room != null) {
      await disconnect();
    }

    // Media por defecto (nitidez aceptable). Baja solo como fallback de connect.
    qualityProfile = forceProfile ?? LiveKitQualityProfile.medium;
    if (!_qualityChanges.isClosed) {
      _qualityChanges.add(qualityProfile);
    }

    // Si falla el primer intento, reintentar otra vez en baja (mismo perfil).
    final profilesToTry = <LiveKitQualityProfile>[
      qualityProfile,
      LiveKitQualityProfile.low,
    ];

    Object? lastError;
    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      final profile = profilesToTry[
          attempt < profilesToTry.length ? attempt : profilesToTry.length - 1];
      qualityProfile = profile;
      if (!_qualityChanges.isClosed) {
        _qualityChanges.add(profile);
      }

      _emitStatus(attempt == 0 ? 'Conectando…' : 'Reintentando…');

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
        _emitStatus('');
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

    // Token y cámara en paralelo: si el permiso ya está, el preview sale ya.
    final tokenFuture = LiveKitTokenService.instance
        .createToken(
          roomName: roomName,
          identity: identity,
          name: name,
          canPublish: publishCamera || publishMicrophone,
          canPublishData: true,
          roomAdmin: publishCamera || publishMicrophone,
        )
        .timeout(const Duration(seconds: 12));
    final mediaFuture = _warmLocalMedia(
      publishCamera: publishCamera,
      publishMicrophone: publishMicrophone,
      profile: profile,
    );

    late final LiveKitTokenResult tokenResult;
    LocalVideoTrack? warmVideo;
    LocalAudioTrack? warmAudio;
    try {
      tokenResult = await tokenFuture;
      final warmed = await mediaFuture;
      warmVideo = warmed.$1;
      warmAudio = warmed.$2;
    } catch (e) {
      try {
        final warmed = await mediaFuture;
        await warmed.$1?.stop();
        await warmed.$1?.dispose();
        await warmed.$2?.stop();
        await warmed.$2?.dispose();
      } catch (_) {}
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

    try {
      await room
          .connect(
            url,
            tokenResult.token,
            connectOptions: const ConnectOptions(autoSubscribe: true),
          )
          .timeout(const Duration(seconds: 18));
    } catch (e) {
      await warmVideo?.stop();
      await warmVideo?.dispose();
      await warmAudio?.stop();
      await warmAudio?.dispose();
      try {
        await room.disconnect();
        await room.dispose();
      } catch (_) {}
      rethrow;
    }

    _room = room;
    _listener = listener;
    _mediaChanges.add(null);

    final lp = room.localParticipant;
    if (lp != null) {
      if (publishMicrophone) {
        _emitStatus('Micrófono…');
        await _publishMic(lp, warmAudio);
        warmAudio = null;
      } else {
        // Audiencia: nunca publicar mic.
        try {
          await lp.setMicrophoneEnabled(false);
        } catch (_) {}
      }
      if (publishCamera) {
        _emitStatus('Cámara…');
        await _publishCamera(lp, warmVideo, profile);
        warmVideo = null;
      } else {
        try {
          await lp.setCameraEnabled(false);
        } catch (_) {}
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

  /// Calidad elegida manualmente por el usuario (no auto-subir).
  bool userSelectedQuality = false;

  /// Cambia calidad en caliente (audiencia: suscripción; host: republica cámara).
  Future<void> setQualityProfile(
    LiveKitQualityProfile profile, {
    bool asHost = false,
  }) async {
    userSelectedQuality = true;
    qualityProfile = profile;
    if (!_qualityChanges.isClosed) {
      _qualityChanges.add(profile);
    }
    await preferRemoteVideoQuality(_subscribeQuality(profile));
    if (asHost && _room?.localParticipant != null) {
      final lp = _room!.localParticipant!;
      final wasCam = lp.isCameraEnabled();
      if (wasCam) {
        try {
          await lp.setCameraEnabled(false);
        } catch (_) {}
        await _publishCamera(lp, null, profile);
      }
    }
    _mediaChanges.add(null);
    Loggers.info('LiveKit quality set manually → $profile');
  }

  /// Solo baja automática si la red se pone mala. Nunca sube sola.
  Future<void> applyConnectionQuality(ConnectionQuality q) async {
    if (q != ConnectionQuality.poor && q != ConnectionQuality.lost) {
      // Si el usuario eligió calidad, respetarla; si no, mantener baja.
      await preferRemoteVideoQuality(_subscribeQuality(qualityProfile));
      return;
    }
    if (qualityProfile == LiveKitQualityProfile.low) {
      await preferRemoteVideoQuality(VideoQuality.LOW);
      return;
    }
    // Red mala: bajar a low (aunque el usuario hubiera subido).
    qualityProfile = LiveKitQualityProfile.low;
    if (!_qualityChanges.isClosed) {
      _qualityChanges.add(qualityProfile);
    }
    await preferRemoteVideoQuality(VideoQuality.LOW);
    Loggers.info('LiveKit quality forced LOW (connection $q)');
  }

  void _startStatsPolling() {
    _statsTimer?.cancel();
    _statsTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _tickStats();
    });
    _tickStats();
  }

  Future<void> _tickStats() async {
    if (_samplingStats) return;
    _samplingStats = true;
    try {
      await _sampleRtcStats();
      _emitStats();
    } finally {
      _samplingStats = false;
    }
  }

  Future<void> _sampleRtcStats() async {
    try {
      final pcReports = await _peerConnectionStats();
      final pingFromPc = _rttMsFromReports(pcReports);
      if (pingFromPc != null) _lastPingMs = pingFromPc;
      final fpsFromPc = _fpsFromReports(pcReports);
      if (fpsFromPc != null) _lastFps = fpsFromPc;

      final lp = _room?.localParticipant;
      for (final pub in lp?.videoTrackPublications ?? []) {
        final track = pub.track;
        if (track is! LocalVideoTrack) continue;
        try {
          final senderStats = await track.getSenderStats();
          for (final s in senderStats) {
            final rtt = s.roundTripTime;
            if (rtt != null && rtt > 0 && _lastPingMs <= 0) {
              final ms = (rtt < 10) ? (rtt * 1000).round() : rtt.round();
              if (ms > 0 && ms < 15000) _lastPingMs = ms;
            }
            final fps = s.framesPerSecond;
            if (fps != null && fps > 0) _lastFps = fps.round();
          }
        } catch (_) {}
        final sender = track.sender;
        if (sender == null) continue;
        final reports = await sender.getStats();
        _lastPingMs = _rttMsFromReports(reports) ?? _lastPingMs;
        _lastFps = _fpsFromReports(reports) ?? _lastFps;
      }
      for (final p in _room?.remoteParticipants.values ??
          const Iterable<RemoteParticipant>.empty()) {
        for (final pub in p.videoTrackPublications) {
          final track = pub.track;
          if (track is! RemoteVideoTrack) continue;
          final receiver = track.receiver;
          if (receiver == null) continue;
          final reports = await receiver.getStats();
          _lastPingMs = _rttMsFromReports(reports) ?? _lastPingMs;
          _lastFps = _fpsFromReports(reports) ?? _lastFps;
        }
      }
    } catch (_) {}

    if (_lastPingMs <= 0) {
      final signal = _signalRttMs();
      if (signal > 0) _lastPingMs = signal;
    }
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

  Future<(LocalVideoTrack?, LocalAudioTrack?)> _warmLocalMedia({
    required bool publishCamera,
    required bool publishMicrophone,
    required LiveKitQualityProfile profile,
  }) async {
    if (!publishCamera && !publishMicrophone) {
      return (null, null);
    }
    LocalVideoTrack? warmVideo;
    LocalAudioTrack? warmAudio;
    try {
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
      return (warmVideo, warmAudio);
    } catch (e) {
      Loggers.error('LiveKit media warm-up skipped: $e');
      try {
        await warmVideo?.stop();
        await warmVideo?.dispose();
      } catch (_) {}
      try {
        await warmAudio?.stop();
        await warmAudio?.dispose();
      } catch (_) {}
      return (null, null);
    }
  }

  Future<void> _ensureMediaPermissions({
    required bool camera,
    required bool microphone,
  }) async {
    await MediaPermissions.ensure(camera: camera, microphone: microphone);
  }

  Future<LocalVideoTrack?> _createCameraTrackSafe(
    LiveKitQualityProfile profile,
  ) async {
    final presets = <VideoParameters>[
      _captureParams(profile),
      _portraitFallbackLow,
    ];
    // Evitar duplicados.
    final tried = <String>{};
    for (final params in presets) {
      final key = '${params.dimensions.width}x${params.dimensions.height}';
      if (!tried.add(key)) continue;
      try {
        final track = await LocalVideoTrack.createCameraTrack(
          CameraCaptureOptions(
            cameraPosition: CameraPosition.front,
            params: params,
          ),
        ).timeout(const Duration(seconds: 8));
        return track;
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
      _portraitFallbackMid,
      _portraitFallbackLow,
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
    _lastFps = 0;
    _lastPingMs = 0;
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
