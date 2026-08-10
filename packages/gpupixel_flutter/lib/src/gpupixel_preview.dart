import 'package:flutter/material.dart';

import 'gpupixel_controller.dart';

/// Preview zero-copy: [Texture] alimentada por el pipeline nativo GPUPixel.
class GpuPixelPreview extends StatelessWidget {
  const GpuPixelPreview({
    super.key,
    required this.controller,
    this.fit = BoxFit.cover,
    this.placeholder,
  });

  final GpuPixelController controller;
  final BoxFit fit;
  final Widget? placeholder;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final id = controller.textureId;
        if (id == null) {
          return placeholder ??
              const ColoredBox(
                color: Colors.black,
                child: Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              );
        }
        return FittedBox(
          fit: fit,
          clipBehavior: Clip.hardEdge,
          child: SizedBox(
            width: 720,
            height: 1280,
            child: Texture(textureId: id),
          ),
        );
      },
    );
  }
}

/// Panel de sliders GPUPixel (suavizado / blanqueamiento / perfilado / ojos).
class GpuPixelBeautySliders extends StatelessWidget {
  const GpuPixelBeautySliders({
    super.key,
    required this.controller,
    this.onChanged,
  });

  final GpuPixelController controller;
  final VoidCallback? onChanged;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final p = controller.params;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _row('Suavizado', p.smooth, (v) async {
              await controller.setSmooth(v);
              onChanged?.call();
            }),
            _row('Blanqueamiento', p.whiten, (v) async {
              await controller.setWhiten(v);
              onChanged?.call();
            }),
            _row('Perfilado', p.slimFace, (v) async {
              await controller.setSlimFace(v);
              onChanged?.call();
            }),
            _row('Ojos', p.bigEye, (v) async {
              await controller.setBigEye(v);
              onChanged?.call();
            }),
          ],
        );
      },
    );
  }

  Widget _row(String label, double value, ValueChanged<double> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 108,
            child: Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ),
          Expanded(
            child: SliderTheme(
              data: const SliderThemeData(
                trackHeight: 2,
                thumbShape: RoundSliderThumbShape(enabledThumbRadius: 7),
                overlayShape: RoundSliderOverlayShape(overlayRadius: 12),
                activeTrackColor: Colors.white,
                inactiveTrackColor: Colors.white24,
                thumbColor: Colors.white,
              ),
              child: Slider(
                value: value.clamp(0, 1),
                onChanged: onChanged,
              ),
            ),
          ),
          SizedBox(
            width: 32,
            child: Text(
              '${(value * 100).round()}',
              textAlign: TextAlign.end,
              style: const TextStyle(color: Colors.white54, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }
}
