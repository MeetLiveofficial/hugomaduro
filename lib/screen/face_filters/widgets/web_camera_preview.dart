import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Preview de cámara web (HtmlElementView sobre getUserMedia).
class WebCameraPreview extends StatelessWidget {
  const WebCameraPreview({
    super.key,
    required this.viewType,
    this.placeholder,
  });

  final String viewType;
  final Widget? placeholder;

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb || viewType.isEmpty) {
      return placeholder ?? const ColoredBox(color: Colors.black);
    }
    return HtmlElementView(viewType: viewType);
  }
}
