import 'package:flutter/material.dart';
import 'package:webview_flutter_plus/webview_flutter_plus.dart';

/// En móvil el WebView carga la misma URL; la página de NexusDevTech
/// mete el formulario de MeetLive en un iframe.
class WompiCheckoutFrame extends StatefulWidget {
  const WompiCheckoutFrame({super.key, required this.url});

  final String url;

  @override
  State<WompiCheckoutFrame> createState() => _WompiCheckoutFrameState();
}

class _WompiCheckoutFrameState extends State<WompiCheckoutFrame> {
  late final WebViewControllerPlus _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewControllerPlus()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF09090B))
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return WebViewWidget(controller: _controller);
  }
}
