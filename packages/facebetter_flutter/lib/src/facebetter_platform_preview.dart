import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import 'facebetter_beauty_params.dart';
import 'facebetter_controller.dart';

/// Preview nativo FaceBetter (GLSurfaceView), igual al demo oficial.
///
/// https://demo.facebetter.net/
class FaceBetterPlatformPreview extends StatelessWidget {
  const FaceBetterPlatformPreview({
    super.key,
    required this.appId,
    required this.appKey,
    this.controller,
  });

  final String appId;
  final String appKey;
  final FaceBetterController? controller;

  static const String viewType = 'facebetter_preview';

  @override
  Widget build(BuildContext context) {
    if (kIsWeb || !Platform.isAndroid) {
      return const ColoredBox(
        color: Colors.black,
        child: Center(
          child: Text(
            'FaceBetter preview: solo Android',
            style: TextStyle(color: Colors.white70),
          ),
        ),
      );
    }

    return AndroidView(
      viewType: viewType,
      layoutDirection: TextDirection.ltr,
      creationParams: <String, dynamic>{
        'appId': appId,
        'appKey': appKey,
      },
      creationParamsCodec: const StandardMessageCodec(),
      gestureRecognizers: const <Factory<OneSequenceGestureRecognizer>>{},
      onPlatformViewCreated: (id) {
        controller?.attachView(id);
      },
    );
  }
}
