import 'dart:ui' as ui;

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Controla el [FragmentShader] de belleza (GPU / Impeller).
///
/// Uniforms del shader `shaders/beauty_skin.frag`:
/// - `uSize` (vec2) → índices 0–1, lo rellena el engine con [ui.ImageFilter.shader]
/// - `uIntensity` (float) → índice **2**
/// - `uMode` (float) → índice **3** (look Soft/Porcelain/Fresh/Warm/Rose)
/// - `uTexture` (sampler) → lo enlaza el engine
class BeautyLook {
  const BeautyLook({required this.intensity, required this.mode});

  final double intensity;
  /// 0 Soft/Natural · 1 Porcelain · 2 Fresh · 3 Warm · 4 Rose
  final double mode;
}

class BeautyShaderController extends ChangeNotifier {
  static const String assetPath = 'shaders/beauty_skin.frag';

  ui.FragmentProgram? _program;
  ui.FragmentShader? _shader;
  double _intensity = 0.0;
  double _mode = 0.0;
  bool _ready = false;
  bool _failed = false;

  double get intensity => _intensity;
  double get mode => _mode;

  bool get isReady => _ready;

  bool get isSupported =>
      !kIsWeb && ui.ImageFilter.isShaderFilterSupported && _ready && _shader != null;

  ui.FragmentShader? get shader => _shader;

  Future<void> load() async {
    if (_ready || _failed) return;
    // ColorFiltered/blur funcionan sin Impeller; el shader es opcional.
    if (kIsWeb || !ui.ImageFilter.isShaderFilterSupported) {
      _failed = true; // no shader, pero setLook sigue notificando
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
    _shader?.setFloat(2, _intensity);
    _shader?.setFloat(3, _mode);
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
    if ((nextI - _intensity).abs() < 0.001 && (nextM - _mode).abs() < 0.001) {
      return;
    }
    _intensity = nextI;
    _mode = nextM;
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

/// Aplica belleza al [child] (p. ej. [CameraPreview] / LiveKit).
///
/// Importante: en Android/emulador la **Texture** de cámara suele ignorar
/// `ColorFiltered` / `ImageFilter`. Por eso el efecto visible se hace con
/// **overlays** encima del video (siempre se ven), más un intento opcional
/// de ColorFilter/blur/shader por si el device sí los soporta.
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

        final mode = controller.mode;
        final tint = _tintColor(mode);
        final lift = _liftAlpha(mode, intensity);

        Widget layered = child;

        // Best-effort (muchos devices lo ignoran sobre Texture).
        try {
          layered = ColorFiltered(
            colorFilter: ColorFilter.matrix(
              _toneMatrix(mode: mode, intensity: intensity * 0.85),
            ),
            child: layered,
          );
        } catch (_) {}

        return Stack(
          fit: StackFit.expand,
          children: [
            layered,
            // Glow central (piel más luminosa) — siempre visible.
            IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0, -0.12),
                    radius: 0.95,
                    colors: [
                      Colors.white.withValues(alpha: lift),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            // Tinte del look (Warm/Rose/Fresh…) — siempre visible.
            IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0, -0.05),
                    radius: 1.15,
                    colors: [
                      tint.withValues(alpha: 0.10 + 0.22 * intensity),
                      tint.withValues(alpha: 0.22 + 0.38 * intensity),
                    ],
                  ),
                ),
              ),
            ),
            // Soft vignette (look “beauty cam”).
            IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 1.05,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.12 * intensity),
                    ],
                    stops: const [0.55, 1.0],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  static Color _tintColor(double mode) {
    if (mode < 0.5) return const Color(0xFFFFE0D0); // Soft / Natural
    if (mode < 1.5) return const Color(0xFFFFF5FA); // Porcelain
    if (mode < 2.5) return const Color(0xFFB3E5FC); // Fresh
    if (mode < 3.5) return const Color(0xFFFFB74D); // Warm
    return const Color(0xFFF48FB1); // Rose
  }

  static double _liftAlpha(double mode, double intensity) {
    final base = mode >= 0.5 && mode < 1.5 ? 0.28 : 0.16;
    return (base * intensity).clamp(0.0, 0.4);
  }

  /// Matriz 4×5 (row-major) para [ColorFilter.matrix].
  static List<double> _toneMatrix({
    required double mode,
    required double intensity,
  }) {
    double r = 1, g = 1, b = 1;
    double ro = 0, go = 0, bo = 0;

    if (mode < 0.5) {
      r = 1.0 + 0.06 * intensity;
      g = 1.0 + 0.04 * intensity;
      b = 1.0 + 0.02 * intensity;
      ro = 0.03 * intensity;
      go = 0.02 * intensity;
      bo = 0.01 * intensity;
    } else if (mode < 1.5) {
      r = 1.0 + 0.08 * intensity;
      g = 1.0 + 0.09 * intensity;
      b = 1.0 + 0.12 * intensity;
      ro = 0.05 * intensity;
      go = 0.05 * intensity;
      bo = 0.06 * intensity;
    } else if (mode < 2.5) {
      r = 1.0 + 0.03 * intensity;
      g = 1.0 + 0.07 * intensity;
      b = 1.0 + 0.14 * intensity;
      ro = 0.02 * intensity;
      go = 0.03 * intensity;
      bo = 0.06 * intensity;
    } else if (mode < 3.5) {
      r = 1.0 + 0.16 * intensity;
      g = 1.0 + 0.08 * intensity;
      b = 1.0 - 0.10 * intensity;
      ro = 0.06 * intensity;
      go = 0.03 * intensity;
      bo = -0.03 * intensity;
    } else {
      r = 1.0 + 0.18 * intensity;
      g = 1.0 - 0.02 * intensity;
      b = 1.0 + 0.08 * intensity;
      ro = 0.07 * intensity;
      go = 0.01 * intensity;
      bo = 0.04 * intensity;
    }

    return <double>[
      r, 0, 0, 0, ro,
      0, g, 0, 0, go,
      0, 0, b, 0, bo,
      0, 0, 0, 1, 0,
    ];
  }
}

/// Preview de cámara frontal + beauty GPU + slider de intensidad.
///
/// Uso mínimo:
/// ```dart
/// BeautyCameraPreview(
///   resolution: ResolutionPreset.high, // ~720p, buen balance 30–60 FPS
/// )
/// ```
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

  /// `high` ≈ 720p — recomendado para 30–60 FPS con shader.
  /// Evitar `max`/`ultraHigh` si hay lag.
  final ResolutionPreset resolution;

  final bool enableAudio;
  final double initialIntensity;
  final bool showSlider;

  /// Capas encima del preview (p. ej. Face Mesh).
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
      // Intentar 60 FPS si el dispositivo lo permite (best-effort).
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
