import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';

/// Iframe a https://nexusdevtech.com/wompi/checkout/… (ahí vive el pago).
class WompiCheckoutFrame extends StatefulWidget {
  const WompiCheckoutFrame({super.key, required this.url});

  final String url;

  @override
  State<WompiCheckoutFrame> createState() => _WompiCheckoutFrameState();
}

class _WompiCheckoutFrameState extends State<WompiCheckoutFrame> {
  late final String _viewType = 'wompi-checkout-${identityHashCode(this)}';

  @override
  void initState() {
    super.initState();
    ui_web.platformViewRegistry.registerViewFactory(_viewType, (int viewId) {
      return html.IFrameElement()
        ..src = widget.url
        ..style.border = '0'
        ..style.width = '100%'
        ..style.height = '100%'
        ..allow = 'payment *';
    });
  }

  @override
  Widget build(BuildContext context) {
    return HtmlElementView(viewType: _viewType);
  }
}
