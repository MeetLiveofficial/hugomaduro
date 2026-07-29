import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;
import 'package:krimson/common/extensions/string_extension.dart';

/// Muestra media de regalos: GIF/WebP/PNG/JPG con [Image.network] y SVG con [SvgPicture].
class GiftMedia extends StatelessWidget {
  const GiftMedia({
    super.key,
    required this.path,
    required this.width,
    required this.height,
    this.fit = BoxFit.contain,
    this.placeholder,
  });

  /// Ruta relativa o URL absoluta del gift (`Gift.image` / `giftImage`).
  final String? path;
  final double width;
  final double height;
  final BoxFit fit;
  final Widget? placeholder;

  static bool isSvgPath(String? raw) {
    final p = (raw ?? '').toLowerCase().split('?').first.trim();
    return p.endsWith('.svg') || p.endsWith('.svgz');
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

    if (isSvgPath(raw) || isSvgPath(url)) {
      return _NetworkSvg(
        url: url,
        width: width,
        height: height,
        fit: fit,
        fallback: _fallback(),
      );
    }

    return Image.network(
      url,
      width: width,
      height: height,
      fit: fit,
      filterQuality: FilterQuality.high,
      gaplessPlayback: true,
      errorBuilder: (_, __, ___) => SizedBox(
        width: width,
        height: height,
        child: Center(child: _fallback()),
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
      // Algunos hosts sirven SVG con content-type raro; validamos el markup.
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
