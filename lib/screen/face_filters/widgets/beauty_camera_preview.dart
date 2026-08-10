import 'dart:ui' as ui;

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Controla el [FragmentShader] de belleza (GPU / Impeller).
///
/// Uniforms del shader `shaders/beauty_skin.frag`:
/// - `uSize` (vec2) → índices 0–1, lo rellena el engine con [ui.ImageFilter.shader]
/// - `uIntensity` (float) → índice **2**
/// - `uMode` (float) → índice **3** (Soft/Porcelain/Fresh/Warm/Rose/Beauty HD)
/// - `uWhiten` / `uRosy` / `uSharpen` → índices **4–6**
/// - `uTexture` (sampler) → lo enlaza el engine
class BeautyLook {
  const BeautyLook({
    required this.intensity,
    required this.mode,
    this.whiten = 0,
    this.rosy = 0,
    this.sharpen = 0,
  });

  final double intensity;
  /// 0 Soft · 1 Porcelain · 2 Fresh · 3 Warm · 4 Rose · 5 Beauty HD
  /// 6 Dewy · 7 Matte · 8 Peach · 9 Night · 10 Crystal · 11 Glass
  final double mode;
  /// 0–1 — lift / whiten overlay (responde al slider en vivo).
  final double whiten;
  /// 0–1 — blush / rosy overlay.
  final double rosy;
  /// 0–1 — contraste / definición.
  final double sharpen;
}

/// Combina sliders (0–100) + preset opcional en un [BeautyLook] continuo.
/// Cada slider cambia el resultado para que el preview reaccione al arrastrar.
BeautyLook beautyLookFromSliders({
  required bool enabled,
  double? presetMode,
  double? presetIntensity,
  required double whiten,
  required double rosy,
  required double smooth,
  required double sharpen,
}) {
  if (!enabled) {
    return const BeautyLook(intensity: 0, mode: 0);
  }

  final w = (whiten / 100.0).clamp(0.0, 1.0);
  final r = (rosy / 100.0).clamp(0.0, 1.0);
  final s = (smooth / 100.0).clamp(0.0, 1.0);
  final sh = (sharpen / 100.0).clamp(0.0, 1.0);

  late final double mode;
  late final double base;
  if (presetMode != null && presetIntensity != null) {
    mode = presetMode;
    base = presetIntensity;
  } else if (r >= w && r >= 0.35) {
    mode = 4;
    base = 0.55 + 0.35 * s;
  } else if (w >= 0.55) {
    mode = 1;
    base = 0.55 + 0.35 * s;
  } else if (w >= 0.35) {
    mode = 2;
    base = 0.55 + 0.35 * s;
  } else if (r >= 0.2) {
    mode = 4;
    base = 0.5 + 0.35 * s;
  } else if (s >= 0.65) {
    // Smooth alto sin tint fuerte → Beauty HD
    mode = 5;
    base = 0.62 + 0.35 * s;
  } else {
    mode = 0;
    base = 0.45 + 0.4 * s;
  }

  // Mínimo visible: si beauty está On, el overlay debe notarse en LIVE.
  final intensity = (base *
          (0.55 + 0.45 * s) *
          (0.85 + 0.15 * sh) *
          (0.80 + 0.20 * (0.55 * w + 0.45 * r)))
      .clamp(0.45, 1.0);

  return BeautyLook(
    intensity: intensity,
    mode: mode,
    whiten: w,
    rosy: r,
    sharpen: sh,
  );
}

class BeautyShaderController extends ChangeNotifier {
  static const String assetPath = 'shaders/beauty_skin.frag';

  ui.FragmentProgram? _program;
  ui.FragmentShader? _shader;
  double _intensity = 0.0;
  double _mode = 0.0;
  double _whiten = 0.0;
  double _rosy = 0.0;
  double _sharpen = 0.0;
  bool _ready = false;
  bool _failed = false;

  double get intensity => _intensity;
  double get mode => _mode;
  double get whiten => _whiten;
  double get rosy => _rosy;
  double get sharpen => _sharpen;

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
    _shader?.setFloat(4, _whiten);
    _shader?.setFloat(5, _rosy);
    _shader?.setFloat(6, _sharpen);
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
    final nextS = look.sharpen.clamp(0.0, 1.0);
    if ((nextI - _intensity).abs() < 0.0005 &&
        (nextM - _mode).abs() < 0.0005 &&
        (nextW - _whiten).abs() < 0.0005 &&
        (nextR - _rosy).abs() < 0.0005 &&
        (nextS - _sharpen).abs() < 0.0005) {
      return;
    }
    _intensity = nextI;
    _mode = nextM;
    _whiten = nextW;
    _rosy = nextR;
    _sharpen = nextS;
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
        final whiten = controller.whiten;
        final rosy = controller.rosy;
        final sharpen = controller.sharpen;
        final active = intensity > 0.001 ||
            whiten > 0.001 ||
            rosy > 0.001 ||
            sharpen > 0.001;
        if (!active) return child;

        final mode = controller.mode;
        final tint = _tintColor(mode);
        // Lift suave y neutro (sin velo crema/amarillo).
        final lift = (_liftAlpha(mode, intensity) + 0.18 * whiten).clamp(0.0, 0.28);
        final rosyAlpha = (0.28 * rosy).clamp(0.0, 0.18);

        Widget layered = child;

        // Tone ligero (sin blur a pantalla completa: oscurecía y ensuciaba).
        try {
          layered = ColorFiltered(
            colorFilter: ColorFilter.matrix(
              _toneMatrix(
                mode: mode,
                intensity: (intensity * 0.45 + 0.12 * whiten + 0.08 * rosy)
                    .clamp(0.0, 0.55),
                sharpen: sharpen,
              ),
            ),
            child: layered,
          );
        } catch (_) {}

        // Shader path (Impeller / devices que lo soportan sobre el child).
        final shader = controller.shader;
        if (controller.isSupported && shader != null && intensity > 0.01) {
          try {
            layered = ImageFiltered(
              imageFilter: ui.ImageFilter.shader(shader),
              child: layered,
            );
          } catch (_) {}
        }

        // Soft even-skin (fallback sin GPUPixel; debe notarse al mover sliders).
        final smoothVeil = (0.05 + 0.12 * intensity + 0.08 * whiten).clamp(0.0, 0.18);
        // Tinte del look solo en el centro.
        final tintCenter = (0.03 + 0.08 * intensity).clamp(0.0, 0.12);

        return Stack(
          fit: StackFit.expand,
          children: [
            layered,
            IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0, -0.08),
                    radius: 0.88,
                    colors: [
                      Colors.white.withValues(alpha: smoothVeil),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            if (lift > 0.01)
              IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(0, -0.12),
                      radius: 0.9,
                      colors: [
                        Colors.white.withValues(alpha: lift),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            if (rosyAlpha > 0.01)
              IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(0, 0.1),
                      radius: 0.7,
                      colors: [
                        const Color(0xFFF48FB1).withValues(alpha: rosyAlpha),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            if (tintCenter > 0.01)
              IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(0, -0.05),
                      radius: 0.75,
                      colors: [
                        tint.withValues(alpha: tintCenter),
                        Colors.transparent,
                      ],
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
    if (mode > 4.5) return const Color(0xFFFFF8F5); // Beauty HD — casi neutro
    if (mode < 0.5) return const Color(0xFFFFF6F2); // Soft / Natural
    if (mode < 1.5) return const Color(0xFFFFFBFD); // Porcelain
    if (mode < 2.5) return const Color(0xFFF0F9FF); // Fresh
    if (mode < 3.5) return const Color(0xFFFFF3E0); // Warm (suave)
    return const Color(0xFFFFF0F5); // Rose
  }

  static double _liftAlpha(double mode, double intensity) {
    final base = mode > 4.5
        ? 0.12
        : (mode >= 0.5 && mode < 1.5 ? 0.12 : 0.08);
    return (base * intensity).clamp(0.0, 0.14);
  }

  /// Matriz 4×5 (row-major) para [ColorFilter.matrix] — tonos suaves, sin cast amarillo.
  static List<double> _toneMatrix({
    required double mode,
    required double intensity,
    double sharpen = 0,
  }) {
    double r = 1, g = 1, b = 1;
    double ro = 0, go = 0, bo = 0;
    final sh = sharpen.clamp(0.0, 1.0);
    final i = intensity.clamp(0.0, 1.0);

    if (mode > 4.5) {
      // Beauty HD — lift neutro (R≈G≈B)
      r = 1.0 + 0.04 * i + 0.02 * sh;
      g = 1.0 + 0.04 * i + 0.02 * sh;
      b = 1.0 + 0.035 * i + 0.02 * sh;
      ro = 0.015 * i;
      go = 0.015 * i;
      bo = 0.012 * i;
    } else if (mode < 0.5) {
      r = 1.0 + 0.03 * i + 0.02 * sh;
      g = 1.0 + 0.03 * i + 0.02 * sh;
      b = 1.0 + 0.025 * i + 0.015 * sh;
      ro = 0.01 * i;
      go = 0.01 * i;
      bo = 0.008 * i;
    } else if (mode < 1.5) {
      r = 1.0 + 0.04 * i;
      g = 1.0 + 0.045 * i;
      b = 1.0 + 0.05 * i;
      ro = 0.02 * i;
      go = 0.02 * i;
      bo = 0.022 * i;
    } else if (mode < 2.5) {
      r = 1.0 + 0.015 * i;
      g = 1.0 + 0.03 * i;
      b = 1.0 + 0.05 * i;
      ro = 0.008 * i;
      go = 0.012 * i;
      bo = 0.02 * i;
    } else if (mode < 3.5) {
      r = 1.0 + 0.06 * i;
      g = 1.0 + 0.035 * i;
      b = 1.0 + 0.01 * i;
      ro = 0.02 * i;
      go = 0.012 * i;
      bo = 0.0;
    } else {
      r = 1.0 + 0.05 * i;
      g = 1.0 + 0.02 * i;
      b = 1.0 + 0.03 * i;
      ro = 0.02 * i;
      go = 0.008 * i;
      bo = 0.012 * i;
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
