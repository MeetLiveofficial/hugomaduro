#include <flutter/runtime_effect.glsl>

// Engine fills uSize (indices 0–1) when used with ImageFilter.shader.
uniform vec2 uSize;
uniform float uIntensity; // 2 — master mix 0..1
uniform float uMode;      // 3 — Soft/Porcelain/Fresh/Warm/Rose
uniform float uWhiten;    // 4 — 0..1
uniform float uRosy;      // 5 — 0..1
uniform float uSmooth;    // 6 — 0..1 skin soft blur
uniform float uSharpen;   // 7 — 0..1 detail restore
uniform sampler2D uTexture;

out vec4 fragColor;

vec3 sampleRgb(vec2 uv) {
  return texture(uTexture, clamp(uv, vec2(0.0), vec2(1.0))).rgb;
}

// Soft bilateral-ish blur biased to mid skin tones.
vec3 softSkin(vec2 uv, vec2 px, float amount) {
  vec3 c = sampleRgb(uv);
  if (amount < 0.01) return c;

  vec3 acc = c * 0.36;
  acc += sampleRgb(uv + vec2(px.x, 0.0)) * 0.12;
  acc += sampleRgb(uv - vec2(px.x, 0.0)) * 0.12;
  acc += sampleRgb(uv + vec2(0.0, px.y)) * 0.12;
  acc += sampleRgb(uv - vec2(0.0, px.y)) * 0.12;
  acc += sampleRgb(uv + px) * 0.08;
  acc += sampleRgb(uv - px) * 0.08;
  float luma = dot(c, vec3(0.299, 0.587, 0.114));
  // Preserve very dark/bright pixels (eyes, hair, highlights).
  float skinMask = smoothstep(0.12, 0.28, luma) * (1.0 - smoothstep(0.78, 0.92, luma));
  float t = amount * skinMask;
  return mix(c, acc, t);
}

vec3 unsharp(vec3 c, vec3 blurred, float amount) {
  if (amount < 0.01) return c;
  vec3 detail = c - blurred;
  return c + detail * (amount * 0.85);
}

vec3 applyMode(vec3 c, float mode, float intensity) {
  float luma = dot(c, vec3(0.299, 0.587, 0.114));
  vec3 soft = mix(c, vec3(luma), 0.10 * intensity);
  vec3 porcelain = mix(soft, vec3(luma * 1.04), 0.18 * intensity) * vec3(1.02, 1.01, 1.04);
  vec3 fresh = soft * mix(vec3(1.0), vec3(0.97, 1.03, 1.05), intensity * 0.7);
  vec3 warm = soft * mix(vec3(1.0), vec3(1.06, 1.02, 0.94), intensity * 0.75);
  vec3 rose = soft * mix(vec3(1.0), vec3(1.05, 0.98, 1.03), intensity * 0.7);

  if (mode > 0.5 && mode < 1.5) return porcelain;
  if (mode > 1.5 && mode < 2.5) return fresh;
  if (mode > 2.5 && mode < 3.5) return warm;
  if (mode > 3.5) return rose;
  return soft;
}

void main() {
  vec2 uv = FlutterFragCoord().xy / uSize;
  vec2 px = (1.5 + 2.5 * uSmooth) / uSize;

  vec3 original = sampleRgb(uv);
  float master = clamp(uIntensity, 0.0, 1.0);
  if (master < 0.001) {
    fragColor = vec4(original, 1.0);
    return;
  }

  float smoothAmt = clamp(uSmooth, 0.0, 1.0) * master;
  float whitenAmt = clamp(uWhiten, 0.0, 1.0) * master;
  float rosyAmt = clamp(uRosy, 0.0, 1.0) * master;
  float sharpenAmt = clamp(uSharpen, 0.0, 1.0) * master;

  vec3 soft = softSkin(uv, px, smoothAmt * 0.85);
  vec3 look = applyMode(soft, uMode, master);

  // Whiten: lift midtones toward bright skin.
  float luma = dot(look, vec3(0.299, 0.587, 0.114));
  vec3 whitened = look + vec3(0.07, 0.06, 0.055) * whitenAmt * smoothstep(0.15, 0.65, luma);
  whitened = mix(whitened, vec3(1.0), whitenAmt * 0.04);

  // Rosy: warm pink on cheeks zone (center-lower face bias via UV).
  float cheek =
      exp(-pow((uv.x - 0.33) * 3.2, 2.0) - pow((uv.y - 0.48) * 3.8, 2.0)) +
      exp(-pow((uv.x - 0.67) * 3.2, 2.0) - pow((uv.y - 0.48) * 3.8, 2.0));
  cheek = clamp(cheek, 0.0, 1.0);
  whitened = mix(whitened, whitened * vec3(1.08, 0.92, 0.96), rosyAmt * cheek * 0.55);
  whitened = mix(whitened, whitened * vec3(1.03, 0.97, 0.99), rosyAmt * 0.18);

  // Light sharpen after smooth so eyes/lips keep detail.
  vec3 hi = unsharp(whitened, soft, sharpenAmt * 0.65);

  fragColor = vec4(mix(original, hi, master), 1.0);
}
