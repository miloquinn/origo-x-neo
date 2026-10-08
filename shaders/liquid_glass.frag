#include <flutter/runtime_effect.glsl>

// The engine supplies the live backdrop and its physical texture size.
uniform vec2 uSize;
uniform vec4 uBasis;
uniform vec2 uOrigin;
uniform vec2 uExtent;
uniform float uRadius;
uniform float uStrength;
uniform float uSoftness;
uniform sampler2D uInput;
out vec4 fragColor;

vec4 sampleBackdrop(vec2 pixel) {
  vec2 uv = clamp(pixel / uSize, 0.5 / uSize, 1.0 - 0.5 / uSize);
#ifdef IMPELLER_TARGET_OPENGLES
  uv.y = 1.0 - uv.y;
#endif
  return texture(uInput, uv);
}

void main() {
  vec2 pixel = FlutterFragCoord().xy;
  vec2 local = vec2(dot(uBasis.xy, pixel), dot(uBasis.zw, pixel)) + uOrigin;
  vec2 halfSize = uExtent * 0.5;
  float radius = min(uRadius, min(halfSize.x, halfSize.y));
  vec2 p = local - halfSize;
  vec2 q = abs(p) - halfSize + radius;
  vec2 outside = max(q, 0.0);
  float distance = length(outside) + min(max(q.x, q.y), 0.0) - radius;
  vec2 normal;
  if (length(outside) > 0.001) {
    normal = normalize(outside) * sign(p);
  } else {
    normal = q.x > q.y ? vec2(sign(p.x), 0.0) : vec2(0.0, sign(p.y));
  }
  float band = max(1.0, min(halfSize.x, halfSize.y) * 0.65);
  float rim = 1.0 - smoothstep(0.0, band, max(0.0, -distance));
  // Pull samples inward at the curved rim, leaving the centre almost clear.
  vec2 localOffset = -normal * uStrength * rim * rim - p * 0.015;
  // Convert the local displacement back to the filter's coordinate space.
  float determinant = uBasis.x * uBasis.w - uBasis.y * uBasis.z;
  if (abs(determinant) < 0.000001) {
    fragColor = sampleBackdrop(pixel);
    return;
  }
  vec2 delta = vec2(
    uBasis.w * localOffset.x - uBasis.y * localOffset.y,
    -uBasis.z * localOffset.x + uBasis.x * localOffset.y
  ) / determinant;
  vec2 refracted = pixel + delta;
  // A fixed five-tap softening avoids a large blur pass or backdrop capture.
  vec4 color = sampleBackdrop(refracted) * 0.5;
  color += sampleBackdrop(refracted + vec2(uSoftness, 0.0)) * 0.125;
  color += sampleBackdrop(refracted - vec2(uSoftness, 0.0)) * 0.125;
  color += sampleBackdrop(refracted + vec2(0.0, uSoftness)) * 0.125;
  color += sampleBackdrop(refracted - vec2(0.0, uSoftness)) * 0.125;
  fragColor = color;
}
