import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:http/http.dart' as http;

import '../controller/story_controller.dart';
import '../utils.dart';

/// Utility to load image (gif, png, jpg, etc) media just once.
class ImageLoader {
  ui.Codec? frames;

  String url;

  Map<String, dynamic>? requestHeaders;

  LoadState state = LoadState.loading;

  ImageLoader(this.url, {this.requestHeaders});

  void loadImage(VoidCallback onComplete) {
    if (frames != null) {
      state = LoadState.success;
      onComplete();
      return;
    }

    if (url.isEmpty) {
      state = LoadState.failure;
      onComplete();
      return;
    }

    if (kIsWeb) {
      _loadBytesWeb(onComplete);
      return;
    }

    final fileStream = DefaultCacheManager()
        .getFileStream(url, headers: requestHeaders as Map<String, String>?);

    fileStream.listen(
      (fileResponse) {
        if (fileResponse is! FileInfo) return;
        if (frames != null) return;
        final imageBytes = fileResponse.file.readAsBytesSync();
        _decode(imageBytes, onComplete);
      },
      onError: (_) {
        state = LoadState.failure;
        onComplete();
      },
    );
  }

  Future<void> _loadBytesWeb(VoidCallback onComplete) async {
    try {
      final headers = <String, String>{};
      requestHeaders?.forEach((k, v) {
        if (v != null) headers[k] = '$v';
      });
      final response = await http.get(Uri.parse(url), headers: headers);
      if (response.statusCode >= 200 &&
          response.statusCode < 300 &&
          response.bodyBytes.isNotEmpty) {
        await _decode(response.bodyBytes, onComplete);
      } else {
        state = LoadState.failure;
        onComplete();
      }
    } catch (_) {
      state = LoadState.failure;
      onComplete();
    }
  }

  Future<void> _decode(List<int> imageBytes, VoidCallback onComplete) async {
    try {
      final codec =
          await ui.instantiateImageCodec(Uint8List.fromList(imageBytes));
      frames = codec;
      state = LoadState.success;
      onComplete();
    } catch (_) {
      state = LoadState.failure;
      onComplete();
    }
  }
}

/// Widget to display animated gifs or still images.
class StoryImage extends StatefulWidget {
  final ImageLoader imageLoader;

  final BoxFit? fit;

  final StoryController? controller;

  StoryImage(
    this.imageLoader, {
    Key? key,
    this.controller,
    this.fit,
  }) : super(key: key ?? UniqueKey());

  factory StoryImage.url(
    String url, {
    StoryController? controller,
    Map<String, dynamic>? requestHeaders,
    BoxFit fit = BoxFit.fitWidth,
    Key? key,
  }) {
    return StoryImage(
        ImageLoader(
          url,
          requestHeaders: requestHeaders,
        ),
        controller: controller,
        fit: fit,
        key: key);
  }

  @override
  State<StatefulWidget> createState() => StoryImageState();
}

class StoryImageState extends State<StoryImage> {
  ui.Image? currentFrame;

  Timer? _timer;

  StreamSubscription<PlaybackState>? _streamSubscription;

  @override
  void initState() {
    super.initState();

    if (widget.controller != null) {
      _streamSubscription =
          widget.controller!.playbackNotifier.listen((playbackState) {
        if (widget.imageLoader.frames == null) {
          return;
        }

        if (playbackState == PlaybackState.pause) {
          _timer?.cancel();
        } else {
          forward();
        }
      });
    }

    widget.controller?.pause();

    widget.imageLoader.loadImage(() async {
      if (mounted) {
        if (widget.imageLoader.state == LoadState.success) {
          widget.controller?.play();
          forward();
        } else {
          setState(() {});
        }
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _streamSubscription?.cancel();
    super.dispose();
  }

  @override
  void setState(fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  void forward() async {
    _timer?.cancel();

    if (widget.controller != null &&
        widget.controller!.playbackNotifier.stream.value ==
            PlaybackState.pause) {
      return;
    }

    final nextFrame = await widget.imageLoader.frames!.getNextFrame();

    currentFrame = nextFrame.image;

    if (nextFrame.duration > const Duration(milliseconds: 0)) {
      _timer = Timer(nextFrame.duration, forward);
    }

    setState(() {});
  }

  Widget getContentView() {
    switch (widget.imageLoader.state) {
      case LoadState.success:
        return RawImage(
          image: currentFrame,
          fit: (currentFrame?.width ?? 0) >= (currentFrame?.height ?? 0)
              ? widget.fit
              : BoxFit.cover,
        );
      case LoadState.failure:
        // Fallback HTML/network image on Web (CORS/cache issues).
        if (kIsWeb && widget.imageLoader.url.isNotEmpty) {
          return Image.network(
            widget.imageLoader.url,
            fit: widget.fit ?? BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            errorBuilder: (_, __, ___) => const Center(
              child: Text(
                'Image failed to load.',
                style: TextStyle(color: Colors.white),
              ),
            ),
          );
        }
        return const Center(
            child: Text(
          'Image failed to load.',
          style: TextStyle(color: Colors.white),
        ));
      default:
        return const Center(
          child: SizedBox(
            width: 70,
            height: 70,
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              strokeWidth: 3,
            ),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: double.infinity,
      child: getContentView(),
    );
  }
}
