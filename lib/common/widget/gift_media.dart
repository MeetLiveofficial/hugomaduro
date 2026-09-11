import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;
import 'package:krimson/common/extensions/string_extension.dart';
import 'package:krimson/common/manager/gift_media_cache.dart';
import 'package:video_player/video_player.dart';

/// Media de regalos: GIF/WebP/PNG/JPG, SVG o MP4.
/// Por defecto el MP4 lleva audio; en miniaturas usar [muted]: true.
class GiftMedia extends StatelessWidget {
  const GiftMedia({
    super.key,
    required this.path,
    required this.width,
    required this.height,
    this.fit = BoxFit.contain,
    this.placeholder,
    this.onVideoEnded,
    this.onVideoReady,
    this.muted = false,
    this.looping = false,
    this.autoplay = true,
  });

  /// Ruta relativa o URL absoluta del gift (`Gift.image` / `giftImage`).
  final String? path;
  final double width;
  final double height;
  final BoxFit fit;
  final Widget? placeholder;
  final VoidCallback? onVideoEnded;
  /// Duración real del MP4 tras inicializar.
  final ValueChanged<Duration>? onVideoReady;
  /// Miniaturas / lista: sin sonido. Overlay al enviar: con sonido.
  final bool muted;
  final bool looping;
  final bool autoplay;

  static bool isSvgPath(String? raw) {
    final p = (raw ?? '').toLowerCase().split('?').first.trim();
    return p.endsWith('.svg') || p.endsWith('.svgz');
  }

  static bool isVideoPath(String? raw) {
    final p = (raw ?? '').toLowerCase().split('?').first.trim();
    return p.endsWith('.mp4') || p.endsWith('.m4v') || p.endsWith('.webm');
  }

  Widget _fallback() {
    return placeholder ??
        Icon(Icons.card_giftcard, size: width * 0.75, color: Colors.white70);
  }

  @override
  Widget build(BuildContext context) {
    final raw = (path ?? '').trim();
    if (raw.isEmpty) {
      return SizedBox(width: width, height: height, child: Center(child: _fallback()));
    }

    final url = raw.addBaseURL();
    if (url.isEmpty) {
      return SizedBox(width: width, height: height, child: Center(child: _fallback()));
    }

    if (isVideoPath(raw) || isVideoPath(url)) {
      // Miniaturas (autoplay: false): no crear VideoPlayer. En iOS un MP4
      // en el chat/pedido ocupa el decoder y el overlay del regalo no se ve.
      if (!autoplay) {
        return SizedBox(
          width: width,
          height: height,
          child: Center(child: _fallback()),
        );
      }
      return _GiftVideo(
        url: url,
        width: width,
        height: height,
        fit: fit,
        fallback: _fallback(),
        onEnded: onVideoEnded,
        onReady: onVideoReady,
        muted: muted,
        looping: looping,
        autoplay: autoplay,
      );
    }

    if (isSvgPath(raw) || isSvgPath(url)) {
      return _NetworkSvg(
        url: url,
        width: width,
        height: height,
        fit: fit,
        fallback: _fallback(),
      );
    }

    return _GiftRaster(
      url: url,
      width: width,
      height: height,
      fit: fit,
      fallback: _fallback(),
      onReady: onVideoReady,
    );
  }
}

class _GiftVideo extends StatefulWidget {
  const _GiftVideo({
    required this.url,
    required this.width,
    required this.height,
    required this.fit,
    required this.fallback,
    this.onEnded,
    this.onReady,
    this.muted = false,
    this.looping = false,
    this.autoplay = true,
  });

  final String url;
  final double width;
  final double height;
  final BoxFit fit;
  final Widget fallback;
  final VoidCallback? onEnded;
  final ValueChanged<Duration>? onReady;
  final bool muted;
  final bool looping;
  final bool autoplay;

  @override
  State<_GiftVideo> createState() => _GiftVideoState();
}

class _GiftVideoState extends State<_GiftVideo> {
  VideoPlayerController? _controller;
  bool _failed = false;
  bool _endedNotified = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    File? cached;
    if (!kIsWeb) {
      cached = await GiftMediaCache.cachedFileIfReady(widget.url);
    }
    if (!mounted) return;

    var usedCache = cached != null;
    var controller = _controllerFor(cached);
    _controller = controller;
    try {
      await controller.initialize();
    } catch (e) {
      try {
        await controller.dispose();
      } catch (_) {}
      if (!mounted) return;
      if (usedCache) {
        usedCache = false;
        controller = _controllerFor(null);
        _controller = controller;
        try {
          await controller.initialize();
        } catch (e2) {
          await _failInit(controller, e2);
          return;
        }
      } else {
        await _failInit(controller, e);
        return;
      }
    }
    if (!mounted) {
      await controller.dispose();
      return;
    }
    try {
      await controller.setVolume(widget.muted ? 0.0 : 1.0);
      await controller.setLooping(widget.looping);
      if (!widget.looping) {
        controller.addListener(_onTick);
      }
      widget.onReady?.call(controller.value.duration);
      if (widget.autoplay) {
        await controller.play();
      } else {
        await controller.seekTo(Duration.zero);
        await controller.pause();
      }
      if (mounted) setState(() {});
    } catch (e) {
      await _failInit(controller, e);
    }
  }

  VideoPlayerController _controllerFor(File? file) {
    final opts = VideoPlayerOptions(mixWithOthers: true);
    if (file != null) {
      return VideoPlayerController.file(file, videoPlayerOptions: opts);
    }
    return VideoPlayerController.networkUrl(
      Uri.parse(widget.url),
      videoPlayerOptions: opts,
    );
  }

  Future<void> _failInit(VideoPlayerController controller, Object e) async {
    if (kDebugMode) {
      debugPrint('GiftMedia video failed: ${widget.url} → $e');
    }
    try {
      await controller.dispose();
    } catch (_) {}
    if (_controller == controller) {
      _controller = null;
    }
    if (mounted) {
      setState(() => _failed = true);
    }
    // No onEnded: el overlay tiene timer de seguridad. Si avisamos al
    // fallar, el regalo se cierra al instante y parece que "no salió".
  }

  void _onTick() {
    final c = _controller;
    if (c == null || !c.value.isInitialized || _endedNotified) return;
    final pos = c.value.position;
    final dur = c.value.duration;
    if (dur.inMilliseconds <= 0) return;
    // Fin real del video (margen 120 ms por redondeo de frames).
    final ended = pos >= dur - const Duration(milliseconds: 120) ||
        (!c.value.isPlaying &&
            pos > Duration.zero &&
            pos.inMilliseconds >= dur.inMilliseconds - 200);
    if (ended) {
      _endedNotified = true;
      widget.onEnded?.call();
    }
  }

  @override
  void dispose() {
    final c = _controller;
    _controller = null;
    c?.removeListener(_onTick);
    c?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_failed) {
      return SizedBox(
        width: widget.width,
        height: widget.height,
        child: Center(child: widget.fallback),
      );
    }
    final c = _controller;
    if (c == null || !c.value.isInitialized) {
      return SizedBox(
        width: widget.width,
        height: widget.height,
        child: const Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: FittedBox(
        fit: widget.fit,
        clipBehavior: Clip.hardEdge,
        child: SizedBox(
          width: c.value.size.width,
          height: c.value.size.height,
          child: VideoPlayer(c),
        ),
      ),
    );
  }
}

class _GiftRaster extends StatefulWidget {
  const _GiftRaster({
    required this.url,
    required this.width,
    required this.height,
    required this.fit,
    required this.fallback,
    this.onReady,
  });

  final String url;
  final double width;
  final double height;
  final BoxFit fit;
  final Widget fallback;
  final ValueChanged<Duration>? onReady;

  @override
  State<_GiftRaster> createState() => _GiftRasterState();
}

class _GiftRasterState extends State<_GiftRaster> {
  File? _file;
  bool _readyNotified = false;

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  Future<void> _resolve() async {
    if (kIsWeb) return;
    final file = await GiftMediaCache.cachedFileIfReady(widget.url);
    if (!mounted) return;
    if (file != null) {
      setState(() => _file = file);
    }
  }

  void _notifyReady() {
    if (_readyNotified) return;
    _readyNotified = true;
    widget.onReady?.call(Duration.zero);
  }

  void _notifyFailed() {
    // El overlay no se cierra: se ve el fallback y sigue la animación.
  }

  Widget _box({required Widget child}) {
    return SizedBox(width: widget.width, height: widget.height, child: child);
  }

  @override
  Widget build(BuildContext context) {
    final image = _file != null
        ? Image.file(
            _file!,
            width: widget.width,
            height: widget.height,
            fit: widget.fit,
            filterQuality: FilterQuality.high,
            gaplessPlayback: true,
            frameBuilder: _frameBuilder,
            errorBuilder: (_, __, ___) => Image.network(
              widget.url,
              width: widget.width,
              height: widget.height,
              fit: widget.fit,
              filterQuality: FilterQuality.high,
              gaplessPlayback: true,
              frameBuilder: _frameBuilder,
              loadingBuilder: _loadingBuilder,
              errorBuilder: (_, __, ___) {
                WidgetsBinding.instance
                    .addPostFrameCallback((_) => _notifyFailed());
                return _box(child: Center(child: widget.fallback));
              },
            ),
          )
        : Image.network(
            widget.url,
            width: widget.width,
            height: widget.height,
            fit: widget.fit,
            filterQuality: FilterQuality.high,
            gaplessPlayback: true,
            frameBuilder: _frameBuilder,
            loadingBuilder: _loadingBuilder,
            errorBuilder: (_, __, ___) {
              WidgetsBinding.instance
                  .addPostFrameCallback((_) => _notifyFailed());
              return _box(child: Center(child: widget.fallback));
            },
          );

    return image;
  }

  Widget _frameBuilder(
    BuildContext context,
    Widget child,
    int? frame,
    bool wasSynchronouslyLoaded,
  ) {
    if (frame != null || wasSynchronouslyLoaded) {
      _notifyReady();
    }
    return child;
  }

  Widget _loadingBuilder(
    BuildContext context,
    Widget child,
    ImageChunkEvent? progress,
  ) {
    if (progress == null) return child;
    return _box(
      child: const Center(
        child: SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }
}

class _NetworkSvg extends StatefulWidget {
  const _NetworkSvg({
    required this.url,
    required this.width,
    required this.height,
    required this.fit,
    required this.fallback,
  });

  final String url;
  final double width;
  final double height;
  final BoxFit fit;
  final Widget fallback;

  @override
  State<_NetworkSvg> createState() => _NetworkSvgState();
}

class _NetworkSvgState extends State<_NetworkSvg> {
  late final Future<String?> _future = _load();

  Future<String?> _load() async {
    try {
      final res = await http.get(Uri.parse(widget.url));
      if (res.statusCode < 200 || res.statusCode >= 300) return null;
      final body = res.body.trim();
      if (body.isEmpty) return null;
      if (!body.contains('<svg') && !body.contains('<SVG')) return null;
      return body;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('GiftMedia SVG load failed: ${widget.url} → $e');
      }
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return SizedBox(
            width: widget.width,
            height: widget.height,
            child: const Center(
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }
        final xml = snap.data;
        if (xml == null || xml.isEmpty) {
          return SizedBox(
            width: widget.width,
            height: widget.height,
            child: Center(child: widget.fallback),
          );
        }
        try {
          return SvgPicture.string(
            xml,
            width: widget.width,
            height: widget.height,
            fit: widget.fit,
            allowDrawingOutsideViewBox: true,
          );
        } catch (e) {
          if (kDebugMode) {
            debugPrint('GiftMedia SVG parse failed: $e');
          }
          return SizedBox(
            width: widget.width,
            height: widget.height,
            child: Center(child: widget.fallback),
          );
        }
      },
    );
  }
}
