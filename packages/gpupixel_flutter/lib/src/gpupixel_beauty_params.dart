/// Intensidades 0–1 mapeadas a propiedades nativas de GPUPixel.
///
/// Escalas internas (demo GPUPixel):
/// - [smooth] → `skin_smoothing` / SetBlurAlpha
/// - [whiten] → `whiteness` / SetWhite (×0.5)
/// - [slimFace] → `thin_face` / SetFaceSlimLevel (×0.05)
/// - [bigEye] → `big_eye` / SetEyeZoomLevel (×0.1)
class GpuPixelBeautyParams {
  const GpuPixelBeautyParams({
    this.smooth = 0.55,
    this.whiten = 0.5,
    this.slimFace = 0.0,
    this.bigEye = 0.0,
    this.enabled = true,
  });

  final double smooth;
  final double whiten;
  final double slimFace;
  final double bigEye;
  final bool enabled;

  GpuPixelBeautyParams copyWith({
    double? smooth,
    double? whiten,
    double? slimFace,
    double? bigEye,
    bool? enabled,
  }) {
    return GpuPixelBeautyParams(
      smooth: smooth ?? this.smooth,
      whiten: whiten ?? this.whiten,
      slimFace: slimFace ?? this.slimFace,
      bigEye: bigEye ?? this.bigEye,
      enabled: enabled ?? this.enabled,
    );
  }

  /// Valores listos para `MethodChannel('krimson/gpupixel').setBeauty`.
  /// Escalas alineadas al demo GPUPixel (sliders UI 0–1 → nivel nativo).
  Map<String, double> toNative() {
    if (!enabled) {
      return const {
        'smooth': 0,
        'whiten': 0,
        'slimFace': 0,
        'bigEye': 0,
      };
    }
    return {
      'smooth': smooth.clamp(0.0, 1.0),
      // Demo: whitening_strength/20 con max ~10 → ~0.5; un poco más visible.
      'whiten': (whiten.clamp(0.0, 1.0) * 0.65),
      // Demo: face_slim/200 con max 10 → 0.05; subimos un poco para UI 0–100.
      'slimFace': (slimFace.clamp(0.0, 1.0) * 0.08),
      // Demo: eye/100 con max 10 → 0.1.
      'bigEye': (bigEye.clamp(0.0, 1.0) * 0.15),
    };
  }

  /// Desde sliders UI 0–100 (compatibles con whiten/smooth existentes).
  factory GpuPixelBeautyParams.fromSliders({
    required bool enabled,
    required double whiten,
    required double smooth,
    double slimFace = 0,
    double bigEye = 0,
  }) {
    return GpuPixelBeautyParams(
      enabled: enabled,
      whiten: (whiten / 100.0).clamp(0.0, 1.0),
      smooth: (smooth / 100.0).clamp(0.0, 1.0),
      slimFace: (slimFace / 100.0).clamp(0.0, 1.0),
      bigEye: (bigEye / 100.0).clamp(0.0, 1.0),
    );
  }
}
