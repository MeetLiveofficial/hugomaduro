import 'dart:ui' as ui;

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Preset de belleza (GPU / Impeller).
///
/// Uniforms del shader `shaders/beauty_skin.frag`:
/// - `uSize` (vec2) → 0–1 (engine)
/// - `uIntensity` → 2
/// - `uMode` → 3 (Soft/Porcelain/Fresh/Warm/Rose)
/// - `uWhiten` → 4
/// - `uRosy` → 5
/// - `uSmooth` → 6
/// - `uSharpen` → 7
class BeautyLook {
  const BeautyLook({
    required this.intensity,
    required this.mode,
    this.whiten = 0.5,
    this.rosy = 0.4,
    this.smooth = 0.55,
    this.sharpen = 0.35,
  });

  final double intensity;

  /// 0 Soft/Natural · 1 Porcelain · 2 Fresh · 3 Warm · 4 Rose
  final double mode;
  final double whiten;
  final double rosy;
  final double smooth;
  final double sharpen;
}

class BeautyShaderController extends ChangeNotifier {
  static const String assetPath = 'shaders/beauty_skin.frag';

  ui.FragmentProgram? _program;
  ui.FragmentShader? _shader;
  double _intensity = 0.0;
  double _mode = 0.0;
  double _whiten = 0.5;
  double _rosy = 0.4;
  double _smooth = 0.55;
  double _sharpen = 0.35;
  bool _ready = false;
  bool _failed = false;

  double get intensity => _intensity;
  double get mode => _mode;
  double get whiten => _whiten;
  double get rosy => _rosy;
  double get smooth => _smooth;
  double get sharpen => _sharpen;

  bool get isReady => _ready;

  bool get isSupported =>
      !kIsWeb &&
      ui.ImageFilter.isShaderFilterSupported &&
      _ready &&
      _shader != null;

  ui.FragmentShader? get shader {
    if (_shader == null) return null;
    _pushUniforms();
    return _shader;
  }

  Future<void> load() async {
    if (_ready || _failed) return;
    if (kIsWeb || !ui.ImageFilter.isShaderFilterSupported) {
      _failed = true;
      notifyListeners();
      return;
    }
    try {
      _program = await ui.FragmentProgram.fromAsset(assetPath);
      _shader = _program!.fragmentShader();
      _pushUniforms();
      _ready = true;
      notifyListeners();
    } catch (e, st) {
      debugPrint('BeautyShader load error: $e\n$st');
      _failed = true;
      notifyListeners();
    }
  }

  void _pushUniforms() {
    final s = _shader;
    if (s == null) return;
    s.setFloat(2, _intensity);
    s.setFloat(3, _mode);
    s.setFloat(4, _whiten);
    s.setFloat(5, _rosy);
    s.setFloat(6, _smooth);
    s.setFloat(7, _sharpen);
  }

  void setIntensity(double value) {
    final next = value.clamp(0.0, 1.0);
    if ((next - _intensity).abs() < 0.001) return;
    _intensity = next;
    _pushUniforms();
    notifyListeners();
  }

  void setLook(BeautyLook look) {
    final nextI = look.intensity.clamp(0.0, 1.0);
    final nextM = look.mode;
    final nextW = look.whiten.clamp(0.0, 1.0);
    final nextR = look.rosy.clamp(0.0, 1.0);
    final nextS = look.smooth.clamp(0.0, 1.0);
    final nextSh = look.sharpen.clamp(0.0, 1.0);
    if ((nextI - _intensity).abs() < 0.001 &&
        (nextM - _mode).abs() < 0.001 &&
        (nextW - _whiten).abs() < 0.001 &&
        (nextR - _rosy).abs() < 0.001 &&
        (nextS - _smooth).abs() < 0.001 &&
        (nextSh - _sharpen).abs() < 0.001) {
      return;
    }
    _intensity = nextI;
    _mode = nextM;
    _whiten = nextW;
    _rosy = nextR;
    _smooth = nextS;
    _sharpen = nextSh;
    _pushUniforms();
    notifyListeners();
  }

  @override
  void dispose() {
    _shader?.dispose();
    _shader = null;
    _program = null;
    _ready = false;
    _failed = false;
    super.dispose();
  }
}

/// Aplica belleza al [child] (CameraPreview / LiveKit texture).
///
/// Prioridad: fragment shader GPU → ColorFilter sutil.
/// Sin overlays a pantalla completa (evitan el “BG lavado”).
class BeautyFiltered extends StatelessWidget {
  const BeautyFiltered({
    super.key,
    required this.controller,
    required this.child,
  });

  final BeautyShaderController controller;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final intensity = controller.intensity;
        if (intensity <= 0.001) return child;

        final shader = controller.isSupported ? controller.shader : null;
        if (shader != null) {
          return ClipRect(
            child: ImageFiltered(
              imageFilter: ui.ImageFilter.shader(shader),
              child: child,
            ),
          );
        }

        // Fallback sin Impeller: tono + soft blur ligero (no overlay gris).
        final mode = controller.mode;
        final smoothSigma = (0.4 + controller.smooth * 1.6) * intensity;
        Widget layered = ColorFiltered(
          colorFilter: ColorFilter.matrix(
            _toneMatrix(
              mode: mode,
              intensity: intensity,
              whiten: controller.whiten,
              rosy: controller.rosy,
            ),
          ),
          child: child,
        );
        if (smoothSigma > 0.35) {
          layered = ClipRect(
            child: ImageFiltered(
              imageFilter: ui.ImageFilter.blur(
                sigmaX: smoothSigma,
                sigmaY: smoothSigma,
                tileMode: TileMode.decal,
              ),
              child: layered,
            ),
          );
        }
        return layered;
      },
    );
  }

  /// Matriz 4×5 (row-major) para [ColorFilter.matrix].
  static List<double> _toneMatrix({
    required double mode,
    required double intensity,
    required double whiten,
    required double rosy,
  }) {
    double r = 1, g = 1, b = 1;
    double ro = 0, go = 0, bo = 0;
    final w = whiten * intensity;
    final ry = rosy * intensity;

    if (mode < 0.5) {
      r = 1.0 + 0.04 * intensity;
      g = 1.0 + 0.03 * intensity;
      b = 1.0 + 0.02 * intensity;
    } else if (mode < 1.5) {
      r = 1.0 + 0.05 * intensity;
      g = 1.0 + 0.06 * intensity;
      b = 1.0 + 0.08 * intensity;
    } else if (mode < 2.5) {
      r = 1.0 + 0.02 * intensity;
      g = 1.0 + 0.05 * intensity;
      b = 1.0 + 0.09 * intensity;
    } else if (mode < 3.5) {
      r = 1.0 + 0.10 * intensity;
      g = 1.0 + 0.05 * intensity;
      b = 1.0 - 0.04 * intensity;
    } else {
      r = 1.0 + 0.10 * intensity;
      g = 1.0 + 0.01 * intensity;
      b = 1.0 + 0.05 * intensity;
    }

    ro += 0.04 * w + 0.035 * ry;
    go += 0.035 * w - 0.01 * ry;
    bo += 0.03 * w + 0.01 * ry;

    return <double>[
      r, 0, 0, 0, ro,
      0, g, 0, 0, go,
      0, 0, b, 0, bo,
      0, 0, 0, 1, 0,
    ];
  }
}

/// Preview de cámara frontal + beauty GPU + slider de intensidad.
class BeautyCameraPreview extends StatefulWidget {
  const BeautyCameraPreview({
    super.key,
    this.resolution = ResolutionPreset.high,
    this.enableAudio = false,
    this.initialIntensity = 0.55,
    this.showSlider = true,
    this.overlay,
    this.onControllerReady,
  });

  final ResolutionPreset resolution;
  final bool enableAudio;
  final double initialIntensity;
  final bool showSlider;
  final Widget? overlay;
  final void Function(CameraController camera, BeautyShaderController beauty)?
      onControllerReady;

  @override
  State<BeautyCameraPreview> createState() => _BeautyCameraPreviewState();
}

class _BeautyCameraPreviewState extends State<BeautyCameraPreview> {
  CameraController? _camera;
  late final BeautyShaderController _beauty;
  String? _error;
  bool _initializing = true;

  @override
  void initState() {
    super.initState();
    _beauty = BeautyShaderController()..setIntensity(widget.initialIntensity);
    _init();
  }

  Future<void> _init() async {
    try {
      await _beauty.load();
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() {
          _error = 'No camera available';
          _initializing = false;
        });
        return;
      }
      final front = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );
      final cam = CameraController(
        front,
        widget.resolution,
        enableAudio: widget.enableAudio,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );
      await cam.initialize();
      try {
        await cam.lockCaptureOrientation();
      } catch (_) {}
      if (!mounted) {
        await cam.dispose();
        return;
      }
      setState(() {
        _camera = cam;
        _initializing = false;
      });
      widget.onControllerReady?.call(cam, _beauty);
    } catch (e, st) {
      debugPrint('BeautyCameraPreview init error: $e\n$st');
      if (mounted) {
        setState(() {
          _error = e.toString();
          _initializing = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _camera?.dispose();
    _beauty.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_initializing) {
      return const ColoredBox(
        color: Colors.black,
        child: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }
    if (_error != null || _camera == null || !_camera!.value.isInitialized) {
      return ColoredBox(
        color: Colors.black,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              _error ?? 'Camera unavailable',
              style: const TextStyle(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        BeautyFiltered(
          controller: _beauty,
          child: CameraPreview(_camera!),
        ),
        if (widget.overlay != null) widget.overlay!,
        if (widget.showSlider)
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: _BeautyIntensitySlider(controller: _beauty),
          ),
      ],
    );
  }
}

class _BeautyIntensitySlider extends StatelessWidget {
  const _BeautyIntensitySlider({required this.controller});

  final BeautyShaderController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        return Material(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                const Icon(Icons.face_retouching_natural,
                    color: Colors.white, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Beauty',
                  style: TextStyle(color: Colors.white, fontSize: 13),
                ),
                Expanded(
                  child: Slider(
                    value: controller.intensity,
                    onChanged: controller.setIntensity,
                    min: 0,
                    max: 1,
                  ),
                ),
                Text(
                  '${(controller.intensity * 100).round()}%',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Slider reutilizable para pantallas que ya tienen su propia [CameraPreview].
class BeautyIntensitySliderBar extends StatelessWidget {
  const BeautyIntensitySliderBar({super.key, required this.controller});

  final BeautyShaderController controller;

  @override
  Widget build(BuildContext context) =>
      _BeautyIntensitySlider(controller: controller);
}
