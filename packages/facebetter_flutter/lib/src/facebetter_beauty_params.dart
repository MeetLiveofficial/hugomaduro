/// Intensidades 0–1 mapeadas a FaceBetter Basic + Reshape.
///
/// Docs: https://www.facebetter.net/docs/android/api-reference
class FaceBetterBeautyParams {
  const FaceBetterBeautyParams({
    this.smooth = 0.55,
    this.whiten = 0.35,
    this.rosy = 0.15,
    this.sharpen = 0.2,
    this.slimFace = 0.0,
    this.bigEye = 0.0,
    this.enabled = true,
  });

  final double smooth;
  final double whiten;
  final double rosy;
  final double sharpen;
  final double slimFace;
  final double bigEye;
  final bool enabled;

  FaceBetterBeautyParams copyWith({
    double? smooth,
    double? whiten,
    double? rosy,
    double? sharpen,
    double? slimFace,
    double? bigEye,
    bool? enabled,
  }) {
    return FaceBetterBeautyParams(
      smooth: smooth ?? this.smooth,
      whiten: whiten ?? this.whiten,
      rosy: rosy ?? this.rosy,
      sharpen: sharpen ?? this.sharpen,
      slimFace: slimFace ?? this.slimFace,
      bigEye: bigEye ?? this.bigEye,
      enabled: enabled ?? this.enabled,
    );
  }

  Map<String, Object> toNative() {
    if (!enabled) {
      return const {
        'enabled': false,
        'smooth': 0.0,
        'whiten': 0.0,
        'rosy': 0.0,
        'sharpen': 0.0,
        'slimFace': 0.0,
        'bigEye': 0.0,
      };
    }
    return {
      'enabled': true,
      'smooth': smooth.clamp(0.0, 1.0),
      'whiten': whiten.clamp(0.0, 1.0),
      'rosy': rosy.clamp(0.0, 1.0),
      'sharpen': sharpen.clamp(0.0, 1.0),
      'slimFace': slimFace.clamp(0.0, 1.0),
      'bigEye': bigEye.clamp(0.0, 1.0),
    };
  }

  /// Sliders UI 0–100.
  factory FaceBetterBeautyParams.fromSliders({
    required bool enabled,
    required double whiten,
    required double smooth,
    double rosy = 20,
    double sharpen = 25,
    double slimFace = 0,
    double bigEye = 0,
  }) {
    return FaceBetterBeautyParams(
      enabled: enabled,
      whiten: (whiten / 100.0).clamp(0.0, 1.0),
      smooth: (smooth / 100.0).clamp(0.0, 1.0),
      rosy: (rosy / 100.0).clamp(0.0, 1.0),
      sharpen: (sharpen / 100.0).clamp(0.0, 1.0),
      slimFace: (slimFace / 100.0).clamp(0.0, 1.0),
      bigEye: (bigEye / 100.0).clamp(0.0, 1.0),
    );
  }
}
