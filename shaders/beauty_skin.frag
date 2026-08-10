#include <flutter/runtime_effect.glsl>

// Engine fills uSize at indices 0–1.
uniform vec2 uSize;
// Index 2 — overall beauty strength 0..1
uniform float uIntensity;
// Index 3 — Soft/Natural=0 · Porcelain=1 · Fresh=2 · Warm=3 · Rose=4 · Beauty HD=5
uniform float uMode;
// Index 4–6 — live sliders (optional overlays also use these in Dart)
uniform float uWhiten;
uniform float uRosy;
uniform float uSharpen;
uniform sampler2D uTexture;

out vec4 fragColor;

vec3 samplePx(vec2 uv, vec2 offsetPx) {
  return texture(uTexture, clamp(uv + offsetPx / uSize, vec2(0.001), vec2(0.999))).rgb;
}

float luma(vec3 c) {
  return dot(c, vec3(0.299, 0.587, 0.114));
}

/// Soft bilateral-ish blur: weights down neighbors that differ a lot (edges).
vec3 softBlur(vec2 uv, float radius, vec3 center) {
  float cl = luma(center);
  vec3 acc = center * 2.0;
  float wSum = 2.0;

  // Cross + diagonals (9-tap style, cheap enough for live preview).
  vec2 offs[8];
  offs[0] = vec2( radius, 0.0);
  offs[1] = vec2(-radius, 0.0);
  offs[2] = vec2(0.0,  radius);
  offs[3] = vec2(0.0, -radius);
  offs[4] = vec2( radius,  radius);
  offs[5] = vec2(-radius,  radius);
  offs[6] = vec2( radius, -radius);
  offs[7] = vec2(-radius, -radius);

  for (int i = 0; i < 8; i++) {
    vec3 s = samplePx(uv, offs[i]);
    float dl = abs(luma(s) - cl);
    // Keep edges (eyes, lips, hair) sharper.
    float w = exp(-dl * dl * 48.0);
    acc += s * w;
    wSum += w;
  }

  // Outer ring for stronger pore/blemish coverage when intensity is high.
  float r2 = radius * 1.65;
  vec2 outer[4];
  outer[0] = vec2( r2, 0.0);
  outer[1] = vec2(-r2, 0.0);
  outer[2] = vec2(0.0,  r2);
  outer[3] = vec2(0.0, -r2);
  for (int i = 0; i < 4; i++) {
    vec3 s = samplePx(uv, outer[i]);
    float dl = abs(luma(s) - cl);
    float w = 0.55 * exp(-dl * dl * 36.0);
    acc += s * w;
    wSum += w;
  }

  return acc / max(wSum, 0.001);
}

/// Prefer mid-tone warm regions (skin) over hair / background / teeth.
float skinMask(vec3 c) {
  float y = luma(c);
  float mid = smoothstep(0.12, 0.32, y) * (1.0 - smoothstep(0.78, 0.96, y));
  float warm = smoothstep(-0.02, 0.06, c.r - c.b);
  float rg = smoothstep(-0.04, 0.05, c.r - c.g);
  return clamp(mid * mix(0.45, 1.0, warm) * mix(0.7, 1.0, rg), 0.0, 1.0);
}

vec3 applyLook(vec3 base, float mode, float amount) {
  float y = luma(base);
  // Soft — piel suave, casi neutro
  vec3 soft = mix(base, vec3(y), 0.12 * amount);
  soft = mix(soft, soft * vec3(1.01, 1.01, 1.02), 0.30 * amount);

  // Porcelain — blanquecino frío
  vec3 porcelain = mix(soft, vec3(y) * vec3(1.06, 1.05, 1.09), 0.42 * amount);
  porcelain = mix(porcelain, porcelain + vec3(0.045, 0.04, 0.055), 0.35 * amount);

  // Fresh — verde-azul fresco
  vec3 fresh = soft * mix(vec3(1.0), vec3(0.92, 1.08, 1.10), amount * 1.15);

  // Warm — dorado/naranja
  vec3 warm = soft * mix(vec3(1.0), vec3(1.14, 1.04, 0.88), amount * 1.2);

  // Rose — rosa/magenta
  vec3 rose = soft * mix(vec3(1.0), vec3(1.12, 0.94, 1.06), amount * 1.25);
  rose = mix(rose, rose + vec3(0.04, 0.0, 0.02), 0.35 * amount);

  // Beauty HD — glow neutro + even
  vec3 beauty = mix(soft, porcelain, 0.40);
  beauty = mix(beauty, beauty * vec3(1.03, 1.03, 1.04), 0.45 * amount);
  beauty = mix(beauty, beauty + vec3(0.02, 0.02, 0.022), 0.35 * amount);

  // Dewy — brillo húmedo + rosado
  vec3 dewy = mix(soft, soft + vec3(0.05, 0.03, 0.04), 0.55 * amount);
  dewy = dewy * mix(vec3(1.0), vec3(1.08, 0.98, 1.05), amount);

  // Matte — aplanar + desaturar
  vec3 matte = mix(base, vec3(y), 0.28 * amount);
  matte = mix(matte, matte * vec3(0.98, 0.97, 0.96), 0.35 * amount);

  // Peach — melocotón
  vec3 peach = soft * mix(vec3(1.0), vec3(1.16, 1.02, 0.90), amount * 1.3);
  peach = mix(peach, peach + vec3(0.05, 0.015, 0.0), 0.4 * amount);

  // Night — contraste frío
  vec3 night = soft * mix(vec3(1.0), vec3(0.92, 0.96, 1.10), amount * 1.15);
  night = mix(night, night * vec3(0.95, 0.97, 1.05), 0.4 * amount);

  // Crystal — brillante + cool
  vec3 crystal = mix(porcelain, fresh, 0.45);
  crystal = mix(crystal, crystal + vec3(0.04, 0.045, 0.055), 0.45 * amount);

  // Glass — piel de cristal (muy claro + cool)
  vec3 glass = mix(porcelain, porcelain * vec3(1.05, 1.06, 1.10), 0.55 * amount);
  glass = mix(glass, glass + vec3(0.05, 0.05, 0.06), 0.4 * amount);

  if (mode > 10.5) return glass;
  if (mode > 9.5) return crystal;
  if (mode > 8.5) return night;
  if (mode > 7.5) return peach;
  if (mode > 6.5) return matte;
  if (mode > 5.5) return dewy;
  if (mode > 4.5) return beauty;
  if (mode > 3.5) return rose;
  if (mode > 2.5) return warm;
  if (mode > 1.5) return fresh;
  if (mode > 0.5) return porcelain;
  return soft;
}

void main() {
  vec2 uv = FlutterFragCoord().xy / uSize;
  vec4 src = texture(uTexture, uv);
  float amount = clamp(uIntensity, 0.0, 1.0);

  if (amount < 0.001) {
    fragColor = src;
    return;
  }

  float skin = skinMask(src.rgb);
  // Stronger radius for Beauty HD / Porcelain.
  float modeBoost = (uMode > 4.5 || (uMode > 0.5 && uMode < 1.5)) ? 1.25 : 1.0;
  float radius = mix(1.2, 5.0, amount) * modeBoost;

  vec3 blurred = softBlur(uv, radius, src.rgb);
  float y0 = luma(src.rgb);
  float yb = luma(blurred);

  // Extra lift where original is darker than neighborhood = spots / pores.
  float blemish = clamp((yb - y0) * 6.0, 0.0, 1.0);
  float edge = clamp(length(src.rgb - blurred) * 4.5, 0.0, 1.0);
  float smoothW = amount * skin * (0.55 + 0.45 * blemish) * (1.0 - 0.7 * edge);

  vec3 smoothed = mix(src.rgb, blurred, clamp(smoothW, 0.0, 0.92));

  // Slight local contrast restore so face doesn't look plastic.
  float sharpen = clamp(uSharpen, 0.0, 1.0);
  vec3 detail = src.rgb - blurred;
  smoothed += detail * (0.18 + 0.35 * sharpen) * (1.0 - 0.5 * amount);

  vec3 looked = applyLook(smoothed, uMode, amount);

  // Whiten / rosy from sliders.
  float whiten = clamp(uWhiten, 0.0, 1.0);
  float rosy = clamp(uRosy, 0.0, 1.0);
  looked = mix(looked, looked + vec3(0.10, 0.09, 0.08), whiten * 0.75 * skin);
  looked = mix(looked, looked * vec3(1.10, 0.94, 1.04) + vec3(0.035, 0.0, 0.015),
               rosy * 0.65 * skin);

  fragColor = vec4(clamp(mix(src.rgb, looked, amount), 0.0, 1.0), src.a);
}
