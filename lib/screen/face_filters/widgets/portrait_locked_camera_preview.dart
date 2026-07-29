import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Igual que [CameraPreview], pero **siempre** asume [DeviceOrientation.portraitUp].
///
/// Evita el bug de BlueStacks/emuladores donde `deviceOrientation` es landscape
/// y el preview (y la cara) quedan de lado.
class PortraitLockedCameraPreview extends StatelessWidget {
  const PortraitLockedCameraPreview(
    this.controller, {
    super.key,
    this.child,
  });

  final CameraController controller;
  final Widget? child;

  static const _orientation = DeviceOrientation.portraitUp;

  @override
  Widget build(BuildContext context) {
    if (!controller.value.isInitialized) {
      return const ColoredBox(color: Colors.black);
    }

    return ValueListenableBuilder<CameraValue>(
      valueListenable: controller,
      builder: (context, value, overlay) {
        // Portrait UI: aspect = height/width del sensor (inverso del landscape).
        final aspect = 1 / value.aspectRatio;
        return AspectRatio(
          aspectRatio: aspect,
          child: Stack(
            fit: StackFit.expand,
            children: [
              _wrapAndroid(controller.buildPreview()),
              if (overlay != null) overlay,
            ],
          ),
        );
      },
      child: child,
    );
  }

  Widget _wrapAndroid(Widget child) {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return child;
    }
    // Mismo mapa que camera_preview.dart, pero fijado a portraitUp → 0.
    const turns = <DeviceOrientation, int>{
      DeviceOrientation.portraitUp: 0,
      DeviceOrientation.landscapeRight: 1,
      DeviceOrientation.portraitDown: 2,
      DeviceOrientation.landscapeLeft: 3,
    };
    return RotatedBox(quarterTurns: turns[_orientation]!, child: child);
  }
}
