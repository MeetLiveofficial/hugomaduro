#include <flutter/runtime_effect.glsl>

// uSize is filled by the engine (indices 0–1).
uniform vec2 uSize;
// Index 2
uniform float uIntensity;
// Index 3 — Soft/Porcelain/Fresh/Warm/Rose
uniform float uMode;
uniform sampler2D uTexture;

out vec4 fragColor;

void main() {
  vec2 uv = FlutterFragCoord().xy / uSize;
  vec4 color = texture(uTexture, uv);

  // Lightweight soft look: slight desaturation + lift toward warm skin.
  float luma = dot(color.rgb, vec3(0.299, 0.587, 0.114));
  vec3 soft = mix(color.rgb, vec3(luma), 0.18 * uIntensity);
  vec3 porcelain = mix(soft, vec3(luma) * 1.05, 0.22 * uIntensity);
  vec3 fresh = soft * mix(vec3(1.0), vec3(0.96, 1.04, 1.02), uIntensity);
  vec3 warm = soft * mix(vec3(1.0), vec3(1.06, 1.01, 0.94), uIntensity);
  vec3 rose = soft * mix(vec3(1.0), vec3(1.05, 0.97, 1.02), uIntensity);

  vec3 look = soft;
  if (uMode > 0.5 && uMode < 1.5) {
    look = porcelain;
  } else if (uMode > 1.5 && uMode < 2.5) {
    look = fresh;
  } else if (uMode > 2.5 && uMode < 3.5) {
    look = warm;
  } else if (uMode > 3.5) {
    look = rose;
  }

  fragColor = vec4(mix(color.rgb, look, clamp(uIntensity, 0.0, 1.0)), color.a);
}
